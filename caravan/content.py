"""Content-addressed storage primitives for the CARAVAN laboratory.

The store never decides whether an artifact is approved. It only preserves and
verifies bytes against an expected content identity supplied by authenticated
catalog logic.
"""

from __future__ import annotations

from dataclasses import dataclass
import errno
import hashlib
import os
from pathlib import Path
import shutil
import stat
import tempfile
from typing import BinaryIO

READ_SIZE = 1024 * 1024
DEFAULT_CHUNK_SIZE = 4 * 1024 * 1024


class IntegrityError(RuntimeError):
    """Raised when bytes or filesystem state violate a CARAVAN invariant."""


@dataclass(frozen=True, slots=True)
class ArtifactIdentity:
    """Immutable whole-artifact identity."""

    sha256: str
    length: int

    def __post_init__(self) -> None:
        digest = self.sha256.lower()
        if len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
            raise ValueError("sha256 must be exactly 64 lowercase hexadecimal characters")
        if self.length < 0:
            raise ValueError("artifact length must be non-negative")
        object.__setattr__(self, "sha256", digest)

    @property
    def artifact_id(self) -> str:
        return f"sha256:{self.sha256}"

    @classmethod
    def parse(cls, artifact_id: str, length: int) -> "ArtifactIdentity":
        prefix = "sha256:"
        if not artifact_id.startswith(prefix):
            raise ValueError("artifact id must use sha256:<digest>")
        return cls(artifact_id[len(prefix) :], length)


def _open_regular_nofollow(path: Path) -> tuple[int, os.stat_result]:
    flags = os.O_RDONLY
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        fd = os.open(path, flags)
    except OSError as exc:
        if exc.errno in {errno.ELOOP, errno.EMLINK}:
            raise IntegrityError(f"symbolic link rejected: {path}") from exc
        raise
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode):
            raise IntegrityError(f"not a regular file: {path}")
        return fd, info
    except Exception:
        os.close(fd)
        raise


def _digest_stream(stream: BinaryIO) -> ArtifactIdentity:
    digest = hashlib.sha256()
    length = 0
    while True:
        block = stream.read(READ_SIZE)
        if not block:
            break
        digest.update(block)
        length += len(block)
    return ArtifactIdentity(digest.hexdigest(), length)


def hash_file(path: os.PathLike[str] | str) -> ArtifactIdentity:
    fd, _ = _open_regular_nofollow(Path(path))
    try:
        with os.fdopen(fd, "rb", closefd=True) as stream:
            return _digest_stream(stream)
    except Exception:
        try:
            os.close(fd)
        except OSError:
            pass
        raise


def chunk_manifest(
    path: os.PathLike[str] | str, chunk_size: int = DEFAULT_CHUNK_SIZE
) -> list[dict[str, int | str]]:
    """Return deterministic SHA-256 chunk records for an artifact."""

    if chunk_size <= 0:
        raise ValueError("chunk_size must be positive")
    fd, _ = _open_regular_nofollow(Path(path))
    records: list[dict[str, int | str]] = []
    offset = 0
    try:
        with os.fdopen(fd, "rb", closefd=True) as stream:
            while True:
                block = stream.read(chunk_size)
                if not block:
                    break
                records.append(
                    {
                        "offset": offset,
                        "length": len(block),
                        "sha256": hashlib.sha256(block).hexdigest(),
                    }
                )
                offset += len(block)
    except Exception:
        try:
            os.close(fd)
        except OSError:
            pass
        raise
    return records


