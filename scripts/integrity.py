#!/usr/bin/env python3
"""CENTL SHA-256 integrity process.

This module deliberately does not define a hash function. It uses SHA-256 from
Python's standard hashlib implementation and emits the conventional two-space
SHA256SUMS format accepted by GNU sha256sum -c for ordinary file names.
"""

from __future__ import annotations

import argparse
import hashlib
import os
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


def normalize_ignored(names: list[str]) -> set[str]:
    ignored: set[str] = set()
    for name in names:
        ignored.add(validate_relative_name(name).as_posix())
    return ignored


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


def tree_regular_paths(root: Path, ignored: set[str]) -> list[str]:
    root = root.resolve()
    if not root.is_dir():
        die(f"tree root is not a directory: {root}")

    names: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root, topdown=True, followlinks=False):
        current = Path(dirpath)

        for dirname in list(dirnames):
            directory = current / dirname
            relative = directory.relative_to(root).as_posix()
            if directory.is_symlink():
                die(f"tree contains symlink directory: {relative}")

        for filename in filenames:
            path = current / filename
            relative = path.relative_to(root).as_posix()
            if relative in ignored:
                continue
            if path.is_symlink() or not path.is_file():
                die(f"tree path is not a regular file: {relative}")
            validate_relative_name(relative)
            names.append(relative)

    return sorted(names)


def write_manifest(output: Path, root: Path, names: list[str]) -> None:
    root = root.resolve()
    output_resolved = output.resolve()
    lines: list[str] = []
    seen: set[str] = set()
    for name in sorted(names):
        relative = validate_relative_name(name)
        canonical = relative.as_posix()
        if canonical in seen:
            die(f"duplicate manifest path: {canonical}")
        seen.add(canonical)
        path = root / relative
        try:
            path.resolve().relative_to(root)
        except ValueError:
            die(f"manifest path escapes root: {canonical}")
        if path.resolve() == output_resolved:
            die(f"manifest cannot hash itself: {canonical}")
        if path.is_symlink() or not path.is_file():
            die(f"manifest path is not a regular file: {canonical}")
        lines.append(f"{sha256_file(path)}  {canonical}\n")
    if not lines:
        die("refusing to create an empty checksum manifest")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {len(lines)} SHA-256 entries: {output}")
    print(f"Manifest SHA-256: {sha256_file(output)}")


def create_source_manifest(output: Path) -> None:
    write_manifest(output, ROOT, tracked_paths())


def create_tree_manifest(output: Path, root: Path, ignored: set[str]) -> None:
    root = root.resolve()
    output_resolved = output.resolve()
    try:
        output_relative = output_resolved.relative_to(root).as_posix()
    except ValueError:
        output_relative = None

    effective_ignored = set(ignored)
    if output_relative is not None:
        effective_ignored.add(output_relative)
        effective_ignored.add(f"{output_relative}.sha256")

    names = tree_regular_paths(root, effective_ignored)
    write_manifest(output, root, names)
    verify_tree_manifest(output, root, ignored=effective_ignored)


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
    root = root.resolve()
    failures = 0
    entries = parse_manifest(manifest)
    for expected, name in entries:
        path = root / name
        try:
            path.resolve().relative_to(root)
        except ValueError:
            print(f"FAILED {name}: path escapes verification root", file=sys.stderr)
            failures += 1
            continue
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


def verify_tree_manifest(
    manifest: Path,
    root: Path,
    *,
    ignored: set[str],
    verbose: bool = False,
) -> None:
    entries = parse_manifest(manifest)
    expected_names = {name for _, name in entries}
    if expected_names & ignored:
        die("tree manifest contains a path configured as ignored")

    actual_names = set(tree_regular_paths(root, ignored))
    missing = sorted(expected_names - actual_names)
    extra = sorted(actual_names - expected_names)
    if missing:
        for name in missing:
            print(f"MISSING {name}", file=sys.stderr)
    if extra:
        for name in extra:
            print(f"UNEXPECTED {name}", file=sys.stderr)
    if missing or extra:
        die(f"tree membership mismatch: {len(missing)} missing, {len(extra)} unexpected")

    verify_manifest(manifest, root, verbose=verbose)
    print(f"SHA-256 tree verified exactly: {root} ({len(entries)} files)")


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

    manifest = sub.add_parser("manifest", help="create a SHA256SUMS manifest for named files")
    manifest.add_argument("--root", required=True, type=Path)
    manifest.add_argument("--output", required=True, type=Path)
    manifest.add_argument("paths", nargs="+")

    tree_manifest = sub.add_parser(
        "tree-manifest",
        help="create a strict SHA256SUMS manifest for every regular file in a tree",
    )
    tree_manifest.add_argument("--root", required=True, type=Path)
    tree_manifest.add_argument("--output", required=True, type=Path)
    tree_manifest.add_argument("--ignore", action="append", default=[])

    verify = sub.add_parser("verify", help="verify a conventional SHA256SUMS manifest")
    verify.add_argument("manifest", type=Path)
    verify.add_argument("--root", type=Path, default=ROOT)
    verify.add_argument("--verbose", action="store_true")

    tree_verify = sub.add_parser(
        "tree-verify",
        help="verify checksums and exact regular-file membership for a tree",
    )
    tree_verify.add_argument("manifest", type=Path)
    tree_verify.add_argument("--root", required=True, type=Path)
    tree_verify.add_argument("--ignore", action="append", default=[])
    tree_verify.add_argument("--verbose", action="store_true")

    one = sub.add_parser("hash", help="print the SHA-256 of one regular file")
    one.add_argument("path", type=Path)

    args = parser.parse_args()
    if args.command == "self-test":
        self_test(announce=True)
    elif args.command == "source-manifest":
        self_test(announce=False)
        create_source_manifest(args.output)
        verify_manifest(args.output, ROOT)
    elif args.command == "manifest":
        self_test(announce=False)
        write_manifest(args.output, args.root, args.paths)
        verify_manifest(args.output, args.root)
    elif args.command == "tree-manifest":
        self_test(announce=False)
        create_tree_manifest(args.output, args.root, normalize_ignored(args.ignore))
    elif args.command == "verify":
        self_test(announce=False)
        verify_manifest(args.manifest, args.root, verbose=args.verbose)
    elif args.command == "tree-verify":
        self_test(announce=False)
        verify_tree_manifest(
            args.manifest,
            args.root,
            ignored=normalize_ignored(args.ignore),
            verbose=args.verbose,
        )
    elif args.command == "hash":
        self_test(announce=False)
        hash_command(args.path)
    else:
        parser.error("unknown command")
    return 0


if __name__ == "__main__":
    sys.exit(main())
