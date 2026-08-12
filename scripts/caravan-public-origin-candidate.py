#!/usr/bin/env python3
"""Build an unprivileged, non-live FCF CARAVAN public-origin candidate."""
from __future__ import annotations

import datetime as dt
import gzip
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import time

CHUNK = 4 * 1024 * 1024
OFFICIAL_SOURCE = "https://github.com/chasebryan/centl.git"
BRANCHES = ("main", "oasis", "mirage")
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


def die(msg: str) -> "NoReturn":
    raise SystemExit(f"fcf caravan candidate: {msg}")


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def git(repo: Path, *args: str, capture: bool = True) -> bytes:
    cmd = ["git", "-c", "core.hooksPath=/dev/null", f"--git-dir={repo}", *args]
    if capture:
        return subprocess.check_output(cmd, timeout=600)
    subprocess.run(cmd, check=True, timeout=600)
    return b""


def safe_tree(root: Path) -> None:
    if root.is_symlink() or not root.is_dir():
        die(f"unsafe directory: {root}")
    for base, dirs, files in os.walk(root, followlinks=False):
        current = Path(base)
        for name in dirs + files:
            p = current / name
            mode = os.lstat(p).st_mode
            if stat.S_ISLNK(mode) or not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
                die(f"symlink/special file rejected: {p}")


def validate_ref(repo: Path, ref: str) -> None:
    if git(repo, "cat-file", "-t", ref).strip() != b"commit":
        die(f"{ref} is not a commit")
    entries = git(repo, "ls-tree", "-r", "-z", "-l", ref).split(b"\0")
    count = 0
    for entry in entries:
        if not entry:
            continue
        count += 1
        if count > 100_000:
            die(f"{ref}: source tree exceeds file ceiling")
        try:
            meta, raw_path = entry.split(b"\t", 1)
            mode, typ, oid, raw_size = meta.split()
            path = raw_path.decode("utf-8", "strict")
            size = int(raw_size)
        except Exception as exc:
            raise SystemExit(f"fcf caravan candidate: malformed tree entry in {ref}") from exc
        if mode not in {b"100644", b"100755"} or typ != b"blob":
            die(f"{ref}: non-regular source entry rejected: {path}")
        p = PurePosixPath(path)
        if (not path or path.startswith("/") or "\\" in path or
                any(part in {"", ".", ".."} for part in p.parts) or
                any(ord(ch) < 32 or ord(ch) == 127 for ch in path)):
            die(f"{ref}: unsafe source path rejected")
        base = p.name.casefold()
        if base in SENSITIVE_NAMES or base.endswith(SENSITIVE_SUFFIXES):
            die(f"{ref}: sensitive filename rejected: {path}")
        if size > 512 * 1024 * 1024:
            die(f"{ref}: oversized source blob rejected: {path}")
        if size <= 8 * 1024 * 1024:
            data = git(repo, "cat-file", "blob", oid.decode())
            if PRIVATE_KEY.search(data) or any(pat.search(data) for pat in TOKEN_PATTERNS):
                die(f"{ref}: credential-like material rejected: {path}")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def verify_manifest(root: Path, manifest: str, receipt: str) -> None:
    m = root / manifest
    r = root / receipt
    if not m.is_file() and not r.is_file():
        return
    if not m.is_file() or not r.is_file() or m.is_symlink() or r.is_symlink():
        die("approved ingest receipt is incomplete or unsafe")
    receipt_parts = r.read_text(encoding="utf-8").strip().split()
    if len(receipt_parts) != 2 or receipt_parts[1].lstrip("*") != manifest:
        die("approved ingest manifest receipt has unexpected form")
    if sha256(m) != receipt_parts[0]:
        die("approved ingest manifest checksum mismatch")

    listed: set[str] = set()
    for line in m.read_text(encoding="utf-8").splitlines():
        parts = line.split(None, 1)
        if len(parts) != 2:
            die("approved ingest manifest contains a malformed line")
        digest, rel = parts
        rel = rel.strip().lstrip("*")
        if rel.startswith("./"):
            rel = rel[2:]
        posix = PurePosixPath(rel)
        if (not rel or rel.startswith("/") or "\\" in rel or
                any(part in {"", ".", ".."} for part in posix.parts)):
            die("approved ingest manifest contains an unsafe path")
        if not re.fullmatch(r"[0-9a-f]{64}", digest):
            die("approved ingest manifest contains an invalid SHA-256")
        if rel in listed:
            die(f"approved ingest manifest duplicates path: {rel}")
        listed.add(rel)
        obj = root.joinpath(*posix.parts)
        if not obj.is_file() or obj.is_symlink() or sha256(obj) != digest:
            die(f"approved ingest object failed verification: {rel}")

    actual = {
        p.relative_to(root).as_posix()
        for p in root.rglob("*")
        if p.is_file() and p.name not in {manifest, receipt}
    }
    if actual != listed:
        missing = sorted(listed - actual)
        extra = sorted(actual - listed)
        detail = []
        if missing:
            detail.append(f"missing={missing[:3]}")
        if extra:
            detail.append(f"extra={extra[:3]}")
        die("approved ingest exact-membership failure: " + ", ".join(detail))


