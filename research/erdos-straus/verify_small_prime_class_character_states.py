#!/usr/bin/env python3
"""Independent finite realization regression for the small-prime class atlas."""
from __future__ import annotations

import argparse
import json
import math

import classify_small_prime_class_character_states as atlas

EXPECTED_100K = {
    (11, 169): (43, 26, 17, 21),
    (11, 289): (45, 31, 14, 25),
    (11, 529): (50, 30, 20, 26),
    (19, 121): (50, 30, 20, 29),
    (31, 169): (43, 31, 12, 25),
    (31, 289): (45, 31, 14, 27),
    (31, 529): (50, 31, 19, 29),
    (47, 121): (50, 32, 18, 28),
    (47, 289): (45, 26, 19, 24),
}


def sieve_flags(n: int) -> bytearray:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for q in range(2, math.isqrt(n) + 1):
        if bs[q]:
            bs[q * q:n + 1:q] = b"\x00" * (((n - q * q) // q) + 1)
    return bs


def primes_upto(n: int) -> list[int]:
    bs = sieve_flags(n)
    return [q for q in range(2, n + 1) if bs[q]]


def factor(n: int, trial: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial:
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


def legendre(a: int, q: int) -> int:
    x = pow(a % q, (q - 1) // 2, q)
    if x == 1:
        return 1
    if x == q - 1:
        return -1
    return 0


def divisor_square_box(fac: dict[int, int], modulus: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, j, modulus) for j in range(2 * e + 1)}
        reach = {(x * y) % modulus for x in reach for y in vals}
    return reach


def direct_hit(p: int, k: int, fac: dict[int, int]) -> bool:
    C = (p + k) // 4
    box = divisor_square_box(fac, k)
    type_i = (-pow(4, -1, k)) % k
    return type_i in box or ((-C) % k) in box


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    trial = primes_upto(math.isqrt((limit + max(atlas.SHIFTS)) // 4) + 2)
    mismatches: list[dict[str, object]] = []
    rows = {}

    theorem_pairs = []
    for k, seed_map in atlas.RANGE_FREE_BRANCHES.items():
        for _seed, classes in seed_map.items():
            theorem_pairs.extend((k, h) for h in classes)

    for k, h in theorem_pairs:
        total = hits = misses = negative = negative_misses = bad_support = 0
        for p in range(2, limit + 1):
            if not flags[p] or p % 840 != h:
                continue
            total += 1
            C = (p + k) // 4
            fac = factor(C, trial)
            hit = direct_hit(p, k, fac)
            if hit:
                hits += 1
            else:
                misses += 1
                if any(legendre(q, k) != 1 for q in fac):
                    bad_support += 1
                    if len(mismatches) < 20:
                        mismatches.append({
                            "kind": "miss-with-nonresidue-factor",
                            "p": p,
                            "h": h,
                            "k": k,
                            "C": C,
                            "factorization": fac,
                        })
            if legendre(p, k) == -1:
                negative += 1
                if not hit:
                    negative_misses += 1
                    if len(mismatches) < 20:
                        mismatches.append({
                            "kind": "negative-character-miss",
                            "p": p,
                            "h": h,
                            "k": k,
                        })

        row = {
            "hard_class": h,
            "k": k,
            "primes": total,
            "hits": hits,
            "misses": misses,
            "negative_character_primes": negative,
            "negative_character_misses": negative_misses,
            "misses_with_nonresidue_factor": bad_support,
        }
        rows[f"k{k}-h{h}"] = row

        if limit == 100_000:
            expected = EXPECTED_100K[(k, h)]
            actual = (total, hits, misses, negative)
            if actual != expected:
                mismatches.append({
                    "kind": "100k-count-regression",
                    "k": k,
                    "h": h,
                    "actual": actual,
                    "expected": expected,
                })

    # Re-run the abstract closures too, but the direct factorization above is
    # intentionally independent of their state representation.
    abstract = atlas.analyze()

    return {
        "analysis": "small-prime-class-character-realization-regression-v1",
        "limit": limit,
        "rows": rows,
        "abstract_analysis": abstract["analysis"],
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": (
            "finite direct divisor-square realization regression for range-free fixed-shift "
            "closures; finite counts are regression anchors, not the theorem itself"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, row in report["rows"].items():
            print(key, row)
        print(f"mismatches: {report['mismatches']}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
