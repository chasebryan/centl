#!/usr/bin/env python3
"""Verify the exact ten-cofactor odd-support separation theorem."""
from __future__ import annotations

import argparse
import json
import math
from itertools import combinations

NAMES = ("R", "B", "E", "D", "F", "G", "H", "J", "K", "L")
LATER = ("B", "E", "D", "F", "G", "H", "J", "K", "L")


def cofactor_values(t: int, S: int) -> dict[str, int]:
    x = 47 + 210 * t
    assert x % S == 0
    return {
        "R": x // S,
        "B": (x + 1) // 6,
        "E": (x + 2) // 7,
        "D": (x + 3) // 10,
        "F": (x + 4) // 3,
        "G": (x + 5) // 2,
        "H": x + 6,
        "J": (x + 7) // 6,
        "K": (x + 8) // 5,
        "L": (x + 9) // 14,
    }


def expected_gcd(a: str, b: str, t: int) -> int:
    pair = frozenset({a, b})
    if pair == frozenset({"B", "G"}):
        return math.gcd(2, t)
    if pair == frozenset({"G", "L"}):
        return math.gcd(2, t)
    if pair == frozenset({"D", "J"}):
        return math.gcd(2, t + 1)
    if pair == frozenset({"B", "L"}):
        return math.gcd(4, t)
    return 1


def verify_later_ladder() -> dict[str, object]:
    # B..L formulas and gcd pattern are route-independent. 840 samples cover
    # all parity/mod3/mod5/mod7 combinations used in the algebraic proof.
    checked = 0
    observed: dict[str, set[int]] = {}
    for t in range(840):
        x = 47 + 210 * t
        vals = {
            "B": 8 + 35 * t,
            "E": 7 + 30 * t,
            "D": 5 + 21 * t,
            "F": 17 + 70 * t,
            "G": 26 + 105 * t,
            "H": 53 + 210 * t,
            "J": 9 + 35 * t,
            "K": 11 + 42 * t,
            "L": 4 + 15 * t,
        }
        assert 6 * vals["B"] == x + 1
        assert 7 * vals["E"] == x + 2
        assert 10 * vals["D"] == x + 3
        assert 3 * vals["F"] == x + 4
        assert 2 * vals["G"] == x + 5
        assert vals["H"] == x + 6
        assert 6 * vals["J"] == x + 7
        assert 5 * vals["K"] == x + 8
        assert 14 * vals["L"] == x + 9

        # Exact affine bounds for the only possible 2-adic overlaps.
        assert vals["G"] - 3 * vals["B"] == 2
        assert 7 * vals["L"] - vals["G"] == 2
        assert 7 * vals["L"] - 3 * vals["B"] == 4
        assert 3 * vals["J"] - 5 * vals["D"] == 2

        for a, b in combinations(LATER, 2):
            g = math.gcd(vals[a], vals[b])
            assert g == expected_gcd(a, b, t), (t, a, b, g)
            observed.setdefault(f"{a}-{b}", set()).add(g)
            # Strong form: odd parts are always disjoint.
            assert g & (g - 1) == 0 if g > 0 else False
            assert g in {1, 2, 4}
            checked += 1

    nontrivial = {
        pair: sorted(gs)
        for pair, gs in observed.items()
        if gs != {1}
    }
    assert nontrivial == {
        "B-G": [1, 2],
        "B-L": [1, 2, 4],
        "D-J": [1, 2],
        "G-L": [1, 2],
    }
    return {
        "t_values_checked": 840,
        "pair_checks": checked,
        "nontrivial_gcd_pairs": nontrivial,
    }


def route_start(S: int) -> tuple[int, int]:
    t0 = (-47 * pow(210, -1, S)) % S
    R0 = (47 + 210 * t0) // S
    return t0, R0


def verify_route(S: int, expected_t0: int, expected_R0: int) -> dict[str, object]:
    t0, R0 = route_start(S)
    assert (t0, R0) == (expected_t0, expected_R0)
    assert R0 % 2 == 1
    assert R0 % 3 == 2
    assert R0 % 5 == 2
    assert R0 % 7 != 0

    pair_checks = 0
    for u in range(840):
        t = t0 + S * u
        vals = cofactor_values(t, S)
        assert vals["R"] == R0 + 210 * u
        assert vals["R"] % 2 == 1
        assert vals["R"] % 3 == 2
        assert vals["R"] % 5 == 2
        assert vals["R"] % 7 != 0

        # R is fully coprime to every later cofactor.
        for q in LATER:
            assert math.gcd(vals["R"], vals[q]) == 1
            pair_checks += 1

        # Entire ten-cofactor gcd graph matches the exact theorem.
        for a, b in combinations(NAMES, 2):
            g = math.gcd(vals[a], vals[b])
            assert g == expected_gcd(a, b, t), (S, u, t, a, b, g)
            # Removing powers of2 leaves pairwise-coprime odd supports.
            odd_g = g
            while odd_g % 2 == 0:
                odd_g //= 2
            assert odd_g == 1

    return {
        "S": S,
        "t0": t0,
        "R0": R0,
        "route_instances_checked": 840,
        "R_later_gcd_checks": pair_checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    later = verify_later_ladder()
    route_a = verify_route(391, 199, 107)
    route_b = verify_route(1081, 705, 137)

    report = {
        "analysis": "ten-cofactor-odd-support-separation-v1",
        "later_ladder": later,
        "route_a": route_a,
        "route_b": route_b,
        "exact_gcd_exceptions": {
            "B-G": "gcd(2,t)",
            "G-L": "gcd(2,t)",
            "D-J": "gcd(2,t+1)",
            "B-L": "gcd(4,t)",
        },
        "odd_parts_pairwise_coprime": True,
        "failures": 0,
        "claim": (
            "on both realized h169 k19 routes, the odd parts of "
            "R,B,E,D,F,G,H,J,K,L are pairwise coprime; only four exact "
            "2-adic gcd edges remain"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
