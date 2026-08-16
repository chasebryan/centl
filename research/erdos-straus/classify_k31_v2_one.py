#!/usr/bin/env python3
"""Exact finite-group classifier for the k=31, v2(C)=1 lift problem.

Let C=(p+31)/4 and suppose v2(C)=1.  In base-3 logarithms modulo 31,
the divisor-log box of the forced factor 2 is

    D0 = {0, 24, 18},   c0 = 24   in C_30.

Every additional prime-valuation occurrence with log a contributes divisor
exponents {0,a,2a}, so the abstract transition is

    D -> D + {0,a,2a},   c -> c+a.

All unit residue classes modulo 31 are represented by some log a in C_30.
This program closes that finite transition system exactly, classifies the two
targets (Type I log 27 and Type II log c+15), separates quotient misses from
genuine H-lift defects, and quotients the latter by the automorphism x->11x.

The output is an exact finite-group computation.  It is not a finite prime
census and does not prove Erdős-Straus.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter, deque

MOD = 30
TYPE_I = 27
FORCED_LOG_2 = 24
FORCED_D = frozenset({0, 24, 18})
AUT = 11


def add_occurrence(D: frozenset[int], a: int) -> frozenset[int]:
    return frozenset((x + z * a) % MOD for x in D for z in (0, 1, 2))


def close_states() -> tuple[dict[tuple[frozenset[int], int], tuple[int, ...]], list[int]]:
    start = (FORCED_D, FORCED_LOG_2)
    witness: dict[tuple[frozenset[int], int], tuple[int, ...]] = {start: ()}
    frontier = {start}
    layer_sizes = [1]

    while frontier:
        new_frontier: set[tuple[frozenset[int], int]] = set()
        for D, c in frontier:
            w = witness[(D, c)]
            for a in range(MOD):
                state = (add_occurrence(D, a), (c + a) % MOD)
                if state not in witness:
                    witness[state] = w + (a,)
                    new_frontier.add(state)
        frontier = new_frontier
        if frontier:
            layer_sizes.append(len(witness))

    return witness, layer_sizes


def exact_miss(D: frozenset[int], c: int) -> bool:
    return TYPE_I not in D and ((c + 15) % MOD) not in D


def quotient_miss(D: frozenset[int], c: int) -> bool:
    U = {x % 6 for x in D}
    return 3 not in U and ((c + 15) % 6) not in U


def transform(D: frozenset[int], c: int) -> tuple[frozenset[int], int]:
    return frozenset((AUT * x) % MOD for x in D), (AUT * c) % MOD


def canonical(D: frozenset[int], c: int) -> tuple[tuple[int, ...], int]:
    D2, c2 = transform(D, c)
    k1 = (tuple(sorted(D)), c)
    k2 = (tuple(sorted(D2)), c2)
    return min(k1, k2)


def analyze() -> dict[str, object]:
    witness, layer_sizes = close_states()

    states = list(witness)
    misses = [(D, c) for D, c in states if exact_miss(D, c)]
    qmiss = [(D, c) for D, c in misses if quotient_miss(D, c)]
    lift = [(D, c) for D, c in misses if not quotient_miss(D, c)]

    # Fixed-point verification: every possible next occurrence remains inside
    # the closed state set.  This is the exhaustive closure certificate.
    state_set = set(states)
    transition_checks = 0
    for D, c in states:
        for a in range(MOD):
            transition_checks += 1
            nxt = (add_occurrence(D, a), (c + a) % MOD)
            if nxt not in state_set:
                raise AssertionError(f"state closure failed at c={c}, a={a}")

    orbits: dict[tuple[tuple[int, ...], int], list[tuple[frozenset[int], int]]] = {}
    for D, c in lift:
        key = canonical(D, c)
        orbits.setdefault(key, []).append((D, c))

    reps = []
    for key, members in sorted(orbits.items(), key=lambda kv: (len(kv[0][0]), kv[0][1], kv[0][0])):
        wanted_D = frozenset(key[0])
        wanted_c = key[1]
        D, c = next((D, c) for D, c in members if D == wanted_D and c == wanted_c)
        missing = sorted(set(range(MOD)) - set(D))
        reps.append({
            "box_size": len(D),
            "c": c,
            "type_i_target": TYPE_I,
            "type_ii_target": (c + 15) % MOD,
            "missing_logs": missing,
            "minimal_additional_log_witness": list(witness[(D, c)]),
            "orbit_size": len(members),
        })

    return {
        "analysis": "k31-v2-one-exact-lift-classifier-v1",
        "group": "C30 base-3 logarithms modulo 31",
        "forced_state": {
            "divisor_logs": sorted(FORCED_D),
            "c": FORCED_LOG_2,
        },
        "reachable_states": len(states),
        "closure_layer_cumulative_sizes": layer_sizes,
        "transition_closure_checks": transition_checks,
        "combined_miss_states": len(misses),
        "quotient_miss_states": len(qmiss),
        "lift_only_miss_states": len(lift),
        "lift_defect_orbits_under_x_to_11x": len(orbits),
        "lift_defect_representatives": reps,
        "miss_box_size_histogram": dict(sorted(Counter(len(D) for D, _ in misses).items())),
        "lift_box_size_histogram": dict(sorted(Counter(len(D) for D, _ in lift).items())),
        "claim": "exact finite-group state closure; not a prime-range census",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
