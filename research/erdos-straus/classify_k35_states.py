#!/usr/bin/env python3
"""Exact finite-state classifier for the k=35 two-target signed-box state space.

Coordinates use G=(Z/35Z)^x = <3> x <6> ~= C12 x C2, encoded as
index = 12*epsilon + a for x = 6^epsilon * 3^a (mod 35).

One prime-valuation occurrence with coordinate g contributes divisor exponents
0,1,2, so the exact state transition is D -> D+{0,g,2g}, c -> c+g.
Closing under all 24 unit directions therefore exhausts arbitrary
factorization residue states. Mordell-hard shifted integers C=(p+35)/4 have
center epsilon=0 by the Jacobi parity law.
"""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

ORDER = 24
IDENTITY = 0
TYPE_I = 12 + 8  # (1,8)
EXPECTED = {
    "states": 1298,
    "admissible_states": 650,
    "miss_states": 232,
    "hit_states": 418,
    "pure_H_states": 92,
    "pure_H_miss_states": 92,
    "nonpure_miss_states": 140,
    "miss_symmetry_orbits": 149,
    "miss_symmetry_fixed": 66,
    "miss_symmetry_pairs": 83,
    "min_outside_histogram": {0: 92, 2: 138, 4: 2},
}


def add(x: int, y: int) -> int:
    return (((x // 12 + y // 12) & 1) * 12 + ((x % 12 + y % 12) % 12))


ADD = [[add(i, j) for j in range(ORDER)] for i in range(ORDER)]
LOCAL = [tuple(sorted({IDENTITY, g, ADD[g][g]})) for g in range(ORDER)]


def residue(g: int) -> int:
    eps, a = divmod(g, 12)
    return (pow(6, eps, 35) * pow(3, a, 35)) % 35


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
    if center >= 12:
        raise ValueError("hard-prime admissible center must lie in H")
    return 12 + ((center + 6) % 12)


def is_miss(state: tuple[int, int]) -> bool:
    mask, center = state
    if center >= 12:
        return False
    return not ((mask >> TYPE_I) & 1) and not ((mask >> type_ii(center)) & 1)


def symmetry_elem(g: int) -> int:
    """Nontrivial target-preserving automorphism (eps,a)->(eps,7a)."""
    eps, a = divmod(g, 12)
    return eps * 12 + (7 * a) % 12


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


def min_outside_cost(states: set[tuple[int, int]]) -> tuple[dict[tuple[int, int], tuple[int, int]], dict]:
    """Lexicographically minimize (outside-H valuation units, total units)."""
    start = (1 << IDENTITY, IDENTITY)
    inf = (10**9, 10**9)
    dist = {start: (0, 0)}
    prev: dict[tuple[int, int], tuple[tuple[int, int], int]] = {}
    heap = [(0, 0, start[0], start[1])]
    while heap:
        outside, total, mask, center = heapq.heappop(heap)
        state = (mask, center)
        if dist.get(state) != (outside, total):
            continue
        for g in range(ORDER):
            nxt = transition(state, g)
            nd = (outside + int(g >= 12), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                prev[nxt] = (state, g)
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost walk did not reach the full closure")
    return dist, prev


def witness(state, prev):
    start = (1 << IDENTITY, IDENTITY)
    seq = []
    cur = state
    while cur != start:
        cur, g = prev[cur]
        seq.append(g)
    seq.reverse()
    return seq


def analyze(include_rows: bool) -> dict:
    states = closure()
    admissible = {s for s in states if s[1] < 12}
    misses = {s for s in admissible if is_miss(s)}
    pure_h = closure(range(12))
    pure_h_misses = pure_h & misses

    visited = set()
    fixed = pairs = 0
    for state in misses:
        if state in visited:
            continue
        mate = symmetry_state(state)
        if mate not in misses:
            raise SystemExit("target-preserving symmetry left the miss set")
        orbit = {state, mate}
        visited.update(orbit)
        if len(orbit) == 1:
            fixed += 1
        else:
            pairs += 1

    dist, prev = min_outside_cost(states)
    min_hist = Counter(dist[s][0] for s in misses)
    exceptional = []
    for state in sorted((s for s in misses if dist[s][0] == 4), key=lambda s: (s[1], s[0])):
        mask, center = state
        seq = witness(state, prev)
        missing = [g for g in range(24) if not ((mask >> g) & 1)]
        exceptional.append({
            "center": [center // 12, center % 12],
            "center_residue": residue(center),
            "divisor_set_size": mask.bit_count(),
            "missing_coordinates": [[g // 12, g % 12] for g in missing],
            "missing_residues": [residue(g) for g in missing],
            "witness_coordinates": [[g // 12, g % 12] for g in seq],
            "witness_residues": [residue(g) for g in seq],
            "targets_coincide": TYPE_I == type_ii(center),
        })

    summary = {
        "analysis": "k35-two-target-state-closure-v1",
        "group": "C12 x C2",
        "coordinate": "x=6^epsilon*3^a mod 35",
        "states": len(states),
        "admissible_states": len(admissible),
        "hit_states": len(admissible) - len(misses),
        "miss_states": len(misses),
        "pure_H_states": len(pure_h),
        "pure_H_miss_states": len(pure_h_misses),
        "nonpure_miss_states": len(misses - pure_h),
        "miss_symmetry_orbits": fixed + pairs,
        "miss_symmetry_fixed": fixed,
        "miss_symmetry_pairs": pairs,
        "min_outside_histogram": dict(sorted(min_hist.items())),
        "minimum_outside_cutoff_for_state_representatives": 4,
        "exceptional_min_outside_4_states": exceptional,
        "claim": "exact finite-group state closure; not a finite-prime extrapolation",
    }
    for key, expected in EXPECTED.items():
        actual = summary[key]
        if isinstance(expected, dict):
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(f"regression constant changed: {key}: {actual!r} != {expected!r}")

    if include_rows:
        summary["miss_rows"] = [
            {
                "center": [c // 12, c % 12],
                "center_residue": residue(c),
                "divisor_coordinates": [[g // 12, g % 12] for g in range(24) if (D >> g) & 1],
                "min_outside": dist[(D, c)][0],
            }
            for D, c in sorted(misses, key=lambda s: (s[1], s[0]))
        ]
    return summary


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--table", action="store_true", help="include all 232 exact miss rows")
    args = ap.parse_args()
    out = analyze(args.table)
    if args.json:
        print(json.dumps(out, indent=2, sort_keys=True))
    else:
        print("k=35 exact two-target state closure")
        for key in ("states", "admissible_states", "hit_states", "miss_states", "pure_H_miss_states", "nonpure_miss_states", "miss_symmetry_orbits"):
            print(f"{key}: {out[key]}")
        print(f"minimum outside histogram: {out['min_outside_histogram']}")
        print("warning: fixed-shift classification only; Erdős-Straus remains open")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
