"""Outbound-only carrier/coordinator HTTP transport for the Phase 1 laboratory.

The carrier client never opens a listening socket. The coordinator test service
is deliberately loopback-only and plaintext HTTP is accepted only for that local
laboratory boundary. Internet-facing transport remains HTTPS-only.
"""

from __future__ import annotations

import base64
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import math
import threading
import time
from typing import Any
from urllib import error as urlerror
from urllib import request as urlrequest
from urllib.parse import urlparse

from .coordinator import CoordinatorError, CoordinatorState
from .identity import CarrierIdentity
from .session import SessionAuthority, SessionError, session_proof_payload

MAX_REQUEST_BYTES = 64 * 1024
MAX_RESPONSE_BYTES = 64 * 1024
MAX_LAB_POLL_SECONDS = 2.0


class TransportError(RuntimeError):
    """Raised when a CARAVAN laboratory transport request fails."""


def _b64url_encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def _b64url_decode(text: object) -> bytes:
    if not isinstance(text, str) or not text:
        raise TransportError("signature must be non-empty base64url text")
    try:
        padded = text + "=" * ((4 - len(text) % 4) % 4)
        return base64.urlsafe_b64decode(padded.encode("ascii"))
    except Exception as exc:
        raise TransportError("invalid base64url signature") from exc


def _validate_client_base_url(url: str, *, allow_loopback_http: bool) -> str:
    parsed = urlparse(url)
    if parsed.scheme == "https" and parsed.netloc:
        return url.rstrip("/")
    if (
        allow_loopback_http
        and parsed.scheme == "http"
        and parsed.hostname in {"127.0.0.1", "::1", "localhost"}
    ):
        return url.rstrip("/")
    raise TransportError("CARAVAN coordinator URL must use HTTPS outside loopback lab mode")


def _require_exact_fields(value: object, expected: set[str]) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != expected:
        raise TransportError("request fields do not match endpoint schema")
    return value


class _CoordinatorHTTPServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(
        self,
        server_address: tuple[str, int],
        coordinator: CoordinatorState,
        sessions: SessionAuthority,
    ) -> None:
        if server_address[0] != "127.0.0.1":
            raise TransportError("Phase 1 coordinator HTTP service is loopback-only")
        self.coordinator = coordinator
        self.sessions = sessions
        super().__init__(server_address, _CoordinatorHandler)


class _CoordinatorHandler(BaseHTTPRequestHandler):
    server: _CoordinatorHTTPServer
    server_version = "CENTL-CARAVAN-LAB"
    sys_version = ""

    def log_message(self, format: str, *args: object) -> None:
        # Do not emit client addresses or request paths into default HTTP logs.
        return

    def _json_response(self, status: int, value: dict[str, object]) -> None:
        payload = (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode(
            "utf-8"
        )
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    def _failure(self, status: int, code: str) -> None:
        self._json_response(status, {"error": code})

    def _read_json(self) -> dict[str, Any]:
        raw_length = self.headers.get("Content-Length")
        if raw_length is None:
            raise TransportError("Content-Length is required")
        try:
            length = int(raw_length)
        except ValueError as exc:
            raise TransportError("invalid Content-Length") from exc
        if length < 0 or length > MAX_REQUEST_BYTES:
            raise TransportError("request body exceeds CARAVAN laboratory limit")
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
        return self.server.sessions.authenticate(authorization[len(prefix) :])

    def do_POST(self) -> None:  # noqa: N802
        try:
            body = self._read_json()
            if self.path == "/v1/session/challenge":
                request = _require_exact_fields(body, {"node_id"})
                node_id = request["node_id"]
                if not isinstance(node_id, str):
                    raise TransportError("node_id must be text")
                challenge = self.server.sessions.issue_challenge(node_id)
                self._json_response(
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
                    body,
                    {"node_id", "challenge_id", "challenge", "signature"},
                )
                node_id = request["node_id"]
                challenge_id = request["challenge_id"]
                challenge = request["challenge"]
                if not all(isinstance(value, str) for value in (node_id, challenge_id, challenge)):
                    raise TransportError("session completion fields must be text")
                session = self.server.sessions.complete_challenge(
                    node_id=node_id,
                    challenge_id=challenge_id,
                    challenge=challenge,
                    signature=_b64url_decode(request["signature"]),
                )
                self._json_response(
                    200,
                    {"session_token": session.token, "expires_at": session.expires_at},
                )
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
                    or not isinstance(capacity, int)
                    or isinstance(capacity, bool)
                    or capacity < 0
                ):
                    raise TransportError("invalid carrier load/capacity")
                self.server.coordinator.heartbeat(
                    node_id,
                    load=float(load),
                    capacity=capacity,
                )
                self._json_response(200, {"status": "ok"})
                return

            if self.path == "/v1/carrier/advertise":
                request = _require_exact_fields(body, {"artifact_id"})
                artifact_id = request["artifact_id"]
                if not isinstance(artifact_id, str):
                    raise TransportError("artifact_id must be text")
                self.server.coordinator.advertise_replica(node_id, artifact_id)
                self._json_response(200, {"status": "ok"})
                return

            if self.path == "/v1/carrier/poll":
                request = _require_exact_fields(body, {"wait_seconds"})
                wait_seconds = request["wait_seconds"]
                if (
                    not isinstance(wait_seconds, (int, float))
                    or isinstance(wait_seconds, bool)
                    or not math.isfinite(float(wait_seconds))
                    or float(wait_seconds) < 0
                    or float(wait_seconds) > MAX_LAB_POLL_SECONDS
                ):
                    raise TransportError("invalid laboratory poll duration")
                if float(wait_seconds) > 0:
                    time.sleep(float(wait_seconds))
                    # The carrier may have been quarantined during the wait.
                    self.server.sessions.authenticate(
                        self.headers["Authorization"][len("Bearer ") :]
                    )
                self._json_response(
                    200,
                    {"commands": [], "retry_after_seconds": 1.0},
                )
                return

            self._failure(404, "not_found")
        except SessionError:
            self._failure(401, "unauthorized")
        except CoordinatorError:
            self._failure(409, "coordinator_rejected")
        except (TransportError, ValueError, TypeError):
            self._failure(400, "bad_request")
        except (BrokenPipeError, ConnectionResetError):
            return

    def do_GET(self) -> None:  # noqa: N802
        self._failure(405, "method_not_allowed")


