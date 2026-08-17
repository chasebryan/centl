#!/usr/bin/env python3
"""Normalize the sidebar navigation across all HTML files in the CENTL site.

Ensures 100% absolute consistency throughout the entire website hierarchy:
- root pages (site/*.html)
- manuals (site/manuals/*.html)
- library records (site/library/*.html)
"""

import os
import re
import sys
from pathlib import Path

SITE_DIR = Path(__file__).resolve().parent.parent / "site"

NAV_REGEX = re.compile(r'<nav aria-label="Primary">.*?</nav>', re.DOTALL)

def make_nav_html(rel: str) -> str:
    return f"""    <nav aria-label="Primary">
      <h2>CENTL &amp; Hub</h2>
      <ul>
        <li><a href="{rel}index.html">CENTL Work Area</a></li>
        <li><a href="{rel}centl.html">About CENTL</a></li>
        <li><a href="{rel}research-erdos-straus.html#es-hunt">Erdős–Straus Hunt</a></li>
        <li><a href="{rel}software.html">Software Suite</a></li>
      </ul>
      <h2>Documentation</h2>
      <ul>
        <li><a href="{rel}docs.html">Documentation Portal</a></li>
        <li><a href="{rel}manuals/install.html">Installation Guide</a></li>
        <li><a href="{rel}manuals/numerics.html">Numerical Contract</a></li>
        <li><a href="{rel}manuals/syntax.html">Syntax &amp; Functions</a></li>
        <li><a href="{rel}manuals/sci.html">CENTL-SCi &amp; Physics</a></li>
      </ul>
      <h2>Research</h2>
      <ul>
        <li><a href="{rel}research.html">Research Library</a></li>
        <li><a href="{rel}research-erdos-straus.html">Erdős–Straus Program</a></li>
        <li><a href="{rel}bryan-recursive-entanglement-calculus.html">BREC v1.0 Calculus</a></li>
      </ul>
      <h2>Foundation</h2>
      <ul>
        <li><a href="{rel}about.html">About FCF</a></li>
        <li><a href="{rel}funding.html">Funding &amp; Sponsors</a></li>
        <li><a href="{rel}mirrors.html">The Bazaar</a></li>
        <li><a href="https://github.com/chasebryan/centl">GitHub Repository</a></li>
      </ul>
    </nav>"""

def normalize_file(filepath: Path) -> bool:
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
        return False

    if "<nav aria-label=\"Primary\">" not in content and "<nav>" not in content:
        return False

    rel_to_site = filepath.parent.relative_to(SITE_DIR)
    depth = len(rel_to_site.parts)
    rel = "../" * depth

    new_nav = make_nav_html(rel)

    # Replace existing <nav ...> ... </nav>
    new_content, count = NAV_REGEX.subn(new_nav, content)
    if count == 0:
        # Fallback for generic <nav>
        generic_nav_regex = re.compile(r'<nav\b[^>]*>.*?</nav>', re.DOTALL)
        new_content, count = generic_nav_regex.subn(new_nav, content)

    if count > 0 and new_content != content:
        filepath.write_text(new_content, encoding="utf-8")
        return True
    return False

def main():
    if not SITE_DIR.exists():
        print(f"Site directory not found at {SITE_DIR}", file=sys.stderr)
        sys.exit(1)

    updated = 0
    total = 0
    for root, _, files in os.walk(SITE_DIR):
        for f in files:
            if f.endswith(".html"):
                total += 1
                path = Path(root) / f
                if normalize_file(path):
                    updated += 1

    print(f"Site Navigation Normalization complete: {updated}/{total} HTML files updated with normalized navigation.")

if __name__ == "__main__":
    main()
