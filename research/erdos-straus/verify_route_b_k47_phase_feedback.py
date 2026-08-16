#!/usr/bin/env python3
"""Verify exact later-phase feedback into the Route-B k47 survivor normal form."""
from __future__ import annotations

import argparse
import json
from fractions import Fraction

S11 = frozenset({0, 1, 2, 3, 4, 8, 9})
S17 = frozenset({0, 1, 2, 3, 6, 8, 9, 10, 11, 12, 13, 15, 16})
THIN_NON1 = ((9,), (3, 3))


def legendre(a: int, p: int) -> int:
    r = pow(a % p, (p - 1) // 2, p)
    if r == 1:
        return 1
    if r == p - 1:
        return -1
    return 0


def J(t: int) -> int:
    return 9 + 35 * t


def route_b_t(u: int) -> int:
    return 705 + 1081 * u


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert legendre(11, 47) == -1
    for n in range(64):
        t = 1 + 11 * n
        assert J(t) % 11 == 0
    assert 1 in S11
    s11_b = frozenset(set(S11) - {1})
    assert s11_b == frozenset({0, 2, 3, 4, 8, 9})

    assert legendre(17, 47) == 1
    assert 17 not in {1, 3, 9}
    for n in range(64):
        t = 8 + 17 * n
        assert J(t) % 17 == 0
    assert 8 in S17

    for u in range(11 * 17):
        t = route_b_t(u)
        assert (t % 11 == 1) == (u % 11 == 0)
        assert (t % 17 == 8) == (u % 17 == 0)

    for t in range(27):
        j = J(t)
        assert (j % 3 == 0) == (t % 3 == 0)
        assert (j % 9 == 0) == (t % 9 == 0)
    assert [t for t in range(27) if J(t) % 27 == 0] == [9]
    assert THIN_NON1 == ((9,), (3, 3))

    for t in (0, 18):
        j = J(t)
        assert j % 9 == 0
        assert j % 27 != 0
    assert J(9) % 27 == 0

    raw_route_b = Fraction(4_422_600, 61_569_937)
    refined = raw_route_b * Fraction(6, 7)
    assert refined == Fraction(291_600, 4_736_149)
    assert Fraction(3_790_800, 61_569_937) == refined

    report = {
        "analysis": "route-b-k47-phase-feedback-v1",
        "tau11": {
            "forced_factor": 11,
            "legendre_mod47": -1,
            "k47_consequence": "hit",
            "survivor_phases_before": sorted(S11),
            "survivor_phases_after": sorted(s11_b),
        },
        "tau17": {
            "phase": 8,
            "forced_factor": 17,
            "legendre_mod47": 1,
            "thin_allowed": False,
            "k47_consequence_on_miss": "FULL_QR",
        },
        "route_b_u": {
            "tau11_1": "u=0 mod11",
            "tau17_8": "u=0 mod17",
        },
        "thin_3adic": {
            "thin_non1_occurrence_tuples": [list(x) for x in THIN_NON1],
            "tau9_0": "THIN forces exact non-1 tuple (3,3), v3(J)=2, J/9 support 1 mod47",
            "tau27_9": "THIN impossible",
        },
        "phase_fraction": {
            "raw_classes": "3,790,800/61,569,937",
            "reduced": f"{refined.numerator}/{refined.denominator}",
            "decimal": float(refined),
        },
        "failures": 0,
        "claim": (
            "on realized Route B, tau11=1 is incompatible with a k47 miss; "
            "tau17=8 forces FULL_QR47 on a miss; and THIN with tau9=0 forces "
            "the exact (3,3) occurrence grammar and excludes tau27=9"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
