#!/usr/bin/env python3
"""Publish FCF research papers and manuals as static HTML.

The public site is HTML and CSS only. This writer never emits executable
JavaScript. Typeahead on the library page uses a native <datalist>. Topic
and letter filters use CSS :has().
"""

from __future__ import annotations

import argparse
import html
import itertools
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "site"
ORIGIN = "https://freecomputation.org"
GITHUB = "https://github.com/chasebryan/centl/blob/main"
OASIS_GITHUB = "https://github.com/chasebryan/centl/blob/oasis"

SKIP_NAME = re.compile(
    r"(BACKUP|CHECKPOINT|CRASH-CHECKPOINT|FUTURE-OPERATOR|"
    r"OPERATOR-COORDINATION|^COORDINATION\.md$|ONE-SHOT-ES-ATTACK|"
    r"RESEARCH-BACKUP|RESEARCH-CHECKPOINT)",
    re.I,
)
SKIP_DIR_PARTS = {
    "operator-02",
    "B-BervigES.kernel",
    "BB.kernel",
    "__pycache__",
}

JOIN_VERSION = "1.0.8"
JOIN_BASE = (
    "https://github.com/chasebryan/centl/releases/download/"
    f"fcf-caravan-join-{JOIN_VERSION}"
)
JOIN_KEY_SHA256 = "450a55addaade128814788a02662a3f10230411f15d91d1060fa17543c288aa8"
JOIN_HELPER_SHA256 = "5fb7cf62bf9f01d4957ff3b2cbed9f6137cffd5cddf9392e7d4a2eecfeb54530"
JOIN_MISSIONS = ("source", "releases", "semantic", "recovery")
JOIN_TRANSPORTS = ("https", "tor")

MANUALS: list[tuple[str, str, str]] = [
    ("docs/INSTALL.md", "install", "Installation"),
    ("docs/NUMERICS.md", "numerics", "Numerical contract"),
    ("docs/SCI.md", "sci", "CENTL-SCi"),
    ("docs/SYNTAX.md", "syntax", "Syntax"),
    ("docs/MATHEMATICS.md", "mathematics", "Mathematics"),
    ("docs/PHYSICS.md", "physics", "Physics"),
    ("docs/VERIFICATION.md", "verification", "Verification"),
    ("docs/PROTOCOL.md", "protocol", "Machine protocol"),
    ("docs/MCP.md", "mcp", "MCP adapter"),
    ("docs/OASIS.md", "oasis", "Oasis"),
    ("docs/FCF-CAMPS.md", "camps", "FCF Camps"),
    ("docs/CENTL-MARSA.md", "marsa", "CENTL Marsa"),
    ("docs/RELEASE-POLICY.md", "release-policy", "Release policy"),
    ("docs/ONBOARDING.md", "onboarding", "Contributor onboarding"),
    ("docs/MATHEMATICIANS.md", "mathematicians", "Mathematician onboarding"),
    ("docs/PHYSICISTS.md", "physicists", "Physicist onboarding"),
    ("docs/FCF-WELLSPRING.md", "wellspring", "Wellspring designation"),
    ("docs/FCF-PROPOSAL.md", "proposal", "Company and AI proposal"),
    ("docs/REPOSITORY-MAP.md", "repository-map", "Repository map"),
    ("docs/DESIGN.md", "design", "Design"),
    ("docs/TOOLCHAIN.md", "toolchain", "Toolchain"),
    ("CONTRIBUTING.md", "contributing", "Contributing"),
    ("SECURITY.md", "security", "Security"),
    ("LICENSING.md", "licensing", "Licensing"),
    ("docs/releases/0.15.0.md", "release-0.15.0", "CENTL v0.15.0 Al-Nur"),
    ("docs/releases/0.14.0.md", "release-0.14.0", "CENTL v0.14.0 Al-Khayma"),
    ("docs/releases/camp-001.md", "camp-001", "FCF Camp #1"),
]

STATIC_SITEMAP = [
    ("https://freecomputation.org/", "weekly", "1.0"),
    ("https://freecomputation.org/about.html", "monthly", "0.8"),
    ("https://freecomputation.org/centl.html", "weekly", "0.9"),
    ("https://freecomputation.org/software.html", "weekly", "0.8"),
    ("https://freecomputation.org/docs.html", "weekly", "0.8"),
    ("https://freecomputation.org/research.html", "weekly", "0.9"),
    ("https://freecomputation.org/research-erdos-straus.html", "weekly", "0.8"),
    ("https://freecomputation.org/mirrors.html", "daily", "0.7"),
    ("https://freecomputation.org/funding.html", "monthly", "0.5"),
    ("https://freecomputation.org/join.html", "monthly", "0.6"),
    ("https://freecomputation.org/ai.html", "monthly", "0.8"),
    ("https://freecomputation.org/proposal.html", "monthly", "0.8"),
    ("https://freecomputation.org/pub/", "weekly", "0.5"),
    ("https://freecomputation.org/llms.txt", "monthly", "0.4"),
]


@dataclass
class Record:
    source: Path
    slug: str
    title: str
    summary: str
    topic: str
    kind: str
    letter: str
    github: str
    href: str
    suggestions: list[str] = field(default_factory=list)
    body_md: str = ""


def fail(message: str) -> None:
    print(f"publish-site-library: {message}", file=sys.stderr)
    raise SystemExit(2)


