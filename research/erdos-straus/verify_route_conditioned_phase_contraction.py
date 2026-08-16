#!/usr/bin/env python3
"""Verify k31 and realized-route phase-volume refinements."""
from __future__ import annotations

import argparse
import json
import math
from fractions import Fraction

QR19 = frozenset(pow(x, 2, 19) for x in range(1, 19))
QR31 = frozenset(pow(x, 2, 31) for x in range(1, 31))

S19 = frozenset(t for t in range(19) if (17 + 4 * t) % 19 in QR19)
S31 = frozenset(t for t in range(31) if (5 + 21 * t) % 31 in QR31)
S39 = frozenset({1, 2, 5, 6, 7, 8, 9, 10, 11})
S43 = frozenset(set(range(43)) - {2, 28, 30})
S47 = frozenset(set(range(47)) - {1, 5, 6, 10, 13, 21, 23, 36, 37, 38, 40, 42, 44})
S51 = frozenset(set(range(17)) - {4, 5, 7, 14})
S55 = frozenset(set(range(11)) - {5, 6, 7, 10})

EXPECTED_S19 = frozenset({0, 2, 7, 8, 11, 14, 15, 16, 17})
EXPECTED_S31 = frozenset({0, 2, 6, 7, 8, 9, 11, 12, 14, 15, 19, 22, 27, 28, 29})


def assert_pairwise_coprime(values: tuple[int, ...]) -> None:
    for i, a in enumerate(values):
        for b in values[i + 1 :]:
            assert math.gcd(a, b) == 1, (a, b)


def general_volume() -> dict[str, object]:
    moduli = (31, 13, 43, 47, 17, 11)
    sizes = (len(S31), len(S39), len(S43), len(S47), len(S51), len(S55))
    assert sizes == (15, 9, 40, 34, 13, 7)
    assert_pairwise_coprime(moduli)

    modulus = math.prod(moduli)
    survivors = math.prod(sizes)
    excluded = modulus - survivors
    fraction = Fraction(survivors, modulus)

    assert modulus == 152_304_581
    assert survivors == 16_707_600
    assert excluded == 135_596_981
    assert math.gcd(survivors, modulus) == 221
    assert fraction == Fraction(75_600, 689_161)

    return {
        "moduli": list(moduli),
        "survivor_sizes": list(sizes),
        "phase_modulus": modulus,
        "survivor_classes": survivors,
        "excluded_classes": excluded,
        "raw_class_ratio": f"{survivors}/{modulus}",
        "reduced_fraction": f"{fraction.numerator}/{fraction.denominator}",
        "survivor_fraction": float(fraction),
        "excluded_fraction": float(1 - fraction),
    }


def route_a_volume() -> dict[str, object]:
    S = 391
    t0 = 199
    assert 47 + 210 * t0 == S * 107
    assert t0 % 17 == 12
    assert t0 % 23 == 15
    assert 12 in S51

    moduli = (19, 31, 13, 43, 47, 11)
    sizes = (len(S19), len(S31), len(S39), len(S43), len(S47), len(S55))
    assert sizes == (9, 15, 9, 40, 34, 7)
    assert_pairwise_coprime(moduli)
    assert all(math.gcd(S, m) == 1 for m in moduli)

    modulus = math.prod(moduli)
    survivors = math.prod(sizes)
    fraction = Fraction(survivors, modulus)

    assert modulus == 170_222_767
    assert survivors == 11_566_800
    assert math.gcd(survivors, modulus) == 1
    assert fraction == Fraction(11_566_800, 170_222_767)

    assert (17 + 4 * 2) % 19 == 6
    assert 2 in S19

    return {
        "route": "A",
        "route_modulus": S,
        "route_t_phase": t0,
        "fixed_mod17": 12,
        "fixed_mod23": 15,
        "independent_moduli": list(moduli),
        "survivor_sizes": list(sizes),
        "phase_modulus": modulus,
        "survivor_classes": survivors,
        "raw_class_ratio": f"{survivors}/{modulus}",
        "reduced_fraction": f"{fraction.numerator}/{fraction.denominator}",
        "survivor_fraction": float(fraction),
        "excluded_fraction": float(1 - fraction),
    }


def route_b_volume() -> dict[str, object]:
    S = 1081
    t0 = 705
    assert 47 + 210 * t0 == S * 137
    assert t0 % 23 == 15
    assert t0 % 47 == 0
    assert 0 in S47

    moduli = (19, 31, 13, 43, 17, 11)
    sizes = (len(S19), len(S31), len(S39), len(S43), len(S51), len(S55))
    assert sizes == (9, 15, 9, 40, 13, 7)
    assert_pairwise_coprime(moduli)
    assert all(math.gcd(S, m) == 1 for m in moduli)

    modulus = math.prod(moduli)
    survivors = math.prod(sizes)
    fraction = Fraction(survivors, modulus)

    assert modulus == 61_569_937
    assert survivors == 4_422_600
    assert math.gcd(survivors, modulus) == 13
    assert fraction == Fraction(340_200, 4_736_149)

    assert (17 + 4 * 8) % 19 == 11
    assert 8 in S19

    return {
        "route": "B",
        "route_modulus": S,
        "route_t_phase": t0,
        "fixed_mod23": 15,
        "fixed_mod47": 0,
        "independent_moduli": list(moduli),
        "survivor_sizes": list(sizes),
        "phase_modulus": modulus,
        "survivor_classes": survivors,
        "raw_class_ratio": f"{survivors}/{modulus}",
        "reduced_fraction": f"{fraction.numerator}/{fraction.denominator}",
        "survivor_fraction": float(fraction),
        "excluded_fraction": float(1 - fraction),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert QR19 == frozenset({1, 4, 5, 6, 7, 9, 11, 16, 17})
    assert QR31 == frozenset({1, 2, 4, 5, 7, 8, 9, 10, 14, 16, 18, 19, 20, 25, 28})
    assert S19 == EXPECTED_S19
    assert S31 == EXPECTED_S31

    report = {
        "analysis": "route-conditioned-phase-contraction-v1",
        "k19_pair_route_survivor_phases_mod19": sorted(S19),
        "k31_survivor_phases_mod31": sorted(S31),
        "general_h169_k31_through_k55": general_volume(),
        "route_a": route_a_volume(),
        "route_b": route_b_volume(),
        "failures": 0,
        "claim": (
            "k31 refines the general h169 phase-only survivor fraction through k55 to about 10.97%; "
            "conditioning further on realized k19 pair-route ancestry and its QR19 center restriction "
            "leaves about 6.80% of Route-A and 7.18% of Route-B independent phase space"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
