#!/usr/bin/env python3
"""Independent arithmetic anchors for the exact-state promotion closure.

This verifier does not reimplement the 346-state BFS. It independently checks
(1) the three state-only k=47 promotion geometries, (2) the exact frontier
reported by the classifier, and (3) the two new downstream prime-saturation
promotions q79 and q251 that appear only after exact-state feedback.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import deque

from classify_exact_state_promotion_closure import closure as exact_closure
from classify_product_character_constraint_closure import closure as parent_closure

EXPECTED_SOURCE_ALPHABET = (
    11, 13, 17, 19, 23, 29, 31, 37, 43, 47, 53, 71, 79, 83, 107,
    109, 127, 131, 151, 167, 191, 251, 271, 383, 971,
)
EXPECTED_DEPTH_ROWS = (
    (0, 8, 28),
    (1, 28, 64),
    (2, 64, 84),
    (3, 84, 76),
    (4, 76, 47),
    (5, 47, 26),
    (6, 26, 12),
    (7, 12, 1),
    (8, 1, 0),
)
EXPECTED_EXACT_TRIPLES = {
    (169, 17, 47),
    (169, 37, 47),
    (529, 17, 47),
}
EXPECTED_NEW_CLASS_SOURCE_PAIRS = {
    (169, 79),
    (169, 251),
    (529, 47),
}


def factorization(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    q = 2
    x = n
    while q * q <= x:
        while x % q == 0:
            out[q] = out.get(q, 0) + 1
            x //= q
        q += 1 if q == 2 else 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisor_square_residues(seed: int, k: int) -> frozenset[int]:
    residues = {1}
    for q, exponent in factorization(seed).items():
        powers = [pow(q, j, k) for j in range(2 * exponent + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return frozenset(residues)


def qrs(k: int) -> frozenset[int]:
    return frozenset(x * x % k for x in range(1, k))


def saturates(seed: int, k: int) -> bool:
    return divisor_square_residues(seed, k) == qrs(k)


def transition(
    state: tuple[frozenset[int], int], a: int, k: int
) -> tuple[frozenset[int], int]:
    mask, center = state
    local = (1, a % k, a * a % k)
    return (
        frozenset(u * v % k for u in mask for v in local),
        center * a % k,
    )


def seed_state(seed: int, k: int) -> tuple[frozenset[int], int]:
    state = (frozenset({1}), 1)
    for q, exponent in factorization(seed).items():
        for _ in range(exponent):
            state = transition(state, q, k)
    return state


def explicit_closure(
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


def negative_miss_centers(
    states: frozenset[tuple[frozenset[int], int]], k: int
) -> tuple[int, ...]:
    qr = qrs(k)
    return tuple(sorted({
        4 * center % k
        for mask, center in states
        if is_miss((mask, center), k) and 4 * center % k not in qr
    }))


def verify_k47_state_only_promotions() -> dict[str, object]:
    k = 47
    seed = 6
    base = seed_state(seed, k)
    ordinary = explicit_closure(base, k)
    ordinary_misses = sum(is_miss(state, k) for state in ordinary)
    ordinary_negative = negative_miss_centers(ordinary, k)

    assert len(ordinary) == 1079
    assert ordinary_misses == 196
    assert ordinary_negative == (5, 10, 13, 19, 20, 26, 29, 30, 33, 38, 40)

    rows = []
    for source_q, required_p_mod_q in ((17, 4), (37, 27)):
        r = source_q % k
        assert r in {17, 37}
        assert (-k) % source_q == required_p_mod_q
        assert legendre(required_p_mod_q, source_q) == 1

        augmented_start = transition(base, r, k)
        augmented = explicit_closure(augmented_start, k)
        misses = tuple(state for state in augmented if is_miss(state, k))
        negative = negative_miss_centers(augmented, k)

        assert len(augmented) == 97
        assert len(misses) == 24
        assert len({4 * center % k for _mask, center in misses}) == 23
        assert not negative
        assert augmented_start[0] != qrs(k)  # genuinely state-only, not QR saturation
        assert len(augmented_start[0]) == 21

        rows.append({
            "source_prime": source_q,
            "source_mod_47": r,
            "required_p_mod_source": required_p_mod_q,
            "augmented_states": len(augmented),
            "augmented_misses": len(misses),
            "surviving_centers": 23,
            "negative_centers": 0,
            "qr_saturates": False,
        })

    return {
        "ordinary_states": len(ordinary),
        "ordinary_misses": ordinary_misses,
        "ordinary_negative_centers": list(ordinary_negative),
        "state_only_source_rows": rows,
    }


def verify_new_downstream_promotions() -> list[dict[str, object]]:
    rows = []

    # h=169, prime destination k=79. Exact-state feedback produces an
    # ancestry-compatible state in which q11, q31 and q167 all take the
    # k79 route. The class seed is 2 and all three routed factors are required
    # for QR saturation.
    h = 169
    k = 79
    sources = (11, 31, 167)
    residues = (9, 14, 88)
    base = math.gcd(210, (h + k) // 4)
    assert base == 2
    for q, r in zip(sources, residues):
        assert (-k) % q == r
        assert legendre(r, q) == 1
    full_seed = math.lcm(base, *sources)
    assert saturates(full_seed, k)
    for size in range(1, len(sources)):
        for subset in itertools.combinations(sources, size):
            assert not saturates(math.lcm(base, *subset), k)
    rows.append({
        "hard_class": h,
        "destination_k": k,
        "extracted_prime": 79,
        "base_seed": base,
        "source_primes": list(sources),
        "required_source_residues": list(residues),
        "combined_seed": full_seed,
        "proper_subsets_saturate": False,
    })

    # h=169, prime destination k=251. The new compatible q13/q17 route pair
    # is a genuine two-source saturation from class seed105.
    k = 251
    sources = (13, 17)
    residues = (9, 4)
    base = math.gcd(210, (h + k) // 4)
    assert base == 105
    for q, r in zip(sources, residues):
        assert (-k) % q == r
        assert legendre(r, q) == 1
    full_seed = math.lcm(base, *sources)
    assert saturates(full_seed, k)
    assert not saturates(math.lcm(base, 13), k)
    assert not saturates(math.lcm(base, 17), k)
    rows.append({
        "hard_class": h,
        "destination_k": k,
        "extracted_prime": 251,
        "base_seed": base,
        "source_primes": list(sources),
        "required_source_residues": list(residues),
        "combined_seed": full_seed,
        "proper_subsets_saturate": False,
    })

    # h=529 q47 is created directly by the state-only q17 -> k47 route.
    assert (-47) % 17 == 4
    assert legendre(4, 17) == 1
    rows.append({
        "hard_class": 529,
        "destination_k": 47,
        "extracted_prime": 47,
        "source_primes": [17],
        "required_source_residues": [4],
        "mechanism": "state-only exact repulsion",
    })

    return rows


def source_pairs(keys: frozenset[tuple[object, ...]]) -> set[tuple[int, int]]:
    out = set()
    for key in keys:
        hard_class, _fixed, characters, _constraints = key
        for q, sign in characters:
            if sign == 1:
                out.add((int(hard_class), int(q)))
    return out


def verify_frontier_pin() -> dict[str, object]:
    report, keys = exact_closure(5000)
    parent_report, parent_keys = parent_closure(5000)

    assert report["roots"] == 8
    assert report["states"] == 346
    assert report["max_depth"] == 8
    assert tuple(report["source_alphabet"]) == EXPECTED_SOURCE_ALPHABET
    assert report["saturation_transition_count"] == 3775
    assert report["saturation_outcomes"] == {
        "constraint_add": 1,
        "extract": 359,
        "known_plus": 3415,
    }
    assert report["exact_state_transition_count"] == 119
    assert report["exact_state_outcomes"] == {"extract": 23, "known_plus": 96}
    assert report["hidden_large_subset_qualifiers"] == 0
    assert report["constraint_derived_characters"] == 0
    assert report["exact_state_or_constraint_contradictions"] == 0

    depth_rows = tuple(
        (int(row["depth"]), int(row["states_processed"]), int(row["new_states"]))
        for row in report["depth_rows"]
    )
    assert depth_rows == EXPECTED_DEPTH_ROWS

    exact_triples = {
        (int(row["hard_class"]), int(row["source_prime"]), int(row["destination_k"]))
        for row in report["exact_state_extract_triples"]
    }
    assert exact_triples == EXPECTED_EXACT_TRIPLES

    new_pairs = source_pairs(keys) - source_pairs(parent_keys)
    assert new_pairs == EXPECTED_NEW_CLASS_SOURCE_PAIRS
    assert parent_report["states"] == 260

    return {
        "parent_states": parent_report["states"],
        "states": report["states"],
        "max_depth": report["max_depth"],
        "exact_state_transition_count": report["exact_state_transition_count"],
        "exact_state_extract_events": report["exact_state_outcomes"]["extract"],
        "exact_state_distinct_extract_triples": len(exact_triples),
        "new_hard_class_source_pairs": [list(row) for row in sorted(new_pairs)],
        "source_alphabet_size": len(report["source_alphabet"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "exact-state-promotion-closure-independent-verification-v1",
        "frontier_pin": verify_frontier_pin(),
        "k47_state_only_geometry": verify_k47_state_only_promotions(),
        "new_downstream_promotions": verify_new_downstream_promotions(),
        "failures": 0,
        "claim": (
            "pins the exact finite closure and independently checks the local state-only "
            "k47 arithmetic plus the new q79/q251 downstream saturation mechanisms"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