def shell_quote(value: str) -> str:
    return "'" + value.replace("'", "'\\''") + "'"


def first_heading(text: str) -> str | None:
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped[2:].strip()
    return None


def first_paragraph(text: str) -> str:
    chunks: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("#"):
            if chunks:
                break
            continue
        if line.startswith("![") or line.startswith("```") or line.startswith("|"):
            if chunks:
                break
            continue
        if line.startswith("**") and ":**" in line and not chunks:
            continue
        if line.startswith(">"):
            line = line.lstrip("> ").strip()
        if not line:
            if chunks:
                break
            continue
        chunks.append(re.sub(r"\s+", " ", line))
    summary = " ".join(chunks)
    summary = re.sub(r"[*_`]+", "", summary)
    summary = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", summary)
    if len(summary) > 240:
        summary = summary[:237].rsplit(" ", 1)[0] + "…"
    return summary


def letter_key(title: str) -> str:
    cleaned = re.sub(r"^(the|a|an)\s+", "", title.strip(), flags=re.I)
    for char in cleaned:
        if char.isalpha():
            return char.lower()
    return "z"


def classify_research(path: Path) -> str:
    name = path.name.upper()
    parts = {part.lower() for part in path.parts}
    if path.parts[-2] == "wellsprings" or name.startswith("WS-CAND"):
        return "wellspring"
    if "great" in parts or "letters" in parts or "good" in parts or path.parts[-2] in {"findings", "seeds"}:
        return "finding"
    if path.parts[-2] == "certificates" or "CERTIFICATE" in name or "CENSUS" in name:
        return "certificate"
    if name.startswith("CRYPTOLOGY"):
        return "cryptology"
    if any(key in name for key in ("PRIOR-ART", "MIZONY", "DYACHENKO", "PROVENANCE")):
        return "prior-art"
    if any(
        key in name
        for key in (
            "DIAMOND",
            "CURRENT-FRONTIER",
            "ERDOS-STRAUS-WALL",
            "ES-HUNT",
            "THEORY",
            "RESULTS",
            "README",
        )
    ):
        return "synthesis"
    if any(
        key in name
        for key in (
            "STRONG-ES",
            "FAB-",
            "TWO-P-PLUS",
            "FOUR-P-PLUS",
            "P-PLUS-FOUR",
            "HARD-Q",
            "HARD-SMOOTH",
            "Q11-TYPE",
            "K15-TWO",
        )
    ):
        return "corridor"
    if any(
        key in name
        for key in (
            "ANCESTRY",
            "QUOTIENT-",
            "ODD-PRIME-SHIFT",
            "PRIME-CHILD",
            "PRIME-DEPTH",
            "PRIME-MODULUS",
        )
    ):
        return "ancestry"
    if any(
        key in name
        for key in (
            "SQUARE-",
            "SQUAREFREE",
            "JACOBI",
            "RECIPROCITY",
            "QUADRATIC",
            "DYADIC",
            "MERSENNE",
            "MULTIPLICATIVE",
            "GENUS",
        )
    ):
        return "geometry"
    if any(
        key in name
        for key in (
            "SHADOW",
            "FIBER",
            "DIRECT-SHADOW",
            "DSC-",
            "TRAP-",
            "SINGLE-ACTIVE",
            "CLASS-C",
            "C1-",
            "C2-",
            "CN-",
        )
    ):
        return "shadow"
    return "theorem"


def topic_label(topic: str) -> str:
    return {
        "wellspring": "Wellspring",
        "synthesis": "Synthesis",
        "theorem": "Theorem",
        "certificate": "Certificate",
        "corridor": "Corridor",
        "ancestry": "Ancestry",
        "geometry": "Geometry",
        "shadow": "Shadow",
        "prior-art": "Prior art",
        "cryptology": "Cryptology",
        "finding": "Finding",
        "manual": "Manual",
    }[topic]


def slug_for(path: Path) -> str:
    if path.parts[-2:] == ("CC.kernel", "PROOF.md"):
        return "cc-kernel-proof"
    if path.parts[-2:] == ("CC.kernel", "README.md"):
        return "cc-kernel"
    if path.parts[-2:] == ("B-BervigES.kernel", "README.md"):
        return "bb-kernel"
    if path.parts[-2:] == ("seeds", "README.md"):
        return "hunt-seed"
    if path.name == "README.md" and path.parts[-2] == "erdos-straus":
        return "erdos-straus-harness"
    if path.parts[-2] == "great":
        return "finding-" + path.stem.lower().replace("_", "-")
    if path.parts[-2] == "letters":
        return "letter-" + path.stem.lower()
    if path.parts[-2] == "good":
        return "finding-" + path.stem.lower().replace("_", "-")
    return path.stem.lower().replace("_", "-")


