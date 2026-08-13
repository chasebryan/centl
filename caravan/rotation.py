"""Authenticated carrier identity rotation for CARAVAN."""

from __future__ import annotations

import base64
from dataclasses import dataclass, replace
import json
import sqlite3
import time

from .coordinator import CoordinatorState
from .identity import CarrierIdentity, IdentityError, derive_node_id, verify_signature
from .session import SessionAuthority

ROTATION_SCHEMA = "fcf-caravan-identity-rotation-v1"


class RotationError(RuntimeError):
    """Raised when a carrier identity rotation is invalid."""


def _encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def _decode(text: str) -> bytes:
    if not text or "=" in text:
        raise RotationError("rotation signature must use unpadded base64url")
    try:
        raw = base64.urlsafe_b64decode(text + "=" * ((4 - len(text) % 4) % 4))
    except Exception as exc:
        raise RotationError("invalid rotation signature encoding") from exc
    if _encode(raw) != text:
        raise RotationError("rotation signature is not canonical base64url")
    return raw


@dataclass(frozen=True, slots=True)
class IdentityRotationProof:
    schema: str
    old_node_id: str
    old_public_identity: str
    new_node_id: str
    new_public_identity: str
    nonce: str
    old_signature: str
    new_signature: str

    def payload(self) -> dict[str, str]:
        return {
            "schema": self.schema,
            "old_node_id": self.old_node_id,
            "old_public_identity": self.old_public_identity,
            "new_node_id": self.new_node_id,
            "new_public_identity": self.new_public_identity,
            "nonce": self.nonce,
        }

    def canonical_payload(self) -> bytes:
        return json.dumps(
            self.payload(), sort_keys=True, separators=(",", ":"), ensure_ascii=True
        ).encode("ascii")


def create_rotation_proof(
    old_identity: CarrierIdentity,
    new_identity: CarrierIdentity,
    *,
    nonce: str,
) -> IdentityRotationProof:
    if not nonce:
        raise RotationError("rotation nonce is required")
    if old_identity.node_id == new_identity.node_id:
        raise RotationError("replacement identity must be different")
    proof = IdentityRotationProof(
        ROTATION_SCHEMA,
        old_identity.node_id,
        old_identity.public_identity,
        new_identity.node_id,
        new_identity.public_identity,
        nonce,
        "",
        "",
    )
    payload = proof.canonical_payload()
    return replace(
        proof,
        old_signature=_encode(old_identity.sign(payload)),
        new_signature=_encode(new_identity.sign(payload)),
    )


def verify_rotation_proof(proof: IdentityRotationProof) -> IdentityRotationProof:
    if proof.schema != ROTATION_SCHEMA:
        raise RotationError("unsupported rotation schema")
    if not proof.nonce:
        raise RotationError("rotation nonce is required")
    if proof.old_node_id == proof.new_node_id:
        raise RotationError("replacement identity must be different")
    try:
        if derive_node_id(proof.old_public_identity) != proof.old_node_id:
            raise RotationError("old node ID does not match public identity")
        if derive_node_id(proof.new_public_identity) != proof.new_node_id:
            raise RotationError("new node ID does not match public identity")
        payload = proof.canonical_payload()
        verify_signature(proof.old_public_identity, payload, _decode(proof.old_signature))
        verify_signature(proof.new_public_identity, payload, _decode(proof.new_signature))
    except IdentityError as exc:
        raise RotationError("rotation signature verification failed") from exc
    return proof


def apply_rotation(
    coordinator: CoordinatorState,
    sessions: SessionAuthority,
    proof: IdentityRotationProof,
    *,
    now: float | None = None,
) -> str:
    """Atomically move an active carrier from the old key to the replacement key."""

    verify_rotation_proof(proof)
    timestamp = time.time() if now is None else float(now)
    db = sqlite3.connect(coordinator.database)
    db.row_factory = sqlite3.Row
    try:
        db.execute("PRAGMA foreign_keys = ON")
        db.execute("BEGIN IMMEDIATE")
        old = db.execute(
            "SELECT * FROM carriers WHERE node_id = ?", (proof.old_node_id,)
        ).fetchone()
        if old is None or old["state"] != "active":
            raise RotationError("old carrier must be actively enrolled")
        if old["public_identity"] != proof.old_public_identity:
            raise RotationError("old public identity does not match enrollment")
        if db.execute(
            "SELECT 1 FROM carriers WHERE node_id = ? OR public_identity = ?",
            (proof.new_node_id, proof.new_public_identity),
        ).fetchone() is not None:
            raise RotationError("replacement carrier identity is already enrolled")

        db.execute(
            """INSERT INTO carriers(
                   node_id, public_identity, policy_version, agent_version,
                   state, last_seen, load, capacity
               ) VALUES (?, ?, ?, ?, 'active', ?, ?, ?)""",
            (
                proof.new_node_id,
                proof.new_public_identity,
                old["policy_version"],
                old["agent_version"],
                timestamp,
                old["load"],
                old["capacity"],
            ),
        )
        db.execute(
            """INSERT INTO replicas(node_id, artifact_id, verified_at)
               SELECT ?, artifact_id, verified_at FROM replicas WHERE node_id = ?""",
            (proof.new_node_id, proof.old_node_id),
        )
        db.execute("DELETE FROM replicas WHERE node_id = ?", (proof.old_node_id,))
        db.execute("DELETE FROM tickets WHERE node_id = ?", (proof.old_node_id,))
        db.execute(
            "UPDATE carriers SET state = 'withdrawn' WHERE node_id = ?",
            (proof.old_node_id,),
        )
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    sessions.revoke_node(proof.old_node_id)
    return proof.new_node_id
