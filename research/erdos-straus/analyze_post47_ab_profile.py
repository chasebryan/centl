#!/usr/bin/env python3
"""Audit bounded Type A/B depth on a supplied fixed-shift survivor set.

This deliberately keeps two coordinates separate:

1. fixed-shift signed-box survival;
2. bounded Type A/B explanation depth.

The Type A/B scan matches the bounded model used by PR #231's cbis-audit:
for A/B index j, m=4j-1, and every divisor split j=d*n, test

  Type B: p == -n  (mod m)
  Type A: p == -4d (mod m).

A finite miss through K never implies that Type A/B is false.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter

POST47_100M = (
    118801,
    496609,
    532249,
    806521,
    2458369,
    8803369,
    10051441,
    11720641,
    13867921,
    14872729,
    16467361,
    22202569,
    22605361,
    25447321,
    25569769,
    28556089,
    32794441,
    33732241,
    39606961,
    53049049,
    54720961,
    55653361,
    70688209,
    74290441,
    77599729,
    80156521,
    90108841,
    95252089,
    99078841,
)


def divisor_pairs(j: int):
    d = 1
    while d * d <= j:
        if j % d == 0:
            n = j // d
            yield d, n
            if d != n:
                yield n, d
        d += 1


def first_ab_hit(p: int, K: int):
    for j in range(1, K + 1):
        m = 4 * j - 1
        r = p % m
        for d, n in divisor_pairs(j):
            if r == (-n) % m:
                return {
                    "type": "B",
                    "ab_index": j,
                    "m": m,
                    "d": d,
                    "n": n,
                }
            if r == (-4 * d) % m:
                return {
                    "type": "A",
                    "ab_index": j,
                    "m": m,
                    "d": d,
                    "n": n,
                }
    return None


def analyze(primes, K: int):
    rows = []
    depth_hist = Counter()
    type_hist = Counter()
    unseen = []
    for p in primes:
        hit = first_ab_hit(p, K)
        if hit is None:
            unseen.append(p)
            rows.append({"p": p, "ab_unseen_through_K": True})
            continue
        depth_hist[hit["ab_index"]] += 1
        type_hist[hit["type"]] += 1
        rows.append({"p": p, "ab_unseen_through_K": False, **hit})

    return {
        "analysis": "post47-fixed-shift-survivor-ab-profile-v1",
        "K": K,
        "primes": len(primes),
        "ab_explained_through_K": len(primes) - len(unseen),
        "ab_unseen_through_K": len(unseen),
        "maximum_first_ab_index": max(
            (row["ab_index"] for row in rows if "ab_index" in row),
            default=None,
        ),
        "type_histogram": dict(sorted(type_hist.items())),
        "depth_histogram": {str(k): v for k, v in sorted(depth_hist.items())},
        "unseen_primes": unseen,
        "rows": rows,
        "claim": (
            "finite bounded Type A/B audit of a separately-defined fixed-shift "
            "survivor set; neither coordinate implies completeness of the other"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--K", type=int, default=71)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("primes", nargs="*", type=int)
    args = ap.parse_args()
    primes = tuple(args.primes) if args.primes else POST47_100M
    report = analyze(primes, args.K)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"primes: {report['primes']}")
        print(f"A/B explained through K={args.K}: {report['ab_explained_through_K']}")
        print(f"A/B unseen through K={args.K}: {report['ab_unseen_through_K']}")
        print(f"max first A/B index: {report['maximum_first_ab_index']}")
        print(f"types: {report['type_histogram']}")
        for row in report["rows"]:
            if row["ab_unseen_through_K"]:
                print(f"p={row['p']}: unseen through {args.K}")
            else:
                print(
                    f"p={row['p']}: {row['type']} j={row['ab_index']} "
                    f"m={row['m']} d={row['d']} n={row['n']}"
                )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
