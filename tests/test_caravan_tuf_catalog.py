from __future__ import annotations

import hashlib
import json
from pathlib import Path, PurePosixPath
import tempfile
import unittest
from urllib.parse import unquote, urlparse

from tuf.api.exceptions import DownloadHTTPError
from tuf.ngclient.fetcher import FetcherInterface

from caravan.catalog import (
    CATALOG_SCHEMA,
    CatalogError,
    TufCatalogClient,
    parse_catalog_bytes,
)
from caravan.content import DEFAULT_CHUNK_SIZE
from caravan.tuf_lab import create_lab_repository


class LocalRepositoryFetcher(FetcherInterface):
    """Map fixed HTTPS laboratory URLs to a local TUF repository tree."""

    def __init__(self, metadata_dir: Path, targets_dir: Path) -> None:
        self.metadata_dir = metadata_dir
        self.targets_dir = targets_dir

    @staticmethod
    def _safe_relative(raw: str) -> Path:
        decoded = unquote(raw)
        pure = PurePosixPath(decoded)
        if decoded.startswith("/") or any(part in {"", ".", ".."} for part in pure.parts):
            raise DownloadHTTPError("unsafe laboratory fetch path", 400)
        return Path(*pure.parts)

    def _fetch(self, url: str):
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname != "caravan.test":
            raise DownloadHTTPError("unexpected laboratory host", 404)

        if parsed.path.startswith("/metadata/"):
            relative = self._safe_relative(parsed.path[len("/metadata/") :])
            path = self.metadata_dir / relative
        elif parsed.path.startswith("/targets/"):
            relative = self._safe_relative(parsed.path[len("/targets/") :])
            path = self.targets_dir / relative
        else:
            raise DownloadHTTPError("unknown laboratory path", 404)

        if not path.is_file() or path.is_symlink():
            raise DownloadHTTPError("laboratory repository file not found", 404)
        yield path.read_bytes()


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _artifact(path: str, data: bytes, distribution: str) -> dict[str, object]:
    chunks = []
    for offset in range(0, len(data), DEFAULT_CHUNK_SIZE):
        block = data[offset : offset + DEFAULT_CHUNK_SIZE]
        chunks.append(
            {
                "offset": offset,
                "length": len(block),
                "sha256": _sha(block),
            }
        )
    return {
        "logical_path": path,
        "artifact_id": "sha256:" + _sha(data),
        "length": len(data),
        "distribution": distribution,
        "chunks": chunks,
    }


