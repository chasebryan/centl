#!/usr/bin/env python3
"""Verify the first reduced symbolic dependency grammar for realized h169 pair routes."""
from __future__ import annotations

import argparse
import json
import math
from fractions import Fraction
from itertools import product

S19 = frozenset({0, 2, 7, 8, 11, 14, 15, 16, 17})
S31 = frozenset({0, 2, 6, 7, 8, 9, 11, 12, 14, 15, 19, 22, 27, 28, 29})
BARE31_PHASES = frozenset({0, 19, 29})
M19 = ("BARE", "FULL_QR")
M31 = ("BARE", "FULL_QR")
M47 = ("THIN", "FULL_QR")
K35 = ("J_ONLY", "S7_ONLY", "BOTH")


def seam_from_tau4(tau4: int) -> dict[str, int | str]:
    assert tau4 in range(4)
    if tau4 == 0:
        return {"name": "EVEN_0", "B-G": 2, "G-L": 2, "B-L": 4, "D-J": 1}
    if tau4 == 2:
        return {"name": "EVEN_2", "B-G": 2, "G-L": 2, "B-L": 2, "D-J": 1}
    return {"name": "ODD", "B-G": 1, "G-L": 1, "B-L": 1, "D-J": 2}


def v3_bucket(tau9: int) -> str:
    if tau9 == 4:
        return "GE2"
    if tau9 in {1, 7}:
        return "EQ1"
    return "ZERO"


def allowed_route_a(row: tuple[int, int, int, int, str, str, str]) -> bool:
    tau19, tau31, tau4, tau9, m19, m31, k35 = row
    if m19 == "BARE" and tau19 != 2:
        return False
    if m31 == "BARE" and not (tau31 in BARE31_PHASES and tau4 % 2 == 0):
        return False
    if tau9 == 4 and k35 != "J_ONLY":
        return False
    return True


def allowed_route_b(row: tuple[int, int, int, int, str, str, str, str]) -> bool:
    tau19, tau31, tau4, tau9, m19, m31, m47, k35 = row
    if m19 == "BARE" and tau19 != 8:
        return False
    if m31 == "BARE" and not (tau31 in BARE31_PHASES and tau4 % 2 == 0):
        return False
    if m47 == "THIN" and tau4 % 2 != 0:
        return False
    if tau4 % 2 and (m31 != "FULL_QR" or m47 != "FULL_QR"):
        return False
    if tau9 == 4 and k35 != "J_ONLY":
        return False
    return True


def count_route_a() -> dict[str, object]:
    rows = product(S19, S31, range(4), range(9), M19, M31, K35)
    naive = 0
    allowed = 0
    by_seam = {"EVEN_0": 0, "EVEN_2": 0, "ODD": 0}
    for row in rows:
        naive += 1
        if allowed_route_a(row):
            allowed += 1
            by_seam[str(seam_from_tau4(row[2])["name"])] += 1
    assert naive == 58_320
    assert allowed == 16_500
    frac = Fraction(allowed, naive)
    assert frac == Fraction(275, 972)
    return {
        "naive_formal_tuples": naive,
        "not_excluded_formal_tuples": allowed,
        "compression_fraction": f"{frac.numerator}/{frac.denominator}",
        "compression_decimal": float(frac),
        "not_excluded_by_seam": by_seam,
    }


def count_route_b() -> dict[str, object]:
    rows = product(S19, S31, range(4), range(9), M19, M31, M47, K35)
    naive = 0
    allowed = 0
    by_seam = {"EVEN_0": 0, "EVEN_2": 0, "ODD": 0}
    odd_pairs = set()
    for row in rows:
        naive += 1
        if allowed_route_b(row):
            allowed += 1
            seam_name = str(seam_from_tau4(row[2])["name"])
            by_seam[seam_name] += 1
            if seam_name == "ODD":
                odd_pairs.add((row[5], row[6]))
    assert naive == 116_640
    assert allowed == 25_500
    assert odd_pairs == {("FULL_QR", "FULL_QR")}
    frac = Fraction(allowed, naive)
    assert frac == Fraction(425, 1944)
    return {
        "naive_formal_tuples": naive,
        "not_excluded_formal_tuples": allowed,
        "compression_fraction": f"{frac.numerator}/{frac.denominator}",
        "compression_decimal": float(frac),
        "not_excluded_by_seam": by_seam,
        "odd_seam_mode_pairs": [list(x) for x in sorted(odd_pairs)],
    }


