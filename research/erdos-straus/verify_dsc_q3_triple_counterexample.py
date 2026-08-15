#!/usr/bin/env python3
"""Independent verifier for DSC-Q3-TRIPLE-COUNTEREXAMPLE.md.

This verifier deliberately does NOT use the linear tau sieve from the C++
verifier. It uses only the elementary bound tau(n) <= 2*sqrt(n) to build a
coarse candidate set, independently factors those candidates, applies the
exact cardinality bound q <= 2*tau(j), and reconstructs every remaining
pullback from scratch.
"""

from __future__ import annotations

import json
import math

K = 15_290_696
M = 61_162_783
TARGET_DIVISOR = 764
T = 61_162_019
H = 1
EXPECTED_R = 41_284_877_761
EXPECTED_L = 51_376_737_720


def divisors_from_factorization(factors: list[tuple[int, int]]) -> list[int]:
    out = [1]
    for p, a in factors:
        out = [d * (p**e) for d in out for e in range(a + 1)]
    return out


def primes_upto(n: int) -> list[int]:
    sieve = bytearray(b"\x01") * (n + 1)
    sieve[0:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if sieve[p]:
            start = p * p
            sieve[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [i for i in range(2, n + 1) if sieve[i]]


PRIMES = primes_upto(math.isqrt(K) + 1)


def factor(n: int) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    x = n
    for p in PRIMES:
        if p * p > x:
            break
        if x % p == 0:
            a = 0
            while x % p == 0:
                x //= p
                a += 1
            out.append((p, a))
        if x == 1:
            break
    if x > 1:
        out.append((x, 1))
    return out


def tau_from_factorization(factors: list[tuple[int, int]]) -> int:
    t = 1
    for _p, a in factors:
        t *= a + 1
    return t


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int]:
    g = math.gcd(m, n)
    if (b - a) % g:
        raise AssertionError("incompatible CRT")
    mm, nn = m // g, n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * u) % L, L


def pullback(r: int, L: int, j: int, factors: list[tuple[int, int]] | None = None) -> set[int]:
    m = 4 * j - 1
    g = math.gcd(L, m)
    q = m // g
    if factors is None:
        factors = factor(j)
    ds = divisors_from_factorization(factors)
    R: set[int] = set()
    if q == 1:
        for e in ds:
            for u in ((-e) % m, (-4 * e) % m):
                if (u - r) % g == 0:
                    R.add(0)
        return R

    inv = pow((L // g) % q, -1, q)
    rmod = r % m
    for e in ds:
        for u in ((-e) % m, (-4 * e) % m):
            if (u - r) % g:
                continue
            delta = (u - rmod) % m
            if delta % g:
                raise AssertionError("pullback divisibility mismatch")
            R.add(((delta // g) * inv) % q)
    return R


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("n must be positive and odd")
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


def main() -> None:
    assert 4 * K - 1 == M
    assert K % TARGET_DIVISOR == 0
    assert T == (-TARGET_DIVISOR) % M
    assert math.gcd(M, 840) == 1

    r, L = crt2(H, 840, T, M)
    assert (r, L) == (EXPECTED_R, EXPECTED_L)
    assert r % 840 == H
    assert r % M == T

    # Reconstruct the covering triple independently.
    R25 = pullback(r, L, 25)
    R70 = pullback(r, L, 70)
    R187 = pullback(r, L, 187)
    assert R25 == {1}
    assert R70 == {2}
    assert R187 == {0}
    assert R25 | R70 | R187 == {0, 1, 2}

    assert jacobi(r, 99) == -1
    assert jacobi(r, 279) == -1
    assert jacobi(r, 747) == -1

    # Independent direct-novelty route.
    # tau(j) <= 2*sqrt(j), so |T_j| <= 2*tau(j) <= 4*sqrt(j).
    # Therefore a direct shadow must have q_j <= 4*sqrt(j), and hence
    # q_j <= 4*sqrt(K-1) over the whole earlier range.
    coarse_bound = 4 * math.isqrt(K - 1) + 4
    coarse: list[tuple[int, int]] = []
    for j in range(1, K):
        m = 4 * j - 1
        q = m // math.gcd(L, m)
        if q <= coarse_bound:
            coarse.append((j, q))

    exact_candidates: list[tuple[int, int, list[tuple[int, int]]]] = []
    for j, q in coarse:
        f = factor(j)
        if q <= 2 * tau_from_factorization(f):
            exact_candidates.append((j, q, f))

    direct_shadows: list[dict[str, int]] = []
    for j, q, f in exact_candidates:
        Rj = pullback(r, L, j, f)
        if len(Rj) == q:
            direct_shadows.append({"j": j, "q": q})

    assert len(coarse) == 111_057
    assert len(exact_candidates) == 297
    assert direct_shadows == []

    result = {
        "verdict": "VERIFIED",
        "independent_control_flow": "sqrt divisor bound -> full j scan -> independent factorization -> exact pullbacks",
        "k": K,
        "M": M,
        "h": H,
        "t": T,
        "r": r,
        "L": L,
        "cover": {"25": sorted(R25), "70": sorted(R70), "187": sorted(R187)},
        "coarse_q_bound": coarse_bound,
        "coarse_candidates": len(coarse),
        "exact_cardinality_candidates": len(exact_candidates),
        "direct_shadows": direct_shadows,
    }
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
