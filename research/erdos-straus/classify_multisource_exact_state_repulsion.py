#!/usr/bin/env python3
"""Classify genuine two-source state-only exact repellers.

A genuine pair repeller is a pair of positive incoming source residues such that:
- the ordinary fixed-shift closure has negative-character miss centers;
- neither source residue alone eliminates all negative centers;
- the two routed residues together eliminate every negative center;
- the combined starting divisor mask still does not fill QR(k).

Pairs are residue multisets: r1=r2 is allowed because two distinct routed source
primes may have the same residue modulo the destination.
"""
from __future__ import annotations

import argparse
import itertools
import json

from classify_exact_state_incoming_repulsion import (
    HARD_CLASSES,
    DESTINATIONS,
    class_seed,
    local_analysis,
    model,
)

EXPECTED_STATE_ONLY_PAIRS = {
    (1, 19, 5): ((4, 4), (5, 5)),
    (169, 19, 1): (
        (4, 9), (4, 16), (4, 17), (5, 6), (5, 16),
        (6, 9), (6, 16), (6, 17), (16, 17), (17, 17),
    ),
    (361, 19, 5): ((4, 4), (5, 5)),
    (529, 19, 1): (
        (4, 9), (4, 16), (4, 17), (5, 6), (5, 16),
        (6, 9), (6, 16), (6, 17), (16, 17), (17, 17),
    ),
    (1, 31, 2): (
        (7, 7), (7, 18), (7, 19), (10, 10), (10, 20), (10, 28),
        (18, 18), (18, 19), (19, 19), (20, 20), (20, 28), (28, 28),
    ),
    (121, 31, 2): (
        (7, 7), (7, 18), (7, 19), (10, 10), (10, 20), (10, 28),
        (18, 18), (18, 19), (19, 19), (20, 20), (20, 28), (28, 28),
    ),
    (1, 47, 6): (
        (2, 3), (2, 16), (3, 3), (3, 16), (3, 24), (4, 6),
        (4, 8), (6, 12), (6, 24), (12, 12), (16, 16), (16, 24),
    ),
    (169, 47, 6): (
        (2, 3), (2, 16), (3, 3), (3, 16), (3, 24), (4, 6),
        (4, 8), (6, 12), (6, 24), (12, 12), (16, 16), (16, 24),
    ),
    (361, 47, 6): (
        (2, 3), (2, 16), (3, 3), (3, 16), (3, 24), (4, 6),
        (4, 8), (6, 12), (6, 24), (12, 12), (16, 16), (16, 24),
    ),
    (529, 47, 6): (
        (2, 3), (2, 16), (3, 3), (3, 16), (3, 24), (4, 6),
        (4, 8), (6, 12), (6, 24), (12, 12), (16, 16), (16, 24),
    ),
}

EXPECTED_AGGREGATES = {
    "state_only_pair_branches": 10,
    "state_only_pair_residue_multisets": 96,
    "formerly_single_source_no_repeller_branches_resolved": 2,
}


def analyze_branch(h: int, k: int, seed: int) -> dict[str, object] | None:
    local = local_analysis(k, seed)
    ordinary_negative = tuple(int(x) for x in local["ordinary_negative_centers"])
    if not ordinary_negative:
        return None

    m = model(k)
    qr = frozenset(x * x % k for x in range(1, k))
    base = m.seed_state(seed)
    single_exact = {
        int(row["source_residue"])
        for row in local["rows"]
        if row["eliminates_all_negative_centers"]
    }

    rows = []
    for r1, r2 in itertools.combinations_with_replacement(sorted(qr), 2):
        # Genuine pair: neither routed residue is already an exact repeller.
        if r1 in single_exact or r2 in single_exact:
            continue

        start = m.transition(m.transition(base, r1), r2)
        closure = m.closure(start)
        misses = tuple(state for state in closure if m.is_miss(state))
        negative = tuple(sorted({
            m.p_center(state)
            for state in misses
            if m.p_center(state) not in qr
        }))
        if negative:
            continue

        mask = m.mask_residues(start)
        if mask == qr:
            # This branch is explained by ordinary two-source QR saturation,
            # not by exact state-only geometry.
            continue

        rows.append({
            "source_residues": [r1, r2],
            "augmented_mask_size": len(mask),
            "qr_size": len(qr),
            "augmented_state_count": len(closure),
            "augmented_miss_count": len(misses),
            "augmented_center_count": len({m.p_center(state) for state in misses}),
            "remaining_negative_centers": [],
            "qr_saturates": False,
        })

    if not rows:
        return None

    return {
        "hard_class": h,
        "destination_k": k,
        "base_seed": seed,
        "ordinary_negative_centers": list(ordinary_negative),
        "single_source_exact_repellers": sorted(single_exact),
        "genuine_state_only_pairs": rows,
    }


def analyze() -> dict[str, object]:
    branches = []
    actual_map: dict[tuple[int, int, int], tuple[tuple[int, int], ...]] = {}

    for k in DESTINATIONS:
        for h in HARD_CLASSES:
            seed = class_seed(k, h)
            if seed % k == 0:
                continue
            row = analyze_branch(h, k, seed)
            if row is None:
                continue
            branches.append(row)
            key = (h, k, seed)
            actual_map[key] = tuple(
                tuple(int(x) for x in pair["source_residues"])
                for pair in row["genuine_state_only_pairs"]
            )

    if actual_map != EXPECTED_STATE_ONLY_PAIRS:
        raise SystemExit(f"two-source state-only repeller atlas changed: {actual_map!r}")

    pair_count = sum(len(v) for v in actual_map.values())
    resolved = sum(
        key in actual_map
        for key in ((169, 19, 1), (529, 19, 1))
    )
    aggregates = {
        "state_only_pair_branches": len(actual_map),
        "state_only_pair_residue_multisets": pair_count,
        "formerly_single_source_no_repeller_branches_resolved": resolved,
    }
    if aggregates != EXPECTED_AGGREGATES:
        raise SystemExit(f"two-source state-only aggregates changed: {aggregates!r}")

    return {
        "analysis": "multisource-exact-state-repulsion-v1",
        **aggregates,
        "destinations_scanned": list(DESTINATIONS),
        "branches": branches,
        "flagship_new_branches": [
            row for row in branches
            if row["destination_k"] == 19 and row["hard_class"] in (169, 529)
        ],
        "claim": (
            "two positive routed source residues can jointly eliminate every negative exact "
            "miss center even when neither source does so alone and the combined seed does "
            "not QR-saturate"
        ),
        "claim_boundary": (
            "residue-pair atlas only; two distinct proved positive source primes must realize "
            "the named route residues on the same ancestry-compatible branch"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"state-only pair branches: {report['state_only_pair_branches']}")
        print(f"state-only residue multisets: {report['state_only_pair_residue_multisets']}")
        print(f"resolved former exceptions: {report['formerly_single_source_no_repeller_branches_resolved']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
