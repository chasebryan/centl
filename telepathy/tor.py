from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import shutil
import signal
import subprocess
import time

from .carrier import CarrierError, CarrierStatus


@dataclass(frozen=True)
class TorOnionConfig:
    telepathy_host: str = "127.0.0.1"
    telepathy_port: int = 8790
    virtual_port: int = 80
    tor_binary: str = "tor"
    state_dir: Path = Path(".telepathy/tor")
    startup_timeout: float = 20.0

    @property
    def hidden_service_dir(self) -> Path:
        return self.state_dir / "hidden-service"

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
    """Tor v3 onion road beneath FCF Telepathy.

    This adapter owns only carrier lifecycle. It does not own FCF node identity,
    CARAVAN authorization, signing keys, or the Telepathy policy surface.
    """

    name = "tor-onion"

    def __init__(self, config: TorOnionConfig | None = None) -> None:
        self.config = config or TorOnionConfig()

    def _tor_binary(self) -> str | None:
        return shutil.which(self.config.tor_binary)

    def render_torrc(self) -> str:
        hidden_service_dir = self.config.hidden_service_dir.resolve()
        log_path = self.config.log_path.resolve()
        return "\n".join(
            [
                "ClientOnly 0",
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

    def prepare(self) -> Path:
        self.config.state_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.config.hidden_service_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
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
        try:
            signal.kill(pid, 0)
        except ProcessLookupError:
            return False
        except PermissionError:
            return True
        return True

    def _hostname(self) -> str | None:
        try:
            hostname = (self.config.hidden_service_dir / "hostname").read_text(
                encoding="ascii"
            ).strip()
        except OSError:
            return None
        if not hostname.endswith(".onion"):
            return None
        return hostname

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
        alive = pid is not None and self._pid_alive(pid)
        endpoint = self._hostname() if alive else None
        return CarrierStatus(
            carrier=self.name,
            available=self._tor_binary() is not None,
            published=alive and endpoint is not None,
            endpoint=endpoint,
            pid=pid if alive else None,
            detail="running" if alive else "not running",
        )

    def publish(self) -> CarrierStatus:
        current = self.status()
        if current.published:
            return current

        binary = self._tor_binary()
        if binary is None:
            raise CarrierError("tor executable not found")

        self.prepare()
        log_handle = self.config.log_path.open("ab", buffering=0)
        try:
            process = subprocess.Popen(
                [binary, "-f", str(self.config.torrc_path)],
                stdin=subprocess.DEVNULL,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
                close_fds=True,
                start_new_session=True,
            )
        finally:
            log_handle.close()

        self.config.pid_path.write_text(f"{process.pid}\n", encoding="ascii")
        self.config.pid_path.chmod(0o600)

        deadline = time.monotonic() + self.config.startup_timeout
        while time.monotonic() < deadline:
            if process.poll() is not None:
                self.config.pid_path.unlink(missing_ok=True)
                raise CarrierError(f"tor exited during startup with code {process.returncode}")
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

    def withdraw(self) -> CarrierStatus:
        pid = self._read_pid()
        if pid is not None and self._pid_alive(pid):
            try:
                signal.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass

            deadline = time.monotonic() + 5.0
            while time.monotonic() < deadline and self._pid_alive(pid):
                time.sleep(0.05)

            if self._pid_alive(pid):
                raise CarrierError("Tor process did not stop after SIGTERM")

        self.config.pid_path.unlink(missing_ok=True)
        return CarrierStatus(
            carrier=self.name,
            available=self._tor_binary() is not None,
            published=False,
            endpoint=None,
            pid=None,
            detail="withdrawn",
        )
