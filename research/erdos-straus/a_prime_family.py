#!/usr/bin/env python3
"""Hard primes with A=(p+3)/4 prime or prime-power: first two-target hit.

Independent family attack. Not a proof of Erdős–Straus.
"""
from __future__ import annotations

import json
import math
from collections import Counter


HARD = (1, 121, 169, 289, 361, 529)
QR7 = {1, 2, 4}
QR11 = {1, 3, 4, 5, 9}
QR23 = {1, 2, 3, 4, 6, 8, 9, 12, 13, 16, 18}


def sieve(n: int) -> list[int]:
    bs = bytearray(b"\x01") * (n + 1)
    bs[:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return [i for i, v in enumerate(bs) if v]


def is_prime(n: int, primes: list[int]) -> bool:
    if n < 2:
        return False
    for q in primes:
        if q * q > n:
            return True
        if n % q == 0:
            return n == q
    return True


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
            return out
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def is_prime_power(n: int, primes: list[int]) -> tuple[int, int] | None:
    fac = factor(n, primes)
    if len(fac) == 1:
        r, e = next(iter(fac.items()))
        return r, e
    return None


def box(fac: dict[int, int], mod: int) -> set[int] | None:
    reach = {1}
    for r, e in fac.items():
        if math.gcd(r, mod) != 1:
            return None
        pw = [pow(r, z, mod) for z in range(-e, e + 1)]
        reach = {(x * y) % mod for x in reach for y in pw}
    return reach


def two_target(p: int, k: int, primes: list[int]) -> str | None:
    if math.gcd(k, p) != 1 or (p + k) % 4:
        return None
    B = box(factor((p + k) // 4, primes), k)
    if B is None:
        return None
    i = ((-pow(p, -1, k)) % k) in B
    ii = ((-1) % k) in B
    if i and ii:
        return "both"
    if ii:
        return "II"
    if i:
        return "I"
    return None


def q23_miss(p: int, primes: list[int]) -> str | None:
    C = (p + 23) // 4
    fac = factor(C, primes)
    if all(q % 23 in QR23 for q in fac):
        return "A"
    if fac.get(2, 0) != 1 or fac.get(3, 0) != 1:
        return None
    e = 0
    for q, ex in fac.items():
        r = q % 23
        if q in (2, 3):
            continue
        if r in QR23 and r != 1:
            return None
        if r in (5, 14):
            e += ex
        elif r != 1:
            return None
    return "B" if e <= 2 else None


def main() -> None:
    limit = 2_000_000
    primes = sieve(max(math.isqrt(4 * limit + 50) + 20, 20_000))
    prime_set = set(primes)
    hard = [p for p in sieve(limit) if p % 840 in HARD and p > 23]

    fam = []
    first = Counter()
    kinds = Counter()
    miss23 = []
    for p in hard:
        A = (p + 3) // 4
        pp = is_prime_power(A, primes)
        if pp is None:
            continue
        r, e = pp
        rec = {"p": p, "A": A, "base": r, "exp": e, "mod840": p % 840}
        hit = None
        for h in range(0, 80):
            k = 4 * h + 3
            kind = two_target(p, k, primes)
            if kind:
                hit = (k, kind)
                break
        rec["first"] = None if hit is None else {"k": hit[0], "kind": hit[1]}
        rec["q23"] = two_target(p, 23, primes)
        rec["q23_miss_branch"] = q23_miss(p, primes)
        fam.append(rec)
        if hit:
            first[hit[0]] += 1
            kinds[hit[1]] += 1
        else:
            first["unresolved"] += 1
        if rec["q23"] is None:
            miss23.append(rec)

    print(
        json.dumps(
            {
                "limit": limit,
                "hard": len(hard),
                "A_prime_power": len(fam),
                "A_prime": sum(1 for r in fam if r["exp"] == 1),
                "first_k": dict(sorted((str(k), n) for k, n in first.items())),
                "kinds": dict(kinds),
                "q23_misses": len(miss23),
                "q23_miss_examples": miss23[:20],
                "examples": fam[:25],
                "largest_first_k": None
                if not fam
                else max(
                    (r["first"]["k"] for r in fam if r["first"]),
                    default=None,
                ),
            },
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