def verify_block_counts() -> dict[str, object]:
    # k19: nine FULL_QR center phases plus one route-specific BARE phase.
    assert 9 * 2 == 18
    k19_allowed = 9 + 1
    assert k19_allowed == 10

    # Route-A k31 block.
    k31_naive = 15 * 4 * 2
    k31_allowed = 15 * 4 + 3 * 2
    assert (k31_naive, k31_allowed) == (120, 66)

    # Route-B joint k31/k47 block.
    joint_naive = 15 * 4 * 2 * 2
    odd = 15 * 2  # only FULL/FULL on two odd tau4 values
    even_bare_phases = 3 * 2 * 4
    even_other_phases = 12 * 2 * 2
    joint_allowed = odd + even_bare_phases + even_other_phases
    assert (joint_naive, joint_allowed) == (240, 102)

    # k35 branch/phase block.
    k35_naive = 9 * 3
    k35_allowed = 8 * 3 + 1
    assert (k35_naive, k35_allowed) == (27, 25)

    assert k19_allowed * k31_allowed * k35_allowed == 16_500
    assert k19_allowed * joint_allowed * k35_allowed == 25_500

    return {
        "k19": {"naive": 18, "not_excluded": 10},
        "route_a_k31": {"naive": 120, "not_excluded": 66},
        "route_b_joint_k31_k47": {"naive": 240, "not_excluded": 102},
        "k35": {"naive": 27, "not_excluded": 25},
    }


def verify_derived_coordinates() -> dict[str, object]:
    seams = {i: seam_from_tau4(i) for i in range(4)}
    assert seams[0]["D-J"] == 1 and seams[0]["B-L"] == 4
    assert seams[2]["D-J"] == 1 and seams[2]["B-L"] == 2
    assert seams[1]["D-J"] == 2 and seams[3]["D-J"] == 2

    buckets = {i: v3_bucket(i) for i in range(9)}
    assert buckets[4] == "GE2"
    assert buckets[1] == buckets[7] == "EQ1"
    assert all(buckets[i] == "ZERO" for i in {0, 2, 3, 5, 6, 8})

    # Direct arithmetic regression of the derived maps.
    for t in range(4 * 9 * 31):
        B = 8 + 35 * t
        D = 5 + 21 * t
        G = 26 + 105 * t
        J = 9 + 35 * t
        L = 4 + 15 * t
        seam = seam_from_tau4(t % 4)
        assert math.gcd(B, G) == seam["B-G"]
        assert math.gcd(G, L) == seam["G-L"]
        assert math.gcd(B, L) == seam["B-L"]
        assert math.gcd(D, J) == seam["D-J"]
        f = 17 + 70 * t
        bucket = v3_bucket(t % 9)
        if bucket == "ZERO":
            assert f % 3 != 0
        elif bucket == "EQ1":
            assert f % 3 == 0 and f % 9 != 0
        else:
            assert f % 9 == 0

    return {
        "seam_is_function_of_tau4": True,
        "k35_3adic_bucket_is_function_of_tau9": True,
        "arithmetic_t_values_checked": 4 * 9 * 31,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "h169-reduced-dependency-grammar-v1",
        "S19": sorted(S19),
        "S31": sorted(S31),
        "derived_coordinates": verify_derived_coordinates(),
        "block_counts": verify_block_counts(),
        "route_a": count_route_a(),
        "route_b": count_route_b(),
        "failures": 0,
        "claim": (
            "composition of landed exact implications reduces the first coarse formal h169 "
            "phase/mode product from 58,320 to 16,500 not-excluded tuples on Route A and "
            "from 116,640 to 25,500 on Route B; these are symbolic grammar counts, not "
            "counts of actual arithmetic survivors"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
