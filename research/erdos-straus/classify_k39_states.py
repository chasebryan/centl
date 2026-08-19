#!/usr/bin/env python3
"""Exact k=39 two-target classifier via C12 x C2 conjugacy with k=35."""
from __future__ import annotations

import argparse
import json
from collections import Counter

import classify_k35_states as core

TYPE_I = 12 + 4
EXPECTED = {
    "states": 1298,
    "admissible_states": 650,
    "hit_states": 418,
    "miss_states": 232,
    "pure_J_states": 92,
    "pure_J_miss_states": 92,
    "nonpure_miss_states": 140,
    "miss_symmetry_orbits": 149,
    "miss_symmetry_fixed": 66,
    "miss_symmetry_pairs": 83,
    "min_outside_histogram": {0: 92, 2: 138, 4: 2},
    "legendre13_miss_branches": {"+1": 122, "-1": 110},
}


def residue(g: int) -> int:
    eps, a = divmod(g, 12)
    return (pow(14, eps, 39) * pow(28, a, 39)) % 39


def type_ii(center: int) -> int:
    if center >= 12:
        raise ValueError("hard-prime k=39 center must be in J={x=1 mod3}")
    return 12 + ((center + 6) % 12)


def is_miss(state: tuple[int, int]) -> bool:
    mask, center = state
    return center < 12 and not ((mask >> TYPE_I) & 1) and not ((mask >> type_ii(center)) & 1)


def map_elem(g: int, mult: int) -> int:
    eps, a = divmod(g, 12)
    return eps * 12 + (mult * a) % 12


def map_state(state: tuple[int, int], mult: int) -> tuple[int, int]:
    mask, center = state
    out = 0
    work = mask
    while work:
        lsb = work & -work
        i = lsb.bit_length() - 1
        work -= lsb
        out |= 1 << map_elem(i, mult)
    return out, map_elem(center, mult)


def analyze(include_rows: bool) -> dict:
    states = core.closure()
    admissible = {s for s in states if s[1] < 12}
    misses = {s for s in admissible if is_miss(s)}
    pure = core.closure(range(12))

    # Exact target conjugacy from k=35: (eps,a) -> (eps,5a).
    # It fixes -1=(1,6), sends (1,8) to (1,4), and maps
    # (1,c+6) to (1,5c+6).
    miss35 = {s for s in states if core.is_miss(s)}
    image35 = {map_state(s, 5) for s in miss35}
    if image35 != misses:
        raise SystemExit("k35->k39 target conjugacy failed")

    visited = set()
    fixed = pairs = 0
    for state in misses:
        if state in visited:
            continue
        mate = core.symmetry_state(state)
        if mate not in misses:
            raise SystemExit("k39 target-preserving symmetry failed")
        orbit = {state, mate}
        visited.update(orbit)
        if len(orbit) == 1:
            fixed += 1
        else:
            pairs += 1

    dist, prev = core.min_outside_cost(states)
    min_hist = Counter(dist[s][0] for s in misses)
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)

    exceptional = []
    for state in sorted((s for s in misses if dist[s][0] == 4), key=lambda s: (s[1], s[0])):
        mask, center = state
        seq = core.witness(state, prev)
        missing = [g for g in range(24) if not ((mask >> g) & 1)]
        exceptional.append({
            "center": [0, center],
            "center_residue": residue(center),
            "divisor_set_size": mask.bit_count(),
            "missing_coordinates": [[g // 12, g % 12] for g in missing],
            "missing_residues": [residue(g) for g in missing],
            "witness_coordinates": [[g // 12, g % 12] for g in seq],
            "witness_residues": [residue(g) for g in seq],
            "targets_coincide": TYPE_I == type_ii(center),
        })

    out = {
        "analysis": "k39-two-target-state-closure-v1",
        "group": "C12 x C2",
        "coordinate": "x=14^epsilon*28^a mod 39",
        "states": len(states),
        "admissible_states": len(admissible),
        "hit_states": len(admissible) - len(misses),
        "miss_states": len(misses),
        "pure_J_states": len(pure),
        "pure_J_miss_states": len(pure & misses),
        "nonpure_miss_states": len(misses - pure),
        "miss_symmetry_orbits": fixed + pairs,
        "miss_symmetry_fixed": fixed,
        "miss_symmetry_pairs": pairs,
        "min_outside_histogram": dict(sorted(min_hist.items())),
        "legendre13_miss_branches": dict(sorted(legendre.items())),
        "k35_conjugacy_multiplier": 5,
        "k35_conjugacy_verified": True,
        "exceptional_min_outside_4_states": exceptional,
        "claim": "exact finite-group state closure via target-preserving conjugacy; not finite-prime extrapolation",
    }

    for key, expected in EXPECTED.items():
        actual = out[key]
        if isinstance(expected, dict) and key == "min_outside_histogram":
            actual = {int(k): v for k, v in actual.items()}
        if actual != expected:
            raise SystemExit(f"regression constant changed: {key}: {actual!r} != {expected!r}")

    if include_rows:
        out["miss_rows"] = [
            {
                "center": [0, center],
                "center_residue": residue(center),
                "divisor_coordinates": [[g // 12, g % 12] for g in range(24) if (mask >> g) & 1],
                "min_outside": dist[(mask, center)][0],
                "legendre13": "+1" if center % 2 == 0 else "-1",
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
        print("k=39 exact two-target state closure")
        for key in (
            "states", "admissible_states", "hit_states", "miss_states",
            "pure_J_miss_states", "nonpure_miss_states", "miss_symmetry_orbits",
        ):
            print(f"{key}: {report[key]}")
        print(f"Legendre(13/p) miss branches: {report['legendre13_miss_branches']}")
        print("warning: fixed-shift classification only; Erdős-Straus remains open")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
