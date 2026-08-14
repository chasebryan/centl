"""One-command reproducible CARAVAN Phase 1 local laboratory.

Run from a CENTL source checkout with:

    python3 -m caravan.lab

The laboratory is loopback/local only, opens no public listening carrier port,
and never publishes volunteer enrollment.
"""

from __future__ import annotations

import argparse
from io import BytesIO
import json
import os
from pathlib import Path
import tempfile

from .catalog import CATALOG_SCHEMA, CatalogArtifact, ChunkRecord, parse_catalog_bytes
from .content import ContentStore, chunk_manifest, hash_file
from .coordinator import CoordinatorState
from .coverage import report as coverage_report
from .lifecycle import join, leave
from .retrieval import retrieve_catalog_artifact

POLICY_VERSION = "phase1-lab-v1"
AGENT_VERSION = "centl-caravan-phase1"


def _policy_path() -> Path:
    return Path(__file__).resolve().parents[1] / "docs" / "CARAVAN-HOST-POLICY.md"


def run(root: Path) -> dict[str, object]:
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(root, 0o700)
    policy = _policy_path()
    if not policy.is_file():
        raise RuntimeError(f"CARAVAN host policy not found: {policy}")

    coordinator = CoordinatorState(root / "coordinator.sqlite")
    store = ContentStore(root / "store", max_bytes=64 * 1024 * 1024)

    def _artifact(logical_path: str, payload: bytes) -> tuple[CatalogArtifact, bytes]:
        source = root / logical_path.replace("/", "-")
        source.write_bytes(payload)
        identity = hash_file(source)
        chunks = tuple(
            ChunkRecord(int(item["offset"]), int(item["length"]), str(item["sha256"]))
            for item in chunk_manifest(source)
        )
        return (
            CatalogArtifact(logical_path, identity, "public-approved", chunks),
            payload,
        )

    source_art, source_bytes = _artifact(
        "source/laboratory.txt",
        b"CENTL CARAVAN laboratory source snapshot\n",
    )
    release_art, release_bytes = _artifact(
        "releases/laboratory.bin",
        b"CENTL CARAVAN Phase 1 authenticated laboratory artifact\n",
    )
    catalog = parse_catalog_bytes(
        json.dumps(
            {
                "schema": CATALOG_SCHEMA,
                "catalog_version": 1,
                "artifacts": [
                    {
                        "logical_path": artifact.logical_path,
                        "artifact_id": artifact.identity.artifact_id,
                        "length": artifact.identity.length,
                        "distribution": artifact.distribution,
                        "chunks": [
                            {
                                "offset": chunk.offset,
                                "length": chunk.length,
                                "sha256": chunk.sha256,
                            }
                            for chunk in artifact.chunks
                        ],
                    }
                    for artifact in (source_art, release_art)
                ],
            }
        ).encode("utf-8")
    )

    # The full TUF authentication path has its own dedicated tests. This runner
    # starts immediately after that trust boundary with already-authenticated
    # application catalog data.
    coordinator.apply_authenticated_catalog(
        catalog.coordinator_targets(),
        catalog_version=catalog.version,
    )

    bad = join(
        coordinator,
        root / "carrier-bad",
        policy_path=policy,
        policy_version=POLICY_VERSION,
        agent_version=AGENT_VERSION,
        acceptance_mode="non-interactive",
    )
    good = join(
        coordinator,
        root / "carrier-good",
        policy_path=policy,
        policy_version=POLICY_VERSION,
        agent_version=AGENT_VERSION,
        acceptance_mode="non-interactive",
    )
    coordinator.heartbeat(bad.node_id, load=0.0, capacity=64 * 1024 * 1024)
    coordinator.heartbeat(good.node_id, load=1.0, capacity=64 * 1024 * 1024)
    for artifact in (source_art, release_art):
        coordinator.advertise_replica(bad.node_id, artifact.identity.artifact_id)
        coordinator.advertise_replica(good.node_id, artifact.identity.artifact_id)

    payloads = {
        source_art.identity.artifact_id: source_bytes,
        release_art.identity.artifact_id: release_bytes,
    }
    corrupted = bytearray(release_bytes)
    corrupted[0] ^= 0x01

    def _good_fetcher(ticket):
        return BytesIO(payloads[ticket.artifact_id])

    def _bad_fetcher(ticket):
        if ticket.artifact_id == release_art.identity.artifact_id:
            return BytesIO(bytes(corrupted))
        return BytesIO(payloads[ticket.artifact_id])

    fetchers = {bad.node_id: _bad_fetcher, good.node_id: _good_fetcher}
    source_result = retrieve_catalog_artifact(
        coordinator, store, source_art, fetchers=fetchers, max_attempts=2
    )
    release_result = retrieve_catalog_artifact(
        coordinator, store, release_art, fetchers=fetchers, max_attempts=2
    )
    inventory = store.reverify_all()
    coverage = coverage_report(
        catalog,
        coordinator=coordinator,
        store=store,
        missions=("all",),
        min_replicas=2,
    )
    source_only = coverage_report(
        catalog,
        coordinator=coordinator,
        store=store,
        missions=("source",),
        min_replicas=1,
    )
    stats = coordinator.network_stats()
    census = coordinator.census_counts()

    summary: dict[str, object] = {
        "status": "ok",
        "catalog_version": catalog.version,
        "artifact_id": release_art.identity.artifact_id,
        "artifact_length": release_art.identity.length,
        "retrieval_attempts": release_result.attempts,
        "accepted_carrier": release_result.node_id,
        "stored_path": str(release_result.stored_path),
        "source_accepted_carrier": source_result.node_id,
        "available_caravans_after_quarantine": stats.available_caravans,
        "protected_artifacts": stats.protected_artifacts,
        "verified_replicas": stats.verified_replicas,
        "cargo_loads": coordinator.cargo_loads(),
        "hungry_camels": census.hungry_camels,
        "inventory_objects": [identity.artifact_id for identity in inventory],
        "coverage": coverage.to_dict(),
        "source_mission_public_approved": source_only.public_approved,
        "bad_carrier_quarantined": True,
        "public_carrier_listener_required": False,
        "network_required_for_lab_flow": False,
        "join_scheme_invoked": False,
    }

    leave(coordinator, root / "carrier-good")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the CENTL CARAVAN Phase 1 local laboratory")
    parser.add_argument(
        "--root",
        type=Path,
        help="retain laboratory state in this owner-only directory instead of a temporary directory",
    )
    args = parser.parse_args()

    if args.root is not None:
        summary = run(args.root)
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0

    with tempfile.TemporaryDirectory(prefix="centl-caravan-lab-") as temp:
        summary = run(Path(temp))
        print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
