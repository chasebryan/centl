from __future__ import annotations

import os
from pathlib import Path
import stat
import tempfile
import unittest

from caravan.content import ArtifactIdentity, ContentStore, IntegrityError, chunk_manifest, hash_file
from caravan.coordinator import CoordinatorError, CoordinatorState


class ContentStoreTests(unittest.TestCase):
    def test_import_verify_and_mutation_rejection(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "cargo.bin"
            source.write_bytes(b"CARAVAN" * 1024)
            expected = hash_file(source)
            store = ContentStore(root / "store", max_bytes=1_000_000)
            identity = store.import_file(source, expected=expected)
            self.assertEqual(identity, expected)
            stored = store.path_for_verified(identity)
            os.chmod(stored, 0o644)
            stored.write_bytes(b"X" + stored.read_bytes()[1:])
            with self.assertRaises(IntegrityError):
                store.verify(identity)

    def test_wrong_expected_identity_is_never_promoted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "cargo.bin"
            source.write_bytes(b"correct bytes")
            store = ContentStore(root / "store", max_bytes=1_000_000)
            wrong = ArtifactIdentity("0" * 64, source.stat().st_size)
            with self.assertRaises(IntegrityError):
                store.import_file(source, expected=wrong)
            self.assertEqual(store.total_bytes(), 0)

    def test_symlink_source_and_symlink_store_root_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            real = root / "real.bin"
            real.write_bytes(b"bytes")
            link = root / "link.bin"
            link.symlink_to(real)
            store = ContentStore(root / "store", max_bytes=1000)
            with self.assertRaises(IntegrityError):
                store.import_file(link)

            actual_root = root / "actual-store"
            actual_root.mkdir()
            root_link = root / "store-link"
            root_link.symlink_to(actual_root, target_is_directory=True)
            with self.assertRaises(IntegrityError):
                ContentStore(root_link, max_bytes=1000)

    def test_store_lock_is_private_regular_and_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "cargo.bin"
            source.write_bytes(b"lock boundary")
            store = ContentStore(root / "store", max_bytes=1000)
            store.import_file(source)

            lock_path = store.root / ".store.lock"
            info = os.lstat(lock_path)
            self.assertTrue(stat.S_ISREG(info.st_mode))
            self.assertEqual(stat.S_IMODE(info.st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(os.lstat(store.root).st_mode), 0o700)
            self.assertEqual(stat.S_IMODE(os.lstat(store.root / "tmp").st_mode), 0o700)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "cargo.bin"
            source.write_bytes(b"lock symlink")
            store = ContentStore(root / "store", max_bytes=1000)
            outside = root / "outside-lock"
            outside.write_bytes(b"outside")
            (store.root / ".store.lock").symlink_to(outside)
            with self.assertRaises(IntegrityError):
                store.import_file(source)
            self.assertEqual(outside.read_bytes(), b"outside")

    def test_storage_limit_and_chunk_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "cargo.bin"
            source.write_bytes(b"abcdefghij")
            store = ContentStore(root / "store", max_bytes=9)
            with self.assertRaises(IntegrityError):
                store.import_file(source)
            chunks = chunk_manifest(source, chunk_size=4)
            self.assertEqual([c["length"] for c in chunks], [4, 4, 2])
            self.assertEqual([c["offset"] for c in chunks], [0, 4, 8])


class CoordinatorTests(unittest.TestCase):
    ARTIFACT = "sha256:" + "a" * 64
    REVOKED = "sha256:" + "b" * 64

    def _coordinator(self, root: Path) -> CoordinatorState:
        state = CoordinatorState(root / "coordinator.sqlite", heartbeat_ttl=10)
        state.apply_authenticated_catalog(
            [
                (self.ARTIFACT, 123, "public-approved"),
                (self.REVOKED, 456, "revoked"),
            ],
            catalog_version=1,
        )
        return state

    def _registered_carrier(self, state: CoordinatorState, *, now: float = 100) -> None:
        state.register_carrier(
            "node-a",
            public_identity="pub-a",
            policy_version="v1",
            agent_version="0.1",
            now=now,
        )
        state.heartbeat("node-a", load=0.1, capacity=1000, now=now)
        state.advertise_replica("node-a", self.ARTIFACT, now=now)

    def test_database_is_private_regular_and_symlink_path_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            database = root / "coordinator.sqlite"
            CoordinatorState(database)
            info = os.lstat(database)
            self.assertTrue(stat.S_ISREG(info.st_mode))
            self.assertEqual(stat.S_IMODE(info.st_mode), 0o600)

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            real = root / "real.sqlite"
            real.write_bytes(b"")
            link = root / "coordinator.sqlite"
            link.symlink_to(real)
            with self.assertRaises(CoordinatorError):
                CoordinatorState(link)

    def test_register_carrier_assigns_durable_live_numbers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = self._coordinator(Path(tmp))
            first = state.register_carrier(
                "node-a",
                public_identity="pub-a",
                policy_version="v1",
                agent_version="0.1",
                now=100,
            )
            second = state.register_carrier(
                "node-b",
                public_identity="pub-b",
                policy_version="v1",
                agent_version="0.1",
                now=100,
            )
            again = state.register_carrier(
                "node-a",
                public_identity="pub-a",
                policy_version="v1",
                agent_version="0.1",
                now=101,
            )
            self.assertEqual(first, 1)
            self.assertEqual(second, 2)
            self.assertEqual(again, 1)

    def test_counts_include_only_fresh_eligible_carriers(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = self._coordinator(Path(tmp))
            state.register_carrier(
                "node-a", public_identity="pub-a", policy_version="v1", agent_version="0.1", now=100
            )
            state.register_carrier(
                "node-b", public_identity="pub-b", policy_version="v1", agent_version="0.1", now=100
            )
            state.advertise_replica("node-a", self.ARTIFACT, now=100)
            state.advertise_replica("node-b", self.ARTIFACT, now=100)
            stats = state.network_stats(now=105)
            self.assertEqual(
                (stats.available_caravans, stats.protected_artifacts, stats.verified_replicas),
                (2, 1, 2),
            )
            stale = state.network_stats(now=111)
            self.assertEqual(
                (stale.available_caravans, stale.protected_artifacts, stale.verified_replicas),
                (0, 0, 0),
            )

    def test_unapproved_or_revoked_content_cannot_be_advertised(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = self._coordinator(Path(tmp))
            state.register_carrier(
                "node-a", public_identity="pub-a", policy_version="v1", agent_version="0.1", now=100
            )
            with self.assertRaises(CoordinatorError):
                state.advertise_replica("node-a", self.REVOKED, now=100)
            with self.assertRaises(CoordinatorError):
                state.advertise_replica("node-a", "sha256:" + "c" * 64, now=100)

    def test_ticket_is_bound_short_lived_and_single_use(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = self._coordinator(Path(tmp))
            self._registered_carrier(state)
            ticket = state.issue_ticket(self.ARTIFACT, ttl=5, now=101)
            self.assertEqual(ticket.node_id, "node-a")
            state.consume_ticket(ticket.token, node_id="node-a", artifact_id=self.ARTIFACT, now=102)
            with self.assertRaises(CoordinatorError):
                state.consume_ticket(ticket.token, node_id="node-a", artifact_id=self.ARTIFACT, now=102)

            later = state.issue_ticket(self.ARTIFACT, ttl=1, now=103)
            with self.assertRaises(CoordinatorError):
                state.consume_ticket(later.token, node_id="node-a", artifact_id=self.ARTIFACT, now=105)

    def test_pending_ticket_population_and_ttl_are_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            state = CoordinatorState(
                root / "coordinator.sqlite",
                heartbeat_ttl=10,
                max_pending_tickets=2,
                max_ticket_ttl=5,
            )
            state.apply_authenticated_catalog(
                [(self.ARTIFACT, 123, "public-approved")],
                catalog_version=1,
            )
            self._registered_carrier(state)
            first = state.issue_ticket(self.ARTIFACT, ttl=5, now=101)
            state.issue_ticket(self.ARTIFACT, ttl=5, now=101)
            with self.assertRaises(CoordinatorError):
                state.issue_ticket(self.ARTIFACT, ttl=5, now=101)
            with self.assertRaises(ValueError):
                state.issue_ticket(self.ARTIFACT, ttl=6, now=101)

            state.consume_ticket(first.token, node_id="node-a", artifact_id=self.ARTIFACT, now=102)
            replacement = state.issue_ticket(self.ARTIFACT, ttl=5, now=102)
            self.assertEqual(replacement.node_id, "node-a")

            # At a later logical time, expired pending rows are purged before
            # enforcing the population ceiling, allowing fresh bounded state.
            fresh = state.issue_ticket(self.ARTIFACT, ttl=1, now=107)
            self.assertEqual(fresh.node_id, "node-a")

    def test_quarantine_removes_carrier_from_routing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            state = self._coordinator(Path(tmp))
            state.register_carrier(
                "node-a", public_identity="pub-a", policy_version="v1", agent_version="0.1", now=100
            )
            state.advertise_replica("node-a", self.ARTIFACT, now=100)
            self.assertEqual(state.network_stats(now=100).available_caravans, 1)
            state.record_integrity_failure(
                "node-a",
                self.ARTIFACT,
                expected_digest="a" * 64,
                observed_digest="c" * 64,
                now=101,
            )
            self.assertEqual(state.network_stats(now=101).available_caravans, 0)
            with self.assertRaises(CoordinatorError):
                state.issue_ticket(self.ARTIFACT, now=101)


if __name__ == "__main__":
    unittest.main()
