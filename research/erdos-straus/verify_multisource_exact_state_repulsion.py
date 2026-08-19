#!/usr/bin/env python3
"""Independent explicit-set verification for two-source state-only repulsion."""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import deque

FLAGSHIP_PAIRS = (
    (4, 9), (4, 16), (4, 17), (5, 6), (5, 16),
    (6, 9), (6, 16), (6, 17), (16, 17), (17, 17),
)


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


def seed_state(seed: int, k: int) -> tuple[frozenset[int], int]:
    state = (frozenset({1}), 1)
    for q, exponent in factorization(seed).items():
        for _ in range(exponent):
            state = transition(state, q, k)
    return state


def closure(
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


def negative_centers(
    states: frozenset[tuple[frozenset[int], int]], k: int
) -> tuple[int, ...]:
    qr = qrs(k)
    return tuple(sorted({
        4 * center % k
        for mask, center in states
        if is_miss((mask, center), k) and 4 * center % k not in qr
    }))


def single_repels(seed: int, k: int, r: int) -> bool:
    start = transition(seed_state(seed, k), r, k)
    return not negative_centers(closure(start, k), k)


def pair_row(seed: int, k: int, r1: int, r2: int) -> dict[str, object]:
    base = seed_state(seed, k)
    start = transition(transition(base, r1, k), r2, k)
    states = closure(start, k)
    misses = tuple(state for state in states if is_miss(state, k))
    neg = negative_centers(states, k)
    return {
        "pair": [r1, r2],
        "mask_size": len(start[0]),
        "qr_size": len(qrs(k)),
        "state_count": len(states),
        "miss_count": len(misses),
        "center_count": len({4 * center % k for _mask, center in misses}),
        "negative_centers": list(neg),
        "qr_saturates": start[0] == qrs(k),
    }


def verify_flagship_k19() -> dict[str, object]:
    k = 19
    seed = 1
    base_states = closure(seed_state(seed, k), k)
    assert len(base_states) == 439
    assert sum(is_miss(state, k) for state in base_states) == 136
    assert negative_centers(base_states, k) == (2, 3, 8, 10, 12, 13, 14)

    qr = sorted(qrs(k))
    single_exact = {r for r in qr if single_repels(seed, k, r)}
    assert single_exact == set()

    found = []
    details = []
    for r1, r2 in itertools.combinations_with_replacement(qr, 2):
        row = pair_row(seed, k, r1, r2)
        if not row["negative_centers"] and not row["qr_saturates"]:
            found.append((r1, r2))
            details.append(row)

    assert tuple(found) == FLAGSHIP_PAIRS
    assert all(row["center_count"] == 9 for row in details)
    assert {int(row["state_count"]) for row in details} == {41, 70}
    assert {int(row["miss_count"]) for row in details} == {10, 12}
    assert {int(row["mask_size"]) for row in details} == {5, 7}

    # The exact geometry depends only on the h169/h529 class seed, which is 1
    # on both branches. Thus the same ten pair types resolve both of the two
    # single-source no-repeller exceptions from the landed theorem.
    return {
        "hard_classes": [169, 529],
        "destination_k": 19,
        "base_seed": 1,
        "ordinary_states": 439,
        "ordinary_misses": 136,
        "ordinary_negative_centers": [2, 3, 8, 10, 12, 13, 14],
        "single_source_exact_repellers": [],
        "genuine_state_only_pair_types": [list(pair) for pair in found],
        "pair_details": details,
    }


def verify_representative_controls() -> list[dict[str, object]]:
    controls = []

    # k31/seed2: (7,18) is a genuine pair-only state repeller.
    assert not single_repels(2, 31, 7)
    assert not single_repels(2, 31, 18)
    row = pair_row(2, 31, 7, 18)
    assert not row["negative_centers"]
    assert not row["qr_saturates"]
    assert row["state_count"] == 65
    assert row["miss_count"] == 16
    controls.append({"destination_k": 31, "base_seed": 2, **row})

    # k47/seed6: (2,3) is likewise pair-only and state-only.
    assert not single_repels(6, 47, 2)
    assert not single_repels(6, 47, 3)
    row = pair_row(6, 47, 2, 3)
    assert not row["negative_centers"]
    assert not row["qr_saturates"]
    assert row["state_count"] == 97
    assert row["miss_count"] == 24
    controls.append({"destination_k": 47, "base_seed": 6, **row})

    # Negative control at flagship k19: (4,5) remains non-repelling.
    row = pair_row(1, 19, 4, 5)
    assert row["negative_centers"]
    controls.append({"destination_k": 19, "base_seed": 1, "negative_control": True, **row})

    return controls


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "multisource-exact-state-repulsion-independent-v1",
        "flagship": verify_flagship_k19(),
        "representative_controls": verify_representative_controls(),
        "failures": 0,
        "claim": (
            "explicit frozenset state verification that the former h169/h529 k19 "
            "single-source exceptions admit exactly ten genuine two-source state-only "
            "repeller residue multisets, with representative k31/k47 controls"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
