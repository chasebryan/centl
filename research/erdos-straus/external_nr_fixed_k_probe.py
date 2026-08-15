#!/usr/bin/env python3
"""Exact finite falsifier for the external-nonresidue × hard-shield fixed-k rule.

This script is deliberately standalone and uses only the Python standard library.
It does NOT prove Erdős-Straus. It enumerates Mordell-hard primes in a finite
range, constructs the first external quadratic nonresidue primes ell>=11, and
tests the exact fixed-k divisor-square theorem for

    k = m * ell,  m in {1,3,5,7},  k == 3 (mod 4).

A hit is exact: with C=(p+k)/4, some u|C^2 satisfies 4u == -1 (mod k).
"""

from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD = {1, 121, 169, 289, 361, 529}
MULTIPLIERS = (1, 3, 5, 7)


def sieve(n: int) -> tuple[list[int], bytearray]:
    is_prime = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        is_prime[0] = 0
    if n >= 1:
        is_prime[1] = 0
    for q in range(2, math.isqrt(n) + 1):
        if is_prime[q]:
            start = q * q
            is_prime[start : n + 1 : q] = b"\x00" * (((n - start) // q) + 1)
    return [i for i in range(2, n + 1) if is_prime[i]], is_prime


def legendre(a: int, p: int) -> int:
    a %= p
    if a == 0:
        return 0
    x = pow(a, (p - 1) // 2, p)
    return -1 if x == p - 1 else x


def factor(n: int, primes: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in primes:
        if q * q > x:
            break
        if x % q == 0:
            e = 0
            while x % q == 0:
                x //= q
                e += 1
            out[q] = e
        if x == 1:
            break
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def target_divisor_exists(C: int, k: int, primes: list[int]) -> bool:
    """Exact DP for u|C^2 with u == -4^{-1} mod k."""
    target = (-pow(4, -1, k)) % k
    fac = factor(C, primes)
    residues = {1 % k}
    for q, e in fac.items():
        powers = [1]
        for _ in range(2 * e):
            powers.append((powers[-1] * (q % k)) % k)
        residues = {(a * b) % k for a in residues for b in powers}
        if target in residues:
            return True
    return target in residues


def first_external_nrs(p: int, nr_primes: list[int], count: int) -> list[int]:
    out: list[int] = []
    for ell in nr_primes:
        if ell == p:
            continue
        if legendre(ell, p) == -1:
            out.append(ell)
            if len(out) == count:
                break
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=10_000_000)
    ap.add_argument("--nr-count", type=int, default=8)
    ap.add_argument("--nr-search-limit", type=int, default=10_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    # Factoring C only needs primes through sqrt((limit + modest k)/4).
    factor_bound = math.isqrt(args.limit + args.nr_search_limit * max(MULTIPLIERS)) + 10
    bound = max(args.limit, args.nr_search_limit, factor_bound)
    all_primes, is_prime = sieve(bound)
    factor_primes = [q for q in all_primes if q <= factor_bound]
    nr_primes = [q for q in all_primes if 11 <= q <= args.nr_search_limit]

    hard_primes = [p for p in all_primes if p <= args.limit and p % 840 in HARD]

    failures: list[dict] = []
    hit_k = Counter()
    hit_multiplier = Counter()
    hit_nr_rank = Counter()
    hit_gcd105 = Counter()

    for p in hard_primes:
        nrs = first_external_nrs(p, nr_primes, args.nr_count)
        hit = None
        for rank, ell in enumerate(nrs, start=1):
            for m in MULTIPLIERS:
                k = m * ell
                if k % 4 != 3:
                    continue
                if math.gcd(p, k) != 1:
                    continue
                C_num = p + k
                if C_num % 4:
                    raise AssertionError((p, k))
                C = C_num // 4
                if target_divisor_exists(C, k, factor_primes):
                    hit = (rank, ell, m, k, C)
                    break
            if hit:
                break

        if hit is None:
            failures.append({"p": p, "external_nrs": nrs})
        else:
            rank, ell, m, k, C = hit
            hit_k[k] += 1
            hit_multiplier[m] += 1
            hit_nr_rank[rank] += 1
            hit_gcd105[math.gcd(C, 105)] += 1

    result = {
        "limit": args.limit,
        "hard_primes": len(hard_primes),
        "nr_count": args.nr_count,
        "multipliers": list(MULTIPLIERS),
        "failures": len(failures),
        "failure_examples": failures[:50],
        "hit_multiplier": dict(sorted(hit_multiplier.items())),
        "hit_nr_rank": dict(sorted(hit_nr_rank.items())),
        "hit_gcd_C_105": dict(sorted(hit_gcd105.items())),
        "claim_boundary": "finite exact falsifier only; zero failures is not a universal proof",
    }

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        for key, value in result.items():
            print(f"{key}: {value}")


if __name__ == "__main__":
    main()
