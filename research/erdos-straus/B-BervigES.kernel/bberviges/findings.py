"""Mechanical findings librarian.

Grades are exact predicates, not opinions. A finding is filed only after
4xyz = n(yz+xz+xy) holds, or the event is a hunt summary / unsolved alarm.
"""

from __future__ import annotations

import json
import os
import re
import time
from datetime import datetime, timezone
from pathlib import Path

from .arithmetic import HARD
from .letter_id import finding_id
from .locks import FileLock
from .witness import Witness, make_witness, verify_witness

ES_ROOT = Path(__file__).resolve().parents[2]
FINDINGS = ES_ROOT / "findings"

ROUTINE_METHODS = {
    "even",
    "3mod4",
    "2mod3",
    "5mod8",
    "4p+1",
    "p+4",
    "corridor[3]",
    "corridor[7]",
}

# Highest first. A finding keeps every matching tag; grade is the top match.
LETTER_RULES = (
    "unsolved_after_search",
    "window_broken",
    "universal_strike",
)
GREAT_RULES = (
    "escaped_small_theorems",
    "type_I_only",
    "deep_shift",
    "cleared_bound",
    "record_shift",
)
GOOD_RULES = (
    "certified_hard_witness",
    "new_method",
)

WHY = {
    "unsolved_after_search": (
        "A Mordell-hard prime survived every construction the engine knows. "
        "That is the most serious computational event possible. It is not yet "
        "a counterexample — the corridor may need a larger k — but it must "
        "not be ignored."
    ),
    "window_broken": (
        "The bounded pairs a,b ≤ 11, which have covered every tested prime "
        "in the published divisor-parametrization experiments, were not enough. "
        "If confirmed, this is a structural crack in that window."
    ),
    "universal_strike": (
        "The proof ledger claims a universal certificate. Treat this as a "
        "letter and read the certificate by hand before believing it."
    ),
    "escaped_small_theorems": (
        "The small proved shifts (k = 3, 7, 11, 15 and the p+4 / 4p+1 "
        "filters) all missed. A later construction still found a solution. "
        "That is the remaining shape of the conjecture: hard primes that "
        "escape the easy theorems."
    ),
    "type_I_only": (
        "Type II missed and Type I hit at the same shift. For many small "
        "shifts those two targets fail together. A Type-I-only rescue is "
        "exactly why original Erdős–Straus is weaker than the strong/Type-II "
        "conjecture."
    ),
    "deep_shift": (
        "The first two-target hit needed k ≥ 19. Deep first hits are the "
        "computational shadow of the fact that no universal constant bound "
        "on depth can exist."
    ),
    "cleared_bound": (
        "Every Mordell-hard prime below this bound received a certified "
        "witness. That is strong computational coverage, not a proof."
    ),
    "record_shift": (
        "This first-hit k is the largest the findings library has seen. "
        "Record depths are the primes a proof must eventually explain."
    ),
    "certified_hard_witness": (
        "An explicit Egyptian-fraction identity for a Mordell-hard prime, "
        "checked by the exact integer test 4xyz = n(yz+xz+xy)."
    ),
    "new_method": (
        "This construction has not appeared in the findings catalog before."
    ),
}


