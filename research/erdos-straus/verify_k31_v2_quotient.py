#!/usr/bin/env python3
"""Independent finite regression for K31-TWO-TARGET-QUOTIENT.md.

The theorem is proved algebraically in the note.  This program independently:

1. generates Mordell-hard primes;
2. factors C=(p+31)/4;
3. constructs the divisor residue box of C^2 directly modulo 31;
4. tests the exact Type-I residue 23 and Type-II residue -C;
5. evaluates the v2(C)>=2 quotient classification from residue cosets.

Finite agreement is regression evidence only, not a proof of Erdős-Straus.
"""
from __future__ import annotations

import argparse
import json
import math

HARD = (1, 121, 169, 289, 361, 529)
MOD = 31
H = {1, 2, 4, 8, 16}
A = {(3 * x) % MOD for x in H}
B = {(pow(3, -1, MOD) * x) % MOD for x in H}
QR = {pow(x, 2, MOD) for x in range(1, MOD)}


def sieve_flags(n: int) -> bytearray:
    if n < 1:
        return bytearray(n + 1)
    bs = bytearray(b"\x01") * (n + 1)
    bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return bs


def primes_up_to(n: int) -> list[int]:
    bs = sieve_flags(n)
    return [p for p in range(2, n + 1) if bs[p]]


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


def divisor_square_box(fac: dict[int, int]) -> set[int]:
    """Residues modulo 31 of all divisors of C^2."""
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, f, MOD) for f in range(0, 2 * e + 1)}
        reach = {(x * y) % MOD for x in reach for y in vals}
    return reach


def theorem_miss(fac: dict[int, int]) -> tuple[bool, str]:
    if fac.get(2, 0) < 2:
        raise ValueError("theorem_miss called outside v2>=2 branch")

    if all((q % MOD) in QR for q in fac):
        return True, "pure-QR"

    e_a = 0
    e_b = 0
    for q, e in fac.items():
        r = q % MOD
        if r in H:
            continue
        if r in A:
            e_a += e
            continue
        if r in B:
            e_b += e
            continue
        return False, "complement-hit"

    if (e_a, e_b) in {(1, 0), (0, 1), (1, 1)}:
        return True, f"thin({e_a},{e_b})"
    return False, "complement-hit"


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    hard = [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]
    trial = primes_up_to(math.isqrt((limit + 31) // 4) + 2)

    tested = 0
    skipped_v2_one = 0
    actual_hits = 0
    actual_misses = 0
    mismatches: list[dict[str, object]] = []
    branches: dict[str, int] = {}

    for p in hard:
        C = (p + 31) // 4
        fac = factor(C, trial)
        if fac.get(2, 0) < 2:
            skipped_v2_one += 1
            continue

        tested += 1
        D = divisor_square_box(fac)
        type_i = 23 in D
        type_ii = ((-C) % MOD) in D
        actual_miss = not (type_i or type_ii)

        predicted_miss, branch = theorem_miss(fac)
        branches[branch] = branches.get(branch, 0) + 1

        if actual_miss:
            actual_misses += 1
        else:
            actual_hits += 1

        if predicted_miss != actual_miss:
            if len(mismatches) < 20:
                mismatches.append({
                    "p": p,
                    "C": C,
                    "factorization": fac,
                    "branch": branch,
                    "predicted_miss": predicted_miss,
                    "type_i": type_i,
                    "type_ii": type_ii,
                    "box": sorted(D),
                })

    return {
        "analysis": "k31-v2-quotient-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "tested_v2_ge_2": tested,
        "skipped_v2_eq_1": skipped_v2_one,
        "actual_hits": actual_hits,
        "actual_misses": actual_misses,
        "classification_mismatches": len(mismatches),
        "mismatch_examples": mismatches,
        "branch_counts": dict(sorted(branches.items())),
        "constants": {
            "H": sorted(H),
            "A": sorted(A),
            "B": sorted(B),
            "QR": sorted(QR),
            "type_i_divisor_target": 23,
        },
        "claim": "finite regression of a separately proved exact v2>=2 classification",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.limit < 31:
        raise SystemExit("--limit must be >= 31")

    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")

    return 1 if report["classification_mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
