#!/usr/bin/env python3
"""Exact finite-state classifier for the fixed k=55 two-target problem.

Use G=(Z/55Z)^x=<2>x<21> ~= C20 x C2, encoded by
index=20*epsilon+a for x=21^epsilon*2^a (mod 55).

For Mordell-hard p, p mod 5 is 1 or 4, hence C=(p+55)/4 is a quadratic
residue mod 5. In these coordinates that is exactly the index-two center
condition a even.
"""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

MOD = 55
N = 20
ORDER = 40
IDENTITY = 0
CYCLIC_GENERATOR = 2
OUTER_INVOLUTION = 21


def add(x: int, y: int) -> int:
    return (((x // N + y // N) & 1) * N + ((x % N + y % N) % N))


ADD = [[add(i, j) for j in range(ORDER)] for i in range(ORDER)]
LOCAL = [tuple(sorted({IDENTITY, g, ADD[g][g]})) for g in range(ORDER)]


def residue(g: int) -> int:
    eps, a = divmod(g, N)
    return (pow(OUTER_INVOLUTION, eps, MOD) * pow(CYCLIC_GENERATOR, a, MOD)) % MOD


RESIDUE_TO_COORD = {residue(g): g for g in range(ORDER)}
TYPE_I_RESIDUE = (-pow(4, -1, MOD)) % MOD
TYPE_I = RESIDUE_TO_COORD[TYPE_I_RESIDUE]
MINUS_ONE = RESIDUE_TO_COORD[MOD - 1]

EXPECTED = {
    "states": 20082,
    "admissible_states": 9558,
    "hit_states": 7239,
    "miss_states": 2319,
    "pure_H_states": 710,
    "pure_H_miss_states": 211,
    "nonpure_miss_states": 2108,
    "miss_symmetry_orbits": 1436,
    "miss_symmetry_fixed": 553,
    "miss_symmetry_pairs": 883,
    "legendre11_miss_branches": {"+1": 1381, "-1": 938},
    "min_outside_histogram": {0: 211, 2: 1962, 4: 146},
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
    return (center % N) % 2 == 0


def type_ii(center: int) -> int:
    if not admissible_center(center):
        raise ValueError("hard-prime k=55 center must be quadratic-residue mod 5")
    return ADD[MINUS_ONE][center]


def is_miss(state: tuple[int, int]) -> bool:
    mask, center = state
    if not admissible_center(center):
        return False
    return not ((mask >> TYPE_I) & 1) and not ((mask >> type_ii(center)) & 1)


def symmetry_elem(g: int) -> int:
    """Target-preserving involution (epsilon,a)->(epsilon,11a)."""
    eps, a = divmod(g, N)
    return eps * N + (11 * a) % N


def symmetry_state(state: tuple[int, int]) -> tuple[int, int]:
    mask, center = state
    out = 0
    work = mask
    while work:
        lsb = work & -work
        i = lsb.bit_length() - 1
        work -= lsb
        out |= 1 << symmetry_elem(i)
    return out, symmetry_elem(center)


def min_outside_cost(states: set[tuple[int, int]]):
    """Minimize valuation units outside the mod-5 quadratic-residue subgroup."""
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
            nd = (outside + ((g % N) & 1), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach the full closure")
    return dist


def analyze(include_rows: bool) -> dict:
    if len(RESIDUE_TO_COORD) != ORDER:
        raise SystemExit("chosen k=55 coordinates do not enumerate the unit group")
    if TYPE_I != 28 or MINUS_ONE != 30:
        raise SystemExit("k=55 target coordinates changed unexpectedly")

    states = closure()
    admissible = {s for s in states if admissible_center(s[1])}
    misses = {s for s in admissible if is_miss(s)}
    h_directions = [g for g in range(ORDER) if (g % N) % 2 == 0]
    pure_h = closure(h_directions)

    visited = set()
    fixed = pairs = 0
    for state in misses:
        if state in visited:
            continue
        mate = symmetry_state(state)
        if mate not in misses:
            raise SystemExit("target-preserving k=55 symmetry left the miss set")
        orbit = {state, mate}
        visited.update(orbit)
        if len(orbit) == 1:
            fixed += 1
        else:
            pairs += 1

    dist = min_outside_cost(states)
    min_hist = Counter(dist[s][0] for s in misses)
    legendre11 = Counter(
        "+1" if center // N == 0 else "-1" for _, center in misses
    )

    out = {
        "analysis": "k55-two-target-state-closure-v1",
        "group": "C20 x C2",
        "coordinate": "x=21^epsilon*2^a mod 55",
        "hard_center_subgroup": "a even, equivalently quadratic-residue mod 5",
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
        "miss_symmetry_orbits": fixed + pairs,
        "miss_symmetry_fixed": fixed,
        "miss_symmetry_pairs": pairs,
        "legendre11_miss_branches": dict(sorted(legendre11.items())),
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
                "legendre11": "+1" if center // N == 0 else "-1",
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
        print("k=55 exact two-target state closure")
        for key in (
            "states", "admissible_states", "hit_states", "miss_states",
            "pure_H_miss_states", "nonpure_miss_states", "miss_symmetry_orbits",
        ):
            print(f"{key}: {report[key]}")
        print(f"Legendre(11/p) miss branches: {report['legendre11_miss_branches']}")
        print(f"minimum outside-H units: {report['min_outside_histogram']}")
        print("warning: fixed-shift classification only; Erdős-Straus remains open")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
