#!/usr/bin/env python3
"""Regression for the finite López Type A/B decision ceilings.

The proof is in LOPEZ-AB-FINITE-DECISION-BOUND.md.  This script protects the
arithmetic constants, residue exclusions, generated parameter families, and
sharp examples.  It is not a substitute for the proof.
"""
from __future__ import annotations

import argparse
import json
import math

HARD_CLASSES = (1, 121, 169, 289, 361, 529)


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    q = 3
    while q <= math.isqrt(n):
        if n % q == 0:
            return False
        q += 2
    return True


def hard_skeleton(n: int) -> bool:
    return n % 840 in HARD_CLASSES


def type_a_value(d: int, n: int, quotient: int) -> int:
    return quotient * (4 * d * n - 1) - 4 * d


def type_b_value(d: int, n: int, quotient: int) -> int:
    return quotient * (4 * d * n - 1) - n


def hard_a_bound(p: int) -> int:
    return (p + 3) // 11


def hard_b_bound(p: int) -> int:
    return (3 * (p + 1)) // 11


def mod24_a_bound(p: int) -> int:
    return (p + 3) // 10


def mod24_b_bound(p: int) -> int:
    return (2 * (p + 1)) // 7


def direct_a(p: int, d: int, n: int) -> bool:
    m = 4 * d * n - 1
    return p % m == (-4 * d) % m


def direct_b(p: int, d: int, n: int) -> bool:
    m = 4 * d * n - 1
    return p % m == (-n) % m


