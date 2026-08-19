#!/usr/bin/env python3
"""Independent finite realization checks for routed k=19/k=23 bottlenecks.

This verifier does not use the abstract state closures. It factors the actual
companions, generates divisor residues of C_k^2 directly, and checks the two
Lane-I targets.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
JACOBI_PLUS_15 = {1, 2, 4, 8}


def sieve(limit: int) -> bytearray:
    prime = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        prime[0] = 0
    if limit >= 1:
        prime[1] = 0
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
    if (p + k) % 4:
        raise ValueError((p, k))
    companion = (p + k) // 4
    factors = factor(companion, trial_primes)
    residues = divisor_square_residues(factors, k)
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-companion) % k
    return type_i not in residues and type_ii not in residues, factors


def legendre(a: int, p: int) -> int:
    a %= p
    if a == 0:
        return 0
    v = pow(a, (p - 1) // 2, p)
    return -1 if v == p - 1 else 1


def analyze(limit: int) -> dict[str, object]:
    prime = sieve(limit)
    trial_primes = [q for q in range(2, math.isqrt(limit) + 2) if q < len(prime) and prime[q]]
    counts: Counter[str] = Counter()
    failures: list[dict[str, object]] = []

    for p in range(2, limit + 1):
        if not prime[p] or p % 840 not in HARD_CLASSES:
            continue
        h = p % 840

        miss23, _ = fixed_shift_miss(p, 23, trial_primes)
        if miss23 and legendre(23, p) == -1:
            counts[f"k23_negative_pmod23_{p % 23}"] += 1
            if p % 23 not in (5, 14):
                failures.append({"kind": "k23-negative-route", "p": p, "p_mod_23": p % 23})

        if h == 121 and p % 19 == 4:
            miss15, factors15 = fixed_shift_miss(p, 15, trial_primes)
            support_plus = all(q % 15 in JACOBI_PLUS_15 for q in factors15)
            counts["k15_h121_route_total"] += 1
            counts["k15_h121_route_miss"] += int(miss15)
            counts["k15_h121_route_jacobi_plus"] += int(support_plus)
            if miss15 != support_plus:
                failures.append({
                    "kind": "k15-support-equivalence",
                    "p": p,
                    "miss": miss15,
                    "support_plus": support_plus,
                    "factors": factors15,
                })

        if h in (1, 169) and p % 23 == 14:
            miss55, factors55 = fixed_shift_miss(p, 55, trial_primes)
            counts[f"k55_h{h}_route_total"] += 1
            counts[f"k55_h{h}_route_miss"] += int(miss55)
            if miss55 and p % 11 != 1:
                failures.append({
                    "kind": "k55-route-residue",
                    "p": p,
                    "h": h,
                    "p_mod_11": p % 11,
                    "factors": factors55,
                })

    required_positive = (
        "k23_negative_pmod23_5",
        "k23_negative_pmod23_14",
        "k15_h121_route_total",
        "k15_h121_route_miss",
        "k55_h1_route_total",
        "k55_h169_route_total",
    )
    for key in required_positive:
        if counts[key] == 0:
            failures.append({"kind": "missing-regression-realization", "counter": key})

    return {
        "analysis": "k19-k23-routed-bottlenecks-independent-regression-v1",
        "limit": limit,
        "counts": dict(sorted(counts.items())),
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "finite direct-factorization regression only; range-free claims come from "
            "the separate exact finite-group classifier"
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
        print(f"limit: {report['limit']}")
        print(f"failures: {report['failures']}")
        for key, value in report["counts"].items():
            print(f"{key}: {value}")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
