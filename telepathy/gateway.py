from __future__ import annotations

from dataclasses import dataclass
from http.client import HTTPConnection, HTTPException
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import ipaddress
import re
import threading
from typing import ClassVar

from .policy import PolicyError, PublicReadPolicy


_SAFE_REQUEST_HEADERS = {
    "accept",
    "if-modified-since",
    "if-none-match",
    "range",
}
_SAFE_RESPONSE_HEADERS = {
    "accept-ranges",
    "cache-control",
    "content-length",
    "content-range",
    "content-type",
    "etag",
    "last-modified",
}
_SINGLE_RANGE = re.compile(r"bytes=(?:[0-9]+-[0-9]*|-[0-9]+)\Z")


def _require_loopback_literal(host: str, *, field: str) -> None:
    try:
        address = ipaddress.ip_address(host)
    except ValueError as exc:
        raise ValueError(f"{field} must be an IPv4 loopback literal") from exc
    if not isinstance(address, ipaddress.IPv4Address) or not address.is_loopback:
        raise ValueError(f"{field} must be an IPv4 loopback literal")


def _require_port(port: int, *, field: str) -> None:
    if not 1 <= port <= 65535:
        raise ValueError(f"{field} must be between 1 and 65535")


@dataclass(frozen=True)
class GatewayConfig:
    listen_host: str = "127.0.0.1"
    listen_port: int = 8790
    upstream_host: str = "127.0.0.1"
    upstream_port: int = 8787
    upstream_timeout: float = 10.0
    max_workers: int = 32

    def __post_init__(self) -> None:
        _require_loopback_literal(self.listen_host, field="listen_host")
        _require_loopback_literal(self.upstream_host, field="upstream_host")
        _require_port(self.listen_port, field="listen_port")
        _require_port(self.upstream_port, field="upstream_port")
        if self.upstream_timeout <= 0:
            raise ValueError("upstream_timeout must be positive")
        if not 1 <= self.max_workers <= 256:
            raise ValueError("max_workers must be between 1 and 256")