def collect_research() -> list[Record]:
    records: list[Record] = []
    seen: set[str] = set()

    wellsprings = sorted((ROOT / "docs" / "wellsprings").glob("WS-CAND-*.md"))
    wellsprings += sorted((ROOT / "docs" / "wellsprings").glob("expedition-*.md"))
    roots = [
        *wellsprings,
        *sorted((ROOT / "research" / "erdos-straus").glob("*.md")),
        *sorted((ROOT / "research" / "erdos-straus" / "certificates").glob("*.md")),
        ROOT / "research" / "erdos-straus" / "CC.kernel" / "PROOF.md",
        ROOT / "research" / "erdos-straus" / "CC.kernel" / "README.md",
        ROOT / "research" / "erdos-straus" / "B-BervigES.kernel" / "README.md",
        ROOT / "research" / "erdos-straus" / "findings" / "seeds" / "README.md",
        *sorted((ROOT / "research" / "erdos-straus" / "findings").glob("*.md")),
        *sorted((ROOT / "research" / "erdos-straus" / "findings" / "great").glob("*.md")),
        *sorted((ROOT / "research" / "erdos-straus" / "findings" / "letters").glob("*.md")),
        *sorted((ROOT / "research" / "erdos-straus" / "findings" / "good").glob("*.md")),
    ]
    extra_ok = {
        ROOT / "research" / "erdos-straus" / "CC.kernel" / "PROOF.md",
        ROOT / "research" / "erdos-straus" / "CC.kernel" / "README.md",
        ROOT / "research" / "erdos-straus" / "B-BervigES.kernel" / "README.md",
        ROOT / "research" / "erdos-straus" / "findings" / "seeds" / "README.md",
    }
    for path in roots:
        if not path.is_file():
            continue
        if path not in extra_ok and any(part in SKIP_DIR_PARTS for part in path.parts):
            continue
        if SKIP_NAME.search(path.name):
            continue
        text = path.read_text(encoding="utf-8")
        slug = slug_for(path)
        if slug in seen:
            fail(f"duplicate slug {slug} from {path}")
        seen.add(slug)
        title = first_heading(text) or path.stem.replace("-", " ")
        topic = classify_research(path)
        rel = path.relative_to(ROOT).as_posix()
        suggestions = [title, path.stem.replace("-", " "), slug.replace("-", " ")]
        if slug.startswith("ws-cand"):
            suggestions.append(slug[:10].upper())
            suggestions.append("wellspring candidate")
        records.append(
            Record(
                source=path,
                slug=slug,
                title=title,
                summary=first_paragraph(text) or "FCF research record.",
                topic=topic,
                kind="paper",
                letter=letter_key(title),
                github=f"{GITHUB}/{rel}",
                href=f"library/{slug}.html",
                suggestions=suggestions,
                body_md=text,
            )
        )
    records.sort(key=lambda item: (item.title.lower(), item.slug))
    return records


def collect_manuals() -> list[Record]:
    records: list[Record] = []
    for rel, slug, fallback in MANUALS:
        path = ROOT / rel
        if not path.is_file():
            fail(f"missing manual {rel}")
        text = path.read_text(encoding="utf-8")
        title = first_heading(text) or fallback
        branch = OASIS_GITHUB if rel.startswith("docs/") and "FCF-CAMPS" not in rel and "wellspring" not in rel.lower() and "CAMP" not in rel and "MARSA" not in rel and "PROPOSAL" not in rel and "ONBOARDING" not in rel and "MATHEMATICIANS" not in rel and "PHYSICISTS" not in rel else GITHUB
        if rel in {"CONTRIBUTING.md", "SECURITY.md", "LICENSING.md"}:
            branch = OASIS_GITHUB
        records.append(
            Record(
                source=path,
                slug=slug,
                title=title,
                summary=first_paragraph(text) or fallback,
                topic="manual",
                kind="manual",
                letter=letter_key(title),
                github=f"{branch}/{rel}",
                href=f"manuals/{slug}.html",
                suggestions=[title, fallback, slug.replace("-", " ")],
                body_md=text,
            )
        )
    return records


def filename_catalog(papers: list[Record], manuals: list[Record]) -> dict[str, Record]:
    catalog: dict[str, Record] = {}
    for record in (*papers, *manuals):
        catalog[record.source.name] = record
        catalog[record.source.as_posix()] = record
        catalog[record.source.relative_to(ROOT).as_posix()] = record
    return catalog


_INLINE_CODE = re.compile(r"`([^`]+)`")
_LINK = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)|\[([^\]]+)\]\(([^)]+)\)")
_BOLD = re.compile(r"\*\*([^*]+)\*\*")
_ITALIC = re.compile(r"(?<!\*)\*([^*\n]+)\*(?!\*)")
_HEADING = re.compile(r"^(#{1,6})\s+(.*)$")


def rewrite_url(url: str, current: Record, catalog: dict[str, Record]) -> str:
    if url.startswith(("http://", "https://", "mailto:", "#")):
        return url
    path, frag = (url.split("#", 1) + [""])[:2]
    suffix = f"#{frag}" if frag else ""
    name = Path(path).name
    target = catalog.get(name)
    if target is None:
        try:
            resolved = (current.source.parent / path).resolve()
            rel = resolved.relative_to(ROOT).as_posix()
            target = catalog.get(rel)
        except (OSError, ValueError):
            target = None
    if target is None:
        try:
            resolved = (current.source.parent / path).resolve()
            rel = resolved.relative_to(ROOT).as_posix()
            return f"{GITHUB}/{rel}{suffix}"
        except (OSError, ValueError):
            return url
    if current.kind == target.kind:
        return f"{target.slug}.html{suffix}"
    if current.kind == "paper":
        return f"../{target.href}{suffix}"
    return f"../{target.href}{suffix}"


