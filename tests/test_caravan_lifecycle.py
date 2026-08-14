from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from caravan.coordinator import CoordinatorState
from caravan.lab import run as run_lab
from caravan.lifecycle import LifecycleError, join, leave, status


class CaravanLifecycleTests(unittest.TestCase):
    def _policy(self, root: Path) -> Path:
        path = root / "policy.txt"
        path.write_text("CENTL CARAVAN laboratory policy\n", encoding="utf-8")
        return path

    def test_join_status_leave_is_explicit_and_reversible(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-lifecycle-") as temp:
            root = Path(temp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            carrier_root = root / "carrier"
            policy = self._policy(root)

            joined = join(
                coordinator,
                carrier_root,
                policy_path=policy,
                policy_version="lab-v1",
                agent_version="0.14.0-lab",
                acceptance_mode="non-interactive",
            )
            self.assertEqual(joined.state, "active")
            self.assertEqual(status(coordinator, carrier_root).node_id, joined.node_id)

            departed = leave(coordinator, carrier_root)
            self.assertEqual(departed.state, "withdrawn")
            with self.assertRaises(LifecycleError):
                leave(coordinator, carrier_root)

    def test_one_command_lab_exercises_bad_carrier_fallback(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-one-command-") as temp:
            summary = run_lab(Path(temp) / "lab")
            self.assertEqual(summary["status"], "ok")
            self.assertEqual(summary["retrieval_attempts"], 2)
            self.assertTrue(summary["bad_carrier_quarantined"])
            self.assertFalse(summary["public_carrier_listener_required"])
            self.assertFalse(summary["network_required_for_lab_flow"])
            self.assertEqual(summary["available_caravans_after_quarantine"], 1)
            self.assertEqual(summary["protected_artifacts"], 2)
            self.assertEqual(summary["verified_replicas"], 2)
            self.assertEqual(summary["cargo_loads"], 2)
            self.assertFalse(summary["join_scheme_invoked"])
            coverage = summary["coverage"]
            self.assertEqual(coverage["public_approved"], 2)
            self.assertEqual(coverage["locally_held"], 2)
            self.assertEqual(summary["source_mission_public_approved"], 1)


if __name__ == "__main__":
    unittest.main()
