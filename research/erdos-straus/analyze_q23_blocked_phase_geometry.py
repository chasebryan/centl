#!/usr/bin/env python3
"""Exact finite atlas of replacement signed-box geometry on blocked q23 phases.

For each of the ten q23 phases where the canonical d=23^2 Type-II
certificate is arithmetically blocked on h169, and for each of the two
realized k19 route families, this script:

1. derives the complete arithmetic progression of p with the required hard
   class, route residue, and q23^2 lift phase;
2. enumerates every candidate through a pinned first replacement hit;
3. tests primality exactly for uint64 values;
4. requires simultaneous k19 and k23 signed-box survival;
5. evaluates the complete destination signed box at k_n=19+92n; and
6. classifies every Type-II destination witness as Lopez-comparable or
   incomparable in canonical root coordinates.

The result is a finite exact atlas, not an asymptotic theorem.
"""
from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass

from verify_q23_square_lift_phase_sieve import (
    H,
    Q,
    Q2,
    factor,
    fixed_shift_status,
    is_prime,
    k_of,
    sieve,
)

BLOCKED_PHASES = (1, 2, 4, 7, 9, 10, 13, 16, 19, 22)
LIFT_MODULUS = 4 * Q2


@dataclass(frozen=True)
class Route:
    name: str
    source_q: int
    source_residue: int


ROUTES = (
    Route("q17-q23", 17, 15),
    Route("q23-q47", 47, 28),
)

# Pinned earliest complete-signed-box replacement hits after simultaneous
# k19/k23 survival on each blocked phase progression.
EXPECTED = {
    "q17-q23": {
        1:  (288_537_649, "both",         "mixed"),
        2:  (382_143_049, "type-II-only", "interior-only"),
        4:  (2_246_368_489, "type-I-only",  "n/a"),
        7:  (457_355_809, "type-II-only", "interior-only"),
        9:  (2_019_416_449, "type-II-only", "boundary-only"),
        10: (1_108_323_889, "type-I-only",  "n/a"),
        13: (1_842_387_289, "type-I-only",  "n/a"),
        16: (8_049_889, "type-II-only", "boundary-only"),
        19: (341_744_929, "type-II-only", "interior-only"),
        22: (3_840_616_249, "type-II-only", "interior-only"),
    },
    "q23-q47": {
        1:  (209_441_569, "both",         "mixed"),
        2:  (118_637_569, "both",         "boundary-only"),
        4:  (3_362_156_449, "type-II-only", "boundary-only"),
        7:  (5_763_014_209, "type-I-only",  "n/a"),
        9:  (9_090_072_769, "type-I-only",  "n/a"),
        10: (3_590_074_489, "type-I-only",  "n/a"),
        13: (6_366_860_809, "type-II-only", "interior-only"),
        16: (580_829_929, "type-I-only",  "n/a"),
        19: (8_328_227_209, "type-I-only",  "n/a"),
        22: (2_124_497_929, "type-I-only",  "n/a"),
    },
}


