from __future__ import annotations

from dataclasses import replace
from pathlib import Path
import tempfile
import unittest

from caravan.coordinator import CoordinatorState
from caravan.enrollment import register_accepted_carrier
from caravan.identity import CarrierIdentity
from caravan.policy import PolicyError, create_policy_receipt


class EnrollmentTests(unittest.TestCase):
    def test_registration_requires_exact_signed_policy_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy = root / "policy.md"
            policy.write_text("laboratory host policy\n", encoding="utf-8")
            identity = CarrierIdentity.create(root / "identity")
            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="FCF-CARAVAN-HOST-lab-v1",
                agent_version="0.0.1-lab",
                acceptance_mode="interactive",
                accepted_at=1_786_000_000,
            )
            coordinator = CoordinatorState(root / "coordinator.sqlite", heartbeat_ttl=10)

            register_accepted_carrier(
                coordinator,
                receipt,
                expected_policy_path=policy,
                expected_policy_version="FCF-CARAVAN-HOST-lab-v1",
                now=100,
            )
            coordinator.heartbeat(identity.node_id, load=0, capacity=1024, now=100)

            with self.assertRaises(PolicyError):
                register_accepted_carrier(
                    coordinator,
                    replace(receipt, agent_version="tampered"),
                    expected_policy_path=policy,
                    expected_policy_version="FCF-CARAVAN-HOST-lab-v1",
                    now=101,
                )

    def test_changed_policy_bytes_require_new_acceptance(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy = root / "policy.md"
            policy.write_text("policy version one\n", encoding="utf-8")
            identity = CarrierIdentity.create(root / "identity")
            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="v1",
                agent_version="lab",
                acceptance_mode="non-interactive",
                accepted_at=1_786_000_000,
            )
            policy.write_text("materially changed policy\n", encoding="utf-8")
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            with self.assertRaises(PolicyError):
                register_accepted_carrier(
                    coordinator,
                    receipt,
                    expected_policy_path=policy,
                    expected_policy_version="v1",
                )


if __name__ == "__main__":
    unittest.main()