def _catalog_bytes(artifacts: list[dict[str, object]], version: int = 1) -> bytes:
    return (
        json.dumps(
            {
                "schema": CATALOG_SCHEMA,
                "catalog_version": version,
                "artifacts": artifacts,
            },
            sort_keys=True,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")


class TufCatalogTests(unittest.TestCase):
    def _client(self, root: Path, catalog: bytes) -> tuple[TufCatalogClient, Path, Path]:
        repository = create_lab_repository(root / "repository", catalog)
        client = TufCatalogClient(
            bootstrap_root=repository.bootstrap_root,
            cache_root=root / "cache",
            metadata_base_url="https://caravan.test/metadata/",
            target_base_url="https://caravan.test/targets/",
            fetcher=LocalRepositoryFetcher(repository.metadata_dir, repository.targets_dir),
        )
        return client, repository.metadata_dir, repository.targets_dir

    def test_valid_tuf_chain_authenticates_catalog_and_distribution_boundary(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            public = b"approved CENTL release bytes"
            pending = b"not yet approved"
            revoked = b"revoked historical bytes"
            catalog_bytes = _catalog_bytes(
                [
                    _artifact("releases/centl.tar.gz", public, "public-approved"),
                    _artifact("staging/pending.bin", pending, "pending-review"),
                    _artifact("releases/revoked.tar.gz", revoked, "revoked"),
                ],
                version=7,
            )
            client, _, _ = self._client(root, catalog_bytes)
            catalog = client.refresh()

            self.assertEqual(catalog.version, 7)
            self.assertEqual(len(catalog.artifacts), 3)
            self.assertEqual(len(catalog.public_artifacts()), 1)
            routed = catalog.coordinator_targets()
            self.assertEqual({entry[2] for entry in routed}, {"public-approved", "revoked"})
            self.assertNotIn("pending-review", {entry[2] for entry in routed})

    def test_mutated_catalog_target_is_rejected_by_tuf_hash_verification(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            catalog_bytes = _catalog_bytes(
                [_artifact("releases/centl.tar.gz", b"trusted bytes", "public-approved")]
            )
            client, _, targets_dir = self._client(root, catalog_bytes)
            target = targets_dir / "caravan" / "catalog-v1.json"
            target.write_bytes(target.read_bytes() + b"tamper")
            with self.assertRaises(CatalogError):
                client.refresh()

    def test_mutated_targets_metadata_is_rejected_by_tuf_chain(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            catalog_bytes = _catalog_bytes(
                [_artifact("releases/centl.tar.gz", b"trusted bytes", "public-approved")]
            )
            client, metadata_dir, _ = self._client(root, catalog_bytes)
            targets = metadata_dir / "targets.json"
            data = bytearray(targets.read_bytes())
            data[len(data) // 2] ^= 1
            targets.write_bytes(data)
            with self.assertRaises(CatalogError):
                client.refresh()

    def test_catalog_parser_rejects_path_and_duplicate_identity(self) -> None:
        shared = b"same bytes"
        first = _artifact("good/a.bin", shared, "public-approved")
        traversal = dict(_artifact("good/b.bin", b"other", "public-approved"))
        traversal["logical_path"] = "../escape.bin"
        with self.assertRaises(CatalogError):
            parse_catalog_bytes(_catalog_bytes([first, traversal]))

        duplicate = dict(first)
        duplicate["logical_path"] = "good/c.bin"
        with self.assertRaises(CatalogError):
            parse_catalog_bytes(_catalog_bytes([first, duplicate]))

    def test_catalog_parser_rejects_missing_reordered_and_incomplete_chunks(self) -> None:
        data = b"x" * (DEFAULT_CHUNK_SIZE + 17)
        artifact = _artifact("large/cargo.bin", data, "public-approved")

        missing = json.loads(json.dumps(artifact))
        missing["chunks"] = missing["chunks"][:-1]
        with self.assertRaises(CatalogError):
            parse_catalog_bytes(_catalog_bytes([missing]))

        reordered = json.loads(json.dumps(artifact))
        reordered["chunks"] = list(reversed(reordered["chunks"]))
        with self.assertRaises(CatalogError):
            parse_catalog_bytes(_catalog_bytes([reordered]))

        duplicate = json.loads(json.dumps(artifact))
        duplicate["chunks"] = [duplicate["chunks"][0], duplicate["chunks"][0]]
        with self.assertRaises(CatalogError):
            parse_catalog_bytes(_catalog_bytes([duplicate]))

        appended = json.loads(json.dumps(artifact))
        appended["length"] += 1
        with self.assertRaises(CatalogError):
            parse_catalog_bytes(_catalog_bytes([appended]))

    def test_non_https_catalog_endpoints_are_rejected_outside_loopback_lab(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repository = create_lab_repository(root / "repository", _catalog_bytes([]))
            fetcher = LocalRepositoryFetcher(repository.metadata_dir, repository.targets_dir)
            with self.assertRaises(CatalogError):
                TufCatalogClient(
                    bootstrap_root=repository.bootstrap_root,
                    cache_root=root / "cache",
                    metadata_base_url="http://caravan.test/metadata/",
                    target_base_url="http://caravan.test/targets/",
                    fetcher=fetcher,
                )


if __name__ == "__main__":
    unittest.main()
