from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlsplit


class PolicyError(ValueError):
    """Incoming request is outside the fcf-telepathyd capability surface."""


@dataclass(frozen=True)
class PublicReadPolicy:
    """Deny-by-default read-only capability for approved CARAVAN publication."""

    exact_paths: tuple[str, ...] = (
        "/",
        "/index.html",
        "/robots.txt",
        "/status.json",
        "/SHA256SUMS",
        "/source/INDEX.json",
        "/source/centl-main.tar.gz",
        "/source/centl-oasis.tar.gz",
        "/source/centl-mirage.tar.gz",
        "/caravan/catalog-v1.json",
        "/caravan/CATALOG-STATUS",
        "/caravan/INGEST-STATUS.json",
    )
    prefix_paths: tuple[str, ...] = ("/releases/", "/semantic/")
    max_target_bytes: int = 2048

    def authorize(self, method: str, target: str) -> str:
        method = method.upper()
        if method not in {"GET", "HEAD"}:
            raise PolicyError(f"method not permitted: {method}")

        try:
            target_bytes = target.encode("ascii", errors="strict")
        except UnicodeError as exc:
            raise PolicyError("request target must be canonical ASCII") from exc
        if len(target_bytes) > self.max_target_bytes:
            raise PolicyError("request target exceeds fcf-telepathyd limit")
        if any(byte < 0x20 or byte == 0x7F for byte in target_bytes):
            raise PolicyError("control characters are forbidden")
        if "%" in target:
            raise PolicyError("percent-encoded routing is forbidden")

        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc:
            raise PolicyError("absolute-form proxy targets are forbidden")
        if parsed.query or parsed.fragment:
            raise PolicyError("query and fragment routing are forbidden")

        path = parsed.path
        if not path.startswith("/"):
            raise PolicyError("request path must be absolute")
        if "\\" in path or "\x00" in path:
            raise PolicyError("invalid request path")
        if "//" in path:
            raise PolicyError("non-canonical request path")

        segments = path.split("/")
        if any(segment in {".", ".."} for segment in segments):
            raise PolicyError("path traversal is forbidden")

        if path in self.exact_paths:
            return path
        if any(path.startswith(prefix) and len(path) > len(prefix) for prefix in self.prefix_paths):
            return path
        raise PolicyError("path is outside the public-read capability")
