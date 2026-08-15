#!/usr/bin/env python3
"""Independent verifier for q3_minimal_alignment_probe.py.

Uses the independent q=3 layer/candidate construction from
verify_q3_primitive_cover.py, but computes each minimal-row mask by solving the
affine pullback from the trap value rather than directly evaluating x(a).
"""
from __future__ import annotations

import argparse
import collections
import json
from functools import lru_cache
from pathlib import Path

from verify_q3_primitive_cover import (
    divisors,
    q3_layers_independent,
    target_candidates,
    trap_set,
)


@lru_cache(maxsize=None)
def minimal_traps(j: int) -> tuple[int, ...]:
    m = 4 * j - 1
    if m % 3:
        return ()
    parents = [
        (d, (d + 1) // 4)
        for d in divisors(m)
        if 3 <= d < m and d % 4 == 3
    ]
    return tuple(
        sorted(
            u
            for u in trap_set(j)
            if u % 3 == 1
            and all(u % d not in trap_set(i) for d, i in parents)
        )
    )


def affine_mask(r: int, L: int, j: int) -> int:
    m = 4 * j - 1
    g = m // 3
    lam = (L // g) % 3
    inv = pow(lam, -1, 3)
    mask = 0
    for u in minimal_traps(j):
        if (u - r) % g:
            continue
        delta = ((u - r) % m) // g
        mask |= 1 << ((delta * inv) % 3)
    return mask


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=100000)
    ap.add_argument("--out", type=Path, default=Path("q3-minimal-output"))
    ap.add_argument("--compare-primary", action="store_true")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    counts: collections.Counter[str] = collections.Counter()
    row_hist: collections.Counter[int] = collections.Counter()
    mask_hist: collections.Counter[int] = collections.Counter()
    three_hist: collections.Counter[int] = collections.Counter()
    max_rows = 0

    for k in range(2, args.k_limit + 1):
        L, all_rows = q3_layers_independent(k)
        rows = [j for j in all_rows if minimal_traps(j)]
        if not rows:
            continue
        for _h, _t, r in target_candidates(k, L):
            counts["admissible_candidates_checked"] += 1
            union = 0
            nrows = 0
            for j in rows:
                jm = affine_mask(r, L, j)
                if jm:
                    union |= jm
                    nrows += 1
            max_rows = max(max_rows, nrows)
            row_hist[nrows] += 1
            mask_hist[union] += 1
            if nrows >= 3:
                counts["candidates_with_three_or_more_minimal_rows"] += 1
                three_hist[union] += 1
                if union.bit_count() >= 2:
                    counts["three_plus_rows_with_multiple_digits"] += 1
            if union == 7:
                counts["full_minimal_q3_covers"] += 1

    result = {
        "status": "independent affine verifier for ancestry-minimal q=3 alignment",
        "k_limit": args.k_limit,
        "counts": dict(counts),
        "maximum_minimal_rows_on_one_candidate": max_rows,
        "minimal_row_count_histogram": {str(k): v for k, v in sorted(row_hist.items())},
        "minimal_union_mask_histogram": {str(k): v for k, v in sorted(mask_hist.items())},
        "three_plus_union_mask_histogram": {str(k): v for k, v in sorted(three_hist.items())},
        "verdict": "VERIFIED" if counts["full_minimal_q3_covers"] == 0 else "COUNTEREXAMPLE_CANDIDATE",
    }

    if args.compare_primary:
        p = json.loads((args.out / "q3-minimal-alignment.json").read_text())
        fields = [
            "maximum_minimal_rows_on_one_candidate",
            "minimal_row_count_histogram",
            "minimal_union_mask_histogram",
            "three_plus_union_mask_histogram",
        ]
        mismatches = [f for f in fields if p[f] != result[f]]
        for key in (
            "admissible_candidates_checked",
            "candidates_with_three_or_more_minimal_rows",
            "three_plus_rows_with_multiple_digits",
            "full_minimal_q3_covers",
        ):
            if int(p["counts"].get(key, 0)) != int(counts.get(key, 0)):
                mismatches.append(key)
        result["primary_mismatches"] = mismatches
        result["primary_comparison"] = "MATCH" if not mismatches else "MISMATCH"
        if mismatches:
            result["verdict"] = "MISMATCH"

    (args.out / "q3-minimal-alignment-independent-verifier.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
