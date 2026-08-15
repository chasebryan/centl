"""Live infinite hunt: collect letters, stop when the operator chooses."""

from __future__ import annotations

import json
import signal
import subprocess
import sys
from collections import deque

from .cc_bridge import cc_binary, solve_via_cc
from .findings import FINDINGS, file_event, latest, load_catalog
from .locks import FileLock
from .seed import (
    MAIN_HUNT,
    apply_window,
    claim_window,
    cleared_milestones,
    format_roster,
    format_seed,
    initiate_hunt,
    join_lane,
    load_seed,
    next_window,
    parse_start_factor,
    random_start_factor,
    reset_seed,
    save_seed,
    seed_lock_path,
    seed_path,
)


def _tty() -> bool:
    return sys.stdout.isatty()


def _counts() -> dict[str, int]:
    cat = load_catalog()
    out = {"letter": 0, "great": 0, "good": 0}
    for item in cat.get("items") or []:
        g = item.get("grade")
        if g in out:
            out[g] += 1
    return out


def draw_dashboard(state: dict) -> None:
    counts = _counts()
    seed = state["seed"]
    latest_lines = state.get("recent") or []
    width = 62
    bar = "─" * width
    status = "STOPPING" if state.get("halt") else "running"
    cur = state.get("current_p") or "—"
    lo, hi, _step = state.get("window") or (0, 0, 0)
    lines = [
        bar,
        f"  Erdős–Straus hunt {seed.get('hunt_id') or 'main':<12} {status:>8}",
        f"  start factor {seed.get('start_factor', 0)}",
        f"  now at {cur}     window ({lo}, {hi}]",
        f"  scanned {seed.get('scanned_through')}     "
        f"cleared {seed.get('cleared_through')}     kmax {seed.get('kmax')}",
        bar,
        f"  LETTERS  {counts['letter']:<6}  GREAT  {counts['great']:<6}  "
        f"GOOD  {counts['good']}",
        bar,
        "  latest",
    ]
    if not latest_lines:
        lines.append("    (nothing new in this sitting yet)")
    else:
        lines.extend(f"    {row}" for row in latest_lines)
    lines.append(bar)
    lines.append("  Ctrl+C  stop after this prime, save the seed, open the menu")
    text = "\n".join(lines) + "\n"
    if _tty():
        sys.stdout.write("\033[2J\033[H" + text)
    else:
        sys.stdout.write(text)
    sys.stdout.flush()


def _row(rec: dict) -> str:
    grade = str(rec.get("grade") or "?").upper()
    n = rec.get("n")
    tags = ", ".join(rec.get("tags") or [])
    num = rec.get("number")
    if rec.get("grade") == "letter" and num is not None:
        return f"{grade:6}  n={n}  #{num}  {tags}"
    return f"{grade:6}  n={n}  {tags}"


def deepen_unsolved(p: int, kmax: int, kmax_cap: int) -> dict | None:
    k = int(kmax)
    cap = int(kmax_cap or 4000)
    while k < cap:
        k = min(cap, k * 2)
        w = solve_via_cc(p, k_max=k, through="search")
        if w is None:
            continue
        return {
            "solved": True,
            "n": w.n,
            "p": w.n,
            "x": w.x,
            "y": w.y,
            "z": w.z,
            "layer": w.layer,
            "method": w.method,
            "kind": w.kind,
            "k": (w.detail or {}).get("k"),
        }
    return None


def _handle_hit(obj: dict, seed: dict, recent: deque) -> tuple[dict | None, bool]:
    still_unsolved = obj.get("solved") is False
    if still_unsolved:
        p = int(obj.get("p") or obj.get("n") or 0)
        rescued = deepen_unsolved(
            p, int(seed.get("kmax") or 400), int(seed.get("kmax_cap") or 4000)
        )
        if rescued is not None:
            obj = rescued
            still_unsolved = False
    rec = file_event(obj)
    if rec:
        recent.appendleft(_row(rec))
        while len(recent) > 6:
            recent.pop()
    return rec, still_unsolved


