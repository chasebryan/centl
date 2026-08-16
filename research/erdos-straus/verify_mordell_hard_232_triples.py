#!/usr/bin/env python3
"""Regression verifier for the exact Mordell-hard 2-3-2 companion triple theorem."""
from __future__ import annotations

import argparse
import json
import math


def forced_seed(k: int) -> int:
    return math.gcd(6, (k + 1) // 4)


def analyze(max_t: int) -> dict[str, object]:
    mismatches = []
    cases = 0
    blocks = []

    # m mod 35 spans the ambient p=24m+1 residue coordinate inside mod 840.
    # Testing all 36 consecutive values also crosses one full residue period.
    for t in range(max_t + 1):
        k0, k1, k2 = 24 * t + 7, 24 * t + 11, 24 * t + 15
        seeds = [forced_seed(k0), forced_seed(k1), forced_seed(k2)]
        if seeds != [2, 3, 2]:
            mismatches.append({"kind": "seed-pattern", "t": t, "seeds": seeds})

        if t <= 4:
            blocks.append({"t": t, "shifts": [k0, k1, k2], "seeds": seeds})

        for m in range(36):
            cases += 1
            p = 24 * m + 1
            n = m + t
            A, B, D = 3 * n + 1, 2 * n + 1, 3 * n + 2
            C0, C1, C2 = (p + k0) // 4, (p + k1) // 4, (p + k2) // 4

            checks = {
                "C0": C0 == 2 * A,
                "C1": C1 == 3 * B,
                "C2": C2 == 2 * D,
                "consecutive01": C1 == C0 + 1,
                "consecutive12": C2 == C1 + 1,
                "detAB": 2 * A - 3 * B == -1,
                "detBD": 3 * B - 2 * D == -1,
                "stepAD": D - A == 1,
                "gcdAB": math.gcd(A, B) == 1,
                "gcdBD": math.gcd(B, D) == 1,
                "gcdAD": math.gcd(A, D) == 1,
                "gcdC01": math.gcd(C0, C1) == 1,
                "gcdC12": math.gcd(C1, C2) == 1,
                "gcdC02": math.gcd(C0, C2) == 2,
            }
            bad = [name for name, ok in checks.items() if not ok]
            if bad:
                mismatches.append({
                    "kind": "identity",
                    "t": t,
                    "m": m,
                    "bad": bad,
                    "A": A,
                    "B": B,
                    "D": D,
                    "companions": [C0, C1, C2],
                })
                if len(mismatches) >= 20:
                    break
        if len(mismatches) >= 20:
            break

    return {
        "analysis": "mordell-hard-232-coprime-triples-v1",
        "max_t": max_t,
        "cases_checked": cases,
        "seed_pattern": [2, 3, 2],
        "example_blocks": blocks,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": "regression of an elementary exact cross-shift theorem",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-t", type=int, default=10000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.max_t < 0:
        raise SystemExit("--max-t must be nonnegative")
    report = analyze(args.max_t)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
