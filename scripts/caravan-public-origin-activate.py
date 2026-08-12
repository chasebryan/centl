#!/usr/bin/env python3
"""Networkless root activation gate for an FCF CARAVAN public origin.

The candidate compiler cannot write the live web root. Activation seizes a ready
candidate into a root-only inbox, freezes it, independently verifies every public
object, compares all FCF-approved cargo byte-for-byte with the root-owned approved
store, and only then switches the live generation.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import sys
import tarfile
from typing import NoReturn

CHUNK = 4 * 1024 * 1024
BRANCHES = ("main", "oasis", "mirage")
HEX40_OR_64 = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
BUILD_ID = re.compile(r"^[0-9]{8}T[0-9]{6}Z-[0-9]+$")
NODE_ID = re.compile(r"^[A-Za-z0-9._-]+$")
TOKEN_PATTERNS = (
    re.compile(rb"github_pat_[A-Za-z0-9_]{40,}"),
    re.compile(rb"gh[pousr]_[A-Za-z0-9]{36,}"),
    re.compile(rb"AKIA[0-9A-Z]{16}"),
    re.compile(rb"sk-proj-[A-Za-z0-9_-]{20,}"),
    re.compile(rb"xox[baprs]-[A-Za-z0-9-]{20,}"),
)
PRIVATE_KEY = re.compile(
    rb"-----BEGIN (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----[\s\S]{100,}"
    rb"-----END (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----"
)
SENSITIVE_NAMES = {
    ".env", ".env.local", ".env.production", "id_rsa", "id_dsa", "id_ecdsa",
    "id_ed25519", "credentials", "credentials.json", "secrets.json", "secrets.yml",
    "secrets.yaml", "authorized_keys", "known_hosts",
}
SENSITIVE_SUFFIXES = (".pem", ".p12", ".pfx", ".kdbx")


def die(message: str) -> NoReturn:
    raise SystemExit(f"fcf caravan activation: {message}")


def sha256(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        die(f"unsafe file: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def safe_rel(value: str) -> PurePosixPath:
    if not value or value.startswith("/") or "\\" in value:
        die("unsafe relative path")
    path = PurePosixPath(value)
    if any(part in {"", ".", ".."} for part in path.parts):
        die("unsafe relative path segment")
    if any(ord(ch) < 32 or ord(ch) == 127 for ch in value):
        die("control character in path")
    return path


def require_safe_tree(root: Path) -> None:
    if root.is_symlink() or not root.is_dir():
        die(f"unsafe tree root: {root}")
    for base, dirs, files in os.walk(root, followlinks=False):
        current = Path(base)
        for name in dirs + files:
            path = current / name
            mode = os.lstat(path).st_mode
            if stat.S_ISLNK(mode):
                die(f"symbolic link rejected: {path}")
            if not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
                die(f"special file rejected: {path}")


def freeze_tree(root: Path) -> None:
    require_safe_tree(root)
    for base, dirs, files in os.walk(root, topdown=False, followlinks=False):
        for name in files:
            path = Path(base) / name
            os.chown(path, 0, 0, follow_symlinks=False)
            os.chmod(path, 0o444, follow_symlinks=False)
        for name in dirs:
            path = Path(base) / name
            os.chown(path, 0, 0, follow_symlinks=False)
            os.chmod(path, 0o555, follow_symlinks=False)
    os.chown(root, 0, 0, follow_symlinks=False)
    os.chmod(root, 0o555, follow_symlinks=False)
    require_safe_tree(root)


def verify_sha_manifest(root: Path, name: str, *, exclude: set[str]) -> None:
    manifest = root / name
    if manifest.is_symlink() or not manifest.is_file():
        die(f"missing/unsafe receipt: {name}")
    listed: dict[str, str] = {}
    for raw in manifest.read_text(encoding="utf-8").splitlines():
        parts = raw.split(None, 1)
        if len(parts) != 2:
            die(f"malformed receipt line in {name}")
        digest, rel = parts
        rel = rel.strip().lstrip("*")
        if rel.startswith("./"):
            rel = rel[2:]
        safe_rel(rel)
        if not HEX64.fullmatch(digest):
            die(f"invalid SHA-256 in {name}")
        if rel in listed:
            die(f"duplicate receipt path in {name}: {rel}")
        path = root.joinpath(*PurePosixPath(rel).parts)
        if path.is_symlink() or not path.is_file() or sha256(path) != digest:
            die(f"receipt verification failed: {rel}")
        listed[rel] = digest
    actual = {
        p.relative_to(root).as_posix()
        for p in root.rglob("*")
        if p.is_file() and p.relative_to(root).as_posix() not in exclude
    }
    if set(listed) != actual:
        die("receipt exact-membership failure")


def verify_approved(root: Path) -> None:
    require_safe_tree(root)
    manifest = root / "APPROVED-SHA256SUMS"
    receipt = root / "APPROVED-SHA256SUMS.sha256"
    if not manifest.is_file() or not receipt.is_file() or manifest.is_symlink() or receipt.is_symlink():
        die("approved store exists without complete receipts")
    parts = receipt.read_text(encoding="utf-8").strip().split()
    if len(parts) != 2 or parts[1].lstrip("*") != "APPROVED-SHA256SUMS":
        die("approved receipt-of-receipt has unexpected form")
    if not HEX64.fullmatch(parts[0]) or sha256(manifest) != parts[0]:
        die("approved receipt-of-receipt mismatch")
    verify_sha_manifest(
        root,
        "APPROVED-SHA256SUMS",
        exclude={"APPROVED-SHA256SUMS", "APPROVED-SHA256SUMS.sha256"},
    )


def compare_tree(left: Path, right: Path, label: str) -> None:
    if left.exists() != right.exists():
        die(f"{label} candidate/approved presence mismatch")
    if not left.exists():
        return
    require_safe_tree(left)
    require_safe_tree(right)
    left_files = {p.relative_to(left).as_posix(): p for p in left.rglob("*") if p.is_file()}
    right_files = {p.relative_to(right).as_posix(): p for p in right.rglob("*") if p.is_file()}
    if set(left_files) != set(right_files):
        die(f"{label} file membership differs from approved store")
    for rel in sorted(left_files):
        a = left_files[rel]
        b = right_files[rel]
        if a.stat().st_size != b.stat().st_size or sha256(a) != sha256(b):
            die(f"{label} bytes differ from approved store: {rel}")


def verify_source_index(root: Path) -> dict[str, object]:
    source = root / "source"
    require_safe_tree(source)
    expected = {"INDEX.json", *(f"centl-{branch}.tar.gz" for branch in BRANCHES)}
    entries = list(source.iterdir())
    if any(p.is_dir() for p in entries) or {p.name for p in entries if p.is_file()} != expected:
        die("source directory membership is not exact")
    try:
        data = json.loads((source / "INDEX.json").read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit("fcf caravan activation: invalid source index JSON") from exc
    required = {
        "schema", "repository", "mirror_receipt_sha256", "authorization_sha256", "branches"
    }
    if not isinstance(data, dict) or set(data) != required:
        die("source index fields do not match schema")
    if data["schema"] != "centl-fcf-source-index-v2" or data["repository"] != "chasebryan/centl":
        die("unsupported source index identity")
    for key in ("mirror_receipt_sha256", "authorization_sha256"):
        if not isinstance(data[key], str) or not HEX64.fullmatch(data[key]):
            die(f"source index {key} invalid")
    branches = data["branches"]
    if not isinstance(branches, dict) or set(branches) != set(BRANCHES):
        die("source index must contain exactly main/oasis/mirage")
    for branch in BRANCHES:
        item = branches[branch]
        if not isinstance(item, dict) or set(item) != {"commit", "archive", "sha256"}:
            die(f"source index entry invalid: {branch}")
        if not isinstance(item["commit"], str) or not HEX40_OR_64.fullmatch(item["commit"]):
            die(f"source index commit invalid: {branch}")
        if item["archive"] != f"centl-{branch}.tar.gz":
            die(f"source index archive invalid: {branch}")
        if not isinstance(item["sha256"], str) or not HEX64.fullmatch(item["sha256"]):
            die(f"source index digest invalid: {branch}")
        if sha256(source / item["archive"]) != item["sha256"]:
            die(f"source archive digest differs from source index: {branch}")
    return data


def verify_source_archive(path: Path, branch: str) -> None:
    prefix = f"centl-{branch}"
    count = 0
    total = 0
    required = {f"{prefix}/README.md", f"{prefix}/LICENSE"}
    seen: set[str] = set()
    try:
        with tarfile.open(path, mode="r:gz") as archive:
            for member in archive:
                count += 1
                if count > 100_000:
                    die(f"{branch} archive exceeds member ceiling")
                name = member.name.rstrip("/")
                if not name:
                    continue
                rel = safe_rel(name)
                if not rel.parts or rel.parts[0] != prefix:
                    die(f"{branch} archive member escaped branch prefix")
                if member.issym() or member.islnk() or not (member.isfile() or member.isdir()):
                    die(f"{branch} archive contains link/special member: {member.name}")
                if not member.isfile():
                    continue
                if member.size < 0 or member.size > 64 * 1024 * 1024:
                    die(f"{branch} archive member size rejected: {member.name}")
                total += member.size
                if total > 2 * 1024 * 1024 * 1024:
                    die(f"{branch} source archive expanded size exceeds ceiling")
                seen.add(name)
                base = PurePosixPath(name).name.casefold()
                if base in SENSITIVE_NAMES or base.endswith(SENSITIVE_SUFFIXES):
                    die(f"{branch} archive contains sensitive filename: {name}")
                stream = archive.extractfile(member)
                if stream is None:
                    die(f"{branch} archive member cannot be read: {name}")
                data = stream.read(64 * 1024 * 1024 + 1)
                if len(data) != member.size:
                    die(f"{branch} archive member length mismatch: {name}")
                if PRIVATE_KEY.search(data) or any(pattern.search(data) for pattern in TOKEN_PATTERNS):
                    die(f"{branch} archive contains credential-like material: {name}")
    except (tarfile.TarError, OSError, UnicodeError) as exc:
        raise SystemExit(f"fcf caravan activation: unreadable {branch} source archive") from exc
    if not required.issubset(seen):
        die(f"{branch} source archive lacks expected CENTL markers")


def load_ingest_status(root: Path) -> object:
    path = root / "caravan" / "INGEST-STATUS.json"
    if not path.exists():
        return None
    if path.is_symlink() or not path.is_file():
        die("ingest status is unsafe")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit("fcf caravan activation: invalid ingest status JSON") from exc


def verify_status(root: Path, source_index: dict[str, object]) -> None:
    try:
        data = json.loads((root / "status.json").read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError, FileNotFoundError) as exc:
        raise SystemExit("fcf caravan activation: invalid node status") from exc
    required = {
        "schema", "node_id", "mode", "generated_at", "source_branches",
        "preservation_ingest", "source_authorization_sha256", "mirror_receipt_sha256",
        "uploads", "proxying", "arbitrary_paths",
    }
    if not isinstance(data, dict) or set(data) != required:
        die("status fields do not match schema")
    if data["schema"] != "fcf-caravan-public-origin-status-v2" or data["mode"] != "fcf-owned-public-origin":
        die("unexpected node status schema/mode")
    if not isinstance(data["node_id"], str) or not NODE_ID.fullmatch(data["node_id"]):
        die("unsafe node id in status")
    for key in ("source_authorization_sha256", "mirror_receipt_sha256"):
        if not isinstance(data[key], str) or not HEX64.fullmatch(data[key]):
            die(f"invalid status {key}")
    if data["source_branches"] != source_index["branches"]:
        die("public status source branches differ from source index")
    if data["source_authorization_sha256"] != source_index["authorization_sha256"]:
        die("public status source authorization differs from source index")
    if data["mirror_receipt_sha256"] != source_index["mirror_receipt_sha256"]:
        die("public status preservation receipt differs from source index")

    ingest = load_ingest_status(root)
    if data["preservation_ingest"] != ingest:
        die("public status preservation metadata differs from ingest status")
    if isinstance(ingest, dict):
        if ingest.get("schema") != "fcf-caravan-approved-ingest-status-v2":
            die("unexpected preservation ingest status schema")
        if ingest.get("preservation_mirror_verified") is not True:
            die("public generation does not report a verified preservation mirror")
        if ingest.get("source_export_present") is not True:
            die("public generation does not report an approved source export")
        if ingest.get("source_authorization_sha256") != source_index["authorization_sha256"]:
            die("ingest source authorization differs from source index")
        if ingest.get("mirror_regular_receipt_sha256") != source_index["mirror_receipt_sha256"]:
            die("ingest preservation receipt differs from source index")
    else:
        die("preservation ingest status is required")

    if data["uploads"] is not False or data["proxying"] is not False or data["arbitrary_paths"] is not False:
        die("candidate attempts to enable forbidden service capabilities")


def verify_catalog(root: Path) -> None:
    try:
        data = json.loads((root / "caravan" / "catalog-v1.json").read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError, FileNotFoundError) as exc:
        raise SystemExit("fcf caravan activation: invalid CARAVAN catalog") from exc
    if not isinstance(data, dict) or set(data) != {"schema", "catalog_version", "artifacts"}:
        die("catalog fields do not match schema")
    if data["schema"] != "centl-caravan-catalog-v1":
        die("unsupported catalog schema")
    if not isinstance(data["catalog_version"], int) or isinstance(data["catalog_version"], bool) or data["catalog_version"] < 1:
        die("invalid catalog version")
    if not isinstance(data["artifacts"], list):
        die("catalog artifacts must be an array")
    paths: set[str] = set()
    ids: set[str] = set()
    for item in data["artifacts"]:
        if not isinstance(item, dict) or set(item) != {"logical_path", "artifact_id", "length", "distribution", "chunks"}:
            die("catalog artifact fields do not match schema")
        rel = item["logical_path"]
        if not isinstance(rel, str):
            die("catalog logical path must be a string")
        posix = safe_rel(rel)
        if posix.parts[0] not in {"source", "releases", "semantic"}:
            die("catalog path outside public cargo roots")
        if rel in paths:
            die("duplicate catalog path")
        obj = root.joinpath(*posix.parts)
        if obj.is_symlink() or not obj.is_file():
            die(f"catalog object missing/unsafe: {rel}")
        digest = sha256(obj)
        artifact_id = item["artifact_id"]
        if artifact_id != f"sha256:{digest}" or artifact_id in ids:
            die(f"catalog identity mismatch: {rel}")
        paths.add(rel)
        ids.add(artifact_id)
        if item["distribution"] != "public-approved" or item["length"] != obj.stat().st_size:
            die(f"catalog length/distribution mismatch: {rel}")
        chunks = item["chunks"]
        if not isinstance(chunks, list):
            die("catalog chunks must be an array")
        offset = 0
        with obj.open("rb") as handle:
            for chunk in chunks:
                if not isinstance(chunk, dict) or set(chunk) != {"offset", "length", "sha256"}:
                    die("catalog chunk fields invalid")
                block = handle.read(CHUNK)
                if not block:
                    die(f"catalog has excess chunks: {rel}")
                if chunk["offset"] != offset or chunk["length"] != len(block) or chunk["sha256"] != hashlib.sha256(block).hexdigest():
                    die(f"catalog chunk mismatch: {rel}")
                offset += len(block)
            if handle.read(1):
                die(f"catalog does not cover complete file: {rel}")
        if offset != obj.stat().st_size:
            die(f"catalog chunk total mismatch: {rel}")
    expected: set[str] = set()
    for top in ("source", "releases", "semantic"):
        base = root / top
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if path.is_file():
                rel = path.relative_to(root).as_posix()
                if rel == "semantic/caravan/catalog-v1.json":
                    continue
                expected.add(rel)
    if paths != expected:
        die("catalog does not exactly enumerate public cargo")


def verify_generation(root: Path, approved: Path) -> None:
    require_safe_tree(root)
    allowed_top = {"index.html", "status.json", "SHA256SUMS", "source", "caravan", "releases", "semantic"}
    names = {p.name for p in root.iterdir()}
    if not names <= allowed_top:
        die("unexpected top-level object")
    if not {"index.html", "status.json", "SHA256SUMS", "source", "caravan"} <= names:
        die("candidate lacks required public-origin objects")
    caravan_names = {p.name for p in (root / "caravan").iterdir()}
    if not caravan_names <= {"catalog-v1.json", "CATALOG-STATUS", "INGEST-STATUS.json"}:
        die("unexpected CARAVAN metadata object")
    if not {"catalog-v1.json", "CATALOG-STATUS", "INGEST-STATUS.json"} <= caravan_names:
        die("required CARAVAN metadata missing")

    verify_sha_manifest(root, "SHA256SUMS", exclude={"SHA256SUMS"})
    source_index = verify_source_index(root)
    branches = source_index["branches"]
    if not isinstance(branches, dict):
        die("source index branches became invalid")
    for branch in BRANCHES:
        item = branches[branch]
        if not isinstance(item, dict):
            die(f"source index entry became invalid: {branch}")
        verify_source_archive(root / "source" / str(item["archive"]), branch)

    verify_status(root, source_index)
    verify_catalog(root)
    verify_approved(approved)
    compare_tree(root / "source", approved / "source", "source export")
    compare_tree(root / "releases", approved / "releases", "release export")
    compare_tree(root / "semantic", approved / "semantic", "semantic export")

    candidate_ingest = root / "caravan" / "INGEST-STATUS.json"
    approved_ingest = approved / "INGEST-STATUS.json"
    if candidate_ingest.exists() != approved_ingest.exists():
        die("ingest status presence differs from approved store")
    if candidate_ingest.exists() and sha256(candidate_ingest) != sha256(approved_ingest):
        die("ingest status differs from approved store")


def relax_for_delete(root: Path) -> None:
    if not root.exists():
        return
    for base, dirs, files in os.walk(root, topdown=False, followlinks=False):
        for name in files:
            try:
                os.chmod(Path(base) / name, 0o600, follow_symlinks=False)
            except OSError:
                pass
        for name in dirs:
            try:
                os.chmod(Path(base) / name, 0o700, follow_symlinks=False)
            except OSError:
                pass
    try:
        os.chmod(root, 0o700, follow_symlinks=False)
    except OSError:
        pass


def main() -> int:
    if os.geteuid() != 0:
        die("activation must run as root")
    candidates = Path(os.environ.get("FCF_CARAVAN_CANDIDATE_ROOT", "/var/lib/fcf-caravan/candidates"))
    approved = Path(os.environ.get("FCF_CARAVAN_APPROVED_ROOT", "/var/lib/fcf-caravan/approved"))
    inbox = Path(os.environ.get("FCF_CARAVAN_ACTIVATION_INBOX", "/var/lib/fcf-caravan/activation-inbox"))
    live = Path(os.environ.get("FCF_CARAVAN_LIVE_ROOT", "/srv/fcf-caravan-live"))
    try:
        keep = int(os.environ.get("FCF_CARAVAN_KEEP_LIVE", "3"))
    except ValueError:
        die("live retention must be an integer")
    if keep < 2 or keep > 20:
        die("live retention must be between 2 and 20")
    for root in (candidates, approved, inbox, live):
        if root.is_symlink():
            die(f"root must not be a symlink: {root}")
    require_safe_tree(approved)
    inbox.mkdir(parents=True, mode=0o700, exist_ok=True)
    live.mkdir(parents=True, mode=0o755, exist_ok=True)
    (live / "generations").mkdir(mode=0o755, exist_ok=True)

    ready = candidates / "READY"
    if not ready.is_file() or ready.is_symlink():
        print("fcf caravan activation: no candidate ready")
        return 0
    build_id = ready.read_text(encoding="ascii").strip()
    if not BUILD_ID.fullmatch(build_id):
        die("READY contains unsafe candidate id")
    source = candidates / build_id
    if source.is_symlink() or not source.is_dir():
        die("READY candidate is missing or unsafe")

    claimed = inbox / f"claimed-{build_id}"
    if claimed.exists():
        die("activation inbox collision")
    os.rename(source, claimed)
    try:
        if ready.is_file() and not ready.is_symlink() and ready.read_text(encoding="ascii").strip() == build_id:
            ready.unlink()
    except FileNotFoundError:
        pass

    stage = live / "generations" / f".stage-{build_id}"
    final = live / "generations" / build_id
    try:
        freeze_tree(claimed)
        if stage.exists() or final.exists():
            die("live generation collision")
        shutil.copytree(claimed, stage, symlinks=True, copy_function=shutil.copyfile)
        require_safe_tree(stage)
        verify_generation(stage, approved)
        freeze_tree(stage)
        os.rename(stage, final)
        pointer = live / ".current.new"
        try:
            pointer.unlink()
        except FileNotFoundError:
            pass
        pointer.symlink_to(Path("generations") / build_id)
        os.replace(pointer, live / "current")
        generations = sorted(
            (p for p in (live / "generations").iterdir() if p.is_dir() and BUILD_ID.fullmatch(p.name)),
            key=lambda p: p.name,
            reverse=True,
        )
        for old in generations[keep:]:
            if old == final:
                continue
            relax_for_delete(old)
            shutil.rmtree(old)
        print(f"fcf caravan activation: PASS\ngeneration={build_id}")
        return 0
    finally:
        if stage.exists():
            relax_for_delete(stage)
            shutil.rmtree(stage, ignore_errors=True)
        if claimed.exists():
            relax_for_delete(claimed)
            shutil.rmtree(claimed, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
