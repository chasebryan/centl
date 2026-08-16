#!/usr/bin/env python3
"""Regression anchors for LOPEZ-AB-CENSUS-100B.md."""
from __future__ import annotations

import argparse
import json

import lopez_ab_bounded_census as census
import lopez_ab_complete_sqrt_audit as complete

RECORDS = (
    (9_658_489, 2_622),
    (362_385_409, 2_850),
    (740_856_601, 3_612),
    (1_135_844_089, 7_138),
    (10_671_101_281, 7_945),
    (37_941_547_081, 9_315),
    (45_894_591_961, 13_234),
)


def analyze() -> dict[str, object]:
    mismatches: list[dict[str, object]] = []

    ten_m = census.analyze(
        2,
        10_000_000,
        5_000,
        2_000_000,
        False,
        100,
    )
    if ten_m["hard_primes"] != 20_513:
        mismatches.append({"kind": "10m-hard-count", "actual": ten_m["hard_primes"]})
    if ten_m["bounded_survivors"] != 0:
        mismatches.append({"kind": "10m-survivors", "actual": ten_m["survivor_primes"]})
    if ten_m["deepest_bounded_hit"] != {"p": 9_658_489, "k": 2_622}:
        mismatches.append({"kind": "10m-record", "actual": ten_m["deepest_bounded_hit"]})

    mods, traps = census.trap_table(13_234)
    record_rows = []
    for p, expected_k in RECORDS:
        direct = census.first_depth(p, 13_234, mods, traps)
        exact = complete.audit(p)
        row = {
            "p": p,
            "expected_k": expected_k,
            "direct_k": direct,
            "complete_k": exact["C_AB"],
            "first_type_ab": exact["first_type_ab"],
        }
        record_rows.append(row)
        if direct != expected_k or exact["C_AB"] != expected_k:
            mismatches.append({"kind": "record-depth", **row})

    final = complete.audit(45_894_591_961, include_all=True)
    first = final["first_type_ab"]
    expected_first = {
        "type": "A",
        "k": 13_234,
        "m": 52_935,
        "d": 26,
        "n_parameter": 509,
        "quotient": 866_999,
    }
    if first != expected_first:
        mismatches.append({"kind": "final-record-certificate", "actual": first, "expected": expected_first})
    if 45_894_591_961 + 4 * 26 != 866_999 * 52_935:
        mismatches.append({"kind": "final-record-identity"})

    interval_counts = [
        179_468,
        1_408_113,
        12_628_126,
        13_345_271,
        13_056_376,
        12_873_998,
        12_739_129,
        12_635_546,
        12_552_626,
        12_477_405,
        12_415_862,
        12_359_299,
    ]
    if sum(interval_counts) != 128_671_219:
        mismatches.append({"kind": "100b-total-arithmetic", "actual": sum(interval_counts)})

    return {
        "analysis": "lopez-ab-100b-census-regression-v1",
        "ten_million_anchor": {
            "hard_primes": ten_m["hard_primes"],
            "bounded_survivors": ten_m["bounded_survivors"],
            "deepest_bounded_hit": ten_m["deepest_bounded_hit"],
        },
        "record_rows": record_rows,
        "interval_counts": interval_counts,
        "interval_count_sum": sum(interval_counts),
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": (
            "regression anchors and exact record certificates for the 100B finite census; "
            "the hosted gate does not replay all 100B primes"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"10M anchor: {report['ten_million_anchor']}")
        print(f"100B count sum: {report['interval_count_sum']}")
        print(f"mismatches: {report['mismatches']}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
