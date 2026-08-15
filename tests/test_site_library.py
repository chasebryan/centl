from __future__ import annotations

import subprocess
import sys
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
PUBLISH = ROOT / "scripts" / "publish-site-library.py"


class SiteLibraryTests(unittest.TestCase):
    def test_research_library_has_native_suggestions_and_hosted_papers(self) -> None:
        html = (SITE / "research.html").read_text(encoding="utf-8")
        self.assertIn('<datalist id="library-suggestions">', html)
        self.assertIn('list="library-suggestions"', html)
        self.assertIn("No JavaScript is used", html)
        papers = list((SITE / "library").glob("*.html"))
        manuals = list((SITE / "manuals").glob("*.html"))
        self.assertGreaterEqual(len(papers), 200)
        self.assertGreaterEqual(len(manuals), 20)
        self.assertTrue((SITE / "library" / "ws-cand-003-erdos-straus-type-ab-shadow-structure.html").is_file())
        self.assertTrue((SITE / "manuals" / "install.html").is_file())
        self.assertIn("ws-cand-003", html)

    def test_published_library_is_current(self) -> None:
        result = subprocess.run(
            [sys.executable, str(PUBLISH), "--check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
