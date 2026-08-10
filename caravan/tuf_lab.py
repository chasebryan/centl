"""Local-only TUF repository builder for the CARAVAN Phase 1 laboratory.

This module is FCF/laboratory tooling. TUF repository signing keys generated here
must never be treated as production publisher keys or shipped with a volunteer
carrier runtime.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import stat

from securesystemslib.signer import CryptoSigner
from tuf.api.metadata import (
    Metadata,
    MetaFile,
    Root,
    Snapshot,
    TargetFile,
    Targets,
    Timestamp,
)

from .catalog import CATALOG_TARGET_PATH


class TufLabError(RuntimeError):
    """Raised when a local laboratory repository cannot be created safely."""


@dataclass(frozen=True, slots=True)
class LabRepository:
    root: Path
    metadata_dir: Path
    targets_dir: Path
    bootstrap_root: bytes


def _expiry(days: int) -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0) + timedelta(days=days)


def _require_new_directory(path: Path) -> None:
    if path.exists() or path.is_symlink():
        raise TufLabError(f"laboratory repository path already exists: {path}")
    path.mkdir(parents=True, mode=0o700)
    info = os.lstat(path)
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
        raise TufLabError("laboratory repository root must be a real directory")


def _write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(path, flags, 0o600)
    try:
        offset = 0
        while offset < len(data):
            written = os.write(fd, data[offset:])
            if written <= 0:
                raise TufLabError(f"failed writing laboratory repository file: {path}")
            offset += written
        os.fsync(fd)
    finally:
        os.close(fd)


def create_lab_repository(
    output_root: os.PathLike[str] | str,
    catalog_bytes: bytes,
) -> LabRepository:
    """Create a fresh single-version TUF repository around catalog_bytes.

    The repository deliberately uses ``consistent_snapshot=False`` in Phase 1
    so the local test fetcher and repository layout remain small and readable.
    The normal TUF root/timestamp/snapshot/targets chain is still verified by
    python-tuf's client workflow.
    """

    if not isinstance(catalog_bytes, bytes):
        raise TypeError("catalog_bytes must be bytes")

    root_path = Path(output_root)
    _require_new_directory(root_path)
    metadata_dir = root_path / "metadata"
    targets_dir = root_path / "targets"
    metadata_dir.mkdir(mode=0o700)
    targets_dir.mkdir(mode=0o700)

    signers = {
        role: CryptoSigner.generate_ed25519()
        for role in ("root", "targets", "snapshot", "timestamp")
    }

    root = Metadata(Root(expires=_expiry(365), consistent_snapshot=False))
    for role, signer in signers.items():
        root.signed.add_key(signer.public_key, role)

    targets = Metadata(Targets(expires=_expiry(30)))
    targets.signed.targets[CATALOG_TARGET_PATH] = TargetFile.from_data(
        CATALOG_TARGET_PATH,
        catalog_bytes,
        ["sha256"],
    )
    targets.sign(signers["targets"])
    targets_bytes = targets.to_bytes()

    snapshot = Metadata(Snapshot(expires=_expiry(7)))
    snapshot.signed.meta["targets.json"] = MetaFile.from_data(
        targets.signed.version,
        targets_bytes,
        ["sha256"],
    )
    snapshot.sign(signers["snapshot"])
    snapshot_bytes = snapshot.to_bytes()

    timestamp = Metadata(Timestamp(expires=_expiry(1)))
    timestamp.signed.snapshot_meta = MetaFile.from_data(
        snapshot.signed.version,
        snapshot_bytes,
        ["sha256"],
    )
    timestamp.sign(signers["timestamp"])
    timestamp_bytes = timestamp.to_bytes()

    root.sign(signers["root"])
    root_bytes = root.to_bytes()

    _write_bytes(metadata_dir / "1.root.json", root_bytes)
    _write_bytes(metadata_dir / "targets.json", targets_bytes)
    _write_bytes(metadata_dir / "snapshot.json", snapshot_bytes)
    _write_bytes(metadata_dir / "timestamp.json", timestamp_bytes)
    _write_bytes(targets_dir / CATALOG_TARGET_PATH, catalog_bytes)

    return LabRepository(root_path, metadata_dir, targets_dir, root_bytes)
