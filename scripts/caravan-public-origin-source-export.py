#!/usr/bin/env python3
"""Export explicitly authorized CENTL source from a verified FCF preservation bundle.

This program deliberately has no network path. Source becomes publishable only when:
  * the FCF preservation mirror has already passed mirror-receipt verification;
  * an operator-created authorization names the exact preservation receipt; and
  * the exact main/oasis/mirage commits named by that authorization exist in the
    preserved CENTL Git bundle and pass the public-source safety policy.

A changed preservation snapshot invalidates the authorization instead of silently
publishing newer bytes.
"""
from __future__ import annotations

import argparse
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
import tempfile
from typing import NoReturn

BRANCHES = ("main", "oasis", "mirage")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
HEX_COMMIT = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
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
    raise SystemExit(f"fcf caravan source export: {message}")


def regular(path: Path, label: str) -> os.stat_result:
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        die(f"{label} is missing: {path}")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        die(f"{label} must be a regular non-symlink file: {path}")
    return info


def safe_dir(path: Path, label: str) -> None:
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        die(f"{label} is missing: {path}")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
        die(f"{label} must be a normal directory: {path}")


def sha256(path: Path) -> str:
    regular(path, "file")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def load_authorization(path: Path, mirror: Path) -> dict[str, str]:
    regular(path, "source authorization")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise SystemExit("fcf caravan source export: invalid authorization JSON") from exc
    if not isinstance(data, dict) or set(data) != {
        "schema", "repository", "mirror_receipt_sha256", "branches"
    }:
        die("authorization fields do not match schema")
    if data["schema"] != "fcf-caravan-source-authorization-v1":
        die("unsupported source authorization schema")
    if data["repository"] != "chasebryan/centl":
        die("authorization repository is not CENTL")
    receipt = data["mirror_receipt_sha256"]
    if not isinstance(receipt, str) or not HEX64.fullmatch(receipt):
        die("authorization mirror receipt is not a SHA-256")
    actual_receipt = sha256(mirror / "MIRROR-SHA256SUMS")
    if receipt != actual_receipt:
        die("source authorization is stale for this preservation snapshot")
    branches = data["branches"]
    if not isinstance(branches, dict) or set(branches) != set(BRANCHES):
        die("authorization must name exactly main/oasis/mirage")
    result: dict[str, str] = {}
    for branch in BRANCHES:
        commit = branches[branch]
        if not isinstance(commit, str) or not HEX_COMMIT.fullmatch(commit):
            die(f"invalid authorized commit for {branch}")
        result[branch] = commit
    return result


def git(repo: Path, *args: str, capture: bool = True) -> bytes:
    cmd = ["git", "-c", "core.hooksPath=/dev/null", f"--git-dir={repo}", *args]
    if capture:
        return subprocess.check_output(cmd, timeout=600)
    subprocess.run(cmd, check=True, timeout=600)
    return b""


def validate_commit(repo: Path, commit: str, branch: str) -> None:
    try:
        if git(repo, "cat-file", "-t", commit).strip() != b"commit":
            die(f"authorized {branch} object is not a commit")
    except subprocess.CalledProcessError as exc:
        raise SystemExit(
            f"fcf caravan source export: authorized {branch} commit is absent from preservation bundle"
        ) from exc
    entries = git(repo, "ls-tree", "-r", "-z", "-l", commit).split(b"\0")
    count = 0
    for entry in entries:
        if not entry:
            continue
        count += 1
        if count > 100_000:
            die(f"{branch}: source tree exceeds file ceiling")
        try:
            meta, raw_path = entry.split(b"\t", 1)
            mode, typ, oid, raw_size = meta.split()
            path = raw_path.decode("utf-8", "strict")
            size = int(raw_size)
        except Exception as exc:
            raise SystemExit(f"fcf caravan source export: malformed {branch} tree entry") from exc
        if mode not in {b"100644", b"100755"} or typ != b"blob":
            die(f"{branch}: non-regular source entry rejected: {path}")
        posix = PurePosixPath(path)
        if (
            not path or path.startswith("/") or "\\" in path
            or any(part in {"", ".", ".."} for part in posix.parts)
            or any(ord(ch) < 32 or ord(ch) == 127 for ch in path)
        ):
            die(f"{branch}: unsafe source path rejected")
        base = posix.name.casefold()
        if base in SENSITIVE_NAMES or base.endswith(SENSITIVE_SUFFIXES):
            die(f"{branch}: sensitive filename rejected: {path}")
        if size > 512 * 1024 * 1024:
            die(f"{branch}: oversized source blob rejected: {path}")
        if size <= 8 * 1024 * 1024:
            data = git(repo, "cat-file", "blob", oid.decode())
            if PRIVATE_KEY.search(data) or any(pattern.search(data) for pattern in TOKEN_PATTERNS):
                die(f"{branch}: credential-like material rejected: {path}")


def archive(repo: Path, commit: str, branch: str, out: Path) -> None:
    proc = subprocess.Popen(
        ["git", "-c", "core.hooksPath=/dev/null", f"--git-dir={repo}",
         "archive", "--format=tar", f"--prefix=centl-{branch}/", commit],
        stdout=subprocess.PIPE,
    )
    assert proc.stdout is not None
    with out.open("wb") as raw, gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as gz:
        while block := proc.stdout.read(1024 * 1024):
            gz.write(block)
    if proc.wait() != 0 or not out.is_file() or out.stat().st_size == 0:
        die(f"failed to archive authorized {branch} source")


def export(mirror: Path, authorization: Path, output: Path) -> None:
    safe_dir(mirror, "preservation mirror")
    bundle = mirror / "project" / "centl.bundle"
    regular(bundle, "preserved CENTL bundle")
    branches = load_authorization(authorization, mirror)
    if output.exists() or output.is_symlink():
        die("source export output must not already exist")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="fcf-caravan-source-") as td:
        repo = Path(td) / "centl.git"
        subprocess.run(
            ["git", "-c", "protocol.file.allow=always", "clone", "--mirror", "--no-local",
             str(bundle), str(repo)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=600,
        )
        output.mkdir(mode=0o755)
        try:
            index = {
                "schema": "centl-fcf-source-index-v2",
                "repository": "chasebryan/centl",
                "mirror_receipt_sha256": sha256(mirror / "MIRROR-SHA256SUMS"),
                "authorization_sha256": sha256(authorization),
                "branches": {},
            }
            for branch in BRANCHES:
                commit = branches[branch]
                validate_commit(repo, commit, branch)
                name = f"centl-{branch}.tar.gz"
                archive(repo, commit, branch, output / name)
                index["branches"][branch] = {
                    "commit": commit,
                    "archive": name,
                    "sha256": sha256(output / name),
                }
            (output / "INDEX.json").write_text(
                json.dumps(index, indent=2, sort_keys=True) + "\n", encoding="utf-8"
            )
        except Exception:
            shutil.rmtree(output, ignore_errors=True)
            raise


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mirror")
    parser.add_argument("authorization")
    parser.add_argument("output")
    args = parser.parse_args()
    export(Path(args.mirror), Path(args.authorization), Path(args.output))
    print("fcf caravan source export: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
