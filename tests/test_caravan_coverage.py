from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from caravan.catalog import (
    CATALOG_SCHEMA,
    CatalogError,
    mission_of,
    parse_catalog_bytes,
)
from caravan.content import ContentStore, IntegrityError
from caravan.coordinator import CoordinatorState
from caravan.coverage import report


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _artifact(path: str, data: bytes, distribution: str = "public-approved") -> dict[str, object]:
    return {
        "logical_path": path,
        "artifact_id": "sha256:" + _sha(data),
        "length": len(data),
        "distribution": distribution,
        "chunks": [{"offset": 0, "length": len(data), "sha256": _sha(data)}],
    }


class CaravanCoverageTests(unittest.TestCase):
    def _catalog(self) -> bytes:
        return json.dumps(
            {
                "schema": CATALOG_SCHEMA,
                "catalog_version": 3,
                "artifacts": [
                    _artifact("source/core.tar.gz", b"source-bytes"),
                    _artifact("releases/centl.tar.gz", b"release-bytes"),
                    _artifact("notes/readme.txt", b"unclassed"),
                    _artifact(
                        "semantic/model.bin",
                        b"pending",
                        distribution="pending-review",
                    ),
                ],
            }
        ).encode("utf-8")

    def test_mission_filter_matches_join_first_segment_rule(self) -> None:
        catalog = parse_catalog_bytes(self._catalog())
        self.assertEqual(mission_of("source/core.tar.gz"), "source")
        self.assertIsNone(mission_of("notes/readme.txt"))
        selected = catalog.for_missions(("source", "releases"))
        self.assertEqual(
            [item.logical_path for item in selected],
            ["source/core.tar.gz", "releases/centl.tar.gz"],
        )
        self.assertEqual(len(catalog.for_missions(("semantic",))), 0)
        with self.assertRaises(CatalogError):
            catalog.for_missions(("unknown",))

    def test_coverage_reports_store_and_replica_gaps_without_changing_identity(self) -> None:
        catalog = parse_catalog_bytes(self._catalog())
        with tempfile.TemporaryDirectory(prefix="centl-caravan-coverage-") as temp:
            root = Path(temp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            store = ContentStore(root / "store", max_bytes=1_000_000)
            source = root / "source.tar.gz"
            source.write_bytes(b"source-bytes")
            identity = store.import_file(source)

            coordinator.apply_authenticated_catalog(
                catalog.coordinator_targets(),
                catalog_version=catalog.version,
            )
            coordinator.register_carrier(
                "camel-a",
                public_identity="pub-a",
                policy_version="lab-v1",
                agent_version="0.14.0-lab",
            )
            coordinator.heartbeat("camel-a", load=0.0, capacity=4096)
            coordinator.advertise_replica("camel-a", identity.artifact_id)

            coverage = report(
                catalog,
                coordinator=coordinator,
                store=store,
                missions=("all",),
                min_replicas=2,
            )
            by_path = {item.logical_path: item for item in coverage.artifacts}
            self.assertEqual(coverage.public_approved, 2)
            self.assertEqual(coverage.locally_held, 1)
            self.assertEqual(coverage.missing_locally, 1)
            self.assertTrue(by_path["source/core.tar.gz"].locally_held)
            self.assertFalse(by_path["releases/centl.tar.gz"].locally_held)
            self.assertTrue(by_path["source/core.tar.gz"].under_replicated)
            self.assertEqual(by_path["source/core.tar.gz"].replica_count, 1)
            self.assertFalse(coverage.to_dict()["carriers_define_trust"])
            self.assertFalse(coverage.to_dict()["join_or_enrollment_performed"])

    def test_inventory_detects_mutated_object(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-inventory-") as temp:
            root = Path(temp)
            store = ContentStore(root / "store", max_bytes=1_000_000)
            source = root / "cargo.bin"
            source.write_bytes(b"immutable")
            identity = store.import_file(source)
            self.assertEqual(store.inventory(), (identity,))
            stored = store.path_for_verified(identity)
            os_mode = stored.stat().st_mode
            stored.chmod(0o644)
            stored.write_bytes(b"mutated!")
            stored.chmod(os_mode)
            with self.assertRaises(IntegrityError):
                store.reverify_all()


if __name__ == "__main__":
    unittest.main()
