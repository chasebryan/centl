from __future__ import annotations

from http.client import HTTPConnection
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
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


def make_live_root(base: Path, *, writable_index: bool = False, symlink_index: bool = False) -> Path:
    live = base / "live"
    generation = live / "generations" / "20260812T110000Z-1"
    source = generation / "source"
    source.mkdir(parents=True)
    (generation / "index.html").write_bytes(b"fcf caravan\n")
    if symlink_index:
        (source / "INDEX.json").symlink_to("/etc/passwd")
    else:
        (source / "INDEX.json").write_bytes(b'{"schema":"test"}\n')

    for path in (generation / "index.html", source / "INDEX.json"):
        if not path.is_symlink():
            path.chmod(0o644 if writable_index and path.name == "INDEX.json" else 0o444)
    source.chmod(0o555)
    generation.chmod(0o555)
    (live / "current").symlink_to(Path("generations") / generation.name)
    return live / "current"


class OriginHandler(BaseHTTPRequestHandler):
    calls: list[tuple[str, str]] = []
    last_headers: dict[str, str] = {}

    def log_message(self, _format: str, *args: object) -> None:
        return

    def _record(self) -> None:
        type(self).calls.append((self.command, self.path))
        type(self).last_headers = {key.lower(): value for key, value in self.headers.items()}

    def do_GET(self) -> None:
        self._record()
        if self.path == "/releases/redirect":
            self.send_response(302)
            self.send_header("Location", "https://example.invalid/")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        body = b"approved-caravan-cargo\n"
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Origin-Secret", "must-not-cross")
        self.end_headers()
        self.wfile.write(body)

    def do_HEAD(self) -> None:
        self._record()
        self.send_response(200)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_POST(self) -> None:
        self._record()
        self.send_response(500)
        self.end_headers()


class RunningOrigin:
    def __init__(self) -> None:
        OriginHandler.calls = []
        OriginHandler.last_headers = {}
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), OriginHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    @property
    def port(self) -> int:
        return int(self.server.server_address[1])

    def __enter__(self) -> "RunningOrigin":
        self.thread.start()
        return self

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        self.server.shutdown()
        self.thread.join(timeout=2.0)
        self.server.server_close()


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

    def test_gateway_config_requires_loopback_literals(self) -> None:
        with self.assertRaises(ValueError):
            GatewayConfig(listen_host="0.0.0.0")
        with self.assertRaises(ValueError):
            GatewayConfig(upstream_host="192.0.2.10")
        with self.assertRaises(ValueError):
            GatewayConfig(upstream_host="localhost")
        with self.assertRaises(ValueError):
            GatewayConfig(listen_host="::1")


class GatewayTests(unittest.TestCase):
    def test_allowed_read_reaches_only_fixed_origin_and_strips_headers(self) -> None:
        with RunningOrigin() as origin:
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(
                    listen_port=gateway_port,
                    upstream_port=origin.port,
                )
            ):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request(
                    "GET",
                    "/source/INDEX.json",
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
            self.assertEqual(body, b"approved-caravan-cargo\n")
            self.assertEqual(OriginHandler.calls, [("GET", "/source/INDEX.json")])
            self.assertNotIn("authorization", OriginHandler.last_headers)
            self.assertNotIn("x-forwarded-for", OriginHandler.last_headers)
            self.assertNotEqual(OriginHandler.last_headers.get("host"), "attacker.invalid")
            self.assertNotIn("x-origin-secret", headers)

    def test_denied_method_never_reaches_origin(self) -> None:
        with RunningOrigin() as origin:
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(listen_port=gateway_port, upstream_port=origin.port)
            ):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("POST", "/status.json")
                response = conn.getresponse()
                response.read()
                conn.close()
            self.assertEqual(response.status, 405)
            self.assertEqual(OriginHandler.calls, [])

    def test_request_body_and_multiple_range_are_rejected(self) -> None:
        with RunningOrigin() as origin:
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(listen_port=gateway_port, upstream_port=origin.port)
            ):
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
            self.assertEqual(OriginHandler.calls, [])

    def test_upstream_redirect_is_not_relayed(self) -> None:
        with RunningOrigin() as origin:
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(listen_port=gateway_port, upstream_port=origin.port)
            ):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/releases/redirect")
                response = conn.getresponse()
                response.read()
                headers = {key.lower(): value for key, value in response.getheaders()}
                conn.close()
            self.assertEqual(response.status, 502)
            self.assertNotIn("location", headers)


class LiveRootGatewayTests(unittest.TestCase):
    def test_atomic_current_symlink_serves_immutable_generation(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            current = make_live_root(Path(td))
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(
                    listen_port=gateway_port,
                    live_root=current,
                    live_root_uid=os.geteuid(),
                )
            ):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/source/INDEX.json")
                response = conn.getresponse()
                body = response.read()
                self.assertEqual(response.status, 200)
                self.assertEqual(body, b'{"schema":"test"}\n')
                self.assertEqual(response.getheader("Accept-Ranges"), "bytes")
                conn.close()

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/source/INDEX.json", headers={"Range": "bytes=0-7"})
                response = conn.getresponse()
                body = response.read()
                self.assertEqual(response.status, 206)
                self.assertEqual(body, b'{"schema')
                self.assertEqual(response.getheader("Content-Range"), "bytes 0-7/18")
                conn.close()

                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("HEAD", "/source/INDEX.json")
                response = conn.getresponse()
                self.assertEqual(response.status, 200)
                self.assertEqual(response.read(), b"")
                conn.close()

    def test_live_root_rejects_symlink_object(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            current = make_live_root(Path(td), symlink_index=True)
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(
                    listen_port=gateway_port,
                    live_root=current,
                    live_root_uid=os.geteuid(),
                )
            ):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/source/INDEX.json")
                response = conn.getresponse()
                response.read()
                conn.close()
            self.assertEqual(response.status, 404)

    def test_live_root_rejects_writable_object(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            current = make_live_root(Path(td), writable_index=True)
            gateway_port = free_port()
            with TelepathyGateway(
                GatewayConfig(
                    listen_port=gateway_port,
                    live_root=current,
                    live_root_uid=os.geteuid(),
                )
            ):
                conn = HTTPConnection("127.0.0.1", gateway_port, timeout=2.0)
                conn.request("GET", "/source/INDEX.json")
                response = conn.getresponse()
                response.read()
                conn.close()
            self.assertEqual(response.status, 404)


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

    @unittest.skipUnless(Path("/proc/self/cmdline").exists(), "Linux /proc identity check required")
    def test_fake_tor_publish_status_and_withdraw_offline(self) -> None:
        with tempfile.TemporaryDirectory() as td, RunningTCP() as gateway:
            fake = Path(td) / "tor"
            write_fake_tor(fake)
            config = TorOnionConfig(
                telepathy_port=gateway.port,
                tor_binary=str(fake),
                state_dir=Path(td) / "state",
                startup_timeout=3.0,
            )
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


if __name__ == "__main__":
    unittest.main()
