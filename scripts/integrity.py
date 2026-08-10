#!/usr/bin/env python3
"""CENTL SHA-256 integrity process.

This module deliberately does not define a hash function. It uses SHA-256 from
Python's standard hashlib implementation and emits the conventional two-space
SHA256SUMS format accepted by GNU sha256sum -c for ordinary file names.
"""

from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

ROOT = Path(__file__).resolve().parents[1]
CHUNK = 1024 * 1024

# FIPS 180-4 / widely published SHA-256 known-answer values.
KNOWN_VECTORS = (
    (b"", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
    (b"abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
)


def die(message: str) -> NoReturn:
    raise SystemExit(f"centl integrity: {message}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(CHUNK)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def validate_relative_name(name: str) -> Path:
    if not name or "\n" in name or "\r" in name or "\\" in name:
        die(f"unsupported checksum path: {name!r}")
    path = Path(name)
    if path.is_absolute() or ".." in path.parts:
        die(f"unsafe checksum path: {name}")
    return path


def self_test(*, announce: bool) -> None:
    for payload, expected in KNOWN_VECTORS:
        actual = hashlib.sha256(payload).hexdigest()
        if actual != expected:
            die(f"SHA-256 known-answer test failed: expected {expected}, got {actual}")
    if announce:
        print("SHA-256 implementation: OK (known-answer tests passed)")


def tracked_paths() -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        check=True,
        stdout=subprocess.PIPE,
    )
    names = result.stdout.decode("utf-8").split("\0")
    return sorted(name for name in names if name)


def create_source_manifest(output: Path) -> None:
    lines: list[str] = []
    output_resolved = output.resolve()
    for name in tracked_paths():
        relative = validate_relative_name(name)
        path = ROOT / relative
        if path.resolve() == output_resolved:
            continue
        if path.is_symlink():
            die(f"tracked symlink requires explicit integrity policy: {name}")
        if not path.is_file():
            die(f"tracked path is not a regular file: {name}")
        lines.append(f"{sha256_file(path)}  {name}\n")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {len(lines)} SHA-256 entries: {output}")
    print(f"Manifest SHA-256: {sha256_file(output)}")


def parse_manifest(manifest: Path) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    seen: set[str] = set()
    for number, raw in enumerate(manifest.read_text(encoding="utf-8").splitlines(), 1):
        if not raw:
            continue
        if len(raw) < 67 or raw[64:66] != "  ":
            die(f"{manifest}:{number}: expected conventional '<sha256>  <path>' format")
        expected = raw[:64]
        if any(character not in "0123456789abcdef" for character in expected):
            die(f"{manifest}:{number}: invalid lowercase SHA-256 digest")
        name = raw[66:]
        validate_relative_name(name)
        if name in seen:
            die(f"{manifest}:{number}: duplicate path: {name}")
        seen.add(name)
        entries.append((expected, name))
    if not entries:
        die(f"empty checksum manifest: {manifest}")
    return entries


def verify_manifest(manifest: Path, root: Path, *, verbose: bool = False) -> None:
    failures = 0
    entries = parse_manifest(manifest)
    for expected, name in entries:
        path = root / name
        if path.is_symlink() or not path.is_file():
            print(f"MISSING {name}", file=sys.stderr)
            failures += 1
            continue
        actual = sha256_file(path)
        if actual != expected:
            print(f"FAILED {name}: expected {expected}, got {actual}", file=sys.stderr)
            failures += 1
        elif verbose:
            print(f"OK {name}")
    if failures:
        die(f"{failures} SHA-256 verification failure(s)")
    print(f"SHA-256 manifest verified: {manifest} ({len(entries)} files)")


def hash_command(path: Path) -> None:
    if not path.is_file() or path.is_symlink():
        die(f"not a regular file: {path}")
    print(f"{sha256_file(path)}  {path.name}")


def main() -> int:
    parser = argparse.ArgumentParser(description="CENTL standard SHA-256 integrity process")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("self-test", help="run published SHA-256 known-answer tests")

    source = sub.add_parser("source-manifest", help="hash every Git-tracked regular file")
    source.add_argument("--output", required=True, type=Path)

    verify = sub.add_parser("verify", help="verify a conventional SHA256SUMS manifest")
    verify.add_argument("manifest", type=Path)
    verify.add_argument("--root", type=Path, default=ROOT)
    verify.add_argument("--verbose", action="store_true")

    one = sub.add_parser("hash", help="print the SHA-256 of one regular file")
    one.add_argument("path", type=Path)

    args = parser.parse_args()
    if args.command == "self-test":
        self_test(announce=True)
    elif args.command == "source-manifest":
        self_test(announce=False)
        create_source_manifest(args.output)
        verify_manifest(args.output, ROOT)
    elif args.command == "verify":
        self_test(announce=False)
        verify_manifest(args.manifest, args.root, verbose=args.verbose)
    elif args.command == "hash":
        self_test(announce=False)
        hash_command(args.path)
    else:
        parser.error("unknown command")
    return 0


if __name__ == "__main__":
    sys.exit(main())
