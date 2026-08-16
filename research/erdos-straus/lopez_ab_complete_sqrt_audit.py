#!/usr/bin/env python3
"""Complete square-root-width López Type A/B audit for one odd integer.

This uses the exact reparameterizations proved in
LOPEZ-AB-SQRT-COMPLETE-AUDIT.md.  It does not impose an empirical K cutoff.
"""
from __future__ import annotations

import argparse
import json
import math
from typing import Iterable

HARD_CLASSES = frozenset((1, 121, 169, 289, 361, 529))
MR64_BASES = (2, 325, 9375, 28178, 450775, 9780504, 1795265022)


def is_prime64(n: int) -> bool:
    if n < 2:
        return False
    small = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for q in small:
        if n % q == 0:
            return n == q
    d = n - 1
    s = 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for a in MR64_BASES:
        if a % n == 0:
            continue
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = (x * x) % n
            if x == n - 1:
                break
        else:
            return False
    return True


def primes_upto(n: int) -> list[int]:
    if n < 2:
        return []
    sieve = bytearray(b"\x01") * (n + 1)
    sieve[0:2] = b"\x00\x00"
    for q in range(2, math.isqrt(n) + 1):
        if sieve[q]:
            start = q * q
            sieve[start:n + 1:q] = b"\x00" * (((n - start) // q) + 1)
    return [q for q in range(2, n + 1) if sieve[q]]


def factor_offset_interval(p: int, width: int) -> list[dict[int, int]]:
    """Factor every p+a for 1<=a<=width by one segmented prime pass."""
    if width < 1:
        return []
    remaining = [p + a for a in range(1, width + 1)]
    factors: list[dict[int, int]] = [{} for _ in range(width)]
    for q in primes_upto(math.isqrt(p + width)):
        a0 = (-p) % q
        if a0 == 0:
            a0 = q
        for a in range(a0, width + 1, q):
            i = a - 1
            e = 0
            while remaining[i] % q == 0:
                remaining[i] //= q
                e += 1
            if e:
                factors[i][q] = e
    for i, x in enumerate(remaining):
        if x > 1:
            factors[i][x] = factors[i].get(x, 0) + 1
    return factors


def divisors(factors: dict[int, int]) -> Iterable[int]:
    out = [1]
    for q, e in factors.items():
        powers = [1]
        for _ in range(e):
            powers.append(powers[-1] * q)
        out = [d * power for d in out for power in powers]
    return out


def type_a_offset_bound(p: int) -> int:
    return 1 + math.isqrt(p + 1)


def type_b_offset_bound(p: int) -> int:
    a = (1 + math.isqrt(1 + 4 * p)) // 4
    while 4 * (a + 1) * (a + 1) - 2 * (a + 1) <= p:
        a += 1
    while a > 0 and 4 * a * a - 2 * a > p:
        a -= 1
    return a


def verify_type_a(p: int, d: int, n: int) -> bool:
    m = 4 * d * n - 1
    return m > 0 and p % m == (-4 * d) % m


def verify_type_b(p: int, d: int, n: int) -> bool:
    m = 4 * d * n - 1
    return m > 0 and p % m == (-n) % m


def audit(p: int, include_all: bool = False) -> dict[str, object]:
    if p < 3 or p % 2 == 0:
        raise ValueError("complete square-root audit currently requires an odd p >= 3")

    a_max = type_a_offset_bound(p)
    b_max = type_b_offset_bound(p)
    factorizations = factor_offset_interval(p, a_max)
    quotient_mod4 = (-p) % 4

    type_a: set[tuple[int, int, int, int, int]] = set()
    type_b: set[tuple[int, int, int, int, int]] = set()

    for a in range(1, a_max + 1):
        N = p + a
        ds = divisors(factorizations[a - 1])

        # Type A: p = n*u*s-u-s, where u=4d and s==-p mod 4.
        for r in ds:
            if r % a != (a - 1) % a:
                continue
            b = N // r
            if b < a:
                continue
            n = (r + 1) // a
            if n < 1:
                continue
            if a % 4 == 0 and b % 4 == quotient_mod4:
                u, quotient = a, b
            elif b % 4 == 0 and a % 4 == quotient_mod4:
                u, quotient = b, a
            else:
                continue
            d = u // 4
            if p != 4 * d * n * quotient - quotient - 4 * d:
                raise RuntimeError("Type A reconstruction identity failed")
            if not verify_type_a(p, d, n):
                raise RuntimeError("Type A reconstructed congruence failed")
            k = d * n
            m = 4 * k - 1
            type_a.add((k, d, n, quotient, m))

        if a > b_max:
            continue

        # Type B is symmetric in n and the positive quotient.  Canonicalize
        # by choosing n=a=min(n,quotient); this preserves existence and cannot
        # increase K=dn.
        for r in ds:
            if r % (4 * a) != (4 * a - 1) % (4 * a):
                continue
            b = N // r
            if b < a:
                continue
            d = (r + 1) // (4 * a)
            if d < 1:
                continue
            n = a
            quotient = b
            if p != 4 * d * n * quotient - n - quotient:
                raise RuntimeError("Type B reconstruction identity failed")
            if not verify_type_b(p, d, n):
                raise RuntimeError("Type B reconstructed congruence failed")
            k = d * n
            m = 4 * k - 1
            type_b.add((k, d, n, quotient, m))

    A = sorted(type_a)
    B = sorted(type_b)
    candidates = [(row[0], "A", row) for row in A] + [(row[0], "B", row) for row in B]
    # Match the historical bounded auditor's same-K preference for B.
    candidates.sort(key=lambda item: (item[0], 0 if item[1] == "B" else 1, item[2]))

    first = None
    if candidates:
        _, typ, row = candidates[0]
        k, d, n, quotient, m = row
        first = {
            "type": typ,
            "k": k,
            "m": m,
            "d": d,
            "n_parameter": n,
            "quotient": quotient,
        }

    def rows(values: list[tuple[int, int, int, int, int]]) -> list[dict[str, int]]:
        return [
            {
                "k": k,
                "m": m,
                "d": d,
                "n_parameter": n,
                "quotient": quotient,
            }
            for k, d, n, quotient, m in values
        ]

    result: dict[str, object] = {
        "analysis": "lopez-ab-complete-sqrt-audit-v1",
        "p": p,
        "prime64": is_prime64(p),
        "hard_prime": is_prime64(p) and p % 840 in HARD_CLASSES,
        "complete": True,
        "type_a_offset_bound": a_max,
        "type_b_offset_bound": b_max,
        "factored_offsets": a_max,
        "type_a_certificate_count": len(A),
        "type_b_canonical_certificate_count": len(B),
        "type_ab_exists": bool(candidates),
        "first_type_ab": first,
        "C_AB": first["k"] if first else None,
        "lopez_counterexample_candidate": is_prime64(p) and not candidates,
        "claim": (
            "complete fixed-p Type A/B decision from exact square-root reparameterization; "
            "an empty result should be independently reproduced before any public falsification claim"
        ),
    }
    if include_all:
        result["type_a_certificates"] = rows(A)
        result["type_b_canonical_certificates"] = rows(B)
    return result


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("p", type=int)
    ap.add_argument("--all", action="store_true", help="include every reconstructed certificate")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    try:
        report = audit(args.p, include_all=args.all)
    except (ValueError, RuntimeError) as exc:
        raise SystemExit(str(exc)) from exc

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"p: {report['p']}")
        print(f"complete: {report['complete']}")
        print(f"Type A offset bound: {report['type_a_offset_bound']}")
        print(f"Type B offset bound: {report['type_b_offset_bound']}")
        print(f"Type A certificates: {report['type_a_certificate_count']}")
        print(f"Type B canonical certificates: {report['type_b_canonical_certificate_count']}")
        print(f"first Type A/B: {report['first_type_ab']}")
        if report["lopez_counterexample_candidate"]:
            print("WARNING: complete Type A/B miss for a prime; independently reproduce before any claim")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
