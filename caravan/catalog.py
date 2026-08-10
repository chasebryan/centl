"""Authenticated CARAVAN catalog consumption through python-tuf.

The trusted bootstrap root is supplied by the authenticated CARAVAN agent or
FCF release. Volunteer carriers never supply or redefine the trust anchor.
"""

from __future__ import annotations

from dataclasses import dataclass
import json
import os
from pathlib import Path, PurePosixPath
import stat
from typing import Iterable
from urllib.parse import urlparse

from tuf.api import exceptions as tuf_exceptions
from tuf.ngclient.fetcher import FetcherInterface
from tuf.ngclient.updater import Updater

from .content import ArtifactIdentity, DEFAULT_CHUNK_SIZE

CATALOG_SCHEMA = "centl-caravan-catalog-v1"
CATALOG_TARGET_PATH = "caravan/catalog-v1.json"
MAX_CATALOG_BYTES = 16 * 1024 * 1024
DISTRIBUTION_CLASSES = {
    "public-approved",
    "revoked",
    "pending-review",
    "fcf-preservation-only",
}


class CatalogError(RuntimeError):
    """Raised when authenticated catalog state is invalid or unusable."""


@dataclass(frozen=True, slots=True)
class ChunkRecord:
    offset: int
    length: int
    sha256: str


@dataclass(frozen=True, slots=True)
class CatalogArtifact:
    logical_path: str
    identity: ArtifactIdentity
    distribution: str
    chunks: tuple[ChunkRecord, ...]


@dataclass(frozen=True, slots=True)
class AuthenticatedCatalog:
    version: int
    artifacts: tuple[CatalogArtifact, ...]

    def coordinator_targets(self) -> list[tuple[str, int, str]]:
        return [
            (artifact.identity.artifact_id, artifact.identity.length, artifact.distribution)
            for artifact in self.artifacts
            if artifact.distribution in {"public-approved", "revoked"}
        ]

    def public_artifacts(self) -> tuple[CatalogArtifact, ...]:
        return tuple(
            artifact for artifact in self.artifacts if artifact.distribution == "public-approved"
        )


def _validate_digest(value: object, *, field: str) -> str:
    if not isinstance(value, str):
        raise CatalogError(f"{field} must be a string")
    digest = value.lower()
    if digest != value or len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
        raise CatalogError(f"{field} must be 64 lowercase hexadecimal characters")
    return digest


def _validate_logical_path(value: object) -> str:
    if not isinstance(value, str) or not value:
        raise CatalogError("artifact logical_path must be a non-empty string")
    if "\\" in value or value.startswith("/"):
        raise CatalogError("artifact logical_path must be a relative POSIX path")
    path = PurePosixPath(value)
    parts = path.parts
    if not parts or any(part in {"", ".", ".."} for part in parts):
        raise CatalogError("artifact logical_path contains an unsafe path segment")
    normalized = "/".join(parts)
    if normalized != value:
        raise CatalogError("artifact logical_path must already be canonical")
    return value


def _parse_chunks(value: object, *, artifact_length: int) -> tuple[ChunkRecord, ...]:
    if not isinstance(value, list):
        raise CatalogError("artifact chunks must be an array")
    if artifact_length == 0:
        if value:
            raise CatalogError("zero-length artifact must have no chunks")
        return ()
    if not value:
        raise CatalogError("non-empty artifact must include authenticated chunks")

    chunks: list[ChunkRecord] = []
    expected_offset = 0
    for index, item in enumerate(value):
        if not isinstance(item, dict) or set(item) != {"offset", "length", "sha256"}:
            raise CatalogError("chunk record fields do not match schema")
        offset = item["offset"]
        length = item["length"]
        if not isinstance(offset, int) or isinstance(offset, bool) or offset < 0:
            raise CatalogError("chunk offset must be a non-negative integer")
        if not isinstance(length, int) or isinstance(length, bool) or length <= 0:
            raise CatalogError("chunk length must be a positive integer")
        if offset != expected_offset:
            raise CatalogError("chunks must be contiguous and ordered")
        if length > DEFAULT_CHUNK_SIZE:
            raise CatalogError("chunk exceeds Phase 1 4 MiB chunk size")
        if index < len(value) - 1 and length != DEFAULT_CHUNK_SIZE:
            raise CatalogError("all non-final chunks must be exactly 4 MiB")
        digest = _validate_digest(item["sha256"], field="chunk sha256")
        chunks.append(ChunkRecord(offset, length, digest))
        expected_offset += length

    if expected_offset != artifact_length:
        raise CatalogError("authenticated chunks do not cover exact artifact length")
    return tuple(chunks)


