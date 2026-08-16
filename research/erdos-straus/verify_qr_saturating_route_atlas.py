#!/usr/bin/env python3
"""Direct finite-prime regression for the full single-route saturation atlas."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

UPGRADES = (
    (23, 289, 4, 19),
    (31, 169, 8, 23),
    (31, 289, 8, 23),
    (31, 529, 8, 23),
    (47, 121, 36, 11),
    (47, 289, 16, 31),
    (47, 289, 28, 19),
    (59, 361, 28, 31),
    (59, 361, 36, 23),
    (59, 361, 48, 11),
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


def is_qr(a: int, k: int) -> bool:
    a %= k
    return a != 0 and pow(a, (k - 1) // 2, k) == 1


def analyze(limit: int) -> dict[str, object]:
    prime = sieve(limit)
    trial_primes = [q for q in range(2, math.isqrt(limit) + 2) if q < len(prime) and prime[q]]
    counts: Counter[str] = Counter()
    failures: list[dict[str, object]] = []

    for source_q, h, source_r, k in UPGRADES:
        key = f"q{source_q}_h{h}_r{source_r}_k{k}"
        for p in range(h, limit + 1, 840):
            if not prime[p] or p % source_q != source_r:
                continue
            counts[key + "_primes"] += 1
            c = (p + k) // 4
            if c % source_q != 0:
                failures.append({"kind": "routing", "key": key, "p": p, "companion": c})
                continue
            miss, factors = fixed_shift_miss(p, k, trial_primes)
            qr_support = all(is_qr(q, k) for q in factors)
            counts[key + "_misses"] += int(miss)
            counts[key + "_qr_support"] += int(qr_support)
            if miss != qr_support:
                failures.append({
                    "kind": "support-equivalence",
                    "key": key,
                    "p": p,
                    "miss": miss,
                    "qr_support": qr_support,
                    "factors": factors,
                })

        if counts[key + "_primes"] == 0:
            failures.append({"kind": "missing-route-realization", "key": key})
        if counts[key + "_misses"] == 0:
            failures.append({"kind": "missing-miss-realization", "key": key})

    return {
        "analysis": "qr-saturating-route-atlas-independent-regression-v2",
        "limit": limit,
        "upgrade_branches": len(UPGRADES),
        "counts": dict(sorted(counts.items())),
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "finite direct-factorization regression; the saturation equivalence itself "
            "is proved by the divisor-lattice lemma"
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
        print(f"upgrade branches: {report['upgrade_branches']}")
        print(f"failures: {report['failures']}")
        for key, value in report["counts"].items():
            print(f"{key}: {value}")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
