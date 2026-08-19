#!/usr/bin/env python3
"""Independent set-state verification of incoming repulsion beyond saturation.

The primary classifier uses integer bitmasks. This verifier uses explicit
frozensets of divisor residues and independently rebuilds the exact closures for
the four seed geometries that contain genuinely state-only repellers.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

EXPECTED = {
    (19, 5): {
        "base_misses": 44,
        "negative_centers": (2, 3, 8, 10, 12, 13),
        "state_only": {6: (10, 9), 16: (10, 9)},
    },
    (31, 2): {
        "base_misses": 118,
        "negative_centers": (3, 6, 11, 12, 13, 17, 21, 22, 24, 26),
        "state_only": {5: (18, 15), 9: (21, 15), 14: (21, 15), 25: (18, 15)},
    },
    (31, 14): {
        "base_misses": 23,
        "negative_centers": (26,),
        "state_only": {7: (18, 15), 9: (18, 15), 18: (16, 15), 19: (16, 15)},
    },
    (47, 6): {
        "base_misses": 196,
        "negative_centers": (5, 10, 13, 19, 20, 26, 29, 30, 33, 38, 40),
        "state_only": {
            7: (24, 23), 9: (26, 23), 14: (24, 23), 17: (24, 23),
            18: (24, 23), 21: (26, 23), 25: (24, 23), 27: (24, 23),
            28: (26, 23), 34: (24, 23), 37: (24, 23), 42: (26, 23),
        },
    },
}

PROMOTION_ANCHORS = (
    # hard class, source prime, destination, required p mod source, source mod destination
    (169, 17, 47, 4, 17),
    (169, 37, 47, 27, 37),
    (529, 17, 47, 4, 17),
)


def factorization(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    x = n
    q = 2
    while q * q <= x:
        while x % q == 0:
            out[q] += 1
            x //= q
        q += 1 if q == 2 else 2
    if x > 1:
        out[x] += 1
    return out


def legendre(residue: int, q: int) -> int:
    residue %= q
    if residue == 0:
        return 0
    value = pow(residue, (q - 1) // 2, q)
    return -1 if value == q - 1 else 1


def transition(state: tuple[frozenset[int], int], a: int, k: int) -> tuple[frozenset[int], int]:
    mask, center = state
    local = (1, a % k, a * a % k)
    return frozenset(x * y % k for x in mask for y in local), center * a % k


def seed_state(seed: int, k: int) -> tuple[frozenset[int], int]:
    state = (frozenset({1}), 1)
    for q, exponent in factorization(seed).items():
        for _ in range(exponent):
            state = transition(state, q, k)
    return state


def closure(start: tuple[frozenset[int], int], k: int) -> frozenset[tuple[frozenset[int], int]]:
    units = tuple(range(1, k))
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for a in units:
            child = transition(state, a, k)
            if child not in seen:
                seen.add(child)
                queue.append(child)
    return frozenset(seen)


def is_miss(state: tuple[frozenset[int], int], k: int) -> bool:
    mask, center = state
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-center) % k
    return type_i not in mask and type_ii not in mask


def p_center(state: tuple[frozenset[int], int], k: int) -> int:
    return 4 * state[1] % k


def analyze_seed(k: int, seed: int) -> dict[str, object]:
    expected = EXPECTED[(k, seed)]
    qrs = {x * x % k for x in range(1, k)}
    base_start = seed_state(seed, k)
    base_closure = closure(base_start, k)
    base_misses = {state for state in base_closure if is_miss(state, k)}
    negative = tuple(sorted({
        p_center(state, k)
        for state in base_misses
        if p_center(state, k) not in qrs
    }))
    assert len(base_misses) == expected["base_misses"]
    assert negative == expected["negative_centers"]

    discovered = {}
    rows = []
    for r in sorted(qrs):
        augmented_start = transition(base_start, r, k)
        augmented_closure = closure(augmented_start, k)
        augmented_misses = {state for state in augmented_closure if is_miss(state, k)}
        assert augmented_misses <= base_misses
        remaining_negative = {
            p_center(state, k)
            for state in augmented_misses
            if p_center(state, k) not in qrs
        }
        qr_saturates = augmented_start[0] == qrs
        if not remaining_negative and not qr_saturates:
            center_count = len({p_center(state, k) for state in augmented_misses})
            discovered[r] = (len(augmented_misses), center_count)
            rows.append({
                "source_residue": r,
                "augmented_state_count": len(augmented_closure),
                "augmented_miss_count": len(augmented_misses),
                "augmented_center_count": center_count,
            })

    assert discovered == expected["state_only"]
    return {
        "k": k,
        "seed": seed,
        "ordinary_miss_count": len(base_misses),
        "ordinary_negative_centers": list(negative),
        "state_only_repellers": rows,
    }


def verify_promotions() -> list[dict[str, int]]:
    state_only_47 = set(EXPECTED[(47, 6)]["state_only"])
    rows = []
    for hard_class, source, destination, required, source_mod_destination in PROMOTION_ANCHORS:
        assert destination == 47
        assert required == (-destination) % source
        assert legendre(required, source) == 1
        assert source % destination == source_mod_destination
        assert source_mod_destination in state_only_47
        rows.append({
            "hard_class": hard_class,
            "source_prime": source,
            "destination_k": destination,
            "required_p_mod_source": required,
            "source_mod_destination": source_mod_destination,
        })
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    seed_rows = [analyze_seed(k, seed) for k, seed in sorted(EXPECTED)]
    promotions = verify_promotions()
    report = {
        "analysis": "exact-state-incoming-repulsion-independent-verification-v1",
        "unique_state_only_seed_geometries_checked": len(seed_rows),
        "state_only_repeller_residues_checked": sum(
            len(row["state_only_repellers"]) for row in seed_rows
        ),
        "new_promotion_anchors_checked": len(promotions),
        "seed_geometries": seed_rows,
        "promotion_anchors": promotions,
        "failures": 0,
        "claim": (
            "explicit set-state closures independently reproduce every state-only repeller "
            "geometry and verify the three new k47 promotion routes"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"seed geometries checked: {len(seed_rows)}")
        print(f"promotion anchors checked: {len(promotions)}")
        print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