def run_window(seed: dict, lo: int, hi: int, state: dict) -> tuple[int, list, list]:
    """Stream one residual window. Returns (scanned_to, unsolved, letter_recs)."""
    binary = cc_binary()
    if binary is None:
        print("CC.kernel binary missing; run make -C CC.kernel", file=sys.stderr)
        return lo, [], []
    cmd = [
        str(binary),
        "residual",
        str(hi),
        "--from",
        str(lo),
        "--k-max",
        str(seed.get("kmax") or 400),
        "--stream",
    ]
    proc = subprocess.Popen(
        cmd,
        cwd=str(binary.parent),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,
    )
    state["proc"] = proc
    scanned_to = lo
    unsolved: list[int] = []
    letters: list[dict] = []
    recent: deque = state["recent"]
    assert proc.stdout is not None
    try:
        for raw in proc.stdout:
            if state.get("halt"):
                try:
                    proc.terminate()
                except OSError:
                    pass
                break
            line = raw.strip()
            if not line.startswith("{"):
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") == "window_done":
                if obj.get("complete"):
                    scanned_to = hi
                elif obj.get("stopped_on"):
                    scanned_to = int(obj["stopped_on"])
                continue
            p = obj.get("p") or obj.get("n")
            if p:
                scanned_to = int(p)
                state["current_p"] = scanned_to
                seed["scanned_through"] = scanned_to
            if obj.get("type") == "progress":
                draw_dashboard(state)
                continue
            rec, still_unsolved = _handle_hit(obj, seed, recent)
            if rec and rec.get("grade") == "letter":
                letters.append(rec)
            if still_unsolved:
                miss_n = int(obj.get("p") or obj.get("n") or 0)
                if miss_n:
                    unsolved.append(miss_n)
            draw_dashboard(state)
    finally:
        if proc.poll() is None:
            try:
                proc.terminate()
                proc.wait(timeout=2)
            except Exception:
                try:
                    proc.kill()
                except OSError:
                    pass
        state["proc"] = None
    return scanned_to, unsolved, letters


def cmd_go(
    *,
    step: int | None = None,
    kmax: int | None = None,
    once: bool = False,
    start_factor: int | None = None,
    random_start: bool = False,
    menu_after: bool = True,
    persist_step: bool = True,
    hunt_id: str | None = None,
) -> int:
    import os

    if random_start:
        start_factor = random_start_factor()
    if start_factor is not None:
        seed = initiate_hunt(start_factor=start_factor, hunt_id=hunt_id)
        print(
            f"Hunt {seed['hunt_id']} at start factor {seed['start_factor']}. "
            f"Other hunts were left alone."
        )
    elif hunt_id:
        seed = load_seed(hunt_id)
    else:
        seed = load_seed(MAIN_HUNT)

    if kmax is not None:
        seed["kmax"] = int(kmax)
    if persist_step and step is not None and step > 0:
        seed["step"] = int(step)
    if cc_binary() is None:
        print("CC.kernel binary missing; run make -C research/erdos-straus/CC.kernel")
        return 2

    lock = FileLock(seed_lock_path(str(seed.get("hunt_id") or MAIN_HUNT)))
    if not lock.acquire(blocking=False):
        print(
            f"Hunt {seed.get('hunt_id')} is already running. "
            "Starting a sibling on the same lane; the first hunt is unchanged."
        )
        seed = join_lane(seed)
        lock = FileLock(seed_lock_path(str(seed["hunt_id"])))
        if not lock.acquire(blocking=False):
            print("Could not lock the sibling hunt. Try --from N for a new stretch.")
            return 2
        print(f"Sibling hunt {seed['hunt_id']} will take the next free windows.")
    lock.record_pid(os.getpid())

    halt = False

    def _stop(_signum, _frame) -> None:
        nonlocal halt
        halt = True
        state["halt"] = True
        proc = state.get("proc")
        if proc is not None and proc.poll() is None:
            try:
                proc.terminate()
            except OSError:
                pass

    used_step = int(step if step is not None else seed.get("step") or 50_000)
    first = claim_window(seed, used_step)
    state = {
        "seed": seed,
        "halt": False,
        "current_p": seed.get("scanned_through"),
        "window": first,
        "recent": deque(maxlen=6),
        "proc": None,
    }

    prev_int = signal.signal(signal.SIGINT, _stop)
    prev_term = signal.signal(signal.SIGTERM, _stop)
    seed["status"] = "running"
    seed["pid"] = os.getpid()
    save_seed(seed)
    draw_dashboard(state)

    try:
        lo, hi, used = first
        while not halt and not state["halt"]:
            state["window"] = (lo, hi, used)
            old_cleared = int(seed.get("cleared_through") or 0)
            scanned_to, unsolved, letters = run_window(seed, lo, hi, state)
            action = apply_window(
                seed,
                scanned_to=scanned_to,
                unsolved=unsolved,
                letter_recs=letters,
                once=once,
            )
            if not (seed.get("skipped_unsolved")):
                for bound in cleared_milestones(old_cleared, int(seed.get("cleared_through") or 0)):
                    rec = file_event(
                        {
                            "type": "cleared_bound",
                            "bound": bound,
                            "unsolved": 0,
                            "equation": f"cleared hard primes through {bound}",
                        }
                    )
                    if rec:
                        state["recent"].appendleft(_row(rec))
            save_seed(seed)
            state["seed"] = seed
            draw_dashboard(state)
            if action == "once" or once:
                break
            if state["halt"] or halt:
                break
            lo, hi, used = claim_window(seed, step)
    finally:
        seed["status"] = "idle"
        seed["pid"] = None
        save_seed(seed)
        lock.release()
        signal.signal(signal.SIGINT, prev_int)
        signal.signal(signal.SIGTERM, prev_term)

    print()
    print(f"Saved seed at {seed.get('scanned_through')}. File: {seed_path()}")
    if seed.get("letters_found"):
        print(f"Letters collected on this hunt: {seed['letters_found']}")
    if menu_after and _tty() and sys.stdin.isatty():
        return cmd_menu()
    return 0


