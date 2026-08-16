#!/usr/bin/env python3
"""Independent finite regression for the k=35 and k=39 hard forced-seed closures."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

import classify_k35_k39_forced_seeds as seeded
import classify_k35_states as k35
import classify_k39_states as k39

HARD = (1, 121, 169, 289, 361, 529)
CONFIG = {
    35: {"forced": 3, "expected_hits_100k": 47, "expected_misses_100k": 226},
    39: {"forced": 2, "expected_hits_100k": 147, "expected_misses_100k": 126},
}


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


def divisor_box(fac: dict[int, int], modulus: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, j, modulus) for j in range(2 * e + 1)}
        reach = {(x * y) % modulus for x in reach for y in vals}
    return reach


def forced_state(modulus: int, fac: dict[int, int]) -> tuple[int, int]:
    forced = CONFIG[modulus]["forced"]
    if fac.get(forced, 0) < 1:
        raise ValueError(f"C{modulus} missing universal factor {forced}")
    direction = seeded.direction_for_residue(modulus, forced)
    state = k35.transition(seeded.START, direction)
    remaining = dict(fac)
    remaining[forced] -= 1
    if remaining[forced] == 0:
        del remaining[forced]
    for q, e in remaining.items():
        g = seeded.direction_for_residue(modulus, q % modulus)
        for _ in range(e):
            state = k35.transition(state, g)
    return state


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    hard = [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]
    trial = primes_up_to(math.isqrt((limit + 39) // 4) + 2)
    mismatch: list[dict[str, object]] = []
    result = {}

    for modulus in (35, 39):
        forced = CONFIG[modulus]["forced"]
        direction = seeded.direction_for_residue(modulus, forced)
        start = k35.transition(seeded.START, direction)
        closed = seeded.closure_from(start)
        miss_fn = k35.is_miss if modulus == 35 else k39.is_miss
        outcomes: Counter[str] = Counter()

        for p in hard:
            C = (p + modulus) // 4
            if C % forced:
                mismatch.append({
                    "kind": "forced-factor-missing", "k": modulus, "p": p, "C": C,
                })
                continue
            fac = factor(C, trial)
            if math.gcd(C, modulus) != 1:
                mismatch.append({
                    "kind": "nonunit-C", "k": modulus, "p": p, "C": C,
                })
                continue
            D = divisor_box(fac, modulus)
            type_i = (-pow(4, -1, modulus)) % modulus
            direct_hit = type_i in D or ((-C) % modulus) in D
            state = forced_state(modulus, fac)
            if state not in closed:
                mismatch.append({
                    "kind": "state-outside-forced-closure", "k": modulus, "p": p, "C": C,
                })
                continue
            if state[1] >= 12:
                mismatch.append({
                    "kind": "hard-center-outside-H", "k": modulus, "p": p, "center": state[1],
                })
                continue
            predicted_hit = not miss_fn(state)
            if direct_hit != predicted_hit:
                mismatch.append({
                    "kind": "forced-state-vs-direct", "k": modulus, "p": p, "C": C,
                    "factorization": fac, "direct_hit": direct_hit,
                    "predicted_hit": predicted_hit,
                })
            outcomes["hit" if direct_hit else "miss"] += 1

        result[str(modulus)] = {
            "hits": outcomes["hit"],
            "misses": outcomes["miss"],
        }

    if limit == 100_000:
        for modulus in (35, 39):
            row = result[str(modulus)]
            if row["hits"] != CONFIG[modulus]["expected_hits_100k"]:
                mismatch.append({"kind": "100k-hit-regression", "k": modulus, "actual": row["hits"]})
            if row["misses"] != CONFIG[modulus]["expected_misses_100k"]:
                mismatch.append({"kind": "100k-miss-regression", "k": modulus, "actual": row["misses"]})

    return {
        "analysis": "k35-k39-forced-seed-structural-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "outcomes": result,
        "mismatches": len(mismatch),
        "mismatch_examples": mismatch[:20],
        "claim": "finite independent regression of two range-free hard-prime forced-seed closures",
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
