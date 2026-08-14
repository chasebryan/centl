from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class PrimaryNavigationParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_nav = False
        self.in_h2 = False
        self.in_link = False
        self.headings: list[str] = []
        self.links: list[tuple[str, str | None]] = []
        self._text: list[str] = []
        self._href: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "nav" and values.get("aria-label") == "Primary":
            self.in_nav = True
        elif self.in_nav and tag == "h2":
            self.in_h2 = True
            self._text = []
        elif self.in_nav and tag == "a":
            self.in_link = True
            self._text = []
            self._href = values.get("href")

    def handle_data(self, data: str) -> None:
        if self.in_h2 or self.in_link:
            self._text.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "h2" and self.in_h2:
            self.headings.append(" ".join("".join(self._text).split()))
            self.in_h2 = False
        elif tag == "a" and self.in_link:
            label = " ".join("".join(self._text).split())
            self.links.append((label, self._href))
            self.in_link = False
        elif tag == "nav" and self.in_nav:
            self.in_nav = False


class SiteNavigationTests(unittest.TestCase):
    def test_bazaar_has_a_simple_join_button_and_consent_page(self) -> None:
        bazaar = (ROOT / "site" / "mirrors.html").read_text(encoding="utf-8")
        join = (ROOT / "site" / "join.html").read_text(encoding="utf-8")
        self.assertIn('class="caravan-join-button" href="join.html"', bazaar)
        self.assertIn('class="caravan-consent"', join)
        self.assertIn('class="caravan-join-button caravan-join-action"', join)
        self.assertIn("CARAVAN-HOST-POLICY.md", join)

    def test_join_page_generates_a_signed_option_specific_launcher(self) -> None:
        join = (ROOT / "site" / "join.html").read_text(encoding="utf-8")
        self.assertIn('id="download-caravan-launcher"', join)
        self.assertIn("new Blob", join)
        self.assertIn("fcf-caravan-join-1.0.8", join)
        self.assertIn("fcf-signify-x86_64-glibc", join)
        self.assertIn("EXPECTED_HELPER_SHA256", join)
        self.assertIn("-V -q", join)
        self.assertIn('--missions \\\"$MISSIONS\\\"', join)
        self.assertIn('--transport \\\"$TRANSPORT\\\"', join)
        self.assertNotIn("releases/tag/fcf-caravan-join-1.0.5", join)

    def test_every_html_page_uses_the_same_primary_navigation(self) -> None:
        expected_headings = ["Foundation", "External"]
        expected_labels = [
            "Home",
            "About FCF",
            "Funding",
            "CENTL",
            "Software",
            "The Bazaar",
            "Documentation",
            "CENTL on GitHub",
            "Latest release",
            "GitHub Sponsors",
        ]
        for path in sorted((ROOT / "site").rglob("*.html")):
            parser = PrimaryNavigationParser()
            parser.feed(path.read_text(encoding="utf-8"))
            labels = [label for label, _ in parser.links]
            self.assertEqual(parser.headings, expected_headings, path)
            self.assertEqual(labels, expected_labels, path)


if __name__ == "__main__":
    unittest.main()
