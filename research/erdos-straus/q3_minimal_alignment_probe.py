#!/usr/bin/env python3
"""Finite falsifier for ancestry-minimal q=3 digit alignment.

Q3-POINTWISE-DIVISOR-REDUCTION.md proves that every q=3 forbidden digit on a
directly novel candidate descends, without changing the digit, to an actual
trap witness that is minimal under divisor-modulus ancestry.  A frozen ancestor
would instead directly shadow the candidate.

This program therefore filters every q=3 trap to ancestry-minimal witnesses and
measures how many such rows can align on one admissible target and how many of
the three common next-3-adic digits they occupy.

Finite zero-failure output is a theorem-certificate only for the tested range.
"""
from __future__ import annotations

import argparse
import collections
import json
from functools import lru_cache
from pathlib import Path

from q3_primitive_cover_probe import (
    admissible_candidates,
    divisors,
    q3_layers,
    trap_set,
)


@lru_cache(maxsize=None)
def ancestry_minimal_traps(j: int) -> tuple[int, ...]:
    m = 4 * j - 1
    if m % 3:
        return ()

    parents = [
        (mi, (mi + 1) // 4)
        for mi in divisors(m)
        if 3 <= mi < m and mi % 4 == 3
    ]

    out: list[int] = []
    for u in trap_set(j):
        # Every Mordell-hard progression is 1 mod 3, so only these traps can
        # align with a q=3 pullback.
        if u % 3 != 1:
            continue
        if all(u % mi not in trap_set(i) for mi, i in parents):
            out.append(u)
    return tuple(sorted(out))


def minimal_mask(r: int, L: int, j: int) -> int:
    """Directly evaluate the three q=3 classes against minimal trap points."""
    m = 4 * j - 1
    mask = 0
    traps = ancestry_minimal_traps(j)
    if not traps:
        return 0
    trap_lookup = set(traps)
    for a in range(3):
        if (r + L * a) % m in trap_lookup:
            mask |= 1 << a
    return mask


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=100000)
    ap.add_argument("--out", type=Path, default=Path("q3-minimal-output"))
    ap.add_argument("--examples", type=int, default=40)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    counts: collections.Counter[str] = collections.Counter()
    row_count_hist: collections.Counter[int] = collections.Counter()
    mask_hist: collections.Counter[int] = collections.Counter()
    three_plus_mask_hist: collections.Counter[int] = collections.Counter()
    first_two_digit = None
    first_three_rows = None
    first_three_rows_multidigit = None
    first_full_cover = None
    three_plus_examples: list[dict] = []
    max_rows = 0

    for k in range(2, args.k_limit + 1):
        L, rows_all = q3_layers(k)
        rows = [j for j in rows_all if ancestry_minimal_traps(j)]
        counts["target_depths"] += 1
        counts["q3_layers_generated"] += len(rows_all)
        counts["q3_layers_with_minimal_traps"] += len(rows)
        if not rows:
            continue

        for h, t, r in admissible_candidates(k, L):
            counts["admissible_candidates_checked"] += 1
            union = 0
            used: list[dict] = []
            for j in rows:
                jm = minimal_mask(r, L, j)
                if not jm:
                    continue
                union |= jm
                used.append(
                    {
                        "j": j,
                        "mask": jm,
                        "classes": [a for a in range(3) if jm & (1 << a)],
                    }
                )

            nrows = len(used)
            max_rows = max(max_rows, nrows)
            row_count_hist[nrows] += 1
            mask_hist[union] += 1

            if union.bit_count() >= 2 and first_two_digit is None:
                first_two_digit = {
                    "k": k, "h": h, "t": t, "r": r, "L": L,
                    "mask": union, "rows": used,
                }

            if nrows >= 3:
                counts["candidates_with_three_or_more_minimal_rows"] += 1
                three_plus_mask_hist[union] += 1
                if first_three_rows is None:
                    first_three_rows = {
                        "k": k, "h": h, "t": t, "r": r, "L": L,
                        "mask": union, "rows": used,
                    }
                if union.bit_count() >= 2:
                    counts["three_plus_rows_with_multiple_digits"] += 1
                    if first_three_rows_multidigit is None:
                        first_three_rows_multidigit = {
                            "k": k, "h": h, "t": t, "r": r, "L": L,
                            "mask": union, "rows": used,
                        }
                if len(three_plus_examples) < args.examples:
                    three_plus_examples.append(
                        {"k": k, "h": h, "t": t, "mask": union, "rows": used}
                    )

            if union == 0b111:
                counts["full_minimal_q3_covers"] += 1
                if first_full_cover is None:
                    first_full_cover = {
                        "k": k, "h": h, "t": t, "r": r, "L": L,
                        "rows": used,
                    }

        if k % 5000 == 0:
            print(
                f"progress k={k} candidates={counts['admissible_candidates_checked']} "
                f"three+={counts['candidates_with_three_or_more_minimal_rows']} "
                f"three+multi={counts['three_plus_rows_with_multiple_digits']} "
                f"full={counts['full_minimal_q3_covers']}",
                flush=True,
            )

    result = {
        "status": "finite ancestry-minimal q=3 alignment falsifier",
        "k_limit": args.k_limit,
        "counts": dict(counts),
        "maximum_minimal_rows_on_one_candidate": max_rows,
        "minimal_row_count_histogram": {str(k): v for k, v in sorted(row_count_hist.items())},
        "minimal_union_mask_histogram": {str(k): v for k, v in sorted(mask_hist.items())},
        "three_plus_union_mask_histogram": {str(k): v for k, v in sorted(three_plus_mask_hist.items())},
        "first_two_digit_union": first_two_digit,
        "first_three_or_more_minimal_rows": first_three_rows,
        "first_three_or_more_minimal_rows_with_multiple_digits": first_three_rows_multidigit,
        "first_full_minimal_q3_cover": first_full_cover,
        "three_plus_examples": three_plus_examples,
        "claim_boundary": (
            "The divisor-reduction theorem justifies ancestry-minimal representatives. "
            "The alignment statements here are exact only through the configured finite k-limit. "
            "They do not prove universal DSC-P, Lopez-all-primes, or Erdos-Straus."
        ),
    }
    (args.out / "q3-minimal-alignment.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = [
        "# Ancestry-minimal q=3 alignment finite attack",
        "",
        f"Range: `k <= {args.k_limit}`.",
        "",
        f"Admissible candidates checked: `{counts['admissible_candidates_checked']}`.",
        f"Maximum ancestry-minimal q=3 rows on one candidate: **`{max_rows}`**.",
        f"Candidates with >=3 minimal rows: **`{counts['candidates_with_three_or_more_minimal_rows']}`**.",
        f">=3-row candidates occupying >=2 digits: **`{counts['three_plus_rows_with_multiple_digits']}`**.",
        f"Full minimal q=3 covers: **`{counts['full_minimal_q3_covers']}`**.",
        "",
        "Minimal-row count histogram:",
        "",
        "```text",
    ]
    for n, c in sorted(row_count_hist.items()):
        report.append(f"{n}: {c}")
    report.extend(["```", "", "Masks among candidates with >=3 minimal rows:", "", "```text"])
    for mask, c in sorted(three_plus_mask_hist.items()):
        report.append(f"{mask}: {c}")
    report.extend(["```", ""])
    if first_three_rows is not None:
        report.append(
            "First >=3-row case: "
            f"`k={first_three_rows['k']}, h={first_three_rows['h']}, "
            f"t={first_three_rows['t']}, mask={first_three_rows['mask']}`."
        )
    if first_three_rows_multidigit is None:
        report.append(
            "No candidate with >=3 ancestry-minimal rows occupies more than one next 3-adic digit in the tested range."
        )
    report.append("")
    (args.out / "q3-minimal-alignment-report.md").write_text("\n".join(report))
    print("\n".join(report))


if __name__ == "__main__":
    main()
