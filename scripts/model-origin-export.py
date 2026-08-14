#!/usr/bin/env python3
"""Export an approved preserved CENTL-SCi model as an FCF semantic origin.

The exporter is deliberately fail-closed. It never decides whether a model may
be redistributed. It requires an already bound and verified provenance record
whose redistribution_status is operator-reviewed-allowed, verifies the active
model by SHA-256, and emits deterministic static-origin metadata plus a CARAVAN
catalog target for the exact same bytes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import stat
import sys
import tempfile
from pathlib import Path
from typing import NoReturn

HEX64 = re.compile(r"^[0-9a-f]{64}$")
SAFE_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._+-]*$")
READ_SIZE = 1024 * 1024
CHUNK_SIZE = 4 * 1024 * 1024
CATALOG_SCHEMA = "centl-caravan-catalog-v1"
ORIGIN_SCHEMA = "centl-semantic-origin-v1"


def die(message: str) -> NoReturn:
    raise SystemExit(f"centl semantic origin: {message}")


def _regular_file(path: Path, label: str) -> os.stat_result:
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        die(f"{label} is missing: {path}")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        die(f"{label} must be a regular non-symlink file: {path}")
    return info


def _safe_directory(path: Path, *, create: bool) -> None:
    if path.exists() or path.is_symlink():
        info = os.lstat(path)
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
            die(f"unsafe output directory: {path}")
        return
    if not create:
        die(f"directory is missing: {path}")
    parent = path.parent
    if parent != path:
        _safe_directory(parent, create=True)
    path.mkdir(mode=0o755)


def sha256_file(path: Path) -> str:
    _regular_file(path, "file")
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(READ_SIZE):
            digest.update(block)
    return digest.hexdigest()


def parse_record(path: Path, label: str) -> dict[str, str]:
    _regular_file(path, label)
    values: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            die(f"{label} line {number} is not key=value")
        key, value = line.split("=", 1)
        if not key or any(ch not in "abcdefghijklmnopqrstuvwxyz0123456789_" for ch in key):
            die(f"{label} line {number} has an invalid key")
        if key in values:
            die(f"{label} contains duplicate key {key}")
        values[key] = value
    return values


def read_single_line(path: Path, label: str) -> str:
    _regular_file(path, label)
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not lines[0]:
        die(f"{label} must contain exactly one non-empty line")
    return lines[0]


def active_model(mirror: Path) -> tuple[str, Path, str, int, Path]:
    models = mirror / "models"
    digest = read_single_line(models / "ACTIVE.sha256", "ACTIVE.sha256")
    if not HEX64.fullmatch(digest):
        die("ACTIVE.sha256 is not a lowercase SHA-256 digest")

    model_dir = models / digest
    manifest = parse_record(model_dir / "MANIFEST", "model MANIFEST")
    required = {"sha256", "file", "bytes"}
    missing = required - set(manifest)
    if missing:
        die(f"model MANIFEST is missing {', '.join(sorted(missing))}")
    if manifest["sha256"] != digest:
        die("model MANIFEST sha256 does not match ACTIVE.sha256")

    name = manifest["file"]
    if not SAFE_NAME.fullmatch(name) or name in {".", ".."}:
        die("model MANIFEST contains an unsafe file name")
    try:
        expected_bytes = int(manifest["bytes"])
    except ValueError:
        die("model MANIFEST bytes is not an integer")
    if expected_bytes < 0:
        die("model MANIFEST bytes must be non-negative")

    model = model_dir / name
    info = _regular_file(model, "active model")
    if info.st_size != expected_bytes:
        die("active model byte count does not match MANIFEST")
    actual = sha256_file(model)
    if actual != digest:
        die(f"active model checksum mismatch: expected {digest}, got {actual}")
    return digest, model, name, expected_bytes, model_dir


def verify_provenance(
    model_dir: Path, *, digest: str, name: str, byte_count: int
) -> dict[str, str]:
    record = model_dir / "PROVENANCE"
    receipt = model_dir / "PROVENANCE.sha256"
    values = parse_record(record, "PROVENANCE")
    receipt_line = read_single_line(receipt, "PROVENANCE.sha256")
    expected_receipt = f"{sha256_file(record)}  PROVENANCE"
    if receipt_line != expected_receipt:
        die("PROVENANCE.sha256 does not authenticate PROVENANCE")

    required = {
        "content_sha256",
        "file_name",
        "bytes",
        "base_model_id",
        "base_model_license",
        "quantization",
        "quantized_source_status",
        "quantized_source_sha256",
        "redistribution_status",
        "preservation_source_commit",
    }
    missing = required - set(values)
    if missing:
        die(f"PROVENANCE is missing {', '.join(sorted(missing))}")
    if values["content_sha256"] != digest:
        die("PROVENANCE content_sha256 does not match active model")
    if values["file_name"] != name:
        die("PROVENANCE file_name does not match active model")
    if values["bytes"] != str(byte_count):
        die("PROVENANCE byte count does not match active model")
    if values["quantized_source_status"] != "verified":
        die("public origin export requires a verified exact quantized source")
    if values["quantized_source_sha256"] != digest:
        die("PROVENANCE quantized_source_sha256 does not match active model")
    if values["redistribution_status"] != "operator-reviewed-allowed":
        die(
            "public origin export requires redistribution_status="
            "operator-reviewed-allowed"
        )
    if values["base_model_id"] in {"", "unrecorded"}:
        die("public origin export requires recorded base-model identity")
    if values["base_model_license"] in {"", "unrecorded"}:
        die("public origin export requires recorded base-model license")
    return values


def chunk_manifest(path: Path) -> list[dict[str, int | str]]:
    records: list[dict[str, int | str]] = []
    offset = 0
    with path.open("rb") as handle:
        while block := handle.read(CHUNK_SIZE):
            records.append(
                {
                    "offset": offset,
                    "length": len(block),
                    "sha256": hashlib.sha256(block).hexdigest(),
                }
            )
            offset += len(block)
    return records


def write_text_atomic(path: Path, text: str) -> None:
    _safe_directory(path.parent, create=True)
    if path.exists() or path.is_symlink():
        _regular_file(path, f"existing output {path.name}")
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        if tmp.exists():
            tmp.unlink()


def copy_verified(source: Path, target: Path, *, digest: str) -> None:
    _safe_directory(target.parent, create=True)
    if target.exists() or target.is_symlink():
        _regular_file(target, f"existing output {target.name}")
        if sha256_file(target) == digest:
            return
        die(f"refusing to replace different bytes at {target}")
    fd, tmp_name = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
    os.close(fd)
    tmp = Path(tmp_name)
    try:
        shutil.copyfile(source, tmp, follow_symlinks=False)
        if sha256_file(tmp) != digest:
            die("copied model failed post-copy SHA-256 verification")
        os.replace(tmp, target)
    finally:
        if tmp.exists():
            tmp.unlink()


def export_origin(
    mirror: Path, output: Path, *, catalog_version: int
) -> dict[str, object]:
    if catalog_version < 1:
        die("catalog version must be a positive integer")
    mirror = mirror.resolve()
    if not mirror.is_dir():
        die(f"preservation mirror not found: {mirror}")

    digest, model, name, byte_count, model_dir = active_model(mirror)
    provenance = verify_provenance(
        model_dir, digest=digest, name=name, byte_count=byte_count
    )

    logical_path = f"models/sha256/{digest}/{name}"
    artifact_id = f"sha256:{digest}"
    chunks = chunk_manifest(model)

    target_dir = output / "models" / "sha256" / digest
    target_model = target_dir / name
    target_provenance = target_dir / "PROVENANCE"
    target_provenance_receipt = target_dir / "PROVENANCE.sha256"

    copy_verified(model, target_model, digest=digest)
    provenance_text = (model_dir / "PROVENANCE").read_text(encoding="utf-8")
    provenance_receipt_text = (model_dir / "PROVENANCE.sha256").read_text(
        encoding="utf-8"
    )
    write_text_atomic(target_provenance, provenance_text)
    write_text_atomic(target_provenance_receipt, provenance_receipt_text)

    active = {
        "schema": ORIGIN_SCHEMA,
        "artifact_id": artifact_id,
        "content_sha256": digest,
        "file_name": name,
        "bytes": byte_count,
        "path": logical_path,
        "provenance_path": f"models/sha256/{digest}/PROVENANCE",
        "base_model_id": provenance["base_model_id"],
        "base_model_license": provenance["base_model_license"],
        "quantization": provenance["quantization"],
    }
    catalog = {
        "schema": CATALOG_SCHEMA,
        "catalog_version": catalog_version,
        "artifacts": [
            {
                "logical_path": logical_path,
                "artifact_id": artifact_id,
                "length": byte_count,
                "distribution": "public-approved",
                "chunks": chunks,
            }
        ],
    }
    write_text_atomic(
        output / "models" / "ACTIVE.json",
        json.dumps(active, indent=2, sort_keys=True) + "\n",
    )
    write_text_atomic(
        output / "caravan" / "catalog-v1.json",
        json.dumps(catalog, indent=2, sort_keys=True) + "\n",
    )

    files_for_receipt = [
        output / "models" / "ACTIVE.json",
        target_model,
        target_provenance,
        target_provenance_receipt,
        output / "caravan" / "catalog-v1.json",
    ]
    receipt_lines = []
    for path in files_for_receipt:
        relative = path.relative_to(output).as_posix()
        receipt_lines.append(f"{sha256_file(path)}  {relative}\n")
    write_text_atomic(output / "ORIGIN-SHA256SUMS", "".join(receipt_lines))

    return {
        "status": "ok",
        "artifact_id": artifact_id,
        "bytes": byte_count,
        "model": logical_path,
        "catalog": "caravan/catalog-v1.json",
        "catalog_version": catalog_version,
    }


def verify_only(mirror: Path) -> dict[str, object]:
    mirror = mirror.resolve()
    if not mirror.is_dir():
        die(f"preservation mirror not found: {mirror}")
    digest, _model, name, byte_count, model_dir = active_model(mirror)
    verify_provenance(model_dir, digest=digest, name=name, byte_count=byte_count)
    return {
        "status": "publishable",
        "artifact_id": f"sha256:{digest}",
        "bytes": byte_count,
        "file_name": name,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export an approved preserved CENTL-SCi model as an FCF semantic origin"
    )
    parser.add_argument("mirror", type=Path, help="FCF preservation mirror")
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        help="static origin directory; omit with --check",
    )
    parser.add_argument(
        "--catalog-version", type=int, default=1, help="CARAVAN catalog version"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify public-origin eligibility without writing output",
    )
    args = parser.parse_args()

    if args.check:
        if args.output is not None:
            parser.error("OUTPUT must be omitted with --check")
        summary = verify_only(args.mirror)
    else:
        if args.output is None:
            parser.error("OUTPUT is required unless --check is used")
        output = args.output.resolve()
        _safe_directory(output, create=True)
        summary = export_origin(
            args.mirror, output, catalog_version=args.catalog_version
        )
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
