#!/usr/bin/env python3
"""Exact finite-state classifier for the fixed k=51 two-target problem.

Use G=(Z/51Z)^x=<37>x<35> ~= C16 x C2, encoded by
index=16*epsilon+a for x=35^epsilon*37^a (mod 51).

Mordell-hard p satisfy p=1 (mod 3), hence C=(p+51)/4 is also 1 (mod 3),
so the admissible center lies in the C16 subgroup epsilon=0.
"""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

MOD = 51
N = 16
ORDER = 32
IDENTITY = 0
H_GENERATOR = 37
OUTER_INVOLUTION = 35


def add(x: int, y: int) -> int:
    return (((x // N + y // N) & 1) * N + ((x % N + y % N) % N))


ADD = [[add(i, j) for j in range(ORDER)] for i in range(ORDER)]
LOCAL = [tuple(sorted({IDENTITY, g, ADD[g][g]})) for g in range(ORDER)]


def residue(g: int) -> int:
    eps, a = divmod(g, N)
    return (pow(OUTER_INVOLUTION, eps, MOD) * pow(H_GENERATOR, a, MOD)) % MOD


RESIDUE_TO_COORD = {residue(g): g for g in range(ORDER)}
TYPE_I_RESIDUE = (-pow(4, -1, MOD)) % MOD
TYPE_I = RESIDUE_TO_COORD[TYPE_I_RESIDUE]
MINUS_ONE = RESIDUE_TO_COORD[MOD - 1]
SYMMETRY_MULTIPLIERS = (1, 5, 9, 13)

EXPECTED = {
    "states": 6217,
    "admissible_states": 2907,
    "hit_states": 2000,
    "miss_states": 907,
    "pure_H_states": 293,
    "pure_H_miss_states": 293,
    "nonpure_miss_states": 614,
    "miss_symmetry_orbits": 273,
    "symmetry_orbit_histogram": {1: 31, 2: 46, 4: 196},
    "legendre17_miss_branches": {"+1": 463, "-1": 444},
    "min_outside_histogram": {0: 293, 2: 602, 4: 12},
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


def type_ii(center: int) -> int:
    if center >= N:
        raise ValueError("hard-prime admissible center must lie in H={x=1 mod3}")
    return ADD[MINUS_ONE][center]


def is_miss(state: tuple[int, int]) -> bool:
    mask, center = state
    if center >= N:
        return False
    return not ((mask >> TYPE_I) & 1) and not ((mask >> type_ii(center)) & 1)


def symmetry_elem(g: int, multiplier: int) -> int:
    eps, a = divmod(g, N)
    return eps * N + (multiplier * a) % N


def symmetry_state(state: tuple[int, int], multiplier: int) -> tuple[int, int]:
    mask, center = state
    out = 0
    work = mask
    while work:
        lsb = work & -work
        i = lsb.bit_length() - 1
        work -= lsb
        out |= 1 << symmetry_elem(i, multiplier)
    return out, symmetry_elem(center, multiplier)


def min_outside_cost(states: set[tuple[int, int]]):
    """Lexicographically minimize (outside-H valuation units, total units)."""
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
            nd = (outside + int(g >= N), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach the full closure")
    return dist


def analyze(include_rows: bool) -> dict:
    if len(RESIDUE_TO_COORD) != ORDER:
        raise SystemExit("chosen k=51 coordinates do not enumerate the unit group")
    if TYPE_I != 28 or MINUS_ONE != 24:
        raise SystemExit("k=51 target coordinates changed unexpectedly")

    states = closure()
    admissible = {s for s in states if s[1] < N}
    misses = {s for s in admissible if is_miss(s)}
    pure_h = closure(range(N))

    visited = set()
    orbit_hist = Counter()
    for state in misses:
        if state in visited:
            continue
        orbit = {symmetry_state(state, m) for m in SYMMETRY_MULTIPLIERS}
        if not orbit <= misses:
            raise SystemExit("target-preserving k=51 symmetry left the miss set")
        visited.update(orbit)
        orbit_hist[len(orbit)] += 1

    dist = min_outside_cost(states)
    min_hist = Counter(dist[s][0] for s in misses)
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)

    out = {
        "analysis": "k51-two-target-state-closure-v1",
        "group": "C16 x C2",
        "coordinate": "x=35^epsilon*37^a mod 51",
        "hard_center_subgroup": "epsilon=0, equivalently x=1 mod3",
        "type_i_residue": TYPE_I_RESIDUE,
        "type_i_coordinate": [TYPE_I // N, TYPE_I % N],
        "minus_one_coordinate": [MINUS_ONE // N, MINUS_ONE % N],
        "states": len(states),
        "admissible_states": len(admissible),
        "hit_states": len(admissible) - len(misses),
        "miss_states": len(misses),
        "pure_H_states": len(pure_h),
        "pure_H_miss_states": len(pure_h & misses),
        "nonpure_miss_states": len(misses - pure_h),
        "miss_symmetry_orbits": sum(orbit_hist.values()),
        "symmetry_orbit_histogram": dict(sorted(orbit_hist.items())),
        "legendre17_miss_branches": dict(sorted(legendre.items())),
        "min_outside_histogram": dict(sorted(min_hist.items())),
        "maximum_minimum_outside_units": max(min_hist),
        "claim": "exact finite-group state closure; not a finite-prime extrapolation",
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if isinstance(expected, dict) and all(isinstance(k, int) for k in expected):
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(f"regression constant changed: {key}: {actual!r} != {expected!r}")

    if include_rows:
        out["miss_rows"] = [
            {
                "center": [center // N, center % N],
                "center_residue": residue(center),
                "legendre17": "+1" if center % 2 == 0 else "-1",
                "divisor_coordinates": [
                    [g // N, g % N] for g in range(ORDER) if (mask >> g) & 1
                ],
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
        print("k=51 exact two-target state closure")
        for key in (
            "states", "admissible_states", "hit_states", "miss_states",
            "pure_H_miss_states", "nonpure_miss_states", "miss_symmetry_orbits",
        ):
            print(f"{key}: {report[key]}")
        print(f"Legendre(17/p) miss branches: {report['legendre17_miss_branches']}")
        print(f"minimum outside-H units: {report['min_outside_histogram']}")
        print("warning: fixed-shift classification only; Erdős-Straus remains open")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