def _as_int(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return v


def findings_root() -> Path:
    override = os.environ.get("ES_FINDINGS")
    root = Path(override) if override else FINDINGS
    root.mkdir(parents=True, exist_ok=True)
    for name in ("good", "great", "letters"):
        (root / name).mkdir(exist_ok=True)
    return root


def catalog_path() -> Path:
    return findings_root() / "catalog.json"


def catalog_lock_path() -> Path:
    return findings_root() / ".catalog.lock"


def counts_path() -> Path:
    return findings_root() / "counts.json"


def catalog_jsonl_path() -> Path:
    return findings_root() / "catalog.jsonl"


def empty_catalog() -> dict:
    return {
        "records": {"max_shift_k": 0, "max_cleared_bound": 0},
        "methods": [],
        "items": [],
    }


def load_catalog(*, required: bool = False) -> dict:
    """Read catalog.json. Concurrent hunts can briefly see an empty file.

    required=True raises after retries (do not save over a good catalog).
    required=False returns an empty catalog for display-only callers.
    """
    path = catalog_path()
    last: Exception | None = None
    empty_hits = 0
    for attempt in range(12):
        try:
            if not path.is_file():
                return empty_catalog()
            if path.stat().st_size == 0:
                empty_hits += 1
                if not required and empty_hits >= 2:
                    return empty_catalog()
                time.sleep(0.03 * (attempt + 1))
                continue
            data = json.loads(path.read_text())
            if not isinstance(data, dict):
                raise json.JSONDecodeError("catalog is not an object", "", 0)
            data.setdefault("records", {"max_shift_k": 0, "max_cleared_bound": 0})
            data.setdefault("methods", [])
            data.setdefault("items", [])
            return data
        except (OSError, json.JSONDecodeError) as exc:
            last = exc
            time.sleep(0.03 * (attempt + 1))
    if required:
        raise RuntimeError(f"catalog.json unreadable after retries: {last}") from last
    return empty_catalog()


def save_catalog(cat: dict) -> None:
    path = catalog_path()
    tmp = path.with_name(f"catalog.json.tmp.{os.getpid()}.{time.time_ns()}")
    tmp.write_text(json.dumps(cat, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)


def default_stats() -> dict:
    return {
        "letter": 0,
        "great": 0,
        "good": 0,
        "max_shift_k": 0,
        "max_cleared_bound": 0,
        "methods": [],
        "since_rebuild": 0,
    }


def load_stats() -> dict:
    path = counts_path()
    if path.is_file() and path.stat().st_size:
        try:
            data = json.loads(path.read_text())
            base = default_stats()
            base.update(data)
            if not isinstance(base.get("methods"), list):
                base["methods"] = []
            return base
        except (OSError, json.JSONDecodeError):
            pass
    cat = load_catalog(required=False)
    stats = default_stats()
    for item in cat.get("items") or []:
        g = item.get("grade")
        if g in stats:
            stats[g] += 1
    recs = cat.get("records") or {}
    stats["max_shift_k"] = int(recs.get("max_shift_k") or 0)
    stats["max_cleared_bound"] = int(recs.get("max_cleared_bound") or 0)
    stats["methods"] = list(cat.get("methods") or [])
    return stats


def save_stats(stats: dict) -> None:
    path = counts_path()
    tmp = path.with_name(f"counts.json.tmp.{os.getpid()}.{time.time_ns()}")
    tmp.write_text(json.dumps(stats, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)


def is_hard(n: int) -> bool:
    return n > 5 and n % 840 in HARD


def tags_for_event(event: dict, cat: dict) -> list[str]:
    tags: list[str] = []
    kind = str(event.get("kind") or "")
    layer = str(event.get("layer") or "")
    method = str(event.get("method") or "")
    k = event.get("k")
    try:
        k_int = int(k) if k is not None else None
    except (TypeError, ValueError):
        k_int = None
    n = int(event.get("n") or event.get("p") or 0)
    solved = bool(event.get("solved", True))

    if event.get("type") == "cleared_bound":
        bound = int(event.get("bound") or 0)
        if bound >= 20_000 and int(event.get("unsolved") or 0) == 0:
            tags.append("cleared_bound")
        return tags

    if event.get("type") == "universal_strike":
        tags.append("universal_strike")
        return tags

    if is_hard(n) and not solved:
        tags.append("unsolved_after_search")
        return tags

    if not solved or n < 2:
        return tags

    if is_hard(n):
        if layer in {"window", "search"}:
            tags.append("escaped_small_theorems")
        if layer == "search":
            tags.append("window_broken")
        if kind == "I":
            tags.append("type_I_only")
        if k_int is not None and k_int >= 19:
            tags.append("deep_shift")
        if (
            k_int is not None
            and k_int >= 19
            and k_int > int(cat["records"].get("max_shift_k") or 0)
        ):
            tags.append("record_shift")
        if method not in ROUTINE_METHODS:
            tags.append("certified_hard_witness")
        if method and method not in cat.get("methods", []) and method not in ROUTINE_METHODS:
            tags.append("new_method")
    return tags


def grade_of(tags: list[str]) -> str | None:
    if any(t in LETTER_RULES for t in tags):
        return "letter"
    if any(t in GREAT_RULES for t in tags):
        return "great"
    if any(t in GOOD_RULES for t in tags):
        return "good"
    return None


def _slug(parts: list[str]) -> str:
    raw = "-".join(parts)
    slug = re.sub(r"[^a-zA-Z0-9._-]+", "-", raw).strip("-")
    return slug[:80] or "finding"


def write_finding(event: dict, tags: list[str], grade: str) -> Path:
    root = findings_root()
    folder = {"good": "good", "great": "great", "letter": "letters"}[grade]
    ident = finding_id(grade, tags, event)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = root / folder / f"{ident['display']}.md"
    title = {
        "letter": "LETTER",
        "great": "GREAT",
        "good": "GOOD",
    }[grade]
    why = "\n\n".join(WHY[t] for t in tags if t in WHY)
    eq = event.get("equation") or ""
    if not eq and event.get("x"):
        eq = f"4/{event.get('n') or event.get('p')} = 1/{event['x']} + 1/{event['y']} + 1/{event['z']}"
    number_block = ""
    if grade == "letter":
        number_block = (
            f"**Letter number:** {ident['number']}\n"
            f"**Letter id:** `{ident['display']}`\n"
            "This number is computed from the finding itself. Anyone who "
            "discovers the same letter on any machine gets the same number.\n"
        )
    body = f"""# {title} — {tags[0]}

**Grade:** {grade.upper()}
**Rules that fired:** {", ".join(tags)}
{number_block}**When first written here:** {stamp}

## What was found

```text
{eq or json.dumps(event, sort_keys=True)}
```

| field | value |
|---|---|
| n or p | {event.get("n") or event.get("p")} |
| letter number | {ident["number"] if grade == "letter" else "—"} |
| letter id | {ident["display"] if grade == "letter" else "—"} |
| layer | {event.get("layer")} |
| method | {event.get("method")} |
| kind | {event.get("kind")} |
| k | {event.get("k")} |
| bound | {event.get("bound")} |

## Why this was filed

{why}

## How to check

If there are three denominators x, y, z, confirm the integer identity

```text
4 · x · y · z  =  n · (y z + x z + x y)
```

with any exact calculator (including `centl es solve n`). Do not trust a
floating-point check. A hunt summary with unsolved = 0 is coverage of a
finite interval, not a proof of the conjecture.

## Claim boundary

Erdős–Straus remains open unless a LETTER file named `universal_strike`
points at a complete deposited proof.
"""
    path.write_text(body)
    side = path.with_suffix(".json")
    side.write_text(
        json.dumps(
            {
                "grade": grade,
                "tags": tags,
                "event": event,
                "file": path.name,
                "id": ident["display"],
                "number": ident["number"],
                "hex": ident["hex"],
            },
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )
    return path


def rebuild_index(cat: dict) -> None:
    root = findings_root()
    lines = [
        "# Findings index",
        "",
        "Read [`START-HERE.md`](START-HERE.md) first.",
        "",
        f"- letters: {sum(1 for i in cat['items'] if i['grade']=='letter')}",
        f"- great: {sum(1 for i in cat['items'] if i['grade']=='great')}",
        f"- good: {sum(1 for i in cat['items'] if i['grade']=='good')}",
        f"- record first-hit k: {cat['records'].get('max_shift_k', 0)}",
        f"- largest cleared bound: {cat['records'].get('max_cleared_bound', 0)}",
        "",
        "| grade | n | number | rules | file |",
        "|---|---:|---:|---|---|",
    ]
    for item in reversed(cat["items"][-200:]):
        num = item.get("number") if item.get("grade") == "letter" else ""
        lines.append(
            f"| {item['grade']} | {item.get('n','')} | {num} | "
            f"{', '.join(item['tags'])} | `{item['file']}` |"
        )
    index = root / "INDEX.md"
    tmp = root / f"INDEX.md.tmp.{os.getpid()}"
    tmp.write_text("\n".join(lines) + "\n")
    tmp.replace(index)


def file_event(event: dict) -> dict | None:
    """Verify if needed, grade, file. Do not rewrite catalog.json on every hit."""
    if event.get("x") is not None and event.get("solved", True):
        n = int(event.get("n") or event.get("p"))
        w = make_witness(
            n,
            int(event["x"]),
            int(event["y"]),
            int(event["z"]),
            layer=str(event.get("layer") or "filed"),
            method=str(event.get("method") or "filed"),
            kind=str(event.get("kind") or "filed"),
        )
        if not verify_witness(w):
            raise ValueError(f"refused to file an unverified witness for n={n}")
        event = dict(event)
        event["equation"] = w.equation()
        event["n"] = n
    with FileLock(catalog_lock_path()):
        stats = load_stats()
        cat_view = {
            "records": {
                "max_shift_k": stats.get("max_shift_k") or 0,
                "max_cleared_bound": stats.get("max_cleared_bound") or 0,
            },
            "methods": list(stats.get("methods") or []),
        }
        tags = tags_for_event(event, cat_view)
        grade = grade_of(tags)
        if grade is None:
            return None
        n = _as_int(event.get("n") or event.get("p") or event.get("bound"))
        ident = finding_id(grade, tags, event)
        folder = {"good": "good", "great": "great", "letter": "letters"}[grade]
        dest = findings_root() / folder / f"{ident['display']}.md"
        if dest.is_file():
            return None
        path = write_finding(event, tags, grade)
        rec = {
            "grade": grade,
            "tags": tags,
            "n": n,
            "file": str(path.relative_to(findings_root())),
            "method": event.get("method"),
            "id": ident["display"],
            "number": ident["number"],
            "hex": ident["hex"],
        }
        stats[grade] = int(stats.get(grade) or 0) + 1
        if event.get("method") and event["method"] not in stats["methods"]:
            stats["methods"].append(event["method"])
        k = event.get("k")
        try:
            k_int = int(k) if k is not None else None
        except (TypeError, ValueError):
            k_int = None
        if k_int is not None and k_int > int(stats.get("max_shift_k") or 0):
            stats["max_shift_k"] = k_int
        if event.get("type") == "cleared_bound":
            bound = int(event.get("bound") or 0)
            if bound > int(stats.get("max_cleared_bound") or 0):
                stats["max_cleared_bound"] = bound
        stats["since_rebuild"] = int(stats.get("since_rebuild") or 0) + 1
        save_stats(stats)
        with catalog_jsonl_path().open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(rec, sort_keys=True) + "\n")
        log = findings_root() / "log.jsonl"
        with log.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps({"grade": grade, "tags": tags, "event": event}) + "\n")
        if stats["since_rebuild"] >= 50 or grade == "letter":
            _rebuild_catalog_unlocked(stats)
            stats["since_rebuild"] = 0
            save_stats(stats)
        return rec


def _rebuild_catalog_unlocked(stats: dict) -> None:
    """Rebuild INDEX.md from the tiny stats file. Do not rewrite catalog.json here."""
    cat = {
        "records": {
            "max_shift_k": stats.get("max_shift_k") or 0,
            "max_cleared_bound": stats.get("max_cleared_bound") or 0,
        },
        "methods": list(stats.get("methods") or []),
        "items": _tail_jsonl(catalog_jsonl_path(), 200),
    }
    rebuild_index(cat)


def _tail_jsonl(path: Path, limit: int) -> list[dict]:
    if not path.is_file():
        return []
    try:
        raw = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    out: list[dict] = []
    for line in raw[-limit:]:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            out.append(obj)
    return out


def ingest_cc_blob(text: str) -> list[dict]:
    """Parse CC.kernel JSON (single object or residual wrapper) and file hits."""
    text = text.strip()
    if not text:
        return []
    filed: list[dict] = []
    try:
        obj = json.loads(text)
    except json.JSONDecodeError:
        # hunt prints one JSON object per line
        for line in text.splitlines():
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                piece = json.loads(line)
            except json.JSONDecodeError:
                continue
            filed.extend(ingest_obj(piece))
        return filed
    filed.extend(ingest_obj(obj))
    return filed


def ingest_obj(obj: dict) -> list[dict]:
    out: list[dict] = []
    if "hits" in obj and isinstance(obj["hits"], list):
        for hit in obj["hits"]:
            if isinstance(hit, dict):
                rec = file_event(hit)
                if rec:
                    out.append(rec)
        # A residual wrapper is a window, not a contiguous clear from 0.
        # The seed files cleared_bound when cleared_through hits a milestone.
        return out
    if obj.get("proof_status") == "proved" or obj.get("strike") is True:
        rec = file_event({"type": "universal_strike", **obj})
        if rec:
            out.append(rec)
        return out
    if obj.get("round") is not None and obj.get("unsolved") == 0 and obj.get("bound"):
        rec = file_event(
            {
                "type": "cleared_bound",
                "bound": obj.get("bound"),
                "unsolved": 0,
                "equation": f"hunt round {obj.get('round')} cleared bound {obj.get('bound')}",
            }
        )
        if rec:
            out.append(rec)
        return out
    rec = file_event(obj)
    if rec:
        out.append(rec)
    return out


def latest(grade: str | None = None, limit: int = 20) -> list[dict]:
    items = _tail_jsonl(catalog_jsonl_path(), max(limit * 8, 80))
    if not items:
        items = load_catalog(required=False).get("items") or []
    if grade:
        want = "letter" if grade in {"letter", "letters"} else grade
        items = [i for i in items if i.get("grade") == want]
    return list(reversed(items[-limit:]))
