from __future__ import annotations

import importlib.util
import importlib.machinery
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
LOADER = importlib.machinery.SourceFileLoader(
    "caravan_lead_census", str(ROOT / "scripts" / "caravan-lead-census")
)
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
assert SPEC is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
LOADER.exec_module(MODULE)


class CaravanLeadCensusTests(unittest.TestCase):
    def test_probe_accepts_only_the_public_origin_boundary(self) -> None:
        status = {
            "schema": "fcf-caravan-public-origin-status-v2",
            "mode": "fcf-owned-public-origin",
            "uploads": False,
            "proxying": False,
            "arbitrary_paths": False,
        }
        result = subprocess.CompletedProcess(
            ["curl"],
            0,
            stdout=(json.dumps(status) + "\n").encode(),
            stderr=b"",
        )
        with patch.object(MODULE.subprocess, "run", return_value=result):
            self.assertTrue(MODULE.probe("a" * 56 + ".onion", "127.0.0.1:9050", 5))

        bad = dict(status, uploads=True)
        result = subprocess.CompletedProcess(
            ["curl"],
            0,
            stdout=(json.dumps(bad) + "\n").encode(),
            stderr=b"",
        )
        with patch.object(MODULE.subprocess, "run", return_value=result):
            self.assertFalse(MODULE.probe("a" * 56 + ".onion", "127.0.0.1:9050", 5))

    def test_writer_publishes_aggregate_without_identity_fields(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            output = Path(td) / "lead-census-v1.json"
            MODULE.write_document(output, active=True)
            document = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(document["active_camels"], 1)
            self.assertEqual(document["hungry_camels"], 0)
            self.assertEqual(document["lost_camels"], 0)
            self.assertFalse(document["individual_nodes_public"])
            self.assertFalse(document["ip_addresses_public"])
            self.assertNotIn("node_id", document)
            self.assertNotIn("origin", document)

            MODULE.write_document(output, active=False)
            document = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(document["active_camels"], 0)
            self.assertEqual(document["hungry_camels"], 0)
            self.assertEqual(document["lost_camels"], 1)
            self.assertEqual(document["probe"], "unreachable")


if __name__ == "__main__":
    unittest.main()
