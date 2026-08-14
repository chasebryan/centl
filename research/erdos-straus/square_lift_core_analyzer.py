#!/usr/bin/env python3
"""Analyze the square-lift core left by the quadratic character shield.

Input: direct-shadow-completeness.json.

For every directly novel candidate, this script identifies character-fixed
negative earlier rows and verifies the theorem from SQUARE-LIFT-CORE.md: every
prime outside the target progression modulus L occurs to even exponent in such
a row, and therefore also to even exponent in its pullback modulus q_j.

The script records finite distributions only.  It does not treat a nonempty
core as a counterexample to Direct-Shadow Completeness.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path


def factor_exp(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    p = 3
    while p * p <= x:
        if x % p == 0:
            a = 0
            while x % p == 0:
                x //= p
                a += 1
            out[p] = a
        p += 2
    if x > 1:
        out[x] = 1
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
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    mf = [dict()] + [factor_exp(4 * j - 1) for j in range(1, k_limit + 1)]
    square_support = [frozenset()] + [
        frozenset(p for p, a in mf[j].items() if a % 2)
        for j in range(1, k_limit + 1)
    ]

    shield_solved = 0
    residual_candidates = 0
    variable_core_size: collections.Counter[int] = collections.Counter()
    pullback_q_counts: collections.Counter[int] = collections.Counter()
    new_square_prime_counts: collections.Counter[int] = collections.Counter()
    fixed_prime_remainder_counts: collections.Counter[int] = collections.Counter()
    maximum_variable_rows = 0
    examples: list[dict] = []

    for index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        fixed_primes = set(factor_exp(L))

        negative: list[int] = []
        variable: list[dict] = []

        for j in range(1, k):
            if not square_support[j] <= fixed_primes:
                continue
            mj = 4 * j - 1
            if jacobi(r, mj) != -1:
                continue
            negative.append(j)

            if L % mj == 0:
                continue

            q = mj // math.gcd(L, mj)
            qfac = factor_exp(q)
            outside_square_part = 1
            inside_part = 1

            for p, a in qfac.items():
                if L % p:
                    if a % 2:
                        raise AssertionError(
                            f"square-lift theorem failed at candidate={index}, j={j}, p={p}, exponent={a}"
                        )
                    new_square_prime_counts[p] += 1
                    outside_square_part *= p**a
                else:
                    fixed_prime_remainder_counts[p] += 1
                    inside_part *= p**a

            pullback_q_counts[q] += 1
            variable.append(
                {
                    "j": j,
                    "m": mj,
                    "q": q,
                    "inside_fixed_prime_part": inside_part,
                    "outside_square_part": outside_square_part,
                }
            )

        if not negative:
            shield_solved += 1
        else:
            residual_candidates += 1
            variable_core_size[len(variable)] += 1
            maximum_variable_rows = max(maximum_variable_rows, len(variable))
            if variable and len(examples) < 30:
                examples.append(
                    {
                        "candidate_index": index,
                        "k": k,
                        "h": int(rec["h"]),
                        "t": int(rec["t"]),
                        "fixed_negative_rows": len(negative),
                        "variable_fixed_negative_rows": variable,
                    }
                )

        if index % 5000 == 0:
            print(
                f"square-lift progress {index}/{len(witnesses)} "
                f"shield={shield_solved} residual={residual_candidates} "
                f"max_variable={maximum_variable_rows}",
                flush=True,
            )

    result = {
        "status": "exact square-lift character-core analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "quadratic_shield_solved_candidates": shield_solved,
        "fixed_negative_character_residual_candidates": residual_candidates,
        "variable_fixed_negative_core_size_counts": {
            str(k): v for k, v in sorted(variable_core_size.items())
        },
        "maximum_variable_fixed_negative_rows": maximum_variable_rows,
        "pullback_q_counts": {str(k): v for k, v in sorted(pullback_q_counts.items())},
        "new_outside_square_prime_counts": {
            str(k): v for k, v in sorted(new_square_prime_counts.items())
        },
        "fixed_prime_remainder_counts": {
            str(k): v for k, v in sorted(fixed_prime_remainder_counts.items())
        },
        "examples": examples,
        "theorem_check": "PASSED",
        "claim_boundary": (
            "Every reported outside-L prime exponent was checked to be even. "
            "Finite core distributions are diagnostics, not universal bounds and not counterexample evidence."
        ),
    }

    (args.out / "square-lift-core-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    n = len(witnesses)
    report = "# Square-lift character core\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Quadratic shield solved: **`{shield_solved}`** (`{shield_solved/n:.3%}`).\n\n"
    report += f"Fixed-negative character residual: **`{residual_candidates}`** (`{residual_candidates/n:.3%}`).\n\n"
    report += f"Maximum variable fixed-negative rows in one candidate: `{maximum_variable_rows}`.\n\n"
    report += "Every prime outside `L` occurring in the variable fixed-negative core had even exponent, as required by the square-lift theorem.\n\n"
    report += "Observed outside-L square primes:\n\n"
    report += "```text\n"
    for p, count in sorted(new_square_prime_counts.items()):
        report += f"{p}: {count}\n"
    report += "```\n\n"
    report += "A nonempty square-lift core is not a failure. It is the higher p-adic residue problem left after the quadratic squareclass information has been exhausted.\n"

    (args.out / "square-lift-core-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
