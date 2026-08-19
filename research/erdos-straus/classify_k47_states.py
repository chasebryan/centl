#!/usr/bin/env python3
"""Exact finite-state classifier for the fixed k=47 two-target problem."""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

MOD = 47
N = 46
ALL = (1 << N) - 1
PRIMITIVE_ROOT = 5
TYPE_I_RESIDUE = (-pow(4, -1, MOD)) % MOD
LOG = {pow(PRIMITIVE_ROOT, a, MOD): a for a in range(N)}
TYPE_I = LOG[TYPE_I_RESIDUE]
MINUS_ONE = N // 2
EXPECTED = {
    "states": 61134,
    "hit_states": 46660,
    "miss_states": 14474,
    "pure_qr_states": 1498,
    "pure_qr_miss_states": 1498,
    "legendre47_miss_branches": {"+1": 7626, "-1": 6848},
    "min_nonresidue_histogram": {0: 1498, 1: 5187, 2: 5740, 3: 1661, 4: 388},
}


def rotate(mask: int, a: int) -> int:
    a %= N
    if not a:
        return mask
    return ((mask << a) | (mask >> (N - a))) & ALL


def transition(state: tuple[int, int], a: int) -> tuple[int, int]:
    mask, center = state
    return mask | rotate(mask, a) | rotate(mask, 2 * a), (center + a) % N


def closure(directions=range(N)) -> set[tuple[int, int]]:
    start = (1, 0)
    seen = {start}
    q = deque([start])
    while q:
        state = q.popleft()
        for a in directions:
            nxt = transition(state, a)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def type_ii(center: int) -> int:
    return (center + MINUS_ONE) % N


def is_miss(state: tuple[int, int]) -> bool:
    mask, center = state
    return not ((mask >> TYPE_I) & 1) and not ((mask >> type_ii(center)) & 1)


def min_nonresidue_cost(states: set[tuple[int, int]]):
    start = (1, 0)
    inf = (10**9, 10**9)
    dist = {start: (0, 0)}
    heap = [(0, 0, start[0], start[1])]
    while heap:
        nr, total, mask, center = heapq.heappop(heap)
        state = (mask, center)
        if dist.get(state) != (nr, total):
            continue
        for a in range(N):
            nxt = transition(state, a)
            nd = (nr + (a & 1), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach the full closure")
    return dist


def analyze(include_rows: bool) -> dict:
    states = closure()
    misses = {s for s in states if is_miss(s)}
    pure_qr = closure(range(0, N, 2))
    dist = min_nonresidue_cost(states)
    nr_hist = Counter(dist[s][0] for s in misses)
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)

    out = {
        "analysis": "k47-two-target-state-closure-v1",
        "group": "C46",
        "primitive_root": PRIMITIVE_ROOT,
        "type_i_residue": TYPE_I_RESIDUE,
        "type_i_log": TYPE_I,
        "minus_one_log": MINUS_ONE,
        "states": len(states),
        "hit_states": len(states) - len(misses),
        "miss_states": len(misses),
        "pure_qr_states": len(pure_qr),
        "pure_qr_miss_states": len(pure_qr & misses),
        "legendre47_miss_branches": dict(sorted(legendre.items())),
        "min_nonresidue_histogram": dict(sorted(nr_hist.items())),
        "maximum_minimum_nonresidue_units": max(nr_hist),
        "nontrivial_target_preserving_power_symmetry": False,
        "claim": "exact finite-group state closure; not a finite-prime extrapolation",
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if key == "min_nonresidue_histogram":
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(f"regression constant changed: {key}: {actual!r} != {expected!r}")

    if include_rows:
        out["miss_rows"] = [
            {
                "center_log": center,
                "center_residue": pow(PRIMITIVE_ROOT, center, MOD),
                "legendre47": "+1" if center % 2 == 0 else "-1",
                "divisor_logs": [a for a in range(N) if (mask >> a) & 1],
                "min_nonresidue_units": dist[(mask, center)][0],
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
        print("k=47 exact two-target state closure")
        for key in ("states", "hit_states", "miss_states", "pure_qr_miss_states"):
            print(f"{key}: {report[key]}")
        print(f"Legendre(47/p) miss branches: {report['legendre47_miss_branches']}")
        print(f"minimum nonresidue units: {report['min_nonresidue_histogram']}")
        print("warning: fixed-shift classification only; Erdős-Straus remains open")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