def apply_inline(text: str, current: Record, catalog: dict[str, Record]) -> str:
    parts: list[str] = []
    last = 0
    codes: list[str] = []

    def stash_code(match: re.Match[str]) -> str:
        codes.append(f"<code>{html.escape(match.group(1))}</code>")
        return f"\x00C{len(codes) - 1}\x00"

    working = _INLINE_CODE.sub(stash_code, text)

    def swap_link(match: re.Match[str]) -> str:
        if match.group(1) is not None:
            alt = html.escape(match.group(1))
            src = html.escape(rewrite_url(match.group(2), current, catalog), quote=True)
            return f'<img src="{src}" alt="{alt}">'
        label = apply_inline(match.group(3), current, catalog)
        href = html.escape(rewrite_url(match.group(4), current, catalog), quote=True)
        return f'<a href="{href}">{label}</a>'

    working = _LINK.sub(swap_link, working)
    working = html.escape(working)
    working = working.replace("&lt;a href=", "<a href=").replace("&lt;/a&gt;", "</a>")
    working = working.replace("&lt;img src=", "<img src=").replace("&gt;", ">")
    # The escape-then-restore above is fragile for mixed content. Re-do links
    # on the original string instead.
    return finish_inline(text, current, catalog)


def finish_inline(text: str, current: Record, catalog: dict[str, Record]) -> str:
    pieces: list[str] = []
    index = 0
    pattern = re.compile(
        r"`([^`]+)`|!?\[([^\]]*)\]\(([^)]+)\)|\*\*([^*]+)\*\*|(?<!\*)\*([^*\n]+)\*(?!\*)"
    )
    for match in pattern.finditer(text):
        pieces.append(html.escape(text[index : match.start()]))
        if match.group(1) is not None:
            pieces.append(f"<code>{html.escape(match.group(1))}</code>")
        elif match.group(0).startswith("!["):
            alt = html.escape(match.group(2))
            src = html.escape(rewrite_url(match.group(3), current, catalog), quote=True)
            pieces.append(f'<img src="{src}" alt="{alt}">')
        elif match.group(2) is not None and match.group(3) is not None and not match.group(0).startswith("!"):
            label = finish_inline(match.group(2), current, catalog)
            href = html.escape(rewrite_url(match.group(3), current, catalog), quote=True)
            pieces.append(f'<a href="{href}">{label}</a>')
        elif match.group(4) is not None:
            pieces.append(f"<strong>{finish_inline(match.group(4), current, catalog)}</strong>")
        else:
            pieces.append(f"<em>{finish_inline(match.group(5), current, catalog)}</em>")
        index = match.end()
    pieces.append(html.escape(text[index:]))
    return "".join(pieces)


def convert_display_math(text: str) -> str:
    def replace(match: re.Match[str]) -> str:
        body = html.escape(match.group(1).strip())
        return f'<div class="math" role="math">{body}</div>\n'
    return re.sub(r"\\\[(.*?)\\\]", replace, text, flags=re.S)


def md_to_html(text: str, current: Record, catalog: dict[str, Record]) -> str:
    text = convert_display_math(text)
    lines = text.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    i = 0
    skipped_title = False
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            lang = html.escape(line[3:].strip())
            fence: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                fence.append(lines[i])
                i += 1
            i += 1
            cls = f' class="language-{lang}"' if lang else ""
            out.append(f"<pre><code{cls}>{html.escape(chr(10).join(fence))}</code></pre>")
            continue
        if line.strip() == "---":
            out.append("<hr>")
            i += 1
            continue
        heading = _HEADING.match(line)
        if heading:
            level = min(len(heading.group(1)), 5)
            if not skipped_title and level == 1:
                skipped_title = True
                i += 1
                continue
            out.append(
                f"<h{level}>{finish_inline(heading.group(2).strip(), current, catalog)}</h{level}>"
            )
            i += 1
            continue
        if line.startswith("> "):
            quote: list[str] = []
            while i < len(lines) and lines[i].startswith(">"):
                quote.append(lines[i].lstrip("> ").rstrip())
                i += 1
            body = finish_inline(" ".join(part for part in quote if part), current, catalog)
            out.append(f"<blockquote><p>{body}</p></blockquote>")
            continue
        if line.startswith("|") and i + 1 < len(lines) and re.match(r"^\|?\s*:?-+:?", lines[i + 1]):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(lines[i])
                i += 1
            out.append(render_table(rows, current, catalog))
            continue
        if re.match(r"^[-*]\s+", line) or re.match(r"^\d+\.\s+", line):
            ordered = bool(re.match(r"^\d+\.\s+", line))
            items: list[str] = []
            while i < len(lines) and (
                re.match(r"^[-*]\s+", lines[i]) or re.match(r"^\d+\.\s+", lines[i])
            ):
                item = re.sub(r"^([-*]|\d+\.)\s+", "", lines[i])
                i += 1
                while i < len(lines) and re.match(r"^  +\S", lines[i]) and not _is_block_start(lines[i].lstrip()):
                    item += " " + lines[i].strip()
                    i += 1
                items.append(f"<li>{finish_inline(item, current, catalog)}</li>")
            tag = "ol" if ordered else "ul"
            out.append(f"<{tag}>{''.join(items)}</{tag}>")
            continue
        if not line.strip():
            i += 1
            continue
        if re.match(r"^\*\*[^*]+?\*\*", line.strip()):
            out.append(f"<p>{finish_inline(line.strip(), current, catalog)}</p>")
            i += 1
            continue
        para: list[str] = [line.strip()]
        i += 1
        while (
            i < len(lines)
            and lines[i].strip()
            and not _is_block_start(lines[i])
            and not re.match(r"^\*\*[^*]+?\*\*", lines[i].strip())
        ):
            para.append(lines[i].strip())
            i += 1
        joined = " ".join(para)
        if joined.startswith('<div class="math"'):
            out.append(joined)
        else:
            out.append(f"<p>{finish_inline(joined, current, catalog)}</p>")
    return "\n".join(out)


