"""Hunt seeds: one cursor per hunt. A new hunt never overwrites another.

The infinite hunt is the recurrence

    s_0 = start_factor
    W_i = (s_i, s_i + Δ]
    s_{i+1} = end of W_i

It does not stop on a letter. Letters are collected. The operator
stops the engine. Typing go again starts at s, never at 0.

Several hunts can run in one tree. Each has its own seed file.
Hunts that share a start factor share a lane and claim windows
so they do not scan the same interval. Hunts begun at different
start factors walk different stretches and do not touch each
other's cursors.

cleared_through is the last bound for which every Mordell-hard prime
has a certified witness. It lags scanned_through if an unsolved letter
was continued past.
"""

from __future__ import annotations

import json
import os
import re
import secrets
from datetime import datetime, timezone
from pathlib import Path

from .findings import findings_root
from .locks import FileLock

SEED_SCHEMA = 3
DEFAULT_STEP = 50_000
DEFAULT_KMAX = 400
DEFAULT_KMAX_CAP = 4_000
CLEARED_MILESTONE = 100_000
# Random starts live in [10^6, 10^10) so a new hunt is not always 0
# and is still inside a range the engine can walk.
RANDOM_START_LO = 1_000_000
RANDOM_START_HI = 10_000_000_000
MAIN_HUNT = "main"
_HUNT_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def seeds_dir() -> Path:
    d = findings_root() / "seeds"
    d.mkdir(parents=True, exist_ok=True)
    return d


def sanitize_hunt_id(hunt_id: str | None) -> str:
    name = (hunt_id or MAIN_HUNT).strip() or MAIN_HUNT
    if not _HUNT_RE.match(name):
        raise ValueError(f"invalid hunt id {hunt_id!r}")
    return name


def hunt_filename(hunt_id: str) -> str:
    return "current.json" if hunt_id == MAIN_HUNT else f"{hunt_id}.json"


def seed_path(hunt_id: str | None = None) -> Path:
    return seeds_dir() / hunt_filename(sanitize_hunt_id(hunt_id))


def seed_lock_path(hunt_id: str | None = None) -> Path:
    return seeds_dir() / f".{sanitize_hunt_id(hunt_id)}.lock"


def lane_id_for(start_factor: int) -> str:
    return f"lane-{int(start_factor)}"


def lane_path(lane: str) -> Path:
    return seeds_dir() / f".{lane}.json"


def lane_lock_path(lane: str) -> Path:
    return seeds_dir() / f".{lane}.lock"


def default_seed(hunt_id: str = MAIN_HUNT, start_factor: int = 0) -> dict:
    hunt_id = sanitize_hunt_id(hunt_id)
    start_factor = int(start_factor)
    return {
        "schema": SEED_SCHEMA,
        "hunt_id": hunt_id,
        "lane": lane_id_for(start_factor),
        "start_factor": start_factor,
        "cleared_through": start_factor,
        "scanned_through": start_factor,
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
        "pid": None,
    }


def _normalize(data: dict, hunt_id: str) -> dict:
    base = default_seed(hunt_id)
    base.update(data)
    base["hunt_id"] = hunt_id
    if "scanned_through" not in data:
        base["scanned_through"] = int(base.get("cleared_through") or 0)
    if "start_factor" not in data:
        base["start_factor"] = 0
    if not base.get("lane"):
        base["lane"] = lane_id_for(int(base.get("start_factor") or 0))
    if not isinstance(base.get("skipped_unsolved"), list):
        base["skipped_unsolved"] = []
    return base


def load_seed(hunt_id: str | None = None) -> dict:
    hunt_id = sanitize_hunt_id(hunt_id)
    path = seed_path(hunt_id)
    if not path.is_file():
        return default_seed(hunt_id)
    data = json.loads(path.read_text())
    return _normalize(data, hunt_id)


def hunt_exists(hunt_id: str | None = None) -> bool:
    return seed_path(hunt_id).is_file()


def list_hunts() -> list[dict]:
    seen: set[str] = set()
    names = ["current.json"]
    names.extend(
        sorted(
            p.name
            for p in seeds_dir().glob("*.json")
            if p.name != "current.json" and not p.name.startswith(".")
        )
    )
    out: list[dict] = []
    for name in names:
        path = seeds_dir() / name
        if not path.is_file():
            continue
        hunt_id = MAIN_HUNT if name == "current.json" else path.stem
        if hunt_id in seen:
            continue
        seen.add(hunt_id)
        seed = load_seed(hunt_id)
        probe = FileLock(seed_lock_path(hunt_id))
        free = probe.acquire(blocking=False)
        seed["_locked"] = not free
        if free:
            probe.release()
        out.append(seed)
    return out


def random_start_factor() -> int:
    span = RANDOM_START_HI - RANDOM_START_LO
    return RANDOM_START_LO + secrets.randbelow(span)


