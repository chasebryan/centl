#!/usr/bin/env python3
"""Seed equation and letter-number identity checks."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import os
import tempfile

from bberviges.letter_id import id_from_key, letter_id, letter_key
from bberviges.seed import (
    apply_window,
    claim_window,
    default_seed,
    initiate_hunt,
    load_seed,
    next_window,
    parse_start_factor,
    random_start_factor,
    save_seed,
)


def check(cond, msg):
    if not cond:
        raise SystemExit(msg)


def main() -> None:
    tmp = tempfile.TemporaryDirectory()
    os.environ["ES_FINDINGS"] = tmp.name
    seed = default_seed()
    lo, hi, step = next_window(seed)
    check(lo == 0 and hi == 50_000 and step == 50_000, f"first window {lo,hi,step}")

    action = apply_window(seed, scanned_to=50_000, unsolved=[], letter_recs=[], once=False)
    check(action == "continue", action)
    check(seed["scanned_through"] == 50_000, seed)
    check(seed["cleared_through"] == 50_000, seed)

    letter = {
        "grade": "letter",
        "n": 99991,
        "tags": ["unsolved_after_search"],
        "file": "letters/demo.md",
        "number": 123,
    }
    action = apply_window(
        seed, scanned_to=52_000, unsolved=[99991], letter_recs=[letter], once=False
    )
    check(action == "continue", "letters must not stop the hunt")
    check(seed["scanned_through"] == 52_000, seed)
    check(seed["cleared_through"] == 50_000, "must not claim a clear past an unsolved")
    check(99991 in seed["skipped_unsolved"], seed)
    check(seed["letters_found"] == 1, seed)

    lo, hi, _ = next_window(seed)
    check(lo == 52_000, f"resume must continue from 52000, got {lo}")

    a = letter_id({"n": 2521, "solved": False}, ["unsolved_after_search"])
    b = letter_id({"p": 2521, "solved": False}, ["unsolved_after_search"])
    check(a is not None and b is not None, "letter id")
    check(a["number"] == b["number"], "same letter must have the same number")
    check(a["hex"] == b["hex"], "same letter must have the same hex id")
    check(a["display"].startswith("L-"), a)

    other = letter_id({"n": 2522, "solved": False}, ["unsolved_after_search"])
    check(other is not None and other["number"] != a["number"], "different n, different number")

    broken = letter_id(
        {"n": 2521, "solved": True, "layer": "search"},
        ["window_broken", "escaped_small_theorems"],
    )
    check(broken is not None and broken["number"] != a["number"], "different rule, different number")

    key = letter_key("unsolved_after_search", 2521, "")
    hexid, number = id_from_key(key)
    check(hexid == a["hex"] and number == a["number"], "id_from_key mismatch")
    check("start" not in key and "host" not in key and "time" not in key, key)

    check(parse_start_factor("0") == 0, "zero")
    check(parse_start_factor("origin") == 0, "origin word")
    check(parse_start_factor("1000") == 1000, "plain")
    check(parse_start_factor("1_000_000") == 1_000_000, "underscores")
    check(parse_start_factor("1,000,000") == 1_000_000, "commas")
    check(parse_start_factor("2e9") == 2_000_000_000, "scientific")
    check(parse_start_factor("20_000_000_000") == 20_000_000_000, "big")
    check(parse_start_factor("-3") == 0, "negative clamps to 0")

    r1 = random_start_factor()
    r2 = random_start_factor()
    check(1_000_000 <= r1 < 10_000_000_000, r1)
    check(r1 != r2 or r1 != 0, "random start should vary")

    with tempfile.TemporaryDirectory() as isolated:
        os.environ["ES_FINDINGS"] = isolated
        first = default_seed("main", 1_000_000)
        save_seed(first)
        first["scanned_through"] = 1_050_000
        save_seed(first)
        origin = initiate_hunt(start_factor=0)
        check(origin["hunt_id"] == "h-0", origin)
        check(origin["start_factor"] == 0, origin)
        check(origin["scanned_through"] == 0, origin)
        second = initiate_hunt(start_factor=9_000_000_000)
        check(second["hunt_id"] == "h-9000000000", second)
        check(second["start_factor"] == 9_000_000_000, second)
        main = load_seed("main")
        check(main["scanned_through"] == 1_050_000, "second hunt must not destroy the first")
        check(main["start_factor"] == 1_000_000, main)
        check(load_seed("h-0")["scanned_through"] == 0, "origin hunt stays at 0")
        again = initiate_hunt(start_factor=9_000_000_000)
        check(again["scanned_through"] == 9_000_000_000, "re-init must resume, not wipe")
        second["scanned_through"] = 9_000_050_000
        save_seed(second)
        again = initiate_hunt(start_factor=9_000_000_000)
        check(again["scanned_through"] == 9_000_050_000, "re-init kept progress")

        lead = load_seed("main")
        worker = dict(lead)
        worker["hunt_id"] = "w-test"
        lo1, hi1, st = claim_window(lead, 50_000)
        lo2, hi2, _ = claim_window(worker, 50_000)
        check(st == 50_000, st)
        check(hi1 == lo2, f"windows must abut, got {lo1,hi1} then {lo2,hi2}")
        check(hi1 <= lo2, "windows must not overlap")
        os.environ.pop("ES_FINDINGS", None)

    print("OK seed and letter numbers")
    print(f"  sample letter n=2521 unsolved number={a['number']}")
    print(f"  sample letter n=2521 window_broken number={broken['number']}")


if __name__ == "__main__":
    main()