def print_look(grade: str | None = None) -> int:
    items = latest(grade=grade, limit=30)
    print(f"Findings live in: {FINDINGS}")
    print("Read START-HERE.md if this is your first time.\n")
    if not items:
        print("Nothing filed yet. Run:  ./centl es go")
        return 0
    for rec in items:
        extra = ""
        if rec.get("grade") == "letter" and rec.get("number") is not None:
            extra = f"  #{rec['number']}"
        print(
            f"[{str(rec['grade']).upper():6}]  n={rec.get('n')}{extra}  "
            f"{', '.join(rec.get('tags') or [])}\n         {rec.get('file')}"
        )
    return 0


def cmd_hunts() -> int:
    print(format_roster())
    return 0


def cmd_seed(action: str | None = None, hunt_id: str | None = None) -> int:
    if action == "reset":
        reset_seed(hunt_id)
        print(f"Hunt {hunt_id or MAIN_HUNT} reset to start factor 0.")
        print("Other hunts were not touched.")
    if action == "list" or action is None:
        print(format_roster())
        print()
    print(format_seed(load_seed(hunt_id)))
    return 0


def cmd_menu() -> int:
    seed = load_seed()
    print()
    print("Erdős–Straus")
    print()
    print(f"  start factor {seed.get('start_factor', 0)}")
    print(f"  scanned through {seed.get('scanned_through')}")
    print(f"  letters in the library: {_counts()['letter']}")
    print()
    print("  [g] go        continue this hunt (infinite; Ctrl+C to stop)")
    print("  [0] from 0    another hunt beginning at the origin")
    print("  [n] from N    another hunt at any number you type (0 is allowed)")
    print("  [r] random    another hunt at a random place")
    print("  [h] hunts     list every hunt cursor")
    print("  or type a number directly (0, 1000, 2e9, 20_000_000_000)")
    print("  [l] letters   collected letters, with numbers")
    print("  [k] look      latest findings")
    print("  [s] seed      show the cursor")
    print("  [q] quit")
    print()
    try:
        choice = input("  ? ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        print()
        return 0
    if choice in {"g", "go", ""}:
        return cmd_go(menu_after=True)
    if choice in {"0", "origin", "from0", "from 0"}:
        return cmd_go(start_factor=0, menu_after=True)
    if choice in {"n", "from", "from n", "number"}:
        try:
            raw = input("  start at (any integer; 0 is allowed)? ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        try:
            return cmd_go(start_factor=parse_start_factor(raw), menu_after=True)
        except ValueError as exc:
            print(f"  {exc}")
            return cmd_menu()
    try:
        return cmd_go(start_factor=parse_start_factor(choice), menu_after=True)
    except ValueError:
        pass
    if choice in {"r", "random"}:
        return cmd_go(random_start=True, menu_after=True)
    if choice in {"h", "hunts"}:
        cmd_hunts()
        return cmd_menu()
    if choice in {"l", "letters"}:
        print_look(grade="letter")
        return cmd_menu()
    if choice in {"k", "look"}:
        print_look()
        return cmd_menu()
    if choice in {"s", "seed"}:
        cmd_seed()
        return cmd_menu()
    return 0
