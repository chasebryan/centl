#!/usr/bin/env python3
"""Independent finite divisor-box regression for the exact k=47 classifier."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

import classify_k47_states as k47

HARD = (1, 121, 169, 289, 361, 529)
MOD = 47
TYPE_I = (-pow(4, -1, MOD)) % MOD


def sieve_flags(n: int) -> bytearray:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return bs


def primes_up_to(n: int) -> list[int]:
    bs = sieve_flags(n)
    return [p for p in range(2, n + 1) if bs[p]]


def factor(n: int, trial: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial:
        if q * q > x:
            break
        if x % q:
            continue
        e = 0
        while x % q == 0:
            x //= q
            e += 1
        out[q] = e
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisor_box(fac: dict[int, int]) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, f, MOD) for f in range(2 * e + 1)}
        reach = {(x * y) % MOD for x in reach for y in vals}
    return reach


def state_from_factorization(fac: dict[int, int]) -> tuple[int, int]:
    state = (1, 0)
    for q, e in fac.items():
        a = k47.LOG[q % MOD]
        for _ in range(e):
            state = k47.transition(state, a)
    return state


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    hard = [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]
    trial = primes_up_to(math.isqrt((limit + MOD) // 4) + 2)
    closed = k47.closure()
    errors: list[dict[str, object]] = []
    outcomes: Counter[str] = Counter()
    branches: Counter[str] = Counter()

    for p in hard:
        C = (p + MOD) // 4
        fac = factor(C, trial)
        if MOD in fac:
            errors.append({"kind": "nonunit-factor", "p": p, "C": C})
            continue
        D = divisor_box(fac)
        direct_hit = TYPE_I in D or ((-C) % MOD) in D
        state = state_from_factorization(fac)
        if state not in closed:
            errors.append({"kind": "state-outside-closure", "p": p})
            continue
        predicted_hit = not k47.is_miss(state)
        if direct_hit != predicted_hit:
            errors.append({"kind": "state-vs-direct", "p": p, "C": C, "factorization": fac})
        _, center = state
        branch = "+1" if center % 2 == 0 else "-1"
        symbol = pow(p % MOD, (MOD - 1) // 2, MOD)
        if branch != ("+1" if symbol == 1 else "-1"):
            errors.append({"kind": "legendre-parity", "p": p, "center": center})
        outcomes["hit" if direct_hit else "miss"] += 1
        branches[f"{branch}:{'hit' if direct_hit else 'miss'}"] += 1

    return {
        "analysis": "k47-structural-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "direct_hits": outcomes["hit"],
        "direct_misses": outcomes["miss"],
        "legendre_outcomes": dict(sorted(branches.items())),
        "mismatches": len(errors),
        "mismatch_examples": errors[:20],
        "claim": "finite independent divisor-box regression of a range-free state classification",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
