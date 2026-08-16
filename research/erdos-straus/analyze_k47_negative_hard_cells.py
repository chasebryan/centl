#!/usr/bin/env python3
"""Split exact negative-character k=47 miss states by p mod 840 hard class.

This third-stage theorem-mining view combines exact k=47 abstract state IDs
with the six universal Mordell-hard residue classes. It imports the validated
state refinement and recomputes finite minimum covers inside each realized
(state, hard-residue) cell.

The cell covers are finite evidence only. The hard-residue partition itself is
universal for Mordell-hard primes.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import analyze_k47_negative_corridor as corridor
import analyze_k47_negative_states as states


def analyze(relations: Path, hi: int) -> dict:
    base = states.analyze(relations, hi)
    hits, _relation_union = corridor.load(relations, hi)

    cells = []
    for row in base["rows"]:
        if not row["finite_targets"]:
            continue
        primes = set(row["finite_target_primes"])
        for hard_residue in corridor.HARD_RESIDUES:
            targets = {p for p in primes if p % 840 == hard_residue}
            if not targets:
                continue
            covers = corridor.exact_minimum_covers(targets, hits)
            cells.append({
                "state_id": row["state_id"],
                "log_direction": row["log_direction"],
                "hard_residue_mod840": hard_residue,
                "finite_targets": len(targets),
                "finite_target_primes": sorted(targets),
                "minimum_finite_cover_size": len(covers[0]) if covers else None,
                "all_minimum_finite_covers": covers,
                "singleton_eliminators": [
                    k for k in corridor.PRIOR if targets <= hits[k]
                ],
                "capture_by_shift": [
                    {
                        "k": k,
                        "caught": len(targets & hits[k]),
                        "left": len(targets - hits[k]),
                    }
                    for k in corridor.PRIOR
                ],
            })

    cells.sort(key=lambda row: (
        corridor.ONE_PACKET_DIRECTIONS.index(row["log_direction"]),
        row["state_id"],
        row["hard_residue_mod840"],
    ))
    min_hist = Counter(row["minimum_finite_cover_size"] for row in cells)
    target_hist = Counter()
    for row in cells:
        target_hist[row["minimum_finite_cover_size"]] += row["finite_targets"]

    hard4 = [row for row in cells if row["minimum_finite_cover_size"] == 4]
    hard3 = [row for row in cells if row["minimum_finite_cover_size"] == 3]
    residue_counts = Counter()
    for row in cells:
        residue_counts[row["hard_residue_mod840"]] += row["finite_targets"]

    expected_hist = {1: 123, 2: 57, 3: 3, 4: 1}
    expected_target_hist = {1: 359, 2: 431, 3: 22, 4: 10}
    if len(cells) != 184:
        raise SystemExit(f"expected 184 realized state×hard cells, got {len(cells)}")
    if dict(sorted(min_hist.items())) != expected_hist:
        raise SystemExit(f"cell minimum-cover histogram changed: {dict(sorted(min_hist.items()))}")
    if dict(sorted(target_hist.items())) != expected_target_hist:
        raise SystemExit(f"cell target histogram changed: {dict(sorted(target_hist.items()))}")
    if len(hard4) != 1:
        raise SystemExit(f"expected one four-shift hard cell, got {len(hard4)}")
    core = hard4[0]
    if (
        core["state_id"] != "r7-s02"
        or core["hard_residue_mod840"] != 1
        or core["finite_targets"] != 10
    ):
        raise SystemExit(f"four-shift hard cell changed: {core}")
    if len(hard3) != 3 or sum(row["finite_targets"] for row in hard3) != 22:
        raise SystemExit("three-shift hard-cell regression changed")
    if dict(sorted(residue_counts.items())) != {1: 202, 169: 208, 361: 196, 529: 216}:
        raise SystemExit(f"negative-miss hard-residue counts changed: {dict(residue_counts)}")

    return {
        "analysis": "k47-negative-legendre-state-hard-cell-refinement-v1",
        "hi": hi,
        "negative_legendre_k47_misses": base["negative_legendre_k47_misses"],
        "realized_state_hard_cells": len(cells),
        "cell_minimum_cover_histogram": {str(k): v for k, v in sorted(min_hist.items())},
        "targets_by_cell_minimum_cover_size": {
            str(k): v for k, v in sorted(target_hist.items())
        },
        "negative_miss_targets_by_hard_residue": {
            str(k): v for k, v in sorted(residue_counts.items())
        },
        "hard_residues_with_no_finite_negative_k47_miss": [
            r for r in corridor.HARD_RESIDUES if residue_counts[r] == 0
        ],
        "cells_with_cover_size_at_most_2": sum(
            1 for row in cells if row["minimum_finite_cover_size"] <= 2
        ),
        "targets_in_cells_with_cover_size_at_most_2": sum(
            row["finite_targets"]
            for row in cells
            if row["minimum_finite_cover_size"] <= 2
        ),
        "three_shift_cells": hard3,
        "four_shift_hard_cells": hard4,
        "cells": cells,
        "claim": (
            "universal hard-residue partition plus exact fixed-k47 state IDs and a complete "
            "finite 10M relation census; cell cover claims remain finite evidence"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("relations", type=Path)
    ap.add_argument("--hi", type=int, required=True)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.relations, args.hi)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"negative-character k47 misses: {report['negative_legendre_k47_misses']}")
        print(f"realized state×hard cells: {report['realized_state_hard_cells']}")
        print(f"cell min-cover histogram: {report['cell_minimum_cover_histogram']}")
        print(f"targets by cell min-cover: {report['targets_by_cell_minimum_cover_size']}")
        print(f"four-shift hard cells: {report['four_shift_hard_cells']}")
        print("warning: finite theorem-mining evidence only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
