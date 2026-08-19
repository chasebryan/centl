#!/usr/bin/env python3
"""Independent finite realization regression for q=11 companion routing."""
from __future__ import annotations

import argparse
import json
import math

import classify_k11_routed_companion_states as routed

EXPECTED_100K_K35 = {
    169: (5, 0, 5),
    289: (5, 0, 5),
    529: (5, 1, 4),
}
EXPECTED_100K_K39 = {
    169: (6, 4, 2, 4),
    289: (3, 1, 2, 1),
    529: (4, 4, 0, 3),
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


def divisor_square_box(fac: dict[int, int], modulus: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, j, modulus) for j in range(2 * e + 1)}
        reach = {(a * b) % modulus for a in reach for b in vals}
    return reach


def direct_hit(p: int, k: int, fac: dict[int, int]) -> bool:
    C = (p + k) // 4
    box = divisor_square_box(fac, k)
    type_i = (-pow(4, -1, k)) % k
    return type_i in box or ((-C) % k) in box


def legendre(a: int, q: int) -> int:
    x = pow(a % q, (q - 1) // 2, q)
    if x == 1:
        return 1
    if x == q - 1:
        return -1
    return 0


def jacobi35(a: int) -> int:
    return legendre(a, 5) * legendre(a, 7)


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    trial = primes_upto(math.isqrt((limit + 39) // 4) + 2)
    mismatches: list[dict[str, object]] = []
    k35_rows = {}
    k39_rows = {}

    # Consume the abstract theorem first.  The finite tests below do not use
    # its masks to decide hits or misses.
    abstract = routed.analyze()

    for h in routed.HARD_CLASSES:
        primes35 = [
            p for p in range(2, limit + 1)
            if flags[p] and p % 840 == h and p % 11 == 9
        ]
        hits = misses = bad_support = 0
        for p in primes35:
            C = (p + 35) // 4
            if C % 11:
                mismatches.append({"kind": "route-factor-missing", "k": 35, "p": p, "C": C})
                continue
            fac = factor(C, trial)
            is_hit = direct_hit(p, 35, fac)
            if is_hit:
                hits += 1
            else:
                misses += 1
                if any(jacobi35(q) != 1 for q in fac):
                    bad_support += 1
                    mismatches.append({
                        "kind": "k35-miss-with-Jacobi-negative-factor",
                        "p": p, "h": h, "C": C, "factorization": fac,
                    })
            support_only = all(jacobi35(q) == 1 for q in fac)
            if is_hit == support_only:
                mismatches.append({
                    "kind": "k35-support-equivalence",
                    "p": p, "h": h, "hit": is_hit,
                    "support_only": support_only, "factorization": fac,
                })
        k35_rows[str(h)] = {
            "primes_on_route": len(primes35),
            "hits": hits,
            "misses": misses,
            "misses_with_Jacobi_negative_factor": bad_support,
        }
        if limit == 100_000:
            expected = EXPECTED_100K_K35[h]
            actual = (len(primes35), hits, misses)
            if actual != expected:
                mismatches.append({
                    "kind": "100k-k35-count-regression", "h": h,
                    "actual": actual, "expected": expected,
                })

        primes39 = [
            p for p in range(2, limit + 1)
            if flags[p] and p % 840 == h and p % 11 == 5
        ]
        hits = misses = negative13 = negative13_misses = 0
        for p in primes39:
            C = (p + 39) // 4
            if C % 11:
                mismatches.append({"kind": "route-factor-missing", "k": 39, "p": p, "C": C})
                continue
            fac = factor(C, trial)
            is_hit = direct_hit(p, 39, fac)
            if is_hit:
                hits += 1
            else:
                misses += 1
            if legendre(13, p) == -1:
                negative13 += 1
                if not is_hit:
                    negative13_misses += 1
                    mismatches.append({
                        "kind": "k39-negative13-miss", "p": p, "h": h,
                    })
        k39_rows[str(h)] = {
            "primes_on_route": len(primes39),
            "hits": hits,
            "misses": misses,
            "negative13_primes": negative13,
            "negative13_misses": negative13_misses,
        }
        if limit == 100_000:
            expected = EXPECTED_100K_K39[h]
            actual = (len(primes39), hits, misses, negative13)
            if actual != expected:
                mismatches.append({
                    "kind": "100k-k39-count-regression", "h": h,
                    "actual": actual, "expected": expected,
                })

    return {
        "analysis": "k11-routed-companion-realization-regression-v1",
        "limit": limit,
        "k35_route_pmod11_9": k35_rows,
        "k39_route_pmod11_5": k39_rows,
        "abstract_analysis": abstract["analysis"],
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": (
            "independent finite direct-factorization regression for exact range-free "
            "routing/state theorems; finite counts are regression anchors only"
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
        print("k35:", report["k35_route_pmod11_9"])
        print("k39:", report["k39_route_pmod11_5"])
        print("mismatches:", report["mismatches"])
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
