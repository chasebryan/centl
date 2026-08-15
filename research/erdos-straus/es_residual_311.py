#!/usr/bin/env python3
"""Residual census after exact 3,7,11 two-target filters plus linear forms.

Standard-library only. Finite mining tool, not a proof of Erdős–Straus.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter


HARD = (1, 121, 169, 289, 361, 529)
QR7 = {1, 2, 4}
QR11 = {1, 3, 4, 5, 9}
NR11 = {2, 6, 7, 8, 10}


def sieve_primes(n: int) -> list[int]:
    if n < 2:
        return []
    bs = bytearray(b"\x01") * (n + 1)
    bs[:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            start = p * p
            bs[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [i for i, v in enumerate(bs) if v]


def factorint(n: int, trial: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial:
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


def signed_box(fac: dict[int, int], mod: int) -> set[int]:
    reach = {1 % mod}
    for r, e in fac.items():
        if math.gcd(r, mod) != 1:
            return set()
        powers = [pow(r, z, mod) for z in range(-e, e + 1)]
        reach = {(x * y) % mod for x in reach for y in powers}
    return reach


def all_in(n: int, trial: list[int], pred) -> bool:
    return all(pred(q) for q in factorint(n, trial))


def q3_miss(p: int, trial: list[int]) -> bool:
    return all_in((p + 3) // 4, trial, lambda q: q % 3 == 1)


def q7_typeII_miss(p: int, trial: list[int]) -> bool:
    return all_in((p + 7) // 4, trial, lambda q: q % 7 in QR7)


def q11_typeII_miss(p: int, trial: list[int]) -> bool:
    C = (p + 11) // 4
    fac = factorint(C, trial)
    # Branch A
    if all(q % 11 in QR11 for q in fac):
        return True
    # Branch B
    if fac.get(3, 0) != 1:
        return False
    e_prim = 0
    for q, e in fac.items():
        r = q % 11
        if r in (7, 8, 10):
            return False
        if r in (3, 4, 5, 9) and q != 3:
            return False
        if r in (2, 6):
            e_prim += e
        if r == 1:
            continue
    return e_prim <= 2


def two_target(p: int, k: int, trial: list[int]) -> str | None:
    if math.gcd(k, p) != 1 or (p + k) % 4:
        return None
    box = signed_box(factorint((p + k) // 4, trial), k)
    if not box:
        return None
    ii = (-1) % k in box
    i = (-pow(p, -1, k)) % k in box
    if i and ii:
        return "both"
    if ii:
        return "II"
    if i:
        return "I"
    return None


def linear_ok(p: int, trial: list[int]) -> bool:
    if not all_in((p + 1) // 2, trial, lambda q: q == 2 or q % 4 == 1):
        return False
    if not all_in(p + 2, trial, lambda q: q % 8 in (1, 3)):
        return False
    if not all_in(4 * p + 1, trial, lambda q: q % 4 == 1):
        return False
    if not all_in(p + 4, trial, lambda q: q % 4 == 1):
        return False
    if not all_in(2 * p + 1, trial, lambda q: q % 8 in (1, 3)):
        return False
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=1_000_000)
    ap.add_argument("--k-scan", type=int, default=200)
    args = ap.parse_args()

    trial = sieve_primes(max(math.isqrt(4 * args.limit + 50) + 20, 10_000))
    hard = [p for p in sieve_primes(args.limit) if p % 840 in HARD and p > 11]

    stages = Counter()
    residual = []
    first_after = Counter()
    kind_after = Counter()
    p_mod = Counter()
    examples = []

    for p in hard:
        if not q3_miss(p, trial):
            stages["hit_q3"] += 1
            continue
        if not q7_typeII_miss(p, trial):
            stages["hit_q7"] += 1
            continue
        # Type I cannot rescue q=7 for hard p; skip
        if not q11_typeII_miss(p, trial):
            stages["hit_q11_II"] += 1
            continue
        hit11 = two_target(p, 11, trial)
        if hit11 in ("I", "both"):
            stages[f"hit_q11_I_{hit11}"] += 1
            continue
        stages["miss_3_7_11"] += 1
        if linear_ok(p, trial):
            stages["miss_3_7_11_and_linear"] += 1
        residual.append(p)
        p_mod[p % 840] += 1
        won = None
        for h in range(3, (args.k_scan - 3) // 4 + 1):
            k = 4 * h + 3
            kind = two_target(p, k, trial)
            if kind:
                won = (k, kind)
                break
        if won:
            first_after[won[0]] += 1
            kind_after[won[1]] += 1
        else:
            first_after["unresolved"] += 1
        if len(examples) < 30:
            A = (p + 3) // 4
            examples.append(
                {
                    "p": p,
                    "mod840": p % 840,
                    "mod11": p % 11,
                    "mod7": p % 7,
                    "mod23": p % 23,
                    "jacobi11": jacobi(11, p),
                    "A_factors": factorint(A, trial),
                    "A1_factors": factorint(A + 1, trial),
                    "A2_factors": factorint(A + 2, trial),
                    "A3_factors": factorint(A + 3, trial),
                    "A5_factors": factorint(A + 5, trial),
                    "first": None if won is None else {"k": won[0], "kind": won[1]},
                    "linear_ok": linear_ok(p, trial),
                }
            )

    print(
        json.dumps(
            {
                "limit": args.limit,
                "hard": len(hard),
                "stages": dict(stages),
                "residual_after_3_7_11": len(residual),
                "residual_mod840": dict(sorted(p_mod.items())),
                "first_hit_after_11": dict(sorted((str(k), n) for k, n in first_after.items())),
                "kind_after": dict(kind_after),
                "examples": examples,
                "claim_boundary": "finite census only",
            },
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
