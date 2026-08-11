#!/usr/bin/env python3
"""Fail closed when stable-product release identity disagrees across CENTL metadata."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys
from typing import Sequence

VERSION_DECL = re.compile(
    r'^\s*let\s+value\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?)"\s*$'
)
SEMVER = r"[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?"


class MetadataError(RuntimeError):
    pass


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise MetadataError(f"cannot read {path}: {exc}") from exc


def source_version(root: Path) -> str:
    path = root / "src/ocaml/centl_version.ml"
    match = VERSION_DECL.match(read_text(path))
    if not match:
        raise MetadataError(f"invalid authoritative version declaration in {path}")
    return match.group(1)


def section(text: str, heading: str) -> str | None:
    pattern = re.compile(
        rf"^##\s+{re.escape(heading)}\s*$\n(.*?)(?=^##\s+|\Z)",
        re.MULTILINE | re.DOTALL | re.IGNORECASE,
    )
    match = pattern.search(text)
    return match.group(1) if match else None


def require_release_notes(root: Path, version: str) -> None:
    path = root / f"docs/releases/{version}.md"
    text = read_text(path)
    first_heading = next((line.strip() for line in text.splitlines() if line.startswith("# ")), "")
    if not re.search(rf"(?:^|\s)v?{re.escape(version)}(?:\s|$)", first_heading):
        raise MetadataError(
            f"{path} does not identify authoritative source version {version} in its title"
        )


def require_changelog(root: Path, version: str) -> None:
    text = read_text(root / "CHANGELOG.md")
    if not re.search(rf"^##\s+v?{re.escape(version)}(?:\s|$)", text, re.MULTILINE):
        raise MetadataError(f"CHANGELOG.md has no release heading for {version}")


def require_readme_status(root: Path, version: str) -> None:
    path = root / "README.md"
    text = read_text(path)
    current = section(text, "Current release status")
    if current is None:
        raise MetadataError("README.md has no 'Current release status' section")
    versions = sorted(set(re.findall(rf"CENTL\s+v({SEMVER})", current)))
    if versions != [version]:
        rendered = ", ".join(versions) if versions else "none"
        raise MetadataError(
            f"README.md current release status identifies {rendered}; authoritative source is {version}"
        )


def require_oasis_status(root: Path, version: str) -> None:
    path = root / "docs/OASIS.md"
    text = read_text(path)
    headings = re.findall(rf"^##\s+v({SEMVER})\s*$", text, re.MULTILINE)
    if headings:
        unique = sorted(set(headings))
        if unique != [version]:
            raise MetadataError(
                "docs/OASIS.md version-specific qualification section identifies "
                f"{', '.join(unique)}; authoritative source is {version}"
            )


def check(root: Path) -> str:
    version = source_version(root)
    require_release_notes(root, version)
    require_changelog(root, version)
    require_readme_status(root, version)
    require_oasis_status(root, version)
    return version


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Check CENTL Oasis release metadata coherence")
    p.add_argument("--root", type=Path, default=Path.cwd())
    return p


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        version = check(args.root.resolve())
    except MetadataError as exc:
        print(f"centl oasis metadata: {exc}", file=sys.stderr)
        return 1
    print(f"Oasis release metadata is coherent for CENTL {version}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
