#!/usr/bin/env python3
"""Propagate multi-character equations through the landed branch-aware closure.

The parent theorem records the lone saturated product relation at k=551 but does
not carry it into child states. This follow-on represents character signs as
GF(2) bits, stores unresolved product equations in a canonical row basis, and
uses them when later saturated destinations query the same character products.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter
from dataclasses import dataclass

from classify_branch_aware_character_closure import (
    EXPECTED_DESTINATIONS,
    EXPECTED_SOURCE_ALPHABET,
    State as BaseState,
    divisor_square_residues,
    factorization,
    jacobi_kernel,
    known_character,
    qualifying_transitions,
    root_states as base_root_states,
)

EXPECTED = {
    "roots": 8,
    "states": 260,
    "transitions": 2826,
    "known_plus": 2541,
    "extract": 284,
    "constraint_add": 1,
    "type_i_hit": 0,
    "sign_hit": 0,
    "constraint_derived_characters": 0,
    "constraint_contradictions": 0,
    "constraint_states": 1,
    "max_depth": 7,
    "hidden_large_subset_qualifiers": 0,
}

EXPECTED_DEPTH_ROWS = (
    (0, 8, 25),
    (1, 25, 56),
    (2, 56, 62),
    (3, 62, 47),
    (4, 47, 29),
    (5, 29, 23),
    (6, 23, 10),
    (7, 10, 0),
)

EXPECTED_CONSTRAINT_STATE = {
    "hard_class": 289,
    "fixed": ((11, 5), (13, 3), (23, 1), (31, 7), (47, 8)),
    "characters": ((11, 1), (13, 1), (23, 1), (31, 1), (47, 1)),
    "constraints": (((19, 29), 0),),
    "depth": 2,
}


@dataclass(frozen=True)
class State:
    hard_class: int
    fixed: tuple[tuple[int, int], ...]
    characters: tuple[tuple[int, int], ...]
    constraints: tuple[tuple[tuple[int, ...], int], ...]
    depth: int

    @property
    def key(self) -> tuple[object, ...]:
        return self.hard_class, self.fixed, self.characters, self.constraints


def sign_to_bit(sign: int) -> int:
    if sign == 1:
        return 0
    if sign == -1:
        return 1
    raise ValueError(sign)


def bit_to_sign(bit: int) -> int:
    return -1 if bit & 1 else 1


def canonicalize_constraints(
    characters: dict[int, int],
    equations: list[tuple[tuple[int, ...], int]],
) -> tuple[dict[int, int], tuple[tuple[tuple[int, ...], int], ...], bool, int]:
    """Gaussian-eliminate character product equations over GF(2).

    A sign character is represented by x_q=0 for +1 and x_q=1 for -1.
    An equation ((q1,...,qn), rhs) means xor(x_qi)=rhs.

    Returns updated characters, canonical unresolved basis, contradiction flag,
    and the number of individual characters derived from equations.
    """
    chars = dict(characters)
    work = [(set(vars_), int(rhs) & 1) for vars_, rhs in equations]
    derived = 0

    while True:
        substituted: list[tuple[set[int], int]] = []
        for variables, rhs in work:
            variables = set(variables)
            for q in list(variables):
                if q in chars:
                    rhs ^= sign_to_bit(chars[q])
                    variables.remove(q)
            substituted.append((variables, rhs))

        basis: dict[int, tuple[set[int], int]] = {}
        for variables, rhs in substituted:
            variables = set(variables)
            while variables:
                pivot = min(variables)
                if pivot not in basis:
                    basis[pivot] = (variables, rhs)
                    break
                row, row_rhs = basis[pivot]
                variables ^= row
                rhs ^= row_rhs
            else:
                if rhs:
                    return chars, (), True, derived

        pivots = sorted(basis)
        for pivot in reversed(pivots):
            row, row_rhs = basis[pivot]
            for smaller in pivots:
                if smaller >= pivot:
                    continue
                other, other_rhs = basis[smaller]
                if pivot in other:
                    basis[smaller] = (other ^ row, other_rhs ^ row_rhs)

        new_character = False
        for _, (variables, rhs) in basis.items():
            if len(variables) != 1:
                continue
            q = next(iter(variables))
            sign = bit_to_sign(rhs)
            prior = chars.get(q)
            if prior is not None and prior != sign:
                return chars, (), True, derived
            if prior is None:
                chars[q] = sign
                derived += 1
                new_character = True

        if not new_character:
            canonical = tuple(sorted(
                (tuple(sorted(variables)), rhs)
                for _, (variables, rhs) in basis.items()
                if len(variables) > 1
            ))
            return chars, canonical, False, derived

        work = [
            (tuple(sorted(variables)), rhs)
            for _, (variables, rhs) in basis.items()
            if len(variables) > 1
        ]


def implied_bit(
    variables: list[int],
    constraints: tuple[tuple[tuple[int, ...], int], ...],
) -> int | None:
    """Return the forced xor bit for variables if the basis determines it."""
    vector = set(variables)
    rhs = 0
    for row_vars, row_rhs in sorted(constraints, key=lambda row: row[0][0]):
        pivot = row_vars[0]
        if pivot in vector:
            vector ^= set(row_vars)
            rhs ^= row_rhs
    return rhs if not vector else None


def root_states() -> list[State]:
    return [
        State(
            hard_class=state.hard_class,
            fixed=state.fixed,
            characters=state.characters,
            constraints=(),
            depth=0,
        )
        for state in base_root_states()
    ]


def reclassify_transition(
    state: State,
    row: dict[str, object],
) -> tuple[str, object | None]:
    if row["outcome"] == "type_i_hit":
        return "type_i_hit", None

    k = int(row["k"])
    seed = int(row["seed"])
    fixed = dict(row["fixed"])
    characters = dict(state.characters)

    residues = divisor_square_residues(seed, k)
    if residues != jacobi_kernel(k):
        raise RuntimeError(f"qualifying row is not saturated at k={k}, seed={seed}")

    known_bit = 0
    unknown: list[int] = []
    for q, exponent in factorization(k):
        if exponent % 2 == 0:
            continue
        sign = known_character(q, state.hard_class, fixed, characters)
        if sign is None:
            unknown.append(q)
        else:
            known_bit ^= sign_to_bit(sign)

    if not unknown:
        return ("known_plus", None) if known_bit == 0 else ("sign_hit", None)

    forced = implied_bit(unknown, state.constraints)
    if forced is not None:
        return ("known_plus", None) if forced == known_bit else ("sign_hit", None)

    if len(unknown) == 1:
        return "extract", (unknown[0], bit_to_sign(known_bit))

    return "constraint_add", (tuple(unknown), known_bit)


def closure(max_k: int) -> tuple[dict[str, object], frozenset[tuple[object, ...]]]:
    roots = root_states()
    seen = {state.key: state for state in roots}
    frontier = roots
    outcome_counts: Counter[str] = Counter()
    transition_count = 0
    hidden_large = 0
    destinations: set[int] = set()
    source_alphabet = {q for state in roots for q, _ in state.characters}
    depth_rows: list[dict[str, int]] = []
    constraint_derived = 0
    constraint_contradictions = 0

    while frontier:
        new_frontier: list[State] = []
        depth = frontier[0].depth

        for state in frontier:
            base_state = BaseState(
                hard_class=state.hard_class,
                fixed=state.fixed,
                characters=state.characters,
                depth=state.depth,
            )
            rows, hidden = qualifying_transitions(base_state, max_k)
            hidden_large += hidden

            for row in rows:
                transition_count += 1
                destinations.add(int(row["k"]))
                outcome, value = reclassify_transition(state, row)
                outcome_counts[outcome] += 1

                if outcome in {"type_i_hit", "sign_hit", "known_plus"}:
                    continue

                characters = dict(state.characters)
                equations = list(state.constraints)

                if outcome == "extract":
                    q, sign = value  # type: ignore[misc]
                    q = int(q)
                    sign = int(sign)
                    prior = characters.get(q)
                    if prior is not None and prior != sign:
                        constraint_contradictions += 1
                        continue
                    characters[q] = sign
                elif outcome == "constraint_add":
                    variables, rhs = value  # type: ignore[misc]
                    equations.append((tuple(int(q) for q in variables), int(rhs)))
                else:
                    raise RuntimeError(outcome)

                characters, constraints, contradiction, derived = canonicalize_constraints(
                    characters, equations
                )
                constraint_derived += derived
                if contradiction:
                    constraint_contradictions += 1
                    continue

                source_alphabet.update(characters)
                child = State(
                    hard_class=state.hard_class,
                    fixed=tuple(row["fixed"]),
                    characters=tuple(sorted(characters.items())),
                    constraints=constraints,
                    depth=state.depth + 1,
                )
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

    constraint_states = [state for state in seen.values() if state.constraints]
    report = {
        "analysis": "product-character-constraint-closure-v1",
        "max_destination_k": max_k,
        "roots": len(roots),
        "states": len(seen),
        "transitions": transition_count,
        "outcomes": dict(sorted(outcome_counts.items())),
        "constraint_derived_characters": constraint_derived,
        "constraint_contradictions": constraint_contradictions,
        "constraint_states": len(constraint_states),
        "constraint_state_rows": [
            {
                "hard_class": state.hard_class,
                "fixed": [list(item) for item in state.fixed],
                "characters": [list(item) for item in state.characters],
                "constraints": [
                    {"primes": list(primes), "rhs_bit": rhs, "forced_product": bit_to_sign(rhs)}
                    for primes, rhs in state.constraints
                ],
                "depth": state.depth,
            }
            for state in constraint_states
        ],
        "max_depth": max(state.depth for state in seen.values()),
        "depth_rows": depth_rows,
        "source_alphabet": sorted(source_alphabet),
        "qualifying_destinations": sorted(destinations),
        "hidden_large_subset_qualifiers": hidden_large,
        "claim": (
            "the lone multi-character saturated relation is carried as a canonical GF(2) "
            "state constraint; it creates one additional state but no individual character "
            "and no contradiction in the class-global-positive closure"
        ),
        "claim_boundary": (
            "product-aware closure of the landed class-global-positive model only; does not "
            "subsume branch-local source refinements or exact miss/valuation geometry"
        ),
    }
    return report, frozenset(seen)


def assert_expected(report: dict[str, object]) -> None:
    outcomes = report["outcomes"]
    actual = {
        "roots": report["roots"],
        "states": report["states"],
        "transitions": report["transitions"],
        "known_plus": outcomes.get("known_plus", 0),
        "extract": outcomes.get("extract", 0),
        "constraint_add": outcomes.get("constraint_add", 0),
        "type_i_hit": outcomes.get("type_i_hit", 0),
        "sign_hit": outcomes.get("sign_hit", 0),
        "constraint_derived_characters": report["constraint_derived_characters"],
        "constraint_contradictions": report["constraint_contradictions"],
        "constraint_states": report["constraint_states"],
        "max_depth": report["max_depth"],
        "hidden_large_subset_qualifiers": report["hidden_large_subset_qualifiers"],
    }
    if actual != EXPECTED:
        raise SystemExit(f"product-aware frontier changed: {actual!r}")
    if set(report["source_alphabet"]) != EXPECTED_SOURCE_ALPHABET:
        raise SystemExit(f"source alphabet changed: {report['source_alphabet']!r}")
    if set(report["qualifying_destinations"]) != EXPECTED_DESTINATIONS:
        raise SystemExit(
            f"qualifying destinations changed: {report['qualifying_destinations']!r}"
        )
    depth_rows = tuple(
        (int(row["depth"]), int(row["states_processed"]), int(row["new_states"]))
        for row in report["depth_rows"]
    )
    if depth_rows != EXPECTED_DEPTH_ROWS:
        raise SystemExit(f"depth profile changed: {depth_rows!r}")

    rows = report["constraint_state_rows"]
    if len(rows) != 1:
        raise SystemExit(f"constraint state count changed: {len(rows)}")
    row = rows[0]
    pinned = {
        "hard_class": row["hard_class"],
        "fixed": tuple(tuple(item) for item in row["fixed"]),
        "characters": tuple(tuple(item) for item in row["characters"]),
        "constraints": tuple(
            (tuple(item["primes"]), int(item["rhs_bit"]))
            for item in row["constraints"]
        ),
        "depth": row["depth"],
    }
    if pinned != EXPECTED_CONSTRAINT_STATE:
        raise SystemExit(f"constraint state changed: {pinned!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-k", type=int, default=5000)
    parser.add_argument("--assert-frontier", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report, state_keys = closure(args.max_k)
    if args.assert_frontier:
        if args.max_k != 5000:
            raise SystemExit("--assert-frontier is pinned to --max-k 5000")
        assert_expected(report)
        short_report, short_keys = closure(1000)
        if short_keys != state_keys:
            raise SystemExit(
                f"k<=1000 and k<=5000 product-aware state closures differ: "
                f"{len(short_keys)} vs {len(state_keys)}"
            )
        if short_report["source_alphabet"] != report["source_alphabet"]:
            raise SystemExit("k<=1000 and k<=5000 source alphabets differ")

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"states: {report['states']}")
        print(f"transitions: {report['transitions']}")
        print(f"constraint states: {report['constraint_states']}")
        print(f"constraint-derived characters: {report['constraint_derived_characters']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
