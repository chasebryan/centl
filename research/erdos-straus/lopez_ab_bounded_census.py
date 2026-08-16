#!/usr/bin/env python3
"""Exact Mordell-hard Type A/B bounded census with optional complete survivor audit."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

import lopez_ab_complete_sqrt_audit as complete

HARD_CLASSES = (1, 121, 169, 289, 361, 529)


def primes_upto(n: int) -> list[int]:
    if n < 2:
        return []
    bs = bytearray(b"\x01") * (n + 1)
    bs[0:2] = b"\x00\x00"
    for q in range(2, math.isqrt(n) + 1):
        if bs[q]:
            bs[q * q:n + 1:q] = b"\x00" * (((n - q * q) // q) + 1)
    return [q for q in range(2, n + 1) if bs[q]]


def hard_primes(lo: int, hi: int, block_size: int) -> list[int]:
    """Return exact hard primes in inclusive interval [lo,hi]."""
    if hi < 2 or hi < lo:
        return []
    lo = max(2, lo)
    base = primes_upto(math.isqrt(hi) + 1)
    out: list[int] = []
    for low in range(lo, hi + 1, block_size):
        high = min(hi + 1, low + block_size)
        block = bytearray(b"\x01") * (high - low)
        for q in base:
            start = max(q * q, ((low + q - 1) // q) * q)
            if start >= high:
                continue
            block[start - low:high - low:q] = b"\x00" * (((high - 1 - start) // q) + 1)
        for h in HARD_CLASSES:
            first = low + ((h - low) % 840)
            for p in range(first, high, 840):
                if block[p - low]:
                    out.append(p)
    out.sort()
    return out


def trap_table(K: int) -> tuple[list[int], list[set[int]]]:
    mods = [0] * (K + 1)
    traps: list[set[int]] = [set() for _ in range(K + 1)]
    for k in range(1, K + 1):
        m = 4 * k - 1
        mods[k] = m
        T = traps[k]
        for e in range(1, math.isqrt(k) + 1):
            if k % e:
                continue
            ds = (e,) if e * e == k else (e, k // e)
            for s in ds:
                # Type B: n=s, d=k/s.
                T.add((-s) % m)
                # Type A: d=s, n=k/s.
                T.add((-4 * s) % m)
    return mods, traps


def first_depth(p: int, K: int, mods: list[int], traps: list[set[int]]) -> int | None:
    for k in range(1, K + 1):
        if p % mods[k] in traps[k]:
            return k
    return None


def analyze(
    lo: int,
    hi: int,
    K: int,
    block_size: int,
    complete_survivors: bool,
    survivor_limit: int,
) -> dict[str, object]:
    mods, traps = trap_table(K)
    primes = hard_primes(lo, hi, block_size)
    survivors: list[int] = []
    records: list[dict[str, int]] = []
    deepest = 0
    deepest_p = None
    hist = Counter()

    for p in primes:
        k = first_depth(p, K, mods, traps)
        if k is None:
            survivors.append(p)
            continue
        hist[k] += 1
        if k > deepest:
            deepest = k
            deepest_p = p
            records.append({"p": p, "k": k})

    completed: list[dict[str, object]] = []
    if complete_survivors:
        if len(survivors) > survivor_limit:
            raise SystemExit(
                f"{len(survivors)} bounded survivors exceed --survivor-limit {survivor_limit}"
            )
        for p in survivors:
            report = complete.audit(p)
            completed.append(
                {
                    "p": p,
                    "type_ab_exists": report["type_ab_exists"],
                    "first_type_ab": report["first_type_ab"],
                    "C_AB": report["C_AB"],
                    "lopez_counterexample_candidate": report["lopez_counterexample_candidate"],
                    "type_a_offset_bound": report["type_a_offset_bound"],
                    "type_b_offset_bound": report["type_b_offset_bound"],
                }
            )

    return {
        "analysis": "lopez-ab-bounded-hard-prime-census-v1",
        "lo": lo,
        "hi": hi,
        "K": K,
        "block_size": block_size,
        "hard_primes": len(primes),
        "bounded_hits": len(primes) - len(survivors),
        "bounded_survivors": len(survivors),
        "survivor_primes": survivors,
        "deepest_bounded_hit": {"p": deepest_p, "k": deepest} if deepest_p else None,
        "record_sequence": records,
        "first_depth_histogram": {str(k): v for k, v in sorted(hist.items())},
        "complete_survivor_audits": completed,
        "claim": (
            "exact finite hard-prime census through K; complete survivor audits use the exact square-root "
            "Type A/B coordinate; finite coverage is not a universal Lopez proof"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--lo", type=int, default=2)
    ap.add_argument("--hi", type=int, required=True)
    ap.add_argument("--k-max", type=int, default=5000)
    ap.add_argument("--block-size", type=int, default=5_000_000)
    ap.add_argument("--complete-survivors", action="store_true")
    ap.add_argument("--survivor-limit", type=int, default=100)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    report = analyze(
        args.lo,
        args.hi,
        args.k_max,
        args.block_size,
        args.complete_survivors,
        args.survivor_limit,
    )
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"hard primes: {report['hard_primes']}")
        print(f"bounded survivors: {report['bounded_survivors']}")
        print(f"deepest bounded hit: {report['deepest_bounded_hit']}")
        if report["complete_survivor_audits"]:
            print(f"complete survivors: {report['complete_survivor_audits']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
