from __future__ import annotations

import hashlib
from pathlib import Path
import sqlite3
import tempfile
import unittest

from caravan.coordinator import CoordinatorState
from caravan.identity import CarrierIdentity
from caravan.rotation import (
    IdentityRotationProof,
    RotationError,
    apply_rotation,
    create_rotation_proof,
    verify_rotation_proof,
)
from caravan.session import SessionAuthority, SessionError, session_proof_payload


def _artifact(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


class RotationTests(unittest.TestCase):
    def _enroll(self, coordinator: CoordinatorState, identity: CarrierIdentity, now: float = 10) -> None:
        coordinator.register_carrier(
            identity.node_id,
            public_identity=identity.public_identity,
            policy_version="FCF-CARAVAN-HOST-v1",
            agent_version="1.0.0",
            now=now,
        )

    def test_rotation_requires_proof_from_both_keys(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            old = CarrierIdentity.create(root / "old")
            new = CarrierIdentity.create(root / "new")
            attacker = CarrierIdentity.create(root / "attacker")
            proof = create_rotation_proof(old, new, nonce="one-time-nonce")
            verify_rotation_proof(proof)

            bad = IdentityRotationProof(
                proof.schema,
                proof.old_node_id,
                proof.old_public_identity,
                proof.new_node_id,
                proof.new_public_identity,
                proof.nonce,
                proof.old_signature,
                create_rotation_proof(old, attacker, nonce=proof.nonce).new_signature,
            )
            with self.assertRaises(RotationError):
                verify_rotation_proof(bad)

    def test_atomic_rotation_withdraws_old_identity_and_moves_replica(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            sessions = SessionAuthority(coordinator)
            old = CarrierIdentity.create(root / "old")
            new = CarrierIdentity.create(root / "new")
            self._enroll(coordinator, old)
            artifact = _artifact(b"approved")
            coordinator.apply_authenticated_catalog(
                [(artifact, len(b"approved"), "public-approved")], catalog_version=1
            )
            coordinator.advertise_replica(old.node_id, artifact, now=11)

            proof = create_rotation_proof(old, new, nonce="rotation-1")
            self.assertEqual(apply_rotation(coordinator, sessions, proof, now=12), new.node_id)

            db = sqlite3.connect(coordinator.database)
            try:
                old_state = db.execute(
                    "SELECT state FROM carriers WHERE node_id = ?", (old.node_id,)
                ).fetchone()[0]
                new_state = db.execute(
                    "SELECT state FROM carriers WHERE node_id = ?", (new.node_id,)
                ).fetchone()[0]
                replica_owner = db.execute(
                    "SELECT node_id FROM replicas WHERE artifact_id = ?", (artifact,)
                ).fetchone()[0]
            finally:
                db.close()
            self.assertEqual(old_state, "withdrawn")
            self.assertEqual(new_state, "active")
            self.assertEqual(replica_owner, new.node_id)

    def test_rotation_revokes_old_live_session(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            sessions = SessionAuthority(coordinator)
            old = CarrierIdentity.create(root / "old")
            new = CarrierIdentity.create(root / "new")
            self._enroll(coordinator, old)

            challenge = sessions.issue_challenge(old.node_id, now=10)
            payload = session_proof_payload(old.node_id, challenge.challenge_id, challenge.challenge)
            session = sessions.complete_challenge(
                node_id=old.node_id,
                challenge_id=challenge.challenge_id,
                challenge=challenge.challenge,
                signature=old.sign(payload),
                now=10,
            )
            apply_rotation(
                coordinator,
                sessions,
                create_rotation_proof(old, new, nonce="rotation-2"),
                now=11,
            )
            with self.assertRaises(SessionError):
                sessions.authenticate(session.token, now=12)

    def test_rotation_proof_cannot_be_replayed_after_success(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            sessions = SessionAuthority(coordinator)
            old = CarrierIdentity.create(root / "old")
            new = CarrierIdentity.create(root / "new")
            self._enroll(coordinator, old)
            proof = create_rotation_proof(old, new, nonce="rotation-3")
            apply_rotation(coordinator, sessions, proof, now=11)
            with self.assertRaises(RotationError):
                apply_rotation(coordinator, sessions, proof, now=12)


if __name__ == "__main__":
    unittest.main()