def crt_pair(a: int, m: int, b: int, n: int) -> tuple[int, int]:
    """Generalized CRT for one compatible pair."""
    g = math.gcd(m, n)
    if (b - a) % g:
        raise ValueError(f"incompatible CRT: {a} mod {m}, {b} mod {n}")
    m1 = m // g
    n1 = n // g
    t = ((b - a) // g * pow(m1, -1, n1)) % n1
    modulus = m * n1
    return (a + m * t) % modulus, modulus


def phase_progression(n: int, route: Route) -> tuple[int, int]:
    """All p on one exact q23^2 lift phase and route.

    q23^2 | C_{k_n} is equivalent to p == -k_n (mod 4*23^2).
    We intersect that with h169 mod840 and the route source residue.
    """
    k = k_of(n)
    a, m = crt_pair(H, 840, (-k) % LIFT_MODULUS, LIFT_MODULUS)
    return crt_pair(a, m, route.source_residue, route.source_q)


def mechanism(type_i: bool, type_ii: bool) -> str:
    if type_i and type_ii:
        return "both"
    if type_i:
        return "type-I-only"
    if type_ii:
        return "type-II-only"
    return "miss"


def type_ii_geometry(
    factors: dict[int, int], k: int, C: int
) -> dict[str, object]:
    target = (-C) % k
    items = sorted((int(q), int(e)) for q, e in factors.items())
    count = 0
    has_boundary = False
    has_interior = False
    boundary_witness: tuple[int, int, int] | None = None
    interior_witness: tuple[int, int, int] | None = None

    def visit(i: int, d_mod: int, s: int, b: int, c: int) -> None:
        nonlocal count, has_boundary, has_interior
        nonlocal boundary_witness, interior_witness
        if i == len(items):
            if d_mod != target:
                return
            count += 1
            witness = (s, b, c)
            assert s * b * c == C
            if c % b == 0 or b % c == 0:
                has_boundary = True
                if boundary_witness is None or witness < boundary_witness:
                    boundary_witness = witness
            else:
                has_interior = True
                if interior_witness is None or witness < interior_witness:
                    interior_witness = witness
            return

        q, e = items[i]
        q_mod_power = 1 % k
        for u in range(2 * e + 1):
            parity = u & 1
            beta = (u - parity) // 2
            gamma = (2 * e - u - parity) // 2
            visit(
                i + 1,
                d_mod * q_mod_power % k,
                s * q**parity,
                b * q**beta,
                c * q**gamma,
            )
            q_mod_power = q_mod_power * (q % k) % k

    visit(0, 1 % k, 1, 1, 1)

    if has_boundary and has_interior:
        region = "mixed"
    elif has_boundary:
        region = "boundary-only"
    elif has_interior:
        region = "interior-only"
    else:
        region = "n/a"

    def show(w: tuple[int, int, int] | None):
        if w is None:
            return None
        return {"s": w[0], "b": w[1], "c": w[2]}

    return {
        "witness_count": count,
        "region": region,
        "boundary_witness": show(boundary_witness),
        "interior_witness": show(interior_witness),
    }


def destination_status(p: int, n: int, primes: list[int]) -> dict[str, object]:
    k = k_of(n)
    C = (p + k) // 4
    miss, type_i, type_ii, factors = fixed_shift_status(p, k, primes)
    out: dict[str, object] = {
        "p": p,
        "phase_n": n,
        "k": k,
        "C": C,
        "factorization": factors,
        "type_i": type_i,
        "type_ii": type_ii,
        "mechanism": mechanism(type_i, type_ii),
        "canonical_d_q2_blocked": Q2 % k != (-C) % k,
    }
    assert out["canonical_d_q2_blocked"] is True
    if type_ii:
        out["type_ii_geometry"] = type_ii_geometry(factors, k, C)
    else:
        out["type_ii_geometry"] = {
            "witness_count": 0,
            "region": "n/a",
            "boundary_witness": None,
            "interior_witness": None,
        }
    if miss:
        assert out["mechanism"] == "miss"
    return out


def verify_cell(route: Route, n: int, primes: list[int]) -> dict[str, object]:
    expected_p, expected_mechanism, expected_region = EXPECTED[route.name][n]
    residue, modulus = phase_progression(n, route)
    p0 = residue if residue >= 2 else residue + modulus

    candidates = 0
    primes_seen = 0
    simultaneous_survivors = 0
    earlier_destination_misses = 0
    found: dict[str, object] | None = None

    p = p0
    while p <= expected_p:
        candidates += 1
        if is_prime(p):
            primes_seen += 1
            assert p % 840 == H
            assert p % route.source_q == route.source_residue
            k = k_of(n)
            assert (p + k) % LIFT_MODULUS == 0
            C19 = (p + 19) // 4
            assert C19 % Q == 0
            M = C19 // Q
            assert (-M) % Q == n

            miss19, _i19, _ii19, _f19 = fixed_shift_status(p, 19, primes)
            miss23, _i23, _ii23, _f23 = fixed_shift_status(p, 23, primes)
            if miss19 and miss23:
                simultaneous_survivors += 1
                status = destination_status(p, n, primes)
                if status["mechanism"] == "miss":
                    earlier_destination_misses += 1
                else:
                    if p < expected_p:
                        raise AssertionError(
                            f"earlier replacement hit route={route.name} n={n}: {p}"
                        )
                    found = status
        p += modulus

    assert found is not None
    assert int(found["p"]) == expected_p
    assert found["mechanism"] == expected_mechanism
    geometry = found["type_ii_geometry"]
    assert isinstance(geometry, dict)
    assert geometry["region"] == expected_region

    return {
        "route": route.name,
        "phase_n": n,
        "k": k_of(n),
        "progression": {"residue": residue, "modulus": modulus},
        "candidates_through_first_hit": candidates,
        "prime_candidates_through_first_hit": primes_seen,
        "simultaneous_k19_k23_survivors_through_first_hit": simultaneous_survivors,
        "earlier_destination_misses": earlier_destination_misses,
        "first_replacement_hit": found,
    }


def summarize(cells: list[dict[str, object]]) -> dict[str, object]:
    mechanism_counts: dict[str, int] = {}
    geometry_counts: dict[str, int] = {}
    for cell in cells:
        hit = cell["first_replacement_hit"]
        assert isinstance(hit, dict)
        mech = str(hit["mechanism"])
        mechanism_counts[mech] = mechanism_counts.get(mech, 0) + 1
        geom = hit["type_ii_geometry"]
        assert isinstance(geom, dict)
        region = str(geom["region"])
        geometry_counts[region] = geometry_counts.get(region, 0) + 1
    return {
        "mechanism_counts": dict(sorted(mechanism_counts.items())),
        "type_ii_geometry_counts": dict(sorted(geometry_counts.items())),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert BLOCKED_PHASES == (1, 2, 4, 7, 9, 10, 13, 16, 19, 22)
    max_p = max(row[0] for table in EXPECTED.values() for row in table.values())
    max_k = max(k_of(n) for n in BLOCKED_PHASES)
    primes = sieve(math.isqrt((max_p + max_k) // 4) + 1)

    cells = [
        verify_cell(route, n, primes)
        for route in ROUTES
        for n in BLOCKED_PHASES
    ]
    report = {
        "analysis": "q23-blocked-phase-full-geometry-atlas-v1",
        "blocked_phases": list(BLOCKED_PHASES),
        "cells": cells,
        "summary": summarize(cells),
        "failures": 0,
        "claim": (
            "finite exact earliest replacement-hit atlas on the two realized h169 q23 "
            "square-lift route families after the canonical d=23^2 boundary certificate "
            "has been phase-blocked"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for cell in cells:
            hit = cell["first_replacement_hit"]
            assert isinstance(hit, dict)
            geom = hit["type_ii_geometry"]
            assert isinstance(geom, dict)
            print(
                f"{cell['route']} n={cell['phase_n']:2d} k={cell['k']:4d} "
                f"p={hit['p']:>10d} {hit['mechanism']:12s} {geom['region']}"
            )
        print(report["summary"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
