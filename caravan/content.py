"""Content-addressed storage primitives for the CARAVAN laboratory.

The store never decides whether an artifact is approved. It only preserves and
verifies bytes against an expected content identity supplied by authenticated
catalog logic.
"""

from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
import errno
import fcntl
import hashlib
import os
from pathlib import Path
import shutil
import stat
import tempfile
from typing import BinaryIO, Iterator

READ_SIZE = 1024 * 1024
DEFAULT_CHUNK_SIZE = 4 * 1024 * 1024
STORE_LOCK_NAME = ".store.lock"


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
            os.chmod(path, 0o700, follow_symlinks=False)

    def _lock_fd(self) -> int:
        path = self.root / STORE_LOCK_NAME
        flags = os.O_RDWR | os.O_CREAT
        if hasattr(os, "O_CLOEXEC"):
            flags |= os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        try:
            fd = os.open(path, flags, 0o600)
        except OSError as exc:
            if exc.errno in {errno.ELOOP, errno.EMLINK}:
                raise IntegrityError("CARAVAN store lock must not be a symbolic link") from exc
            raise
        try:
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode):
                raise IntegrityError("CARAVAN store lock must be a regular file")
            os.fchmod(fd, 0o600)
            return fd
        except Exception:
            os.close(fd)
            raise

    @contextmanager
    def _exclusive_lock(self) -> Iterator[None]:
        self._assert_internal_directories()
        fd = self._lock_fd()
        try:
            fcntl.flock(fd, fcntl.LOCK_EX)
            yield
        finally:
            try:
                fcntl.flock(fd, fcntl.LOCK_UN)
            finally:
                os.close(fd)

    @contextmanager
    def transfer_guard(self, incoming_bytes: int) -> Iterator[None]:
        """Serialize temporary transfer admission and immutable promotion.

        GNU/Linux is the supported CARAVAN platform. An owner-only ``flock``
        keeps concurrent local import/retrieval operations from all passing the
        same capacity check and collectively exceeding the configured store
        ceiling or free-disk reserve.
        """

        with self._exclusive_lock():
            self._check_capacity_for(incoming_bytes)
            yield

    def _object_path(self, digest: str) -> Path:
        identity = ArtifactIdentity(digest, 0)
        shard = self.root / "objects" / "sha256" / identity.sha256[:2]
        if shard.exists() or shard.is_symlink():
            info = os.lstat(shard)
            if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
                raise IntegrityError(f"unsafe object shard: {shard}")
            os.chmod(shard, 0o700, follow_symlinks=False)
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

    def _check_object_capacity(self, incoming_bytes: int) -> None:
        if incoming_bytes < 0:
            raise ValueError("incoming byte count must be non-negative")
        if incoming_bytes > self.max_bytes:
            raise IntegrityError("artifact exceeds CARAVAN storage limit")
        if self.total_bytes() + incoming_bytes > self.max_bytes:
            raise IntegrityError("CARAVAN storage limit would be exceeded")

    def _check_free_capacity(self, incoming_bytes: int) -> None:
        free = shutil.disk_usage(self.root).free
        if free < incoming_bytes or free - incoming_bytes < self.min_free_bytes:
            raise IntegrityError("CARAVAN minimum free-disk reserve would be violated")

    def _check_capacity_for(self, incoming_bytes: int) -> None:
        self._check_object_capacity(incoming_bytes)
        self._check_free_capacity(incoming_bytes)

    def ensure_capacity(self, incoming_bytes: int) -> None:
        """Reject a transfer before temporary bytes can violate store limits."""

        with self._exclusive_lock():
            self._check_capacity_for(incoming_bytes)

    def _import_file_locked(
        self,
        source_path: Path,
        *,
        expected: ArtifactIdentity | None,
    ) -> ArtifactIdentity:
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

            # The temporary copy already consumes its disk blocks. Re-check the
            # immutable-object ceiling under the same lock, but do not subtract
            # the same bytes from free space twice before hard-link promotion.
            self._check_object_capacity(length)
            destination = self._object_path(identity.sha256)
            try:
                os.link(tmp_path, destination, follow_symlinks=False)
                # CARAVAN objects are immutable and private to the local owner.
                os.chmod(destination, 0o400, follow_symlinks=False)
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

    def import_file(
        self,
        source: os.PathLike[str] | str,
        *,
        expected: ArtifactIdentity | None = None,
        _lock_held: bool = False,
    ) -> ArtifactIdentity:
        """Copy a regular file into immutable storage and return its identity.

        Bytes are hashed from the already-open source descriptor while they are
        copied. Promotion uses a same-filesystem hard link so an existing object
        is never silently replaced. Normal callers are serialized by the store
        lock; CARAVAN retrieval passes ``_lock_held=True`` only while inside the
        store's ``transfer_guard``.
        """

        source_path = Path(source)
        if _lock_held:
            self._assert_internal_directories()
            return self._import_file_locked(source_path, expected=expected)
        with self._exclusive_lock():
            return self._import_file_locked(source_path, expected=expected)

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
