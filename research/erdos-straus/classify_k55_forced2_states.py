#!/usr/bin/env python3
"""Exact hard-prime k=55 state closure after the universally forced factor 2."""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

import classify_k55_states as core

FORCED_FACTOR = 2
FORCED_DIRECTION = core.RESIDUE_TO_COORD[FORCED_FACTOR]
EXPECTED = {
    "states": 4051,
    "admissible_states": 1990,
    "hit_states": 1676,
    "miss_states": 314,
    "legendre11_miss_branches": {"+1": 198, "-1": 116},
    "min_added_outside_histogram": {1: 283, 3: 31},
}


def forced_start() -> tuple[int, int]:
    return core.transition((1, 0), FORCED_DIRECTION)


def closure(directions=range(core.ORDER)) -> set[tuple[int, int]]:
    start = forced_start()
    seen = {start}
    q = deque([start])
    while q:
        state = q.popleft()
        for g in directions:
            nxt = core.transition(state, g)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def min_added_outside_cost(states: set[tuple[int, int]]):
    """Minimize added valuation units outside the hard mod-5 QR subgroup."""
    start = forced_start()
    inf = (10**9, 10**9)
    dist = {start: (0, 0)}
    heap = [(0, 0, start[0], start[1])]
    while heap:
        outside, total, mask, center = heapq.heappop(heap)
        state = (mask, center)
        if dist.get(state) != (outside, total):
            continue
        for g in range(core.ORDER):
            nxt = core.transition(state, g)
            nd = (outside + int(not core.admissible_center(g)), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach forced-2 closure")
    return dist


def analyze(include_rows: bool) -> dict:
    if FORCED_DIRECTION != 1:
        raise SystemExit(f"unexpected k=55 coordinate for factor 2: {FORCED_DIRECTION}")

    states = closure()
    admissible = {s for s in states if core.admissible_center(s[1])}
    misses = {s for s in admissible if core.is_miss(s)}
    dist = min_added_outside_cost(states)
    outside_hist = Counter(dist[s][0] for s in misses)
    legendre = Counter("+1" if center // core.N == 0 else "-1" for _, center in misses)

    out = {
        "analysis": "k55-forced2-hard-state-closure-v1",
        "forced_factor": FORCED_FACTOR,
        "forced_direction": FORCED_DIRECTION,
        "forced_coordinate": [0, 1],
        "forced_start_divisor_set_size": forced_start()[0].bit_count(),
        "forced_start_center": [0, 1],
        "states": len(states),
        "admissible_states": len(admissible),
        "hit_states": len(admissible) - len(misses),
        "miss_states": len(misses),
        "legendre11_miss_branches": dict(sorted(legendre.items())),
        "min_added_outside_histogram": dict(sorted(outside_hist.items())),
        "maximum_minimum_added_outside_units": max(outside_hist),
        "claim": (
            "exact hard-prime superset state closure after universal 2|C55; "
            "no finite-prime extrapolation"
        ),
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if key == "min_added_outside_histogram":
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(
                f"regression constant changed: {key}: {actual!r} != {expected!r}"
            )

    if include_rows:
        out["miss_rows"] = [
            {
                "center": [center // core.N, center % core.N],
                "center_residue": core.residue(center),
                "legendre11": "+1" if center // core.N == 0 else "-1",
                "divisor_coordinates": [
                    [g // core.N, g % core.N]
                    for g in range(core.ORDER)
                    if (mask >> g) & 1
                ],
                "min_added_outside": dist[(mask, center)][0],
            }
            for mask, center in sorted(misses, key=lambda s: (s[1], s[0]))
        ]
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--table", action="store_true")
    args = ap.parse_args()
    report = analyze(args.table)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("k=55 hard-prime forced-2 state closure")
        for key in ("states", "admissible_states", "hit_states", "miss_states"):
            print(f"{key}: {report[key]}")
        print(f"Legendre branches: {report['legendre11_miss_branches']}")
        print(f"minimum added outside-H units: {report['min_added_outside_histogram']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
