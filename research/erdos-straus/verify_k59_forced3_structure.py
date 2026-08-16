#!/usr/bin/env python3
"""Independent finite regression for the hard-prime k=59 forced-3 closure."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

import classify_k59_forced3_states as forced3
import classify_k59_states as core

HARD = (1, 121, 169, 289, 361, 529)
MOD = 59
TYPE_I = (-pow(4, -1, MOD)) % MOD


def sieve_flags(n: int) -> bytearray:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for q in range(2, math.isqrt(n) + 1):
        if bs[q]:
            bs[q * q : n + 1 : q] = b"\x00" * (((n - q * q) // q) + 1)
    return bs


def primes_up_to(n: int) -> list[int]:
    bs = sieve_flags(n)
    return [q for q in range(2, n + 1) if bs[q]]


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
        vals = {pow(q, j, MOD) for j in range(2 * e + 1)}
        reach = {(x * y) % MOD for x in reach for y in vals}
    return reach


def forced_state_from_factorization(fac: dict[int, int]) -> tuple[int, int]:
    if fac.get(3, 0) < 1:
        raise ValueError("hard-prime C59 is missing the universal factor 3")
    state = forced3.forced_start()
    remaining = dict(fac)
    remaining[3] -= 1
    if remaining[3] == 0:
        del remaining[3]
    for q, e in remaining.items():
        a = core.LOG[q % MOD]
        for _ in range(e):
            state = core.transition(state, a)
    return state


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    hard = [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]
    trial = primes_up_to(math.isqrt((limit + MOD) // 4) + 2)
    closed = forced3.closure()

    mismatch: list[dict[str, object]] = []
    outcomes: Counter[str] = Counter()

    for p in hard:
        C = (p + MOD) // 4
        if C % 3:
            mismatch.append({"kind": "forced-factor-missing", "p": p, "C": C})
            continue
        fac = factor(C, trial)
        D = divisor_box(fac)
        direct_hit = TYPE_I in D or ((-C) % MOD) in D

        state = forced_state_from_factorization(fac)
        if state not in closed:
            mismatch.append({"kind": "state-outside-forced-closure", "p": p, "C": C})
            continue
        predicted_hit = not core.is_miss(state)
        if direct_hit != predicted_hit:
            mismatch.append({
                "kind": "forced-state-vs-direct",
                "p": p,
                "C": C,
                "factorization": fac,
                "direct_hit": direct_hit,
                "predicted_hit": predicted_hit,
            })

        outcomes["hit" if direct_hit else "miss"] += 1

    return {
        "analysis": "k59-forced3-structural-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "direct_hits": outcomes["hit"],
        "direct_misses": outcomes["miss"],
        "mismatches": len(mismatch),
        "mismatch_examples": mismatch[:20],
        "claim": "finite independent regression of a range-free hard-prime forced-3 closure",
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
