#!/usr/bin/env python3
"""Compare an active CENTL-SCi GGUF against known candidate source hashes.

Candidate rows are evidence for exact byte comparison only. A filename or model
name never counts as a match. An optional output sidecar is emitted only when the
active content SHA-256 matches exactly one candidate row.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path
from typing import NoReturn
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "supply-chain" / "model-provenance"
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def die(message: str, code: int = 1) -> NoReturn:
    raise SystemExit(f"centl model candidate match: {message}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def one_line(path: Path, label: str) -> str:
    if not path.is_file() or path.is_symlink():
        die(f"{label} is missing or unsafe: {path}")
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not lines[0]:
        die(f"{label} must contain exactly one non-empty line")
    return lines[0]


def parse_key_values(path: Path) -> dict[str, str]:
    if not path.is_file() or path.is_symlink():
        die(f"record is missing or unsafe: {path}")
    result: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            die(f"{path}:{number}: expected key=value")
        key, value = line.split("=", 1)
        if key in result:
            die(f"{path}:{number}: duplicate key {key}")
        result[key] = value
    return result


def active_model(mirror: Path) -> tuple[str, str, Path]:
    digest = one_line(mirror / "models" / "ACTIVE.sha256", "ACTIVE.sha256")
    if not HEX64.fullmatch(digest):
        die("ACTIVE.sha256 is not a lowercase SHA-256 digest")
    model_dir = mirror / "models" / digest
    manifest = parse_key_values(model_dir / "MANIFEST")
    name = manifest.get("file", "")
    if not name or "/" in name or "\\" in name or ".." in name:
        die("model MANIFEST contains an unsafe file name")
    model = model_dir / name
    if not model.is_file() or model.is_symlink():
        die("active model bytes are missing or unsafe")
    actual = sha256_file(model)
    if actual != digest:
        die(f"active model checksum mismatch: expected {digest}, got {actual}")
    return digest, name, model


def parse_candidates(path: Path) -> list[tuple[str, str, str]]:
    if not path.is_file() or path.is_symlink():
        return []
    rows: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 3:
            die(f"{path}:{number}: expected sha256|repository|file")
        digest, repository, file_name = parts
        if not HEX64.fullmatch(digest):
            die(f"{path}:{number}: invalid candidate SHA-256")
        if digest in seen:
            die(f"{path}:{number}: duplicate candidate SHA-256")
        seen.add(digest)
        parsed = urlparse(repository)
        if parsed.scheme != "https" or not parsed.netloc:
            die(f"{path}:{number}: candidate repository must use HTTPS")
        if not file_name or "/" in file_name or "\\" in file_name or ".." in file_name:
            die(f"{path}:{number}: unsafe candidate file name")
        rows.append((digest, repository, file_name))
    return rows


def write_sidecar(
    output: Path,
    *,
    model_name: str,
    digest: str,
    repository: str,
    source_file: str,
) -> None:
    catalog = CATALOG / f"{model_name}.provenance"
    values = parse_key_values(catalog)
    required = {
        "schema",
        "file_name",
        "base_model_id",
        "base_model_source",
        "base_model_license",
        "quantization",
        "note",
    }
    missing = required - set(values)
    if missing:
        die(f"catalog is missing fields needed for sidecar: {sorted(missing)}")
    if values["file_name"] != model_name:
        die("catalog file_name does not match active model")

    output.parent.mkdir(parents=True, exist_ok=True)
    content = (
        f"schema={values['schema']}\n"
        f"file_name={model_name}\n"
        f"base_model_id={values['base_model_id']}\n"
        f"base_model_source={values['base_model_source']}\n"
        f"base_model_license={values['base_model_license']}\n"
        f"quantization={values['quantization']}\n"
        "quantized_source_status=verified\n"
        f"quantized_source_repository={repository}\n"
        f"quantized_source_file={source_file}\n"
        f"quantized_source_sha256={digest}\n"
        "redistribution_status=not-approved\n"
        "note=Exact candidate origin matched the active preserved model by SHA-256; redistribution remains separately unapproved.\n"
    )
    output.write_text(content, encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="match active GGUF against known source hashes")
    parser.add_argument("mirror", type=Path)
    parser.add_argument("--output", type=Path, help="write a verified-origin sidecar on exact match")
    parser.add_argument("--require-match", action="store_true")
    args = parser.parse_args()

    mirror = args.mirror.resolve()
    if not mirror.is_dir():
        die(f"mirror not found: {mirror}")
    digest, model_name, model = active_model(mirror)
    ledger = CATALOG / f"{model_name}.candidates"
    rows = parse_candidates(ledger)
    matches = [row for row in rows if row[0] == digest]

    print(f"model={model}")
    print(f"sha256={digest}")
    print(f"candidate_ledger={ledger if ledger.exists() else 'none'}")
    print(f"candidate_count={len(rows)}")

    if not matches:
        print("match=none")
        if args.output is not None:
            die("cannot write a verified-origin sidecar without an exact SHA-256 match", code=2)
        if args.require_match:
            die("active model SHA-256 does not match a recorded candidate", code=3)
        return 0

    if len(matches) != 1:
        die("active model SHA-256 matched multiple candidate rows")
    _, repository, source_file = matches[0]
    print("match=exact-sha256")
    print(f"repository={repository}")
    print(f"source_file={source_file}")

    if args.output is not None:
        output = args.output.expanduser().resolve()
        write_sidecar(
            output,
            model_name=model_name,
            digest=digest,
            repository=repository,
            source_file=source_file,
        )
        print(f"sidecar={output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
