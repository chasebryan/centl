#!/usr/bin/env python3
"""Audit full signed-box ancestry for the q23 blocked-phase atlas.

The parent atlas classifies the destination k_n on exact route-phase
progressions after requiring k19/k23 survival. This audit asks the stronger
framework question: does a candidate actually survive every admissible
signed-box shift between k23 and k_n?

For each parent prefix it exhausts the same progression, keeps only prime
simultaneous k19/k23 survivors, and records the first exact post-k23 hit.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

from analyze_q23_blocked_phase_geometry import (
    BLOCKED_PHASES,
    EXPECTED,
    ROUTES,
    phase_progression,
    type_ii_geometry,
)
from verify_q23_square_lift_phase_sieve import (
    fixed_shift_status,
    is_prime,
    k_of,
    sieve,
)

EXPECTED_CELL = {
    "q17-q23": {
        1: (10, 2, {31: 2}),
        2: (13, 4, {31: 4}),
        4: (61, 12, {27: 6, 31: 3, 39: 1, 43: 1, 47: 1}),
        7: (13, 2, {31: 2}),
        9: (62, 12, {27: 3, 31: 7, 35: 1, 39: 1}),
        10: (37, 9, {27: 5, 31: 3, 43: 1}),
        13: (59, 7, {27: 4, 31: 3}),
        16: (2, 1, {31: 1}),
        19: (14, 4, {27: 1, 31: 2, 43: 1}),
        22: (115, 19, {27: 12, 31: 7}),
    },
    "q23-q47": {
        1: (5, 2, {27: 1, 31: 1}),
        2: (3, 1, {27: 1}),
        4: (39, 7, {27: 2, 31: 2, 35: 2, 39: 1}),
        7: (56, 8, {27: 2, 31: 5, 47: 1}),
        9: (99, 17, {27: 7, 31: 7, 35: 1, 39: 1, 55: 1}),
        10: (38, 8, {27: 3, 31: 4, 47: 1}),
        13: (66, 6, {27: 3, 31: 2, 35: 1}),
        16: (6, 2, {27: 1, 31: 1}),
        19: (87, 16, {27: 8, 31: 6, 35: 1, 43: 1}),
        22: (29, 9, {27: 5, 31: 2, 35: 1, 43: 1}),
    },
}

EXPECTED_TOTAL_PRIMES = 814
EXPECTED_TOTAL_SIMULTANEOUS = 148
EXPECTED_FIRST_HIT_HISTOGRAM = {
    27: 64,
    31: 64,
    35: 7,
    39: 4,
    43: 5,
    47: 3,
    55: 1,
}
EXPECTED_MECHANISMS = {
    "both": 122,
    "type-I-only": 20,
    "type-II-only": 6,
}
EXPECTED_GEOMETRY = {
    "boundary-only": 16,
    "interior-only": 49,
    "mixed": 63,
    "n/a": 20,
}


def mechanism(type_i: bool, type_ii: bool) -> str:
    if type_i and type_ii:
        return "both"
    if type_i:
        return "type-I-only"
    if type_ii:
        return "type-II-only"
    return "miss"


def first_post23_hit(
    p: int, destination_k: int, primes: list[int]
) -> dict[str, object] | None:
    """Return the earliest admissible signed-box hit after k23."""
    for k in range(27, destination_k + 1, 4):
        miss, type_i, type_ii, factors = fixed_shift_status(p, k, primes)
        if miss:
            continue
        C = (p + k) // 4
        if type_ii:
            geometry = type_ii_geometry(factors, k, C)
        else:
            geometry = {
                "witness_count": 0,
                "region": "n/a",
                "boundary_witness": None,
                "interior_witness": None,
            }
        return {
            "k": k,
            "C": C,
            "mechanism": mechanism(type_i, type_ii),
            "type_i": type_i,
            "type_ii": type_ii,
            "type_ii_geometry": geometry,
        }
    return None


def audit_cell(route, n: int, primes: list[int]) -> dict[str, object]:
    destination_p, _parent_mech, _parent_region = EXPECTED[route.name][n]
    destination_k = k_of(n)
    residue, modulus = phase_progression(n, route)
    p0 = residue if residue >= 2 else residue + modulus

    prime_candidates = 0
    simultaneous = 0
    first_hit_hist = Counter()
    mechanisms = Counter()
    geometry = Counter()
    persistent_to_destination: list[int] = []

    p = p0
    while p <= destination_p:
        if is_prime(p):
            prime_candidates += 1
            miss19, _i19, _ii19, _f19 = fixed_shift_status(p, 19, primes)
            miss23, _i23, _ii23, _f23 = fixed_shift_status(p, 23, primes)
            if miss19 and miss23:
                simultaneous += 1
                first = first_post23_hit(p, destination_k, primes)
                assert first is not None
                first_k = int(first["k"])
                first_hit_hist[first_k] += 1
                mechanisms[str(first["mechanism"])] += 1
                g = first["type_ii_geometry"]
                assert isinstance(g, dict)
                geometry[str(g["region"])] += 1
                if first_k == destination_k:
                    persistent_to_destination.append(p)
                else:
                    assert first_k < destination_k
        p += modulus

    expected_primes, expected_simultaneous, expected_hist = EXPECTED_CELL[route.name][n]
    assert prime_candidates == expected_primes
    assert simultaneous == expected_simultaneous
    assert dict(sorted(first_hit_hist.items())) == expected_hist
    assert not persistent_to_destination

    return {
        "route": route.name,
        "phase_n": n,
        "destination_k": destination_k,
        "parent_destination_anchor_p": destination_p,
        "prime_candidates_through_parent_anchor": prime_candidates,
        "simultaneous_k19_k23_survivors": simultaneous,
        "first_post23_hit_histogram": dict(sorted(first_hit_hist.items())),
        "mechanism_counts": dict(sorted(mechanisms.items())),
        "type_ii_geometry_counts": dict(sorted(geometry.items())),
        "persistent_to_parent_destination": persistent_to_destination,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    max_p = max(row[0] for table in EXPECTED.values() for row in table.values())
    max_k = max(k_of(n) for n in BLOCKED_PHASES)
    primes = sieve(math.isqrt((max_p + max_k) // 4) + 1)

    cells = [
        audit_cell(route, n, primes)
        for route in ROUTES
        for n in BLOCKED_PHASES
    ]

    total_primes = sum(int(cell["prime_candidates_through_parent_anchor"]) for cell in cells)
    total_simultaneous = sum(int(cell["simultaneous_k19_k23_survivors"]) for cell in cells)
    first_hits = Counter()
    mechanisms = Counter()
    geometry = Counter()
    for cell in cells:
        first_hits.update({int(k): int(v) for k, v in cell["first_post23_hit_histogram"].items()})
        mechanisms.update({str(k): int(v) for k, v in cell["mechanism_counts"].items()})
        geometry.update({str(k): int(v) for k, v in cell["type_ii_geometry_counts"].items()})

    assert total_primes == EXPECTED_TOTAL_PRIMES
    assert total_simultaneous == EXPECTED_TOTAL_SIMULTANEOUS
    assert dict(sorted(first_hits.items())) == EXPECTED_FIRST_HIT_HISTOGRAM
    assert dict(sorted(mechanisms.items())) == EXPECTED_MECHANISMS
    assert dict(sorted(geometry.items())) == EXPECTED_GEOMETRY
    assert max(first_hits) == 55
    assert all(not cell["persistent_to_parent_destination"] for cell in cells)

    report = {
        "analysis": "q23-blocked-phase-full-ancestry-audit-v1",
        "parent_prefix_prime_candidates": total_primes,
        "simultaneous_k19_k23_survivors": total_simultaneous,
        "first_post23_hit_histogram": dict(sorted(first_hits.items())),
        "maximum_first_post23_hit_k": max(first_hits),
        "mechanism_counts": dict(sorted(mechanisms.items())),
        "type_ii_geometry_counts": dict(sorted(geometry.items())),
        "persistent_to_blocked_phase_destination": 0,
        "cells": cells,
        "failures": 0,
        "claim": (
            "finite exact ancestry audit over the parent blocked-phase atlas prefixes: "
            "every simultaneous k19/k23 survivor terminates before its phase destination, "
            "with first post-k23 hit at k<=55"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
