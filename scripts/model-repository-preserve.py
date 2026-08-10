#!/usr/bin/env python3
"""Preserve an immutable Hugging Face model-repository revision under FCF control.

This is development/reconstruction preservation, distinct from the active GGUF
runtime snapshot. The command records the exact model-hub revision, verifies LFS
SHA-256 or Git blob identities where the hub publishes them, computes an FCF
SHA-256 manifest for every preserved file, and finalizes the whole CENTL mirror.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, NoReturn

ROOT = Path(__file__).resolve().parents[1]
REPO_ID = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def die(message: str) -> NoReturn:
    raise SystemExit(f"centl model repository preserve: {message}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def git_blob_sha1(path: Path) -> str:
    data = path.read_bytes()
    digest = hashlib.sha1()  # Git object identity, not CENTL integrity primitive.
    digest.update(f"blob {len(data)}\0".encode("ascii"))
    digest.update(data)
    return digest.hexdigest()


def safe_relative(name: str) -> Path:
    if not name or "\n" in name or "\r" in name or "\\" in name:
        die(f"unsafe model-repository path: {name!r}")
    path = Path(name)
    if path.is_absolute() or ".." in path.parts:
        die(f"unsafe model-repository path: {name!r}")
    return path


def write_json(path: Path, value: Any) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )


class HubClient:
    def __init__(self, base_url: str) -> None:
        parsed = urllib.parse.urlparse(base_url)
        allow_http = os.environ.get("CENTL_MODEL_PRESERVE_TEST_ALLOW_HTTP") == "1"
        if parsed.scheme != "https":
            if not (
                allow_http
                and parsed.scheme == "http"
                and parsed.hostname in {"127.0.0.1", "localhost", "::1"}
            ):
                die("model hub base URL must use HTTPS")
        if not parsed.netloc:
            die("model hub base URL is invalid")
        self.base_url = base_url.rstrip("/")
        self.origin = (parsed.scheme, parsed.netloc)
        self.token = os.environ.get("HF_TOKEN") or None
        self.requests = 0

    def _request(self, url: str) -> bytes:
        parsed = urllib.parse.urlparse(url)
        if (parsed.scheme, parsed.netloc) != self.origin:
            die(f"refusing model-hub request outside configured origin: {url}")
        headers = {"User-Agent": "centl-fcf-model-preservation/1"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        request = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                data = response.read()
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")[:1000]
            die(f"model hub HTTP {error.code} for {url}: {detail}")
        except urllib.error.URLError as error:
            die(f"model hub request failed for {url}: {error.reason}")
        self.requests += 1
        return data

    def json(self, path: str) -> Any:
        raw = self._request(f"{self.base_url}{path}")
        try:
            return json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            die(f"model hub returned invalid JSON for {path}: {error}")

    def download(self, path: str, output: Path) -> None:
        url = f"{self.base_url}{path}"
        output.parent.mkdir(parents=True, exist_ok=True)
        temporary = output.with_name(output.name + f".part.{os.getpid()}")
        temporary.unlink(missing_ok=True)
        raw = self._request(url)
        temporary.write_bytes(raw)
        temporary.replace(output)


def exact_metadata(client: HubClient, repository: str, revision: str) -> tuple[str, dict[str, Any]]:
    encoded = urllib.parse.quote(repository, safe="/")
    if revision == "main":
        current = client.json(f"/api/models/{encoded}")
        if not isinstance(current, dict):
            die("unexpected model metadata response")
        resolved = current.get("sha")
    else:
        resolved = revision
    if not isinstance(resolved, str) or not HEX40.fullmatch(resolved):
        die(f"model revision did not resolve to a full Git commit: {resolved!r}")
    metadata = client.json(
        f"/api/models/{encoded}/revision/{resolved}?blobs=true"
    )
    if not isinstance(metadata, dict):
        die("unexpected exact model-revision metadata response")
    if metadata.get("sha") not in {None, resolved}:
        die("model hub exact revision response disagrees with requested commit")
    return resolved, metadata


def sibling_identity(sibling: dict[str, Any]) -> tuple[str | None, str | None, int | None]:
    blob = sibling.get("blobId")
    if blob is not None and (not isinstance(blob, str) or not HEX40.fullmatch(blob)):
        die("model hub returned an invalid Git blobId")
    lfs = sibling.get("lfs")
    lfs_sha: str | None = None
    size: int | None = None
    if lfs is not None:
        if not isinstance(lfs, dict):
            die("model hub returned malformed LFS metadata")
        oid = lfs.get("oid")
        if isinstance(oid, str) and oid.startswith("sha256:"):
            oid = oid.removeprefix("sha256:")
        if not isinstance(oid, str) or not HEX64.fullmatch(oid):
            die("model hub LFS metadata has no valid SHA-256 oid")
        lfs_sha = oid
        candidate_size = lfs.get("size")
        if candidate_size is not None:
            if not isinstance(candidate_size, int) or candidate_size < 0:
                die("model hub LFS size is invalid")
            size = candidate_size
    if size is None:
        candidate_size = sibling.get("size")
        if isinstance(candidate_size, int) and candidate_size >= 0:
            size = candidate_size
    return blob, lfs_sha, size


def plan(metadata: dict[str, Any]) -> tuple[list[dict[str, Any]], int | None]:
    siblings = metadata.get("siblings")
    if not isinstance(siblings, list) or not siblings:
        die("model revision metadata contains no files")
    rows: list[dict[str, Any]] = []
    known_total = 0
    all_sizes_known = True
    seen: set[str] = set()
    for raw in siblings:
        if not isinstance(raw, dict):
            die("model revision contains malformed sibling metadata")
        name = raw.get("rfilename")
        if not isinstance(name, str):
            die("model revision sibling has no file name")
        relative = safe_relative(name).as_posix()
        if relative in seen:
            die(f"duplicate model repository file: {relative}")
        seen.add(relative)
        blob, lfs_sha, size = sibling_identity(raw)
        if size is None:
            all_sizes_known = False
        else:
            known_total += size
        rows.append(
            {
                "path": relative,
                "git_blob_sha1": blob,
                "lfs_sha256": lfs_sha,
                "upstream_size": size,
            }
        )
    rows.sort(key=lambda item: item["path"])
    return rows, known_total if all_sizes_known else None


def verify_download(path: Path, row: dict[str, Any]) -> dict[str, Any]:
    if not path.is_file() or path.is_symlink():
        die(f"downloaded model file is missing or unsafe: {path}")
    size = path.stat().st_size
    expected_size = row["upstream_size"]
    if expected_size is not None and size != expected_size:
        die(f"size mismatch for {row['path']}: expected {expected_size}, got {size}")
    lfs_sha = row["lfs_sha256"]
    local_sha = sha256_file(path)
    if lfs_sha is not None and local_sha != lfs_sha:
        die(f"LFS SHA-256 mismatch for {row['path']}: expected {lfs_sha}, got {local_sha}")
    blob = row["git_blob_sha1"]
    if lfs_sha is None and blob is not None:
        local_blob = git_blob_sha1(path)
        if local_blob != blob:
            die(f"Git blob identity mismatch for {row['path']}: expected {blob}, got {local_blob}")
    return {
        **row,
        "bytes": size,
        "fcf_sha256": local_sha,
    }


def finalize(stage: Path) -> None:
    manifest = stage / "REPOSITORY-SHA256SUMS"
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "integrity.py"),
            "tree-manifest",
            "--root",
            str(stage),
            "--output",
            str(manifest),
        ],
        check=True,
    )
    receipt = stage / "REPOSITORY-SHA256SUMS.sha256"
    receipt.write_text(
        f"{sha256_file(manifest)}  REPOSITORY-SHA256SUMS\n",
        encoding="ascii",
        newline="\n",
    )
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "integrity.py"),
            "verify",
            str(receipt),
            "--root",
            str(stage),
        ],
        check=True,
    )
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "integrity.py"),
            "tree-verify",
            str(manifest),
            "--root",
            str(stage),
            "--ignore",
            "REPOSITORY-SHA256SUMS",
            "--ignore",
            "REPOSITORY-SHA256SUMS.sha256",
        ],
        check=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="preserve an immutable model repository revision")
    parser.add_argument("mirror", type=Path)
    parser.add_argument("--repository", default="Qwen/Qwen3-4B-Instruct-2507")
    parser.add_argument("--revision", default="main")
    parser.add_argument("--base-url", default="https://huggingface.co")
    parser.add_argument("--plan", action="store_true", help="resolve/list files without downloading")
    args = parser.parse_args()

    if not REPO_ID.fullmatch(args.repository):
        die("repository must be in owner/name form")
    if args.revision != "main" and not HEX40.fullmatch(args.revision):
        die("revision must be 'main' or a full 40-character Git commit")
    mirror = args.mirror.expanduser().resolve()
    if not mirror.is_dir():
        die(f"preservation mirror not found: {mirror}")

    client = HubClient(args.base_url)
    resolved, metadata = exact_metadata(client, args.repository, args.revision)
    rows, known_total = plan(metadata)
    print(f"repository={args.repository}")
    print(f"revision={resolved}")
    print(f"files={len(rows)}")
    print(f"known_total_bytes={known_total if known_total is not None else 'partial'}")
    if args.plan:
        for row in rows:
            identity = row["lfs_sha256"] or row["git_blob_sha1"] or "unpublished"
            print(f"file={row['path']} identity={identity} size={row['upstream_size']}")
        return 0

    existing_receipt = mirror / "MIRROR-SHA256SUMS"
    if existing_receipt.exists():
        subprocess.run(
            ["sh", str(ROOT / "scripts" / "mirror-receipt"), "verify", str(mirror)],
            check=True,
        )

    safe_repo = args.repository.replace("/", "_")
    repository_root = mirror / "model-repositories" / safe_repo
    target = repository_root / resolved
    if target.exists():
        if not target.is_dir() or target.is_symlink():
            die(f"existing model repository revision is unsafe: {target}")
        subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "integrity.py"),
                "verify",
                str(target / "REPOSITORY-SHA256SUMS.sha256"),
                "--root",
                str(target),
            ],
            check=True,
        )
        subprocess.run(
            [
                sys.executable,
                str(ROOT / "scripts" / "integrity.py"),
                "tree-verify",
                str(target / "REPOSITORY-SHA256SUMS"),
                "--root",
                str(target),
                "--ignore",
                "REPOSITORY-SHA256SUMS",
                "--ignore",
                "REPOSITORY-SHA256SUMS.sha256",
            ],
            check=True,
        )
        print(f"model repository revision already preserved: {target}")
    else:
        repository_root.mkdir(parents=True, exist_ok=True)
        stage = Path(tempfile.mkdtemp(prefix=f".{resolved}.new.", dir=repository_root))
        try:
            files_root = stage / "files"
            identities: list[dict[str, Any]] = []
            encoded_repo = urllib.parse.quote(args.repository, safe="/")
            for row in rows:
                relative = Path(row["path"])
                output = files_root / relative
                encoded_path = "/".join(
                    urllib.parse.quote(part, safe="") for part in relative.parts
                )
                client.download(
                    f"/{encoded_repo}/resolve/{resolved}/{encoded_path}?download=true",
                    output,
                )
                verified = verify_download(output, row)
                identities.append(verified)
                print(f"verified={row['path']} sha256={verified['fcf_sha256']}")

            source = {
                "schema": 1,
                "repository": args.repository,
                "source_url": f"{client.base_url}/{args.repository}",
                "requested_revision": args.revision,
                "resolved_revision": resolved,
                "captured_at_utc": datetime.now(timezone.utc)
                .replace(microsecond=0)
                .isoformat()
                .replace("+00:00", "Z"),
                "license": (
                    metadata.get("cardData", {}).get("license")
                    if isinstance(metadata.get("cardData"), dict)
                    else None
                ),
                "file_count": len(identities),
                "bytes": sum(item["bytes"] for item in identities),
                "token_used": bool(client.token),
                "note": "Private FCF development/reconstruction snapshot; public redistribution is a separate review.",
            }
            write_json(stage / "SOURCE.json", source)
            write_json(stage / "UPSTREAM-IDENTITIES.json", identities)
            finalize(stage)
            stage.rename(target)
        except Exception:
            shutil.rmtree(stage, ignore_errors=True)
            raise

    repository_root.mkdir(parents=True, exist_ok=True)
    (repository_root / "ACTIVE").write_text(
        resolved + "\n", encoding="ascii", newline="\n"
    )
    subprocess.run(
        ["sh", str(ROOT / "scripts" / "mirror-receipt"), "create", str(mirror)],
        check=True,
    )

    print("FCF model repository preservation: PASS")
    print(f"output={target}")
    print(f"requests={client.requests}")
    print(f"token_used={'yes' if client.token else 'no'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
