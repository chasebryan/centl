from __future__ import annotations

from io import BytesIO
import hashlib
from pathlib import Path
import tempfile
import unittest

from caravan.catalog import ChunkRecord
from caravan.content import ArtifactIdentity, ContentStore
from caravan.coordinator import CoordinatorState
from caravan.retrieval import RetrievalError, retrieve_verified


class CaravanRetrievalTests(unittest.TestCase):
    def _fixture(self, root: Path, data: bytes) -> tuple[CoordinatorState, ContentStore, ArtifactIdentity, tuple[ChunkRecord, ...]]:
        coordinator = CoordinatorState(root / "coordinator.sqlite")
        store = ContentStore(root / "store", max_bytes=16 * 1024 * 1024)
        identity = ArtifactIdentity(hashlib.sha256(data).hexdigest(), len(data))
        chunks = (
            ChunkRecord(0, len(data), hashlib.sha256(data).hexdigest()),
        )
        coordinator.apply_authenticated_catalog(
            [(identity.artifact_id, identity.length, "public-approved")],
            catalog_version=1,
        )
        return coordinator, store, identity, chunks

    @staticmethod
    def _register(coordinator: CoordinatorState, node_id: str, *, load: float) -> None:
        coordinator.register_carrier(
            node_id,
            public_identity=f"public-{node_id}",
            policy_version="lab-v1",
            agent_version="0.14.0-lab",
        )
        coordinator.heartbeat(node_id, load=load, capacity=1024 * 1024)

    def test_bad_carrier_is_quarantined_and_good_carrier_fallback_succeeds(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-retrieval-") as temp:
            root = Path(temp)
            data = b"authenticated CARAVAN artifact"
            coordinator, store, identity, chunks = self._fixture(root, data)
            self._register(coordinator, "bad", load=0.0)
            self._register(coordinator, "good", load=1.0)
            coordinator.advertise_replica("bad", identity.artifact_id)
            coordinator.advertise_replica("good", identity.artifact_id)

            result = retrieve_verified(
                coordinator,
                store,
                expected=identity,
                chunks=chunks,
                fetchers={
                    "bad": lambda _ticket: BytesIO(b"malicious CARAVAN artifact"),
                    "good": lambda _ticket: BytesIO(data),
                },
                max_attempts=2,
            )

            self.assertEqual(result.node_id, "good")
            self.assertEqual(result.attempts, 2)
            self.assertEqual(result.identity, identity)
            self.assertEqual(result.stored_path.read_bytes(), data)
            stats = coordinator.network_stats()
            self.assertEqual(stats.available_caravans, 1)
            self.assertEqual(stats.verified_replicas, 1)

    def test_truncated_transfer_is_never_promoted(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-truncated-") as temp:
            root = Path(temp)
            data = b"0123456789abcdef"
            coordinator, store, identity, chunks = self._fixture(root, data)
            self._register(coordinator, "truncated", load=0.0)
            coordinator.advertise_replica("truncated", identity.artifact_id)

            with self.assertRaises(RetrievalError):
                retrieve_verified(
                    coordinator,
                    store,
                    expected=identity,
                    chunks=chunks,
                    fetchers={"truncated": lambda _ticket: BytesIO(data[:-1])},
                    max_attempts=1,
                )
            self.assertEqual(store.total_bytes(), 0)
            self.assertEqual(coordinator.network_stats().available_caravans, 0)

    def test_appended_bytes_are_never_promoted(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-appended-") as temp:
            root = Path(temp)
            data = b"exact bytes"
            coordinator, store, identity, chunks = self._fixture(root, data)
            self._register(coordinator, "appended", load=0.0)
            coordinator.advertise_replica("appended", identity.artifact_id)

            with self.assertRaises(RetrievalError):
                retrieve_verified(
                    coordinator,
                    store,
                    expected=identity,
                    chunks=chunks,
                    fetchers={"appended": lambda _ticket: BytesIO(data + b"X")},
                    max_attempts=1,
                )
            self.assertEqual(store.total_bytes(), 0)

    def test_chunk_order_or_content_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-caravan-chunk-") as temp:
            root = Path(temp)
            data = b"abcdefgh"
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            store = ContentStore(root / "store", max_bytes=1024 * 1024)
            identity = ArtifactIdentity(hashlib.sha256(data).hexdigest(), len(data))
            chunks = (
                ChunkRecord(0, 4, hashlib.sha256(b"abcd").hexdigest()),
                ChunkRecord(4, 4, hashlib.sha256(b"efgh").hexdigest()),
            )
            coordinator.apply_authenticated_catalog(
                [(identity.artifact_id, identity.length, "public-approved")],
                catalog_version=1,
            )
            self._register(coordinator, "reordered", load=0.0)
            coordinator.advertise_replica("reordered", identity.artifact_id)

            with self.assertRaises(RetrievalError):
                retrieve_verified(
                    coordinator,
                    store,
                    expected=identity,
                    chunks=chunks,
                    fetchers={"reordered": lambda _ticket: BytesIO(b"efghabcd")},
                    max_attempts=1,
                )
            self.assertEqual(store.total_bytes(), 0)


if __name__ == "__main__":
    unittest.main()
