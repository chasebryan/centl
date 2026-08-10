#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "supply-chain" / "sources.lock"
TOOLCHAIN = ROOT / "toolchain.lock"
JULIA_MANIFEST = ROOT / "lab" / "julia" / "Manifest.toml"
SCI_ENGINE = ROOT / "docs" / "SCI-ENGINE.md"

HEX64 = re.compile(r"^[0-9a-f]{64}$")
HEX40 = re.compile(r"^[0-9a-f]{40}$")


def fail(message: str) -> None:
    raise SystemExit(f"supply-chain check: {message}")


def parse_toolchain() -> dict[str, dict[str, str]]:
    sections: dict[str, dict[str, str]] = {}
    current: dict[str, str] | None = None
    for raw in TOOLCHAIN.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = sections.setdefault(line[1:-1], {})
            continue
        if "=" not in line:
            fail(f"cannot parse toolchain line: {raw}")
        key, value = (part.strip() for part in line.split("=", 1))
        if current is None:
            if key == "schema":
                continue
            fail(f"unexpected top-level toolchain key: {key}")
        current[key] = value.strip('"')
    return sections


def parse_lock() -> dict[str, tuple[str, str, str, str, str]]:
    rows: dict[str, tuple[str, str, str, str, str]] = {}
    for number, raw in enumerate(LOCK.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        parts = raw.split("|")
        if len(parts) != 6:
            fail(f"{LOCK}:{number}: expected 6 fields")
        kind, name, version, mirror_name, digest, upstream = parts
        if name in rows:
            fail(f"duplicate source name: {name}")
        if kind not in {"artifact", "git"}:
            fail(f"invalid source kind for {name}: {kind}")
        if not upstream.startswith("https://"):
            fail(f"{name}: upstream must use https")
        if kind == "artifact":
            if not HEX64.fullmatch(digest):
                fail(f"{name}: artifact SHA-256 is not 64 lowercase hex characters")
        else:
            if digest != "-":
                fail(f"{name}: git source checksum field must be '-'")
            if not HEX40.fullmatch(version):
                fail(f"{name}: git pin is not a full 40-character commit")
        if "/" in mirror_name or mirror_name in {"", ".", ".."}:
            fail(f"{name}: unsafe mirror name")
        rows[name] = (kind, version, mirror_name, digest, upstream)
    return rows


def require_artifact(
    rows: dict[str, tuple[str, str, str, str, str]],
    name: str,
    version: str,
    digest: str | None,
) -> None:
    row = rows.get(name)
    if row is None:
        fail(f"missing required artifact {name}")
    kind, locked_version, _, locked_digest, _ = row
    if kind != "artifact":
        fail(f"{name}: expected artifact row")
    if locked_version != version:
        fail(f"{name}: lock has {locked_version}, toolchain requires {version}")
    if digest is not None and locked_digest != digest:
        fail(f"{name}: lock SHA-256 disagrees with toolchain.lock")


def main() -> int:
    rows = parse_lock()
    toolchain = parse_toolchain()
    verification = toolchain["verification"]
    runtime = toolchain["runtime"]
    laboratory = toolchain["laboratory"]

    require_artifact(
        rows,
        "fstar-linux-x86_64",
        verification["fstar"],
        verification["fstar_sha256"],
    )
    require_artifact(rows, "gmp", runtime["gmp"], runtime["gmp_sha256"])
    require_artifact(rows, "mpfr", runtime["mpfr"], runtime["mpfr_sha256"])
    require_artifact(rows, "flint", runtime["flint"], runtime["flint_sha256"])
    require_artifact(rows, "julia-linux-x86_64", laboratory["julia"], None)

    fstar_git = rows.get("fstar")
    if fstar_git is None or fstar_git[0] != "git":
        fail("missing F* git mirror pin")
    if fstar_git[1] != verification["fstar_commit"]:
        fail("F* git pin disagrees with toolchain.lock")

    llama = rows.get("llama.cpp")
    if llama is None or llama[0] != "git":
        fail("missing llama.cpp git mirror pin")
    engine = SCI_ENGINE.read_text(encoding="utf-8")
    build_match = re.search(r"llama-cli` build `b[0-9]+-([0-9a-f]+)`", engine)
    if build_match is None:
        fail("could not recover documented llama.cpp qualification commit")
    if not llama[1].startswith(build_match.group(1)):
        fail("llama.cpp mirror pin disagrees with documented qualification build")

    if rows.get("opam-repository", ("",))[0] != "git":
        fail("missing opam-repository git mirror pin")

    julia_text = JULIA_MANIFEST.read_text(encoding="utf-8")
    julia_match = re.search(r'^julia_version = "([^"]+)"$', julia_text, re.MULTILINE)
    if julia_match is None:
        fail("Julia manifest has no julia_version")
    if julia_match.group(1) != laboratory["julia"]:
        fail("Julia manifest version disagrees with toolchain.lock")

    lock_digest = hashlib.sha256(LOCK.read_bytes()).hexdigest()
    print(f"supply-chain lock: OK ({len(rows)} sources, sha256:{lock_digest})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
