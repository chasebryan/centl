#!/usr/bin/env python3
"""Compile a non-live public CARAVAN candidate from root-approved FCF cargo.

The candidate compiler has no source-network authority. It reads only the
root-owned approved store produced by the networkless preservation ingest gate.
"""
from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import sys
import time
from typing import NoReturn

CHUNK = 4 * 1024 * 1024
BRANCHES = ("main", "oasis", "mirage")
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def die(message: str) -> NoReturn:
    raise SystemExit(f"fcf caravan candidate: {message}")


def sha256(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        die(f"unsafe file: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def safe_tree(root: Path) -> None:
    if root.is_symlink() or not root.is_dir():
        die(f"unsafe directory: {root}")
    for base, dirs, files in os.walk(root, followlinks=False):
        current = Path(base)
        for name in dirs + files:
            path = current / name
            mode = os.lstat(path).st_mode
            if stat.S_ISLNK(mode) or not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
                die(f"symlink/special file rejected: {path}")


def safe_rel(value: str) -> PurePosixPath:
    if not value or value.startswith("/") or "\\" in value:
        die("unsafe approved manifest path")
    path = PurePosixPath(value)
    if any(part in {"", ".", ".."} for part in path.parts):
        die("unsafe approved manifest path segment")
    return path


def verify_manifest(root: Path) -> None:
    safe_tree(root)
    manifest = root / "APPROVED-SHA256SUMS"
    receipt = root / "APPROVED-SHA256SUMS.sha256"
    if manifest.is_symlink() or receipt.is_symlink() or not manifest.is_file() or not receipt.is_file():
        die("approved store is missing complete receipts")
    parts = receipt.read_text(encoding="utf-8").strip().split()
    if len(parts) != 2 or parts[1].lstrip("*") != "APPROVED-SHA256SUMS":
        die("approved receipt-of-receipt has unexpected form")
    if not HEX64.fullmatch(parts[0]) or sha256(manifest) != parts[0]:
        die("approved receipt-of-receipt mismatch")
    listed: set[str] = set()
    for raw in manifest.read_text(encoding="utf-8").splitlines():
        fields = raw.split(None, 1)
        if len(fields) != 2 or not HEX64.fullmatch(fields[0]):
            die("malformed approved manifest")
        rel = fields[1].strip().lstrip("*")
        if rel.startswith("./"):
            rel = rel[2:]
        posix = safe_rel(rel)
        if rel in listed:
            die("duplicate approved manifest path")
        obj = root.joinpath(*posix.parts)
        if obj.is_symlink() or not obj.is_file() or sha256(obj) != fields[0]:
            die(f"approved object failed verification: {rel}")
        listed.add(rel)
    actual = {
        p.relative_to(root).as_posix()
        for p in root.rglob("*")
        if p.is_file() and p.name not in {"APPROVED-SHA256SUMS", "APPROVED-SHA256SUMS.sha256"}
    }
    if listed != actual:
        die("approved store exact-membership failure")


def verify_source_index(source: Path) -> dict[str, object]:
    safe_tree(source)
    expected = {"INDEX.json", *(f"centl-{branch}.tar.gz" for branch in BRANCHES)}
    names = {p.name for p in source.iterdir() if p.is_file()}
    if names != expected or any(p.is_dir() for p in source.iterdir()):
        die("approved source export membership is not exact")
    try:
        data = json.loads((source / "INDEX.json").read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit("fcf caravan candidate: invalid approved source index") from exc
    required = {
        "schema", "repository", "mirror_receipt_sha256", "authorization_sha256", "branches"
    }
    if not isinstance(data, dict) or set(data) != required:
        die("approved source index fields do not match schema")
    if data["schema"] != "centl-fcf-source-index-v2" or data["repository"] != "chasebryan/centl":
        die("approved source index identity is invalid")
    for key in ("mirror_receipt_sha256", "authorization_sha256"):
        if not isinstance(data[key], str) or not HEX64.fullmatch(data[key]):
            die(f"approved source index {key} is invalid")
    branches = data["branches"]
    if not isinstance(branches, dict) or set(branches) != set(BRANCHES):
        die("approved source index must contain exactly main/oasis/mirage")
    for branch in BRANCHES:
        item = branches[branch]
        if not isinstance(item, dict) or set(item) != {"commit", "archive", "sha256"}:
            die(f"approved source index entry invalid: {branch}")
        if item["archive"] != f"centl-{branch}.tar.gz":
            die(f"approved source archive name invalid: {branch}")
        if not isinstance(item["sha256"], str) or not HEX64.fullmatch(item["sha256"]):
            die(f"approved source digest invalid: {branch}")
        archive = source / item["archive"]
        if sha256(archive) != item["sha256"]:
            die(f"approved source archive digest mismatch: {branch}")
    return data


def make_catalog(root: Path, version: int) -> None:
    artifacts = []
    for top in ("source", "releases", "semantic"):
        base = root / top
        if not base.is_dir():
            continue
        for path in sorted(p for p in base.rglob("*") if p.is_file()):
            rel = path.relative_to(root).as_posix()
            whole = hashlib.sha256()
            chunks = []
            offset = 0
            length = 0
            with path.open("rb") as handle:
                while block := handle.read(CHUNK):
                    whole.update(block)
                    chunks.append({
                        "offset": offset,
                        "length": len(block),
                        "sha256": hashlib.sha256(block).hexdigest(),
                    })
                    offset += len(block)
                    length += len(block)
            artifacts.append({
                "logical_path": rel,
                "artifact_id": f"sha256:{whole.hexdigest()}",
                "length": length,
                "distribution": "public-approved",
                "chunks": chunks,
            })
    (root / "caravan" / "catalog-v1.json").write_text(
        json.dumps(
            {"schema": "centl-caravan-catalog-v1", "catalog_version": version, "artifacts": artifacts},
            indent=2,
            sort_keys=True,
        ) + "\n",
        encoding="utf-8",
    )
    (root / "caravan" / "CATALOG-STATUS").write_text(
        "authentication=requires-independent-tuf-target\n"
        "authority=fcf-publication-pipeline\n",
        encoding="utf-8",
    )


def main() -> int:
    node = os.environ.get("FCF_CARAVAN_NODE_ID", "")
    approved = Path(os.environ.get("FCF_CARAVAN_APPROVED_ROOT", "/var/lib/fcf-caravan/approved"))
    candidates = Path(os.environ.get("FCF_CARAVAN_CANDIDATE_ROOT", "/var/lib/fcf-caravan/candidates"))
    state = Path(os.environ.get("FCF_CARAVAN_STATE_ROOT", "/var/lib/fcf-caravan/source-state"))
    keep_raw = os.environ.get("FCF_CARAVAN_KEEP_CANDIDATES", "2")
    if not node or not re.fullmatch(r"[A-Za-z0-9._-]+", node):
        die("unsafe/missing node id")
    try:
        keep = int(keep_raw)
    except ValueError:
        die("candidate retention must be an integer")
    if keep < 2 or keep > 20:
        die("candidate retention must be between 2 and 20")
    for root in (candidates, state):
        if root.is_symlink():
            die(f"root must not be a symlink: {root}")
        root.mkdir(parents=True, exist_ok=True)
    if approved.is_symlink() or not approved.is_dir():
        die("root-approved publication store is missing")

    verify_manifest(approved)
    source_index = verify_source_index(approved / "source")

    build_id = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ") + f"-{os.getpid()}"
    build = candidates / f".build-{build_id}"
    if build.exists():
        shutil.rmtree(build)
    build.mkdir()
    try:
        shutil.copytree(approved / "source", build / "source")
        for name in ("releases", "semantic"):
            if (approved / name).is_dir():
                shutil.copytree(approved / name, build / name)
        (build / "caravan").mkdir()
        if (approved / "INGEST-STATUS.json").is_file():
            shutil.copy2(approved / "INGEST-STATUS.json", build / "caravan" / "INGEST-STATUS.json")

        version_path = state / "catalog-version"
        try:
            last = int(version_path.read_text(encoding="ascii").strip())
        except (FileNotFoundError, ValueError):
            last = 0
        version = max(last + 1, int(time.time()))
        version_path.write_text(f"{version}\n", encoding="ascii")
        make_catalog(build, version)

        ingest = None
        ingest_path = build / "caravan" / "INGEST-STATUS.json"
        if ingest_path.is_file():
            ingest = json.loads(ingest_path.read_text(encoding="utf-8"))
        status = {
            "schema": "fcf-caravan-public-origin-status-v2",
            "node_id": node,
            "mode": "fcf-owned-public-origin",
            "generated_at": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
            "source_branches": source_index["branches"],
            "preservation_ingest": ingest,
            "source_authorization_sha256": source_index["authorization_sha256"],
            "mirror_receipt_sha256": source_index["mirror_receipt_sha256"],
            "uploads": False,
            "proxying": False,
            "arbitrary_paths": False,
        }
        (build / "status.json").write_text(
            json.dumps(status, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        (build / "index.html").write_text(
            f"<!doctype html><meta charset=utf-8><title>FCF CARAVAN · {node}</title>"
            "<style>body{max-width:850px;margin:4rem auto;padding:0 1rem;font:18px/1.5 system-ui;background:#111;color:#eee}a{color:#f3c66b}</style>"
            f"<h1>FCF CARAVAN 🐪</h1><p><b>{node}</b> is an FCF-owned public CENTL origin.</p>"
            "<p>Every served cargo object crossed the FCF preservation and publication boundary. "
            "No uploads. No proxying. No arbitrary filesystem paths.</p><ul>"
            "<li><a href=/source/centl-main.tar.gz>main source</a></li>"
            "<li><a href=/source/centl-oasis.tar.gz>Oasis source</a></li>"
            "<li><a href=/source/centl-mirage.tar.gz>Mirage source</a></li>"
            "<li><a href=/source/INDEX.json>source authorization index</a></li>"
            "<li><a href=/caravan/catalog-v1.json>CARAVAN catalog</a></li>"
            "<li><a href=/status.json>node status</a></li>"
            "<li><a href=/SHA256SUMS>public-tree receipt</a></li></ul>"
            "<p>Good maths should be free.</p>",
            encoding="utf-8",
        )

        safe_tree(build)
        files = sorted(
            p for p in build.rglob("*") if p.is_file() and p.name != "SHA256SUMS"
        )
        manifest = "".join(f"{sha256(p)}  {p.relative_to(build).as_posix()}\n" for p in files)
        (build / "SHA256SUMS").write_text(manifest, encoding="utf-8")
        safe_tree(build)
        for path in build.rglob("*"):
            if path.is_file():
                path.chmod(0o444)
        for path in sorted((p for p in build.rglob("*") if p.is_dir()), reverse=True):
            path.chmod(0o555)
        build.chmod(0o555)

        final = candidates / build_id
        os.rename(build, final)
        ready = candidates / ".READY.new"
        ready.write_text(build_id + "\n", encoding="ascii")
        os.replace(ready, candidates / "READY")

        generations = sorted(
            (p for p in candidates.iterdir() if p.is_dir() and not p.name.startswith(".")),
            key=lambda p: p.name,
            reverse=True,
        )
        for old in generations[keep:]:
            if old == final:
                continue
            for base, dirs, files_old in os.walk(old, topdown=False, followlinks=False):
                for name in files_old:
                    os.chmod(Path(base) / name, 0o600)
                for name in dirs:
                    os.chmod(Path(base) / name, 0o700)
            os.chmod(old, 0o700)
            shutil.rmtree(old)
        print(f"fcf caravan candidate: PASS\ngeneration={build_id}")
        return 0
    finally:
        if build.exists():
            shutil.rmtree(build, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
