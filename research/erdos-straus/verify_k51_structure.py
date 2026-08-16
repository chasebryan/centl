#!/usr/bin/env python3
"""Independent finite regression for the exact k=51 state classification.

Generates Mordell-hard primes, factors C=(p+51)/4, builds the divisor residue
set of C^2 directly modulo 51, and compares direct two-target membership with
the separately closed C16 x C2 state classifier.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

import classify_k51_states as k51

HARD = (1, 121, 169, 289, 361, 529)
MOD = 51
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
        residue = q % MOD
        if residue not in k51.RESIDUE_TO_COORD:
            raise ValueError(f"non-unit factor residue {residue} mod 51")
        g = k51.RESIDUE_TO_COORD[residue]
        for _ in range(e):
            state = k51.transition(state, g)
    return state


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    hard = [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]
    trial = primes_up_to(math.isqrt((limit + MOD) // 4) + 2)
    closed = k51.closure()

    mismatch: list[dict[str, object]] = []
    outcomes: Counter[str] = Counter()
    legendre: Counter[str] = Counter()

    for p in hard:
        C = (p + MOD) // 4
        fac = factor(C, trial)
        if 3 in fac or 17 in fac:
            mismatch.append({"kind": "nonunit-factor", "p": p, "C": C, "factorization": fac})
            continue

        D = divisor_box(fac)
        direct_hit = TYPE_I in D or ((-C) % MOD) in D

        state = state_from_factorization(fac)
        if state not in closed:
            mismatch.append({"kind": "state-outside-closure", "p": p, "C": C})
            continue
        predicted_hit = not k51.is_miss(state)
        if direct_hit != predicted_hit:
            mismatch.append({
                "kind": "state-vs-direct",
                "p": p,
                "C": C,
                "factorization": fac,
                "direct_hit": direct_hit,
                "predicted_hit": predicted_hit,
            })

        _, center = state
        if center >= k51.N:
            mismatch.append({"kind": "hard-center-outside-H", "p": p, "center": center})
            continue
        branch = "+1" if center % 2 == 0 else "-1"
        actual_symbol = pow(p % 17, 8, 17)
        symbol_branch = "+1" if actual_symbol == 1 else "-1"
        if branch != symbol_branch:
            mismatch.append({"kind": "legendre17-parity", "p": p, "center": center})

        outcomes["hit" if direct_hit else "miss"] += 1
        legendre[f"{branch}:{'hit' if direct_hit else 'miss'}"] += 1

    return {
        "analysis": "k51-structural-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "direct_hits": outcomes["hit"],
        "direct_misses": outcomes["miss"],
        "legendre17_outcomes": dict(sorted(legendre.items())),
        "mismatches": len(mismatch),
        "mismatch_examples": mismatch[:20],
        "claim": "finite independent divisor-box regression of a range-free finite-group classification",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.limit < MOD:
        raise SystemExit("--limit must be >= 51")
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
