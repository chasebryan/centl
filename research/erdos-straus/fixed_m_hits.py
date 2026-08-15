#!/usr/bin/env python3
"""List exact hard subclasses for which a fixed M gives a uniform Type-II hit."""
from __future__ import annotations

import json
import math
import sys


HARD = (1, 121, 169, 289, 361, 529)


def box(fac: dict[int, int], mod: int) -> set[int] | None:
    reach = {1 % mod}
    for r, e in fac.items():
        if math.gcd(r, mod) != 1:
            return None
        pw = [pow(r, z, mod) for z in range(-e, e + 1)]
        reach = {(x * y) % mod for x in reach for y in pw}
    return reach


def factorize(n: int) -> dict[int, int]:
    fac: dict[int, int] = {}
    x = n
    d = 2
    while d * d <= x:
        while x % d == 0:
            fac[d] = fac.get(d, 0) + 1
            x //= d
        d += 1 if d == 2 else 2
    if x > 1:
        fac[x] = fac.get(x, 0) + 1
    return fac


def jacobi(a: int, n: int) -> int:
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


def hits_for_M(M: int) -> list[dict]:
    fac = factorize(M)
    mod = 4 * M
    hits = []
    for h in HARD:
        r = h
        while r < mod:
            if math.gcd(r, mod) == 1:
                k = (-r) % mod
                if k == 0:
                    k = mod
                B = box(fac, k)
                if B is not None and ((-1) % k) in B:
                    signs = {p: jacobi(p, k) for p in fac}
                    hits.append(
                        {
                            "M": M,
                            "r": r,
                            "mod": mod,
                            "k": k,
                            "hard": h,
                            "jacobi": signs,
                            "box": len(B),
                        }
                    )
            r += 840
    return hits


def main() -> None:
    Ms = [
        210,
        420,
        630,
        1050,
        1470,
        2310,
        2730,
        4290,
        4620,
        5460,
        6930,
        8590,
        9240,
        11550,
        13860,
        15015,
        30030,
    ]
    # 8590 is not 210-smooth-times-11; keep only 210 | M
    Ms = [M for M in Ms if M % 210 == 0]
    all_hits = []
    for M in Ms:
        hs = hits_for_M(M)
        all_hits.extend(hs)
        print(f"M={M:6d}  hits={len(hs):3d}  subclasses={4*M//840 * 6}", flush=True)
    print(json.dumps({"hit_count": len(all_hits), "hits": all_hits}, indent=2))


if __name__ == "__main__":
    main()
