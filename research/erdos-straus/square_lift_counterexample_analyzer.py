#!/usr/bin/env python3
"""Construct explicit escaping square lifts for every non-universal base.

Implements the converse proof in
UNIVERSAL-SQUARE-LIFT-SHADOW-CLASSIFICATION.md.

For each j in a finite range except 1,2,4:

1. find a Jacobi-negative unit v outside T_j;
2. put u=-v mod m, which is Jacobi-positive;
3. find a prime ell == u mod m;
4. solve c^2 == -m^{-1} mod ell by Tonelli-Shanks;
5. choose c odd and >1;
6. form K=(m*c^2+1)/4;
7. verify ell|K and -ell mod m=v outside T_j.

The resulting tuple is a direct certificate that the base does not shadow its
entire odd square-lift tower.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("Jacobi denominator must be positive odd")
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


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    small = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for p in small:
        if n % p == 0:
            return n == p
    d = n - 1
    s = 0
    while d % 2 == 0:
        d //= 2
        s += 1
    # Deterministic for unsigned 64-bit integers.
    for a in (2, 325, 9375, 28178, 450775, 9780504, 1795265022):
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


def tonelli_shanks(n: int, p: int) -> int:
    """Return x with x^2=n mod odd prime p, assuming a root exists."""
    n %= p
    if n == 0:
        return 0
    if p == 2:
        return n
    if pow(n, (p - 1) // 2, p) != 1:
        raise ValueError("not a quadratic residue")
    if p % 4 == 3:
        return pow(n, (p + 1) // 4, p)

    q = p - 1
    s = 0
    while q % 2 == 0:
        s += 1
        q //= 2

    z = 2
    while pow(z, (p - 1) // 2, p) != p - 1:
        z += 1

    c = pow(z, q, p)
    x = pow(n, (q + 1) // 2, p)
    t = pow(n, q, p)
    m = s
    while t != 1:
        i = 1
        tt = (t * t) % p
        while tt != 1:
            tt = (tt * tt) % p
            i += 1
            if i == m:
                raise AssertionError("Tonelli-Shanks failed")
        b = pow(c, 1 << (m - i - 1), p)
        x = (x * b) % p
        t = (t * b * b) % p
        c = (b * b) % p
        m = i
    return x


def first_missing_negative(m: int, T: set[int]) -> int:
    for v in range(1, m):
        if math.gcd(v, m) == 1 and jacobi(v, m) == -1 and v not in T:
            return v
    raise AssertionError("base appears Jacobi-saturated")


def prime_in_progression(u: int, m: int, max_steps: int) -> tuple[int, int]:
    start = u if u >= 2 else u + m
    if start % 2 == 0:
        start += m
    ell = start
    steps = 0
    while steps <= max_steps:
        if ell > 2 and is_prime(ell):
            return ell, steps
        ell += m
        steps += 1
    raise RuntimeError(f"no progression prime found within {max_steps} steps for u={u}, m={m}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--j-limit", type=int, default=5000)
    ap.add_argument("--prime-search-steps", type=int, default=200000)
    ap.add_argument("--out", type=Path, default=Path("square-lift-counterexample-output"))
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    records: list[dict] = []
    max_ell = 0
    max_c = 0
    max_K = 0
    max_steps = 0
    examples: list[dict] = []

    for j in range(1, args.j_limit + 1):
        if j in (1, 2, 4):
            continue
        m = 4 * j - 1
        T = trap_set(j)
        v = first_missing_negative(m, T)
        u = (-v) % m
        if jacobi(u, m) != 1:
            raise AssertionError("negating missing trap did not produce positive Jacobi class")

        ell, steps = prime_in_progression(u, m, args.prime_search_steps)
        if ell % m != u:
            raise AssertionError("progression prime has wrong residue")
        if jacobi(ell, m) != 1:
            raise AssertionError("progression prime has wrong Jacobi sign")

        rhs = (-pow(m, -1, ell)) % ell
        if pow(rhs, (ell - 1) // 2, ell) != 1:
            raise AssertionError("-m inverse is not a square modulo ell")
        root = tonelli_shanks(rhs, ell)
        if (root * root - rhs) % ell:
            raise AssertionError("bad Tonelli-Shanks root")

        c = root
        if c % 2 == 0:
            c += ell
        if c <= 1:
            c += 2 * ell
        if c % 2 == 0 or c <= 1:
            raise AssertionError("failed to choose a nontrivial odd lift")

        K_num = m * c * c + 1
        if K_num % 4:
            raise AssertionError("lift numerator not divisible by four")
        K = K_num // 4
        if K <= j:
            raise AssertionError("constructed lift is not later than base")
        if K % ell:
            raise AssertionError("constructed prime does not divide lifted depth")

        escaping = (-ell) % m
        if escaping != v:
            raise AssertionError("escaping residue does not match missing negative residue")
        if escaping in T:
            raise AssertionError("constructed lifted trap does not escape base")

        rec = {
            "j": j,
            "m": m,
            "missing_negative_v": v,
            "positive_class_u": u,
            "progression_prime_ell": ell,
            "prime_search_steps": steps,
            "odd_lift_c": c,
            "lift_depth_K": K,
            "escaping_trap_residue_mod_m": escaping,
        }
        records.append(rec)
        if len(examples) < args.examples or steps > max_steps or ell > max_ell:
            examples.append(rec)
            examples = examples[-args.examples:]

        max_ell = max(max_ell, ell)
        max_c = max(max_c, c)
        max_K = max(max_K, K)
        max_steps = max(max_steps, steps)

        if j % 500 == 0:
            print(
                f"counter-lift progress {j}/{args.j_limit} certs={len(records)} "
                f"max_ell={max_ell} max_steps={max_steps}",
                flush=True,
            )

    expected = args.j_limit - len([x for x in (1, 2, 4) if x <= args.j_limit])
    if len(records) != expected:
        raise AssertionError("certificate count mismatch")

    result = {
        "status": "constructive nonuniversal square-lift certificates",
        "j_limit": args.j_limit,
        "bases_certified_nonuniversal": len(records),
        "universal_bases_skipped": [x for x in (1, 2, 4) if x <= args.j_limit],
        "maximum_progression_prime": max_ell,
        "maximum_prime_search_steps": max_steps,
        "maximum_odd_lift_parameter": max_c,
        "maximum_constructed_lift_depth": max_K,
        "examples": examples,
        "all_certificates": records,
        "claim_boundary": (
            "Each finite record explicitly disproves universal square-lift shadowing for that base. "
            "The universal classification proof is in UNIVERSAL-SQUARE-LIFT-SHADOW-CLASSIFICATION.md."
        ),
    }
    (args.out / "square-lift-counterexamples.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Constructive square-lift counterexamples\n\n"
    report += f"Bases checked: `1 <= j <= {args.j_limit}`.\n\n"
    report += f"Universal bases skipped by theorem: `{result['universal_bases_skipped']}`.\n\n"
    report += f"Nonuniversal bases with explicit escaping lift certificate: **`{len(records)}`**.\n\n"
    report += f"Maximum progression prime used: `{max_ell}`.\n\n"
    report += f"Maximum arithmetic-progression search steps: `{max_steps}`.\n\n"
    report += f"Maximum constructed lift depth: `{max_K}`.\n\n"
    report += "Every certificate verifies `ell|K` and `-ell mod (4j-1)` outside the base trap set.\n"
    (args.out / "square-lift-counterexamples-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
