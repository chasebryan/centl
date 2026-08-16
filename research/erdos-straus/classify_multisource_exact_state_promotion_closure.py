#!/usr/bin/env python3
"""Re-close the character graph with two-source state-only exact promotion.

This extends the landed 346-state single-source exact-state promotion closure.
A pair transition requires two distinct already-positive source primes whose
route residues realize one of the landed genuine two-source state-only repeller
multisets on the same ancestry-compatible state.
"""
from __future__ import annotations

import argparse
import itertools
import json
from collections import Counter

from classify_branch_aware_character_closure import known_character, legendre_from_residue
from classify_product_character_constraint_closure import State, root_states
from classify_exact_state_promotion_closure import (
    exact_state_branches,
    exact_state_children,
    process_child,
    saturation_children,
)
from classify_multisource_exact_state_repulsion import EXPECTED_STATE_ONLY_PAIRS


def pair_branches() -> dict[int, list[tuple[int, frozenset[tuple[int, int]]]]]:
    by_h: dict[int, list[tuple[int, frozenset[tuple[int, int]]]]] = {}
    for (hard_class, destination, _seed), pairs in EXPECTED_STATE_ONLY_PAIRS.items():
        by_h.setdefault(hard_class, []).append(
            (destination, frozenset(tuple(sorted(pair)) for pair in pairs))
        )
    for rows in by_h.values():
        rows.sort(key=lambda row: row[0])
    return by_h


def route_source_compatible(
    source: int,
    destination: int,
    fixed: dict[int, int],
    source_sign: int,
) -> tuple[bool, int]:
    required = (-destination) % source
    if source in fixed:
        return fixed[source] == required, required
    return legendre_from_residue(required, source) == source_sign, required


def pair_state_children(
    state: State,
    branches: dict[int, list[tuple[int, frozenset[tuple[int, int]]]]],
) -> tuple[list[State], Counter[str], list[dict[str, object]], int]:
    children: list[State] = []
    outcomes: Counter[str] = Counter()
    rows: list[dict[str, object]] = []
    contradictions = 0

    fixed0 = dict(state.fixed)
    characters0 = dict(state.characters)
    positive_sources = sorted(
        q for q, sign in characters0.items() if sign == 1
    )

    for destination, repeller_pairs in branches.get(state.hard_class, []):
        eligible_sources = [q for q in positive_sources if q != destination]
        for q1, q2 in itertools.combinations(eligible_sources, 2):
            residues = tuple(sorted((q1 % destination, q2 % destination)))
            if residues not in repeller_pairs:
                continue

            ok1, required1 = route_source_compatible(
                q1, destination, fixed0, characters0[q1]
            )
            if not ok1:
                continue
            ok2, required2 = route_source_compatible(
                q2, destination, fixed0, characters0[q2]
            )
            if not ok2:
                continue

            fixed = dict(fixed0)
            fixed[q1] = required1
            fixed[q2] = required2
            destination_sign = known_character(
                destination,
                state.hard_class,
                fixed,
                characters0,
            )

            row: dict[str, object] = {
                "hard_class": state.hard_class,
                "source_primes": [q1, q2],
                "destination_k": destination,
                "source_residues_mod_destination": list(residues),
                "required_p_mod_sources": [required1, required2],
            }

            if destination_sign == -1:
                outcomes["sign_hit"] += 1
                contradictions += 1
                row["outcome"] = "sign_hit"
                rows.append(row)
                continue
            if destination_sign == 1:
                outcomes["known_plus"] += 1
                row["outcome"] = "known_plus"
                rows.append(row)
                continue

            characters = dict(characters0)
            characters[destination] = 1
            child, derived, contradiction = process_child(
                state,
                fixed,
                characters,
                list(state.constraints),
            )
            if derived:
                outcomes["constraint_derived"] += derived
            if contradiction:
                outcomes["constraint_hit"] += 1
                contradictions += 1
                row["outcome"] = "constraint_hit"
                rows.append(row)
                continue

            assert child is not None
            children.append(child)
            outcomes["extract"] += 1
            row["outcome"] = "extract"
            rows.append(row)

    return children, outcomes, rows, contradictions


