#!/usr/bin/env python3
"""Authenticate the narrowly allowed stale-receipt state for caravan-preserve.

The first physical CARAVAN bring-up performed source-only refreshes after
capsule-build had already created a whole-mirror receipt. This helper allows the
new driver to adopt that one transitional state without accepting arbitrary
whole-mirror drift.
"""

from __future__ import annotations

import sys
from pathlib import Path

import integrity


RECEIPT_FILES = {
    "MIRROR-SHA256SUMS",
    "MIRROR-SHA256SUMS.sha256",
    "MIRROR-SYMLINKS",
    "MIRROR-SYMLINKS.sha256",
}

ALLOWED_SOURCE_REFRESH = {
    "project/centl.bundle",
    "project/SOURCE-COMMIT",
    "project/SOURCE-SHA256SUMS",
    "project/SOURCE-SHA256SUMS.sha256",
}


def die(message: str) -> "NoReturn":
    raise SystemExit(f"caravan preserve receipt: {message}")


def main() -> int:
    if len(sys.argv) != 2:
        die("usage: caravan-preserve-receipt.py MIRROR_DIR")

    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        die(f"mirror directory not found: {root}")

    manifest = root / "MIRROR-SHA256SUMS"
    manifest_hash = root / "MIRROR-SHA256SUMS.sha256"
    symlinks = root / "MIRROR-SYMLINKS"
    symlinks_hash = root / "MIRROR-SYMLINKS.sha256"
    for path in (manifest, manifest_hash, symlinks, symlinks_hash):
        if not path.is_file() or path.is_symlink():
            die(f"required receipt file missing or unsafe: {path.name}")

    # First authenticate the old receipt documents themselves. An attacker may
    # not replace the manifest and then ask this transitional verifier to trust
    # the replacement.
    integrity.verify_manifest(manifest_hash, root)
    integrity.verify_manifest(symlinks_hash, root)

    entries = integrity.parse_manifest(manifest)
    expected = {name: digest for digest, name in entries}
    missing_allowed = ALLOWED_SOURCE_REFRESH - set(expected)
    if missing_allowed:
        die(
            "old receipt does not contain every controlled source-refresh path: "
            + ", ".join(sorted(missing_allowed))
        )

    # Compare exact regular-file membership after removing only the four source
    # files that the manual first-node workflow was known to refresh and the
    # receipt documents that mirror-receipt deliberately excludes from itself.
    actual_regular, _ = integrity.walk_tree(root)
    actual = set(actual_regular) - RECEIPT_FILES - ALLOWED_SOURCE_REFRESH
    expected_names = set(expected) - ALLOWED_SOURCE_REFRESH

    missing = sorted(expected_names - actual)
    extra = sorted(actual - expected_names)
    if missing or extra:
        for name in missing:
            print(f"MISSING {name}", file=sys.stderr)
        for name in extra:
            print(f"UNEXPECTED {name}", file=sys.stderr)
        die(
            f"mirror drift exists outside controlled source refresh: "
            f"{len(missing)} missing, {len(extra)} unexpected"
        )

    failures = 0
    for name in sorted(expected_names):
        path = root / integrity.validate_relative_name(name)
        if path.is_symlink() or not path.is_file():
            print(f"MISSING {name}", file=sys.stderr)
            failures += 1
            continue
        actual_digest = integrity.sha256_file(path)
        if actual_digest != expected[name]:
            print(
                f"FAILED {name}: expected {expected[name]}, got {actual_digest}",
                file=sys.stderr,
            )
            failures += 1
    if failures:
        die(f"{failures} changed file(s) outside controlled source refresh")

    # Source-only refreshes do not have permission to alter the symlink tree.
    integrity.verify_symlink_manifest(symlinks, root, ignored=set())

    print("FCF controlled stale-source receipt authentication: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
