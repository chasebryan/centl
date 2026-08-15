from __future__ import annotations

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
EXECUTABLE_SCRIPT = re.compile(
    r"<script(?![^>]*type=[\"']application/ld\+json[\"'])",
    re.I,
)


class SiteCopyTests(unittest.TestCase):
    def test_site_serves_no_executable_javascript(self) -> None:
        js_files = list(SITE.rglob("*.js"))
        self.assertEqual(js_files, [])
        for path in SITE.rglob("*.html"):
            html = path.read_text(encoding="utf-8")
            self.assertIsNone(EXECUTABLE_SCRIPT.search(html), path)

    def test_centl_page_states_oasis_and_installs_from_oasis(self) -> None:
        html = (SITE / "centl.html").read_text(encoding="utf-8")
        self.assertIn("CENTL v0.15.0 is an Oasis release", html)
        self.assertNotIn("Oasis candidate", html)
        self.assertIn("centl/oasis/install", html)
        self.assertNotIn("centl/main/install", html)
        self.assertNotIn("CENTL-MIRAGE", html)
        self.assertNotIn("CARAVAN", html)

    def test_software_page_does_not_call_github_latest_the_oasis_release(self) -> None:
        html = (SITE / "software.html").read_text(encoding="utf-8")
        self.assertIn("releases/tag/v0.15.0", html)
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
        self.assertIn("CENTL Marsa", html)
        self.assertNotIn("proposal.html", html)
        self.assertNotIn("Why simple HTML", html)
        self.assertNotIn("CENTL-MIRAGE", html)
        self.assertIn("research.html", html)

    def test_readme_leads_with_the_product(self) -> None:
        text = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("## Current release status", text)
        self.assertIn("CENTL v0.15.0 is an Oasis release", text)
        self.assertIn("FCF Camp #1", text)
        self.assertIn("oasis/install", text)
        self.assertNotIn("Mathematical Introspective Recursive Autonomous Growth Engine", text)
        self.assertLess(len(text.splitlines()), 130)


if __name__ == "__main__":
    unittest.main()