def parse_catalog_bytes(data: bytes) -> AuthenticatedCatalog:
    if len(data) > MAX_CATALOG_BYTES:
        raise CatalogError("CARAVAN catalog exceeds laboratory size limit")
    try:
        raw = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise CatalogError("CARAVAN catalog is not valid UTF-8 JSON") from exc
    if not isinstance(raw, dict) or set(raw) != {"schema", "catalog_version", "artifacts"}:
        raise CatalogError("CARAVAN catalog top-level fields do not match schema")
    if raw["schema"] != CATALOG_SCHEMA:
        raise CatalogError("unsupported CARAVAN catalog schema")
    version = raw["catalog_version"]
    if not isinstance(version, int) or isinstance(version, bool) or version < 1:
        raise CatalogError("catalog_version must be a positive integer")
    if not isinstance(raw["artifacts"], list):
        raise CatalogError("catalog artifacts must be an array")

    artifacts: list[CatalogArtifact] = []
    seen_ids: set[str] = set()
    seen_paths: set[str] = set()
    for item in raw["artifacts"]:
        if not isinstance(item, dict) or set(item) != {
            "logical_path",
            "artifact_id",
            "length",
            "distribution",
            "chunks",
        }:
            raise CatalogError("artifact fields do not match schema")
        logical_path = _validate_logical_path(item["logical_path"])
        artifact_id = item["artifact_id"]
        length = item["length"]
        distribution = item["distribution"]
        if not isinstance(length, int) or isinstance(length, bool) or length < 0:
            raise CatalogError("artifact length must be a non-negative integer")
        if not isinstance(distribution, str) or distribution not in DISTRIBUTION_CLASSES:
            raise CatalogError("artifact distribution class is not recognized")
        try:
            identity = ArtifactIdentity.parse(artifact_id, length)
        except (TypeError, ValueError) as exc:
            raise CatalogError("artifact_id is not a valid SHA-256 content identity") from exc
        if identity.artifact_id in seen_ids:
            raise CatalogError("duplicate artifact content identity")
        if logical_path in seen_paths:
            raise CatalogError("duplicate artifact logical_path")
        chunks = _parse_chunks(item["chunks"], artifact_length=length)
        seen_ids.add(identity.artifact_id)
        seen_paths.add(logical_path)
        artifacts.append(CatalogArtifact(logical_path, identity, distribution, chunks))

    return AuthenticatedCatalog(version, tuple(artifacts))


def _require_safe_cache_directory(path: Path) -> None:
    if path.exists() or path.is_symlink():
        info = os.lstat(path)
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
            raise CatalogError("TUF cache root must be a real directory")
    else:
        path.mkdir(parents=True, mode=0o700)


def _validate_base_url(url: str, *, allow_loopback_http: bool) -> None:
    parsed = urlparse(url)
    if parsed.scheme == "https" and parsed.netloc:
        return
    if (
        allow_loopback_http
        and parsed.scheme == "http"
        and parsed.hostname in {"127.0.0.1", "::1", "localhost"}
    ):
        return
    raise CatalogError("CARAVAN TUF base URLs must use HTTPS outside loopback laboratory mode")


class TufCatalogClient:
    """Consume the CARAVAN catalog only after the python-tuf client workflow."""

    def __init__(
        self,
        *,
        bootstrap_root: bytes,
        cache_root: os.PathLike[str] | str,
        metadata_base_url: str,
        target_base_url: str,
        fetcher: FetcherInterface | None = None,
        allow_loopback_http: bool = False,
    ) -> None:
        if not bootstrap_root:
            raise CatalogError("trusted bootstrap root bytes are required")
        _validate_base_url(metadata_base_url, allow_loopback_http=allow_loopback_http)
        _validate_base_url(target_base_url, allow_loopback_http=allow_loopback_http)
        root = Path(cache_root)
        _require_safe_cache_directory(root)
        metadata_dir = root / "metadata"
        target_dir = root / "targets"
        metadata_dir.mkdir(mode=0o700, exist_ok=True)
        target_dir.mkdir(mode=0o700, exist_ok=True)
        self._updater = Updater(
            str(metadata_dir),
            metadata_base_url,
            str(target_dir),
            target_base_url,
            fetcher=fetcher,
            bootstrap=bootstrap_root,
        )

    def refresh(self) -> AuthenticatedCatalog:
        try:
            targetinfo = self._updater.get_targetinfo(CATALOG_TARGET_PATH)
            if targetinfo is None:
                raise CatalogError("authenticated TUF metadata does not contain CARAVAN catalog target")
            if targetinfo.length > MAX_CATALOG_BYTES:
                raise CatalogError("authenticated CARAVAN catalog target is too large")
            downloaded = self._updater.download_target(targetinfo)
            data = Path(downloaded).read_bytes()
        except CatalogError:
            raise
        except (OSError, tuf_exceptions.RepositoryError, tuf_exceptions.DownloadError) as exc:
            raise CatalogError("TUF catalog refresh or target verification failed") from exc
        return parse_catalog_bytes(data)