def _is_block_start(line: str) -> bool:
    return bool(
        line.startswith("```")
        or line.startswith("#")
        or line.startswith("> ")
        or line.startswith("|")
        or line.strip() == "---"
        or re.match(r"^[-*]\s+", line)
        or re.match(r"^\d+\.\s+", line)
        or line.startswith("\\[")
        or line.startswith('<div class="math"')
    )


def render_table(rows: list[str], current: Record, catalog: dict[str, Record]) -> str:
    def cells(row: str) -> list[str]:
        body = row.strip().strip("|")
        return [cell.strip() for cell in body.split("|")]

    header = cells(rows[0])
    body_rows = [cells(row) for row in rows[2:] if not re.match(r"^\s*\|?\s*:?-+:?", row)]
    thead = "".join(f"<th>{finish_inline(cell, current, catalog)}</th>" for cell in header)
    tbody = []
    for row in body_rows:
        padded = row + [""] * (len(header) - len(row))
        tbody.append(
            "<tr>"
            + "".join(f"<td>{finish_inline(cell, current, catalog)}</td>" for cell in padded[: len(header)])
            + "</tr>"
        )
    return (
        f'<table class="directory"><thead><tr>{thead}</tr></thead>'
        f"<tbody>{''.join(tbody)}</tbody></table>"
    )


def render_nav(depth: int) -> str:
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
      <ul>
        <li><a href="{p}research.html">Research library</a></li>
        <li><a href="{p}research-erdos-straus.html">Erdős–Straus program</a></li>
      </ul>
      <h2>External</h2>
      <ul>
        <li><a href="https://github.com/chasebryan/centl">CENTL on GitHub</a></li>
        <li><a href="https://github.com/chasebryan/centl/releases/tag/v0.15.0">Latest release</a></li>
        <li><a href="https://github.com/sponsors/chasebryan">GitHub Sponsors</a></li>
      </ul>
    </nav>"""


def wrap_page(
    *,
    title: str,
    description: str,
    canonical: str,
    depth: int,
    heading: str,
    dek: str,
    body: str,
    extra_head: str = "",
    footer: str = "Free Computation Foundation · Free for science. · HTML and CSS only.",
) -> str:
    prefix = "../" * depth
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{html.escape(description)}">
  <title>{html.escape(title)} — Free Computation Foundation</title>
  <link rel="canonical" href="{html.escape(canonical)}">
  <meta name="robots" content="index,follow">
  <link rel="alternate" type="text/plain" href="https://freecomputation.org/llms.txt" title="LLM briefing">
  <meta property="og:type" content="article">
  <meta property="og:url" content="{html.escape(canonical)}">
  <meta property="og:title" content="{html.escape(title)} — Free Computation Foundation">
  <meta property="og:description" content="{html.escape(description)}">
  <meta property="og:image" content="https://freecomputation.org/assets/fcf-centl-banner.png">
  <link rel="stylesheet" href="{prefix}style.css">
  {extra_head}
</head>
<body>
<div class="shell">
  <a class="skip" href="#content">Skip to content</a>
  <header class="masthead">
    <div class="brand"><a href="{prefix}index.html"><strong>FCF</strong><span>Free Computation Foundation</span><small>Free for science.</small></a></div>
    <div class="title"><h1>{html.escape(heading)}</h1><p>{html.escape(dek)}</p></div>
  </header>
  <div class="layout">
    {render_nav(depth)}
    <main id="content">
{body}
    </main>
  </div>
  <footer>{html.escape(footer)}</footer>
</div>
</body>
</html>
"""


def write_record(record: Record, catalog: dict[str, Record], dest: Path, depth: int) -> None:
    body_html = md_to_html(record.body_md, record, catalog)
    kicker = topic_label(record.topic)
    crumb_href = "../research.html" if record.kind == "paper" else "../docs.html"
    crumb_label = "Research library" if record.kind == "paper" else "Documentation"
    body = f"""      <p class="crumbs"><a href="{crumb_href}">{html.escape(crumb_label)}</a> · {html.escape(kicker)}</p>
      <article class="paper">
        <header class="paper-head">
          <p class="kicker">{html.escape(kicker)}</p>
          <p class="dek">{html.escape(record.summary)}</p>
          <p class="paper-meta"><a href="{html.escape(record.github)}">Source in the repository</a></p>
        </header>
        <div class="paper-body">
{body_html}
        </div>
      </article>"""
    dest.write_text(
        wrap_page(
            title=record.title,
            description=record.summary,
            canonical=f"{ORIGIN}/{record.href}",
            depth=depth,
            heading=record.title,
            dek=f"{kicker} · hosted from the CENTL repository",
            body=body,
            footer="Free Computation Foundation · Repository is canonical · Free for science.",
        ),
        encoding="utf-8",
    )


def datalist_options(records: list[Record]) -> str:
    seen: set[str] = set()
    options: list[str] = []
    for record in records:
        for suggestion in record.suggestions:
            label = re.sub(r"\s+", " ", suggestion).strip()
            if not label:
                continue
            key = label.casefold()
            if key in seen:
                continue
            seen.add(key)
            options.append(f'        <option value="{html.escape(label, quote=True)}"></option>')
    return "\n".join(options)


