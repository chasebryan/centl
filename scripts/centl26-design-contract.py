#!/usr/bin/env python3
"""Verify or intentionally advance the approved CentL26 visual design contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
import tempfile
from typing import Any


DEFAULT_MANIFEST = "design/centl26/approved-design.json"
VERSION_PATTERN = re.compile(r"CentL26(?:\.[0-9]+)*")
HASH_PATTERN = re.compile(r"[0-9a-f]{64}")


class ContractError(RuntimeError):
    """Raised when the checked-in design contract is malformed or violated."""


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ContractError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ContractError(f"cannot read manifest {path}: {exc}") from exc
    try:
        value = json.loads(raw, object_pairs_hook=_unique_object)
    except (json.JSONDecodeError, ContractError) as exc:
        raise ContractError(f"invalid manifest {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ContractError("manifest root must be an object")
    return value


def safe_source_path(root: Path, relative: str) -> Path:
    if not isinstance(relative, str) or not relative:
        raise ContractError("approved source path must be a non-empty string")
    pure = PurePosixPath(relative)
    if pure.is_absolute() or ".." in pure.parts or "." in pure.parts:
        raise ContractError(f"approved source path is not repository-relative: {relative!r}")
    candidate = root.joinpath(*pure.parts)
    if candidate.is_symlink():
        raise ContractError(f"approved visual source must not be a symlink: {relative}")
    try:
        resolved = candidate.resolve(strict=True)
    except OSError as exc:
        raise ContractError(f"approved visual source is missing: {relative}") from exc
    try:
        resolved.relative_to(root.resolve(strict=True))
    except ValueError as exc:
        raise ContractError(f"approved visual source escapes repository root: {relative}") from exc
    if not resolved.is_file():
        raise ContractError(f"approved visual source is not a regular file: {relative}")
    return resolved


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _require_mapping(value: object, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContractError(f"{label} must be an object")
    return value


def _require_string_list(value: object, label: str) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
        raise ContractError(f"{label} must be a list of non-empty strings")
    return value


def validate_structure(contract: dict[str, Any]) -> dict[str, str]:
    if contract.get("schema") != 1:
        raise ContractError("manifest schema must be 1")
    if contract.get("algorithm") != "sha256":
        raise ContractError("manifest algorithm must be sha256")

    approval = _require_mapping(contract.get("approval"), "approval")
    if approval.get("status") != "user-approved":
        raise ContractError("approval.status must be user-approved")
    version = approval.get("release")
    if not isinstance(version, str) or VERSION_PATTERN.fullmatch(version) is None:
        raise ContractError("approval.release must use the CentL26 / CentL26.1 version scheme")
    note = approval.get("change_note")
    if not isinstance(note, str) or not note.strip():
        raise ContractError("approval.change_note must explain the approved baseline")

    files = _require_mapping(contract.get("files"), "files")
    if not files:
        raise ContractError("files must contain at least one approved visual source")
    normalized: dict[str, str] = {}
    for relative, expected in files.items():
        if not isinstance(relative, str):
            raise ContractError("files keys must be repository-relative strings")
        if not isinstance(expected, str) or HASH_PATTERN.fullmatch(expected) is None:
            raise ContractError(f"invalid SHA-256 for {relative}")
        normalized[relative] = expected
    if list(files) != sorted(files):
        raise ContractError("files must be sorted by repository-relative path")

    semantics = _require_mapping(contract.get("semantic_contract"), "semantic_contract")
    _require_mapping(semantics.get("css_variables"), "semantic_contract.css_variables")
    _require_mapping(semantics.get("css_declarations"), "semantic_contract.css_declarations")
    _require_mapping(semantics.get("required_text"), "semantic_contract.required_text")
    return normalized


def _read_utf8(root: Path, relative: str) -> str:
    path = safe_source_path(root, relative)
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise ContractError(f"semantic source is not UTF-8: {relative}") from exc


def _normalized_css_value(value: str) -> str:
    return " ".join(value.strip().split()).lower()


def _css_block(css: str, selector: str) -> str:
    pattern = re.compile(r"(?m)^\s*" + re.escape(selector) + r"\s*\{([^{}]*)\}")
    match = pattern.search(css)
    if match is None:
        raise ContractError(f"semantic CSS selector is missing: {selector}")
    return match.group(1)


def _css_property(block: str, property_name: str) -> str:
    pattern = re.compile(
        r"(?:^|;)\s*" + re.escape(property_name) + r"\s*:\s*([^;]+);",
        re.MULTILINE,
    )
    match = pattern.search(block)
    if match is None:
        raise ContractError(f"semantic CSS property is missing: {property_name}")
    return _normalized_css_value(match.group(1))


def check_semantics(root: Path, contract: dict[str, Any]) -> int:
    semantics = _require_mapping(contract["semantic_contract"], "semantic_contract")
    css_relative = semantics.get("css_file")
    if not isinstance(css_relative, str):
        raise ContractError("semantic_contract.css_file must be a path string")
    css = _read_utf8(root, css_relative)
    invariant_count = 0

    variables = _require_mapping(semantics["css_variables"], "semantic_contract.css_variables")
    for name, expected in variables.items():
        if not isinstance(name, str) or not isinstance(expected, str):
            raise ContractError("CSS variable invariants must map strings to strings")
        pattern = re.compile(r"(?m)^\s*--" + re.escape(name) + r"\s*:\s*([^;]+);")
        match = pattern.search(css)
        if match is None:
            raise ContractError(f"approved CSS variable is missing: --{name}")
        actual = _normalized_css_value(match.group(1))
        if actual != _normalized_css_value(expected):
            raise ContractError(
                f"approved CSS variable --{name} changed: expected {expected!r}, got {actual!r}"
            )
        invariant_count += 1

    declarations = _require_mapping(
        semantics["css_declarations"], "semantic_contract.css_declarations"
    )
    for selector, properties_value in declarations.items():
        if not isinstance(selector, str):
            raise ContractError("CSS declaration selectors must be strings")
        properties = _require_mapping(
            properties_value, f"semantic CSS declarations for {selector}"
        )
        block = _css_block(css, selector)
        for property_name, expected in properties.items():
            if not isinstance(property_name, str) or not isinstance(expected, str):
                raise ContractError("CSS declaration invariants must map strings to strings")
            actual = _css_property(block, property_name)
            if actual != _normalized_css_value(expected):
                raise ContractError(
                    f"approved CSS declaration {selector} {property_name} changed: "
                    f"expected {expected!r}, got {actual!r}"
                )
            invariant_count += 1

    required_text = _require_mapping(
        semantics["required_text"], "semantic_contract.required_text"
    )
    for relative, fragments_value in required_text.items():
        if not isinstance(relative, str):
            raise ContractError("required_text keys must be source paths")
        fragments = _require_string_list(
            fragments_value, f"semantic required text for {relative}"
        )
        source = _read_utf8(root, relative)
        for fragment in fragments:
            if fragment not in source:
                raise ContractError(
                    f"approved semantic invariant is missing from {relative}: {fragment!r}"
                )
            invariant_count += 1
    return invariant_count


def check_contract(root: Path, contract: dict[str, Any]) -> tuple[int, int]:
    files = validate_structure(contract)
    invariant_count = check_semantics(root, contract)
    mismatches: list[str] = []
    for relative, expected in files.items():
        actual = sha256_file(safe_source_path(root, relative))
        if actual != expected:
            mismatches.append(f"{relative}: expected {expected}, got {actual}")
    if mismatches:
        detail = "\n  ".join(mismatches)
        raise ContractError(
            "approved visual source drift detected:\n  "
            + detail
            + "\nDo not refresh hashes for incidental edits. Follow docs/CENTL26-DESIGN-CONTRACT.md."
        )
    return len(files), invariant_count


def write_manifest(path: Path, contract: dict[str, Any]) -> None:
    encoded = (json.dumps(contract, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode(
        "utf-8"
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".design-contract-", delete=False) as tmp:
        temporary = Path(tmp.name)
        tmp.write(encoded)
        tmp.flush()
        os.fsync(tmp.fileno())
    try:
        temporary.chmod(mode)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def approve_contract(
    root: Path,
    manifest_path: Path,
    contract: dict[str, Any],
    version: str,
    reason: str,
) -> tuple[int, int]:
    if VERSION_PATTERN.fullmatch(version) is None:
        raise ContractError("--version must use the CentL26 / CentL26.1 version scheme")
    reason = reason.strip()
    if not reason:
        raise ContractError("--reason must describe the intentionally approved visual change")

    files = validate_structure(contract)
    invariant_count = check_semantics(root, contract)
    contract["files"] = {
        relative: sha256_file(safe_source_path(root, relative)) for relative in sorted(files)
    }
    approval = _require_mapping(contract["approval"], "approval")
    approval["release"] = version
    approval["change_note"] = reason
    approval["status"] = "user-approved"
    approval["reviewed_viewports"] = ["1366x768", "1440x900"]
    write_manifest(manifest_path, contract)
    checked_files, checked_invariants = check_contract(root, load_manifest(manifest_path))
    return checked_files, checked_invariants or invariant_count


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository root (defaults to the script's parent repository)",
    )
    parser.add_argument(
        "--manifest",
        default=DEFAULT_MANIFEST,
        help=f"manifest path relative to --root (default: {DEFAULT_MANIFEST})",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("check", help="verify hashes and semantic invariants")
    approve = subparsers.add_parser("approve", help="record an intentionally reviewed design")
    approve.add_argument("--version", required=True, help="approved release, for example CentL26.1")
    approve.add_argument("--reason", required=True, help="concise reason for the approved change")
    approve.add_argument(
        "--confirm-visual-review",
        action="store_true",
        help="confirm review at both contract viewports before updating hashes",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    root = args.root.resolve()
    manifest_pure = PurePosixPath(args.manifest)
    if manifest_pure.is_absolute() or ".." in manifest_pure.parts:
        print("CentL26 design contract: manifest must stay inside --root", file=sys.stderr)
        return 2
    manifest_path = root.joinpath(*manifest_pure.parts)
    try:
        contract = load_manifest(manifest_path)
        if args.command == "check":
            file_count, invariant_count = check_contract(root, contract)
            print(
                f"CentL26 design contract: PASS "
                f"({file_count} approved files, {invariant_count} semantic invariants)"
            )
        else:
            if not args.confirm_visual_review:
                raise ContractError(
                    "approval requires --confirm-visual-review after review at 1366x768 and 1440x900"
                )
            file_count, invariant_count = approve_contract(
                root, manifest_path, contract, args.version, args.reason
            )
            print(
                f"CentL26 design contract: APPROVED {args.version} "
                f"({file_count} files, {invariant_count} semantic invariants)"
            )
    except ContractError as exc:
        print(f"CentL26 design contract: FAIL: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
