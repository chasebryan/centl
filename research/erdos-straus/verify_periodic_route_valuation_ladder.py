#!/usr/bin/env python3
"""Exact regression for periodic routed-factor valuation lifts."""
from __future__ import annotations

import argparse
import json
import math


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    d = 3
    while d * d <= n:
        if n % d == 0:
            return False
        d += 2
    return True


def valuation(n: int, q: int) -> int:
    e = 0
    while n % q == 0:
        n //= q
        e += 1
    return e


def companion(p: int, k: int) -> int:
    if (p + k) % 4:
        raise AssertionError((p, k))
    return (p + k) // 4


def verify_single_route_family(q: int, k0: int, m: int, max_level: int) -> int:
    if not is_prime(q) or q % 2 == 0:
        raise AssertionError(q)
    if k0 % 4 != 3 or k0 % q == 0:
        raise AssertionError((q, k0))

    p = 4 * q * m - k0
    if p <= 0 or p % 4 != 1:
        raise AssertionError((p, q, k0, m))
    c0 = companion(p, k0)
    assert c0 == q * m

    checked = 0
    for level in range(1, max_level + 1):
        period = q ** (level - 1)
        lift_residue = (-m) % period if period > 1 else 0
        lifts = 0
        for n in range(period):
            k = k0 + 4 * q * n
            c = companion(p, k)
            assert c == q * (m + n)
            expected = (m + n) % period == 0
            actual = c % (q ** level) == 0
            assert actual == expected
            lifts += int(actual)
            checked += 1
        assert lifts == 1
        assert lift_residue < period

    return checked


def verify_generic_grid(max_q: int, max_level: int) -> dict[str, int]:
    checked_families = 0
    checked_representatives = 0
    for q in range(3, max_q + 1, 2):
        if not is_prime(q):
            continue
        for k0 in range(3, 4 * q, 4):
            if k0 % q == 0:
                continue
            for m in (1, 2, q - 1, q + 1, 2 * q + 3):
                checked_representatives += verify_single_route_family(q, k0, m, max_level)
                checked_families += 1
    return {
        "generic_families_checked": checked_families,
        "route_representatives_checked": checked_representatives,
    }


def verify_multisource_lift() -> dict[str, int]:
    # Record branch: q11 and q23 both route into k0=19.
    p = 8_803_369
    k0 = 19
    q_product = 11 * 23
    c0 = companion(p, k0)
    assert c0 == q_product * 8_699
    residual = c0 // q_product

    # Repeating by 4Q preserves every routed source factor simultaneously:
    # C_{k0+4Qt}=Q(R+t).
    t = (-residual) % q_product
    k = k0 + 4 * q_product * t
    c = companion(p, k)
    assert c == q_product * (residual + t)
    assert c % (q_product * q_product) == 0
    assert t == 156
    assert k == 157_891
    assert c == 2_240_315
    assert c // (q_product * q_product) == 35

    return {
        "Q": q_product,
        "square_lift_t": t,
        "square_lift_k": k,
        "square_lift_companion": c,
    }


def verify_k107_anchor() -> dict[str, int]:
    p = 8_803_369
    q = 11
    k0 = 19
    c0 = companion(p, k0)
    assert c0 == 2_200_847
    assert c0 % q == 0
    m = c0 // q
    assert m == 200_077

    # k_n = 19 + 44 n. Exactly n=2 mod11 lifts 11 to 11^2.
    square_residue = (-m) % q
    assert square_residue == 2
    k = k0 + 4 * q * square_residue
    assert k == 107
    c = companion(p, k)
    assert c == 2_200_869
    assert c == 11 * 11 * 18_189
    assert valuation(c, 11) == 2

    # The q^2 lift supplies the exact complementary divisor in the known
    # Type-II certificate. Because q is invertible mod k, d=q^2 reaches the
    # Type-II target iff B=C/q^2 is -1 mod k.
    d = q * q
    b = c // d
    assert math.gcd(q, k) == 1
    assert d % k == (-c) % k
    assert b % k == k - 1
    assert b == 170 * k - 1

    # The complete first square-lift window is k=19,63,...,459.
    square_lifts = []
    for n in range(q):
        kn = k0 + 4 * q * n
        cn = companion(p, kn)
        assert cn == q * (m + n)
        if cn % (q * q) == 0:
            square_lifts.append((n, kn))
    assert square_lifts == [(2, 107)]

    return {
        "p": p,
        "q": q,
        "route_k0": k0,
        "route_residual_M": m,
        "square_lift_n": square_residue,
        "square_lift_k": k,
        "C107": c,
        "type_ii_divisor": d,
        "type_ii_quotient": b,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-q", type=int, default=97)
    parser.add_argument("--max-level", type=int, default=3)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    generic = verify_generic_grid(args.max_q, args.max_level)
    multi = verify_multisource_lift()
    anchor = verify_k107_anchor()
    report = {
        "analysis": "periodic-route-valuation-ladder-regression-v1",
        "max_q": args.max_q,
        "max_level": args.max_level,
        **generic,
        "multisource_record_lift": multi,
        "k107_record_anchor": anchor,
        "failures": 0,
        "claim": (
            "exact arithmetic regression of C_{k0+4qn}=q(M+n), its q-adic lift "
            "schedule, the simultaneous squarefree-Q lift, and the k107 Type-II anchor"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"generic families checked: {generic['generic_families_checked']}")
        print(f"route representatives checked: {generic['route_representatives_checked']}")
        print(f"k107 anchor: {anchor}")
        print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
