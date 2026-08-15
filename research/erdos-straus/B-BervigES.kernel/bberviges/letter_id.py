"""Deterministic letter numbers.

A letter number is not assigned by a machine, a clock, or a person.
It is the first 128 bits of SHA-256 of a fixed description of *what
was found*. Anyone who finds the same thing computes the same number.

That is possible. A worldwide serial number (#1, #2, #3 in discovery
order) is not: two hunters would need a shared counter. Content
addressing does not.

The start factor of a hunt is deliberately absent from the key.
Two people who begin at different places and later meet the same
prime write the same letter.
"""

from __future__ import annotations

import hashlib
import json

LETTER_DOMAIN = "ES-LETTER-v1"
FINDING_DOMAIN = "ES-FINDING-v1"

# Canonical rule names. Changing a string here would re-number every letter.
LETTER_RULES = (
    "unsolved_after_search",
    "window_broken",
    "universal_strike",
)


def _as_int(v, default: int = 0) -> int:
    try:
        return int(v)
    except (TypeError, ValueError):
        return default


def letter_rule(tags: list[str]) -> str | None:
    for rule in LETTER_RULES:
        if rule in tags:
            return rule
    return None


def letter_key(rule: str, n: int, extra: str = "") -> str:
    """Exact UTF-8 key. Do not add fields. Do not reorder."""
    return (
        f"{LETTER_DOMAIN}\n"
        f"rule={rule}\n"
        f"n={int(n)}\n"
        f"extra={extra}\n"
    )


def id_from_key(key: str) -> tuple[str, int]:
    digest = hashlib.sha256(key.encode("utf-8")).digest()
    raw = digest[:16]
    return raw.hex(), int.from_bytes(raw, "big")


def strike_extra(event: dict) -> str:
    """Certificate identity only. No clocks, hosts, or paths."""
    cert = event.get("certificate") or event.get("proof") or event.get("reason")
    if cert is None:
        return ""
    if isinstance(cert, (dict, list)):
        payload = json.dumps(cert, sort_keys=True, separators=(",", ":"))
    else:
        payload = str(cert)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def letter_id(event: dict, tags: list[str]) -> dict | None:
    rule = letter_rule(tags)
    if rule is None:
        return None
    n = _as_int(event.get("n") or event.get("p") or 0)
    extra = strike_extra(event) if rule == "universal_strike" else ""
    key = letter_key(rule, n, extra)
    hexid, number = id_from_key(key)
    return {
        "rule": rule,
        "n": n,
        "extra": extra,
        "key": key,
        "hex": hexid,
        "number": number,
        "display": f"L-{hexid}",
    }


def finding_id(grade: str, tags: list[str], event: dict) -> dict:
    """Stable id for any stamped finding. Letters use letter_id instead."""
    lid = letter_id(event, tags)
    if lid is not None:
        return lid
    n = _as_int(event.get("n") or event.get("p") or event.get("bound") or 0)
    rule = tags[0] if tags else grade
    key = f"{FINDING_DOMAIN}\ngrade={grade}\nrule={rule}\nn={n}\n"
    hexid, number = id_from_key(key)
    prefix = {"great": "G", "good": "O"}.get(grade, "F")
    return {
        "rule": rule,
        "n": n,
        "extra": "",
        "key": key,
        "hex": hexid,
        "number": number,
        "display": f"{prefix}-{hexid}",
    }
