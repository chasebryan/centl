"""Bounded public CARAVAN coordinator service.

The service is intentionally designed to listen on loopback and sit behind a
TLS-capable edge such as Tailscale Funnel.  It exposes only the authenticated
carrier lifecycle endpoints and the aggregate census document.  It never
logs request paths or client addresses and never serves the coordinator
database or carrier identities.
"""

from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import math
from pathlib import Path
import threading
import time
from typing import Any

from .census import build_live_document
from .coordinator import CoordinatorError, CoordinatorState
from .enrollment_protocol import EnrollmentAuthority, EnrollmentProtocolError
from .observability import ObservabilityStore
from .session import SessionAuthority, SessionError
from .transport import (
    MAX_CONCURRENT_REQUESTS,
    MAX_REQUEST_BYTES,
    MAX_RESPONSE_BYTES,
    TransportError,
    _b64url_decode,
)


class PublicServiceError(RuntimeError):
    """Raised when the public service cannot be safely configured."""


def _require_exact_fields(value: object, expected: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != expected:
        raise TransportError("request fields do not match endpoint schema")
    return value


class _PublicHTTPServer(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = MAX_CONCURRENT_REQUESTS

    def __init__(
        self,
        address: tuple[str, int],
        coordinator: CoordinatorState,
        sessions: SessionAuthority,
        enrollment: EnrollmentAuthority,
        *,
        max_concurrent_requests: int = MAX_CONCURRENT_REQUESTS,
    ) -> None:
        if address[0] not in {"127.0.0.1", "::1", "localhost"}:
            raise PublicServiceError("public coordinator must bind to loopback behind a TLS edge")
        if max_concurrent_requests <= 0:
            raise ValueError("max_concurrent_requests must be positive")
        self.coordinator = coordinator
        self.sessions = sessions
        self.enrollment = enrollment
        self.observability = ObservabilityStore(coordinator.database)
        self.max_concurrent_requests = int(max_concurrent_requests)
        self._active_requests = 0
        self._active_requests_lock = threading.Lock()
        super().__init__(address, _PublicHandler)

    @property
    def active_requests(self) -> int:
        with self._active_requests_lock:
            return self._active_requests

    def _reserve_request(self) -> bool:
        with self._active_requests_lock:
            if self._active_requests >= self.max_concurrent_requests:
                return False
            self._active_requests += 1
            return True

    def _release_request(self) -> None:
        with self._active_requests_lock:
            self._active_requests = max(0, self._active_requests - 1)

    def process_request(self, request, client_address) -> None:
        if not self._reserve_request():
            try:
                request.sendall(
                    b"HTTP/1.1 503 Service Unavailable\r\n"
                    b"Content-Length: 0\r\n"
                    b"Cache-Control: no-store\r\n"
                    b"Connection: close\r\n\r\n"
                )
            except OSError:
                pass
            finally:
                self.shutdown_request(request)
            return
        try:
            super().process_request(request, client_address)
        except BaseException:
            self._release_request()
            raise

    def process_request_thread(self, request, client_address) -> None:
        try:
            super().process_request_thread(request, client_address)
        finally:
            self._release_request()


class _PublicHandler(BaseHTTPRequestHandler):
    server: _PublicHTTPServer
    server_version = "CENTL-CARAVAN"
    sys_version = ""

    def setup(self) -> None:
        super().setup()
        self.connection.settimeout(15.0)

    def log_message(self, format: str, *args: object) -> None:
        # Deliberately discard the default client-address/path log record.
        return

    def _send_json(
        self,
        status: int,
        value: dict[str, object],
        *,
        cache: str = "no-store",
        public_read: bool = False,
    ) -> None:
        payload = (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
            "utf-8"
        )
        if len(payload) > MAX_RESPONSE_BYTES:
            self._send_error(500, "response_too_large")
            return
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", cache)
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Strict-Transport-Security", "max-age=31536000")
        if public_read:
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Vary", "Origin")
        self.end_headers()
        self.wfile.write(payload)

    def _send_error(self, status: int, code: str) -> None:
        self._send_json(status, {"error": code})

    def _read_json(self) -> dict[str, Any]:
        raw_length = self.headers.get("Content-Length")
        if raw_length is None:
            raise TransportError("Content-Length is required")
        try:
            length = int(raw_length)
        except ValueError as exc:
            raise TransportError("invalid Content-Length") from exc
        if length < 0 or length > MAX_REQUEST_BYTES:
            raise TransportError("request body exceeds public CARAVAN limit")
        body = self.rfile.read(length)
        if len(body) != length:
            raise TransportError("truncated request body")
        try:
            value = json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise TransportError("request body is not valid UTF-8 JSON") from exc
        if not isinstance(value, dict):
            raise TransportError("request body must be a JSON object")
        return value

    def _session_node(self) -> str:
        authorization = self.headers.get("Authorization", "")
        prefix = "Bearer "
        if not authorization.startswith(prefix):
            raise SessionError("missing carrier session")
        token = authorization[len(prefix) :]
        if not token or len(token) > 256:
            raise SessionError("invalid carrier session")
        return self.server.sessions.authenticate(token)

    def do_GET(self) -> None:  # noqa: N802
        try:
            if self.path == "/healthz":
                self._send_json(200, {"schema": "fcf-caravan-health-v1", "status": "ok"})
                return
            if self.path == "/census-v1.json":
                self._send_json(
                    200,
                    build_live_document(self.server.coordinator),
                    cache="no-cache",
                    public_read=True,
                )
                return
            self._send_error(404, "not_found")
        except (OSError, ValueError, RuntimeError):
            self._send_error(503, "service_unavailable")

    def do_POST(self) -> None:  # noqa: N802
        is_enrollment = self.path == "/v1/enroll"
        if is_enrollment:
            self.server.observability.increment("enrollment_requests")
        try:
            body = self._read_json()
            if is_enrollment:
                request = _require_exact_fields(body, {"receipt"})
                result = self.server.enrollment.enroll(request["receipt"])
                self.server.observability.increment("enrollment_accepted")
                self._send_json(200, result)
                return

            if self.path == "/v1/session/challenge":
                request = _require_exact_fields(body, {"node_id"})
                node_id = request["node_id"]
                if not isinstance(node_id, str) or not node_id:
                    raise TransportError("node_id must be non-empty text")
                challenge = self.server.sessions.issue_challenge(node_id)
                self.server.observability.increment("session_challenges_issued")
                self._send_json(
                    200,
                    {
                        "challenge_id": challenge.challenge_id,
                        "challenge": challenge.challenge,
                        "expires_at": challenge.expires_at,
                    },
                )
                return

            if self.path == "/v1/session/complete":
                request = _require_exact_fields(
                    body, {"node_id", "challenge_id", "challenge", "signature"}
                )
                node_id = request["node_id"]
                challenge_id = request["challenge_id"]
                challenge = request["challenge"]
                if not all(isinstance(value, str) and value for value in (node_id, challenge_id, challenge)):
                    raise TransportError("session completion fields must be non-empty text")
                session = self.server.sessions.complete_challenge(
                    node_id=node_id,
                    challenge_id=challenge_id,
                    challenge=challenge,
                    signature=_b64url_decode(request["signature"]),
                )
                self.server.observability.increment("session_completions_succeeded")
                self._send_json(200, {"session_token": session.token, "expires_at": session.expires_at})
                return

            node_id = self._session_node()
            if self.path == "/v1/carrier/heartbeat":
                request = _require_exact_fields(body, {"load", "capacity"})
                load = request["load"]
                capacity = request["capacity"]
                if (
                    not isinstance(load, (int, float))
                    or isinstance(load, bool)
                    or not math.isfinite(float(load))
                    or float(load) < 0
                    or float(load) > 1
                    or not isinstance(capacity, int)
                    or isinstance(capacity, bool)
                    or capacity < 0
                ):
                    raise TransportError("invalid carrier load/capacity")
                self.server.coordinator.heartbeat(node_id, load=float(load), capacity=capacity)
                self.server.observability.record_first_heartbeat(node_id)
                self._send_json(200, {"status": "ok"})
                return

            if self.path == "/v1/carrier/withdraw":
                _require_exact_fields(body, set())
                result = self.server.enrollment.withdraw(node_id)
                self._send_json(200, result)
                return

            self._send_error(404, "not_found")
        except SessionError:
            self._send_error(401, "unauthorized")
        except EnrollmentProtocolError:
            if is_enrollment:
                self.server.observability.increment("enrollment_rejected")
            self._send_error(403, "enrollment_rejected")
        except CoordinatorError:
            self._send_error(409, "coordinator_rejected")
        except (TransportError, ValueError, TypeError, KeyError):
            if is_enrollment:
                self.server.observability.increment("enrollment_rejected")
            self._send_error(400, "bad_request")
        except (BrokenPipeError, ConnectionResetError, TimeoutError):
            return


class PublicCoordinatorService:
    """Lifecycle wrapper for the loopback-bound public coordinator."""

    def __init__(
        self,
        coordinator: CoordinatorState,
        *,
        policy_path: str | Path,
        policy_version: str,
        allowed_agent_versions: set[str] | frozenset[str],
        port: int = 8789,
        max_concurrent_requests: int = MAX_CONCURRENT_REQUESTS,
    ) -> None:
        sessions = SessionAuthority(coordinator)
        enrollment = EnrollmentAuthority(
            coordinator,
            sessions,
            policy_path=policy_path,
            policy_version=policy_version,
            allowed_agent_versions=allowed_agent_versions,
        )
        self._server = _PublicHTTPServer(
            ("127.0.0.1", port),
            coordinator,
            sessions,
            enrollment,
            max_concurrent_requests=max_concurrent_requests,
        )
        self._thread: threading.Thread | None = None

    @property
    def address(self) -> tuple[str, int]:
        return self._server.server_address[:2]

    def serve_forever(self) -> None:
        self._server.serve_forever()

    def close(self) -> None:
        self._server.shutdown()
        self._server.server_close()
        if self._thread is not None:
            self._thread.join(timeout=5)
            self._thread = None


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the loopback-bound FCF CARAVAN public coordinator")
    parser.add_argument("--database", type=Path, required=True)
    parser.add_argument("--policy", type=Path, required=True)
    parser.add_argument("--policy-version", default="FCF-CARAVAN-HOST-v1")
    parser.add_argument("--agent-version", action="append", required=True)
    parser.add_argument("--port", type=int, default=8789)
    args = parser.parse_args()
    if not args.policy.is_file() or args.policy.is_symlink():
        raise SystemExit("public coordinator policy must be a real file")
    coordinator = CoordinatorState(args.database, heartbeat_ttl=1800.0)
    service = PublicCoordinatorService(
        coordinator,
        policy_path=args.policy,
        policy_version=args.policy_version,
        allowed_agent_versions=set(args.agent_version),
        port=args.port,
    )
    host, port = service.address
    print(f"FCF CARAVAN public coordinator listening on {host}:{port}", flush=True)
    try:
        service.serve_forever()
    except KeyboardInterrupt:
        return 0
    finally:
        service.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
