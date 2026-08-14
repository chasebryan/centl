"""Coordinator state model for the CARAVAN Phase 1 laboratory.

The coordinator routes only catalog-approved content identities. It never changes
an artifact identity based on carrier population, reputation, or availability.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import os
import secrets
import sqlite3
import stat
import time
from pathlib import Path
from typing import Iterable

MAX_PENDING_TICKETS = 4096
MAX_TICKET_TTL = 300.0


class CoordinatorError(RuntimeError):
    """Raised for invalid coordinator state transitions or authorizations."""


def _validate_artifact_id(artifact_id: str) -> str:
    prefix = "sha256:"
    if not artifact_id.startswith(prefix):
        raise ValueError("artifact id must use sha256:<digest>")
    digest = artifact_id[len(prefix) :]
    if len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
        raise ValueError("artifact id must contain a 64-character lowercase SHA-256")
    return artifact_id


def _prepare_database_path(database: str | Path) -> str:
    """Create or validate the coordinator database without following a final symlink."""

    value = str(database)
    if value == ":memory:":
        return value

    path = Path(database)
    parent = path.parent
    if parent.exists() or parent.is_symlink():
        info = os.lstat(parent)
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
            raise CoordinatorError("CARAVAN coordinator database parent must be a real directory")
        if stat.S_IMODE(info.st_mode) & 0o022:
            raise CoordinatorError("CARAVAN coordinator database parent must not be group/other writable")
    else:
        parent.mkdir(parents=True, mode=0o700)

    flags = os.O_RDWR
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW

    if path.exists() or path.is_symlink():
        try:
            fd = os.open(path, flags)
        except OSError as exc:
            raise CoordinatorError("unsafe CARAVAN coordinator database path") from exc
    else:
        try:
            fd = os.open(path, flags | os.O_CREAT | os.O_EXCL, 0o600)
        except OSError as exc:
            raise CoordinatorError("could not create CARAVAN coordinator database safely") from exc

    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode):
            raise CoordinatorError("CARAVAN coordinator database must be a regular file")
        os.fchmod(fd, 0o600)
    finally:
        os.close(fd)
    return str(path)


@dataclass(frozen=True, slots=True)
class NetworkStats:
    available_caravans: int
    protected_artifacts: int
    verified_replicas: int


@dataclass(frozen=True, slots=True)
class RetrievalTicket:
    token: str
    node_id: str
    artifact_id: str
    expires_at: float


@dataclass(frozen=True, slots=True)
class CensusCounts:
    active_camels: int
    hungry_camels: int
    lost_camels: int
    cargo_loads: int


class CoordinatorState:
    """SQLite-backed routing state with expiring presence and one-use tickets."""

    def __init__(
        self,
        database: str | Path,
        *,
        heartbeat_ttl: float = 45.0,
        max_pending_tickets: int = MAX_PENDING_TICKETS,
        max_ticket_ttl: float = MAX_TICKET_TTL,
    ) -> None:
        if heartbeat_ttl <= 0:
            raise ValueError("heartbeat_ttl must be positive")
        if max_pending_tickets <= 0:
            raise ValueError("max_pending_tickets must be positive")
        if max_ticket_ttl <= 0:
            raise ValueError("max_ticket_ttl must be positive")
        self.database = _prepare_database_path(database)
        self.heartbeat_ttl = float(heartbeat_ttl)
        self.max_pending_tickets = int(max_pending_tickets)
        self.max_ticket_ttl = float(max_ticket_ttl)
        self._initialize()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.database)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        return connection

    def _initialize(self) -> None:
        with self._connect() as db:
            db.executescript(
                """
                CREATE TABLE IF NOT EXISTS catalog (
                    artifact_id TEXT PRIMARY KEY,
                    length INTEGER NOT NULL CHECK(length >= 0),
                    catalog_version INTEGER NOT NULL CHECK(catalog_version >= 1),
                    distribution TEXT NOT NULL CHECK(distribution IN ('public-approved', 'revoked'))
                );

                CREATE TABLE IF NOT EXISTS carriers (
                    node_id TEXT PRIMARY KEY,
                    caravan_number INTEGER UNIQUE,
                    public_identity TEXT NOT NULL,
                    policy_version TEXT NOT NULL,
                    agent_version TEXT NOT NULL,
                    carrier_class TEXT NOT NULL DEFAULT 'volunteer'
                        CHECK(carrier_class IN ('volunteer', 'fcf-admin')),
                    state TEXT NOT NULL CHECK(state IN ('active', 'quarantined', 'withdrawn')),
                    last_seen REAL NOT NULL,
                    load REAL NOT NULL DEFAULT 0 CHECK(load >= 0),
                    capacity INTEGER NOT NULL DEFAULT 0 CHECK(capacity >= 0)
                );

                CREATE TABLE IF NOT EXISTS replicas (
                    node_id TEXT NOT NULL REFERENCES carriers(node_id) ON DELETE CASCADE,
                    artifact_id TEXT NOT NULL REFERENCES catalog(artifact_id) ON DELETE CASCADE,
                    verified_at REAL NOT NULL,
                    PRIMARY KEY (node_id, artifact_id)
                );

                CREATE TABLE IF NOT EXISTS tickets (
                    token_hash TEXT PRIMARY KEY,
                    node_id TEXT NOT NULL REFERENCES carriers(node_id) ON DELETE CASCADE,
                    artifact_id TEXT NOT NULL REFERENCES catalog(artifact_id) ON DELETE CASCADE,
                    expires_at REAL NOT NULL,
                    used INTEGER NOT NULL DEFAULT 0 CHECK(used IN (0, 1))
                );

                CREATE TABLE IF NOT EXISTS integrity_failures (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    node_id TEXT NOT NULL REFERENCES carriers(node_id) ON DELETE CASCADE,
                    artifact_id TEXT NOT NULL,
                    expected_digest TEXT NOT NULL,
                    observed_digest TEXT NOT NULL,
                    observed_at REAL NOT NULL
                );

                CREATE TABLE IF NOT EXISTS caravan_counters (
                    counter_name TEXT PRIMARY KEY,
                    counter_value INTEGER NOT NULL CHECK(counter_value >= 0)
                );

                INSERT OR IGNORE INTO caravan_counters(counter_name, counter_value)
                    VALUES ('cargo_loads', 0);
                INSERT OR IGNORE INTO caravan_counters(counter_name, counter_value)
                    VALUES ('camel_numbers', 0);
                """
            )
            columns = {row["name"] for row in db.execute("PRAGMA table_info(carriers)")}
            if "carrier_class" not in columns:
                db.execute(
                    "ALTER TABLE carriers ADD COLUMN carrier_class TEXT NOT NULL DEFAULT 'volunteer'"
                )
            if "caravan_number" not in columns:
                db.execute("ALTER TABLE carriers ADD COLUMN caravan_number INTEGER")
            missing = db.execute(
                "SELECT node_id FROM carriers WHERE caravan_number IS NULL ORDER BY rowid"
            ).fetchall()
            for row in missing:
                db.execute(
                    "UPDATE caravan_counters SET counter_value = counter_value + 1 WHERE counter_name = 'camel_numbers'"
                )
                number = db.execute(
                    "SELECT counter_value FROM caravan_counters WHERE counter_name = 'camel_numbers'"
                ).fetchone()[0]
                db.execute(
                    "UPDATE carriers SET caravan_number = ? WHERE node_id = ?",
                    (number, row["node_id"]),
                )

    @staticmethod
    def _purge_expired_tickets(db: sqlite3.Connection, now: float) -> None:
        db.execute("DELETE FROM tickets WHERE expires_at < ?", (now,))

    def apply_authenticated_catalog(
        self,
        targets: Iterable[tuple[str, int, str]],
        *,
        catalog_version: int,
    ) -> None:
        """Replace routing eligibility from already-authenticated catalog data.

        Authentication is deliberately outside the coordinator. Callers must
        pass only targets that have already crossed the CARAVAN TUF trust gate.
        """

        if catalog_version < 1:
            raise ValueError("catalog_version must be positive")
        normalized: list[tuple[str, int, int, str]] = []
        for artifact_id, length, distribution in targets:
            _validate_artifact_id(artifact_id)
            if length < 0:
                raise ValueError("artifact length must be non-negative")
            if distribution not in {"public-approved", "revoked"}:
                raise ValueError("unsupported distribution class for coordinator catalog")
            normalized.append((artifact_id, length, catalog_version, distribution))

        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            db.execute("DELETE FROM replicas")
            db.execute("DELETE FROM tickets")
            db.execute("DELETE FROM catalog")
            db.executemany(
                "INSERT INTO catalog(artifact_id, length, catalog_version, distribution) VALUES (?, ?, ?, ?)",
                normalized,
            )

    def register_carrier(
        self,
        node_id: str,
        *,
        public_identity: str,
        policy_version: str,
        agent_version: str,
        carrier_class: str = "volunteer",
        now: float | None = None,
    ) -> None:
        if not node_id or not public_identity or not policy_version or not agent_version:
            raise ValueError("carrier registration fields must be non-empty")
        if carrier_class not in {"volunteer", "fcf-admin"}:
            raise ValueError("unsupported CARAVAN carrier class")
        timestamp = time.time() if now is None else float(now)
        with self._connect() as db:
            row = db.execute(
                "SELECT public_identity, state FROM carriers WHERE node_id = ?", (node_id,)
            ).fetchone()
            if row is not None and row["public_identity"] != public_identity:
                raise CoordinatorError("node identity collision with different public identity")
            if row is None:
                db.execute(
                    "UPDATE caravan_counters SET counter_value = counter_value + 1 WHERE counter_name = 'camel_numbers'"
                )
                caravan_number = db.execute(
                    "SELECT counter_value FROM caravan_counters WHERE counter_name = 'camel_numbers'"
                ).fetchone()[0]
                db.execute(
                    """INSERT INTO carriers(
                        node_id, caravan_number, public_identity, policy_version, agent_version,
                        carrier_class, state, last_seen
                    ) VALUES (?, ?, ?, ?, ?, ?, 'active', ?)""",
                    (node_id, caravan_number, public_identity, policy_version, agent_version, carrier_class, timestamp),
                )
            elif row["state"] == "withdrawn":
                raise CoordinatorError("withdrawn node identity must not be silently reactivated")
            else:
                db.execute(
                    """UPDATE carriers
                       SET policy_version = ?, agent_version = ?, carrier_class = ?, last_seen = ?
                       WHERE node_id = ?""",
                    (policy_version, agent_version, carrier_class, timestamp, node_id),
                )
            return int(
                db.execute(
                    "SELECT caravan_number FROM carriers WHERE node_id = ?", (node_id,)
                ).fetchone()[0]
            )

    def caravan_number(self, node_id: str) -> int:
        """Return the durable, first-enrollment number assigned to a camel."""

        with self._connect() as db:
            row = db.execute(
                "SELECT caravan_number FROM carriers WHERE node_id = ?", (node_id,)
            ).fetchone()
        if row is None or row["caravan_number"] is None:
            raise CoordinatorError("unknown camel number")
        return int(row["caravan_number"])

    def heartbeat(
        self,
        node_id: str,
        *,
        load: float,
        capacity: int,
        now: float | None = None,
    ) -> None:
        if load < 0 or capacity < 0:
            raise ValueError("load and capacity must be non-negative")
        timestamp = time.time() if now is None else float(now)
        with self._connect() as db:
            row = db.execute("SELECT state FROM carriers WHERE node_id = ?", (node_id,)).fetchone()
            if row is None:
                raise CoordinatorError("unknown carrier")
            if row["state"] != "active":
                raise CoordinatorError(f"carrier is not active: {row['state']}")
            db.execute(
                "UPDATE carriers SET last_seen = ?, load = ?, capacity = ? WHERE node_id = ?",
                (timestamp, float(load), int(capacity), node_id),
            )

    def advertise_replica(
        self,
        node_id: str,
        artifact_id: str,
        *,
        now: float | None = None,
    ) -> None:
        _validate_artifact_id(artifact_id)
        timestamp = time.time() if now is None else float(now)
        with self._connect() as db:
            carrier = db.execute(
                "SELECT state FROM carriers WHERE node_id = ?", (node_id,)
            ).fetchone()
            if carrier is None or carrier["state"] != "active":
                raise CoordinatorError("only active registered carriers may advertise")
            target = db.execute(
                "SELECT distribution FROM catalog WHERE artifact_id = ?", (artifact_id,)
            ).fetchone()
            if target is None or target["distribution"] != "public-approved":
                raise CoordinatorError("carrier may advertise only public-approved catalog artifacts")
            db.execute(
                """INSERT INTO replicas(node_id, artifact_id, verified_at)
                   VALUES (?, ?, ?)
                   ON CONFLICT(node_id, artifact_id)
                   DO UPDATE SET verified_at = excluded.verified_at""",
                (node_id, artifact_id, timestamp),
            )

    def _fresh_cutoff(self, now: float) -> float:
        return now - self.heartbeat_ttl

    def census_counts(
        self,
        *,
        now: float | None = None,
        active_window: float = 1_800.0,
        lost_after: float = 259_200.0,
    ) -> CensusCounts:
        """Return aggregate public census counts from authenticated carriers.

        Active and Lost use the public CARAVAN windows. Withdrawn and
        quarantined carriers are excluded rather than being presented as Lost.
        """
        if active_window <= 0:
            raise ValueError("active_window must be positive")
        if lost_after <= active_window:
            raise ValueError("lost_after must exceed active_window")
        timestamp = time.time() if now is None else float(now)
        active_cutoff = timestamp - float(active_window)
        lost_cutoff = timestamp - float(lost_after)
        with self._connect() as db:
            row = db.execute(
                """SELECT
                       SUM(
                           CASE
                               WHEN state = 'active'
                                AND last_seen >= ?
                                AND last_seen <= ?
                               THEN 1 ELSE 0
                           END
                       ) AS active_count,
                       SUM(
                           CASE
                               WHEN state = 'active'
                                AND last_seen < ?
                                AND last_seen >= ?
                               THEN 1 ELSE 0
                           END
                       ) AS hungry_count,
                       SUM(
                           CASE
                               WHEN state = 'active'
                                AND last_seen < ?
                               THEN 1 ELSE 0
                           END
                       ) AS lost_count
                   FROM carriers""",
                (active_cutoff, timestamp, active_cutoff, lost_cutoff, lost_cutoff),
            ).fetchone()
        return CensusCounts(
            int(row["active_count"] or 0),
            int(row["hungry_count"] or 0),
            int(row["lost_count"] or 0),
            self.cargo_loads(),
        )

    def network_stats(self, *, now: float | None = None) -> NetworkStats:
        timestamp = time.time() if now is None else float(now)
        cutoff = self._fresh_cutoff(timestamp)
        with self._connect() as db:
            available = db.execute(
                """SELECT COUNT(*) AS count FROM (
                       SELECT DISTINCT c.node_id
                       FROM carriers c
                       JOIN replicas r ON r.node_id = c.node_id
                       JOIN catalog a ON a.artifact_id = r.artifact_id
                       WHERE c.state = 'active'
                         AND c.last_seen >= ?
                         AND a.distribution = 'public-approved'
                   )""",
                (cutoff,),
            ).fetchone()["count"]
            protected = db.execute(
                """SELECT COUNT(DISTINCT r.artifact_id) AS count
                   FROM replicas r
                   JOIN carriers c ON c.node_id = r.node_id
                   JOIN catalog a ON a.artifact_id = r.artifact_id
                   WHERE c.state = 'active'
                     AND c.last_seen >= ?
                     AND a.distribution = 'public-approved'""",
                (cutoff,),
            ).fetchone()["count"]
            replicas = db.execute(
                """SELECT COUNT(*) AS count
                   FROM replicas r
                   JOIN carriers c ON c.node_id = r.node_id
                   JOIN catalog a ON a.artifact_id = r.artifact_id
                   WHERE c.state = 'active'
                     AND c.last_seen >= ?
                     AND a.distribution = 'public-approved'""",
                (cutoff,),
            ).fetchone()["count"]
        return NetworkStats(int(available), int(protected), int(replicas))

    def quarantine(self, node_id: str) -> None:
        with self._connect() as db:
            changed = db.execute(
                "UPDATE carriers SET state = 'quarantined' WHERE node_id = ? AND state = 'active'",
                (node_id,),
            ).rowcount
            if changed != 1:
                raise CoordinatorError("carrier cannot be quarantined from current state")
            db.execute("DELETE FROM tickets WHERE node_id = ?", (node_id,))

    def withdraw(self, node_id: str) -> None:
        with self._connect() as db:
            changed = db.execute(
                "UPDATE carriers SET state = 'withdrawn' WHERE node_id = ? AND state != 'withdrawn'",
                (node_id,),
            ).rowcount
            if changed != 1:
                raise CoordinatorError("carrier is already withdrawn or unknown")
            db.execute("DELETE FROM replicas WHERE node_id = ?", (node_id,))
            db.execute("DELETE FROM tickets WHERE node_id = ?", (node_id,))

    def record_integrity_failure(
        self,
        node_id: str,
        artifact_id: str,
        *,
        expected_digest: str,
        observed_digest: str,
        now: float | None = None,
        quarantine: bool = True,
    ) -> None:
        _validate_artifact_id(artifact_id)
        timestamp = time.time() if now is None else float(now)
        with self._connect() as db:
            carrier = db.execute("SELECT state FROM carriers WHERE node_id = ?", (node_id,)).fetchone()
            if carrier is None:
                raise CoordinatorError("unknown carrier")
            db.execute(
                """INSERT INTO integrity_failures(
                    node_id, artifact_id, expected_digest, observed_digest, observed_at
                ) VALUES (?, ?, ?, ?, ?)""",
                (node_id, artifact_id, expected_digest, observed_digest, timestamp),
            )
            if quarantine and carrier["state"] == "active":
                db.execute("UPDATE carriers SET state = 'quarantined' WHERE node_id = ?", (node_id,))
                db.execute("DELETE FROM tickets WHERE node_id = ?", (node_id,))

    def issue_ticket(
        self,
        artifact_id: str,
        *,
        ttl: float = 30.0,
        now: float | None = None,
    ) -> RetrievalTicket:
        _validate_artifact_id(artifact_id)
        if ttl <= 0 or ttl > self.max_ticket_ttl:
            raise ValueError(
                f"ticket ttl must be positive and no greater than {self.max_ticket_ttl:g} seconds"
            )
        timestamp = time.time() if now is None else float(now)
        cutoff = self._fresh_cutoff(timestamp)
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            self._purge_expired_tickets(db, timestamp)
            pending = db.execute(
                "SELECT COUNT(*) AS count FROM tickets WHERE used = 0"
            ).fetchone()["count"]
            if int(pending) >= self.max_pending_tickets:
                raise CoordinatorError("CARAVAN pending retrieval-ticket limit reached")
            target = db.execute(
                "SELECT distribution FROM catalog WHERE artifact_id = ?", (artifact_id,)
            ).fetchone()
            if target is None or target["distribution"] != "public-approved":
                raise CoordinatorError("artifact is not public-approved")
            carrier = db.execute(
                """SELECT c.node_id
                   FROM carriers c
                   JOIN replicas r ON r.node_id = c.node_id
                   WHERE r.artifact_id = ?
                     AND c.state = 'active'
                     AND c.last_seen >= ?
                   ORDER BY c.load ASC, c.last_seen DESC, c.node_id ASC
                   LIMIT 1""",
                (artifact_id, cutoff),
            ).fetchone()
            if carrier is None:
                raise CoordinatorError("no eligible carrier available")
            token = secrets.token_urlsafe(32)
            token_hash = hashlib.sha256(token.encode("ascii")).hexdigest()
            expires_at = timestamp + ttl
            db.execute(
                "INSERT INTO tickets(token_hash, node_id, artifact_id, expires_at, used) VALUES (?, ?, ?, ?, 0)",
                (token_hash, carrier["node_id"], artifact_id, expires_at),
            )
        return RetrievalTicket(token, carrier["node_id"], artifact_id, expires_at)

    def consume_ticket(
        self,
        token: str,
        *,
        node_id: str,
        artifact_id: str,
        now: float | None = None,
    ) -> None:
        _validate_artifact_id(artifact_id)
        if not isinstance(token, str) or not token:
            raise CoordinatorError("retrieval ticket token is required")
        try:
            token_hash = hashlib.sha256(token.encode("ascii")).hexdigest()
        except UnicodeEncodeError as exc:
            raise CoordinatorError("retrieval ticket token must be ASCII") from exc
        timestamp = time.time() if now is None else float(now)
        cutoff = self._fresh_cutoff(timestamp)
        with self._connect() as db:
            db.execute("BEGIN IMMEDIATE")
            self._purge_expired_tickets(db, timestamp)
            ticket = db.execute(
                "SELECT node_id, artifact_id, expires_at, used FROM tickets WHERE token_hash = ?",
                (token_hash,),
            ).fetchone()
            if ticket is None:
                raise CoordinatorError("unknown or expired retrieval ticket")
            if ticket["used"]:
                raise CoordinatorError("retrieval ticket replay rejected")
            if ticket["expires_at"] < timestamp:
                raise CoordinatorError("retrieval ticket expired")
            if ticket["node_id"] != node_id or ticket["artifact_id"] != artifact_id:
                raise CoordinatorError("retrieval ticket binding mismatch")
            carrier = db.execute(
                "SELECT state, last_seen FROM carriers WHERE node_id = ?", (node_id,)
            ).fetchone()
            if carrier is None or carrier["state"] != "active" or carrier["last_seen"] < cutoff:
                raise CoordinatorError("retrieval ticket carrier is no longer eligible")
            # Deletion is the durable one-use transition: replay remains rejected
            # as an unknown ticket without retaining consumed ticket rows forever.
            deleted = db.execute("DELETE FROM tickets WHERE token_hash = ?", (token_hash,)).rowcount
            if deleted != 1:
                raise CoordinatorError("retrieval ticket could not be consumed atomically")

    def record_cargo_load(self, node_id: str, artifact_id: str) -> None:
        """Count one artifact after its bytes pass verified retrieval.

        The counter is aggregate-only. It is not incremented merely because a
        ticket was issued or consumed, and it stores no public carrier identity.
        """
        _validate_artifact_id(artifact_id)
        with self._connect() as db:
            approved = db.execute(
                "SELECT distribution FROM catalog WHERE artifact_id = ?", (artifact_id,)
            ).fetchone()
            if approved is None or approved["distribution"] != "public-approved":
                raise CoordinatorError("only public-approved artifacts count as CARAVAN cargo")
            carrier = db.execute(
                "SELECT state FROM carriers WHERE node_id = ?", (node_id,)
            ).fetchone()
            if carrier is None:
                raise CoordinatorError("unknown carrier")
            db.execute(
                "UPDATE caravan_counters SET counter_value = counter_value + 1 "
                "WHERE counter_name = 'cargo_loads'"
            )

    def cargo_loads(self) -> int:
        """Return the monotonic aggregate of verified CARAVAN cargo loads."""
        with self._connect() as db:
            row = db.execute(
                "SELECT counter_value FROM caravan_counters WHERE counter_name = 'cargo_loads'"
            ).fetchone()
        return int(row["counter_value"] if row is not None else 0)
