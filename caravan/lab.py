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

from .catalog import ChunkRecord
from .content import ContentStore, chunk_manifest, hash_file
from .coordinator import CoordinatorState
from .lifecycle import join, leave
from .retrieval import retrieve_verified

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

    source = root / "laboratory-artifact.bin"
    good_bytes = b"CENTL CARAVAN Phase 1 authenticated laboratory artifact\n"
    source.write_bytes(good_bytes)
    identity = hash_file(source)
    chunk_dicts = chunk_manifest(source)
    chunks = tuple(
        ChunkRecord(int(item["offset"]), int(item["length"]), str(item["sha256"]))
        for item in chunk_dicts
    )

    # The full TUF authentication path has its own dedicated tests. This runner
    # starts immediately after that trust boundary with already-authenticated
    # application catalog data.
    coordinator.apply_authenticated_catalog(
        [(identity.artifact_id, identity.length, "public-approved")],
        catalog_version=1,
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
    coordinator.advertise_replica(bad.node_id, identity.artifact_id)
    coordinator.advertise_replica(good.node_id, identity.artifact_id)

    corrupted = bytearray(good_bytes)
    corrupted[0] ^= 0x01
    result = retrieve_verified(
        coordinator,
        store,
        expected=identity,
        chunks=chunks,
        fetchers={
            bad.node_id: lambda _ticket: BytesIO(bytes(corrupted)),
            good.node_id: lambda _ticket: BytesIO(good_bytes),
        },
        max_attempts=2,
    )
    stats = coordinator.network_stats()

    summary: dict[str, object] = {
        "status": "ok",
        "artifact_id": identity.artifact_id,
        "artifact_length": identity.length,
        "retrieval_attempts": result.attempts,
        "accepted_carrier": result.node_id,
        "stored_path": str(result.stored_path),
        "available_caravans_after_quarantine": stats.available_caravans,
        "protected_artifacts": stats.protected_artifacts,
        "verified_replicas": stats.verified_replicas,
        "bad_carrier_quarantined": True,
        "public_carrier_listener_required": False,
        "network_required_for_lab_flow": False,
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