class ContentStore:
    """User-owned immutable content-addressed artifact store."""

    def __init__(
        self,
        root: os.PathLike[str] | str,
        *,
        max_bytes: int,
        min_free_bytes: int = 0,
    ) -> None:
        if max_bytes < 0 or min_free_bytes < 0:
            raise ValueError("resource limits must be non-negative")
        self.root = Path(root)
        self.max_bytes = max_bytes
        self.min_free_bytes = min_free_bytes
        self._initialize_root()

    def _initialize_root(self) -> None:
        if self.root.exists() or self.root.is_symlink():
            info = os.lstat(self.root)
            if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
                raise IntegrityError("CARAVAN store root must be a real directory")
        else:
            self.root.mkdir(parents=True, mode=0o700)
        (self.root / "objects" / "sha256").mkdir(parents=True, exist_ok=True)
        (self.root / "tmp").mkdir(parents=True, exist_ok=True)
        self._assert_internal_directories()

    def _assert_internal_directories(self) -> None:
        for path in (
            self.root,
            self.root / "objects",
            self.root / "objects" / "sha256",
            self.root / "tmp",
        ):
            info = os.lstat(path)
            if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
                raise IntegrityError(f"unsafe CARAVAN store directory: {path}")

    def _object_path(self, digest: str) -> Path:
        identity = ArtifactIdentity(digest, 0)
        shard = self.root / "objects" / "sha256" / identity.sha256[:2]
        if shard.exists() or shard.is_symlink():
            info = os.lstat(shard)
            if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
                raise IntegrityError(f"unsafe object shard: {shard}")
        else:
            shard.mkdir(mode=0o700)
        return shard / identity.sha256

    def total_bytes(self) -> int:
        total = 0
        base = self.root / "objects" / "sha256"
        for current, dirs, files in os.walk(base, followlinks=False):
            current_path = Path(current)
            for name in list(dirs):
                child = current_path / name
                info = os.lstat(child)
                if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
                    raise IntegrityError(f"unsupported object-store entry: {child}")
            for name in files:
                child = current_path / name
                info = os.lstat(child)
                if not stat.S_ISREG(info.st_mode):
                    raise IntegrityError(f"unsupported object-store entry: {child}")
                total += info.st_size
        return total

    def _check_capacity_for(self, incoming_bytes: int) -> None:
        if self.total_bytes() + incoming_bytes > self.max_bytes:
            raise IntegrityError("CARAVAN storage limit would be exceeded")
        free = shutil.disk_usage(self.root).free
        if free - incoming_bytes < self.min_free_bytes:
            raise IntegrityError("CARAVAN minimum free-disk reserve would be violated")

    def import_file(
        self,
        source: os.PathLike[str] | str,
        *,
        expected: ArtifactIdentity | None = None,
    ) -> ArtifactIdentity:
        """Copy a regular file into immutable storage and return its identity.

        Bytes are hashed from the already-open source descriptor while they are
        copied. Promotion uses a same-filesystem hard link so an existing object
        is never silently replaced.
        """

        self._assert_internal_directories()
        source_path = Path(source)
        source_fd, source_info = _open_regular_nofollow(source_path)
        self._check_capacity_for(source_info.st_size)

        tmp_fd, tmp_name = tempfile.mkstemp(prefix="incoming-", dir=self.root / "tmp")
        tmp_path = Path(tmp_name)
        digest = hashlib.sha256()
        length = 0
        try:
            with os.fdopen(source_fd, "rb", closefd=True) as src, os.fdopen(
                tmp_fd, "wb", closefd=True
            ) as dst:
                while True:
                    block = src.read(READ_SIZE)
                    if not block:
                        break
                    dst.write(block)
                    digest.update(block)
                    length += len(block)
                dst.flush()
                os.fsync(dst.fileno())

            identity = ArtifactIdentity(digest.hexdigest(), length)
            if expected is not None and identity != expected:
                raise IntegrityError(
                    f"artifact identity mismatch: expected {expected.artifact_id}/{expected.length}, "
                    f"got {identity.artifact_id}/{identity.length}"
                )

            self._check_capacity_for(length)
            destination = self._object_path(identity.sha256)
            try:
                os.link(tmp_path, destination, follow_symlinks=False)
                os.chmod(destination, 0o444, follow_symlinks=False)
            except FileExistsError:
                existing = self.verify(identity)
                if existing != identity:
                    raise IntegrityError("existing object does not match its content address")
            return identity
        finally:
            try:
                tmp_path.unlink()
            except FileNotFoundError:
                pass
            for fd in (source_fd, tmp_fd):
                try:
                    os.close(fd)
                except OSError:
                    pass

    def verify(self, identity: ArtifactIdentity) -> ArtifactIdentity:
        path = self._object_path(identity.sha256)
        actual = hash_file(path)
        if actual != identity:
            raise IntegrityError(
                f"stored object failed verification: expected {identity.artifact_id}/{identity.length}, "
                f"got {actual.artifact_id}/{actual.length}"
            )
        return actual

    def path_for_verified(self, identity: ArtifactIdentity) -> Path:
        self.verify(identity)
        return self._object_path(identity.sha256)
