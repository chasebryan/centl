from __future__ import annotations

import hashlib
import json
from pathlib import Path
import stat
import tempfile
import unittest

from caravan.catalog import parse_catalog_bytes
from caravan.content import ContentStore
from caravan.join_caravan import (
    INVITE_SCHEMA,
    POLICY_VERSION,
    Invite,
    JoinError,
    _normalize_missions,
    _write_generation,
)


class JoinCaravanTests(unittest.TestCase):
    def test_invite_requires_pinned_origin_catalog_and_policy(self) -> None:
        digest = "a" * 64
        invite = Invite.from_dict(
            {
                "schema": INVITE_SCHEMA,
                "origin": "a" * 56 + ".onion",
                "catalog_sha256": digest,
                "policy_version": POLICY_VERSION,
                "policy_sha256": "b" * 64,
            }
        )
        self.assertEqual(invite.catalog_sha256, digest)
        with self.assertRaises(JoinError):
            Invite.from_dict(
                {
                    "schema": INVITE_SCHEMA,
                    "origin": "not-an-onion",
                    "catalog_sha256": digest,
                    "policy_version": POLICY_VERSION,
                    "policy_sha256": "b" * 64,
                }
            )

    def test_mission_normalization_is_closed_world(self) -> None:
        self.assertEqual(_normalize_missions("all"), ("source", "releases", "semantic", "recovery"))
        self.assertEqual(_normalize_missions("recovery,source"), ("source", "recovery"))
        with self.assertRaises(JoinError):
            _normalize_missions("source,arbitrary")

    def test_generation_contains_only_verified_selected_objects(self) -> None:
        payload = b"approved source index\n"
        digest = hashlib.sha256(payload).hexdigest()
        catalog_bytes = (
            json.dumps(
                {
                    "schema": "centl-caravan-catalog-v1",
                    "catalog_version": 1,
                    "artifacts": [
                        {
                            "logical_path": "source/INDEX.json",
                            "artifact_id": f"sha256:{digest}",
                            "length": len(payload),
                            "distribution": "public-approved",
                            "chunks": [
                                {"offset": 0, "length": len(payload), "sha256": digest}
                            ],
                        }
                    ],
                },
                sort_keys=True,
            ).encode()
            + b"\n"
        )
        catalog = parse_catalog_bytes(catalog_bytes)
        selected = list(catalog.artifacts)
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            store = ContentStore(root / "store", max_bytes=1024 * 1024)
            incoming = root / "incoming"
            incoming.write_bytes(payload)
            store.import_file(incoming, expected=selected[0].identity)
            generation = _write_generation(
                data_root=root / "data",
                catalog_bytes=catalog_bytes,
                catalog=catalog,
                selected=selected,
                store=store,
                downloaded={"source/INDEX.json": incoming},
                missions=("source",),
                policy_version=POLICY_VERSION,
            )
            self.assertTrue((root / "data" / "current").is_symlink())
            self.assertEqual((generation / "source" / "INDEX.json").read_bytes(), payload)
            status = json.loads((generation / "status.json").read_text())
            self.assertFalse(status["public_node_identity"])
            for path in generation.rglob("*"):
                mode = stat.S_IMODE(path.lstat().st_mode)
                if path.is_dir():
                    self.assertEqual(mode & 0o222, 0)
                else:
                    self.assertEqual(mode & 0o222, 0)


if __name__ == "__main__":
    unittest.main()
