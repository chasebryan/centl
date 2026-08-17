#!/usr/bin/env python3
"""Keep the public FCF site shell consistent across every HTML page.

This script owns cross-page presentation invariants that should not depend on
whether a page is handwritten or emitted by publish-site-library.py:

* one canonical Foundation / Research / Programs / Topics / External sidebar;
* one hierarchy treatment in the shared stylesheet;
* emoji-free mathematician and physicist onboarding manuals;
* a publisher that emits the same canonical sidebar;
* a curated research landing page that is not overwritten by the bulk-paper
  publisher; and
* a sitemap entry for the BREC program page.

Use --apply to normalize the tree. Use --check in CI to reject drift.
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
NAV_STYLE = r'''

/* Site-wide research navigation hierarchy. */
.research-nav-label {
  margin: 12px 0 5px;
  color: var(--muted);
  font: 700 11px/1.3 var(--ui);
  letter-spacing: .06em;
  text-transform: uppercase;
}
nav .research-subnav { margin-bottom: 10px; }
nav .research-subnav li { margin: 4px 0; }
nav .research-subnav.secondary {
  padding-left: 10px;
  border-left: 2px solid var(--rule);
}
nav a[aria-current="page"] { font-weight: 700; }

@media (max-width: 760px) {
  nav .research-nav-label { display: none; }
  nav .research-subnav.secondary {
    padding-left: 0;
    border-left: 0;
  }
}
'''


def nav_html(depth: int) -> str:
    p = "../" * depth
    return f'''<nav aria-label="Primary">
      <h2>Foundation</h2>
      <ul>
        <li><a href="{p}index.html">Home</a></li>
        <li><a href="{p}about.html">About FCF</a></li>
        <li><a href="{p}funding.html">Funding</a></li>
        <li><a href="{p}centl.html">CENTL</a></li>
        <li><a href="{p}software.html">Software</a></li>
        <li><a href="{p}mirrors.html">The Bazaar</a></li>
        <li><a href="{p}docs.html">Documentation</a></li>
      </ul>
      <h2>Research</h2>
      <ul class="research-subnav">
        <li><a href="{p}research.html">Manuals and research library</a></li>
      </ul>
      <p class="research-nav-label">Programs</p>
      <ul class="research-subnav secondary">
        <li><a href="{p}research-erdos-straus.html">Erdős–Straus</a></li>
        <li><a href="{p}bryan-recursive-entanglement-calculus.html">BREC</a></li>
      </ul>
      <p class="research-nav-label">Topics</p>
      <ul class="research-subnav secondary">
        <li><a href="{p}research.html#unit-fractions">Unit-fraction decomposition</a></li>
        <li><a href="{p}research.html#character-methods">Character methods</a></li>
        <li><a href="{p}research.html#shadowing">Shadowing and ancestry</a></li>
        <li><a href="{p}research.html#entanglement">Entanglement formalisms</a></li>
      </ul>
      <h2>External</h2>
      <ul>
        <li><a href="https://github.com/chasebryan/centl">CENTL on GitHub</a></li>
        <li><a href="https://github.com/chasebryan/centl/releases/tag/v0.15.0">Latest release</a></li>
        <li><a href="https://github.com/chasebryan/centl-cbx">CENTL-CBX on GitHub</a></li>
        <li><a href="https://github.com/chasebryan/Black-Calculus">Black Calculus on GitHub</a></li>
        <li><a href="https://github.com/sponsors/chasebryan">GitHub Sponsors</a></li>
      </ul>
    </nav>'''


def normalize_html(path: Path, text: str) -> str:
    rel = path.relative_to(SITE)
    depth = len(rel.parts) - 1
    replacement = nav_html(depth)
    normalized, count = re.subn(
        r'<nav aria-label="Primary">.*?</nav>',
        replacement,
        text,
        count=1,
        flags=re.S,
    )
    if count == 0 and "<div class=\"layout\">" in text:
        raise RuntimeError(f"site shell page has no primary nav: {rel}")
    return normalized


def normalize_onboarding_source(text: str) -> str:
    for symbol in ONBOARDING_EMOJI:
        text = text.replace(symbol, "")
    return text


def normalized_stylesheet(text: str) -> str:
    if NAV_STYLE_MARKER in text:
        return text
    return text.rstrip() + NAV_STYLE + "\n"


def publisher_nav_function() -> str:
    return '''def render_nav(depth: int) -> str:
    p = "../" * depth
    return f"""<nav aria-label="Primary">
      <h2>Foundation</h2>
      <ul>
        <li><a href="{p}index.html">Home</a></li>
        <li><a href="{p}about.html">About FCF</a></li>
        <li><a href="{p}funding.html">Funding</a></li>
        <li><a href="{p}centl.html">CENTL</a></li>
        <li><a href="{p}software.html">Software</a></li>
        <li><a href="{p}mirrors.html">The Bazaar</a></li>
        <li><a href="{p}docs.html">Documentation</a></li>
      </ul>
      <h2>Research</h2>
      <ul class="research-subnav">
        <li><a href="{p}research.html">Manuals and research library</a></li>
      </ul>
      <p class="research-nav-label">Programs</p>
      <ul class="research-subnav secondary">
        <li><a href="{p}research-erdos-straus.html">Erdős–Straus</a></li>
        <li><a href="{p}bryan-recursive-entanglement-calculus.html">BREC</a></li>
      </ul>
      <p class="research-nav-label">Topics</p>
      <ul class="research-subnav secondary">
        <li><a href="{p}research.html#unit-fractions">Unit-fraction decomposition</a></li>
        <li><a href="{p}research.html#character-methods">Character methods</a></li>
        <li><a href="{p}research.html#shadowing">Shadowing and ancestry</a></li>
        <li><a href="{p}research.html#entanglement">Entanglement formalisms</a></li>
      </ul>
      <h2>External</h2>
      <ul>
        <li><a href="https://github.com/chasebryan/centl">CENTL on GitHub</a></li>
        <li><a href="https://github.com/chasebryan/centl/releases/tag/v0.15.0">Latest release</a></li>
        <li><a href="https://github.com/chasebryan/centl-cbx">CENTL-CBX on GitHub</a></li>
        <li><a href="https://github.com/chasebryan/Black-Calculus">Black Calculus on GitHub</a></li>
        <li><a href="https://github.com/sponsors/chasebryan">GitHub Sponsors</a></li>
      </ul>
    </nav>"""'''


def curated_research_writer() -> str:
    return '''def write_research_index(papers: list[Record], manuals: list[Record], dest: Path) -> None:
    # The public research landing page is deliberately curated by subject.
    # The bulk publisher owns individual records, not the information
    # architecture of research.html. During --check, copy the canonical page
    # into the temporary publication tree so the check still covers it.
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

    publisher = PUBLISHER.read_text(encoding="utf-8")
    expected[PUBLISHER] = normalize_publisher(publisher)

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
