#!/usr/bin/env python3
"""Mine exact squareclass-cycle obstructions to the quadratic character shield.

This analyzer does not use stored avoiding witnesses. It reconstructs the F_2
character system from each directly novel candidate and performs Gaussian
elimination while tracking row provenance. Any inconsistency is returned with
an explicit subset of earlier layers whose free squareclasses cancel while the
fixed character parity is odd.

Such a cycle obstructs only the quadratic character shield. It is not evidence
of union shadowing or failure of DSC-P.
"""
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

from quadratic_trap_signature_analyzer import factor_exp, legendre_bit, prime_list


def eliminate_with_provenance(
    rows: list[tuple[int, int]],
) -> tuple[bool, int, int | None]:
    """Return solvable, final free-row rank, first inconsistent provenance."""
    basis: dict[int, tuple[int, int, int]] = {}
    first_bad: int | None = None

    for row_index, (mask, rhs) in enumerate(rows):
        x = mask
        b = rhs
        provenance = 1 << row_index

        while x:
            pivot = x.bit_length() - 1
            if pivot in basis:
                y, c, p = basis[pivot]
                x ^= y
                b ^= c
                provenance ^= p
            else:
                basis[pivot] = (x, b, provenance)
                break

        if x == 0 and b and first_bad is None:
            first_bad = provenance

    return first_bad is None, len(basis), first_bad


def provenance_indices(mask: int) -> list[int]:
    out: list[int] = []
    while mask:
        low = mask & -mask
        i = low.bit_length() - 1
        out.append(i)
        mask ^= low
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--examples", type=int, default=40)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    primes = prime_list(4 * k_limit)
    p_index = {p: i for i, p in enumerate(primes)}

    odd_masks = [0] * (k_limit + 1)
    for j in range(1, k_limit + 1):
        fac = factor_exp(4 * j - 1)
        mask = 0
        for p, a in fac.items():
            if a % 2:
                mask |= 1 << p_index[p]
        odd_masks[j] = mask

    solvable_count = 0
    inconsistent_count = 0
    cycle_rank_counts: collections.Counter[int] = collections.Counter()
    obstruction_size_counts: collections.Counter[int] = collections.Counter()
    obstruction_max_layer_counts: collections.Counter[int] = collections.Counter()
    examples: list[dict] = []
    max_cycle_rank = 0
    max_obstruction_size = 0

    for candidate_index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])

        fixed_mask = 0
        negative_fixed_mask = 0
        for p in primes:
            if p > 4 * k - 1:
                break
            if L % p:
                continue
            bit = 1 << p_index[p]
            fixed_mask |= bit
            if legendre_bit(r, p):
                negative_fixed_mask |= bit

        rows: list[tuple[int, int]] = []
        layer_map: list[int] = []
        for j in range(1, k):
            row = odd_masks[j]
            free = row & ~fixed_mask
            rhs = (row & negative_fixed_mask).bit_count() & 1
            rows.append((free, rhs))
            layer_map.append(j)

        solvable, rank, bad = eliminate_with_provenance(rows)
        cycle_rank = len(rows) - rank
        cycle_rank_counts[cycle_rank] += 1
        max_cycle_rank = max(max_cycle_rank, cycle_rank)

        if solvable:
            solvable_count += 1
        else:
            inconsistent_count += 1
            assert bad is not None
            row_indices = provenance_indices(bad)
            layers = [layer_map[i] for i in row_indices]
            size = len(layers)
            obstruction_size_counts[size] += 1
            obstruction_max_layer_counts[max(layers)] += 1
            max_obstruction_size = max(max_obstruction_size, size)

            # Exact certificate checks.
            free_xor = 0
            rhs_xor = 0
            for i in row_indices:
                free_xor ^= rows[i][0]
                rhs_xor ^= rows[i][1]
            if free_xor != 0 or rhs_xor != 1:
                raise AssertionError("invalid quadratic cycle certificate")

            if len(examples) < args.examples:
                examples.append(
                    {
                        "candidate_index": candidate_index,
                        "k": k,
                        "h": int(rec["h"]),
                        "t": int(rec["t"]),
                        "free_row_rank": rank,
                        "quadratic_cycle_rank": cycle_rank,
                        "obstruction_cycle_size": size,
                        "obstruction_layers": layers,
                    }
                )

        if candidate_index % 5000 == 0:
            print(
                f"quadratic-cycle progress {candidate_index}/{len(witnesses)} "
                f"solvable={solvable_count} inconsistent={inconsistent_count} "
                f"max_cycle_rank={max_cycle_rank} max_obstruction={max_obstruction_size}",
                flush=True,
            )

    n = len(witnesses)
    result = {
        "status": "exact quadratic character cycle-core analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": n,
        "character_solvable_candidates": solvable_count,
        "character_inconsistent_candidates": inconsistent_count,
        "character_solvable_fraction": solvable_count / n,
        "quadratic_cycle_rank_counts": {
            str(k): v for k, v in sorted(cycle_rank_counts.items())
        },
        "maximum_quadratic_cycle_rank": max_cycle_rank,
        "obstruction_cycle_size_counts": {
            str(k): v for k, v in sorted(obstruction_size_counts.items())
        },
        "maximum_first_obstruction_cycle_size": max_obstruction_size,
        "obstruction_max_layer_counts": {
            str(k): v for k, v in sorted(obstruction_max_layer_counts.items())
        },
        "obstruction_examples": examples,
        "claim_boundary": (
            "An inconsistency certificate is an exact obstruction to the sufficient quadratic character shield only. "
            "It is a subset of earlier layers whose free squareclass vectors cancel while fixed character parity is odd. "
            "It does not imply union shadowing or failure of exact Type A/B avoidance."
        ),
    }
    (args.out / "quadratic-cycle-core-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Quadratic cycle core\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Character-shield solvable: **`{solvable_count}`** (`{solvable_count/n:.3%}`).\n\n"
    report += f"Character-cycle residual: **`{inconsistent_count}`** (`{inconsistent_count/n:.3%}`).\n\n"
    report += f"Maximum quadratic cycle rank observed: `{max_cycle_rank}`.\n\n"
    report += f"Maximum first obstruction-cycle size observed: `{max_obstruction_size}` layers.\n\n"
    if obstruction_size_counts:
        report += "| first obstruction cycle size | candidates |\n|---:|---:|\n"
        for size, count in sorted(obstruction_size_counts.items()):
            report += f"| {size} | {count} |\n"
    report += (
        "\nEach recorded residual includes an exact F_2 dependency certificate. "
        "A residual cycle obstructs only the character shield, not DSC-P.\n"
    )
    (args.out / "quadratic-cycle-core-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