class _TelepathyHTTPServer(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 16
    allow_reuse_address = True

    def __init__(
        self,
        server_address: tuple[str, int],
        handler: type[BaseHTTPRequestHandler],
        max_workers: int,
    ) -> None:
        self._worker_slots = threading.BoundedSemaphore(max_workers)
        super().__init__(server_address, handler)

    def process_request(self, request: object, client_address: object) -> None:
        if not self._worker_slots.acquire(blocking=False):
            try:
                request.close()  # type: ignore[attr-defined]
            finally:
                return
        try:
            super().process_request(request, client_address)
        except BaseException:
            self._worker_slots.release()
            raise

    def process_request_thread(self, request: object, client_address: object) -> None:
        try:
            super().process_request_thread(request, client_address)
        finally:
            self._worker_slots.release()


class TelepathyGateway:
    """Fixed-destination, read-only gateway between a carrier and CARAVAN."""

    def __init__(
        self,
        config: GatewayConfig | None = None,
        policy: PublicReadPolicy | None = None,
    ) -> None:
        self.config = config or GatewayConfig()
        self.policy = policy or PublicReadPolicy()
        self._server: _TelepathyHTTPServer | None = None
        self._thread: threading.Thread | None = None

    @property
    def address(self) -> tuple[str, int]:
        if self._server is None:
            return self.config.listen_host, self.config.listen_port
        host, port = self._server.server_address[:2]
        return str(host), int(port)

    def _handler_type(self) -> type[BaseHTTPRequestHandler]:
        config = self.config
        policy = self.policy

        class Handler(BaseHTTPRequestHandler):
            server_version: ClassVar[str] = "fcf-telepathyd/0.1-mirage"
            sys_version = ""

            def log_message(self, _format: str, *args: object) -> None:
                return

            def _deny(self, status: int, message: str) -> None:
                body = (message + "\n").encode("utf-8")
                self.send_response(status)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Cache-Control", "no-store")
                self.send_header("Connection", "close")
                self.end_headers()
                self.close_connection = True
                if self.command != "HEAD":
                    self.wfile.write(body)

            def _request_shape_allowed(self) -> bool:
                transfer_values = self.headers.get_all("Transfer-Encoding", []) or []
                if transfer_values:
                    self._deny(400, "transfer-encoded requests are forbidden")
                    return False

                expect_values = self.headers.get_all("Expect", []) or []
                if expect_values:
                    self._deny(400, "expectation requests are forbidden")
                    return False

                length_values = self.headers.get_all("Content-Length", []) or []
                if len(length_values) > 1:
                    self._deny(400, "ambiguous content length is forbidden")
                    return False
                if length_values:
                    try:
                        parsed = int(length_values[0], 10)
                    except ValueError:
                        self._deny(400, "invalid content length")
                        return False
                    if parsed != 0:
                        self._deny(400, "request bodies are forbidden")
                        return False

                range_values = self.headers.get_all("Range", []) or []
                if len(range_values) > 1:
                    self._deny(400, "multiple range headers are forbidden")
                    return False
                if range_values and _SINGLE_RANGE.fullmatch(range_values[0].strip()) is None:
                    self._deny(400, "only one canonical byte range is permitted")
                    return False
                return True

            def _forward(self) -> None:
                if not self._request_shape_allowed():
                    return
                try:
                    path = policy.authorize(self.command, self.path)
                except PolicyError as exc:
                    status = 405 if "method not permitted" in str(exc) else 403
                    self._deny(status, "fcf-telepathyd policy denied request")
                    return

                request_headers = {
                    key: value
                    for key, value in self.headers.items()
                    if key.lower() in _SAFE_REQUEST_HEADERS
                }

                connection = HTTPConnection(
                    config.upstream_host,
                    config.upstream_port,
                    timeout=config.upstream_timeout,
                )
                try:
                    connection.request(self.command, path, headers=request_headers)
                    response = connection.getresponse()
                    if 300 <= response.status < 400 and response.status != 304:
                        response.read()
                        self._deny(502, "upstream redirects are forbidden")
                        return

                    self.send_response(response.status)
                    for key, value in response.getheaders():
                        if key.lower() in _SAFE_RESPONSE_HEADERS:
                            self.send_header(key, value)
                    self.send_header("Connection", "close")
                    self.end_headers()
                    self.close_connection = True
                    if self.command != "HEAD":
                        while True:
                            chunk = response.read(64 * 1024)
                            if not chunk:
                                break
                            self.wfile.write(chunk)
                except (OSError, TimeoutError, HTTPException):
                    if not self.wfile.closed:
                        try:
                            self._deny(502, "CARAVAN loopback endpoint unavailable")
                        except (BrokenPipeError, ConnectionResetError):
                            pass
                finally:
                    connection.close()

            do_GET = _forward
            do_HEAD = _forward
            do_POST = _forward
            do_PUT = _forward
            do_DELETE = _forward
            do_PATCH = _forward
            do_OPTIONS = _forward
            do_TRACE = _forward
            do_CONNECT = _forward

        return Handler

    def start(self) -> "TelepathyGateway":
        if self._server is not None:
            raise RuntimeError("fcf-telepathyd gateway is already running")
        self._server = _TelepathyHTTPServer(
            (self.config.listen_host, self.config.listen_port),
            self._handler_type(),
            self.config.max_workers,
        )
        return self

    def serve_forever(self) -> None:
        if self._server is None:
            self.start()
        assert self._server is not None
        self._server.serve_forever(poll_interval=0.25)

    def start_background(self) -> "TelepathyGateway":
        self.start()
        assert self._server is not None
        self._thread = threading.Thread(
            target=self._server.serve_forever,
            kwargs={"poll_interval": 0.1},
            name="fcf-telepathyd",
            daemon=True,
        )
        self._thread.start()
        return self

    def close(self) -> None:
        if self._server is None:
            return
        if self._thread is not None:
            self._server.shutdown()
            self._thread.join(timeout=2.0)
            self._thread = None
        self._server.server_close()
        self._server = None

    def __enter__(self) -> "TelepathyGateway":
        return self.start_background()

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        self.close()
