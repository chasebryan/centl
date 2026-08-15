#!/usr/bin/env python3
"""Checks for HARD-SMOOTH-TYPEII-OBSTRUCTION.md. Not a proof of Erdős–Straus."""
from __future__ import annotations

import itertools
import math
import sys


HARD = (1, 121, 169, 289, 361, 529)


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("odd positive modulus required")
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


def box(fac: dict[int, int], mod: int) -> set[int] | None:
    reach = {1 % mod}
    for r, e in fac.items():
        if math.gcd(r, mod) != 1:
            return None
        pw = [pow(r, z, mod) for z in range(-e, e + 1)]
        reach = {(x * y) % mod for x in reach for y in pw}
    return reach


def smooth_multipliers() -> list[tuple[int, dict[int, int]]]:
    out = []
    for ex in itertools.product(range(0, 5), range(0, 4), range(0, 3), range(0, 3)):
        fac = {p: e for p, e in zip((2, 3, 5, 7), ex) if e}
        if not fac:
            continue
        M = 1
        for p, e in fac.items():
            M *= p**e
        out.append((M, fac))
    return out


def check_jacobi_and_box() -> None:
    n = 0
    for M, fac in smooth_multipliers():
        for h in HARD:
            k = (-h) % (4 * M)
            if k == 0:
                k = 4 * M
            if k % 4 != 3:
                raise SystemExit(f"k not 3 mod 4: M={M} h={h} k={k}")
            if jacobi(-1, k) != -1:
                raise SystemExit(f"(-1/k) failed M={M} k={k}")
            for r in fac:
                if math.gcd(r, k) != 1:
                    continue
                if jacobi(r, k) != 1:
                    raise SystemExit(f"({r}/{k})={jacobi(r, k)} M={M} h={h}")
            B = box(fac, k)
            if B is None:
                continue
            if ((-1) % k) in B:
                raise SystemExit(f"-1 in box M={M} h={h} k={k}")
            n += 1
    print(f"OK Jacobi+box obstruction on {n} aligned shifts")


def check_family() -> None:
    val = (2 * 3 * 7 * 13 * pow(5, -1, 551)) % 551
    if val != 550:
        raise SystemExit(f"exponent witness failed: {val}")
    A, B, D = 1, 546, 5
    for t in range(0, 21):
        T = t + 1
        p = 10920 * t + 10369
        if 4 * A * B * D * T - A * p - B - D != 0:
            raise SystemExit(f"master identity failed t={t}")
    if 546 * 10369 != 5_661_474:
        raise SystemExit("seed denominator mismatch")
    print("OK 13-family witness and master identity t=0..20")


def main() -> None:
    check_jacobi_and_box()
    check_family()
    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    sys.exit(main())
