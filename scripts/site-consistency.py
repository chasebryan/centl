#!/usr/bin/env python3
"""Keep the public FCF site shell identical across every HTML page.

The sidebar is organized and normalized across 4 clear categories:
CENTL & Hub · Documentation · Research · Foundation
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
PUBLISHER = ROOT / "scripts" / "publish-site-library.py"
ONBOARDING_SOURCES = (
    ROOT / "docs" / "MATHEMATICIANS.md",
    ROOT / "docs" / "PHYSICISTS.md",
)

ONBOARDING_EMOJI = ("🧮", "📐", "⚛️", "⚛", "🔬", "🐧", "🍎", "🪟")
NAV_STYLE_MARKER = "/* Site-wide research navigation hierarchy. */"


def nav_html(depth: int) -> str:
    p = "../" * depth
    return f'''<nav aria-label="Primary">
      <h2>CENTL &amp; Hub</h2>
      <ul>
        <li><a href="{p}index.html#top">CENTL Work Area</a></li>
        <li><a href="{p}centl.html#top">About CENTL</a></li>
        <li><a href="{p}research-erdos-straus.html#top">Erdős–Straus Hunt</a></li>
        <li><a href="{p}software.html#top">Software Suite</a></li>
      </ul>
      <h2>Documentation</h2>
      <ul>
        <li><a href="{p}docs.html#top">Documentation Portal</a></li>
        <li><a href="{p}manuals/install.html#top">Installation Guide</a></li>
        <li><a href="{p}manuals/numerics.html#top">Numerical Contract</a></li>
        <li><a href="{p}manuals/syntax.html#top">Syntax &amp; Functions</a></li>
        <li><a href="{p}manuals/sci.html#top">CENTL-SCi &amp; Physics</a></li>
      </ul>
      <h2>Research</h2>
      <ul>
        <li><a href="{p}research.html#top">Research Library</a></li>
        <li><a href="{p}research-erdos-straus.html#top">Erdős–Straus Program</a></li>
        <li><a href="{p}bryan-recursive-entanglement-calculus.html#top">BREC v1.0 Calculus</a></li>
      </ul>
      <h2>Foundation</h2>
      <ul>
        <li><a href="{p}about.html#top">About FCF</a></li>
        <li><a href="{p}funding.html#top">Funding &amp; Sponsors</a></li>
        <li><a href="{p}mirrors.html#top">The Bazaar</a></li>
        <li><a href="https://github.com/chasebryan/centl">GitHub Repository</a></li>
      </ul>
    </nav>'''


def normalize_html(path: Path, text: str) -> str:
    rel = path.relative_to(SITE)
    depth = len(rel.parts) - 1
    prefix = "../" * depth
    normalized, count = re.subn(
        r'<nav aria-label="Primary">.*?</nav>',
        nav_html(depth),
        text,
        count=1,
        flags=re.S,
    )
    if count == 0 and '<div class="layout">' in text:
        raise RuntimeError(f"site shell page has no primary nav: {rel}")
    normalized, shell_count = re.subn(
        r'<div class="shell"(?: id="top")?>',
        '<div class="shell" id="top">',
        normalized,
        count=1,
    )
    if shell_count == 0 and '<div class="layout">' in normalized:
        raise RuntimeError(f"site shell page has no page-top anchor: {rel}")
    normalized = re.sub(
        r'(<div class="brand"><a href=")(?:\.\./)*index\.html(?:#top)?"',
        rf'\1{prefix}index.html#top"',
        normalized,
        count=1,
    )
    return normalized


def normalize_onboarding_source(text: str) -> str:
    for symbol in ONBOARDING_EMOJI:
        text = text.replace(symbol, "")
    return text


def normalized_stylesheet(text: str) -> str:
    """Remove the abandoned nested research-navigation styling."""
    if NAV_STYLE_MARKER not in text:
        return text
    pattern = re.compile(
        r'\n*/\* Site-wide research navigation hierarchy\. \*/.*?'
        r'@media \(max-width: 760px\) \{.*?\n\}\n?',
        re.S,
    )
    return pattern.sub("\n", text, count=1).rstrip() + "\n"


def publisher_nav_function() -> str:
    return '''def render_nav(depth: int) -> str:
    p = "../" * depth
    return f"""<nav aria-label="Primary">
      <h2>CENTL &amp; Hub</h2>
      <ul>
        <li><a href="{p}index.html#top">CENTL Work Area</a></li>
        <li><a href="{p}centl.html#top">About CENTL</a></li>
        <li><a href="{p}research-erdos-straus.html#top">Erdős–Straus Hunt</a></li>
        <li><a href="{p}software.html#top">Software Suite</a></li>
      </ul>
      <h2>Documentation</h2>
      <ul>
        <li><a href="{p}docs.html#top">Documentation Portal</a></li>
        <li><a href="{p}manuals/install.html#top">Installation Guide</a></li>
        <li><a href="{p}manuals/numerics.html#top">Numerical Contract</a></li>
        <li><a href="{p}manuals/syntax.html#top">Syntax &amp; Functions</a></li>
        <li><a href="{p}manuals/sci.html#top">CENTL-SCi &amp; Physics</a></li>
      </ul>
      <h2>Research</h2>
      <ul>
        <li><a href="{p}research.html#top">Research Library</a></li>
        <li><a href="{p}research-erdos-straus.html#top">Erdős–Straus Program</a></li>
        <li><a href="{p}bryan-recursive-entanglement-calculus.html#top">BREC v1.0 Calculus</a></li>
      </ul>
      <h2>Foundation</h2>
      <ul>
        <li><a href="{p}about.html#top">About FCF</a></li>
        <li><a href="{p}funding.html#top">Funding &amp; Sponsors</a></li>
        <li><a href="{p}mirrors.html#top">The Bazaar</a></li>
        <li><a href="https://github.com/chasebryan/centl">GitHub Repository</a></li>
      </ul>
    </nav>"""'''


def curated_research_writer() -> str:
    return '''def write_research_index(papers: list[Record], manuals: list[Record], dest: Path) -> None:
    # research.html is a curated subject index. The bulk publisher owns
    # individual records, not the information architecture of the landing page.
    canonical = SITE / "research.html"
    if dest.resolve() == canonical.resolve():
        return
    dest.write_text(canonical.read_text(encoding="utf-8"), encoding="utf-8")'''


def normalize_publisher(text: str) -> str:
    nav_pattern = re.compile(
        r'def render_nav\(depth: int\) -> str:\n.*?\n\n\ndef wrap_page\(', re.S
    )
    text, nav_count = nav_pattern.subn(
        publisher_nav_function() + "\n\n\ndef wrap_page(", text, count=1
    )
    if nav_count != 1:
        raise RuntimeError("could not normalize publisher render_nav")

    research_pattern = re.compile(
        r'def write_research_index\(papers: list\[Record\], manuals: list\[Record\], dest: Path\) -> None:\n.*?\n\n\ndef write_sitemap\(', re.S
    )
    text, research_count = research_pattern.subn(
        curated_research_writer() + "\n\n\ndef write_sitemap(", text, count=1
    )
    if research_count != 1:
        raise RuntimeError("could not normalize publisher write_research_index")

    brec_sitemap = '    ("https://freecomputation.org/bryan-recursive-entanglement-calculus.html", "monthly", "0.8"),\n'
    if "freecomputation.org/bryan-recursive-entanglement-calculus.html" not in text:
        anchor = '    ("https://freecomputation.org/research-erdos-straus.html", "weekly", "0.8"),\n'
        if anchor not in text:
            raise RuntimeError("could not locate sitemap research anchor")
        text = text.replace(anchor, anchor + brec_sitemap, 1)
    return text


def expected_files() -> dict[Path, str]:
    expected: dict[Path, str] = {}
    expected[PUBLISHER] = normalize_publisher(PUBLISHER.read_text(encoding="utf-8"))

    style = SITE / "style.css"
    expected[style] = normalized_stylesheet(style.read_text(encoding="utf-8"))

    for source in ONBOARDING_SOURCES:
        expected[source] = normalize_onboarding_source(source.read_text(encoding="utf-8"))

    for path in sorted(SITE.rglob("*.html")):
        expected[path] = normalize_html(path, path.read_text(encoding="utf-8"))

    return expected


def apply() -> int:
    changed = 0
    for path, wanted in expected_files().items():
        current = path.read_text(encoding="utf-8")
        if current == wanted:
            continue
        path.write_text(wanted, encoding="utf-8")
        changed += 1
        print(path.relative_to(ROOT))
    print(f"site-consistency: normalized {changed} file(s)")
    return 0


def check() -> int:
    stale: list[Path] = []
    for path, wanted in expected_files().items():
        if path.read_text(encoding="utf-8") != wanted:
            stale.append(path)
    if stale:
        for path in stale:
            print(f"site-consistency: stale: {path.relative_to(ROOT)}", file=sys.stderr)
        print(
            "site-consistency: run scripts/site-consistency.py --apply and republish the site",
            file=sys.stderr,
        )
        return 1
    print("site-consistency: PASS")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true", help="normalize the repository in place")
    mode.add_argument("--check", action="store_true", help="fail if any site shell has drifted")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    return apply() if args.apply else check()


if __name__ == "__main__":
    raise SystemExit(main())
