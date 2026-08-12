from __future__ import annotations

from dataclasses import dataclass
from http.client import HTTPConnection, HTTPException
import ipaddress
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import time

from .carrier import CarrierError, CarrierStatus


_V3_ONION = re.compile(r"[a-z2-7]{56}\.onion\Z")


def _require_loopback_literal(host: str) -> None:
    try:
        address = ipaddress.ip_address(host)
    except ValueError as exc:
        raise ValueError("telepathy_host must be an IPv4 loopback literal") from exc
    if not isinstance(address, ipaddress.IPv4Address) or not address.is_loopback:
        raise ValueError("telepathy_host must be an IPv4 loopback literal")


def _require_port(port: int, *, field: str) -> None:
    if not 1 <= port <= 65535:
        raise ValueError(f"{field} must be between 1 and 65535")


def _require_torrc_safe_path(path: Path, *, field: str) -> None:
    value = str(path)
    if any(ord(ch) < 0x20 or ord(ch) == 0x7F for ch in value):
        raise ValueError(f"{field} contains a control character unsafe for torrc")


@dataclass(frozen=True)
class TorOnionConfig:
    telepathy_host: str = "127.0.0.1"
    telepathy_port: int = 8790
    virtual_port: int = 80
    tor_binary: str = "tor"
    state_dir: Path = Path(".fcf-telepathyd/tor")
    startup_timeout: float = 20.0
    gateway_probe_timeout: float = 1.0

    def __post_init__(self) -> None:
        _require_loopback_literal(self.telepathy_host)
        _require_port(self.telepathy_port, field="telepathy_port")
        _require_port(self.virtual_port, field="virtual_port")
        _require_torrc_safe_path(self.state_dir, field="state_dir")
        if self.startup_timeout <= 0:
            raise ValueError("startup_timeout must be positive")
        if self.gateway_probe_timeout <= 0:
            raise ValueError("gateway_probe_timeout must be positive")

    @property
    def hidden_service_dir(self) -> Path:
        return self.state_dir / "hidden-service"

    @property
    def data_dir(self) -> Path:
        return self.state_dir / "data"

    @property
    def torrc_path(self) -> Path:
        return self.state_dir / "torrc"

    @property
    def pid_path(self) -> Path:
        return self.state_dir / "tor.pid"

    @property
    def log_path(self) -> Path:
        return self.state_dir / "tor.log"