def save_seed(seed: dict) -> Path:
    hunt_id = sanitize_hunt_id(seed.get("hunt_id"))
    seed = dict(seed)
    seed["schema"] = SEED_SCHEMA
    seed["hunt_id"] = hunt_id
    if not seed.get("lane"):
        seed["lane"] = lane_id_for(int(seed.get("start_factor") or 0))
    seed["updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    path = seed_path(hunt_id)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(seed, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)
    return path


def initiate_hunt(*, start_factor: int, hunt_id: str | None = None) -> dict:
    """Open a hunt at start_factor without destroying any other hunt.

    If that hunt id already exists, resume it. Progress is kept.
    """
    start_factor = int(start_factor)
    if start_factor < 0:
        start_factor = 0
    if hunt_id is None:
        hunt_id = f"h-{start_factor}"
    hunt_id = sanitize_hunt_id(hunt_id)
    if hunt_exists(hunt_id):
        seed = load_seed(hunt_id)
        return seed
    seed = default_seed(hunt_id, start_factor)
    save_seed(seed)
    return seed


def join_lane(leader: dict) -> dict:
    """Create a sibling worker on the leader's lane. Does not touch the leader seed."""
    lane = str(leader.get("lane") or lane_id_for(int(leader.get("start_factor") or 0)))
    hunt_id = f"w-{os.getpid()}"
    lo, _hi, _step = peek_lane_next(lane, int(leader.get("step") or DEFAULT_STEP))
    seed = default_seed(hunt_id, int(leader.get("start_factor") or 0))
    seed["lane"] = lane
    seed["scanned_through"] = lo
    seed["cleared_through"] = int(leader.get("cleared_through") or 0)
    seed["kmax"] = int(leader.get("kmax") or DEFAULT_KMAX)
    seed["kmax_cap"] = int(leader.get("kmax_cap") or DEFAULT_KMAX_CAP)
    seed["step"] = int(leader.get("step") or DEFAULT_STEP)
    save_seed(seed)
    return seed


def reset_seed(hunt_id: str | None = None) -> dict:
    hunt_id = sanitize_hunt_id(hunt_id)
    seed = default_seed(hunt_id)
    save_seed(seed)
    return seed


def load_lane(lane: str) -> dict:
    path = lane_path(lane)
    if not path.is_file():
        return {"lane": lane, "next_lo": None}
    return json.loads(path.read_text())


def save_lane(state: dict) -> None:
    path = lane_path(str(state["lane"]))
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")
    tmp.replace(path)


def peek_lane_next(lane: str, step: int) -> tuple[int, int, int]:
    state = load_lane(lane)
    lo = state.get("next_lo")
    if lo is None:
        lo = 0
    lo = int(lo)
    return lo, lo + int(step), int(step)


def claim_window(seed: dict, step: int | None = None) -> tuple[int, int, int]:
    """Atomically take the next unclaimed window on this hunt's lane."""
    used = int(step if step is not None else seed.get("step") or DEFAULT_STEP)
    if used < 1:
        used = DEFAULT_STEP
    lane = str(seed.get("lane") or lane_id_for(int(seed.get("start_factor") or 0)))
    seed_lo = int(seed.get("scanned_through") or 0)
    with FileLock(lane_lock_path(lane)):
        state = load_lane(lane)
        nxt = state.get("next_lo")
        if nxt is None:
            lo = seed_lo
        else:
            lo = max(int(nxt), seed_lo)
        hi = lo + used
        state["lane"] = lane
        state["next_lo"] = hi
        state["last_hunt"] = seed.get("hunt_id")
        state["last_pid"] = os.getpid()
        save_lane(state)
    return lo, hi, used


def next_window(seed: dict, step: int | None = None) -> tuple[int, int, int]:
    """Return (lo, hi, step) for the next half-open interval (lo, hi].

    Prefer the lane claim so two processes on the same line do not
    overlap. Isolated tests without a lane file fall back to the seed.
    """
    used = int(step if step is not None else seed.get("step") or DEFAULT_STEP)
    if used < 1:
        used = DEFAULT_STEP
    lane = str(seed.get("lane") or lane_id_for(int(seed.get("start_factor") or 0)))
    if lane_path(lane).is_file():
        return peek_lane_next(lane, used)
    lo = int(seed.get("scanned_through") or 0)
    return lo, lo + used, used


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
    hid = seed.get("hunt_id") or MAIN_HUNT
    lines = [
        f"Hunt: {hid}",
        f"Seed file: {seed_path(str(hid))}",
        f"Lane: {seed.get('lane')}",
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


def format_roster() -> str:
    hunts = list_hunts()
    if not hunts:
        return "No hunts yet. Run:  ./centl es go"
    lines = ["Hunts in this tree (each has its own cursor):", ""]
    for seed in hunts:
        flag = "RUNNING" if seed.get("_locked") else "idle"
        lines.append(
            f"  {seed['hunt_id']:<20} {flag:<8}  "
            f"start={seed.get('start_factor')}  "
            f"scanned={seed.get('scanned_through')}  "
            f"cleared={seed.get('cleared_through')}"
        )
    lines.append("")
    lines.append("Resume one:  ./centl es go --hunt NAME")
    lines.append("Start another without touching these:  ./centl es go --from N")
    return "\n".join(lines)
