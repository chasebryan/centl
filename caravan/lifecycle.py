"""Join, status, and leave lifecycle for the CARAVAN Phase 1 local laboratory."""

from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path
import sqlite3
import stat

from .coordinator import CoordinatorError, CoordinatorState
from .enrollment import register_accepted_carrier
from .identity import CarrierIdentity
from .policy import create_policy_receipt, write_policy_receipt


@dataclass(frozen=True, slots=True)
class CarrierStatus:
    node_id: str
    state: str
    policy_version: str
    agent_version: str
    last_seen: float
    load: float
    capacity: int


class LifecycleError(RuntimeError):
    """Raised when a local carrier lifecycle operation is invalid."""


def _private_root(path: os.PathLike[str] | str) -> Path:
    root = Path(path)
    if root.exists() or root.is_symlink():
        info = os.lstat(root)
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
            raise LifecycleError("CARAVAN lifecycle root must be a real directory")
        if stat.S_IMODE(info.st_mode) & 0o077:
            raise LifecycleError("CARAVAN lifecycle root must be owner-only")
    else:
        root.mkdir(parents=True, mode=0o700)
    return root


def _identity(root: Path) -> CarrierIdentity:
    identity_root = root / "identity"
    if identity_root.exists():
        return CarrierIdentity.load(identity_root)
    return CarrierIdentity.create(identity_root)


def join(
    coordinator: CoordinatorState,
    root: os.PathLike[str] | str,
    *,
    policy_path: os.PathLike[str] | str,
    policy_version: str,
    agent_version: str,
    acceptance_mode: str,
) -> CarrierStatus:
    """Create/load local identity, record policy acceptance, and enroll it."""

    lifecycle_root = _private_root(root)
    identity = _identity(lifecycle_root)
    receipt = create_policy_receipt(
        identity,
        policy_path,
        policy_version=policy_version,
        agent_version=agent_version,
        acceptance_mode=acceptance_mode,
    )
    write_policy_receipt(lifecycle_root / "policy-acceptance.json", receipt)
    register_accepted_carrier(
        coordinator,
        receipt,
        expected_policy_path=policy_path,
        expected_policy_version=policy_version,
    )
    return status(coordinator, lifecycle_root)


def status(
    coordinator: CoordinatorState,
    root: os.PathLike[str] | str,
) -> CarrierStatus:
    lifecycle_root = _private_root(root)
    identity = CarrierIdentity.load(lifecycle_root / "identity")
    connection = sqlite3.connect(coordinator.database)
    connection.row_factory = sqlite3.Row
    try:
        row = connection.execute(
            """SELECT state, policy_version, agent_version, last_seen, load, capacity
               FROM carriers WHERE node_id = ?""",
            (identity.node_id,),
        ).fetchone()
    finally:
        connection.close()
    if row is None:
        raise LifecycleError("local carrier identity is not enrolled in this coordinator")
    return CarrierStatus(
        node_id=identity.node_id,
        state=str(row["state"]),
        policy_version=str(row["policy_version"]),
        agent_version=str(row["agent_version"]),
        last_seen=float(row["last_seen"]),
        load=float(row["load"]),
        capacity=int(row["capacity"]),
    )


def leave(
    coordinator: CoordinatorState,
    root: os.PathLike[str] | str,
) -> CarrierStatus:
    lifecycle_root = _private_root(root)
    identity = CarrierIdentity.load(lifecycle_root / "identity")
    try:
        coordinator.withdraw(identity.node_id)
    except CoordinatorError as exc:
        raise LifecycleError(str(exc)) from exc
    return status(coordinator, lifecycle_root)