def render_cards(records: list[Record]) -> str:
    cards = []
    for record in records:
        cards.append(
            f"""        <article class="paper-card" id="{html.escape(record.slug)}" data-topic="{html.escape(record.topic)}" data-letter="{html.escape(record.letter)}">
          <p class="kicker"><span class="badge badge-{html.escape(record.topic)}">{html.escape(topic_label(record.topic))}</span></p>
          <h3><a href="{html.escape(record.href)}">{html.escape(record.title)}</a></h3>
          <p>{html.escape(record.summary)}</p>
          <p class="card-links"><a href="{html.escape(record.href)}">Read on this site</a> · <a href="{html.escape(record.github)}">Source</a></p>
        </article>"""
        )
    return "\n".join(cards)


def render_filter_radios(name: str, options: list[tuple[str, str]]) -> str:
    parts = []
    for index, (value, label) in enumerate(options):
        checked = " checked" if index == 0 else ""
        parts.append(
            f'      <input class="filter-input" type="radio" name="{name}" id="{name}-{value}" value="{value}"{checked}>'
        )
    labels = []
    for value, label in options:
        labels.append(f'        <label class="pill" for="{name}-{value}">{html.escape(label)}</label>')
    return "\n".join(parts) + "\n      <div class=\"pill-row\">\n" + "\n".join(labels) + "\n      </div>"


def write_folder_index(
    dest: Path,
    *,
    title: str,
    dek: str,
    intro: str,
    records: list[Record],
    depth: int,
    catalog_href: str,
    catalog_label: str,
) -> None:
    items = "\n".join(
        f'        <li><a href="{html.escape(record.slug)}.html">{html.escape(record.title)}</a></li>'
        for record in records
    )
    body = f"""      <p>{html.escape(intro)} <a href="{html.escape(catalog_href)}">{html.escape(catalog_label)}</a>.</p>
      <ul class="manual-index">
{items}
      </ul>"""
    dest.write_text(
        wrap_page(
            title=title,
            description=intro,
            canonical=f"{ORIGIN}/{dest.parent.name}/",
            depth=depth,
            heading=title,
            dek=dek,
            body=body,
        ),
        encoding="utf-8",
    )


def write_research_index(papers: list[Record], manuals: list[Record], dest: Path) -> None:
    topics = [
        ("all", "All topics"),
        ("wellspring", "Wellsprings"),
        ("synthesis", "Synthesis"),
        ("theorem", "Theorems"),
        ("certificate", "Certificates"),
        ("corridor", "Corridor"),
        ("ancestry", "Ancestry"),
        ("geometry", "Geometry"),
        ("shadow", "Shadow"),
        ("prior-art", "Prior art"),
        ("cryptology", "Cryptology"),
        ("finding", "Findings"),
    ]
    letters = [("all", "All")] + [(chr(code), chr(code).upper()) for code in range(ord("a"), ord("z") + 1)]
    suggestions = datalist_options(papers + manuals)
    suggest_links = "\n".join(
        f'          <li><a href="{html.escape(record.href)}">{html.escape(record.title)}</a></li>'
        for record in papers
    )
    body = f"""      <p class="notice"><strong>The library is hosted here.</strong> Every public research note below is readable on this site as HTML. The repository remains canonical. The Erdős–Straus conjecture remains open. Novelty and priority stay under review.</p>
      <p>There are {len(papers)} research records and {len(manuals)} hosted manuals. Type in the field to see native suggestions. Filters use ordinary CSS. No JavaScript is used.</p>

      <form class="library-search" role="search" action="https://html.duckduckgo.com/html/" method="get">
        <label for="library-q">Search papers and manuals</label>
        <div class="search-row">
          <input id="library-q" name="q" type="search" list="library-suggestions" placeholder="Type a title, theorem, author, or topic" autocomplete="off" spellcheck="false">
          <input type="hidden" name="sites" value="freecomputation.org">
          <button type="submit">Search</button>
        </div>
        <p class="small">Suggestions appear as you type. Choose one, then open the matching card. The button searches the published site.</p>
        <datalist id="library-suggestions">
{suggestions}
        </datalist>
        <div class="suggest-panel" aria-label="All hosted papers">
          <p class="kicker">Open a paper</p>
          <ul class="suggest-list">
{suggest_links}
          </ul>
        </div>
      </form>

      <div class="library" id="catalog">
{render_filter_radios("topic", topics)}
{render_filter_radios("letter", letters)}
        <div class="paper-grid">
{render_cards(papers)}
        </div>
        <p class="library-empty">No paper matches that filter. Choose another topic or letter, or <a href="#library-q">search by title</a>.</p>
      </div>

      <h2>Hosted manuals</h2>
      <p>Software manuals live in the <a href="docs.html">documentation index</a>. They are also hosted on this site:</p>
      <ul class="manual-index">
        {''.join(f'<li><a href="{html.escape(item.href)}">{html.escape(item.title)}</a></li>' for item in manuals)}
      </ul>"""
    dest.write_text(
        wrap_page(
            title="Research library",
            description="Hosted FCF research papers and Wellspring candidates, with no-JavaScript search suggestions.",
            canonical=f"{ORIGIN}/research.html",
            depth=0,
            heading="Research library",
            dek="Every public research record, readable here. Search as you type.",
            body=body,
            extra_head='<meta property="og:type" content="website">',
            footer="Free Computation Foundation · Research library · HTML and CSS only.",
        ),
        encoding="utf-8",
    )


