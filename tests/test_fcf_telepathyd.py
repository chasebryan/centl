from __future__ import annotations

from http.client import HTTPConnection
import os
from pathlib import Path
import socket
import socketserver
import subprocess
import sys
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from telepathy.carrier import CarrierError
from telepathy.gateway import GatewayConfig, TelepathyGateway
from telepathy.policy import PolicyError, PublicReadPolicy
from telepathy.tor import TorOnionCarrier, TorOnionConfig

SCRIPT = ROOT / "scripts" / "fcf-telepathyd"
DOC = ROOT / "docs" / "FCF-TELEPATHY.md"


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def freeze_tree(root: Path) -> None:
    for path in sorted(root.rglob("*"), key=lambda item: len(item.parts), reverse=True):
        if path.is_symlink():
            continue
        path.chmod(0o555 if path.is_dir() else 0o444)
    root.chmod(0o555)


def make_generation(base: Path, name: str, *, marker: bytes) -> Path:
    generation = base / name
    for directory in ("source", "caravan", "releases/v0.14.0", "semantic"):
        (generation / directory).mkdir(parents=True, exist_ok=True)

    files = {
        "index.html": marker,
        "robots.txt": b"User-agent: *\nDisallow: /\n",
        "status.json": b'{"status":"approved"}\n',
        "SHA256SUMS": b"0" * 64 + b"  index.html\n",
        "source/INDEX.json": b'{"source":"approved"}\n',
        "source/centl-main.tar.gz": b"main-source",
        "source/centl-oasis.tar.gz": b"oasis-source",
        "source/centl-mirage.tar.gz": b"mirage-source",
        "caravan/catalog-v1.json": b'{"catalog":"approved"}\n',
        "caravan/CATALOG-STATUS": b"authenticated-by-fcf\n",
        "caravan/INGEST-STATUS.json": b'{"ingest":"approved"}\n',
        "releases/v0.14.0/centl.tar.gz": b"0123456789abcdef",
        "semantic/catalog.json": b'{"semantic":"approved"}\n',
    }
    for relative, content in files.items():
        (generation / relative).write_bytes(content)

    freeze_tree(generation)
    return generation


def point_current(base: Path, generation: Path) -> Path:
    current = base / "current"
    current.unlink(missing_ok=True)
    current.symlink_to(generation, target_is_directory=True)
    return current


def gateway_config(current: Path, *, listen_port: int) -> GatewayConfig:
    return GatewayConfig(
        listen_port=listen_port,
        live_root=current,
        live_root_uid=os.getuid(),
    )


class EmptyTCPHandler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        return


class RunningTCP:
    def __init__(self) -> None:
        self.server = socketserver.ThreadingTCPServer(("127.0.0.1", 0), EmptyTCPHandler)
        self.server.daemon_threads = True
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    @property
    def port(self) -> int:
        return int(self.server.server_address[1])

    def __enter__(self) -> "RunningTCP":
        self.thread.start()
        return self

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        self.server.shutdown()
        self.thread.join(timeout=2.0)
        self.server.server_close()


def write_fake_tor(path: Path) -> None:
    path.write_text(
        """#!/usr/bin/env python3
import pathlib
import signal
import sys
import time

torrc = pathlib.Path(sys.argv[sys.argv.index('-f') + 1])
hidden = None
for line in torrc.read_text(encoding='utf-8').splitlines():
    if line.startswith('HiddenServiceDir '):
        hidden = pathlib.Path(line.split(' ', 1)[1])
        break
if hidden is None:
    raise SystemExit(2)
hidden.mkdir(parents=True, exist_ok=True)
(hidden / 'hostname').write_text('a' * 56 + '.onion\\n', encoding='ascii')
running = True

def stop(_signum, _frame):
    global running
    running = False

signal.signal(signal.SIGTERM, stop)
while running:
    time.sleep(0.05)
""",
        encoding="utf-8",
    )
    path.chmod(0o755)


class PolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.policy = PublicReadPolicy()

    def test_exact_and_approved_tree_reads(self) -> None:
        for method in ("GET", "HEAD"):
            for path in (
                "/",
                "/status.json",
                "/source/INDEX.json",
                "/source/centl-main.tar.gz",
                "/caravan/catalog-v1.json",
                "/releases/v0.14.0/centl.tar.gz",
                "/semantic/catalog.json",
            ):
                self.assertEqual(self.policy.authorize(method, path), path)

    def test_write_and_proxy_surfaces_are_closed(self) -> None:
        for method in ("POST", "PUT", "DELETE", "PATCH", "OPTIONS", "TRACE", "CONNECT"):
            with self.assertRaises(PolicyError):
                self.policy.authorize(method, "/status.json")
        for target in (
            "http://127.0.0.1:22/",
            "//127.0.0.1:22/",
            "/status.json?next=/etc/shadow",
            "/source/%2e%2e/status.json",
            "/source/../status.json",
            "/source//INDEX.json",
            "/source\\INDEX.json",
            "/releases/",
            "/not-approved",
        ):
            with self.assertRaises(PolicyError, msg=target):
                self.policy.authorize("GET", target)

    def test_gateway_config_requires_loopback_and_absolute_live_root(self) -> None:
        with self.assertRaises(ValueError):
            GatewayConfig(listen_host="0.0.0.0")
        with self.assertRaises(ValueError):
            GatewayConfig(listen_host="localhost")
        with self.assertRaises(ValueError):
            GatewayConfig(listen_host="::1")
        with self.assertRaises(ValueError):
            GatewayConfig(live_root=Path("relative/current"))
        with self.assertRaises(ValueError):
            GatewayConfig(live_root_uid=-1)
        with self.assertRaises(ValueError):
            GatewayConfig(max_bytes_per_second=-1)
        with self.assertRaises(ValueError):
            GatewayConfig(max_bytes_per_second=1024 * 1024 * 1024 + 1)


