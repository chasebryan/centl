#!/usr/bin/env python3
"""Verify the k27-aware reduced symbolic dependency grammar for realized h169 pair routes."""
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
K27 = ("Q", "A", "B", "C", "D", "E", "F")
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


def allowed_route_a(
    row: tuple[int, int, int, int, str, str, str, str]
) -> bool:
    tau19, tau31, tau4, tau9, m19, k27, m31, k35 = row
    if m19 == "BARE" and tau19 != 2:
        return False
    if tau19 == 8 and k27 != "Q":
        return False
    if m31 == "BARE" and not (tau31 in BARE31_PHASES and tau4 % 2 == 0):
        return False
    if tau9 == 4 and k35 != "J_ONLY":
        return False
    return True


def allowed_route_b(
    row: tuple[int, int, int, int, str, str, str, str, str]
) -> bool:
    tau19, tau31, tau4, tau9, m19, k27, m31, m47, k35 = row
    if m19 == "BARE" and tau19 != 8:
        return False
    if tau19 == 8 and k27 != "Q":
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
    rows = product(S19, S31, range(4), range(9), M19, K27, M31, K35)
    naive = 0
    allowed = 0
    by_seam = {"EVEN_0": 0, "EVEN_2": 0, "ODD": 0}
    by_k27 = {m: 0 for m in K27}
    for row in rows:
        naive += 1
        if allowed_route_a(row):
            allowed += 1
            by_seam[str(seam_from_tau4(row[2])["name"])] += 1
            by_k27[row[5]] += 1
    assert naive == 408_240
    assert allowed == 105_600
    frac = Fraction(allowed, naive)
    assert frac == Fraction(440, 1701)
    return {
        "naive_formal_tuples": naive,
        "not_excluded_formal_tuples": allowed,
        "compression_fraction": f"{frac.numerator}/{frac.denominator}",
        "compression_decimal": float(frac),
        "not_excluded_by_seam": by_seam,
        "not_excluded_by_k27_mode": by_k27,
    }


def count_route_b() -> dict[str, object]:
    rows = product(S19, S31, range(4), range(9), M19, K27, M31, M47, K35)
    naive = 0
    allowed = 0
    by_seam = {"EVEN_0": 0, "EVEN_2": 0, "ODD": 0}
    by_k27 = {m: 0 for m in K27}
    odd_pairs = set()
    bare_k27_modes = set()
    phase8_k27_modes = set()
    for row in rows:
        naive += 1
        if allowed_route_b(row):
            allowed += 1
            seam_name = str(seam_from_tau4(row[2])["name"])
            by_seam[seam_name] += 1
            by_k27[row[5]] += 1
            if seam_name == "ODD":
                odd_pairs.add((row[6], row[7]))
            if row[4] == "BARE":
                bare_k27_modes.add(row[5])
            if row[0] == 8:
                phase8_k27_modes.add(row[5])
    assert naive == 816_480
    assert allowed == 147_900
    assert odd_pairs == {("FULL_QR", "FULL_QR")}
    assert bare_k27_modes == {"Q"}
    assert phase8_k27_modes == {"Q"}
    frac = Fraction(allowed, naive)
    assert frac == Fraction(2465, 13608)
    return {
        "naive_formal_tuples": naive,
        "not_excluded_formal_tuples": allowed,
        "compression_fraction": f"{frac.numerator}/{frac.denominator}",
        "compression_decimal": float(frac),
        "not_excluded_by_seam": by_seam,
        "not_excluded_by_k27_mode": by_k27,
        "odd_seam_mode_pairs": [list(x) for x in sorted(odd_pairs)],
        "route_b_bare_k27_modes": sorted(bare_k27_modes),
        "tau19_8_k27_modes": sorted(phase8_k27_modes),
    }


def verify_block_counts() -> dict[str, object]:
    # Route-A k19/k27 block.
    k19k27_naive = 9 * 2 * 7
    route_a_k19k27 = 1 + 14 + 49
    assert (k19k27_naive, route_a_k19k27) == (126, 64)

    # Route-B k19/k27 block: phase8 permits FULL_QR or BARE, but k27 is forced Q.
    route_b_k19k27 = 2 + 8 * 7
    assert route_b_k19k27 == 58

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

    assert route_a_k19k27 * k31_allowed * k35_allowed == 105_600
    assert route_b_k19k27 * joint_allowed * k35_allowed == 147_900

    # Revision-1 reduced grammar with an unconstrained seven-way k27 tensor.
    assert 16_500 * 7 == 115_500
    assert 25_500 * 7 == 178_500
    assert 115_500 - 105_600 == 9_900
    assert 178_500 - 147_900 == 30_600

    return {
        "route_a_k19_k27": {"naive": 126, "not_excluded": 64},
        "route_b_k19_k27": {"naive": 126, "not_excluded": 58},
        "route_a_k31": {"naive": 120, "not_excluded": 66},
        "route_b_joint_k31_k47": {"naive": 240, "not_excluded": 102},
        "k35": {"naive": 27, "not_excluded": 25},
        "revision1_tensor_comparison": {
            "route_a_unconstrained_k27": 115_500,
            "route_a_revision2": 105_600,
            "route_a_removed_by_k27_selector": 9_900,
            "route_b_unconstrained_k27": 178_500,
            "route_b_revision2": 147_900,
            "route_b_removed_by_k27_selector": 30_600,
        },
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

    # Direct arithmetic regression of derived maps plus the phase8 k27 selector.
    phase8_checks = 0
    for t in range(4 * 9 * 31 * 19):
        B = 8 + 35 * t
        D = 5 + 21 * t
        E = 7 + 30 * t
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
        if t % 19 == 8:
            assert E % 19 == 0
            phase8_checks += 1
    assert phase8_checks > 0

    return {
        "seam_is_function_of_tau4": True,
        "k35_3adic_bucket_is_function_of_tau9": True,
        "tau19_8_forces_19_divides_E": True,
        "arithmetic_t_values_checked": 4 * 9 * 31 * 19,
        "tau19_8_instances_checked": phase8_checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "h169-reduced-dependency-grammar-v2-k27",
        "S19": sorted(S19),
        "S31": sorted(S31),
        "k27_modes": list(K27),
        "derived_coordinates": verify_derived_coordinates(),
        "block_counts": verify_block_counts(),
        "route_a": count_route_a(),
        "route_b": count_route_b(),
        "failures": 0,
        "claim": (
            "after including k27 explicitly and applying the landed tau19=8 -> k27 Q selector, "
            "the coarse formal h169 product contracts from 408,240 to 105,600 not-excluded "
            "tuples on Route A and from 816,480 to 147,900 on Route B; these are symbolic "
            "grammar counts, not counts of actual arithmetic survivors"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