def write_sitemap(papers: list[Record], manuals: list[Record], dest: Path) -> None:
    urls = list(STATIC_SITEMAP)
    for record in papers:
        urls.append((f"{ORIGIN}/{record.href}", "weekly", "0.6"))
    for record in manuals:
        urls.append((f"{ORIGIN}/{record.href}", "monthly", "0.5"))
    items = []
    for loc, freq, priority in urls:
        items.append(
            "  <url>\n"
            f"    <loc>{html.escape(loc)}</loc>\n"
            f"    <changefreq>{freq}</changefreq>\n"
            f"    <priority>{priority}</priority>\n"
            "  </url>"
        )
    dest.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "\n".join(items)
        + "\n</urlset>\n",
        encoding="utf-8",
    )


def launcher_script(missions: tuple[str, ...], transport: str) -> str:
    mission_csv = ",".join(missions)
    return "\n".join(
        [
            "#!/bin/sh",
            "set -eu",
            "",
            "# FCF CARAVAN launcher. Static HTML/CSS download after host-policy consent.",
            f"# FCF-approved provisions: {mission_csv}",
            f"# Coordinator route: {transport}",
            f"RELEASE_VERSION={shell_quote(JOIN_VERSION)}",
            f"MISSIONS={shell_quote(mission_csv)}",
            f"TRANSPORT={shell_quote(transport)}",
            f"ASSET_BASE={shell_quote(JOIN_BASE)}",
            f"EXPECTED_KEY_SHA256={shell_quote(JOIN_KEY_SHA256)}",
            "HELPER_ASSET='fcf-signify-x86_64-glibc'",
            f"EXPECTED_HELPER_SHA256='{JOIN_HELPER_SHA256}'",
            "fail() { printf '%s\\n' \"FCF CARAVAN launcher: $*\" >&2; exit 1; }",
            'for command in python3 sha256sum tar; do command -v "$command" >/dev/null 2>&1 || fail "$command is required for signed setup"; done',
            'work="$(mktemp -d "${TMPDIR:-/tmp}/fcf-caravan-join.XXXXXXXX")"',
            "cleanup() { rm -rf -- \"$work\"; }",
            "trap cleanup EXIT HUP INT TERM",
            'python3 - "$work" "$ASSET_BASE" "$RELEASE_VERSION" <<\'PY\'',
            "import sys",
            "from pathlib import Path",
            "from urllib.request import Request, urlopen",
            "",
            "work, base, version = sys.argv[1:]",
            "root = Path(work)",
            "names = (",
            '    f"fcf-caravan-join-{version}.tar.gz",',
            '    "FCF-CARAVAN-JOIN.pub",',
            '    "SHA256SUMS",',
            '    "SHA256SUMS.sig",',
            '    "fcf-signify-x86_64-glibc",',
            ")",
            "for name in names:",
            "    request = Request(",
            "        f\"{base.rstrip('/')}/{name}\",",
            "        headers={",
            '            "Accept": "application/octet-stream",',
            '            "User-Agent": f"FCF-CARAVAN-web-launcher/{version}",',
            "        },",
            "    )",
            "    output = root / name",
            "    total = 0",
            '    with urlopen(request, timeout=60) as response, output.open("wb") as stream:',
            "        while True:",
            "            chunk = response.read(1024 * 1024)",
            "            if not chunk:",
            "                break",
            "            total += len(chunk)",
            "            if total > 64 * 1024 * 1024:",
            '                raise SystemExit(f"download too large: {name}")',
            "            stream.write(chunk)",
            "PY",
            'actual_key_sha256="$(sha256sum "$work/FCF-CARAVAN-JOIN.pub" | awk \'{print $1}\')"',
            '[ "$actual_key_sha256" = "$EXPECTED_KEY_SHA256" ] || fail "the downloaded FCF trust key fingerprint is unexpected"',
            'signify_command="$(command -v signify 2>/dev/null || true)"',
            'if [ -z "$signify_command" ]; then',
            '  case "$(uname -m)" in',
            "    x86_64|amd64)",
            '      helper_sha256="$(sha256sum "$work/$HELPER_ASSET" | awk \'{print $1}\')"',
            '      [ "$helper_sha256" = "$EXPECTED_HELPER_SHA256" ] || fail "the FCF signify helper fingerprint is unexpected"',
            '      helper_dir="$HOME/.local/bin"',
            '      helper_target="$helper_dir/signify"',
            "      mkdir -p -m 0755 \"$helper_dir\"",
            '      if [ -e "$helper_target" ] || [ -L "$helper_target" ]; then',
            '        [ "$(sha256sum "$helper_target" | awk \'{print $1}\')" = "$EXPECTED_HELPER_SHA256" ] || fail "an unexpected user-local signify already exists"',
            "      else",
            '        cp "$work/$HELPER_ASSET" "$helper_target"',
            '        chmod 0755 "$helper_target"',
            "      fi",
            '      signify_command="$helper_target"',
            '      PATH="$helper_dir:$PATH"; export PATH',
            "      ;;",
            '    *) fail "signify is missing and this architecture has no FCF-hosted helper yet" ;;',
            "  esac",
            "fi",
            '"$signify_command" -V -q -p "$work/FCF-CARAVAN-JOIN.pub" -x "$work/SHA256SUMS.sig" -m "$work/SHA256SUMS" || fail "FCF release signature verification failed"',
            '(cd "$work" && sha256sum -c SHA256SUMS >/dev/null) || fail "FCF release checksum verification failed"',
            'tar -xzf "$work/fcf-caravan-join-$RELEASE_VERSION.tar.gz" -C "$work" || fail "signed FCF release could not be unpacked"',
            'signed_join="$work/fcf-caravan-join-$RELEASE_VERSION/join-caravan"',
            '[ -f "$signed_join" ] && [ ! -L "$signed_join" ] || fail "signed join launcher is missing"',
            '"$signed_join" --missions "$MISSIONS" --transport "$TRANSPORT"',
            "",
        ]
    )


