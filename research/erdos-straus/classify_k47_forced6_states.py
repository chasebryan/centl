#!/usr/bin/env python3
"""Exact hard-prime k=47 state closure after the universally forced factor 6."""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

import classify_k47_states as core

FORCED_LOGS = (core.LOG[2], core.LOG[3])
EXPECTED = {
    "states": 1079,
    "hit_states": 883,
    "miss_states": 196,
    "pure_qr_states": 66,
    "pure_qr_miss_states": 66,
    "legendre47_miss_branches": {"+1": 116, "-1": 80},
    "min_added_nonresidue_histogram": {0: 66, 1: 80, 2: 50},
}


def forced_start() -> tuple[int, int]:
    state = (1, 0)
    for a in FORCED_LOGS:
        state = core.transition(state, a)
    return state


def closure(directions=range(core.N)) -> set[tuple[int, int]]:
    start = forced_start()
    seen = {start}
    q = deque([start])
    while q:
        state = q.popleft()
        for a in directions:
            nxt = core.transition(state, a)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def min_added_nonresidue_cost(states: set[tuple[int, int]]):
    start = forced_start()
    inf = (10**9, 10**9)
    dist = {start: (0, 0)}
    heap = [(0, 0, start[0], start[1])]
    while heap:
        nr, total, mask, center = heapq.heappop(heap)
        state = (mask, center)
        if dist.get(state) != (nr, total):
            continue
        for a in range(core.N):
            nxt = core.transition(state, a)
            nd = (nr + (a & 1), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach forced-6 closure")
    return dist


def analyze(include_rows: bool) -> dict:
    states = closure()
    misses = {s for s in states if core.is_miss(s)}
    pure_qr = closure(range(0, core.N, 2))
    dist = min_added_nonresidue_cost(states)
    nr_hist = Counter(dist[s][0] for s in misses)
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)

    out = {
        "analysis": "k47-forced6-hard-state-closure-v1",
        "forced_factors": [2, 3],
        "forced_logs": list(FORCED_LOGS),
        "forced_start_divisor_set_size": forced_start()[0].bit_count(),
        "forced_start_center_log": forced_start()[1],
        "states": len(states),
        "hit_states": len(states) - len(misses),
        "miss_states": len(misses),
        "pure_qr_states": len(pure_qr),
        "pure_qr_miss_states": len(pure_qr & misses),
        "legendre47_miss_branches": dict(sorted(legendre.items())),
        "min_added_nonresidue_histogram": dict(sorted(nr_hist.items())),
        "maximum_minimum_added_nonresidue_units": max(nr_hist),
        "claim": "exact hard-prime superset state closure after universal 6|C47; no finite-prime extrapolation",
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if key == "min_added_nonresidue_histogram":
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(f"regression constant changed: {key}: {actual!r} != {expected!r}")

    if include_rows:
        out["miss_rows"] = [
            {
                "center_log": center,
                "center_residue": pow(core.PRIMITIVE_ROOT, center, core.MOD),
                "legendre47": "+1" if center % 2 == 0 else "-1",
                "divisor_logs": [a for a in range(core.N) if (mask >> a) & 1],
                "min_added_nonresidue_units": dist[(mask, center)][0],
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
        print("k=47 hard-prime forced-6 state closure")
        for key in ("states", "hit_states", "miss_states", "pure_qr_miss_states"):
            print(f"{key}: {report[key]}")
        print(f"Legendre branches: {report['legendre47_miss_branches']}")
        print(f"minimum added NR units: {report['min_added_nonresidue_histogram']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
