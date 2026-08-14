"""Aggregate CARAVAN census documents from coordinator state.

This module only emits the public aggregate contract. It never exposes carrier
identifiers or turns prepared/local state into a live public claim.
"""

from __future__ import annotations

from collections.abc import Mapping
from datetime import datetime, timezone
import time
from typing import Any

from .coordinator import CoordinatorState

CENSUS_SCHEMA = "fcf-caravan-census-v1"
ACTIVE_WINDOW_SECONDS = 1_800
LOST_AFTER_SECONDS = 259_200

_PUBLIC_KEYS = frozenset(
    {
        "schema",
        "status",
        "generated_at",
        "active_camels",
        "hungry_camels",
        "lost_camels",
        "cargo_loads",
        "active_window_seconds",
        "lost_after_seconds",
        "individual_nodes_public",
        "ip_addresses_public",
    }
)


class CensusError(ValueError):
    """Raised when a public census document violates the published contract."""


def _utc_timestamp(value: float) -> str:
    return (
        datetime.fromtimestamp(value, tz=timezone.utc)
        .isoformat(timespec="seconds")
        .replace("+00:00", "Z")
    )


def _valid_timestamp(value: object) -> bool:
    if not isinstance(value, str) or not value:
        return False
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return parsed.tzinfo is not None


def _nonnegative_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def validate_public_document(document: Mapping[str, Any]) -> dict[str, Any]:
    """Validate and return a JSON-ready copy of the exact public census contract."""

    if not isinstance(document, Mapping):
        raise CensusError("public census document must be an object")
    if set(document) != _PUBLIC_KEYS:
        raise CensusError("public census document contains unexpected or missing fields")
    if document["schema"] != CENSUS_SCHEMA:
        raise CensusError("public census schema is unsupported")
    if document["status"] != "live":
        raise CensusError("public census status must be live")
    if not _valid_timestamp(document["generated_at"]):
        raise CensusError("public census generated_at must be an offset-aware timestamp")
    for field in (
        "active_camels",
        "hungry_camels",
        "lost_camels",
        "cargo_loads",
        "active_window_seconds",
        "lost_after_seconds",
    ):
        if not _nonnegative_int(document[field]):
            raise CensusError(f"public census {field} must be a non-negative integer")
    if document["active_window_seconds"] != ACTIVE_WINDOW_SECONDS:
        raise CensusError("public census active window does not match the contract")
    if document["lost_after_seconds"] != LOST_AFTER_SECONDS:
        raise CensusError("public census lost threshold does not match the contract")
    if document["individual_nodes_public"] is not False:
        raise CensusError("public census must not publish individual nodes")
    if document["ip_addresses_public"] is not False:
        raise CensusError("public census must not publish IP addresses")
    return dict(document)


def build_live_document(
    coordinator: CoordinatorState,
    *,
    now: float | None = None,
    generated_at: str | None = None,
) -> dict[str, Any]:
    """Build one live aggregate from authenticated coordinator state.

    Publication remains a separate deployment decision. Callers must not invoke
    this for prepared/local carriers before the authenticated production
    enrollment and coordinator gates are enabled.
    """

    timestamp = time.time() if now is None else float(now)
    counts = coordinator.census_counts(
        now=timestamp,
        active_window=ACTIVE_WINDOW_SECONDS,
        lost_after=LOST_AFTER_SECONDS,
    )
    document = {
        "schema": CENSUS_SCHEMA,
        "status": "live",
        "generated_at": _utc_timestamp(timestamp) if generated_at is None else generated_at,
        "active_camels": counts.active_camels,
        "hungry_camels": counts.hungry_camels,
        "lost_camels": counts.lost_camels,
        "cargo_loads": counts.cargo_loads,
        "active_window_seconds": ACTIVE_WINDOW_SECONDS,
        "lost_after_seconds": LOST_AFTER_SECONDS,
        "individual_nodes_public": False,
        "ip_addresses_public": False,
    }
    return validate_public_document(document)
