#!/usr/bin/env python3
"""Exact multiplicative-coset analysis for Type A/B trap layers.

For every k <= --k-limit this independently verifies the theorem in
MULTIPLICATIVE-TRAP-COSET.md:

    T_k subset -H_k,

where H_k is generated modulo 4k-1 by the prime divisors of k.  It also checks
that -1 is not in H_k, verifies inversion closure of T_k, and records the
quotient index [G_k:H_k].

This script is a theorem falsifier / finite diagnostic.  It does not establish
literature priority or any universal Erdős-Straus coverage claim.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def prime_divisors(n: int) -> list[int]:
    out: list[int] = []
    x = n
    p = 2
    while p * p <= x:
        if x % p == 0:
            out.append(p)
            while x % p == 0:
                x //= p
        p = 3 if p == 2 else p + 2
    if x > 1:
        out.append(x)
    return out


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


def subgroup_generated(m: int, generators: list[int]) -> set[int]:
    gens = [g % m for g in generators]
    H = {1 % m}
    queue = [1 % m]
    while queue:
        x = queue.pop()
        for g in gens:
            y = (x * g) % m
            if y not in H:
                H.add(y)
                queue.append(y)
    return H


def phi(n: int) -> int:
    result = n
    for p in prime_divisors(n):
        result -= result // p
    return result


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("Jacobi denominator must be positive and odd")
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
    ap.add_argument("--k-limit", type=int, default=1500)
    ap.add_argument("--out", type=Path, default=Path("trap-coset-output"))
    ap.add_argument("--top", type=int, default=30)
    args = ap.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)

    rows: list[dict] = []
    index_counts: collections.Counter[int] = collections.Counter()

    for k in range(1, args.k_limit + 1):
        m = 4 * k - 1
        gens = prime_divisors(k)
        H = subgroup_generated(m, gens)
        minus_H = {(-h) % m for h in H}
        T = trap_set(k)

        if 4 % m not in H:
            raise AssertionError(f"4 not in H_k at k={k}")
        if not T <= minus_H:
            raise AssertionError(f"trap escaped -H_k at k={k}")
        if (-1) % m in H:
            raise AssertionError(f"-1 unexpectedly lies in H_k at k={k}")
        if H & minus_H:
            raise AssertionError(f"H_k and -H_k intersect at k={k}")

        # The generators must all be Jacobi-positive and therefore the whole
        # subgroup must remain inside the positive Jacobi kernel.
        if any(jacobi(g, m) != 1 for g in gens):
            raise AssertionError(f"Jacobi-positive generator theorem failed at k={k}")
        if any(jacobi(h, m) != 1 for h in H):
            raise AssertionError(f"H_k left Jacobi-positive kernel at k={k}")

        # López already notes the Type A/B inverse relation.  Keep it as a
        # regression check because it is also a useful internal consistency
        # condition for the trap set.
        if {pow(t, -1, m) for t in T} != T:
            raise AssertionError(f"trap set is not inversion-closed at k={k}")

        ph = phi(m)
        if ph % len(H):
            raise AssertionError(f"subgroup order does not divide phi at k={k}")
        index = ph // len(H)
        if index < 2 or index % 2:
            raise AssertionError(f"trap-coset index is not even >=2 at k={k}")

        index_counts[index] += 1
        rows.append(
            {
                "k": k,
                "m": m,
                "prime_divisors_of_k": gens,
                "phi_m": ph,
                "H_size": len(H),
                "trap_size": len(T),
                "coset_index": index,
                "coset_fraction_num": 1,
                "coset_fraction_den": index,
            }
        )

        if k % 250 == 0:
            print(f"trap-coset progress {k}/{args.k_limit}", flush=True)

    indices = [int(row["coset_index"]) for row in rows]
    top = sorted(rows, key=lambda r: (-int(r["coset_index"]), int(r["k"])))[: args.top]

    result = {
        "status": "exact finite multiplicative Type A/B trap-coset verification",
        "k_limit": args.k_limit,
        "layers_checked": len(rows),
        "theorem_checks": {
            "T_subset_minus_H": True,
            "minus_one_not_in_H": True,
            "H_minus_H_disjoint": True,
            "H_jacobi_positive": True,
            "trap_inversion_closed": True,
            "coset_index_even_at_least_two": True,
        },
        "index_min": min(indices),
        "index_max": max(indices),
        "index_mean": sum(indices) / len(indices),
        "index_median": sorted(indices)[len(indices) // 2]
        if len(indices) % 2
        else (sorted(indices)[len(indices) // 2 - 1] + sorted(indices)[len(indices) // 2]) / 2,
        "index_counts": {str(k): v for k, v in sorted(index_counts.items())},
        "top_index_layers": top,
        "rows": rows,
        "claim_boundary": (
            "This is a finite falsifier and diagnostic for the proved subgroup/coset theorem. "
            "It does not prove Direct-Shadow Completeness, universal Type A/B coverage, the Erdős-Straus conjecture, or publication priority."
        ),
    }

    (args.out / "trap-coset-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Multiplicative Type A/B trap-coset analysis\n\n"
    report += f"Range: `k <= {args.k_limit}`.\n\n"
    report += "All theorem regression checks passed.\n\n"
    report += f"Minimum quotient index: `{result['index_min']}`.\n\n"
    report += f"Median quotient index: `{result['index_median']}`.\n\n"
    report += f"Mean quotient index: `{result['index_mean']:.6f}`.\n\n"
    report += f"Maximum quotient index: **`{result['index_max']}`**.\n\n"
    report += "| k | 4k-1 | phi | |H_k| | index | |T_k| |\n"
    report += "|---:|---:|---:|---:|---:|---:|\n"
    for row in top:
        report += (
            f"| {row['k']} | {row['m']} | {row['phi_m']} | {row['H_size']} | "
            f"{row['coset_index']} | {row['trap_size']} |\n"
        )
    report += (
        "\nEvery Type A/B trap is contained in the single coset `-H_k`. "
        "The Jacobi `-1` theorem is only an order-two projection of this quotient structure.\n"
    )
    (args.out / "trap-coset-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
