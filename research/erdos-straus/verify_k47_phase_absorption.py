#!/usr/bin/env python3
"""Independent exact-state verification of h169 k47 phase absorption."""
from __future__ import annotations

import argparse
import json
from collections import Counter, deque

K = 47
UNITS = tuple(range(1, K))
TYPE_I_TARGET = (-pow(4, -1, K)) % K
ABSORBED_PHASES = frozenset({1, 5, 6, 10, 13, 21, 23, 36, 37, 38, 40, 42, 44})
TRIVIAL_SHELL_PHASES = frozenset({21, 36, 44})
EXTRA_PHASES = ABSORBED_PHASES - TRIVIAL_SHELL_PHASES
EXPECTED_SURVIVOR_PHASES = frozenset(set(range(K)) - set(ABSORBED_PHASES))
EXPECTED_ZERO_MISS_CENTERS = frozenset({0, 11, 22, 23, 29, 35, 38, 39, 41, 43, 44, 45, 46})
EXPECTED_NONRESIDUE_MISS_CENTERS = frozenset({5, 10, 13, 15, 19, 20, 26, 30, 31, 33, 40})
EXPECTED_PHASE_MISS_COUNTS = (
    2,0,5,11,7,0,0,10,2,2,0,2,4,0,3,2,6,13,2,5,11,0,2,0,
    5,7,3,2,15,2,4,2,17,2,12,6,0,0,0,3,0,3,0,9,0,13,2,
)


def transition(
    state: tuple[frozenset[int], int], residue: int
) -> tuple[frozenset[int], int]:
    mask, center = state
    r = residue % K
    powers = {1, r, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def seed_state() -> tuple[frozenset[int], int]:
    state: tuple[frozenset[int], int] = (frozenset({1}), 1)
    state = transition(state, 2)
    state = transition(state, 3)
    return state


def hit(state: tuple[frozenset[int], int]) -> tuple[bool, bool]:
    mask, center = state
    return TYPE_I_TARGET in mask, (-center) % K in mask


def closure() -> frozenset[tuple[frozenset[int], int]]:
    start = seed_state()
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for residue in UNITS:
            nxt = transition(state, residue)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def legendre(a: int) -> int:
    a %= K
    if a == 0:
        return 0
    x = pow(a, (K - 1) // 2, K)
    return 1 if x == 1 else -1


def center_for_phase(t: int) -> int:
    return (54 + 210 * t) % K


def p_for_phase(t: int) -> int:
    return (169 + 840 * t) % (840 * K)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert TYPE_I_TARGET == 35
    mask0, center0 = seed_state()
    assert center0 == 6
    assert mask0 == frozenset({1, 2, 3, 4, 6, 9, 12, 18, 36})

    states = closure()
    misses = []
    mechanism = Counter()
    for state in states:
        type_i, type_ii = hit(state)
        if type_i and type_ii:
            mechanism["I+II"] += 1
        elif type_i:
            mechanism["I-only"] += 1
        elif type_ii:
            mechanism["II-only"] += 1
        else:
            mechanism["miss"] += 1
            misses.append(state)

    assert len(states) == 1079
    assert len(misses) == 196
    assert mechanism == Counter({"I+II": 594, "I-only": 221, "II-only": 68, "miss": 196})

    miss_by_center = Counter(center for _mask, center in misses)
    phase_rows = []
    for t in range(K):
        center = center_for_phase(t)
        count = 0 if center == 0 else miss_by_center[center]
        phase_rows.append((t, center, count))

    assert tuple(row[2] for row in phase_rows) == EXPECTED_PHASE_MISS_COUNTS
    absorbed = frozenset(t for t, _center, count in phase_rows if count == 0)
    assert absorbed == ABSORBED_PHASES
    assert frozenset(set(range(K)) - set(absorbed)) == EXPECTED_SURVIVOR_PHASES

    zero_centers = frozenset(center for _t, center, count in phase_rows if count == 0)
    assert zero_centers == EXPECTED_ZERO_MISS_CENTERS

    nonzero_zero_centers = zero_centers - {0}
    assert all(legendre(center) == -1 for center in nonzero_zero_centers)

    nr_miss_centers = frozenset(
        center for center in miss_by_center if legendre(center) == -1
    )
    assert nr_miss_centers == EXPECTED_NONRESIDUE_MISS_CENTERS

    qr_centers = frozenset(center for center in UNITS if legendre(center) == 1)
    assert all(miss_by_center[center] > 0 for center in qr_centers)

    assert center_for_phase(21) == K - 1
    assert center_for_phase(36) == 0
    assert center_for_phase(44) == TYPE_I_TARGET
    assert EXTRA_PHASES == frozenset({1, 5, 6, 10, 13, 23, 37, 38, 40, 42})

    p_absorbed = tuple(sorted(p_for_phase(t) for t in ABSORBED_PHASES))
    assert p_absorbed == (
        1009, 4369, 5209, 8569, 11089, 17809, 19489,
        30409, 31249, 32089, 33769, 35449, 37129,
    )

    report = {
        "analysis": "h169-k47-phase-absorption-v1",
        "states": len(states),
        "misses": len(misses),
        "mechanisms": dict(mechanism),
        "type_i_target": TYPE_I_TARGET,
        "absorbed_phases_mod47": sorted(ABSORBED_PHASES),
        "trivial_shell_phases": sorted(TRIVIAL_SHELL_PHASES),
        "extra_exact_state_phases": sorted(EXTRA_PHASES),
        "possible_survivor_phases_mod47": sorted(EXPECTED_SURVIVOR_PHASES),
        "zero_miss_centers": sorted(zero_centers),
        "nonresidue_miss_centers": sorted(nr_miss_centers),
        "absorbed_p_residues_mod39480": list(p_absorbed),
        "phase_rows": [
            {"t": t, "center": center, "miss_states": count}
            for t, center, count in phase_rows
        ],
        "failures": 0,
        "claim": (
            "exact h169 k47 implication: a k47 miss requires t mod47 outside "
            "{1,5,6,10,13,21,23,36,37,38,40,42,44}; ten absorbed phases "
            "are beyond the universal d in {1,C,C^2} selector shell"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
