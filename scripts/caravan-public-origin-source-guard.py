#!/usr/bin/env python3
"""Independent networkless source-archive guard for CARAVAN activation."""
from __future__ import annotations

import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
import tarfile
from typing import NoReturn

BRANCHES = ("main", "oasis", "mirage")
BUILD_ID = re.compile(r"^[0-9]{8}T[0-9]{6}Z-[0-9]+$")
HEX40 = re.compile(r"^[0-9a-f]{40}$")
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
    ".env",
    ".env.local",
    ".env.production",
    "authorized_keys",
    "credentials",
    "credentials.json",
    "id_dsa",
    "id_ecdsa",
    "id_ed25519",
    "id_rsa",
    "known_hosts",
    "secrets.json",
    "secrets.yaml",
    "secrets.yml",
}
SENSITIVE_SUFFIXES = (".kdbx", ".p12", ".pem", ".pfx")


def die(message: str) -> NoReturn:
    raise SystemExit(f"fcf caravan source guard: {message}")


def safe_rel(value: str) -> PurePosixPath:
    if not value or value.startswith("/") or "\\" in value:
        die("unsafe source path")
    path = PurePosixPath(value)
    if any(part in {"", ".", ".."} for part in path.parts):
        die("unsafe source path segment")
    if any(ord(ch) < 32 or ord(ch) == 127 for ch in value):
        die("control character in source path")
    return path


def guard_archive(path: Path, branch: str) -> None:
    if path.is_symlink() or not path.is_file():
        die(f"missing/unsafe {branch} source archive")
    if path.stat().st_size > 2 * 1024 * 1024 * 1024:
        die(f"{branch} compressed source archive exceeds ceiling")

    prefix = f"centl-{branch}"
    required = {f"{prefix}/README.md", f"{prefix}/LICENSE"}
    seen: set[str] = set()
    count = 0
    expanded = 0
    try:
        archive = tarfile.open(path, mode="r:gz")
    except (OSError, tarfile.TarError) as exc:
        raise SystemExit(f"fcf caravan source guard: unreadable {branch} archive") from exc

    with archive:
        for member in archive:
            count += 1
            if count > 100_000:
                die(f"{branch} archive member ceiling exceeded")
            name = member.name.rstrip("/")
            if not name:
                continue
            rel = safe_rel(name)
            if not rel.parts or rel.parts[0] != prefix:
                die(f"{branch} archive escaped fixed branch prefix")
            if member.issym() or member.islnk() or not (member.isfile() or member.isdir()):
                die(f"{branch} archive contains link/special object: {name}")
            if member.isdir():
                continue

            if member.size < 0 or member.size > 64 * 1024 * 1024:
                die(f"{branch} archive member size rejected: {name}")
            expanded += member.size
            if expanded > 2 * 1024 * 1024 * 1024:
                die(f"{branch} expanded source archive exceeds ceiling")
            seen.add(name)

            base = rel.name.casefold()
            if base in SENSITIVE_NAMES or base.endswith(SENSITIVE_SUFFIXES):
                die(f"{branch} archive contains sensitive filename: {name}")
            if member.size <= 8 * 1024 * 1024:
                stream = archive.extractfile(member)
                if stream is None:
                    die(f"{branch} archive member could not be read: {name}")
                data = stream.read(8 * 1024 * 1024 + 1)
                if len(data) != member.size:
                    die(f"{branch} archive member changed while reading: {name}")
                if PRIVATE_KEY.search(data) or any(pattern.search(data) for pattern in TOKEN_PATTERNS):
                    die(f"{branch} archive contains credential-like material: {name}")

    if not required.issubset(seen):
        die(f"{branch} archive lacks expected CENTL markers")


def main() -> int:
    if os.geteuid() != 0:
        die("source guard must run as root")
    candidates = Path(
        os.environ.get("FCF_CARAVAN_CANDIDATE_ROOT", "/var/lib/fcf-caravan/candidates")
    )
    if candidates.is_symlink() or not candidates.is_dir():
        die("candidate root is missing or unsafe")
    ready = candidates / "READY"
    if ready.is_symlink() or not ready.is_file():
        print("fcf caravan source guard: no candidate ready")
        return 0
    build_id = ready.read_text(encoding="ascii").strip()
    if not BUILD_ID.fullmatch(build_id):
        die("READY contains unsafe candidate id")
    candidate = candidates / build_id
    if candidate.is_symlink() or not candidate.is_dir():
        die("READY candidate is missing or unsafe")
    source = candidate / "source"
    if source.is_symlink() or not source.is_dir():
        die("candidate source directory is missing or unsafe")

    names = {entry.name for entry in source.iterdir()}
    expected = {"INDEX.json", *(f"centl-{branch}.tar.gz" for branch in BRANCHES)}
    if names != expected:
        die("candidate source membership is not exact")

    try:
        index = json.loads((source / "INDEX.json").read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit("fcf caravan source guard: invalid source index") from exc
    if (
        not isinstance(index, dict)
        or set(index) != {"schema", "branches"}
        or index["schema"] != "centl-fcf-source-index-v1"
        or not isinstance(index["branches"], dict)
        or set(index["branches"]) != set(BRANCHES)
    ):
        die("source index schema/branch set mismatch")

    for branch in BRANCHES:
        item = index["branches"][branch]
        if not isinstance(item, dict) or set(item) != {"commit", "archive"}:
            die(f"source index entry invalid: {branch}")
        if not isinstance(item["commit"], str) or not HEX40.fullmatch(item["commit"]):
            die(f"source commit identity invalid: {branch}")
        if item["archive"] != f"centl-{branch}.tar.gz":
            die(f"source archive name invalid: {branch}")
        guard_archive(source / item["archive"], branch)

    print(f"fcf caravan source guard: PASS\ncandidate={build_id}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