class CoordinatorLabService:
    """Loopback-only coordinator HTTP service used by Phase 1 integration tests."""

    def __init__(
        self,
        coordinator: CoordinatorState,
        *,
        sessions: SessionAuthority | None = None,
        port: int = 0,
    ) -> None:
        self.sessions = sessions or SessionAuthority(coordinator)
        self._server = _CoordinatorHTTPServer(("127.0.0.1", port), coordinator, self.sessions)
        self._thread: threading.Thread | None = None

    @property
    def base_url(self) -> str:
        host, port = self._server.server_address[:2]
        return f"http://{host}:{port}"

    def start(self) -> "CoordinatorLabService":
        if self._thread is not None:
            raise TransportError("coordinator laboratory service already started")
        self._thread = threading.Thread(
            target=self._server.serve_forever,
            name="centl-caravan-lab-coordinator",
            daemon=True,
        )
        self._thread.start()
        return self

    def close(self) -> None:
        self._server.shutdown()
        self._server.server_close()
        if self._thread is not None:
            self._thread.join(timeout=5)
            self._thread = None

    def __enter__(self) -> "CoordinatorLabService":
        return self.start()

    def __exit__(self, exc_type, exc, traceback) -> None:
        self.close()


class CarrierTransportClient:
    """Carrier-side outbound HTTP client: it never binds a listening socket."""

    def __init__(
        self,
        coordinator_url: str,
        identity: CarrierIdentity,
        *,
        allow_loopback_http: bool = False,
        timeout: float = 5.0,
    ) -> None:
        if timeout <= 0:
            raise ValueError("transport timeout must be positive")
        self.coordinator_url = _validate_client_base_url(
            coordinator_url,
            allow_loopback_http=allow_loopback_http,
        )
        self.identity = identity
        self.timeout = float(timeout)
        self._session_token: str | None = None

    def _post(
        self,
        path: str,
        value: dict[str, object],
        *,
        authenticated: bool = False,
    ) -> dict[str, Any]:
        payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        if authenticated:
            if self._session_token is None:
                raise TransportError("carrier session has not been established")
            headers["Authorization"] = "Bearer " + self._session_token
        request = urlrequest.Request(
            self.coordinator_url + path,
            data=payload,
            headers=headers,
            method="POST",
        )
        try:
            with urlrequest.urlopen(request, timeout=self.timeout) as response:
                data = response.read(MAX_RESPONSE_BYTES + 1)
        except urlerror.HTTPError as exc:
            raise TransportError(f"coordinator rejected request with HTTP {exc.code}") from exc
        except (urlerror.URLError, TimeoutError, OSError) as exc:
            raise TransportError("coordinator request failed") from exc
        if len(data) > MAX_RESPONSE_BYTES:
            raise TransportError("coordinator response exceeds laboratory limit")
        try:
            result = json.loads(data.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise TransportError("coordinator returned invalid JSON") from exc
        if not isinstance(result, dict):
            raise TransportError("coordinator response must be a JSON object")
        return result

    def connect(self) -> None:
        challenge = self._post(
            "/v1/session/challenge",
            {"node_id": self.identity.node_id},
        )
        try:
            challenge_id = challenge["challenge_id"]
            challenge_value = challenge["challenge"]
        except KeyError as exc:
            raise TransportError("coordinator challenge response is incomplete") from exc
        if not isinstance(challenge_id, str) or not isinstance(challenge_value, str):
            raise TransportError("coordinator challenge response has invalid types")
        signature = self.identity.sign(
            session_proof_payload(
                self.identity.node_id,
                challenge_id,
                challenge_value,
            )
        )
        completed = self._post(
            "/v1/session/complete",
            {
                "node_id": self.identity.node_id,
                "challenge_id": challenge_id,
                "challenge": challenge_value,
                "signature": _b64url_encode(signature),
            },
        )
        token = completed.get("session_token")
        if not isinstance(token, str) or not token:
            raise TransportError("coordinator did not return a carrier session")
        self._session_token = token

    def heartbeat(self, *, load: float, capacity: int) -> None:
        self._post(
            "/v1/carrier/heartbeat",
            {"load": load, "capacity": capacity},
            authenticated=True,
        )

    def advertise(self, artifact_id: str) -> None:
        self._post(
            "/v1/carrier/advertise",
            {"artifact_id": artifact_id},
            authenticated=True,
        )

    def poll(self, *, wait_seconds: float = 0.0) -> list[object]:
        response = self._post(
            "/v1/carrier/poll",
            {"wait_seconds": wait_seconds},
            authenticated=True,
        )
        commands = response.get("commands")
        if not isinstance(commands, list):
            raise TransportError("coordinator poll response has invalid commands")
        return commands

    def disconnect(self) -> None:
        self._session_token = None