def analyze(max_d: int, max_n: int, max_quotient: int) -> dict[str, object]:
    mismatches: list[dict[str, object]] = []

    residue_facts = {
        str(h): {
            "mod3": h % 3,
            "mod5": h % 5,
            "mod7": h % 7,
            "mod8": h % 8,
            "mod24": h % 24,
        }
        for h in HARD_CLASSES
    }

    for h in HARD_CLASSES:
        if h % 3 != 1 or h % 8 != 1 or h % 24 != 1:
            mismatches.append({"kind": "hard-basic-residue", "h": h})
        if h % 5 not in (1, 4):
            mismatches.append({"kind": "hard-mod5-residue", "h": h})
        if h % 7 not in (1, 2, 4):
            mismatches.append({"kind": "hard-mod7-residue", "h": h})

    # The Type-A extremal quotient is s=3.  On the hard skeleton the cases
    # n=1,2,3 are impossible.  A full residue period in d is sufficient.
    excluded_a = {}
    for n in (1, 2, 3):
        realized = sorted(
            {
                type_a_value(d, n, 3) % 840
                for d in range(1, 841)
            }
            & set(HARD_CLASSES)
        )
        excluded_a[str(n)] = realized
        if realized:
            mismatches.append(
                {"kind": "type-a-extremal-residue-realized", "n": n, "classes": realized}
            )

    # The Type-B extremal quotient is s=1.  The hard skeleton excludes d=1
    # through mod 3 and d=2 through mod 7.
    excluded_b = {}
    for d in (1, 2):
        realized = sorted(
            {
                type_b_value(d, n, 1) % 840
                for n in range(1, 841)
            }
            & set(HARD_CLASSES)
        )
        excluded_b[str(d)] = realized
        if realized:
            mismatches.append(
                {"kind": "type-b-extremal-residue-realized", "d": d, "classes": realized}
            )

    generated = {
        "hard_type_a": 0,
        "hard_type_b": 0,
        "mod24_type_a": 0,
        "mod24_type_b": 0,
    }

    # Parameter-family regression.  Primality is deliberately not required:
    # the inequalities use only the residue skeleton, so testing all generated
    # integers is stronger than testing prime examples alone.
    for d in range(1, max_d + 1):
        for n in range(1, max_n + 1):
            k = d * n

            for s in range(3, max_quotient + 1, 4):
                p = type_a_value(d, n, s)
                if p <= 0:
                    continue
                if p % 24 == 1:
                    generated["mod24_type_a"] += 1
                    if k > mod24_a_bound(p):
                        mismatches.append(
                            {
                                "kind": "mod24-type-a-bound",
                                "p": p,
                                "d": d,
                                "n": n,
                                "s": s,
                                "k": k,
                                "bound": mod24_a_bound(p),
                            }
                        )
                if hard_skeleton(p):
                    generated["hard_type_a"] += 1
                    if k > hard_a_bound(p):
                        mismatches.append(
                            {
                                "kind": "hard-type-a-bound",
                                "p": p,
                                "d": d,
                                "n": n,
                                "s": s,
                                "k": k,
                                "bound": hard_a_bound(p),
                            }
                        )

            for s in range(1, max_quotient + 1):
                p = type_b_value(d, n, s)
                if p <= 0:
                    continue
                if p % 24 == 1:
                    generated["mod24_type_b"] += 1
                    if k > mod24_b_bound(p):
                        mismatches.append(
                            {
                                "kind": "mod24-type-b-bound",
                                "p": p,
                                "d": d,
                                "n": n,
                                "s": s,
                                "k": k,
                                "bound": mod24_b_bound(p),
                            }
                        )
                if hard_skeleton(p):
                    generated["hard_type_b"] += 1
                    if k > hard_b_bound(p):
                        mismatches.append(
                            {
                                "kind": "hard-type-b-bound",
                                "p": p,
                                "d": d,
                                "n": n,
                                "s": s,
                                "k": k,
                                "bound": hard_b_bound(p),
                            }
                        )

    sharp = {
        "hard_type_a": {"p": 1009, "d": 23, "n": 4, "s": 3},
        "hard_type_b": {"p": 4201, "d": 3, "n": 382, "s": 1},
        "mod24_type_a": {"p": 97, "d": 5, "n": 2, "s": 3},
        "mod24_type_b": {"p": 97, "d": 2, "n": 14, "s": 1},
    }

    a = sharp["hard_type_a"]
    a_k = a["d"] * a["n"]
    if (
        type_a_value(a["d"], a["n"], a["s"]) != a["p"]
        or not hard_skeleton(a["p"])
        or not is_prime(a["p"])
        or not direct_a(a["p"], a["d"], a["n"])
        or a_k != hard_a_bound(a["p"])
    ):
        mismatches.append({"kind": "sharp-hard-type-a", "row": a})

    b = sharp["hard_type_b"]
    b_k = b["d"] * b["n"]
    if (
        type_b_value(b["d"], b["n"], b["s"]) != b["p"]
        or not hard_skeleton(b["p"])
        or not is_prime(b["p"])
        or not direct_b(b["p"], b["d"], b["n"])
        or b_k != hard_b_bound(b["p"])
    ):
        mismatches.append({"kind": "sharp-hard-type-b", "row": b})

    a24 = sharp["mod24_type_a"]
    a24_k = a24["d"] * a24["n"]
    if (
        type_a_value(a24["d"], a24["n"], a24["s"]) != a24["p"]
        or a24["p"] % 24 != 1
        or not is_prime(a24["p"])
        or not direct_a(a24["p"], a24["d"], a24["n"])
        or a24_k != mod24_a_bound(a24["p"])
    ):
        mismatches.append({"kind": "sharp-mod24-type-a", "row": a24})

    b24 = sharp["mod24_type_b"]
    b24_k = b24["d"] * b24["n"]
    if (
        type_b_value(b24["d"], b24["n"], b24["s"]) != b24["p"]
        or b24["p"] % 24 != 1
        or not is_prime(b24["p"])
        or not direct_b(b24["p"], b24["d"], b24["n"])
        or b24_k != mod24_b_bound(b24["p"])
    ):
        mismatches.append({"kind": "sharp-mod24-type-b", "row": b24})

    return {
        "analysis": "lopez-ab-finite-decision-bound-regression-v1",
        "hard_classes": list(HARD_CLASSES),
        "residue_facts": residue_facts,
        "excluded_type_a_s3_n": excluded_a,
        "excluded_type_b_s1_d": excluded_b,
        "parameter_grid": {
            "max_d": max_d,
            "max_n": max_n,
            "max_quotient": max_quotient,
            "generated": generated,
        },
        "bounds": {
            "hard_type_a": "floor((p+3)/11)",
            "hard_type_b": "floor(3(p+1)/11)",
            "hard_complete": "floor(3(p+1)/11)",
            "mod24_type_a": "floor((p+3)/10)",
            "mod24_type_b": "floor(2(p+1)/7)",
            "mod24_complete": "floor(2(p+1)/7)",
        },
        "sharp_examples": sharp,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": "finite regression of an elementary range-free parameter bound; not a proof of Lopez or Erdos-Straus",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-d", type=int, default=160)
    ap.add_argument("--max-n", type=int, default=320)
    ap.add_argument("--max-quotient", type=int, default=63)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    report = analyze(args.max_d, args.max_n, args.max_quotient)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("López A/B finite-decision-bound regression")
        print(f"generated: {report['parameter_grid']['generated']}")
        print(f"mismatches: {report['mismatches']}")
        print(f"sharp examples: {report['sharp_examples']}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
