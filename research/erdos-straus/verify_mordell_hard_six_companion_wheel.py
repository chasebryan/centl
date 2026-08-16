#!/usr/bin/env python3
"""Regression verifier for the exact Mordell-hard six-companion residual wheel."""
from __future__ import annotations

import argparse
import itertools
import json
import math

SEEDS = (1, 2, 3, 2, 1, 6)


def forced_seed(k: int) -> int:
    if k % 4 != 3:
        raise ValueError(k)
    return math.gcd(6, (k + 1) // 4)


def residuals(n: int) -> tuple[int, ...]:
    return (6*n + 1, 3*n + 1, 2*n + 1, 3*n + 2, 6*n + 5, n + 1)


def expected_gcd(i: int, j: int, n: int) -> int:
    pair = (min(i, j), max(i, j))
    if pair == (0, 5):
        return math.gcd(n + 1, 5)
    if pair == (1, 5):
        return math.gcd(n + 1, 2)
    return 1


def analyze(max_t: int) -> dict[str, object]:
    mismatches = []
    cases = 0
    pair_checks = 0
    overlap_counts = {"R0-R5:gcd5": 0, "R1-R5:gcd2": 0}
    examples = []

    # m modulo 35 is the natural coordinate of p=24m+1 inside modulus 840.
    # Testing m=0..35 crosses a full residue period and one boundary value.
    for t in range(max_t + 1):
        shifts = tuple(24*t + 3 + 4*j for j in range(6))
        seeds = tuple(forced_seed(k) for k in shifts)
        if seeds != SEEDS:
            mismatches.append({"kind": "seed-pattern", "t": t, "shifts": shifts, "seeds": seeds})

        if t <= 4:
            examples.append({"t": t, "shifts": list(shifts), "seeds": list(seeds)})

        for m in range(36):
            cases += 1
            p = 24*m + 1
            n = m + t
            R = residuals(n)
            C = tuple((p + k)//4 for k in shifts)
            expected_C = tuple(SEEDS[j] * R[j] for j in range(6))

            if C != expected_C:
                mismatches.append({
                    "kind": "companion-normal-form", "t": t, "m": m,
                    "companions": C, "expected": expected_C,
                })

            if C != tuple(6*n + j + 1 for j in range(6)):
                mismatches.append({
                    "kind": "consecutive-wheel", "t": t, "m": m, "companions": C,
                })

            # Explicit determinant/small-remainder identities used in the proof.
            identities = {
                "R0-2R1": R[0] - 2*R[1] == -1,
                "R0-3R2": R[0] - 3*R[2] == -2,
                "R0-2R3": R[0] - 2*R[3] == -3,
                "R4-R0": R[4] - R[0] == 4,
                "R0-6R5": R[0] - 6*R[5] == -5,
                "2R1-3R2": 2*R[1] - 3*R[2] == -1,
                "R3-R1": R[3] - R[1] == 1,
                "R4-2R1": R[4] - 2*R[1] == 3,
                "R1-3R5": R[1] - 3*R[5] == -2,
                "3R2-2R3": 3*R[2] - 2*R[3] == -1,
                "R4-3R2": R[4] - 3*R[2] == 2,
                "R2-2R5": R[2] - 2*R[5] == -1,
                "2R3-R4": 2*R[3] - R[4] == -1,
                "R3-3R5": R[3] - 3*R[5] == -1,
                "R4-6R5": R[4] - 6*R[5] == -1,
            }
            bad_identities = [name for name, ok in identities.items() if not ok]
            if bad_identities:
                mismatches.append({
                    "kind": "linear-identity", "t": t, "m": m,
                    "bad": bad_identities, "residuals": R,
                })

            for i, j in itertools.combinations(range(6), 2):
                pair_checks += 1
                actual = math.gcd(R[i], R[j])
                expected = expected_gcd(i, j, n)
                if actual != expected:
                    mismatches.append({
                        "kind": "gcd-graph", "t": t, "m": m,
                        "pair": [i, j], "actual": actual, "expected": expected,
                        "residuals": R,
                    })
                if (i, j) == (0, 5) and actual == 5:
                    overlap_counts["R0-R5:gcd5"] += 1
                if (i, j) == (1, 5) and actual == 2:
                    overlap_counts["R1-R5:gcd2"] += 1

            if len(mismatches) >= 20:
                break
        if len(mismatches) >= 20:
            break

    return {
        "analysis": "mordell-hard-six-companion-residual-wheel-v1",
        "max_t": max_t,
        "cases_checked": cases,
        "pairwise_gcd_checks": pair_checks,
        "seed_pattern": list(SEEDS),
        "example_blocks": examples,
        "exceptional_edges": {
            "R0-R5": "gcd(n+1,5)",
            "R1-R5": "gcd(n+1,2)",
        },
        "observed_exceptional_nontrivial_counts": overlap_counts,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": "regression of an elementary exact six-shift cross-structure theorem",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-t", type=int, default=1000)
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
