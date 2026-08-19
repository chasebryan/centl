#!/usr/bin/env python3
"""Verify the universal forced-seed formula on the six Mordell-hard classes."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD_RESIDUES_840 = (1, 121, 169, 289, 361, 529)


def closed_formula(k: int) -> int:
    if k <= 0 or k % 4 != 3:
        raise ValueError("k must be a positive admissible shift, k=3 mod 4")
    u = (k + 1) // 4
    return math.gcd(6, u)


def skeleton_gcd(k: int) -> int:
    """GCD of C_k over all six complete Mordell-hard arithmetic classes."""
    if k <= 0 or k % 4 != 3:
        raise ValueError("k must be a positive admissible shift, k=3 mod 4")
    g = 210  # coefficient of n after p=840n+h and division by 4
    for h in HARD_RESIDUES_840:
        if (h + k) % 4:
            raise AssertionError((h, k))
        g = math.gcd(g, (h + k) // 4)
    return g


def analyze(max_k: int) -> dict[str, object]:
    rows = []
    hist: Counter[int] = Counter()
    mismatches = []
    for k in range(3, max_k + 1, 4):
        u = (k + 1) // 4
        formula = closed_formula(k)
        exact = skeleton_gcd(k)
        if formula != exact:
            mismatches.append({"k": k, "u": u, "formula": formula, "skeleton_gcd": exact})
        if math.gcd(formula, k) != 1:
            mismatches.append({"k": k, "kind": "forced-seed-not-unit", "seed": formula})
        hist[formula] += 1
        if k <= 107:
            rows.append({"k": k, "u": u, "forced_seed": formula})

    expected_examples = {
        3: 1, 7: 2, 11: 3, 15: 2, 19: 1, 23: 6,
        31: 2, 35: 3, 39: 2, 47: 6, 55: 2, 59: 3,
        63: 2, 71: 6, 79: 2, 83: 3, 87: 2, 95: 6,
        103: 2, 107: 3,
    }
    for k, expected in expected_examples.items():
        if k <= max_k and closed_formula(k) != expected:
            mismatches.append({
                "k": k,
                "kind": "example-regression",
                "actual": closed_formula(k),
                "expected": expected,
            })

    return {
        "analysis": "mordell-hard-forced-seed-law-v1",
        "max_k": max_k,
        "admissible_shifts_checked": sum(hist.values()),
        "seed_histogram": {str(k): v for k, v in sorted(hist.items())},
        "rows_through_107": rows,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "formula": "gcd(6,(k+1)/4)",
        "claim": "exact arithmetic-skeleton regression; theorem proof is elementary",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-k", type=int, default=5000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.max_k < 3:
        raise SystemExit("--max-k must be >= 3")
    report = analyze(args.max_k)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