class GatewayTests(unittest.TestCase):
    def test_allowed_read_comes_only_from_activated_live_generation(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            marker = b"approved-caravan-cargo\n"
            current = point_current(base, make_generation(base, "generation-1", marker=marker))
            gateway_port = free_port()

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request(
                    "GET",
                    "/",
                    headers={
                        "Host": "attacker.invalid",
                        "Authorization": "Bearer secret",
                        "X-Forwarded-For": "203.0.113.9",
                    },
                )
                response = conn.getresponse()
                body = response.read()
                headers = {key.lower(): value for key, value in response.getheaders()}
                conn.close()

            self.assertEqual(response.status, 200)
            self.assertEqual(body, marker)
            self.assertEqual(headers.get("x-content-type-options"), "nosniff")
            self.assertEqual(headers.get("x-frame-options"), "DENY")
            self.assertNotIn("authorization", headers)
            self.assertNotIn("x-forwarded-for", headers)

    def test_denied_method_and_path_do_not_touch_public_cargo(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            current = point_current(
                base,
                make_generation(base, "generation-1", marker=b"immutable\n"),
            )
            status_path = current.resolve() / "status.json"
            before = status_path.read_bytes()
            gateway_port = free_port()

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("POST", "/status.json")
                response = conn.getresponse()
                response.read()
                conn.close()
                self.assertEqual(response.status, 405)

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/etc/passwd")
                response = conn.getresponse()
                response.read()
                conn.close()
                self.assertEqual(response.status, 403)

            self.assertEqual(status_path.read_bytes(), before)

    def test_request_body_multiple_range_and_unsatisfiable_range_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            current = point_current(
                base,
                make_generation(base, "generation-1", marker=b"immutable\n"),
            )
            gateway_port = free_port()

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/status.json", body=b"x")
                response = conn.getresponse()
                response.read()
                self.assertEqual(response.status, 400)
                conn.close()

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/status.json", headers={"Range": "bytes=0-1,4-5"})
                response = conn.getresponse()
                response.read()
                self.assertEqual(response.status, 400)
                conn.close()

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/status.json", headers={"Range": "bytes=999-1000"})
                response = conn.getresponse()
                response.read()
                headers = {key.lower(): value for key, value in response.getheaders()}
                self.assertEqual(response.status, 416)
                self.assertIn("content-range", headers)
                conn.close()

    def test_single_range_head_and_etag_revalidation(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            current = point_current(
                base,
                make_generation(base, "generation-1", marker=b"immutable\n"),
            )
            gateway_port = free_port()

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request(
                    "GET",
                    "/releases/v0.14.0/centl.tar.gz",
                    headers={"Range": "bytes=2-5"},
                )
                response = conn.getresponse()
                body = response.read()
                headers = {key.lower(): value for key, value in response.getheaders()}
                conn.close()
                self.assertEqual(response.status, 206)
                self.assertEqual(body, b"2345")
                self.assertEqual(headers.get("content-range"), "bytes 2-5/16")

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("HEAD", "/releases/v0.14.0/centl.tar.gz")
                response = conn.getresponse()
                body = response.read()
                head_headers = {key.lower(): value for key, value in response.getheaders()}
                conn.close()
                self.assertEqual(response.status, 200)
                self.assertEqual(body, b"")
                self.assertEqual(head_headers.get("content-length"), "16")

                etag = head_headers["etag"]
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request(
                    "GET",
                    "/releases/v0.14.0/centl.tar.gz",
                    headers={"If-None-Match": etag},
                )
                response = conn.getresponse()
                body = response.read()
                conn.close()
                self.assertEqual(response.status, 304)
                self.assertEqual(body, b"")

    def test_writable_objects_and_internal_symlinks_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            generation = make_generation(base, "generation-1", marker=b"immutable\n")

            writable = generation / "semantic" / "writable.bin"
            (generation / "semantic").chmod(0o755)
            writable.write_bytes(b"must-not-serve")
            writable.chmod(0o644)
            (generation / "semantic").chmod(0o555)

            link = generation / "releases" / "escape"
            (generation / "releases").chmod(0o755)
            link.symlink_to("/etc/passwd")
            (generation / "releases").chmod(0o555)

            current = point_current(base, generation)
            gateway_port = free_port()
            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                for path in ("/semantic/writable.bin", "/releases/escape"):
                    conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                    conn.request("GET", path)
                    response = conn.getresponse()
                    response.read()
                    conn.close()
                    self.assertEqual(response.status, 404, msg=path)

    def test_live_selector_cannot_escape_or_use_untrusted_anchor(self) -> None:
        with tempfile.TemporaryDirectory() as td, tempfile.TemporaryDirectory() as outside_td:
            base = Path(td)
            outside = make_generation(
                Path(outside_td), "outside-generation", marker=b"must-not-serve\n"
            )
            current = point_current(base, outside)
            gateway_port = free_port()

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/")
                response = conn.getresponse()
                response.read()
                conn.close()
                self.assertEqual(response.status, 404)

            inside = make_generation(base, "inside-generation", marker=b"inside\n")
            point_current(base, inside)
            base.chmod(0o777)
            try:
                gateway_port = free_port()
                with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                    conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                    conn.request("GET", "/")
                    response = conn.getresponse()
                    response.read()
                    conn.close()
                    self.assertEqual(response.status, 404)
            finally:
                base.chmod(0o700)

    def test_atomic_current_switch_changes_generation_without_reconfiguring_daemon(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            first = make_generation(base, "generation-1", marker=b"first\n")
            second = make_generation(base, "generation-2", marker=b"second\n")
            current = point_current(base, first)
            gateway_port = free_port()

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/")
                response = conn.getresponse()
                self.assertEqual(response.read(), b"first\n")
                conn.close()

                point_current(base, second)

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/")
                response = conn.getresponse()
                self.assertEqual(response.read(), b"second\n")
                conn.close()


class TorCarrierTests(unittest.TestCase):
    def test_config_is_private_single_service_and_no_socks_proxy(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            config = TorOnionConfig(state_dir=Path(td) / "tor")
            carrier = TorOnionCarrier(config)
            torrc = carrier.render_torrc()
            self.assertIn("SocksPort 0", torrc)
            self.assertIn("DataDirectory ", torrc)
            self.assertIn("HiddenServiceVersion 3", torrc)
            self.assertIn("HiddenServicePort 80 127.0.0.1:8790", torrc)
            self.assertNotIn("ExitRelay", torrc)
            self.assertNotIn("ORPort", torrc)

        with self.assertRaises(ValueError):
            TorOnionConfig(telepathy_host="::1")
        with self.assertRaises(ValueError):
            TorOnionConfig(state_dir=Path("/tmp/fcf\nSocksPort 9050"))

    def test_publish_requires_live_gateway(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            fake = Path(td) / "tor"
            write_fake_tor(fake)
            carrier = TorOnionCarrier(
                TorOnionConfig(
                    telepathy_port=free_port(),
                    tor_binary=str(fake),
                    state_dir=Path(td) / "state",
                    gateway_probe_timeout=0.1,
                )
            )
            with self.assertRaises(CarrierError):
                carrier.publish()

    def test_publish_refuses_an_unidentified_loopback_service(self) -> None:
        with tempfile.TemporaryDirectory() as td, RunningTCP() as not_telepathy:
            fake = Path(td) / "tor"
            write_fake_tor(fake)
            carrier = TorOnionCarrier(
                TorOnionConfig(
                    telepathy_port=not_telepathy.port,
                    tor_binary=str(fake),
                    state_dir=Path(td) / "state",
                    gateway_probe_timeout=0.5,
                )
            )
            with self.assertRaises(CarrierError):
                carrier.publish()

    @unittest.skipUnless(Path("/proc/self/cmdline").exists(), "Linux /proc identity check required")
    def test_fake_tor_publish_status_and_withdraw_offline(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            current = point_current(
                base,
                make_generation(base, "generation-1", marker=b"carrier-ready\n"),
            )
            gateway_port = free_port()
            fake = base / "tor"
            write_fake_tor(fake)
            config = TorOnionConfig(
                telepathy_port=gateway_port,
                tor_binary=str(fake),
                state_dir=base / "state",
                startup_timeout=3.0,
            )

            with TelepathyGateway(gateway_config(current, listen_port=gateway_port)):
                first = TorOnionCarrier(config)
                published = first.publish()
                self.assertTrue(published.published)
                self.assertEqual(published.endpoint, "a" * 56 + ".onion")

                recovered = TorOnionCarrier(config)
                status = recovered.status()
                self.assertTrue(status.published)
                self.assertEqual(status.pid, published.pid)
                recovered.withdraw()

            deadline = time.monotonic() + 2.0
            while published.pid is not None and deadline > time.monotonic():
                try:
                    os.kill(published.pid, 0)
                except ProcessLookupError:
                    break
                time.sleep(0.05)
            self.assertFalse(config.pid_path.exists())
            self.assertTrue((config.hidden_service_dir / "hostname").exists())

    @unittest.skipUnless(Path("/proc/self/cmdline").exists(), "Linux /proc identity check required")
    def test_stale_pid_record_cannot_kill_unrelated_process(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            fake = Path(td) / "tor"
            write_fake_tor(fake)
            config = TorOnionConfig(tor_binary=str(fake), state_dir=Path(td) / "state")
            config.state_dir.mkdir(parents=True)
            sleeper = subprocess.Popen(["sleep", "30"])
            try:
                config.pid_path.write_text(f"{sleeper.pid}\n", encoding="ascii")
                carrier = TorOnionCarrier(config)
                with self.assertRaises(CarrierError):
                    carrier.withdraw()
                self.assertIsNone(sleeper.poll())
            finally:
                sleeper.terminate()
                sleeper.wait(timeout=3.0)


class NamingAndCLITests(unittest.TestCase):
    def test_one_public_software_name(self) -> None:
        self.assertFalse((ROOT / "scripts" / "telepathyctl").exists())
        for path in [SCRIPT, DOC, *sorted((ROOT / "telepathy").glob("*.py"))]:
            text = path.read_text(encoding="utf-8")
            self.assertNotIn("telepathic-camel", text, msg=str(path))

    def test_cli_help_runs_from_repository_root(self) -> None:
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--help"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("fcf-telepathyd", result.stdout)
        self.assertIn("carrier", result.stdout)
        self.assertIn("serve", result.stdout)

        serve_help = subprocess.run(
            [sys.executable, str(SCRIPT), "serve", "--help"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(serve_help.returncode, 0, msg=serve_help.stderr)
        self.assertIn("--caravan-live-root", serve_help.stdout)
        self.assertNotIn("--upstream-host", serve_help.stdout)
        self.assertNotIn("--upstream-port", serve_help.stdout)


if __name__ == "__main__":
    unittest.main()