def mission_key(missions: tuple[str, ...], transport: str) -> str:
    return "-".join(missions) + f"-{transport}"


def write_join_launchers(dest_dir: Path) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    for width in range(1, len(JOIN_MISSIONS) + 1):
        for combo in itertools.combinations(JOIN_MISSIONS, width):
            for transport in JOIN_TRANSPORTS:
                name = f"fcf-caravan-join-{JOIN_VERSION}-{mission_key(combo, transport)}.sh"
                path = dest_dir / name
                path.write_text(launcher_script(combo, transport), encoding="utf-8")
                path.chmod(0o644)


def write_join_filter_css(dest: Path) -> None:
    rules = [
        "/* Generated. Consent-gated launcher visibility. No JavaScript. */",
        ".caravan-join-action { display: none; }",
        ".launcher-card { display: none; }",
        ".need-mission { display: none; }",
        ".caravan-join-flow:has(.caravan-consent input:checked):not(:has(input[name=\"mission\"]:checked)) .need-mission { display: block; }",
    ]
    for width in range(1, len(JOIN_MISSIONS) + 1):
        for combo in itertools.combinations(JOIN_MISSIONS, width):
            for transport in JOIN_TRANSPORTS:
                key = mission_key(combo, transport)
                clauses = [".caravan-join-flow:has(.caravan-consent input:checked)"]
                for mission in JOIN_MISSIONS:
                    if mission in combo:
                        clauses.append(f":has(#m-{mission}:checked)")
                    else:
                        clauses.append(f":not(:has(#m-{mission}:checked))")
                clauses.append(f":has(#t-{transport}:checked)")
                prefix = "".join(clauses)
                rules.append(f'{prefix} .caravan-join-action[data-key="{key}"] {{ display: inline-block; }}')
                rules.append(f'{prefix} .launcher-card[data-key="{key}"] {{ display: block; }}')
    dest.write_text("\n".join(rules) + "\n", encoding="utf-8")


def reset_dir(path: Path) -> None:
    if path.exists():
        for child in path.iterdir():
            if child.is_file():
                child.unlink()
    path.mkdir(parents=True, exist_ok=True)


def publish(site_root: Path) -> dict[str, int]:
    papers = collect_research()
    manuals = collect_manuals()
    catalog = filename_catalog(papers, manuals)

    library = site_root / "library"
    manuals_dir = site_root / "manuals"
    reset_dir(library)
    reset_dir(manuals_dir)

    for record in papers:
        write_record(record, catalog, library / f"{record.slug}.html", 1)
    for record in manuals:
        write_record(record, catalog, manuals_dir / f"{record.slug}.html", 1)

    write_folder_index(
        library / "index.html",
        title="Hosted research papers",
        dek="Individual HTML copies of the public research records.",
        intro="This directory holds one HTML file per public research record. The searchable catalog is the research library.",
        records=papers,
        depth=1,
        catalog_href="../research.html",
        catalog_label="Research library",
    )
    write_folder_index(
        manuals_dir / "index.html",
        title="Hosted manuals",
        dek="Individual HTML copies of the front-facing CENTL manuals.",
        intro="This directory holds hosted manuals. Start at the documentation index if you want the reading order.",
        records=manuals,
        depth=1,
        catalog_href="../docs.html",
        catalog_label="Documentation",
    )

    write_research_index(papers, manuals, site_root / "research.html")
    write_sitemap(papers, manuals, site_root / "sitemap.xml")
    write_join_launchers(site_root / "pub" / "caravan" / "launchers")
    write_join_filter_css(site_root / "join-launchers.css")
    return {"papers": len(papers), "manuals": len(manuals)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="regenerate into a temporary tree and compare with site/",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.check:
        from tempfile import TemporaryDirectory

        with TemporaryDirectory() as tmp:
            temp = Path(tmp)
            publish(temp)
            for rel in (
                "research.html",
                "sitemap.xml",
                "join-launchers.css",
            ):
                left = (temp / rel).read_text(encoding="utf-8")
                right = (SITE / rel).read_text(encoding="utf-8")
                if left != right:
                    fail(f"{rel} is stale; run scripts/publish-site-library.py")
            for folder in ("library", "manuals", "pub/caravan/launchers"):
                generated = {p.name for p in (temp / folder).iterdir() if p.is_file()}
                committed = {p.name for p in (SITE / folder).iterdir() if p.is_file()}
                if generated != committed:
                    fail(f"{folder} membership is stale; run scripts/publish-site-library.py")
        print("publish-site-library: check passed")
        return 0
    counts = publish(SITE)
    print(
        f"publish-site-library: wrote {counts['papers']} papers and {counts['manuals']} manuals"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