class TorOnionCarrier:
    """Tor v3 onion road beneath fcf-telepathyd.

    The adapter owns carrier lifecycle only. It does not own FCF node identity,
    CARAVAN authorization, signing keys, or the fcf-telepathyd policy surface.
    """

    name = "tor-onion"

    def __init__(self, config: TorOnionConfig | None = None) -> None:
        self.config = config or TorOnionConfig()
        self._process: subprocess.Popen[bytes] | None = None

    def _tor_binary(self) -> str | None:
        return shutil.which(self.config.tor_binary)

    def render_torrc(self) -> str:
        hidden_service_dir = self.config.hidden_service_dir.resolve()
        data_dir = self.config.data_dir.resolve()
        log_path = self.config.log_path.resolve()
        return "\n".join(
            [
                f"DataDirectory {data_dir}",
                "SocksPort 0",
                "AvoidDiskWrites 1",
                f"HiddenServiceDir {hidden_service_dir}",
                "HiddenServiceVersion 3",
                (
                    f"HiddenServicePort {self.config.virtual_port} "
                    f"{self.config.telepathy_host}:{self.config.telepathy_port}"
                ),
                f"Log notice file {log_path}",
                "",
            ]
        )

    @staticmethod
    def _ensure_private_directory(path: Path) -> None:
        if path.is_symlink():
            raise CarrierError(f"refusing symlinked state directory: {path}")
        path.mkdir(parents=True, exist_ok=True, mode=0o700)
        if path.is_symlink() or not path.is_dir():
            raise CarrierError(f"unsafe state directory: {path}")
        path.chmod(0o700)

    def prepare(self) -> Path:
        self._ensure_private_directory(self.config.state_dir)
        self._ensure_private_directory(self.config.data_dir)
        self._ensure_private_directory(self.config.hidden_service_dir)
        self.config.torrc_path.write_text(self.render_torrc(), encoding="utf-8")
        self.config.torrc_path.chmod(0o600)
        return self.config.torrc_path

    def _read_pid(self) -> int | None:
        try:
            raw = self.config.pid_path.read_text(encoding="ascii").strip()
            pid = int(raw)
        except (FileNotFoundError, ValueError, OSError):
            return None
        if pid <= 1:
            return None
        return pid

    @staticmethod
    def _pid_alive(pid: int) -> bool:
        stat_path = Path("/proc") / str(pid) / "stat"
        try:
            stat = stat_path.read_text(encoding="ascii", errors="replace")
            closing = stat.rfind(")")
            if closing != -1:
                fields = stat[closing + 2 :].split()
                if fields and fields[0] == "Z":
                    return False
        except OSError:
            pass

        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return False
        except PermissionError:
            return True
        return True

    @staticmethod
    def _reap_if_child(pid: int) -> None:
        """Best-effort reap when the managed PID is our child.

        Normal `serve --publish` lifecycle uses the stored Popen handle and
        waits directly. Recovery may instead discover the same managed process
        through the persisted PID. In a same-process recovery test that PID is
        still our child; reaping it avoids leaving a zombie/test-harness warning.
        After a real daemon restart it is not our child, so waitpid safely
        raises ChildProcessError and no action is taken.
        """

        try:
            os.waitpid(pid, os.WNOHANG)
        except (ChildProcessError, OSError):
            return

    def _pid_is_ours(self, pid: int) -> bool:
        """Verify a persisted PID before ever signaling it.

        Linux can recycle process IDs. A stale pid file must therefore never be
        sufficient authority to terminate a process. The live command line must
        contain both our configured Tor executable and our exact torrc path.
        """

        cmdline_path = Path("/proc") / str(pid) / "cmdline"
        try:
            raw = cmdline_path.read_bytes()
        except OSError:
            return False
        argv = [
            part.decode("utf-8", errors="surrogateescape")
            for part in raw.split(b"\0")
            if part
        ]
        expected_torrc = str(self.config.torrc_path.resolve())
        binary = self._tor_binary()
        if binary is None:
            return False
        binary_name = Path(binary).name
        names = {Path(arg).name for arg in argv if arg and not arg.startswith("-")}
        return expected_torrc in argv and binary_name in names

    def _hostname(self) -> str | None:
        try:
            hostname = (self.config.hidden_service_dir / "hostname").read_text(
                encoding="ascii"
            ).strip()
        except OSError:
            return None
        if _V3_ONION.fullmatch(hostname) is None:
            return None
        return hostname

    def _require_gateway(self) -> None:
        connection = HTTPConnection(
            self.config.telepathy_host,
            self.config.telepathy_port,
            timeout=self.config.gateway_probe_timeout,
        )
        try:
            connection.request("HEAD", "/")
            response = connection.getresponse()
            response.read()
            server = response.getheader("Server") or ""
            if response.status != 200 or not server.startswith("fcf-telepathyd/"):
                raise CarrierError(
                    "loopback target is not a healthy fcf-telepathyd gateway; "
                    "refusing to publish"
                )
        except CarrierError:
            raise
        except (OSError, TimeoutError, HTTPException) as exc:
            raise CarrierError(
                "fcf-telepathyd loopback gateway is not reachable; refusing to publish"
            ) from exc
        finally:
            connection.close()

    def probe(self) -> CarrierStatus:
        binary = self._tor_binary()
        return CarrierStatus(
            carrier=self.name,
            available=binary is not None,
            published=False,
            detail=binary or "tor executable not found",
        )

    def status(self) -> CarrierStatus:
        pid = self._read_pid()
        if pid is None:
            return CarrierStatus(
                carrier=self.name,
                available=self._tor_binary() is not None,
                published=False,
                detail="not running",
            )
        if not self._pid_alive(pid):
            return CarrierStatus(
                carrier=self.name,
                available=self._tor_binary() is not None,
                published=False,
                detail="stale pid record",
            )
        if not self._pid_is_ours(pid):
            return CarrierStatus(
                carrier=self.name,
                available=self._tor_binary() is not None,
                published=False,
                pid=pid,
                detail="pid record does not identify this Tor instance",
            )
        endpoint = self._hostname()
        return CarrierStatus(
            carrier=self.name,
            available=self._tor_binary() is not None,
            published=endpoint is not None,
            endpoint=endpoint,
            pid=pid,
            detail="running" if endpoint is not None else "Tor running; onion not published",
        )

    def publish(self) -> CarrierStatus:
        current_pid = self._read_pid()
        if current_pid is not None and self._pid_alive(current_pid):
            if not self._pid_is_ours(current_pid):
                raise CarrierError("refusing to overwrite an unverified live Tor pid record")
            current = self.status()
            if current.published:
                return current
            raise CarrierError(
                "the managed Tor process is already running without a published onion"
            )
        if current_pid is not None:
            self._reap_if_child(current_pid)
            self.config.pid_path.unlink(missing_ok=True)

        binary = self._tor_binary()
        if binary is None:
            raise CarrierError("tor executable not found")

        self._require_gateway()
        self.prepare()
        log_handle = self.config.log_path.open("ab", buffering=0)
        try:
            process = subprocess.Popen(
                [binary, "-f", str(self.config.torrc_path.resolve())],
                stdin=subprocess.DEVNULL,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
                close_fds=True,
                start_new_session=True,
            )
        finally:
            log_handle.close()

        self._process = process
        self.config.pid_path.write_text(f"{process.pid}\n", encoding="ascii")
        self.config.pid_path.chmod(0o600)

        deadline = time.monotonic() + self.config.startup_timeout
        while time.monotonic() < deadline:
            if process.poll() is not None:
                self.config.pid_path.unlink(missing_ok=True)
                raise CarrierError(
                    f"tor exited during startup with code {process.returncode}"
                )
            endpoint = self._hostname()
            if endpoint is not None:
                return CarrierStatus(
                    carrier=self.name,
                    available=True,
                    published=True,
                    endpoint=endpoint,
                    pid=process.pid,
                    detail="published",
                )
            time.sleep(0.1)

        self.withdraw()
        raise CarrierError("timed out waiting for Tor onion-service hostname")

    def _stop_owned_pid(self, pid: int) -> None:
        if not self._pid_alive(pid):
            self._reap_if_child(pid)
            return
        if not self._pid_is_ours(pid):
            raise CarrierError(
                "refusing to signal a process not verified as this Tor instance"
            )
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            self._reap_if_child(pid)
            return

        deadline = time.monotonic() + 5.0
        while time.monotonic() < deadline and self._pid_alive(pid):
            time.sleep(0.05)
        if self._pid_alive(pid):
            raise CarrierError("Tor process did not stop after SIGTERM")
        self._reap_if_child(pid)

    def withdraw(self) -> CarrierStatus:
        if self._process is not None and self._process.poll() is None:
            self._process.terminate()
            try:
                self._process.wait(timeout=5.0)
            except subprocess.TimeoutExpired as exc:
                raise CarrierError("Tor child did not stop after SIGTERM") from exc
        else:
            pid = self._read_pid()
            if pid is not None:
                self._stop_owned_pid(pid)

        self.config.pid_path.unlink(missing_ok=True)
        self._process = None
        return CarrierStatus(
            carrier=self.name,
            available=self._tor_binary() is not None,
            published=False,
            endpoint=None,
            pid=None,
            detail="withdrawn",
        )
