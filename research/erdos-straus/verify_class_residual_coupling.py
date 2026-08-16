#!/usr/bin/env python3
"""Regression for the class-conditioned residual-coupling theorem."""
from __future__ import annotations

import argparse
import json
import math

HARD_CLASSES = (1, 121, 169, 289, 361, 529)


def seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def companion(r: int, h: int, k: int) -> int:
    p = 840 * r + h
    value = (p + k) // 4
    if 4 * value != p + k:
        raise ValueError((r, h, k))
    return value


def analyze(max_r: int) -> dict[str, object]:
    mismatches: list[dict[str, object]] = []
    checks = 0

    expected_seeds = {
        (121, 19): 35,
        (121, 47): 42,
        (169, 11): 15,
        (169, 31): 10,
        (289, 11): 15,
        (289, 31): 10,
        (289, 47): 42,
        (361, 31): 14,
        (361, 59): 105,
        (529, 11): 15,
        (529, 31): 70,
    }

    for (h, k), expected in expected_seeds.items():
        actual = seed(k, h)
        if actual != expected:
            mismatches.append(
                {"kind": "seed", "h": h, "k": k, "actual": actual, "expected": expected}
            )

    for r in range(max_r + 1):
        # h=121
        A = 6 * r + 1
        B = 5 * r + 1
        if companion(r, 121, 19) != 35 * A or companion(r, 121, 47) != 42 * B:
            mismatches.append({"kind": "h121-companion", "r": r})
        if 5 * A - 6 * B != -1 or math.gcd(A, B) != 1:
            mismatches.append({"kind": "h121-coupling", "r": r, "A": A, "B": B})
        checks += 1

        # h=169
        A = 14 * r + 3
        B = 21 * r + 5
        if companion(r, 169, 11) != 15 * A or companion(r, 169, 31) != 10 * B:
            mismatches.append({"kind": "h169-companion", "r": r})
        if 2 * B - 3 * A != 1 or math.gcd(A, B) != 1:
            mismatches.append({"kind": "h169-coupling", "r": r, "A": A, "B": B})
        checks += 1

        # h=529
        A = 14 * r + 9
        B = 3 * r + 2
        if companion(r, 529, 11) != 15 * A or companion(r, 529, 31) != 70 * B:
            mismatches.append({"kind": "h529-companion", "r": r})
        if 14 * B - 3 * A != 1 or math.gcd(A, B) != 1:
            mismatches.append({"kind": "h529-coupling", "r": r, "A": A, "B": B})
        checks += 1

        # h=361
        A = 15 * r + 7
        B = 2 * r + 1
        if companion(r, 361, 31) != 14 * A or companion(r, 361, 59) != 105 * B:
            mismatches.append({"kind": "h361-companion", "r": r})
        if 15 * B - 2 * A != 1 or math.gcd(A, B) != 1:
            mismatches.append({"kind": "h361-coupling", "r": r, "A": A, "B": B})
        checks += 1

        # h=289 triple
        A = 14 * r + 5
        B = 21 * r + 8
        D = 5 * r + 2
        if (
            companion(r, 289, 11) != 15 * A
            or companion(r, 289, 31) != 10 * B
            or companion(r, 289, 47) != 42 * D
        ):
            mismatches.append({"kind": "h289-companion", "r": r})
        if 2 * B - 3 * A != 1 or math.gcd(A, B) != 1:
            mismatches.append({"kind": "h289-ab", "r": r, "A": A, "B": B})
        if 14 * D - 5 * A != 3:
            mismatches.append({"kind": "h289-ad-identity", "r": r, "A": A, "D": D})
        expected_ad = 3 if r % 3 == 2 else 1
        if math.gcd(A, D) != expected_ad:
            mismatches.append(
                {"kind": "h289-ad-gcd", "r": r, "actual": math.gcd(A, D), "expected": expected_ad}
            )
        if 21 * D - 5 * B != 2:
            mismatches.append({"kind": "h289-bd-identity", "r": r, "B": B, "D": D})
        expected_bd = 2 if r % 2 == 0 else 1
        if math.gcd(B, D) != expected_bd:
            mismatches.append(
                {"kind": "h289-bd-gcd", "r": r, "actual": math.gcd(B, D), "expected": expected_bd}
            )
        common_large = set()
        for q in range(5, math.isqrt(max(A, B, D)) + 1):
            if A % q == B % q == 0 or A % q == D % q == 0 or B % q == D % q == 0:
                common_large.add(q)
        if common_large:
            mismatches.append({"kind": "h289-large-overlap", "r": r, "primes": sorted(common_large)[:20]})
        checks += 1

    return {
        "analysis": "mordell-hard-class-residual-coupling-regression-v1",
        "max_r": max_r,
        "symbolic_family_instances_checked": checks,
        "expected_seeds": {f"h{h}-k{k}": value for (h, k), value in sorted(expected_seeds.items())},
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": (
            "regression of elementary affine identities and exact gcd formulas; "
            "the theorem itself is range-free and does not assert fixed-shift coverage"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-r", type=int, default=100000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.max_r)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"family instances checked: {report['symbolic_family_instances_checked']}")
        print(f"mismatches: {report['mismatches']}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
