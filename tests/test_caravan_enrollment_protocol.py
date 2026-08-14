from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from caravan.coordinator import CoordinatorState
from caravan.enrollment_protocol import EnrollmentAuthority, EnrollmentProtocolError
from caravan.identity import CarrierIdentity
from caravan.policy import create_policy_receipt
from caravan.session import SessionAuthority, SessionError, session_proof_payload


class EnrollmentProtocolTests(unittest.TestCase):
    def _setup(self, root: Path):
        policy = root / "policy.md"
        policy.write_text("FCF CARAVAN host policy\n", encoding="utf-8")
        coordinator = CoordinatorState(root / "coordinator.sqlite")
        sessions = SessionAuthority(coordinator)
        authority = EnrollmentAuthority(
            coordinator,
            sessions,
            policy_path=policy,
            policy_version="FCF-CARAVAN-HOST-v1",
            allowed_agent_versions={"1.0.0"},
        )
        return policy, coordinator, sessions, authority

    def test_signed_policy_receipt_enrolls_pseudonymous_carrier(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy, coordinator, sessions, authority = self._setup(root)
            identity = CarrierIdentity.create(root / "identity")
            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="FCF-CARAVAN-HOST-v1",
                agent_version="1.0.0",
                acceptance_mode="non-interactive",
            )
            result = authority.enroll(receipt.to_dict(), now=10)
            self.assertEqual(result["node_id"], identity.node_id)
            self.assertEqual(result["state"], "active")
            self.assertFalse(result["public_listing"])
            challenge = sessions.issue_challenge(identity.node_id, now=11)
            payload = session_proof_payload(
                identity.node_id, challenge.challenge_id, challenge.challenge
            )
            session = sessions.complete_challenge(
                node_id=identity.node_id,
                challenge_id=challenge.challenge_id,
                challenge=challenge.challenge,
                signature=identity.sign(payload),
                now=11,
            )
            self.assertEqual(sessions.authenticate(session.token, now=12), identity.node_id)
            self.assertEqual(coordinator.census_counts(now=12).active_camels, 1)

    def test_unadmitted_release_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy, _coordinator, _sessions, authority = self._setup(root)
            identity = CarrierIdentity.create(root / "identity")
            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="FCF-CARAVAN-HOST-v1",
                agent_version="0.9.0",
                acceptance_mode="interactive",
            )
            with self.assertRaises(EnrollmentProtocolError):
                authority.enroll(receipt.to_dict())

    def test_policy_digest_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy, _coordinator, _sessions, authority = self._setup(root)
            identity = CarrierIdentity.create(root / "identity")
            other = root / "other-policy.md"
            other.write_text("different policy bytes\n", encoding="utf-8")
            receipt = create_policy_receipt(
                identity,
                other,
                policy_version="FCF-CARAVAN-HOST-v1",
                agent_version="1.0.0",
                acceptance_mode="interactive",
            )
            with self.assertRaises(EnrollmentProtocolError):
                authority.enroll(receipt.to_dict())

    def test_withdrawal_excludes_carrier_and_revokes_live_session(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy, coordinator, sessions, authority = self._setup(root)
            identity = CarrierIdentity.create(root / "identity")
            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="FCF-CARAVAN-HOST-v1",
                agent_version="1.0.0",
                acceptance_mode="non-interactive",
            )
            authority.enroll(receipt.to_dict(), now=10)
            challenge = sessions.issue_challenge(identity.node_id, now=11)
            payload = session_proof_payload(
                identity.node_id, challenge.challenge_id, challenge.challenge
            )
            session = sessions.complete_challenge(
                node_id=identity.node_id,
                challenge_id=challenge.challenge_id,
                challenge=challenge.challenge,
                signature=identity.sign(payload),
                now=11,
            )
            result = authority.withdraw(identity.node_id)
            self.assertEqual(result["state"], "withdrawn")
            with self.assertRaises(SessionError):
                sessions.authenticate(session.token, now=12)
            counts = coordinator.census_counts(now=1_000_000)
            self.assertEqual(counts.active_camels, 0)
            self.assertEqual(counts.lost_camels, 0)


if __name__ == "__main__":
    unittest.main()
