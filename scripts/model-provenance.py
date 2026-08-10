#!/usr/bin/env python3
"""Bind and verify CENTL-SCi model provenance without guessing origin.

The model content SHA-256 remains the preservation identity. Provenance records
separately describe base-model lineage, an exact quantized source only when that
source is content-hash verified, and an explicit redistribution review state.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from pathlib import Path
from typing import NoReturn

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "supply-chain" / "model-provenance"
HEX64 = re.compile(r"^[0-9a-f]{64}$")
KEY = re.compile(r"^[a-z][a-z0-9_]*$")

OUTPUT_ORDER = (
    "schema",
    "content_sha256",
    "file_name",
    "bytes",
    "base_model_id",
    "base_model_source",
    "base_model_license",
    "quantization",
    "quantized_source_status",
    "quantized_source_repository",
    "quantized_source_file",
    "quantized_source_sha256",
    "redistribution_status",
    "preservation_source_commit",
    "record_source",
    "note",
)


def die(message: str) -> NoReturn:
    raise SystemExit(f"centl model provenance: {message}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def parse_record(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            die(f"{path}:{number}: expected key=value")
        key, value = line.split("=", 1)
        if not KEY.fullmatch(key):
            die(f"{path}:{number}: invalid key {key!r}")
        if key in values:
            die(f"{path}:{number}: duplicate key {key}")
        if "\x00" in value or "\n" in value or "\r" in value:
            die(f"{path}:{number}: unsupported value")
        values[key] = value
    return values


def read_one_line(path: Path, label: str) -> str:
    if not path.is_file() or path.is_symlink():
        die(f"{label} is missing or not a regular file: {path}")
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not lines[0]:
        die(f"{label} must contain exactly one non-empty line")
    return lines[0]


def active_model(mirror: Path) -> tuple[str, Path, str]:
    digest = read_one_line(mirror / "models" / "ACTIVE.sha256", "ACTIVE.sha256")
    if not HEX64.fullmatch(digest):
        die("ACTIVE.sha256 is not a lowercase SHA-256 digest")

    model_dir = mirror / "models" / digest
    manifest = parse_record(model_dir / "MANIFEST")
    model_name = manifest.get("file", "")
    if not model_name or "/" in model_name or "\\" in model_name or ".." in model_name:
        die("model MANIFEST has an unsafe file name")
    model = model_dir / model_name
    if not model.is_file() or model.is_symlink():
        die(f"active model bytes are missing or unsafe: {model}")
    actual = sha256_file(model)
    if actual != digest:
        die(f"active model checksum mismatch: expected {digest}, got {actual}")
    return digest, model, model_name


def default_record(model_name: str) -> dict[str, str]:
    return {
        "schema": "1",
        "file_name": model_name,
        "base_model_id": "unrecorded",
        "base_model_source": "-",
        "base_model_license": "unrecorded",
        "quantization": "unrecorded",
        "quantized_source_status": "unverified",
        "quantized_source_repository": "-",
        "quantized_source_file": "-",
        "quantized_source_sha256": "-",
        "redistribution_status": "not-approved",
        "note": "No verified provenance record was available for this model file.",
    }


def validate_source_record(values: dict[str, str], *, model_name: str, digest: str) -> None:
    required = {
        "schema",
        "file_name",
        "base_model_id",
        "base_model_source",
        "base_model_license",
        "quantization",
        "quantized_source_status",
        "quantized_source_repository",
        "quantized_source_file",
        "quantized_source_sha256",
        "redistribution_status",
        "note",
    }
    unknown = set(values) - required
    missing = required - set(values)
    if unknown:
        die(f"unknown provenance key(s): {', '.join(sorted(unknown))}")
    if missing:
        die(f"missing provenance key(s): {', '.join(sorted(missing))}")
    if values["schema"] != "1":
        die("unsupported provenance schema")
    if values["file_name"] != model_name:
        die(
            f"provenance file_name {values['file_name']!r} does not match active model {model_name!r}"
        )
    if values["quantized_source_status"] not in {"unverified", "verified"}:
        die("quantized_source_status must be unverified or verified")
    if values["redistribution_status"] not in {
        "not-approved",
        "operator-reviewed-allowed",
        "operator-reviewed-restricted",
    }:
        die("invalid redistribution_status")

    if values["quantized_source_status"] == "verified":
        if values["quantized_source_repository"] in {"", "-"}:
            die("verified quantized source requires quantized_source_repository")
        if values["quantized_source_file"] in {"", "-"}:
            die("verified quantized source requires quantized_source_file")
        source_hash = values["quantized_source_sha256"]
        if not HEX64.fullmatch(source_hash):
            die("verified quantized source requires a lowercase SHA-256")
        if source_hash != digest:
            die(
                "verified quantized_source_sha256 does not match the active model content SHA-256"
            )
    else:
        if values["quantized_source_sha256"] != "-":
            die("unverified quantized source must not claim a source SHA-256")
        if values["redistribution_status"] == "operator-reviewed-allowed":
            die("redistribution cannot be marked allowed while exact quantized origin is unverified")


def record_source_for(model_name: str, explicit: Path | None) -> tuple[dict[str, str], str]:
    if explicit is not None:
        if not explicit.is_file() or explicit.is_symlink():
            die(f"explicit provenance file is missing or unsafe: {explicit}")
        return parse_record(explicit), f"operator:{explicit.name}"

    catalog = CATALOG / f"{model_name}.provenance"
    if catalog.is_file() and not catalog.is_symlink():
        return parse_record(catalog), f"centl-catalog:{catalog.name}"
    return default_record(model_name), "generated:unrecorded"


def write_bound_record(
    mirror: Path,
    source: dict[str, str],
    source_label: str,
    *,
    digest: str,
    model: Path,
    model_name: str,
) -> Path:
    validate_source_record(source, model_name=model_name, digest=digest)
    model_dir = model.parent
    commit_path = mirror / "project" / "SOURCE-COMMIT"
    commit = read_one_line(commit_path, "SOURCE-COMMIT") if commit_path.exists() else "unrecorded"
    if commit != "unrecorded" and not re.fullmatch(r"[0-9a-f]{40}", commit):
        die("preservation SOURCE-COMMIT is invalid")

    bound = dict(source)
    bound.update(
        {
            "content_sha256": digest,
            "bytes": str(model.stat().st_size),
            "preservation_source_commit": commit,
            "record_source": source_label,
        }
    )
    output = model_dir / "PROVENANCE"
    text = "".join(f"{key}={bound[key]}\n" for key in OUTPUT_ORDER)
    output.write_text(text, encoding="utf-8", newline="\n")
    receipt = model_dir / "PROVENANCE.sha256"
    receipt.write_text(f"{sha256_file(output)}  PROVENANCE\n", encoding="ascii", newline="\n")
    return output


def verify_bound(mirror: Path) -> Path:
    digest, model, model_name = active_model(mirror)
    model_dir = model.parent
    output = model_dir / "PROVENANCE"
    receipt = model_dir / "PROVENANCE.sha256"
    if not output.is_file() or output.is_symlink():
        die("active model has no safe PROVENANCE record")
    if not receipt.is_file() or receipt.is_symlink():
        die("active model has no safe PROVENANCE.sha256 receipt")

    receipt_values = receipt.read_text(encoding="ascii").splitlines()
    if len(receipt_values) != 1 or len(receipt_values[0]) < 67:
        die("PROVENANCE.sha256 is malformed")
    expected, separator, name = (
        receipt_values[0][:64],
        receipt_values[0][64:66],
        receipt_values[0][66:],
    )
    if not HEX64.fullmatch(expected) or separator != "  " or name != "PROVENANCE":
        die("PROVENANCE.sha256 is malformed")
    actual = sha256_file(output)
    if actual != expected:
        die(f"PROVENANCE checksum mismatch: expected {expected}, got {actual}")

    values = parse_record(output)
    expected_keys = set(OUTPUT_ORDER)
    if set(values) != expected_keys:
        missing = expected_keys - set(values)
        extra = set(values) - expected_keys
        die(f"bound provenance key mismatch; missing={sorted(missing)}, extra={sorted(extra)}")
    if values["content_sha256"] != digest:
        die("PROVENANCE content_sha256 does not match active model")
    if values["file_name"] != model_name:
        die("PROVENANCE file_name does not match active model")
    if values["bytes"] != str(model.stat().st_size):
        die("PROVENANCE byte count does not match active model")

    source_projection = {
        key: values[key]
        for key in (
            "schema",
            "file_name",
            "base_model_id",
            "base_model_source",
            "base_model_license",
            "quantization",
            "quantized_source_status",
            "quantized_source_repository",
            "quantized_source_file",
            "quantized_source_sha256",
            "redistribution_status",
            "note",
        )
    }
    validate_source_record(source_projection, model_name=model_name, digest=digest)

    source_commit = mirror / "project" / "SOURCE-COMMIT"
    if source_commit.exists():
        expected_commit = read_one_line(source_commit, "SOURCE-COMMIT")
        if values["preservation_source_commit"] != expected_commit:
            die("PROVENANCE preservation_source_commit does not match mirror SOURCE-COMMIT")
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description="CENTL-SCi model provenance binding")
    sub = parser.add_subparsers(dest="command", required=True)

    bind = sub.add_parser("bind", help="bind catalog/operator provenance to the active model")
    bind.add_argument("mirror", type=Path)
    bind.add_argument("--input", type=Path)

    verify = sub.add_parser("verify", help="verify the active model provenance binding")
    verify.add_argument("mirror", type=Path)

    args = parser.parse_args()
    mirror = args.mirror.resolve()
    if not mirror.is_dir():
        die(f"mirror not found: {mirror}")

    if args.command == "bind":
        digest, model, model_name = active_model(mirror)
        explicit = args.input
        if explicit is None and os.environ.get("CENTL_SCI_MODEL_PROVENANCE_FILE"):
            explicit = Path(os.environ["CENTL_SCI_MODEL_PROVENANCE_FILE"]).expanduser().resolve()
        source, source_label = record_source_for(model_name, explicit)
        output = write_bound_record(
            mirror,
            source,
            source_label,
            digest=digest,
            model=model,
            model_name=model_name,
        )
        verify_bound(mirror)
        print(f"CENTL-SCi model provenance bound: {output}")
    elif args.command == "verify":
        output = verify_bound(mirror)
        print(f"CENTL-SCi model provenance verified: {output}")
    else:
        parser.error("unknown command")
    return 0


if __name__ == "__main__":
    sys.exit(main())
