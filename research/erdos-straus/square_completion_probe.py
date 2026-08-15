#!/usr/bin/env python3
"""Exact finite census for square-completed Type-II congruence layers.

For layer a, m=4a-1 and

    S_a = {-4D mod m : D | a^2}.

A prime p is counted as captured at a only when at least one representing
D is not divisible by p, matching the exact square-completion theorem.

This is a finite computational certificate generator, not a proof of
universal Erdős--Straus coverage.
"""

from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict

HARD = (1, 121, 169, 289, 361, 529)


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def hard_primes(limit: int) -> list[int]:
    flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        flags[0] = 0
    if limit >= 1:
        flags[1] = 0
    for p in range(2, math.isqrt(limit) + 1):
        if not flags[p]:
            continue
        start = p * p
        count = ((limit - start) // p) + 1
        flags[start : limit + 1 : p] = b"\x00" * count
    hard = set(HARD)
    return [p for p in range(2, limit + 1) if flags[p] and p % 840 in hard]


def square_layer(a: int) -> tuple[int, dict[int, tuple[int, ...]]]:
    m = 4 * a - 1
    by_residue: dict[int, list[int]] = defaultdict(list)
    for D in divisors(a * a):
        by_residue[(-4 * D) % m].append(D)
    return m, {r: tuple(ds) for r, ds in by_residue.items()}


def first_ab_depth(p: int, max_a: int) -> int | None:
    for a in range(1, max_a + 1):
        m = 4 * a - 1
        ds = divisors(a)
        target = p % m
        if any(target == (-d) % m or target == (-4 * d) % m for d in ds):
            return a
    return None


def run(prime_limit: int, a_max: int, compare_ab_max: int) -> dict:
    primes = hard_primes(prime_limit)
    unresolved = set(primes)
    first: dict[int, dict] = {}

    for a in range(1, a_max + 1):
        if not unresolved:
            break
        m, residues = square_layer(a)
        solved: list[int] = []
        for p in unresolved:
            ds = residues.get(p % m)
            if not ds:
                continue
            valid = next((D for D in ds if D % p != 0), None)
            if valid is None:
                continue
            first[p] = {
                "a": a,
                "m": m,
                "D": valid,
                "quotient": (p + 4 * valid) // m,
            }
            solved.append(p)
        for p in solved:
            unresolved.remove(p)

    records: list[dict] = []
    record = 0
    for p in sorted(first):
        w = first[p]
        if w["a"] > record:
            record = w["a"]
            records.append({"p": p, **w})

    deepest = None
    if first:
        p_deep = max(first, key=lambda p: (first[p]["a"], p))
        deepest = {"p": p_deep, **first[p_deep]}
        a = deepest["a"]
        D = deepest["D"]
        q = deepest["quotient"]
        C = (p_deep + q) // 4
        deepest.update(
            {
                "C": C,
                "checks": {
                    "D_divides_a_squared": (a * a) % D == 0,
                    "modulus_divides_p_plus_4D": (p_deep + 4 * D) % deepest["m"] == 0,
                    "D_divides_C_squared": (C * C) % D == 0,
                    "D_plus_C_equals_aq": D + C == a * q,
                    "p_not_divides_D": D % p_deep != 0,
                },
            }
        )
        if compare_ab_max > 0:
            deepest["lopez_ab_first_depth"] = first_ab_depth(p_deep, compare_ab_max)

    return {
        "claim_boundary": "finite exact census only; no universal coverage claim",
        "prime_limit": prime_limit,
        "a_max": a_max,
        "hard_prime_count": len(primes),
        "captured": len(first),
        "unresolved": len(unresolved),
        "max_completed_depth": max((w["a"] for w in first.values()), default=None),
        "deepest": deepest,
        "record_frontier": records,
        "unresolved_primes": sorted(unresolved)[:100],
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--prime-limit", type=int, default=1_000_000)
    ap.add_argument("--a-max", type=int, default=1_000)
    ap.add_argument(
        "--compare-ab-max",
        type=int,
        default=0,
        help="optionally scan López A/B depth for the deepest completed witness",
    )
    args = ap.parse_args()
    if args.prime_limit < 2:
        raise SystemExit("--prime-limit must be >= 2")
    if args.a_max < 1:
        raise SystemExit("--a-max must be >= 1")
    print(
        json.dumps(
            run(args.prime_limit, args.a_max, args.compare_ab_max),
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
