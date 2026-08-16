#!/usr/bin/env python3
"""Independent direct-factorization regression for composite character extraction."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

BRANCHES = (
    (121, 39, (47,), (8,), 13),
    (169, 51, (11, 23), (4, 18), 17),
    (169, 111, (23,), (4,), 37),
    (289, 39, (11, 47), (5, 8), 13),
    (289, 51, (11, 23), (4, 18), 17),
    (289, 215, (11, 31), (5, 2), 43),
    (529, 51, (11, 23), (4, 18), 17),
    (529, 171, (11, 23), (5, 13), 19),
)
PRODUCT_BRANCHES = (
    # Both source residues are positive-character branches. Jacobi saturation
    # at k=551=19*29 forces the product (19/p)(29/p)=+1, but does not
    # determine either factor character individually.
    (289, 551, (23, 31), (1, 7), (19, 29)),
)


def sieve(limit: int) -> bytearray:
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
    for q in range(2, math.isqrt(limit) + 1):
        if prime[q]:
            start = q * q
            prime[start : limit + 1 : q] = b"\x00" * (((limit - start) // q) + 1)
    return prime


def factor(n: int, trial_primes: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial_primes:
        if q * q > x:
            break
        if x % q:
            continue
        e = 0
        while x % q == 0:
            x //= q
            e += 1
        out[q] = e
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisor_square_residues(factors: dict[int, int], k: int) -> set[int]:
    residues = {1}
    for q, e in factors.items():
        powers = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return residues


def fixed_shift_miss(p: int, k: int, trial_primes: list[int]) -> tuple[bool, dict[int, int]]:
    c = (p + k) // 4
    factors = factor(c, trial_primes)
    residues = divisor_square_residues(factors, k)
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-c) % k
    return type_i not in residues and type_ii not in residues, factors


def character(p: int, q: int) -> int:
    value = pow(p % q, (q - 1) // 2, q)
    return -1 if value == q - 1 else 1


def positive_character(p: int, q: int) -> bool:
    return character(p, q) == 1


def analyze(limit: int) -> dict[str, object]:
    prime = sieve(limit)
    trial_primes = [q for q in range(2, math.isqrt(limit) + 2) if q < len(prime) and prime[q]]
    counts: Counter[str] = Counter()
    failures: list[dict[str, object]] = []

    for h, k, sources, residues, extracted in BRANCHES:
        key = f"h{h}_k{k}_q{extracted}"
        for p in range(h, limit + 1, 840):
            if not prime[p]:
                continue
            if any(p % q != r for q, r in zip(sources, residues)):
                continue
            counts[key + "_route_primes"] += 1
            c = (p + k) // 4
            for q in sources:
                if c % q != 0:
                    failures.append({
                        "kind": "routing",
                        "key": key,
                        "p": p,
                        "source": q,
                        "companion": c,
                    })
            miss, factors = fixed_shift_miss(p, k, trial_primes)
            counts[key + "_misses"] += int(miss)
            if miss:
                if not positive_character(p, extracted):
                    failures.append({
                        "kind": "extracted-character",
                        "key": key,
                        "p": p,
                        "extracted": extracted,
                        "factors": factors,
                    })
                else:
                    counts[key + "_positive_character_misses"] += 1

        if counts[key + "_route_primes"] == 0:
            failures.append({"kind": "missing-route-realization", "key": key})
        if counts[key + "_misses"] == 0:
            failures.append({"kind": "missing-miss-realization", "key": key})

    for h, k, sources, residues, unknown_factors in PRODUCT_BRANCHES:
        key = f"h{h}_k{k}_product_" + "_".join(map(str, unknown_factors))
        for p in range(h, limit + 1, 840):
            if not prime[p]:
                continue
            if any(p % q != r for q, r in zip(sources, residues)):
                continue
            counts[key + "_route_primes"] += 1
            c = (p + k) // 4
            for q in sources:
                if c % q != 0:
                    failures.append({
                        "kind": "product-routing",
                        "key": key,
                        "p": p,
                        "source": q,
                        "companion": c,
                    })
            miss, factors = fixed_shift_miss(p, k, trial_primes)
            counts[key + "_misses"] += int(miss)
            if miss:
                product = math.prod(character(p, q) for q in unknown_factors)
                if product != 1:
                    failures.append({
                        "kind": "composite-character-product",
                        "key": key,
                        "p": p,
                        "unknown_factors": list(unknown_factors),
                        "character_product": product,
                        "factors": factors,
                    })
                else:
                    counts[key + "_positive_product_misses"] += 1

        if counts[key + "_route_primes"] == 0:
            failures.append({"kind": "missing-product-route-realization", "key": key})
        if counts[key + "_misses"] == 0:
            failures.append({"kind": "missing-product-miss-realization", "key": key})

    return {
        "analysis": "jacobi-saturation-character-extraction-independent-regression-v2",
        "limit": limit,
        "extraction_branches": len(BRANCHES),
        "product_branches": len(PRODUCT_BRANCHES),
        "counts": dict(sorted(counts.items())),
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "finite direct-factorization regression of routed composite branches; "
            "range-free extraction and product constraints follow from Jacobi saturation"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=2_000_000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"extraction branches: {report['extraction_branches']}")
        print(f"product branches: {report['product_branches']}")
        print(f"failures: {report['failures']}")
        for key, value in report["counts"].items():
            print(f"{key}: {value}")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
