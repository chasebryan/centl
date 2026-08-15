#!/usr/bin/env python3
"""Analyze the squarefree-lift residual core of Type A/B candidates.

This implements SQUAREFREE-LIFT-CORE.md. It uses only the target candidate
(k,h,t,r,L) from an already generated direct-shadow bundle. Stored avoiding
witnesses are not consulted.

For each earlier layer j it computes

    m_j = 4j-1 = d_j * s_j^2,

where d_j is the squarefree kernel and d_j = 4a_j-1. It then computes the
projection excess

    E_j = (T_j mod d_j) \ T_{a_j}.

For a directly novel candidate, every fixed-negative layer has d_j|L and
r mod d_j outside T_{a_j}. Such a layer can only remain an exact immutable
obstruction candidate when r mod d_j lies in E_j.
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


def factor_exp(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    p = 3
    while p * p <= x:
        while x % p == 0:
            out[p] = out.get(p, 0) + 1
            x //= p
        p += 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def squarefree_kernel(n: int) -> int:
    d = 1
    for p, a in factor_exp(n).items():
        if a % 2:
            d *= p
    return d


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


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

    traps = [set()] + [trap_set(k) for k in range(1, k_limit + 1)]
    modulus = [0] * (k_limit + 1)
    sf = [0] * (k_limit + 1)
    ancestor = [0] * (k_limit + 1)
    lift = [0] * (k_limit + 1)
    excess: list[set[int]] = [set() for _ in range(k_limit + 1)]

    nonsquarefree = 0
    excess_layers: list[int] = []
    max_excess = (0, 0)

    for j in range(1, k_limit + 1):
        m = 4 * j - 1
        d = squarefree_kernel(m)
        if d % 4 != 3:
            raise AssertionError(f"squarefree kernel is not 3 mod 4 at j={j}")
        a = (d + 1) // 4
        q = m // d
        s = math.isqrt(q)
        if d * s * s != m:
            raise AssertionError(f"m_j/d_j is not a square at j={j}")
        if 4 * a - 1 != d or a > j:
            raise AssertionError(f"invalid squarefree ancestor at j={j}")

        modulus[j] = m
        sf[j] = d
        ancestor[j] = a
        lift[j] = s
        if d != m:
            nonsquarefree += 1

        projected = {u % d for u in traps[j]}
        e = projected - traps[a]
        excess[j] = e
        if e:
            excess_layers.append(j)
            max_excess = max(max_excess, (len(e), j))

    # L depends only on target depth k. Precompute which earlier squarefree
    # ancestors are fixed by the target progression.
    fixed_by_k: list[list[int]] = [[] for _ in range(k_limit + 1)]
    for k in range(1, k_limit + 1):
        L = math.lcm(840, 4 * k - 1)
        fixed_by_k[k] = [j for j in range(1, k) if L % sf[j] == 0]

    fixed_negative_counts: collections.Counter[int] = collections.Counter()
    active_excess_counts: collections.Counter[int] = collections.Counter()
    active_layer_frequency: collections.Counter[int] = collections.Counter()
    character_residual = 0
    residual_eliminated = 0
    active_candidates = 0
    examples: list[dict] = []

    for index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        expected_L = math.lcm(840, 4 * k - 1)
        if L != expected_L:
            raise AssertionError(f"candidate L mismatch at index {index}")

        fixed_negative: list[int] = []
        active: list[int] = []
        for j in fixed_by_k[k]:
            d = sf[j]
            sign = jacobi(r, d)
            if sign == 0:
                raise AssertionError("candidate is not a unit at a fixed squarefree ancestor")
            if sign != -1:
                continue

            fixed_negative.append(j)
            a = ancestor[j]
            rd = r % d
            # A directly novel candidate cannot already be trapped at the
            # fixed ancestor modulus.
            if rd in traps[a]:
                raise AssertionError(
                    f"direct novelty violated by ancestor a={a} for candidate {index}"
                )
            if rd in excess[j]:
                active.append(j)
                active_layer_frequency[j] += 1

        fixed_negative_counts[len(fixed_negative)] += 1
        active_excess_counts[len(active)] += 1
        if fixed_negative:
            character_residual += 1
            if not active:
                residual_eliminated += 1
        if active:
            active_candidates += 1
            if len(examples) < args.examples:
                examples.append(
                    {
                        "candidate_index": index,
                        "k": k,
                        "h": int(rec["h"]),
                        "t": int(rec["t"]),
                        "fixed_negative_layers": fixed_negative,
                        "active_projection_excess_layers": active,
                    }
                )

        if index % 5000 == 0:
            print(
                f"squarefree-core progress {index}/{len(witnesses)} "
                f"character_residual={character_residual} active={active_candidates}",
                flush=True,
            )

    max_excess_size, max_excess_layer = max_excess
    result = {
        "status": "exact squarefree-lift residual-core analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "nonsquarefree_modulus_layers": nonsquarefree,
        "nonempty_projection_excess_layers": len(excess_layers),
        "empty_projection_excess_layers": k_limit - len(excess_layers),
        "projection_excess_layers": excess_layers,
        "max_projection_excess_size": max_excess_size,
        "max_projection_excess_layer": max_excess_layer,
        "max_projection_excess_modulus": modulus[max_excess_layer] if max_excess_layer else 0,
        "max_projection_excess_ancestor_depth": ancestor[max_excess_layer] if max_excess_layer else 0,
        "max_projection_excess_ancestor_modulus": sf[max_excess_layer] if max_excess_layer else 0,
        "character_residual_candidates": character_residual,
        "character_residual_with_no_active_projection_excess": residual_eliminated,
        "candidates_with_active_projection_excess": active_candidates,
        "candidates_with_zero_active_projection_excess": len(witnesses) - active_candidates,
        "fixed_negative_count_distribution": {str(k): v for k, v in sorted(fixed_negative_counts.items())},
        "active_excess_count_distribution": {str(k): v for k, v in sorted(active_excess_counts.items())},
        "top_active_excess_layers": [
            {"j": j, "count": count, "m": modulus[j], "ancestor": ancestor[j], "d": sf[j], "lift": lift[j]}
            for j, count in active_layer_frequency.most_common(40)
        ],
        "examples": examples,
        "claim_boundary": (
            "The analyzer proves only which immutable fixed-negative layers are automatically exact-safe after projection to their squarefree ancestor. "
            "Zero active projection-excess layers does not by itself prove simultaneous avoidance of all non-fixed earlier layers."
        ),
    }
    (args.out / "squarefree-lift-core-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    n = len(witnesses)
    report = "# Squarefree-lift residual core\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Non-squarefree layer moduli: `{nonsquarefree}`.\n\n"
    report += f"Layers with nonempty projection excess: **`{len(excess_layers)}`**.\n\n"
    report += f"Character-shield residual candidates: `{character_residual}`.\n\n"
    report += (
        "Character residuals with no fixed-negative layer surviving the exact "
        f"projection-excess test: **`{residual_eliminated}`**.\n\n"
    )
    report += f"Candidates with at least one active projection-excess layer: **`{active_candidates}`**.\n\n"
    report += f"Maximum active projection-excess layers in a candidate: `{max(active_excess_counts)}`.\n\n"
    report += (
        "This is an exact localization of the immutable character residual, not a complete "
        "simultaneous-avoidance proof.\n"
    )
    (args.out / "squarefree-lift-core-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
