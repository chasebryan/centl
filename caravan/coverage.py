"""Catalog-relative coverage for the CARAVAN laboratory.

Coverage reports availability against authenticated catalog identity. Replica
counts and local store possession never change which bytes are trusted.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence

from .catalog import (
    MISSIONS,
    AuthenticatedCatalog,
    CatalogArtifact,
    mission_of,
    normalize_missions,
)
from .content import ArtifactIdentity, ContentStore
from .coordinator import CoordinatorState, ReplicaCoverage


@dataclass(frozen=True, slots=True)
class ArtifactCoverage:
    logical_path: str
    artifact_id: str
    length: int
    mission: str | None
    distribution: str
    replica_count: int
    locally_held: bool
    under_replicated: bool


@dataclass(frozen=True, slots=True)
class CoverageReport:
    catalog_version: int
    missions: tuple[str, ...]
    min_replicas: int
    artifacts: tuple[ArtifactCoverage, ...]
    public_approved: int
    locally_held: int
    under_replicated: int
    missing_locally: int

    def to_dict(self) -> dict[str, object]:
        return {
            "schema": "centl-caravan-coverage-v1",
            "catalog_version": self.catalog_version,
            "missions": list(self.missions),
            "min_replicas": self.min_replicas,
            "public_approved": self.public_approved,
            "locally_held": self.locally_held,
            "under_replicated": self.under_replicated,
            "missing_locally": self.missing_locally,
            "join_or_enrollment_performed": False,
            "carriers_define_trust": False,
            "artifacts": [
                {
                    "logical_path": item.logical_path,
                    "artifact_id": item.artifact_id,
                    "length": item.length,
                    "mission": item.mission,
                    "distribution": item.distribution,
                    "replica_count": item.replica_count,
                    "locally_held": item.locally_held,
                    "under_replicated": item.under_replicated,
                }
                for item in self.artifacts
            ],
        }


def _replica_index(
    rows: Iterable[ReplicaCoverage],
) -> dict[str, ReplicaCoverage]:
    return {row.artifact_id: row for row in rows}


def report(
    catalog: AuthenticatedCatalog,
    *,
    coordinator: CoordinatorState | None = None,
    store: ContentStore | None = None,
    missions: Sequence[str] = ("all",),
    min_replicas: int = 2,
    held: Iterable[ArtifactIdentity] | None = None,
) -> CoverageReport:
    """Describe replica and local-store coverage for selected missions.

    This function never enrolls a carrier, never joins the public scheme, and
    never treats replica majority as catalog authority.
    """

    selected_missions = tuple(sorted(normalize_missions(missions)))
    selected = catalog.for_missions(selected_missions)
    replica_rows = _replica_index(
        coordinator.replica_coverage(min_replicas=min_replicas)
        if coordinator is not None
        else ()
    )
    held_ids: set[str]
    if held is not None:
        held_ids = {identity.artifact_id for identity in held}
    elif store is not None:
        held_ids = {identity.artifact_id for identity in store.inventory()}
    else:
        held_ids = set()

    rows: list[ArtifactCoverage] = []
    for artifact in selected:
        replica = replica_rows.get(artifact.identity.artifact_id)
        replica_count = 0 if replica is None else replica.replica_count
        locally_held = artifact.identity.artifact_id in held_ids
        rows.append(
            ArtifactCoverage(
                logical_path=artifact.logical_path,
                artifact_id=artifact.identity.artifact_id,
                length=artifact.identity.length,
                mission=mission_of(artifact.logical_path),
                distribution=artifact.distribution,
                replica_count=replica_count,
                locally_held=locally_held,
                under_replicated=replica_count < min_replicas,
            )
        )

    return CoverageReport(
        catalog_version=catalog.version,
        missions=selected_missions,
        min_replicas=min_replicas,
        artifacts=tuple(rows),
        public_approved=len(selected),
        locally_held=sum(1 for item in rows if item.locally_held),
        under_replicated=sum(1 for item in rows if item.under_replicated),
        missing_locally=sum(1 for item in rows if not item.locally_held),
    )


def catalog_artifact_targets(
    catalog: AuthenticatedCatalog,
    *,
    missions: Sequence[str] = ("all",),
) -> tuple[CatalogArtifact, ...]:
    """Public-approved mission selection used by laboratory retrieval."""

    return catalog.for_missions(missions)


__all__ = [
    "MISSIONS",
    "ArtifactCoverage",
    "CoverageReport",
    "catalog_artifact_targets",
    "report",
]
