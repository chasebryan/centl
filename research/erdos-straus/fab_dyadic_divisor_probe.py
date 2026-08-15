#!/usr/bin/env python3
"""Exact finite probe for FAB-DYADIC-DIVISOR-LIFT-CONJECTURE.md.

For each Mordell-hard prime p, test only adaptive nodes

    t | (p-1)/2,   d = 4t-1,

up to a user-selected t cap.  At every such d the script tests both the
forward and reciprocal exact square-divisor criteria, reconstructs a complete
fab certificate on success, and verifies the Egyptian-fraction identity using
integer arithmetic through helpers from fab_reciprocal_probe.py.

This is a finite falsification instrument, not a proof of the conjecture.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter
from pathlib import Path

from fab_reciprocal_probe import (
    HARD,
    forward_hit,
    ordinary_primes,
    prime_sieve,
    reciprocal_hit,
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=50_000_000)
    ap.add_argument("--max-t", type=int, default=64)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    if args.limit < 2:
        raise SystemExit("--limit must be >=2")
    if args.max_t < 1:
        raise SystemExit("--max-t must be >=1")

    max_d = 4 * args.max_t - 1
    max_factor_target = (args.limit * max_d + 1) // 4
    trial_primes = ordinary_primes(math.isqrt(max_factor_target) + 1)
    hard_primes = prime_sieve(args.limit)

    counts: Counter[tuple[str, int]] = Counter()
    unresolved: list[int] = []
    records: list[dict] = []
    max_first_t = None

    for p in hard_primes:
        V = (p - 1) // 2
        hit = None

        for t in range(1, args.max_t + 1):
            if V % t:
                continue

            d = 4 * t - 1

            hit = forward_hit(p, d, trial_primes)
            if hit is not None:
                hit["t"] = t
                hit["adaptive_dividend"] = V
                break

            hit = reciprocal_hit(p, d, trial_primes)
            if hit is not None:
                hit["t"] = t
                hit["adaptive_dividend"] = V
                break

        if hit is None:
            unresolved.append(p)
            continue

        hit["p"] = p
        counts[(hit["lane"], hit["t"])] += 1
        max_first_t = hit["t"] if max_first_t is None else max(max_first_t, hit["t"])
        records.append(hit)

    distribution = [
        {"lane": lane, "t": t, "d": 4 * t - 1, "captures": counts[(lane, t)]}
        for t in range(1, args.max_t + 1)
        for lane in ("forward", "reciprocal")
        if counts[(lane, t)]
    ]

    summary = {
        "schema": 1,
        "problem": "Erdos-Straus adaptive dyadic divisor-lift probe",
        "limit": args.limit,
        "max_t": args.max_t,
        "hard_residues_mod_840": list(HARD),
        "hard_prime_count": len(hard_primes),
        "captured_count": len(records),
        "unresolved_count": len(unresolved),
        "unresolved": unresolved,
        "max_first_success_t": max_first_t,
        "max_first_success_d": (4 * max_first_t - 1) if max_first_t is not None else None,
        "first_success_distribution": distribution,
        "scientific_status": "finite exact computation; not an Erdos-Straus proof",
    }

    print("CENTL / adaptive dyadic divisor-lift probe")
    print(f"prime bound            {args.limit:,}")
    print(f"largest tested t       {args.max_t}")
    print(f"Mordell-hard primes    {len(hard_primes):,}")
    print(f"captured               {len(records):,}")
    print(f"unresolved             {len(unresolved):,}")
    print(f"max first-success t    {max_first_t}")
    if max_first_t is not None:
        print(f"max first-success d    {4 * max_first_t - 1}")

    print()
    print("first-success distribution")
    for row in distribution:
        print(
            f"{row['lane']:10s}  "
            f"t={row['t']:>3d}  "
            f"d={row['d']:>4d}  "
            f"{row['captures']:>7,d}"
        )

    if unresolved:
        print()
        print("first unresolved")
        print(" ".join(str(p) for p in unresolved[:20]))

    if records:
        record = max(records, key=lambda row: row["t"])
        print()
        print("largest first-success specimen")
        print(f"p                     {record['p']}")
        print(f"lane                  {record['lane']}")
        print(f"t                     {record['t']}")
        print(f"d                     {record['m']}")
        print(f"D                     {record['D']}")
        print(
            "certificate           "
            f"a={record['a']} b={record['b']} c={record['c']} "
            f"k={record['k']} d={record['d']} q={record['q']}"
        )
        print(
            "decomposition         "
            f"4/{record['p']} = 1/{record['x']} + 1/{record['y']} + 1/{record['z']}"
        )

    if args.out is not None:
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
        (args.out / "first-success-certificates.jsonl").write_text(
            "".join(json.dumps(row, sort_keys=True) + "\n" for row in records)
        )
        files = sorted(p for p in args.out.iterdir() if p.is_file() and p.name != "SHA256SUMS")
        (args.out / "SHA256SUMS").write_text("".join(f"{sha256(p)}  {p.name}\n" for p in files))
        print()
        print(f"results                {args.out}")


if __name__ == "__main__":
    main()
