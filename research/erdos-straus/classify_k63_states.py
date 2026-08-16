#!/usr/bin/env python3
"""Exact finite-state classifier for the fixed k=63 two-target problem.

Use G=(Z/63Z)^x ~= C6 x C6 with CRT generators 29 and 10:
29 has order 6 and is nontrivial only on the mod-9 factor;
10 has order 6 and is nontrivial only on the mod-7 factor.

Mordell-hard primes force C=(p+63)/4 into the index-four subgroup where
both C6 coordinates are even, equivalently C3 x C3.
"""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

MOD = 63
N = 6
ORDER = 36
IDENTITY = 0
GEN9 = 29
GEN7 = 10


def encode(a: int, b: int) -> int:
    return (a % N) * N + (b % N)


def decode(g: int) -> tuple[int, int]:
    return divmod(g, N)


def add(x: int, y: int) -> int:
    a, b = decode(x)
    c, d = decode(y)
    return encode(a + c, b + d)


ADD = [[add(i, j) for j in range(ORDER)] for i in range(ORDER)]
LOCAL = [tuple(sorted({IDENTITY, g, ADD[g][g]})) for g in range(ORDER)]


def residue(g: int) -> int:
    a, b = decode(g)
    return (pow(GEN9, a, MOD) * pow(GEN7, b, MOD)) % MOD


RESIDUE_TO_COORD = {residue(g): g for g in range(ORDER)}
TYPE_I_RESIDUE = (-pow(4, -1, MOD)) % MOD
TYPE_I = RESIDUE_TO_COORD[TYPE_I_RESIDUE]
MINUS_ONE = RESIDUE_TO_COORD[MOD - 1]

EXPECTED = {
    "states": 6389,
    "admissible_states": 1844,
    "hit_states": 1160,
    "miss_states": 684,
    "pure_H_states": 22,
    "pure_H_miss_states": 22,
    "nonpure_miss_states": 662,
    "min_outside_histogram": {0: 22, 2: 222, 3: 206, 4: 234},
}


def transition(state: tuple[int, int], g: int) -> tuple[int, int]:
    mask, center = state
    out = 0
    work = mask
    while work:
        lsb = work & -work
        i = lsb.bit_length() - 1
        work -= lsb
        for v in LOCAL[g]:
            out |= 1 << ADD[i][v]
    return out, ADD[center][g]


def closure(directions=range(ORDER)) -> set[tuple[int, int]]:
    start = (1 << IDENTITY, IDENTITY)
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for g in directions:
            nxt = transition(state, g)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def admissible_center(center: int) -> bool:
    a, b = decode(center)
    return a % 2 == 0 and b % 2 == 0


def type_ii(center: int) -> int:
    if not admissible_center(center):
        raise ValueError("hard-prime k=63 center must lie in C3 x C3")
    return ADD[MINUS_ONE][center]


def is_miss(state: tuple[int, int]) -> bool:
    mask, center = state
    if not admissible_center(center):
        return False
    return not ((mask >> TYPE_I) & 1) and not ((mask >> type_ii(center)) & 1)


def min_outside_cost(states: set[tuple[int, int]]):
    """Minimize valuation units outside the hard C3 x C3 center subgroup."""
    start = (1 << IDENTITY, IDENTITY)
    inf = (10**9, 10**9)
    dist = {start: (0, 0)}
    heap = [(0, 0, start[0], start[1])]
    while heap:
        outside, total, mask, center = heapq.heappop(heap)
        state = (mask, center)
        if dist.get(state) != (outside, total):
            continue
        for g in range(ORDER):
            nxt = transition(state, g)
            nd = (outside + int(not admissible_center(g)), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach the full closure")
    return dist


def analyze(include_rows: bool) -> dict:
    if len(RESIDUE_TO_COORD) != ORDER:
        raise SystemExit("chosen k=63 coordinates do not enumerate the unit group")
    if decode(TYPE_I) != (1, 5) or decode(MINUS_ONE) != (3, 3):
        raise SystemExit("k=63 target coordinates changed unexpectedly")

    states = closure()
    admissible = {s for s in states if admissible_center(s[1])}
    misses = {s for s in admissible if is_miss(s)}
    h_directions = [g for g in range(ORDER) if admissible_center(g)]
    pure_h = closure(h_directions)
    dist = min_outside_cost(states)
    min_hist = Counter(dist[s][0] for s in misses)

    out = {
        "analysis": "k63-two-target-state-closure-v1",
        "group": "C6 x C6",
        "coordinate": "x=29^a*10^b mod 63",
        "hard_center_subgroup": "a,b even, equivalently C3 x C3",
        "type_i_residue": TYPE_I_RESIDUE,
        "type_i_coordinate": list(decode(TYPE_I)),
        "minus_one_coordinate": list(decode(MINUS_ONE)),
        "states": len(states),
        "admissible_states": len(admissible),
        "hit_states": len(admissible) - len(misses),
        "miss_states": len(misses),
        "pure_H_states": len(pure_h),
        "pure_H_miss_states": len(pure_h & misses),
        "nonpure_miss_states": len(misses - pure_h),
        "min_outside_histogram": dict(sorted(min_hist.items())),
        "maximum_minimum_outside_units": max(min_hist),
        "claim": "exact finite-group state closure; not a finite-prime extrapolation",
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if isinstance(expected, dict):
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(f"regression constant changed: {key}: {actual!r} != {expected!r}")

    if include_rows:
        out["miss_rows"] = [
            {
                "center": list(decode(center)),
                "center_residue": residue(center),
                "divisor_coordinates": [list(decode(g)) for g in range(ORDER) if (mask >> g) & 1],
                "min_outside": dist[(mask, center)][0],
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
        print("k=63 exact two-target state closure")
        for key in (
            "states", "admissible_states", "hit_states", "miss_states",
            "pure_H_miss_states", "nonpure_miss_states",
        ):
            print(f"{key}: {report[key]}")
        print(f"minimum outside-H units: {report['min_outside_histogram']}")
        print("warning: fixed-shift classification only; Erdős-Straus remains open")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
