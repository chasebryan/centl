from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ACTIVATE = ROOT / "scripts" / "caravan-public-origin-activate.py"


def load_activation():
    spec = importlib.util.spec_from_file_location("caravan_activation_metadata", ACTIVATE)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class CaravanPublicOriginMetadataTests(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_activation()
        self.authorization = "a" * 64
        self.receipt = "b" * 64
        self.branches = {
            branch: {
                "commit": (str(index + 1) * 40),
                "archive": f"centl-{branch}.tar.gz",
                "sha256": (str(index + 4) * 64),
            }
            for index, branch in enumerate(("main", "oasis", "mirage"))
        }
        self.source_index = {
            "schema": "centl-fcf-source-index-v2",
            "repository": "chasebryan/centl",
            "mirror_receipt_sha256": self.receipt,
            "authorization_sha256": self.authorization,
            "branches": self.branches,
        }

    def write_generation(self, root: Path) -> None:
        caravan = root / "caravan"
        caravan.mkdir(parents=True)
        ingest = {
            "schema": "fcf-caravan-approved-ingest-status-v2",
            "generated_at": "2026-08-12T00:00:00+00:00",
            "preservation_mirror_verified": True,
            "mirror_regular_receipt_sha256": self.receipt,
            "source_authorization_sha256": self.authorization,
            "source_export_present": True,
            "release_export_present": True,
            "semantic_export_present": False,
            "semantic_status": "withheld-by-provenance-policy",
        }
        (caravan / "INGEST-STATUS.json").write_text(
            json.dumps(ingest, sort_keys=True) + "\n", encoding="utf-8"
        )
        status = {
            "schema": "fcf-caravan-public-origin-status-v2",
            "node_id": "fcf-caravan-x200-001",
            "mode": "fcf-owned-public-origin",
            "generated_at": "2026-08-12T00:00:00+00:00",
            "source_branches": self.branches,
            "preservation_ingest": ingest,
            "source_authorization_sha256": self.authorization,
            "mirror_receipt_sha256": self.receipt,
            "uploads": False,
            "proxying": False,
            "arbitrary_paths": False,
        }
        (root / "status.json").write_text(
            json.dumps(status, sort_keys=True) + "\n", encoding="utf-8"
        )

    def test_matching_status_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.write_generation(root)
            self.module.verify_status(root, self.source_index)

    def test_status_cannot_lie_about_authorization(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.write_generation(root)
            status_path = root / "status.json"
            status = json.loads(status_path.read_text(encoding="utf-8"))
            status["source_authorization_sha256"] = "c" * 64
            status_path.write_text(json.dumps(status) + "\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                self.module.verify_status(root, self.source_index)

    def test_status_cannot_lie_about_preservation_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.write_generation(root)
            status_path = root / "status.json"
            status = json.loads(status_path.read_text(encoding="utf-8"))
            status["mirror_receipt_sha256"] = "d" * 64
            status_path.write_text(json.dumps(status) + "\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                self.module.verify_status(root, self.source_index)

    def test_ingest_status_cannot_diverge_from_source_index(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.write_generation(root)
            ingest_path = root / "caravan" / "INGEST-STATUS.json"
            ingest = json.loads(ingest_path.read_text(encoding="utf-8"))
            ingest["mirror_regular_receipt_sha256"] = "e" * 64
            ingest_path.write_text(json.dumps(ingest) + "\n", encoding="utf-8")
            status_path = root / "status.json"
            status = json.loads(status_path.read_text(encoding="utf-8"))
            status["preservation_ingest"] = ingest
            status_path.write_text(json.dumps(status) + "\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                self.module.verify_status(root, self.source_index)


if __name__ == "__main__":
    unittest.main()
