from __future__ import annotations

from hashlib import sha256
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
STYLE_SHA256 = "e3fa72e283b131b1f6e5894c03585c55bfeef390d8c6271b22b0458f38e805f4"
JOIN_SHA256 = "aa1480941f2a1f676eebd295b3ddee2a55233966de6fd3a88f0d033d0e024f27"


def sha(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


class SiteCopyTests(unittest.TestCase):
    def test_visual_and_join_scheme_files_are_untouched(self) -> None:
        self.assertEqual(sha(SITE / "style.css"), STYLE_SHA256)
        self.assertEqual(sha(SITE / "join.html"), JOIN_SHA256)

    def test_centl_page_states_oasis_and_installs_from_oasis(self) -> None:
        html = (SITE / "centl.html").read_text(encoding="utf-8")
        self.assertIn("CENTL v0.14.0 is an Oasis release", html)
        self.assertNotIn("Oasis candidate", html)
        self.assertIn("centl/oasis/install", html)
        self.assertNotIn("centl/main/install", html)
        self.assertNotIn("CENTL-MIRAGE", html)
        self.assertNotIn("CARAVAN", html)

    def test_software_page_does_not_call_github_latest_the_oasis_release(self) -> None:
        html = (SITE / "software.html").read_text(encoding="utf-8")
        self.assertIn("releases/tag/v0.14.0", html)
        self.assertNotIn("releases/latest", html)
        self.assertIn("centl/oasis/install", html)

    def test_docs_page_is_a_start_here_index(self) -> None:
        html = (SITE / "docs.html").read_text(encoding="utf-8")
        self.assertIn("Start here", html)
        self.assertIn("Go deeper", html)
        self.assertNotIn("CARAVAN-PHASE1.md", html)
        self.assertNotIn("CENTL-MIRAGE.md", html)
        self.assertIn("FCF-CAMPS.md", html)

    def test_home_does_not_pitch_every_surface(self) -> None:
        html = (SITE / "index.html").read_text(encoding="utf-8")
        self.assertIn("centl/oasis/install", html)
        self.assertIn("FCF Camp #1", html)
        self.assertNotIn("proposal.html", html)
        self.assertNotIn("Why simple HTML", html)
        self.assertNotIn("CENTL-MIRAGE", html)

    def test_readme_leads_with_the_product(self) -> None:
        text = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("## Current release status", text)
        self.assertIn("CENTL v0.14.0 is an Oasis release", text)
        self.assertIn("FCF Camp #1", text)
        self.assertIn("oasis/install", text)
        self.assertNotIn("Mathematical Introspective Recursive Autonomous Growth Engine", text)
        self.assertLess(len(text.splitlines()), 110)


if __name__ == "__main__":
    unittest.main()