def closure(max_k: int) -> tuple[dict[str, object], frozenset[tuple[object, ...]]]:
    roots = root_states()
    single_branches = exact_state_branches()
    multi_branches = pair_branches()

    seen = {state.key: state for state in roots}
    frontier = roots
    depth_rows: list[dict[str, int]] = []

    saturation_outcomes: Counter[str] = Counter()
    single_outcomes: Counter[str] = Counter()
    pair_outcomes: Counter[str] = Counter()
    saturation_transition_count = 0
    single_transition_count = 0
    pair_transition_count = 0
    hidden_large = 0
    constraint_derived = 0
    contradictions = 0
    saturation_destinations: set[int] = set()
    single_rows: list[dict[str, int]] = []
    pair_rows: list[dict[str, object]] = []
    source_alphabet = {q for state in roots for q, _ in state.characters}

    while frontier:
        new_frontier: list[State] = []
        depth = frontier[0].depth

        for state in frontier:
            sat_children, sat_counts, hidden, derived, destinations = saturation_children(
                state, max_k
            )
            saturation_outcomes.update(sat_counts)
            saturation_transition_count += sum(sat_counts.values())
            hidden_large += hidden
            constraint_derived += derived
            saturation_destinations |= destinations

            one_children, one_counts, one_rows, one_contradictions = exact_state_children(
                state, single_branches
            )
            single_outcomes.update(one_counts)
            single_transition_count += sum(
                one_counts[key]
                for key in ("known_plus", "extract", "sign_hit")
            )
            contradictions += one_contradictions
            single_rows.extend(one_rows)

            two_children, two_counts, two_rows, two_contradictions = pair_state_children(
                state, multi_branches
            )
            pair_outcomes.update(two_counts)
            pair_transition_count += sum(
                two_counts[key]
                for key in ("known_plus", "extract", "sign_hit")
            )
            contradictions += two_contradictions
            pair_rows.extend(two_rows)

            for child in sat_children + one_children + two_children:
                source_alphabet.update(q for q, _ in child.characters)
                if child.key not in seen:
                    seen[child.key] = child
                    new_frontier.append(child)

        depth_rows.append({
            "depth": depth,
            "states_processed": len(frontier),
            "new_states": len(new_frontier),
        })
        frontier = new_frontier
        if depth > 24:
            raise RuntimeError("unexpected non-closure beyond depth 24")

    single_extract_triples = sorted({
        (row["hard_class"], row["source_prime"], row["destination_k"])
        for row in single_rows if row["outcome_code"] == 1
    })
    pair_extract_quads = sorted({
        (
            int(row["hard_class"]),
            tuple(int(q) for q in row["source_primes"]),
            int(row["destination_k"]),
        )
        for row in pair_rows if row["outcome"] == "extract"
    })
    pair_known_quads = sorted({
        (
            int(row["hard_class"]),
            tuple(int(q) for q in row["source_primes"]),
            int(row["destination_k"]),
        )
        for row in pair_rows if row["outcome"] == "known_plus"
    })
    pair_hit_quads = sorted({
        (
            int(row["hard_class"]),
            tuple(int(q) for q in row["source_primes"]),
            int(row["destination_k"]),
        )
        for row in pair_rows if row["outcome"] in {"sign_hit", "constraint_hit"}
    })

    report = {
        "analysis": "multisource-exact-state-augmented-character-closure-v1",
        "max_destination_k": max_k,
        "roots": len(roots),
        "states": len(seen),
        "max_depth": max(state.depth for state in seen.values()),
        "depth_rows": depth_rows,
        "source_alphabet": sorted(source_alphabet),
        "saturation_transition_count": saturation_transition_count,
        "saturation_outcomes": dict(sorted(saturation_outcomes.items())),
        "saturation_qualifying_destinations": sorted(saturation_destinations),
        "single_exact_transition_count": single_transition_count,
        "single_exact_outcomes": dict(sorted(single_outcomes.items())),
        "single_exact_extract_triples": [
            {"hard_class": h, "source_prime": q, "destination_k": k}
            for h, q, k in single_extract_triples
        ],
        "pair_exact_transition_count": pair_transition_count,
        "pair_exact_outcomes": dict(sorted(pair_outcomes.items())),
        "pair_exact_extract_quads": [
            {"hard_class": h, "source_primes": list(qs), "destination_k": k}
            for h, qs, k in pair_extract_quads
        ],
        "pair_exact_known_plus_quads": [
            {"hard_class": h, "source_primes": list(qs), "destination_k": k}
            for h, qs, k in pair_known_quads
        ],
        "pair_exact_contradiction_quads": [
            {"hard_class": h, "source_primes": list(qs), "destination_k": k}
            for h, qs, k in pair_hit_quads
        ],
        "hidden_large_subset_qualifiers": hidden_large,
        "constraint_derived_characters": constraint_derived,
        "exact_state_or_constraint_contradictions": contradictions,
        "claim": (
            "product-aware class-global character recursion re-closed with both single-source "
            "and genuine two-source state-only exact promotion edges"
        ),
        "claim_boundary": (
            "does not yet retain full surviving mask-center states, branch-local q23 semantics, "
            "or residual-gcd/valuation data as active constraints"
        ),
    }
    return report, frozenset(seen)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-k", type=int, default=5000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report, _ = closure(args.max_k)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"states: {report['states']}")
        print(f"max depth: {report['max_depth']}")
        print(f"pair exact outcomes: {report['pair_exact_outcomes']}")
        print(f"pair exact extracts: {report['pair_exact_extract_quads']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
