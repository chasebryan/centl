from __future__ import annotations

import json
from html.parser import HTMLParser
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"


class HeadParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.canonical: str | None = None
        self.robots: str | None = None
        self.has_og_title = False
        self.llms_alternate = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "link" and values.get("rel") == "canonical":
            self.canonical = values.get("href")
        if tag == "meta" and values.get("name") == "robots":
            self.robots = values.get("content")
        if tag == "meta" and values.get("property") == "og:title":
            self.has_og_title = True
        if (
            tag == "link"
            and values.get("rel") == "alternate"
            and values.get("href")
            and "llms.txt" in (values.get("href") or "")
        ):
            self.llms_alternate = True


class SiteDiscoveryTests(unittest.TestCase):
    def test_public_html_pages_have_search_discovery_heads(self) -> None:
        pages = [
            SITE / "index.html",
            SITE / "about.html",
            SITE / "centl.html",
            SITE / "software.html",
            SITE / "docs.html",
            SITE / "research.html",
            SITE / "research-erdos-straus.html",
            SITE / "funding.html",
            SITE / "mirrors.html",
            SITE / "join.html",
            SITE / "ai.html",
            SITE / "proposal.html",
            SITE / "pub" / "index.html",
        ]
        for path in pages:
            parser = HeadParser()
            parser.feed(path.read_text(encoding="utf-8"))
            self.assertTrue(parser.canonical, path)
            self.assertIn("freecomputation.org", parser.canonical or "")
            self.assertIsNotNone(parser.robots, path)
            self.assertTrue(parser.has_og_title, path)
            self.assertTrue(parser.llms_alternate, path)

    def test_robots_welcomes_search_and_ai_crawlers(self) -> None:
        text = (SITE / "robots.txt").read_text(encoding="utf-8")
        self.assertIn("Sitemap: https://freecomputation.org/sitemap.xml", text)
        for agent in ("Googlebot", "GPTBot", "ClaudeBot", "PerplexityBot", "Grok"):
            self.assertIn(f"User-agent: {agent}", text)
            self.assertIn("Allow: /", text)

    def test_sitemap_lists_machine_and_human_entry_points(self) -> None:
        text = (SITE / "sitemap.xml").read_text(encoding="utf-8")
        for loc in (
            "https://freecomputation.org/",
            "https://freecomputation.org/centl.html",
            "https://freecomputation.org/research.html",
            "https://freecomputation.org/ai.html",
            "https://freecomputation.org/proposal.html",
            "https://freecomputation.org/join.html",
            "https://freecomputation.org/llms.txt",
        ):
            self.assertIn(f"<loc>{loc}</loc>", text)

    def test_machine_briefings_welcome_programs_without_granting_authority(self) -> None:
        llms = (SITE / "llms.txt").read_text(encoding="utf-8")
        self.assertIn("you are welcome", llms.lower())
        self.assertIn("may not confer mathematical truth", llms)
        self.assertIn("https://freecomputation.org/", llms)
        index = json.loads((SITE / "pub" / "machine-index.json").read_text(encoding="utf-8"))
        self.assertEqual(index["schema"], "fcf-machine-index-v1")
        self.assertFalse(index["oasis_declared_by_this_file"])
        self.assertFalse(index["model_is_mathematical_authority"])
        self.assertTrue(any(item["name"] == "mcp" for item in index["interfaces"]))
        self.assertIn("proposal", index["briefings"])

    def test_company_and_ai_proposal_is_open_and_does_not_sell_oasis(self) -> None:
        html = (SITE / "proposal.html").read_text(encoding="utf-8")
        self.assertIn("draft pull request against <code>mirage</code>", html)
        self.assertIn("github.com/sponsors/chasebryan", html)
        self.assertIn("Money is not a crown", html)
        proposal = json.loads((SITE / "pub" / "proposal.json").read_text(encoding="utf-8"))
        self.assertEqual(proposal["schema"], "fcf-proposal-v1")
        self.assertEqual(proposal["status"], "open")
        self.assertFalse(proposal["oasis_declared_by_this_file"])
        self.assertFalse(proposal["endorsement_granted"])
        self.assertFalse(proposal["sla_offered"])
        self.assertEqual(proposal["contribute"]["pull_request_base"], "mirage")
        self.assertIsNone(proposal["contact"]["sales_inbox"])
        self.assertIn("Oasis qualification", proposal["sponsor"]["does_not_buy"])

    def test_home_json_ld_is_valid_and_names_centl(self) -> None:
        html = (SITE / "index.html").read_text(encoding="utf-8")
        start = html.index('<script type="application/ld+json">')
        end = html.index("</script>", start)
        payload = html[start : end].split(">", 1)[1]
        graph = json.loads(payload)
        types = {node["@type"] for node in graph["@graph"]}
        self.assertIn("Organization", types)
        self.assertIn("SoftwareApplication", types)
        self.assertIn("WebSite", types)

    def test_style_sheet_was_not_modified_by_discovery_files(self) -> None:
        css = (SITE / "style.css").read_text(encoding="utf-8")
        self.assertGreater(len(css), 100)


if __name__ == "__main__":
    unittest.main()
