#!/usr/bin/env python3
"""Re-close the product-aware character graph with exact-state promotion edges.

The landed product-aware closure can create characters only through complete
QR/Jacobi saturation. EXACT-STATE-INCOMING-REPULSION proves additional
single-source routes where all negative fixed-shift centers disappear without
full saturation. Such a destination miss still forces a positive destination
character. This classifier feeds those new characters back into the recursive
character graph while preserving route residues and product constraints.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter

from classify_branch_aware_character_closure import (
    State as BaseState,
    known_character,
    legendre_from_residue,
    qualifying_transitions,
)
from classify_product_character_constraint_closure import (
    State,
    canonicalize_constraints,
    reclassify_transition,
    root_states,
)
from classify_exact_state_incoming_repulsion import EXPECTED_STATE_ONLY


def exact_state_branches() -> dict[int, list[tuple[int, frozenset[int]]]]:
    by_h: dict[int, list[tuple[int, frozenset[int]]]] = {}
    for (hard_class, destination, _seed), residues in EXPECTED_STATE_ONLY.items():
        by_h.setdefault(hard_class, []).append((destination, frozenset(residues)))
    for rows in by_h.values():
        rows.sort()
    return by_h


def process_child(
    state: State,
    fixed: dict[int, int],
    characters: dict[int, int],
    equations: list[tuple[tuple[int, ...], int]],
) -> tuple[State | None, int, bool]:
    characters, constraints, contradiction, derived = canonicalize_constraints(
        characters, equations
    )
    if contradiction:
        return None, derived, True
    return (
        State(
            hard_class=state.hard_class,
            fixed=tuple(sorted(fixed.items())),
            characters=tuple(sorted(characters.items())),
            constraints=constraints,
            depth=state.depth + 1,
        ),
        derived,
        False,
    )


def saturation_children(
    state: State,
    max_k: int,
) -> tuple[list[State], Counter[str], int, int, set[int]]:
    base_state = BaseState(
        hard_class=state.hard_class,
        fixed=state.fixed,
        characters=state.characters,
        depth=state.depth,
    )
    rows, hidden = qualifying_transitions(base_state, max_k)
    children: list[State] = []
    outcomes: Counter[str] = Counter()
    constraint_derived = 0
    contradictions = 0
    destinations: set[int] = set()

    for row in rows:
        destinations.add(int(row["k"]))
        outcome, value = reclassify_transition(state, row)
        outcomes[outcome] += 1
        if outcome in {"type_i_hit", "sign_hit", "known_plus"}:
            continue

        characters = dict(state.characters)
        equations = list(state.constraints)
        fixed = dict(row["fixed"])

        if outcome == "extract":
            q, sign = value  # type: ignore[misc]
            q = int(q)
            sign = int(sign)
            prior = characters.get(q)
            if prior is not None and prior != sign:
                contradictions += 1
                continue
            characters[q] = sign
        elif outcome == "constraint_add":
            variables, rhs = value  # type: ignore[misc]
            equations.append((tuple(int(q) for q in variables), int(rhs)))
        else:
            raise RuntimeError(outcome)

        child, derived, contradiction = process_child(
            state, fixed, characters, equations
        )
        constraint_derived += derived
        if contradiction:
            contradictions += 1
            continue
        assert child is not None
        children.append(child)

    return children, outcomes, hidden, constraint_derived, destinations


def exact_state_children(
    state: State,
    branches: dict[int, list[tuple[int, frozenset[int]]]],
) -> tuple[list[State], Counter[str], list[dict[str, int]], int]:
    children: list[State] = []
    outcomes: Counter[str] = Counter()
    rows: list[dict[str, int]] = []
    contradictions = 0
    fixed0 = dict(state.fixed)
    characters0 = dict(state.characters)

    for destination, repellers in branches.get(state.hard_class, []):
        for source, source_sign in characters0.items():
            if source_sign != 1 or source == destination:
                continue
            source_residue = source % destination
            if source_residue not in repellers:
                continue

            required = (-destination) % source
            if source in fixed0:
                if fixed0[source] != required:
                    continue
            elif legendre_from_residue(required, source) != source_sign:
                continue

            fixed = dict(fixed0)
            fixed[source] = required
            destination_sign = known_character(
                destination,
                state.hard_class,
                fixed,
                characters0,
            )

            row = {
                "hard_class": state.hard_class,
                "source_prime": source,
                "destination_k": destination,
                "source_mod_destination": source_residue,
                "required_p_mod_source": required,
            }

            if destination_sign == -1:
                outcomes["sign_hit"] += 1
                contradictions += 1
                rows.append({**row, "outcome_code": -1})
                continue
            if destination_sign == 1:
                outcomes["known_plus"] += 1
                rows.append({**row, "outcome_code": 0})
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
                rows.append({**row, "outcome_code": -2})
                continue
            assert child is not None
            children.append(child)
            outcomes["extract"] += 1
            rows.append({**row, "outcome_code": 1})

    return children, outcomes, rows, contradictions


def closure(max_k: int) -> tuple[dict[str, object], frozenset[tuple[object, ...]]]:
    roots = root_states()
    branches = exact_state_branches()
    seen = {state.key: state for state in roots}
    frontier = roots
    depth_rows: list[dict[str, int]] = []
    saturation_outcomes: Counter[str] = Counter()
    exact_outcomes: Counter[str] = Counter()
    saturation_transition_count = 0
    exact_transition_count = 0
    hidden_large = 0
    constraint_derived = 0
    contradictions = 0
    saturation_destinations: set[int] = set()
    exact_rows: list[dict[str, int]] = []
    source_alphabet = {q for state in roots for q, _ in state.characters}

    while frontier:
        new_frontier: list[State] = []
        depth = frontier[0].depth

        for state in frontier:
            sat_children, sat_outcomes, hidden, derived, destinations = saturation_children(
                state, max_k
            )
            hidden_large += hidden
            constraint_derived += derived
            saturation_destinations |= destinations
            saturation_outcomes.update(sat_outcomes)
            saturation_transition_count += sum(sat_outcomes.values())

            exact_children, exact_counts, state_rows, exact_contradictions = exact_state_children(
                state, branches
            )
            exact_outcomes.update(exact_counts)
            exact_transition_count += sum(
                exact_counts[key] for key in ("known_plus", "extract", "sign_hit")
            )
            contradictions += exact_contradictions
            exact_rows.extend(state_rows)

            for child in sat_children + exact_children:
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
        if depth > 20:
            raise RuntimeError("unexpected non-closure beyond depth 20")

    exact_extract_triples = sorted({
        (row["hard_class"], row["source_prime"], row["destination_k"])
        for row in exact_rows if row["outcome_code"] == 1
    })
    exact_known_triples = sorted({
        (row["hard_class"], row["source_prime"], row["destination_k"])
        for row in exact_rows if row["outcome_code"] == 0
    })
    exact_hit_triples = sorted({
        (row["hard_class"], row["source_prime"], row["destination_k"])
        for row in exact_rows if row["outcome_code"] < 0
    })

    report = {
        "analysis": "exact-state-augmented-character-closure-v1",
        "max_destination_k": max_k,
        "roots": len(roots),
        "states": len(seen),
        "max_depth": max(state.depth for state in seen.values()),
        "depth_rows": depth_rows,
        "source_alphabet": sorted(source_alphabet),
        "saturation_transition_count": saturation_transition_count,
        "saturation_outcomes": dict(sorted(saturation_outcomes.items())),
        "saturation_qualifying_destinations": sorted(saturation_destinations),
        "exact_state_transition_count": exact_transition_count,
        "exact_state_outcomes": dict(sorted(exact_outcomes.items())),
        "exact_state_extract_triples": [
            {"hard_class": h, "source_prime": q, "destination_k": k}
            for h, q, k in exact_extract_triples
        ],
        "exact_state_known_plus_triples": [
            {"hard_class": h, "source_prime": q, "destination_k": k}
            for h, q, k in exact_known_triples
        ],
        "exact_state_contradiction_triples": [
            {"hard_class": h, "source_prime": q, "destination_k": k}
            for h, q, k in exact_hit_triples
        ],
        "hidden_large_subset_qualifiers": hidden_large,
        "constraint_derived_characters": constraint_derived,
        "exact_state_or_constraint_contradictions": contradictions,
        "claim": (
            "product-aware class-global character recursion re-closed with single-source "
            "state-only exact-mask promotion edges from the landed small-prime atlas"
        ),
        "claim_boundary": (
            "does not yet retain full surviving mask-center states, branch-local q23 semantics, "
            "or multi-source state-only exact repulsion"
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
        print(f"source alphabet: {report['source_alphabet']}")
        print(f"exact extracts: {report['exact_state_extract_triples']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
