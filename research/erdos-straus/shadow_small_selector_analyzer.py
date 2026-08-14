#!/usr/bin/env python3
"""Test a bounded integer selector menu on residual Type A/B fiber kernels.

This is a proof-mining diagnostic built on the exact fiber-peeling theorem.
It does not use the stored reduced witness to decide peelability or selector
success. A selector that satisfies the residual kernel, together with reverse
fiber extension, independently proves existence of a reduced avoiding class
for that candidate.

Failure of the bounded selector menu is not a DSC-P counterexample. It means
only that this particularly simple post-peeling construction did not suffice.
"""
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

from shadow_fiber_kernel_analyzer import (
    factor_exp,
    fiber_peel,
    parameter_constraints,
    trap_set,
)


def selector_menu(bound: int) -> list[int]:
    """Deterministic increasing-absolute-value selector order."""
    if bound < 0:
        raise ValueError("selector bound must be nonnegative")
    out = [0]
    for a in range(1, bound + 1):
        out.extend((a, -a))
    return out


def selector_satisfies(
    s: int,
    r: int,
    L: int,
    residual_primes: tuple[int, ...],
    residual_edges: list[dict],
) -> bool:
    # Preserve reducedness on every residual prime coordinate. If p divides L,
    # candidate admissibility already guarantees p does not divide r.
    for p in residual_primes:
        if L % p and (r + L * s) % p == 0:
            return False

    # All residual forbidden pullbacks are expressed directly in the original
    # integer parameter s, so a single integer selector determines every local
    # prime-power coordinate simultaneously.
    for edge in residual_edges:
        if s % int(edge["q"]) in edge["R"]:
            return False
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--selector-bound", type=int, default=64)
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    traps = [set()] + [trap_set(k) for k in range(1, k_limit + 1)]
    factors = {q: factor_exp(q) for q in range(1, 4 * k_limit, 2)}
    menu = selector_menu(args.selector_bound)

    empty_kernel = 0
    selector_solved = 0
    unresolved = 0
    selector_counts: collections.Counter[int] = collections.Counter()
    radius_counts: collections.Counter[int] = collections.Counter()
    kernel_size_counts: collections.Counter[int] = collections.Counter()
    unresolved_examples: list[dict] = []
    solved_examples: list[dict] = []
    max_radius = 0

    for index, rec in enumerate(witnesses, start=1):
        k, h, t = int(rec["k"]), int(rec["h"]), int(rec["t"])
        r, L, constraints = parameter_constraints(k, h, t, traps)
        peeled = fiber_peel(r, L, constraints, factors)
        primes = peeled["residual_primes"]
        edges = peeled["residual_edges"]
        kernel_size_counts[len(primes)] += 1

        if not primes:
            empty_kernel += 1
            continue

        chosen = next(
            (
                s
                for s in menu
                if selector_satisfies(s, r, L, primes, edges)
            ),
            None,
        )

        if chosen is None:
            unresolved += 1
            if len(unresolved_examples) < args.examples:
                unresolved_examples.append(
                    {
                        "candidate_index": index,
                        "k": k,
                        "h": h,
                        "t": t,
                        "residual_primes": list(primes),
                        "residual_edge_count": len(edges),
                    }
                )
        else:
            selector_solved += 1
            selector_counts[chosen] += 1
            radius = abs(chosen)
            radius_counts[radius] += 1
            max_radius = max(max_radius, radius)
            if len(solved_examples) < args.examples:
                solved_examples.append(
                    {
                        "candidate_index": index,
                        "k": k,
                        "h": h,
                        "t": t,
                        "selector": chosen,
                        "residual_primes": list(primes),
                        "residual_edge_count": len(edges),
                    }
                )

        if index % 2000 == 0:
            print(
                f"small-selector progress {index}/{len(witnesses)} "
                f"empty={empty_kernel} selector={selector_solved} "
                f"unresolved={unresolved} max_radius={max_radius}",
                flush=True,
            )

    nonempty = len(witnesses) - empty_kernel
    cumulative = empty_kernel
    cumulative_rows = [
        {
            "radius": "fiber-empty",
            "newly_solved": empty_kernel,
            "cumulative": cumulative,
            "cumulative_fraction": cumulative / len(witnesses),
        }
    ]
    for radius in sorted(radius_counts):
        count = radius_counts[radius]
        cumulative += count
        cumulative_rows.append(
            {
                "radius": radius,
                "newly_solved": count,
                "cumulative": cumulative,
                "cumulative_fraction": cumulative / len(witnesses),
            }
        )

    result = {
        "status": "bounded small-selector proof-mining analysis",
        "k_limit": k_limit,
        "selector_bound": args.selector_bound,
        "direct_novel_candidates": len(witnesses),
        "fiber_empty_candidates": empty_kernel,
        "nonempty_fiber_kernels": nonempty,
        "selector_solved_nonempty_kernels": selector_solved,
        "selector_solved_fraction_of_nonempty": (
            selector_solved / nonempty if nonempty else 1.0
        ),
        "total_independently_resolved_by_fiber_or_selector": empty_kernel + selector_solved,
        "total_resolved_fraction": (empty_kernel + selector_solved) / len(witnesses),
        "unresolved_selector_kernels": unresolved,
        "maximum_selector_radius_used": max_radius,
        "selector_counts": {str(k): v for k, v in sorted(selector_counts.items())},
        "radius_counts": {str(k): v for k, v in sorted(radius_counts.items())},
        "cumulative_resolution": cumulative_rows,
        "kernel_size_counts": {str(k): v for k, v in sorted(kernel_size_counts.items())},
        "solved_examples": solved_examples,
        "unresolved_examples": unresolved_examples,
        "claim_boundary": (
            "Fiber-empty candidates are resolved by the exact fiber-peeling theorem. "
            "For nonempty kernels, selector success is checked only against the reconstructed residual kernel and local reducedness; reverse fiber extension then supplies a reduced avoiding assignment. "
            "An unresolved bounded selector is not evidence of union coverage or failure of DSC-P."
        ),
    }
    (args.out / "shadow-small-selector-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    n = len(witnesses)
    report = "# Small-selector residual-kernel analysis\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Selector menu: `0, ±1, ..., ±{args.selector_bound}`.\n\n"
    report += f"Fiber kernel already empty: **`{empty_kernel}`** (`{empty_kernel/n:.3%}`).\n\n"
    if nonempty:
        report += (
            f"Nonempty kernels solved by the bounded selector menu: **`{selector_solved}/{nonempty}`** "
            f"(`{selector_solved/nonempty:.3%}`).\n\n"
        )
    report += (
        f"Total independently resolved by fiber peeling or selector: **`{empty_kernel + selector_solved}/{n}`** "
        f"(`{(empty_kernel + selector_solved)/n:.3%}`).\n\n"
    )
    report += f"Unresolved by this bounded selector menu: **`{unresolved}`**.\n\n"
    report += f"Largest selector radius actually used: `{max_radius}`.\n\n"
    report += "| selector radius | newly solved | cumulative |\n|---:|---:|---:|\n"
    for row in cumulative_rows:
        report += (
            f"| {row['radius']} | {row['newly_solved']} | "
            f"{row['cumulative_fraction']:.3%} |\n"
        )
    report += (
        "\nA bounded-selector failure is not a Direct-Shadow Completeness counterexample. "
        "It only marks a residual kernel requiring a richer local construction.\n"
    )
    (args.out / "shadow-small-selector-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
