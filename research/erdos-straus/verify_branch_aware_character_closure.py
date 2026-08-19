#!/usr/bin/env python3
"""Independent anchor verification for branch-aware character closure.

This verifier intentionally does not reproduce the BFS/state-closure algorithm.
It replays representative early, middle, and late extraction edges by direct
integer factorization and direct divisor enumeration of the mandatory seed.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

# Representative extraction edges selected from the exact closure.
# fixed contains every source residue that is fixed on the branch by the time
# the destination is reached. For each row, those congruences make the named
# routed primes mandatory divisors of C_k.
EXTRACTION_ANCHORS = (
    {
        "label": "q79-root",
        "hard_class": 121,
        "k": 79,
        "fixed": {13: 12, 19: 16, 47: 8},
        "seed": 2470,
        "extracted": 79,
    },
    {
        "label": "q83-root",
        "hard_class": 169,
        "k": 83,
        "fixed": {11: 5, 23: 4, 31: 10},
        "seed": 7161,
        "extracted": 83,
    },
    {
        "label": "q109-composite",
        "hard_class": 289,
        "k": 327,
        "fixed": {11: 4, 17: 13, 23: 18, 31: 14, 47: 2},
        "seed": 7975618,
        "extracted": 109,
    },
    {
        "label": "q151-root",
        "hard_class": 169,
        "k": 151,
        "fixed": {11: 3, 23: 4, 31: 4, 37: 34},
        "seed": 126170,
        "extracted": 151,
    },
    {
        "label": "q271-root",
        "hard_class": 289,
        "k": 271,
        "fixed": {11: 4, 17: 1, 23: 18, 31: 8},
        "seed": 405790,
        "extracted": 271,
    },
    {
        "label": "q383-depth2",
        "hard_class": 289,
        "k": 383,
        "fixed": {11: 4, 17: 8, 19: 16, 23: 18, 31: 20, 47: 28},
        "seed": 420546,
        "extracted": 383,
    },
    {
        "label": "q971-depth2",
        "hard_class": 289,
        "k": 971,
        "fixed": {11: 4, 17: 15, 19: 17, 23: 18, 47: 16},
        "seed": 36662115,
        "extracted": 971,
    },
)

PRODUCT_ANCHOR = {
    "label": "h289-k551-product",
    "hard_class": 289,
    "k": 551,
    "fixed": {23: 1, 31: 7},
    "seed": 149730,
    "unknown_factors": (19, 29),
    "forced_product": 1,
}


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
    divisors = [1]
    for q, e in factors.items():
        local = [q**j for j in range(e + 1)]
        divisors = [a * b for a in divisors for b in local]
    return divisors


def seed_square_residues(seed: int, k: int) -> set[int]:
    # Directly enumerate the positive divisors of seed^2. This is deliberately
    # different from the transition/sumset implementation in the classifier.
    factors = Counter({q: 2 * e for q, e in factorization(seed).items()})
    return {d % k for d in divisors_from_factorization(factors)}


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


def jacobi_kernel(k: int) -> set[int]:
    return {
        u for u in range(1, k)
        if math.gcd(u, k) == 1 and jacobi(u, k) == 1
    }


def legendre(residue: int, q: int) -> int:
    residue %= q
    if residue == 0:
        return 0
    value = pow(residue, (q - 1) // 2, q)
    return -1 if value == q - 1 else 1


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def mandatory_seed(k: int, h: int, fixed: dict[int, int]) -> int:
    seed = class_seed(k, h)
    for q, residue in fixed.items():
        if (residue + k) % q == 0:
            seed = math.lcm(seed, q)
    return seed


def fixed_character(q: int, h: int, fixed: dict[int, int]) -> int | None:
    if 840 % q == 0:
        return legendre(h % q, q)
    if q in fixed:
        return legendre(fixed[q], q)
    return None


def verify_extraction(row: dict[str, object], failures: list[dict[str, object]]) -> dict[str, object]:
    h = int(row["hard_class"])
    k = int(row["k"])
    fixed = dict(row["fixed"])
    seed = int(row["seed"])
    extracted = int(row["extracted"])

    actual_seed = mandatory_seed(k, h, fixed)
    if actual_seed != seed:
        failures.append({
            "kind": "mandatory-seed",
            "label": row["label"],
            "expected": seed,
            "actual": actual_seed,
        })

    for q, residue in fixed.items():
        sign = legendre(residue, q)
        if sign != 1:
            failures.append({
                "kind": "fixed-source-not-positive",
                "label": row["label"],
                "q": q,
                "residue": residue,
                "sign": sign,
            })

    residues = seed_square_residues(seed, k)
    kernel = jacobi_kernel(k)
    if residues != kernel:
        failures.append({
            "kind": "not-jacobi-saturating",
            "label": row["label"],
            "seed_residue_count": len(residues),
            "kernel_count": len(kernel),
        })

    type_i = (-pow(4, -1, k)) % k
    if type_i in residues:
        failures.append({
            "kind": "type-i-already-hit",
            "label": row["label"],
            "target": type_i,
        })

    unknown: list[int] = []
    known_product = 1
    for q, e in factorization(k).items():
        if e % 2 == 0:
            continue
        sign = fixed_character(q, h, fixed)
        if sign is None:
            unknown.append(q)
        else:
            known_product *= sign

    if unknown != [extracted] or known_product != 1:
        failures.append({
            "kind": "extraction",
            "label": row["label"],
            "unknown": unknown,
            "expected_unknown": extracted,
            "known_product": known_product,
        })

    return {
        "label": row["label"],
        "hard_class": h,
        "k": k,
        "factorization_k": dict(sorted(factorization(k).items())),
        "seed": seed,
        "factorization_seed": dict(sorted(factorization(seed).items())),
        "seed_divisor_residues": len(residues),
        "jacobi_kernel_size": len(kernel),
        "extracted_prime": extracted,
        "forced_character": known_product,
    }


def verify_product(row: dict[str, object], failures: list[dict[str, object]]) -> dict[str, object]:
    h = int(row["hard_class"])
    k = int(row["k"])
    fixed = dict(row["fixed"])
    seed = int(row["seed"])
    expected_unknown = list(row["unknown_factors"])

    actual_seed = mandatory_seed(k, h, fixed)
    if actual_seed != seed:
        failures.append({
            "kind": "product-mandatory-seed",
            "expected": seed,
            "actual": actual_seed,
        })

    residues = seed_square_residues(seed, k)
    kernel = jacobi_kernel(k)
    if residues != kernel:
        failures.append({"kind": "product-not-saturating"})

    unknown: list[int] = []
    known_product = 1
    for q, e in factorization(k).items():
        if e % 2 == 0:
            continue
        sign = fixed_character(q, h, fixed)
        if sign is None:
            unknown.append(q)
        else:
            known_product *= sign

    if unknown != expected_unknown or known_product != int(row["forced_product"]):
        failures.append({
            "kind": "product-character",
            "unknown": unknown,
            "expected_unknown": expected_unknown,
            "known_product": known_product,
        })

    return {
        "label": row["label"],
        "hard_class": h,
        "k": k,
        "factorization_k": dict(sorted(factorization(k).items())),
        "seed": seed,
        "factorization_seed": dict(sorted(factorization(seed).items())),
        "unknown_factors": unknown,
        "forced_product": known_product,
    }


def analyze() -> dict[str, object]:
    failures: list[dict[str, object]] = []
    extraction_rows = [verify_extraction(row, failures) for row in EXTRACTION_ANCHORS]
    product_row = verify_product(PRODUCT_ANCHOR, failures)

    return {
        "analysis": "branch-aware-character-closure-independent-anchors-v1",
        "extraction_anchors_checked": len(extraction_rows),
        "extraction_rows": extraction_rows,
        "product_anchor": product_row,
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "independent direct-divisor replay of representative root, composite, and late "
            "recursive extraction edges plus the k551 two-character product constraint"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"extraction anchors: {report['extraction_anchors_checked']}")
        print(f"failures: {report['failures']}")
        for row in report["extraction_rows"]:
            print(row)
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
