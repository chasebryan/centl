#!/usr/bin/env python3
"""Exact hard-prime forced-seed reductions for the conjugate k=35 and k=39 models."""
from __future__ import annotations

import argparse
import heapq
import json
from collections import Counter, deque

import classify_k35_states as k35
import classify_k39_states as k39

START = (1 << k35.IDENTITY, k35.IDENTITY)

EXPECTED = {
    35: {
        "forced_factor": 3,
        "forced_direction": 1,
        "states": 394,
        "admissible_states": 194,
        "hit_states": 130,
        "miss_states": 64,
        "pure_H_states": 38,
        "pure_H_miss_states": 38,
        "min_added_outside_histogram": {0: 38, 2: 26},
    },
    39: {
        "forced_factor": 2,
        "forced_direction": 13,
        "states": 394,
        "admissible_states": 196,
        "hit_states": 160,
        "miss_states": 36,
        "min_added_outside_histogram": {1: 34, 3: 2},
    },
}


def direction_for_residue(modulus: int, residue: int) -> int:
    fn = k35.residue if modulus == 35 else k39.residue
    matches = [g for g in range(k35.ORDER) if fn(g) == residue % modulus]
    if len(matches) != 1:
        raise SystemExit((modulus, residue, matches))
    return matches[0]


def closure_from(start: tuple[int, int], directions=range(k35.ORDER)):
    seen = {start}
    q = deque([start])
    while q:
        state = q.popleft()
        for g in directions:
            nxt = k35.transition(state, g)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def min_added_outside_cost(states: set[tuple[int, int]], start: tuple[int, int]):
    inf = (10**9, 10**9)
    dist = {start: (0, 0)}
    heap = [(0, 0, start[0], start[1])]
    while heap:
        outside, total, mask, center = heapq.heappop(heap)
        state = (mask, center)
        if dist.get(state) != (outside, total):
            continue
        for g in range(k35.ORDER):
            nxt = k35.transition(state, g)
            nd = (outside + int(g >= 12), total + 1)
            if nd < dist.get(nxt, inf):
                dist[nxt] = nd
                heapq.heappush(heap, (nd[0], nd[1], nxt[0], nxt[1]))
    if set(dist) != states:
        raise SystemExit("minimum-cost traversal did not reach forced-seed closure")
    return dist


def analyze_one(modulus: int, include_rows: bool) -> dict:
    if modulus == 35:
        forced_factor = 3
        miss_fn = k35.is_miss
        residue_fn = k35.residue
    elif modulus == 39:
        forced_factor = 2
        miss_fn = k39.is_miss
        residue_fn = k39.residue
    else:
        raise ValueError(modulus)

    forced_direction = direction_for_residue(modulus, forced_factor)
    start = k35.transition(START, forced_direction)
    states = closure_from(start)
    admissible = {s for s in states if s[1] < 12}
    misses = {s for s in admissible if miss_fn(s)}
    dist = min_added_outside_cost(states, start)
    hist = Counter(dist[s][0] for s in misses)

    out = {
        "modulus": modulus,
        "forced_factor": forced_factor,
        "forced_direction": forced_direction,
        "forced_coordinate": [forced_direction // 12, forced_direction % 12],
        "forced_start_divisor_set_size": start[0].bit_count(),
        "states": len(states),
        "admissible_states": len(admissible),
        "hit_states": len(admissible) - len(misses),
        "miss_states": len(misses),
        "min_added_outside_histogram": dict(sorted(hist.items())),
        "maximum_minimum_added_outside_units": max(hist),
    }

    if modulus == 35:
        pure_h = closure_from(start, range(12))
        out["pure_H_states"] = len(pure_h)
        out["pure_H_miss_states"] = len(pure_h & misses)

    for key, expected in EXPECTED[modulus].items():
        actual = out[key]
        if key == "min_added_outside_histogram":
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(
                f"k={modulus} regression changed: {key}: {actual!r} != {expected!r}"
            )

    if include_rows:
        out["miss_rows"] = [
            {
                "center": [center // 12, center % 12],
                "center_residue": residue_fn(center),
                "divisor_coordinates": [
                    [g // 12, g % 12]
                    for g in range(k35.ORDER)
                    if (mask >> g) & 1
                ],
                "min_added_outside": dist[(mask, center)][0],
            }
            for mask, center in sorted(misses, key=lambda s: (s[1], s[0]))
        ]
    return out


def analyze(include_rows: bool) -> dict:
    return {
        "analysis": "k35-k39-forced-seed-hard-closures-v1",
        "k35": analyze_one(35, include_rows),
        "k39": analyze_one(39, include_rows),
        "claim": (
            "exact hard-prime superset closures after universal seeds; "
            "the generic k35/k39 conjugacy does not identify the seeded hard problems"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--table", action="store_true")
    args = ap.parse_args()
    report = analyze(args.table)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key in ("k35", "k39"):
            row = report[key]
            print(
                f"{key}: forced={row['forced_factor']} states={row['states']} "
                f"admissible={row['admissible_states']} misses={row['miss_states']} "
                f"added-outside={row['min_added_outside_histogram']}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
