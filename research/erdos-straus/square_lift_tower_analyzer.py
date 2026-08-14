#!/usr/bin/env python3
"""Analyze negative square-lift towers in a direct-shadow certificate bundle.

This script implements the structural organization in SQUARE-LIFT-TOWERS.md.
It does not use stored avoiding witnesses to decide tower membership or Jacobi
sign. For each directly novel target candidate it groups character-fixed
negative earlier layers by their squarefree kernel a=sf(4j-1), records the
variable tower bases whose moduli are not already fully fixed by L, and checks
that every row in a tower has the same Jacobi sign.

Finite counts are proof-mining diagnostics, not universal bounds.
"""
from __future__ import annotations

import argparse
import bisect
import collections
import json
import math
from pathlib import Path


def factor_exp(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    p = 2
    while p * p <= x:
        if x % p == 0:
            a = 0
            while x % p == 0:
                x //= p
                a += 1
            out[p] = a
        p = 3 if p == 2 else p + 2
    if x > 1:
        out[x] = 1
    return out


def squarefree_kernel(n: int) -> int:
    out = 1
    for p, a in factor_exp(n).items():
        if a % 2:
            out *= p
    return out


def radical(n: int) -> int:
    out = 1
    for p in factor_exp(n):
        out *= p
    return out


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("Jacobi denominator must be positive odd")
    a %= n
    result = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                result = -result
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            result = -result
        a %= n
    return result if n == 1 else 0


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    sf = [1] * (k_limit + 1)
    groups: dict[int, list[int]] = collections.defaultdict(list)
    for j in range(1, k_limit + 1):
        a = squarefree_kernel(4 * j - 1)
        if a % 4 != 3:
            raise AssertionError(f"squarefree tower base not 3 mod 4 at j={j}: {a}")
        sf[j] = a
        groups[a].append(j)

    residual_candidates = 0
    multi_variable_tower_candidates = 0
    negative_tower_count = collections.Counter()
    variable_tower_count = collections.Counter()
    negative_row_count = collections.Counter()
    variable_row_count = collections.Counter()
    variable_tower_frequency: collections.Counter[int] = collections.Counter()
    variable_rows_per_tower: collections.Counter[int] = collections.Counter()
    examples: list[dict] = []
    maximum_variable_towers = 0
    maximum_variable_rows = 0

    for candidate_index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        rad_L = radical(L)

        negative_towers: list[dict] = []
        total_negative_rows = 0
        total_variable_rows = 0
        variable_towers = 0

        for a, rows in groups.items():
            if rad_L % a:
                continue
            stop = bisect.bisect_left(rows, k)
            if stop == 0:
                continue
            if jacobi(r, a) != -1:
                continue

            earlier_rows = rows[:stop]
            # Character coherence regression: every lift must have the same
            # Jacobi sign as its squarefree tower base.
            for j in earlier_rows:
                if jacobi(r, 4 * j - 1) != -1:
                    raise AssertionError(
                        f"tower character coherence failed candidate={candidate_index} a={a} j={j}"
                    )

            variable_rows = [j for j in earlier_rows if L % (4 * j - 1) != 0]
            total_negative_rows += len(earlier_rows)
            total_variable_rows += len(variable_rows)
            if variable_rows:
                variable_towers += 1
                variable_tower_frequency[a] += 1
                variable_rows_per_tower[len(variable_rows)] += 1

            negative_towers.append(
                {
                    "a": a,
                    "earlier_rows": len(earlier_rows),
                    "variable_rows": variable_rows,
                }
            )

        if negative_towers:
            residual_candidates += 1
        if variable_towers > 1:
            multi_variable_tower_candidates += 1

        negative_tower_count[len(negative_towers)] += 1
        variable_tower_count[variable_towers] += 1
        negative_row_count[total_negative_rows] += 1
        variable_row_count[total_variable_rows] += 1
        maximum_variable_towers = max(maximum_variable_towers, variable_towers)
        maximum_variable_rows = max(maximum_variable_rows, total_variable_rows)

        if variable_towers and (
            len(examples) < args.examples
            or variable_towers == maximum_variable_towers
            or total_variable_rows == maximum_variable_rows
        ):
            examples.append(
                {
                    "candidate_index": candidate_index,
                    "k": k,
                    "h": int(rec["h"]),
                    "t": int(rec["t"]),
                    "r": r,
                    "L": L,
                    "negative_towers": negative_towers,
                    "variable_tower_count": variable_towers,
                    "variable_row_count": total_variable_rows,
                }
            )
            examples = examples[-args.examples :]

        if candidate_index % 5000 == 0:
            print(
                f"square-lift tower progress {candidate_index}/{len(witnesses)} "
                f"residual={residual_candidates} max_towers={maximum_variable_towers} "
                f"max_rows={maximum_variable_rows}",
                flush=True,
            )

    result = {
        "status": "exact square-lift tower analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "character_residual_candidates": residual_candidates,
        "multi_variable_tower_candidates": multi_variable_tower_candidates,
        "maximum_variable_negative_towers": maximum_variable_towers,
        "maximum_variable_fixed_negative_rows": maximum_variable_rows,
        "negative_tower_count_distribution": {
            str(k): v for k, v in sorted(negative_tower_count.items())
        },
        "variable_tower_count_distribution": {
            str(k): v for k, v in sorted(variable_tower_count.items())
        },
        "negative_row_count_distribution": {
            str(k): v for k, v in sorted(negative_row_count.items())
        },
        "variable_row_count_distribution": {
            str(k): v for k, v in sorted(variable_row_count.items())
        },
        "variable_rows_per_tower_distribution": {
            str(k): v for k, v in sorted(variable_rows_per_tower.items())
        },
        "top_variable_tower_bases": [
            {"a": a, "candidate_count": count}
            for a, count in variable_tower_frequency.most_common(50)
        ],
        "examples": examples,
        "theorem_checks": {
            "squarefree_tower_base_3_mod_4": True,
            "character_coherence_within_tower": True,
        },
        "claim_boundary": (
            "Tower decomposition and character coherence are exact. "
            "Finite tower-count distributions are proof-mining diagnostics, not universal bounds."
        ),
    }

    (args.out / "square-lift-tower-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    n = len(witnesses)
    report = "# Square-lift tower analysis\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Character residual candidates: **`{residual_candidates}`** (`{residual_candidates/n:.3%}`).\n\n"
    report += f"Candidates with more than one variable negative tower: **`{multi_variable_tower_candidates}`**.\n\n"
    report += f"Maximum variable negative tower count: **`{maximum_variable_towers}`**.\n\n"
    report += f"Maximum variable fixed-negative row count: **`{maximum_variable_rows}`**.\n\n"
    report += "Top variable negative tower bases:\n\n"
    report += "| a | candidates |\n|---:|---:|\n"
    for a, count in variable_tower_frequency.most_common(30):
        report += f"| {a} | {count} |\n"
    report += (
        "\nEvery tower member was checked to have the same Jacobi sign as its squarefree base. "
        "A nonempty tower core is a structured higher-p-adic proof target, not counterexample evidence.\n"
    )
    (args.out / "square-lift-tower-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
