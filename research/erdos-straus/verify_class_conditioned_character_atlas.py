#!/usr/bin/env python3
"""Independent finite realization regression for the class character atlas.

This deliberately does not import classify_class_conditioned_character_atlas.
It factors actual companions and evaluates the exact signed divisor box directly.
"""
from __future__ import annotations

import argparse
import json
import math

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
THEOREMS = {
    11: (169, 289, 529),
    31: (169, 289, 529),
    47: (121, 289),
    59: (361,),
}
EXPECTED_2M = {
    11: {"class_primes": 2247, "negative_character": 1147, "negative_misses": 0},
    31: {"class_primes": 2247, "negative_character": 1171, "negative_misses": 0},
    47: {"class_primes": 1511, "negative_character": 760, "negative_misses": 0},
    59: {"class_primes": 745, "negative_character": 376, "negative_misses": 0},
}
EXPECTED_NEGATIVE_CONTROL_2M = {
    "class_primes": 745,
    "negative_character": 383,
    "negative_misses": 3,
    "first_negative_misses": [54121, 1408201, 1824841],
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
    flags = sieve_flags(n)
    return [q for q in range(2, n + 1) if flags[q]]


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


def signed_box(fac: dict[int, int], modulus: int) -> set[int]:
    reach = {1 % modulus}
    for q, e in fac.items():
        residue = q % modulus
        if residue == 0:
            raise ValueError(f"nonunit factor {modulus} in fixed-shift companion")
        inv = pow(residue, -1, modulus)
        packet = {1}
        x = 1
        for _ in range(e):
            x = (x * residue) % modulus
            packet.add(x)
        x = 1
        for _ in range(e):
            x = (x * inv) % modulus
            packet.add(x)
        reach = {(a * b) % modulus for a in reach for b in packet}
    return reach


def fixed_shift_hit(p: int, q: int, trial: list[int]) -> bool:
    C = (p + q) // 4
    if 4 * C != p + q:
        raise ValueError(f"inadmissible fixed shift p={p}, q={q}")
    box = signed_box(factor(C, trial), q)
    targets = {(-1) % q, (-pow(p, -1, q)) % q}
    return bool(box & targets)


def negative_character(p: int, q: int) -> bool:
    return pow(p % q, (q - 1) // 2, q) == q - 1


def class_seed(q: int, h: int) -> int:
    return math.gcd(210, (h + q) // 4)


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    trial = primes_upto(math.isqrt((limit + max(THEOREMS)) // 4) + 2)
    mismatches: list[dict[str, object]] = []
    rows: dict[str, object] = {}

    expected_seeds = {
        11: {169: 15, 289: 15, 529: 15},
        31: {169: 10, 289: 10, 529: 70},
        47: {121: 42, 289: 42},
        59: {361: 105},
    }

    for q, classes in THEOREMS.items():
        class_primes = 0
        negative = 0
        negative_misses: list[int] = []
        seed_failures: list[dict[str, int]] = []
        for h in classes:
            if class_seed(q, h) != expected_seeds[q][h]:
                mismatches.append(
                    {
                        "kind": "class-seed-formula",
                        "q": q,
                        "h": h,
                        "actual": class_seed(q, h),
                        "expected": expected_seeds[q][h],
                    }
                )
        for p in range(2, limit + 1):
            if not flags[p] or p % 840 not in classes:
                continue
            h = p % 840
            class_primes += 1
            C = (p + q) // 4
            seed = expected_seeds[q][h]
            if C % seed:
                seed_failures.append({"p": p, "h": h, "seed": seed, "C": C})
            if negative_character(p, q):
                negative += 1
                if not fixed_shift_hit(p, q, trial):
                    negative_misses.append(p)

        row = {
            "class_primes": class_primes,
            "negative_character": negative,
            "negative_misses": len(negative_misses),
            "negative_miss_examples": negative_misses[:20],
            "seed_failures": len(seed_failures),
        }
        rows[str(q)] = row
        if seed_failures:
            mismatches.append({"kind": "seed-realization", "q": q, "examples": seed_failures[:20]})
        if negative_misses:
            mismatches.append({"kind": "annihilation-realization", "q": q, "examples": negative_misses[:20]})
        if limit == 2_000_000:
            expected = EXPECTED_2M[q]
            for key in ("class_primes", "negative_character", "negative_misses"):
                if row[key] != expected[key]:
                    mismatches.append(
                        {"kind": "2m-regression", "q": q, "key": key, "actual": row[key], "expected": expected[key]}
                    )

    # Negative control: q=31, h=361, seed=14 has one abstract negative miss
    # state and actual prime realizations.  This protects the theorem boundary.
    control_total = 0
    control_negative = 0
    control_misses: list[int] = []
    for p in range(2, limit + 1):
        if not flags[p] or p % 840 != 361:
            continue
        control_total += 1
        C = (p + 31) // 4
        if C % 14:
            mismatches.append({"kind": "negative-control-seed", "p": p, "C": C})
        if negative_character(p, 31):
            control_negative += 1
            if not fixed_shift_hit(p, 31, trial):
                control_misses.append(p)

    control = {
        "q": 31,
        "h": 361,
        "seed": 14,
        "class_primes": control_total,
        "negative_character": control_negative,
        "negative_misses": len(control_misses),
        "first_negative_misses": control_misses[:20],
    }
    if limit == 2_000_000:
        for key, expected in EXPECTED_NEGATIVE_CONTROL_2M.items():
            actual = control[key]
            if actual != expected:
                mismatches.append(
                    {"kind": "2m-negative-control", "key": key, "actual": actual, "expected": expected}
                )

    # Pin the smallest counterexample to any accidental extension of the
    # q=31 theorem onto h=361.
    p = 54_121
    C = (p + 31) // 4
    fac = factor(C, trial)
    if C != 13_538 or fac != {2: 1, 7: 1, 967: 1}:
        mismatches.append({"kind": "54121-factorization", "C": C, "factorization": fac})
    if not negative_character(p, 31) or fixed_shift_hit(p, 31, trial):
        mismatches.append({"kind": "54121-negative-control-hit"})

    return {
        "analysis": "class-conditioned-character-annihilation-realization-regression-v1",
        "limit": limit,
        "theorem_rows": rows,
        "negative_control": control,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": (
            "finite independent realization regression for range-free finite-group implications; "
            "the q=31 h=361 miss is retained as an explicit negative control"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=2_000_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"limit: {report['limit']}")
        print(f"theorem rows: {report['theorem_rows']}")
        print(f"negative control: {report['negative_control']}")
        print(f"mismatches: {report['mismatches']}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
