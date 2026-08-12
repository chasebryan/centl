from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import unquote, urlsplit


class PolicyError(ValueError):
    """Incoming request is outside the Telepathy capability surface."""


@dataclass(frozen=True)
class PublicReadPolicy:
    """Deny-by-default read-only capability for public CARAVAN material."""

    exact_paths: tuple[str, ...] = ("/", "/status.json", "/source/INDEX.json")
    prefix_paths: tuple[str, ...] = ("/source/",)
    max_target_bytes: int = 2048

    def authorize(self, method: str, target: str) -> str:
        method = method.upper()
        if method not in {"GET", "HEAD"}:
            raise PolicyError(f"method not permitted: {method}")

        if len(target.encode("utf-8", errors="strict")) > self.max_target_bytes:
            raise PolicyError("request target exceeds Telepathy limit")

        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc:
            raise PolicyError("absolute-form proxy targets are forbidden")
        if parsed.query or parsed.fragment:
            raise PolicyError("query and fragment routing are forbidden")

        try:
            path = unquote(parsed.path, errors="strict")
        except UnicodeError as exc:
            raise PolicyError("invalid request target encoding") from exc

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
        if any(path.startswith(prefix) for prefix in self.prefix_paths):
            return path
        raise PolicyError("path is outside the public-read capability")
