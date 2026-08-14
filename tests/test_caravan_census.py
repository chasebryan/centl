from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from caravan.census import (
    ACTIVE_WINDOW_SECONDS,
    CENSUS_SCHEMA,
    CensusError,
    build_live_document,
    validate_public_document,
)
from caravan.coordinator import CoordinatorState


class CensusTests(unittest.TestCase):
    def _register(
        self,
        state: CoordinatorState,
        node_id: str,
        *,
        now: float,
    ) -> None:
        state.register_carrier(
            node_id,
            public_identity=f"pub-{node_id}",
            policy_version="v1",
            agent_version="0.1",
            now=now,
        )

    def test_counts_follow_public_active_and_lost_windows(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = CoordinatorState(Path(tmp) / "coordinator.sqlite")
            self._register(state, "active", now=1_000)
            self._register(state, "hungry", now=1_000 - ACTIVE_WINDOW_SECONDS - 1)
            self._register(state, "lost", now=1_000 - 259_200 - 1)
            self._register(state, "withdrawn", now=1_000 - 259_200 - 1)
            state.withdraw("withdrawn")
            self._register(state, "quarantined", now=1_000 - 259_200 - 1)
            state.quarantine("quarantined")

            counts = state.census_counts(now=1_000)
            self.assertEqual(
                (counts.active_camels, counts.hungry_camels, counts.lost_camels),
                (1, 1, 1),
            )
            self.assertEqual(counts.cargo_loads, 0)

    def test_live_document_is_exact_aggregate_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = CoordinatorState(Path(tmp) / "coordinator.sqlite")
            self._register(state, "active", now=100)
            self._register(state, "lost", now=100 - 259_200 - 1)

            document = build_live_document(
                state,
                now=100,
                generated_at="1970-01-01T00:01:40Z",
            )
            self.assertEqual(
                document,
                {
                    "schema": CENSUS_SCHEMA,
                    "status": "live",
                    "generated_at": "1970-01-01T00:01:40Z",
                    "active_camels": 1,
                    "hungry_camels": 0,
                    "lost_camels": 1,
                    "cargo_loads": 0,
                    "active_window_seconds": ACTIVE_WINDOW_SECONDS,
                    "lost_after_seconds": 259_200,
                    "individual_nodes_public": False,
                    "ip_addresses_public": False,
                },
            )

    def test_public_document_rejects_identifiers_and_contract_drift(self) -> None:
        with self.assertRaises(CensusError):
            validate_public_document(
                {
                    "schema": CENSUS_SCHEMA,
                    "status": "live",
                    "generated_at": "1970-01-01T00:01:40Z",
                    "active_camels": 1,
                    "hungry_camels": 0,
                    "lost_camels": 0,
                    "cargo_loads": 0,
                    "active_window_seconds": ACTIVE_WINDOW_SECONDS,
                    "lost_after_seconds": 259_200,
                    "individual_nodes_public": False,
                    "ip_addresses_public": False,
                    "node_id": "x200",
                }
            )

        with self.assertRaises(CensusError):
            validate_public_document(
                {
                    "schema": CENSUS_SCHEMA,
                    "status": "live",
                    "generated_at": "1970-01-01T00:01:40Z",
                    "active_camels": True,
                    "hungry_camels": 0,
                    "lost_camels": 0,
                    "cargo_loads": 0,
                    "active_window_seconds": ACTIVE_WINDOW_SECONDS,
                    "lost_after_seconds": 259_200,
                    "individual_nodes_public": False,
                    "ip_addresses_public": False,
                }
            )


if __name__ == "__main__":
    unittest.main()