def archive(repo: Path, ref: str, prefix: str, out: Path) -> None:
    proc = subprocess.Popen(
        ["git", "-c", "core.hooksPath=/dev/null", f"--git-dir={repo}",
         "archive", "--format=tar", f"--prefix={prefix}/", ref],
        stdout=subprocess.PIPE,
    )
    assert proc.stdout is not None
    with out.open("wb") as raw, gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as gz:
        while block := proc.stdout.read(1024 * 1024):
            gz.write(block)
    if proc.wait() != 0 or out.stat().st_size == 0:
        die(f"source archive failed: {ref}")


def make_catalog(root: Path, version: int) -> None:
    artifacts = []
    for top in ("source", "releases", "semantic"):
        base = root / top
        if not base.is_dir():
            continue
        for p in sorted(x for x in base.rglob("*") if x.is_file()):
            rel = p.relative_to(root).as_posix()
            whole = hashlib.sha256()
            chunks, offset, length = [], 0, 0
            with p.open("rb") as f:
                while block := f.read(CHUNK):
                    whole.update(block)
                    chunks.append({"offset": offset, "length": len(block),
                                   "sha256": hashlib.sha256(block).hexdigest()})
                    offset += len(block)
                    length += len(block)
            artifacts.append({"logical_path": rel,
                              "artifact_id": f"sha256:{whole.hexdigest()}",
                              "length": length, "distribution": "public-approved",
                              "chunks": chunks})
    data = {"schema": "centl-caravan-catalog-v1", "catalog_version": version,
            "artifacts": artifacts}
    (root / "caravan" / "catalog-v1.json").write_text(
        json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (root / "caravan" / "CATALOG-STATUS").write_text(
        "authentication=requires-independent-tuf-target\n"
        "authority=fcf-publication-pipeline\n", encoding="utf-8")


def main() -> int:
    node = env("FCF_CARAVAN_NODE_ID")
    source_url = env("FCF_CARAVAN_SOURCE_REPO_URL", OFFICIAL_SOURCE)
    state = Path(env("FCF_CARAVAN_STATE_ROOT", "/var/lib/fcf-caravan/source-state"))
    approved = Path(env("FCF_CARAVAN_APPROVED_ROOT", "/var/lib/fcf-caravan/approved"))
    candidates = Path(env("FCF_CARAVAN_CANDIDATE_ROOT", "/var/lib/fcf-caravan/candidates"))
    keep_candidates_raw = env("FCF_CARAVAN_KEEP_CANDIDATES", "2")
    try:
        keep_candidates = int(keep_candidates_raw)
    except ValueError:
        die("candidate retention must be an integer")
    if keep_candidates < 2 or keep_candidates > 20:
        die("candidate retention must be between 2 and 20")
    if not node or not re.fullmatch(r"[A-Za-z0-9._-]+", node):
        die("unsafe/missing node id")
    if source_url != OFFICIAL_SOURCE:
        die("source repository is not the fixed CENTL public source")
    for root in (state, candidates):
        if root.is_symlink():
            die(f"root must not be symlink: {root}")
        root.mkdir(parents=True, exist_ok=True)

    repo = state / "source.git"
    if not repo.exists():
        subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "init", "--bare", str(repo)], check=True)
        git(repo, "remote", "add", "origin", source_url, capture=False)
    elif git(repo, "remote", "get-url", "origin").decode().strip() != source_url:
        die("source remote changed; refusing retarget")
    refspecs = [f"+refs/heads/{b}:refs/remotes/origin/{b}" for b in BRANCHES]
    subprocess.run(["git", "-c", "core.hooksPath=/dev/null", "-c", "protocol.file.allow=never",
                    "-c", "protocol.ext.allow=never", f"--git-dir={repo}", "fetch", "--force",
                    "--prune", "--no-tags", "origin", *refspecs], check=True, timeout=600,
                   env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
    commits = {}
    for branch in BRANCHES:
        ref = f"refs/remotes/origin/{branch}"
        validate_ref(repo, ref)
        commits[branch] = git(repo, "rev-parse", "--verify", f"{ref}^{{commit}}").decode().strip()

    build_id = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ") + f"-{os.getpid()}"
    build = candidates / f".build-{build_id}"
    if build.exists():
        shutil.rmtree(build)
    (build / "source").mkdir(parents=True)
    (build / "caravan").mkdir()
    try:
        index = {"schema": "centl-fcf-source-index-v1", "branches": {}}
        for branch in BRANCHES:
            name = f"centl-{branch}.tar.gz"
            archive(repo, f"refs/remotes/origin/{branch}", f"centl-{branch}", build / "source" / name)
            index["branches"][branch] = {"commit": commits[branch], "archive": name}
        (build / "source" / "INDEX.json").write_text(
            json.dumps(index, indent=2, sort_keys=True) + "\n", encoding="utf-8")

        if approved.is_dir():
            safe_tree(approved)
            verify_manifest(approved, "APPROVED-SHA256SUMS", "APPROVED-SHA256SUMS.sha256")
            for name in ("releases", "semantic"):
                if (approved / name).is_dir():
                    shutil.copytree(approved / name, build / name)
            if (approved / "INGEST-STATUS.json").is_file():
                shutil.copy2(approved / "INGEST-STATUS.json", build / "caravan" / "INGEST-STATUS.json")

        vf = state / "catalog-version"
        try:
            last = int(vf.read_text(encoding="ascii").strip())
        except (FileNotFoundError, ValueError):
            last = 0
        version = max(last + 1, int(time.time()))
        vf.write_text(f"{version}\n", encoding="ascii")
        make_catalog(build, version)

        ingest = None
        ip = build / "caravan" / "INGEST-STATUS.json"
        if ip.is_file():
            ingest = json.loads(ip.read_text(encoding="utf-8"))
        status = {"schema": "fcf-caravan-public-origin-status-v1", "node_id": node,
                  "mode": "fcf-owned-public-origin",
                  "generated_at": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
                  "source_branches": index["branches"], "preservation_ingest": ingest,
                  "uploads": False, "proxying": False, "arbitrary_paths": False}
        (build / "status.json").write_text(json.dumps(status, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        (build / "index.html").write_text(
            f"<!doctype html><meta charset=utf-8><title>FCF CARAVAN · {node}</title>"
            "<style>body{max-width:850px;margin:4rem auto;padding:0 1rem;font:18px/1.5 system-ui;background:#111;color:#eee}a{color:#f3c66b}</style>"
            f"<h1>FCF CARAVAN 🐪</h1><p><b>{node}</b> is an FCF-owned public CENTL origin.</p>"
            "<p>No uploads. No proxying. No arbitrary filesystem paths.</p><ul>"
            "<li><a href=/source/centl-main.tar.gz>main source</a></li>"
            "<li><a href=/source/centl-oasis.tar.gz>Oasis source</a></li>"
            "<li><a href=/source/centl-mirage.tar.gz>Mirage source</a></li>"
            "<li><a href=/caravan/catalog-v1.json>CARAVAN catalog</a></li>"
            "<li><a href=/status.json>status</a></li><li><a href=/SHA256SUMS>SHA-256 receipt</a></li></ul>"
            "<p>Good maths should be free.</p>", encoding="utf-8")

        safe_tree(build)
        files = sorted(p for p in build.rglob("*") if p.is_file() and p.name != "SHA256SUMS")
        with (build / "SHA256SUMS").open("w", encoding="utf-8", newline="\n") as f:
            for p in files:
                f.write(f"{sha256(p)}  {p.relative_to(build).as_posix()}\n")
        safe_tree(build)
        for p in build.rglob("*"):
            os.chmod(p, 0o555 if p.is_dir() else 0o444, follow_symlinks=False)
        os.chmod(build, 0o555)
        final = candidates / build_id
        build.rename(final)
        tmp_ready = candidates / ".READY.new"
        tmp_ready.write_text(build_id + "\n", encoding="ascii")
        os.replace(tmp_ready, candidates / "READY")

        generations = sorted(
            (p for p in candidates.iterdir() if p.is_dir() and not p.name.startswith(".build-")),
            key=lambda p: p.name, reverse=True,
        )
        for old in generations[keep_candidates:]:
            if old.name == build_id or old.is_symlink():
                continue
            for item in old.rglob("*"):
                if item.is_dir():
                    os.chmod(item, 0o755, follow_symlinks=False)
                elif item.is_file():
                    os.chmod(item, 0o644, follow_symlinks=False)
            os.chmod(old, 0o755, follow_symlinks=False)
            shutil.rmtree(old)

        print(f"fcf caravan candidate: PASS\ncandidate={build_id}")
        return 0
    finally:
        if build.exists():
            shutil.rmtree(build, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
