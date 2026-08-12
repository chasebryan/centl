from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path, PurePosixPath
import stat
from typing import BinaryIO


class LiveRootError(ValueError):
    """A requested CARAVAN live object failed the immutable-root contract."""


_CONTENT_TYPES = {
    ".gz": "application/gzip",
    ".html": "text/html; charset=utf-8",
    ".json": "application/json",
    ".txt": "text/plain; charset=utf-8",
}


@dataclass(frozen=True)
class LiveObject:
    path: Path
    stat_result: os.stat_result
    content_type: str

    @property
    def size(self) -> int:
        return int(self.stat_result.st_size)

    @property
    def etag(self) -> str:
        st = self.stat_result
        return f'"{st.st_dev:x}-{st.st_ino:x}-{st.st_size:x}-{st.st_mtime_ns:x}"'

    def open(self) -> BinaryIO:
        handle = self.path.open("rb")
        opened = os.fstat(handle.fileno())
        expected = self.stat_result
        if (
            not stat.S_ISREG(opened.st_mode)
            or opened.st_dev != expected.st_dev
            or opened.st_ino != expected.st_ino
            or opened.st_mode != expected.st_mode
            or opened.st_uid != expected.st_uid
            or opened.st_gid != expected.st_gid
            or opened.st_size != expected.st_size
            or opened.st_mtime_ns != expected.st_mtime_ns
        ):
            handle.close()
            raise LiveRootError("live object changed during open")
        return handle


@dataclass(frozen=True)
class LiveRoot:
    """Read-only view of one CARAVAN publication generation.

    The configured root may be CARAVAN's atomic ``current`` symlink or a direct
    generation path. Its parent is the trusted live anchor. The selected
    generation must remain beneath that anchor, and every object beneath the
    generation must satisfy the immutable publication contract.
    """

    root: Path
    required_uid: int | None = None

    @staticmethod
    def _immutable_mode(mode: int) -> bool:
        return mode & 0o222 == 0

    @staticmethod
    def _trusted_anchor_mode(mode: int) -> bool:
        return mode & 0o022 == 0

    def _require_owner(self, st: os.stat_result, *, label: str) -> None:
        if self.required_uid is not None and st.st_uid != self.required_uid:
            raise LiveRootError(f"{label} owner does not match publication policy")

    def _require_immutable(self, st: os.stat_result, *, label: str) -> None:
        self._require_owner(st, label=label)
        if not self._immutable_mode(st.st_mode):
            raise LiveRootError(f"{label} is writable")

    def _resolved_generation(self) -> Path:
        try:
            anchor = self.root.parent.resolve(strict=True)
            anchor_stat = anchor.stat()
            pointer_stat = self.root.lstat()
            generation = self.root.resolve(strict=True)
            generation_stat = generation.stat()
        except OSError as exc:
            raise LiveRootError("CARAVAN live generation is unavailable") from exc

        if not stat.S_ISDIR(anchor_stat.st_mode):
            raise LiveRootError("CARAVAN live anchor is not a directory")
        self._require_owner(anchor_stat, label="live anchor")
        if not self._trusted_anchor_mode(anchor_stat.st_mode):
            raise LiveRootError("live anchor is group/other writable")

        self._require_owner(pointer_stat, label="live selector")
        if not (stat.S_ISLNK(pointer_stat.st_mode) or stat.S_ISDIR(pointer_stat.st_mode)):
            raise LiveRootError("live selector is neither a symlink nor directory")

        try:
            relative = generation.relative_to(anchor)
        except ValueError as exc:
            raise LiveRootError("CARAVAN live generation escapes the live anchor") from exc
        if not relative.parts:
            raise LiveRootError("CARAVAN live selector resolves to the anchor itself")

        if not stat.S_ISDIR(generation_stat.st_mode):
            raise LiveRootError("CARAVAN live generation is not a directory")
        self._require_immutable(generation_stat, label="live generation")
        return generation

    @staticmethod
    def _parts(path: str) -> tuple[str, ...]:
        relative = "index.html" if path == "/" else path.lstrip("/")
        pure = PurePosixPath(relative)
        if (
            not relative
            or relative.startswith("/")
            or "\\" in relative
            or any(part in {"", ".", ".."} for part in pure.parts)
        ):
            raise LiveRootError("unsafe live-root path")
        return tuple(pure.parts)

    def resolve(self, path: str) -> LiveObject:
        generation = self._resolved_generation()
        current = generation
        parts = self._parts(path)

        for index, part in enumerate(parts):
            current = current / part
            try:
                st = current.lstat()
            except OSError as exc:
                raise LiveRootError("live object is unavailable") from exc
            if stat.S_ISLNK(st.st_mode):
                raise LiveRootError("symbolic links are forbidden inside live generation")
            self._require_immutable(st, label="live object")
            if index < len(parts) - 1:
                if not stat.S_ISDIR(st.st_mode):
                    raise LiveRootError("live path component is not a directory")
            elif not stat.S_ISREG(st.st_mode):
                raise LiveRootError("live object is not a regular file")

        suffix = current.suffix.lower()
        if current.name in {"SHA256SUMS", "CATALOG-STATUS"}:
            content_type = "text/plain; charset=utf-8"
        else:
            content_type = _CONTENT_TYPES.get(suffix, "application/octet-stream")
        return LiveObject(path=current, stat_result=st, content_type=content_type)
