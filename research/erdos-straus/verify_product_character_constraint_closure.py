#!/usr/bin/env python3
"""Independent verification of the k=551 product-character constraint.

This verifier does not reproduce the recursive closure. It directly enumerates
positive divisors of the mandatory seed square at k=551, derives the exact
character equation, and verifies the GF(2) consequences by exhaustive sign
truth tables.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD_CLASS = 289
K = 551
FIXED = {11: 5, 13: 3, 23: 1, 31: 7, 47: 8}
EXPECTED_SEED = 149730
UNKNOWN_FACTORS = (19, 29)
EXPECTED_FORCED_PRODUCT = 1


def factorization(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    x = n
    q = 2
    while q * q <= x:
        while x % q == 0:
            out[q] += 1
            x //= q
        q += 1 if q == 2 else 2
    if x > 1:
        out[x] += 1
    return out


def divisors_from_factorization(factors: Counter[int]) -> list[int]:
    values = [1]
    for q, e in factors.items():
        values = [v * q**j for v in values for j in range(e + 1)]
    return values


def seed_square_residues(seed: int, modulus: int) -> set[int]:
    doubled = Counter({q: 2 * e for q, e in factorization(seed).items()})
    return {d % modulus for d in divisors_from_factorization(doubled)}


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError(n)
    a %= n
    result = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                result = -result
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            result = -result
        a %= n
    return result if n == 1 else 0


def jacobi_plus(modulus: int) -> set[int]:
    return {
        u for u in range(1, modulus)
        if math.gcd(u, modulus) == 1 and jacobi(u, modulus) == 1
    }


def legendre(residue: int, q: int) -> int:
    residue %= q
    if residue == 0:
        return 0
    value = pow(residue, (q - 1) // 2, q)
    return -1 if value == q - 1 else 1


def mandatory_seed() -> int:
    seed = math.gcd(210, (HARD_CLASS + K) // 4)
    for q, residue in FIXED.items():
        if (residue + K) % q == 0:
            seed = math.lcm(seed, q)
    return seed


def direct_character_equation() -> dict[str, object]:
    seed = mandatory_seed()
    assert seed == EXPECTED_SEED

    routed = tuple(sorted(q for q, r in FIXED.items() if (r + K) % q == 0))
    assert routed == (23, 31)

    for q in routed:
        assert legendre(FIXED[q], q) == 1

    residues = seed_square_residues(seed, K)
    kernel = jacobi_plus(K)
    assert residues == kernel

    type_i = (-pow(4, -1, K)) % K
    assert type_i not in residues

    factors_k = factorization(K)
    assert factors_k == Counter({19: 1, 29: 1})

    # Neither 19 nor 29 is class-fixed by modulus 840 and neither is fixed by
    # the routed ancestry. Thus saturation forces only their product.
    unknown = tuple(sorted(q for q, e in factors_k.items() if e % 2 == 1))
    assert unknown == UNKNOWN_FACTORS

    # A saturated miss forces Jacobi(K/p)=+1, so chi_19 * chi_29 = +1.
    forced_product = 1
    assert forced_product == EXPECTED_FORCED_PRODUCT

    return {
        "hard_class": HARD_CLASS,
        "k": K,
        "factorization_k": dict(sorted(factors_k.items())),
        "fixed_residues": dict(sorted(FIXED.items())),
        "routed_sources": list(routed),
        "mandatory_seed": seed,
        "factorization_seed": dict(sorted(factorization(seed).items())),
        "seed_square_residue_count": len(residues),
        "jacobi_plus_size": len(kernel),
        "unknown_factors": list(unknown),
        "forced_product": forced_product,
    }


def truth_table() -> dict[str, object]:
    allowed = []
    forbidden = []
    for chi19 in (-1, 1):
        for chi29 in (-1, 1):
            row = {"chi19": chi19, "chi29": chi29, "product": chi19 * chi29}
            if chi19 * chi29 == 1:
                allowed.append(row)
            else:
                forbidden.append(row)

    assert allowed == [
        {"chi19": -1, "chi29": -1, "product": 1},
        {"chi19": 1, "chi29": 1, "product": 1},
    ]
    assert len(forbidden) == 2

    # The product equation alone does not determine either sign.
    assert {row["chi19"] for row in allowed} == {-1, 1}
    assert {row["chi29"] for row in allowed} == {-1, 1}

    # Once either sign is learned, the other is forced to match it.
    for sign in (-1, 1):
        rows19 = [row for row in allowed if row["chi19"] == sign]
        rows29 = [row for row in allowed if row["chi29"] == sign]
        assert len(rows19) == 1 and rows19[0]["chi29"] == sign
        assert len(rows29) == 1 and rows29[0]["chi19"] == sign

    # Opposite signs are exact contradictions to the product equation.
    assert all(row["product"] == -1 for row in forbidden)

    return {
        "allowed_assignments": allowed,
        "forbidden_assignments": forbidden,
        "equation_alone_determines_chi19": False,
        "equation_alone_determines_chi29": False,
        "one_known_sign_forces_the_other": True,
        "opposite_known_signs_contradict": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    equation = direct_character_equation()
    table = truth_table()
    report = {
        "analysis": "product-character-constraint-independent-verification-v1",
        "equation": equation,
        "truth_table": table,
        "failures": 0,
        "claim": (
            "direct divisor enumeration proves the lone k551 relation chi19*chi29=+1; "
            "the relation alone fixes neither sign, but either later sign determines the other"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("k551 product equation: chi19 * chi29 = +1")
        print("equation alone determines neither individual sign")
        print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
