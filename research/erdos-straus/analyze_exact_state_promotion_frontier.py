#!/usr/bin/env python3
"""Compare exact-state-augmented and parent product-aware character frontiers."""
from __future__ import annotations

import argparse
import json
from collections import Counter

from classify_exact_state_promotion_closure import closure as exact_closure
from classify_product_character_constraint_closure import closure as parent_closure


def source_pairs(keys: frozenset[tuple[object, ...]]) -> set[tuple[int, int]]:
    out = set()
    for key in keys:
        hard_class, _fixed, characters, _constraints = key
        for q, sign in characters:
            if sign == 1:
                out.add((int(hard_class), int(q)))
    return out


def analyze() -> dict[str, object]:
    exact_report, exact_keys = exact_closure(5000)
    parent_report, parent_keys = parent_closure(5000)
    new_pairs = sorted(source_pairs(exact_keys) - source_pairs(parent_keys))

    rows = []
    for hard_class, q in new_pairs:
        supporting = [
            key for key in exact_keys
            if int(key[0]) == hard_class and (q, 1) in key[2]
        ]
        fixed_counter = Counter(tuple(key[1]) for key in supporting)
        shortest_fixed = min(
            fixed_counter,
            key=lambda fixed: (len(fixed), fixed),
        )
        rows.append({
            "hard_class": hard_class,
            "source_prime": q,
            "states_containing_source": len(supporting),
            "minimum_fixed_residue_count": len(shortest_fixed),
            "example_minimal_fixed_residues": [list(item) for item in shortest_fixed],
        })

    return {
        "analysis": "exact-state-promotion-frontier-diff-v1",
        "parent_states": parent_report["states"],
        "exact_state_augmented_states": exact_report["states"],
        "parent_source_alphabet": parent_report["source_alphabet"],
        "exact_state_source_alphabet": exact_report["source_alphabet"],
        "new_hard_class_source_pairs": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
