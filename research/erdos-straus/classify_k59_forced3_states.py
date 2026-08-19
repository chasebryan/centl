#!/usr/bin/env python3
"""Exact hard-prime k=59 state closure after the universally forced factor 3."""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

import classify_k59_states as core

FORCED_FACTOR = 3
FORCED_LOG = core.LOG[FORCED_FACTOR]
EXPECTED = {
    "states": 35740,
    "hit_states": 29871,
    "miss_states": 5869,
    "pure_qr_states": 900,
    "pure_qr_miss_states": 900,
    "legendre59_miss_branches": {"+1": 3148, "-1": 2721},
    "min_added_nonresidue_histogram": {0: 900, 1: 2263, 2: 2185, 3: 458, 4: 63},
}


def forced_start() -> tuple[int, int]:
    return core.transition((1, 0), FORCED_LOG)


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
    """Minimize added odd-log valuation units after the forced factor 3."""
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
        raise SystemExit("minimum-cost traversal did not reach forced-3 closure")
    return dist


def analyze(include_rows: bool) -> dict:
    if FORCED_LOG != 50:
        raise SystemExit(f"unexpected log_2(3) mod 59: {FORCED_LOG}")

    states = closure()
    misses = {s for s in states if core.is_miss(s)}
    pure_qr = closure(range(0, core.N, 2))
    dist = min_added_nonresidue_cost(states)
    nr_hist = Counter(dist[s][0] for s in misses)
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)

    out = {
        "analysis": "k59-forced3-hard-state-closure-v1",
        "forced_factor": FORCED_FACTOR,
        "forced_log": FORCED_LOG,
        "forced_start_divisor_set_size": forced_start()[0].bit_count(),
        "forced_start_center_log": forced_start()[1],
        "states": len(states),
        "hit_states": len(states) - len(misses),
        "miss_states": len(misses),
        "pure_qr_states": len(pure_qr),
        "pure_qr_miss_states": len(pure_qr & misses),
        "legendre59_miss_branches": dict(sorted(legendre.items())),
        "min_added_nonresidue_histogram": dict(sorted(nr_hist.items())),
        "maximum_minimum_added_nonresidue_units": max(nr_hist),
        "claim": (
            "exact hard-prime superset state closure after universal 3|C59; "
            "no finite-prime extrapolation"
        ),
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if key == "min_added_nonresidue_histogram":
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(
                f"regression constant changed: {key}: {actual!r} != {expected!r}"
            )

    if include_rows:
        out["miss_rows"] = [
            {
                "center_log": center,
                "center_residue": pow(core.PRIMITIVE_ROOT, center, core.MOD),
                "legendre59": "+1" if center % 2 == 0 else "-1",
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
        print("k=59 hard-prime forced-3 state closure")
        for key in ("states", "hit_states", "miss_states", "pure_qr_miss_states"):
            print(f"{key}: {report[key]}")
        print(f"Legendre branches: {report['legendre59_miss_branches']}")
        print(f"minimum added NR units: {report['min_added_nonresidue_histogram']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
