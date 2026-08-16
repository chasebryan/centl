#!/usr/bin/env python3
"""Independent verification for the two-source exact-state promotion closure.

This verifier does not reimplement the pair-enabled BFS. It pins the reported
frontier against the landed single-source exact-state parent and separately
checks the two realized h169/k19 pair geometries with explicit residue sets.
"""
from __future__ import annotations

import argparse
import json
from collections import deque

from classify_exact_state_promotion_closure import closure as parent_closure
from classify_multisource_exact_state_promotion_closure import closure as pair_closure

EXPECTED_SOURCE_ALPHABET = (
    11, 13, 17, 19, 23, 29, 31, 37, 43, 47, 53, 71, 79, 83, 107,
    109, 127, 131, 151, 167, 191, 251, 271, 383, 971,
)
EXPECTED_DEPTH_ROWS = (
    (0, 8, 28),
    (1, 28, 65),
    (2, 65, 90),
    (3, 90, 90),
    (4, 90, 59),
    (5, 59, 27),
    (6, 27, 12),
    (7, 12, 1),
    (8, 1, 0),
)
EXPECTED_PAIR_EXTRACTS = {
    (169, (17, 23), 19),
    (169, (23, 47), 19),
}


def qrs(k: int) -> frozenset[int]:
    return frozenset(x * x % k for x in range(1, k))


def transition(
    state: tuple[frozenset[int], int], a: int, k: int
) -> tuple[frozenset[int], int]:
    mask, center = state
    local = (1, a % k, a * a % k)
    return (
        frozenset(u * v % k for u in mask for v in local),
        center * a % k,
    )


def closure_explicit(
    start: tuple[frozenset[int], int], k: int
) -> frozenset[tuple[frozenset[int], int]]:
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for a in range(1, k):
            child = transition(state, a, k)
            if child not in seen:
                seen.add(child)
                queue.append(child)
    return frozenset(seen)


def is_miss(state: tuple[frozenset[int], int], k: int) -> bool:
    mask, center = state
    type_i = (-pow(4, -1, k)) % k
    return type_i not in mask and (-center) % k not in mask


def legendre(a: int, q: int) -> int:
    a %= q
    if a == 0:
        return 0
    v = pow(a, (q - 1) // 2, q)
    return -1 if v == q - 1 else 1


def negative_centers(
    states: frozenset[tuple[frozenset[int], int]], k: int
) -> tuple[int, ...]:
    qr = qrs(k)
    return tuple(sorted({
        4 * center % k
        for mask, center in states
        if is_miss((mask, center), k) and 4 * center % k not in qr
    }))


def pair_geometry(r1: int, r2: int) -> dict[str, object]:
    k = 19
    start = (frozenset({1}), 1)
    start = transition(start, r1, k)
    start = transition(start, r2, k)
    states = closure_explicit(start, k)
    misses = tuple(state for state in states if is_miss(state, k))
    centers = tuple(sorted({4 * center % k for _mask, center in misses}))
    assert len(start[0]) == 7
    assert start[0] != qrs(k)
    assert len(states) == 41
    assert len(misses) == 10
    assert centers == (1, 4, 5, 6, 7, 9, 11, 16, 17)
    assert not negative_centers(states, k)
    return {
        "source_residues_mod_19": [r1, r2],
        "starting_mask": sorted(start[0]),
        "starting_mask_size": len(start[0]),
        "qr_size": len(qrs(k)),
        "state_count": len(states),
        "miss_count": len(misses),
        "surviving_centers": list(centers),
        "negative_centers": [],
    }


def source_pairs(keys: frozenset[tuple[object, ...]]) -> set[tuple[int, int]]:
    out = set()
    for key in keys:
        hard_class, _fixed, characters, _constraints = key
        for q, sign in characters:
            if sign == 1:
                out.add((int(hard_class), int(q)))
    return out


def verify_frontier() -> dict[str, object]:
    report, keys = pair_closure(5000)
    parent_report, parent_keys = parent_closure(5000)

    assert parent_report["states"] == 346
    assert report["roots"] == 8
    assert report["states"] == 380
    assert report["max_depth"] == 8
    assert tuple(report["source_alphabet"]) == EXPECTED_SOURCE_ALPHABET
    assert report["source_alphabet"] == parent_report["source_alphabet"]
    assert report["hidden_large_subset_qualifiers"] == 0
    assert report["constraint_derived_characters"] == 0
    assert report["exact_state_or_constraint_contradictions"] == 0

    depth_rows = tuple(
        (int(row["depth"]), int(row["states_processed"]), int(row["new_states"]))
        for row in report["depth_rows"]
    )
    assert depth_rows == EXPECTED_DEPTH_ROWS

    assert report["saturation_transition_count"] == 4142
    assert report["saturation_outcomes"] == {
        "constraint_add": 1,
        "extract": 379,
        "known_plus": 3762,
    }
    assert report["single_exact_transition_count"] == 149
    assert report["single_exact_outcomes"] == {"extract": 23, "known_plus": 126}
    assert report["pair_exact_transition_count"] == 76
    assert report["pair_exact_outcomes"] == {"extract": 18, "known_plus": 58}

    extracts = {
        (
            int(row["hard_class"]),
            tuple(int(q) for q in row["source_primes"]),
            int(row["destination_k"]),
        )
        for row in report["pair_exact_extract_quads"]
    }
    assert extracts == EXPECTED_PAIR_EXTRACTS
    assert not report["pair_exact_contradiction_quads"]

    # The pair mechanism creates new canonical ancestry states, but it does not
    # create a new hard-class/source character pair. That distinction is the
    # main interpretation of the 346 -> 380 expansion.
    assert source_pairs(keys) == source_pairs(parent_keys)

    return {
        "parent_states": parent_report["states"],
        "states": report["states"],
        "added_states": report["states"] - parent_report["states"],
        "max_depth": report["max_depth"],
        "source_alphabet_size": len(report["source_alphabet"]),
        "new_hard_class_source_pairs": [],
        "pair_exact_transition_count": report["pair_exact_transition_count"],
        "pair_exact_extract_events": report["pair_exact_outcomes"]["extract"],
        "distinct_pair_extract_geometries": len(extracts),
    }


def verify_realized_pairs() -> list[dict[str, object]]:
    # h169, q17+q23 -> k19. The exact route residues of p are 15 mod17 and
    # 4 mod23; the incoming source residues modulo19 are 17 and4.
    assert (-19) % 17 == 15
    assert legendre(15, 17) == 1
    assert (-19) % 23 == 4
    assert legendre(4, 23) == 1
    row_a = pair_geometry(4, 17)
    row_a.update({
        "hard_class": 169,
        "source_primes": [17, 23],
        "required_p_mod_sources": [15, 4],
        "destination_k": 19,
    })

    # h169, q23+q47 -> k19. Required p residues are 4 mod23 and28 mod47;
    # incoming source residues modulo19 are4 and9.
    assert (-19) % 47 == 28
    assert legendre(28, 47) == 1
    row_b = pair_geometry(4, 9)
    row_b.update({
        "hard_class": 169,
        "source_primes": [23, 47],
        "required_p_mod_sources": [4, 28],
        "destination_k": 19,
    })

    return [row_a, row_b]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "multisource-exact-state-promotion-independent-v1",
        "frontier_pin": verify_frontier(),
        "realized_pair_geometries": verify_realized_pairs(),
        "failures": 0,
        "claim": (
            "pins the 380-state pair-enabled closure against the landed 346-state parent "
            "and independently checks the two realized h169/k19 state-only pair routes"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
