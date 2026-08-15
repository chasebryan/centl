"""Hunt seed: a resume cursor, not a PRNG.

The infinite hunt is the recurrence

    s_0 = start_factor
    W_i = (s_i, s_i + Δ]
    s_{i+1} = end of W_i

It does not stop on a letter. Letters are collected. The operator
stops the engine. Typing go again starts at s, never at 0.

start_factor is chosen when a hunt is initiated (0, a given bound,
or a random integer). It is stored so this hunt is the same hunt
tomorrow. It is not part of a letter's identity.

cleared_through is the last bound for which every Mordell-hard prime
has a certified witness. It lags scanned_through if an unsolved letter
was continued past.
"""

from __future__ import annotations

import json
import secrets
from datetime import datetime, timezone
from pathlib import Path

from .findings import findings_root

SEED_SCHEMA = 2
DEFAULT_STEP = 50_000
DEFAULT_KMAX = 400
DEFAULT_KMAX_CAP = 4_000
CLEARED_MILESTONE = 100_000
# Random starts live in [10^6, 10^10) so a new hunt is not always 0
# and is still inside a range the engine can walk.
RANDOM_START_LO = 1_000_000
RANDOM_START_HI = 10_000_000_000


def seed_path() -> Path:
    d = findings_root() / "seeds"
    d.mkdir(parents=True, exist_ok=True)
    return d / "current.json"


def default_seed() -> dict:
    return {
        "schema": SEED_SCHEMA,
        "start_factor": 0,
        "cleared_through": 0,
        "scanned_through": 0,
        "kmax": DEFAULT_KMAX,
        "kmax_cap": DEFAULT_KMAX_CAP,
        "step": DEFAULT_STEP,
        "status": "idle",
        "letter_n": None,
        "letter_file": None,
        "letter_kind": None,
        "letter_number": None,
        "letters_found": 0,
        "skipped_unsolved": [],
        "windows_done": 0,
        "updated": None,
    }


def load_seed() -> dict:
    path = seed_path()
    base = default_seed()
    if not path.is_file():
        return base
    data = json.loads(path.read_text())
    base.update(data)
    if "scanned_through" not in data:
        base["scanned_through"] = int(base.get("cleared_through") or 0)
    if "start_factor" not in data:
        base["start_factor"] = 0
    if not isinstance(base.get("skipped_unsolved"), list):
        base["skipped_unsolved"] = []
    return base


def random_start_factor() -> int:
    span = RANDOM_START_HI - RANDOM_START_LO
    return RANDOM_START_LO + secrets.randbelow(span)


def initiate_hunt(*, start_factor: int) -> dict:
    """Begin a hunt at start_factor. Replaces the current seed."""
    seed = default_seed()
    start_factor = int(start_factor)
    if start_factor < 0:
        start_factor = 0
    seed["start_factor"] = start_factor
    seed["scanned_through"] = start_factor
    seed["cleared_through"] = start_factor
    save_seed(seed)
    return seed


def save_seed(seed: dict) -> Path:
    seed = dict(seed)
    seed["schema"] = SEED_SCHEMA
    seed["updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    path = seed_path()
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(seed, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)
    return path


def reset_seed() -> dict:
    seed = default_seed()
    save_seed(seed)
    return seed


def next_window(seed: dict, step: int | None = None) -> tuple[int, int, int]:
    """Return (lo, hi, step) for the next half-open interval (lo, hi]."""
    used = int(step if step is not None else seed.get("step") or DEFAULT_STEP)
    if used < 1:
        used = DEFAULT_STEP
    lo = int(seed.get("scanned_through") or 0)
    hi = lo + used
    return lo, hi, used


def cleared_milestones(old: int, new: int) -> list[int]:
    """100000, 200000, ... newly reached by a contiguous clear."""
    if new < CLEARED_MILESTONE:
        return []
    start = (int(old) // CLEARED_MILESTONE + 1) * CLEARED_MILESTONE
    if start < CLEARED_MILESTONE:
        start = CLEARED_MILESTONE
    out: list[int] = []
    b = start
    while b <= int(new):
        out.append(b)
        b += CLEARED_MILESTONE
    return out


def apply_window(
    seed: dict,
    *,
    scanned_to: int,
    unsolved: list[int],
    letter_recs: list[dict],
    once: bool = False,
) -> str:
    """Update the seed after a window. Letters are collected, not a stop.

    Returns 'continue' or 'once'. scanned_to is the last integer looked at.
    """
    seed["scanned_through"] = int(scanned_to)
    skipped = [int(p) for p in (seed.get("skipped_unsolved") or [])]
    if unsolved:
        for p in unsolved:
            ip = int(p)
            if ip not in skipped:
                skipped.append(ip)
        seed["skipped_unsolved"] = skipped
    else:
        seed["skipped_unsolved"] = skipped
        if not skipped:
            seed["cleared_through"] = int(scanned_to)
    seed["windows_done"] = int(seed.get("windows_done") or 0) + 1
    if letter_recs:
        rec = letter_recs[-1]
        tags = rec.get("tags") or []
        seed["letter_file"] = rec.get("file")
        seed["letter_n"] = rec.get("n")
        seed["letter_kind"] = tags[0] if tags else "letter"
        seed["letter_number"] = rec.get("number")
        seed["letters_found"] = int(seed.get("letters_found") or 0) + len(letter_recs)
    seed["status"] = "idle" if once else "running"
    return "once" if once else "continue"


def format_seed(seed: dict) -> str:
    lo, hi, step = next_window(seed)
    lines = [
        f"Seed file: {seed_path()}",
        f"Status: {seed.get('status')}",
        f"Start factor: {seed.get('start_factor', 0)}",
        f"Scanned through: {seed.get('scanned_through')}",
        f"Cleared through: {seed.get('cleared_through')}"
        "  (every hard prime at or below this has a checked witness)",
        f"Next window: ({lo}, {hi}]   step={step}   kmax={seed.get('kmax')}",
        f"Windows done: {seed.get('windows_done')}",
        f"Letters collected on this hunt: {seed.get('letters_found') or 0}",
    ]
    skipped = seed.get("skipped_unsolved") or []
    if skipped:
        lines.append(f"Unsolved primes continued past: {skipped}")
        lines.append("cleared_through will not advance past those primes.")
    if seed.get("letter_n"):
        lines.append(
            f"Last letter: n={seed.get('letter_n')}  "
            f"number={seed.get('letter_number')}  ({seed.get('letter_kind')})"
        )
        if seed.get("letter_file"):
            lines.append(f"Read: {findings_root() / seed['letter_file']}")
    return "\n".join(lines)
