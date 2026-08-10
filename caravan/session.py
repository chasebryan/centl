"""Ephemeral authenticated carrier sessions for the CARAVAN laboratory.

Challenges and bearer sessions intentionally live only in coordinator-process
memory: a restart invalidates them. Durable carrier registration remains in the
coordinator database and is policy-gated separately.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import hmac
import json
import secrets
import sqlite3
import threading
import time

from .coordinator import CoordinatorState
from .identity import IdentityError, verify_signature

SESSION_PROOF_SCHEMA = "centl-caravan-session-proof-v1"


class SessionError(RuntimeError):
    """Raised when carrier proof of possession or session use fails."""


@dataclass(frozen=True, slots=True)
class SessionChallenge:
    challenge_id: str
    challenge: str
    expires_at: float


@dataclass(frozen=True, slots=True)
class CarrierSession:
    token: str
    node_id: str
    expires_at: float


@dataclass(slots=True)
class _ChallengeState:
    node_id: str
    challenge_hash: str
    expires_at: float


@dataclass(slots=True)
class _SessionState:
    node_id: str
    expires_at: float


def session_proof_payload(node_id: str, challenge_id: str, challenge: str) -> bytes:
    if not node_id or not challenge_id or not challenge:
        raise ValueError("session proof fields must be non-empty")
    return json.dumps(
        {
            "schema": SESSION_PROOF_SCHEMA,
            "node_id": node_id,
            "challenge_id": challenge_id,
            "challenge": challenge,
        },
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
        allow_nan=False,
    ).encode("utf-8")


class SessionAuthority:
    """Issue challenges and short-lived sessions for registered active carriers."""

    def __init__(
        self,
        coordinator: CoordinatorState,
        *,
        challenge_ttl: float = 30.0,
        session_ttl: float = 300.0,
    ) -> None:
        if challenge_ttl <= 0 or session_ttl <= 0:
            raise ValueError("session TTL values must be positive")
        self.coordinator = coordinator
        self.challenge_ttl = float(challenge_ttl)
        self.session_ttl = float(session_ttl)
        self._challenges: dict[str, _ChallengeState] = {}
        self._sessions: dict[str, _SessionState] = {}
        self._lock = threading.Lock()

    def _carrier_record(self, node_id: str) -> tuple[str, str]:
        if not node_id:
            raise SessionError("node_id is required")
        connection = sqlite3.connect(self.coordinator.database)
        connection.row_factory = sqlite3.Row
        try:
            row = connection.execute(
                "SELECT public_identity, state FROM carriers WHERE node_id = ?",
                (node_id,),
            ).fetchone()
        finally:
            connection.close()
        if row is None:
            raise SessionError("unknown carrier")
        return str(row["public_identity"]), str(row["state"])

    def _require_active_identity(self, node_id: str) -> str:
        public_identity, state = self._carrier_record(node_id)
        if state != "active":
            raise SessionError("carrier is not active")
        return public_identity

    @staticmethod
    def _token_hash(token: str) -> str:
        if not token:
            raise SessionError("empty session token")
        return hashlib.sha256(token.encode("ascii")).hexdigest()

    def _purge_locked(self, now: float) -> None:
        self._challenges = {
            key: value for key, value in self._challenges.items() if value.expires_at >= now
        }
        self._sessions = {
            key: value for key, value in self._sessions.items() if value.expires_at >= now
        }

    def issue_challenge(
        self,
        node_id: str,
        *,
        now: float | None = None,
    ) -> SessionChallenge:
        self._require_active_identity(node_id)
        timestamp = time.time() if now is None else float(now)
        challenge_id = secrets.token_urlsafe(18)
        challenge = secrets.token_urlsafe(32)
        challenge_hash = hashlib.sha256(challenge.encode("ascii")).hexdigest()
        expires_at = timestamp + self.challenge_ttl
        with self._lock:
            self._purge_locked(timestamp)
            self._challenges[challenge_id] = _ChallengeState(
                node_id,
                challenge_hash,
                expires_at,
            )
        return SessionChallenge(challenge_id, challenge, expires_at)

    def complete_challenge(
        self,
        *,
        node_id: str,
        challenge_id: str,
        challenge: str,
        signature: bytes,
        now: float | None = None,
    ) -> CarrierSession:
        timestamp = time.time() if now is None else float(now)
        public_identity = self._require_active_identity(node_id)
        with self._lock:
            self._purge_locked(timestamp)
            state = self._challenges.pop(challenge_id, None)
        if state is None:
            raise SessionError("unknown, expired, or already-used session challenge")
        if state.expires_at < timestamp:
            raise SessionError("session challenge expired")
        if not hmac.compare_digest(state.node_id, node_id):
            raise SessionError("session challenge node binding mismatch")
        observed = hashlib.sha256(challenge.encode("ascii")).hexdigest()
        if not hmac.compare_digest(state.challenge_hash, observed):
            raise SessionError("session challenge value mismatch")

        try:
            verify_signature(
                public_identity,
                session_proof_payload(node_id, challenge_id, challenge),
                signature,
            )
        except IdentityError as exc:
            raise SessionError("carrier proof-of-possession signature failed") from exc

        token = secrets.token_urlsafe(32)
        token_hash = self._token_hash(token)
        expires_at = timestamp + self.session_ttl
        with self._lock:
            self._purge_locked(timestamp)
            self._sessions[token_hash] = _SessionState(node_id, expires_at)
        return CarrierSession(token, node_id, expires_at)

    def authenticate(
        self,
        token: str,
        *,
        now: float | None = None,
    ) -> str:
        timestamp = time.time() if now is None else float(now)
        token_hash = self._token_hash(token)
        with self._lock:
            self._purge_locked(timestamp)
            state = self._sessions.get(token_hash)
        if state is None or state.expires_at < timestamp:
            raise SessionError("unknown or expired carrier session")
        try:
            self._require_active_identity(state.node_id)
        except SessionError:
            with self._lock:
                self._sessions.pop(token_hash, None)
            raise
        return state.node_id

    def revoke_node(self, node_id: str) -> None:
        with self._lock:
            self._challenges = {
                key: value
                for key, value in self._challenges.items()
                if value.node_id != node_id
            }
            self._sessions = {
                key: value for key, value in self._sessions.items() if value.node_id != node_id
            }
