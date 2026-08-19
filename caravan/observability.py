"""Privacy-preserving aggregate observability for CARAVAN recruitment.

The coordinator deliberately suppresses request logs and never exposes carrier
identities publicly.  This module keeps that privacy contract while retaining
small durable counters that answer the operational question we actually need:
how many enrollment requests reached the coordinator, how many were accepted or
rejected, and how many distinct accepted carriers reached an authenticated
heartbeat.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from pathlib import Path
import sqlite3
import time
from typing import Any


COUNTER_NAMES = (
    "enrollment_requests",
    "enrollment_accepted",
    "enrollment_rejected",
    "session_challenges_issued",
    "session_completions_succeeded",
)


@dataclass(frozen=True, slots=True)
class ObservabilitySnapshot:
    tracking_started_at: float
    enrollment_requests: int
    enrollment_accepted: int
    enrollment_rejected: int
    enrollment_incomplete: int
    session_challenges_issued: int
    session_completions_succeeded: int
    registered_carriers: int
    highest_caravan_number: int
    first_heartbeat_carriers: int
    active_camels: int
    hungry_camels: int
    lost_camels: int
    withdrawn_carriers: int
    quarantined_carriers: int

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class ObservabilityStore:
    """Store aggregate recruitment telemetry in the coordinator SQLite file.

    No IP address, HTTP header, user agent, request body, public identity, or
    per-request timestamp is retained.  The only per-carrier observability row
    is the already-pseudonymous coordinator node id needed to count a first
    authenticated heartbeat exactly once.
    """

    def __init__(self, database: str | Path) -> None:
        self.database = str(database)
        if self.database == ":memory:":
            raise ValueError("CARAVAN observability requires a file-backed coordinator database")
        self._initialize()

    def _connect(self) -> sqlite3.Connection:
        db = sqlite3.connect(self.database)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys = ON")
        return db

    def _initialize(self) -> None:
        with self._connect() as db:
            db.executescript(
                """
                CREATE TABLE IF NOT EXISTS caravan_observability_counters (
                    name TEXT PRIMARY KEY,
                    value INTEGER NOT NULL DEFAULT 0 CHECK(value >= 0)
                );

                CREATE TABLE IF NOT EXISTS caravan_observability_meta (
                    name TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS caravan_observability_milestones (
                    node_id TEXT PRIMARY KEY,
                    first_heartbeat_at REAL NOT NULL
                );
                """
            )
            db.execute(
                "INSERT OR IGNORE INTO caravan_observability_meta(name, value) VALUES ('started_at', ?)",
                (repr(time.time()),),
            )
            db.executemany(
                "INSERT OR IGNORE INTO caravan_observability_counters(name, value) VALUES (?, 0)",
                ((name,) for name in COUNTER_NAMES),
            )

    def increment(self, name: str) -> None:
        if name not in COUNTER_NAMES:
            raise ValueError(f"unsupported CARAVAN observability counter: {name}")
        with self._connect() as db:
            db.execute(
                "UPDATE caravan_observability_counters SET value = value + 1 WHERE name = ?",
                (name,),
            )

    def record_first_heartbeat(self, node_id: str, *, now: float | None = None) -> bool:
        if not node_id:
            raise ValueError("node_id is required")
        timestamp = time.time() if now is None else float(now)
        with self._connect() as db:
            cursor = db.execute(
                """INSERT OR IGNORE INTO caravan_observability_milestones(
                       node_id, first_heartbeat_at
                   ) VALUES (?, ?)""",
                (node_id, timestamp),
            )
            return cursor.rowcount == 1

    def snapshot(
        self,
        *,
        now: float | None = None,
        active_window: float = 1_800.0,
        lost_after: float = 259_200.0,
    ) -> ObservabilitySnapshot:
        if active_window <= 0:
            raise ValueError("active_window must be positive")
        if lost_after <= active_window:
            raise ValueError("lost_after must exceed active_window")
        timestamp = time.time() if now is None else float(now)
        active_cutoff = timestamp - float(active_window)
        lost_cutoff = timestamp - float(lost_after)

        with self._connect() as db:
            started = db.execute(
                "SELECT value FROM caravan_observability_meta WHERE name = 'started_at'"
            ).fetchone()
            counters = {
                str(row["name"]): int(row["value"])
                for row in db.execute(
                    "SELECT name, value FROM caravan_observability_counters"
                ).fetchall()
            }
            carrier = db.execute(
                """SELECT
                       COUNT(*) AS registered,
                       COALESCE(MAX(caravan_number), 0) AS highest_number,
                       SUM(CASE WHEN state = 'withdrawn' THEN 1 ELSE 0 END) AS withdrawn,
                       SUM(CASE WHEN state = 'quarantined' THEN 1 ELSE 0 END) AS quarantined,
                       SUM(
                           CASE WHEN state = 'active' AND last_seen >= ? AND last_seen <= ?
                                THEN 1 ELSE 0 END
                       ) AS active_count,
                       SUM(
                           CASE WHEN state = 'active' AND last_seen < ? AND last_seen >= ?
                                THEN 1 ELSE 0 END
                       ) AS hungry_count,
                       SUM(
                           CASE WHEN state = 'active' AND last_seen < ?
                                THEN 1 ELSE 0 END
                       ) AS lost_count
                   FROM carriers""",
                (
                    active_cutoff,
                    timestamp,
                    active_cutoff,
                    lost_cutoff,
                    lost_cutoff,
                ),
            ).fetchone()
            first_heartbeats = db.execute(
                "SELECT COUNT(*) AS count FROM caravan_observability_milestones"
            ).fetchone()

        requests = counters.get("enrollment_requests", 0)
        accepted = counters.get("enrollment_accepted", 0)
        rejected = counters.get("enrollment_rejected", 0)
        incomplete = max(0, requests - accepted - rejected)
        return ObservabilitySnapshot(
            tracking_started_at=float(started["value"]) if started else 0.0,
            enrollment_requests=requests,
            enrollment_accepted=accepted,
            enrollment_rejected=rejected,
            enrollment_incomplete=incomplete,
            session_challenges_issued=counters.get("session_challenges_issued", 0),
            session_completions_succeeded=counters.get("session_completions_succeeded", 0),
            registered_carriers=int(carrier["registered"] or 0),
            highest_caravan_number=int(carrier["highest_number"] or 0),
            first_heartbeat_carriers=int(first_heartbeats["count"] or 0),
            active_camels=int(carrier["active_count"] or 0),
            hungry_camels=int(carrier["hungry_count"] or 0),
            lost_camels=int(carrier["lost_count"] or 0),
            withdrawn_carriers=int(carrier["withdrawn"] or 0),
            quarantined_carriers=int(carrier["quarantined"] or 0),
        )
