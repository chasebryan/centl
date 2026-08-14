from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
INGEST = ROOT / "scripts" / "caravan-public-origin-ingest"


def write_executable(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def make_fixture(root: Path) -> tuple[Path, Path, Path, Path, dict[str, str]]:
    mirror = root / "mirror"
    mirror.mkdir()
    (mirror / "MIRROR-SHA256SUMS").write_text("fixture receipt\n", encoding="utf-8")

    authorization = root / "source-authorization.json"
    authorization.write_text("{}\n", encoding="utf-8")

    tools = root / "tools" / "scripts"
    tools.mkdir(parents=True)
    marker = root / "publication-export-called"

    write_executable(tools / "mirror-receipt", "#!/bin/sh\nexit 0\n")
    write_executable(
        tools / "caravan-public-origin-source-export.py",
        "#!/bin/sh\nset -eu\nmkdir -p \"$3\"\nprintf 'source-only fixture\\n' > \"$3/INDEX.json\"\n",
    )
    write_executable(
        tools / "publication-export",
        "#!/bin/sh\nset -eu\nprintf 'called\\n' > \"$FCF_TEST_PUBLICATION_MARKER\"\nexit 91\n",
    )
    write_executable(tools / "model-origin-export.py", "#!/bin/sh\nexit 1\n")

    state = root / "state"
    approved = state / "approved"
    work = state / "work"
    env = os.environ.copy()
    env.update(
        {
            "FCF_CARAVAN_PRESERVATION_ROOT": str(mirror),
            "FCF_CARAVAN_SOURCE_AUTHORIZATION": str(authorization),
            "FCF_CARAVAN_APPROVED_ROOT": str(approved),
            "FCF_CARAVAN_INGEST_WORK_ROOT": str(work),
            "FCF_CARAVAN_TOOLS_ROOT": str(tools.parent),
            "FCF_CARAVAN_SEMANTIC_MODE": "auto",
            "FCF_TEST_PUBLICATION_MARKER": str(marker),
        }
    )
    return mirror, approved, work, marker, env


def make_writable(root: Path) -> None:
    if not root.exists():
        return
    for current, dirs, files in os.walk(root, topdown=False):
        for name in files:
            (Path(current) / name).chmod(0o600)
        for name in dirs:
            (Path(current) / name).chmod(0o700)
    root.chmod(0o700)


class CaravanPublicOriginIngestTests(unittest.TestCase):
    def test_missing_releases_is_valid_source_only_ingest(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            mirror, approved, _work, marker, env = make_fixture(root)
            self.assertFalse((mirror / "releases").exists())
            try:
                run = subprocess.run(
                    ["bash", str(INGEST)],
                    env=env,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
                self.assertFalse(marker.exists(), "release exporter must not run when release storage is absent")
                status = json.loads((approved / "INGEST-STATUS.json").read_text(encoding="utf-8"))
                self.assertTrue(status["source_export_present"])
                self.assertFalse(status["release_export_present"])
                self.assertFalse(status["semantic_export_present"])
                self.assertEqual(status["semantic_status"], "withheld-by-provenance-policy")
                self.assertNotIn("releases", {p.name for p in approved.iterdir()})
            finally:
                make_writable(approved)

    def test_nonempty_release_state_still_requires_strict_export(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            mirror, approved, _work, marker, env = make_fixture(root)
            releases = mirror / "releases"
            releases.mkdir()
            (releases / "unexpected-state").write_text("must not be ignored\n", encoding="utf-8")
            try:
                run = subprocess.run(
                    ["bash", str(INGEST)],
                    env=env,
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertNotEqual(run.returncode, 0)
                self.assertTrue(marker.exists(), "nonempty release state must be sent through strict validation")
                self.assertFalse(approved.exists())
            finally:
                make_writable(approved)


if __name__ == "__main__":
    unittest.main()
