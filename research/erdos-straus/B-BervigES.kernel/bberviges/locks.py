"""Advisory locks so two hunts can share one findings library."""

from __future__ import annotations

import fcntl
from pathlib import Path


class FileLock:
    """Exclusive flock. Non-blocking acquire returns False if another process holds it."""

    def __init__(self, path: Path):
        self.path = path
        self._fd = None

    def acquire(self, *, blocking: bool = True) -> bool:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._fd = open(self.path, "a+", encoding="utf-8")
        flags = fcntl.LOCK_EX if blocking else fcntl.LOCK_EX | fcntl.LOCK_NB
        try:
            fcntl.flock(self._fd.fileno(), flags)
            return True
        except BlockingIOError:
            self._fd.close()
            self._fd = None
            return False

    def holder_pid(self) -> int | None:
        if self._fd is None:
            return None
        self._fd.seek(0)
        text = self._fd.read().strip()
        if text.isdigit():
            return int(text)
        return None

    def record_pid(self, pid: int) -> None:
        if self._fd is None:
            return
        self._fd.seek(0)
        self._fd.truncate()
        self._fd.write(str(pid))
        self._fd.flush()

    def release(self) -> None:
        if self._fd is None:
            return
        try:
            fcntl.flock(self._fd.fileno(), fcntl.LOCK_UN)
        finally:
            self._fd.close()
            self._fd = None

    def __enter__(self) -> FileLock:
        self.acquire(blocking=True)
        return self

    def __exit__(self, *exc) -> None:
        self.release()
