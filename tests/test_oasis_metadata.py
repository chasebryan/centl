from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "centl_oasis_metadata", ROOT / "scripts/oasis-metadata-check.py"
)
assert SPEC is not None and SPEC.loader is not None
METADATA = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = METADATA
SPEC.loader.exec_module(METADATA)


class MetadataTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="centl-oasis-metadata-")
        self.root = Path(self.temp.name)
        (self.root / "src/ocaml").mkdir(parents=True)
        (self.root / "docs/releases").mkdir(parents=True)
        self.write_coherent("0.13.0")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_coherent(self, version: str) -> None:
        (self.root / "src/ocaml/centl_version.ml").write_text(
            f'let value = "{version}"\n', encoding="utf-8"
        )
        (self.root / f"docs/releases/{version}.md").write_text(
            f"# CENTL {version} - test release\n", encoding="utf-8"
        )
        (self.root / "CHANGELOG.md").write_text(
            f"# Changelog\n\n## {version} - today\n", encoding="utf-8"
        )
        (self.root / "README.md").write_text(
            "# CENTL OASIS\n\n"
            "## Current release status\n\n"
            f"**CENTL v{version} is being qualified as an Oasis release.**\n\n"
            "## Next section\n",
            encoding="utf-8",
        )
        (self.root / "docs/OASIS.md").write_text(
            "# Oasis\n\n" f"## v{version}\n\nOasis candidate.\n",
            encoding="utf-8",
        )


class CoherenceTests(MetadataTestCase):
    def test_coherent_metadata_passes(self) -> None:
        self.assertEqual(METADATA.check(self.root), "0.13.0")

    def test_readme_future_version_blocks_qualification(self) -> None:
        (self.root / "README.md").write_text(
            "# CENTL OASIS\n\n"
            "## Current release status\n\n"
            "**CENTL v0.14.0 is being qualified as an Oasis release.**\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(METADATA.MetadataError, "authoritative source is 0.13.0"):
            METADATA.check(self.root)

    def test_oasis_policy_future_version_blocks_qualification(self) -> None:
        (self.root / "docs/OASIS.md").write_text(
            "# Oasis\n\n## v0.14.0\n\nOasis candidate.\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(METADATA.MetadataError, "authoritative source is 0.13.0"):
            METADATA.check(self.root)

    def test_missing_release_notes_blocks_qualification(self) -> None:
        (self.root / "docs/releases/0.13.0.md").unlink()
        with self.assertRaises(METADATA.MetadataError):
            METADATA.check(self.root)

    def test_release_note_title_must_match_source_version(self) -> None:
        (self.root / "docs/releases/0.13.0.md").write_text(
            "# CENTL 0.14.0 - wrong\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(METADATA.MetadataError, "does not identify"):
            METADATA.check(self.root)

    def test_changelog_must_contain_source_version(self) -> None:
        (self.root / "CHANGELOG.md").write_text(
            "# Changelog\n\n## 0.12.0 - old\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(METADATA.MetadataError, "no release heading"):
            METADATA.check(self.root)

    def test_multiple_current_readme_versions_are_rejected(self) -> None:
        (self.root / "README.md").write_text(
            "# CENTL OASIS\n\n"
            "## Current release status\n\n"
            "CENTL v0.13.0 is stable while CENTL v0.14.0 is also current.\n",
            encoding="utf-8",
        )
        with self.assertRaises(METADATA.MetadataError):
            METADATA.check(self.root)


if __name__ == "__main__":
    unittest.main()
