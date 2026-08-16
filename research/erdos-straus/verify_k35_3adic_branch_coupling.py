#!/usr/bin/env python3
"""Verify exact k35 survivor-branch coupling to the 3-adic phase of F."""
from __future__ import annotations

import argparse
import json

H35 = frozenset({1, 3, 4, 9, 11, 12, 13, 16, 17, 27, 29, 33})


def F(t: int) -> int:
    return 17 + 70 * t


def legendre(a: int, p: int) -> int:
    x = pow(a % p, (p - 1) // 2, p)
    return 1 if x == 1 else -1


def route_a_t(u: int) -> int:
    return 199 + 391 * u


def route_b_t(u: int) -> int:
    return 705 + 1081 * u


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    # Rational prime3 is the exceptional residue for S7 but remains J35-safe.
    assert 3 % 7 == 3
    assert legendre(3, 5) == -1
    assert legendre(3, 7) == -1
    assert legendre(3, 5) * legendre(3, 7) == 1
    assert 3 in H35

    rows = []
    for t in range(9):
        f = F(t)
        rows.append({
            "t_mod9": t,
            "F_mod9": f % 9,
            "divisible_by_3": f % 3 == 0,
            "divisible_by_9": f % 9 == 0,
        })

    assert [r["t_mod9"] for r in rows if r["divisible_by_3"]] == [1, 4, 7]
    assert [r["t_mod9"] for r in rows if r["divisible_by_9"]] == [4]
    assert F(1) % 9 == 6
    assert F(4) % 9 == 0
    assert F(7) % 9 == 3

    # At t=1,7 mod9 the 3-adic valuation is exactly one.
    assert F(1) % 3 == 0 and F(1) % 9 != 0
    assert F(7) % 3 == 0 and F(7) % 9 != 0

    # At t=4 mod9 the factor occurrence 3 appears at least twice, which is
    # incompatible with S7's exact-one occurrence in residue class3 mod7.
    for n in range(60):
        t = 4 + 9 * n
        assert F(t) % 9 == 0
        assert F(t) % 3 == 0

    # Route-local phase maps.
    route_a_forced_j = []
    route_a_single3_s7 = []
    route_b_forced_j = []
    route_b_single3_s7 = []
    for u in range(9):
        ta = route_a_t(u) % 9
        tb = route_b_t(u) % 9
        assert ta == (1 + 4 * u) % 9
        assert tb == (3 + u) % 9
        if ta == 4:
            route_a_forced_j.append(u)
        if ta in {1, 7}:
            route_a_single3_s7.append(u)
        if tb == 4:
            route_b_forced_j.append(u)
        if tb in {1, 7}:
            route_b_single3_s7.append(u)

    assert route_a_forced_j == [3]
    assert route_a_single3_s7 == [0, 6]
    assert route_b_forced_j == [1]
    assert route_b_single3_s7 == [4, 7]

    report = {
        "analysis": "k35-3adic-branch-coupling-v1",
        "F": "17+70t",
        "three_divides_F_t_mod9": [1, 4, 7],
        "nine_divides_F_t_mod9": [4],
        "s7_forbidden_t_mod9": [4],
        "single_three_s7_phases_mod9": [1, 7],
        "route_a": {
            "t_mod9": "1+4u",
            "forced_J35_u_mod9": [3],
            "S7_with_three_distinguished_u_mod9": [0, 6],
        },
        "route_b": {
            "t_mod9": "3+u",
            "forced_J35_u_mod9": [1],
            "S7_with_three_distinguished_u_mod9": [4, 7],
        },
        "three_in_H35": True,
        "failures": 0,
        "claim": (
            "9|F (equivalently t=4 mod9) makes S7 impossible, so a k35 miss is forced "
            "into J35; when t=1 or7 mod9 and S7 holds, rational prime3 is the unique "
            "distinguished 3-mod7 factor and F/3 has only 1-mod7 prime support"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
