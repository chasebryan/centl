#!/usr/bin/env python3
"""Regression tests for the CentL26 approved-design gate."""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
SCRIPT = REPOSITORY / "scripts" / "centl26-design-contract.py"
MANIFEST_RELATIVE = Path("design/centl26/approved-design.json")


class DesignContractTests(unittest.TestCase):
    def run_contract(
        self, root: Path, *arguments: str, expected: int = 0
    ) -> subprocess.CompletedProcess[str]:
        completed = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(root), *arguments],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
        )
        self.assertEqual(
            completed.returncode,
            expected,
            msg=f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}",
        )
        return completed

    def fixture(self, destination: Path) -> dict[str, object]:
        manifest = json.loads((REPOSITORY / MANIFEST_RELATIVE).read_text(encoding="utf-8"))
        manifest_destination = destination / MANIFEST_RELATIVE
        manifest_destination.parent.mkdir(parents=True)
        shutil.copy2(REPOSITORY / MANIFEST_RELATIVE, manifest_destination)
        files = manifest["files"]
        self.assertIsInstance(files, dict)
        for relative in files:
            source = REPOSITORY / relative
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        return manifest

    def test_checked_in_approved_design_passes(self) -> None:
        completed = self.run_contract(REPOSITORY, "check")
        self.assertIn("CentL26 design contract: PASS", completed.stdout)

    def test_byte_drift_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl26-design-test-") as raw:
            root = Path(raw)
            self.fixture(root)
            css = root / "src-web/server/lab.css"
            css.write_text(css.read_text(encoding="utf-8") + "\n/* unapproved drift */\n", encoding="utf-8")

            completed = self.run_contract(root, "check", expected=1)
            self.assertIn("approved visual source drift detected", completed.stderr)
            self.assertIn("src-web/server/lab.css", completed.stderr)

    def test_hash_refresh_cannot_bypass_semantic_baseline(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl26-design-test-") as raw:
            root = Path(raw)
            self.fixture(root)
            css = root / "src-web/server/lab.css"
            source = css.read_text(encoding="utf-8")
            approved = "body {\n  margin: 0;\n  overflow: hidden;"
            self.assertIn(approved, source)
            css.write_text(
                source.replace(approved, "body {\n  margin: 0;\n  overflow: auto;", 1),
                encoding="utf-8",
            )

            completed = self.run_contract(
                root,
                "approve",
                "--version",
                "CentL26.1",
                "--reason",
                "test-only semantic regression",
                "--confirm-visual-review",
                expected=1,
            )
            self.assertIn("approved CSS declaration body overflow changed", completed.stderr)

    def test_intentional_reviewed_update_refreshes_hashes(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl26-design-test-") as raw:
            root = Path(raw)
            original = self.fixture(root)
            css = root / "src-web/server/lab.css"
            css.write_text(css.read_text(encoding="utf-8") + "\n/* reviewed fixture change */\n", encoding="utf-8")

            completed = self.run_contract(
                root,
                "approve",
                "--version",
                "CentL26.1",
                "--reason",
                "Reviewed fixture-only visual adjustment.",
                "--confirm-visual-review",
            )
            self.assertIn("APPROVED CentL26.1", completed.stdout)
            self.run_contract(root, "check")

            updated = json.loads((root / MANIFEST_RELATIVE).read_text(encoding="utf-8"))
            self.assertNotEqual(
                original["files"]["src-web/server/lab.css"],
                updated["files"]["src-web/server/lab.css"],
            )
            self.assertEqual(updated["approval"]["release"], "CentL26.1")
            self.assertEqual(
                updated["approval"]["change_note"],
                "Reviewed fixture-only visual adjustment.",
            )

    def test_approval_requires_explicit_visual_review_confirmation(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl26-design-test-") as raw:
            root = Path(raw)
            self.fixture(root)
            completed = self.run_contract(
                root,
                "approve",
                "--version",
                "CentL26.1",
                "--reason",
                "Missing review confirmation fixture.",
                expected=1,
            )
            self.assertIn("requires --confirm-visual-review", completed.stderr)


if __name__ == "__main__":
    unittest.main()
