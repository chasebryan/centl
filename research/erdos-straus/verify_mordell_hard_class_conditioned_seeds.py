#!/usr/bin/env python3
"""Verify the class-conditioned forced-seed law on the six Mordell-hard classes."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD = (1, 121, 169, 289, 361, 529)
EXPECTED_HIST_5000 = {
    1: 1717, 2: 1714, 3: 854, 5: 427, 6: 858, 7: 287,
    10: 430, 14: 287, 15: 216, 21: 142, 30: 214, 35: 71,
    42: 141, 70: 71, 105: 36, 210: 35,
}
EXPECTED_EXTRA_5000 = {1: 5143, 5: 1287, 7: 857, 35: 213}
SELECTED = {
    39: {1:10,121:10,169:2,289:2,361:10,529:2},
    47: {1:6,121:42,169:6,289:42,361:6,529:6},
    51: {1:1,121:1,169:5,289:5,361:1,529:5},
    55: {1:14,121:2,169:14,289:2,361:2,529:2},
    59: {1:15,121:15,169:3,289:3,361:105,529:21},
    63: {1:2,121:2,169:2,289:2,361:2,529:2},
}


def universal_seed(k: int) -> int:
    return math.gcd(6, (k + 1) // 4)


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def extra_seed(k: int, h: int) -> int:
    return math.gcd(35, (h + k) // 4)


def analyze(max_k: int) -> dict[str, object]:
    seed_hist: Counter[int] = Counter()
    extra_hist: Counter[int] = Counter()
    mismatches = []
    strict_refinements = 0
    pairs = 0

    for k in range(3, max_k + 1, 4):
        gu = universal_seed(k)
        for h in HARD:
            pairs += 1
            if (h + k) % 4:
                mismatches.append({"kind":"nonintegral-companion-offset","k":k,"h":h})
                continue
            offset = (h + k) // 4
            gc = class_seed(k, h)
            extra = extra_seed(k, h)
            seed_hist[gc] += 1
            extra_hist[extra] += 1

            if gc != gu * extra:
                mismatches.append({
                    "kind":"factorization","k":k,"h":h,"class_seed":gc,
                    "universal_seed":gu,"extra":extra,
                })
            if gc % gu:
                mismatches.append({"kind":"not-refinement","k":k,"h":h,"gc":gc,"gu":gu})
            if gc > gu:
                strict_refinements += 1
            if math.gcd(gc, k) != 1:
                mismatches.append({"kind":"seed-not-unit","k":k,"h":h,"seed":gc})

            # Maximality on the complete arithmetic class: gcd of coefficient
            # 210 and one offset is the gcd of all 210*r+offset values.
            sample_gcd = 0
            for r in range(0, 8):
                sample_gcd = math.gcd(sample_gcd, 210*r + offset)
            if sample_gcd != gc:
                mismatches.append({
                    "kind":"progression-gcd","k":k,"h":h,"sample":sample_gcd,"formula":gc,
                })

            # Exact 840-periodicity when the translated shift remains in range.
            if k + 840 <= max_k and class_seed(k + 840, h) != gc:
                mismatches.append({"kind":"periodicity","k":k,"h":h,"seed":gc})

    selected = {}
    for k, expected in SELECTED.items():
        if k > max_k:
            continue
        actual = {h: class_seed(k, h) for h in HARD}
        selected[str(k)] = {str(h): actual[h] for h in HARD}
        if actual != expected:
            mismatches.append({"kind":"selected-ledger","k":k,"actual":actual,"expected":expected})

    if max_k == 5000:
        if dict(sorted(seed_hist.items())) != EXPECTED_HIST_5000:
            mismatches.append({
                "kind":"seed-histogram","actual":dict(seed_hist),"expected":EXPECTED_HIST_5000,
            })
        if dict(sorted(extra_hist.items())) != EXPECTED_EXTRA_5000:
            mismatches.append({
                "kind":"extra-histogram","actual":dict(extra_hist),"expected":EXPECTED_EXTRA_5000,
            })
        if strict_refinements != 2357:
            mismatches.append({
                "kind":"strict-refinements","actual":strict_refinements,"expected":2357,
            })

    return {
        "analysis": "mordell-hard-class-conditioned-seed-law-v1",
        "max_k": max_k,
        "hard_classes": list(HARD),
        "class_shift_pairs_checked": pairs,
        "seed_histogram": {str(k): v for k, v in sorted(seed_hist.items())},
        "extra_multiplier_histogram": {str(k): v for k, v in sorted(extra_hist.items())},
        "strict_refinements_over_universal_seed": strict_refinements,
        "selected_ledgers": selected,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "formula": "gcd(210,(h+k)/4)",
        "factorization": "gcd(6,(k+1)/4)*gcd(35,(h+k)/4)",
        "claim": "exact arithmetic-class regression; theorem proof is elementary",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-k", type=int, default=5000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.max_k < 3:
        raise SystemExit("--max-k must be >=3")
    report = analyze(args.max_k)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for key, value in report.items():
            print(f"{key}: {value}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
