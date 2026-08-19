#!/usr/bin/env python3
"""Independent exact-state verification of h169 k39 phase absorption."""
from __future__ import annotations

import argparse
import json
import math
from collections import deque

K = 39
UNITS = tuple(r for r in range(1, K) if math.gcd(r, K) == 1)
TYPE_I_TARGET = (-pow(4, -1, K)) % K

EXPECTED = {
    1: (28, 14, 2),
    2: (4, 19, 4),
    3: (19, 20, 0),
    4: (34, 20, 0),
    5: (10, 11, 6),
    6: (25, 14, 3),
    7: (1, 19, 6),
    8: (16, 11, 2),
    9: (31, 20, 4),
    10: (7, 20, 6),
    11: (22, 14, 3),
    12: (37, 14, 0),
}
FORCED = {0, 3, 4, 12}
RESIDUAL = {1, 2, 5, 6, 7, 8, 9, 10, 11}

State = tuple[frozenset[int], int]


def seed_state() -> State:
    return frozenset({1, 2, 4}), 2


def transition(state: State, r: int) -> State:
    mask, center = state
    powers = {1, r % K, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def status(state: State) -> tuple[bool, bool]:
    mask, center = state
    return TYPE_I_TARGET in mask, (-center) % K in mask


def is_hit(state: State) -> bool:
    return any(status(state))


def closure() -> set[State]:
    seen = {seed_state()}
    queue = deque(seen)
    while queue:
        state = queue.popleft()
        for r in UNITS:
            nxt = transition(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def verify_phase_zero() -> dict[str, object]:
    # For t=13u, G=26+105t is divisible by13 and remains2 mod3.
    # Writing G=13H therefore gives H=2 mod3 and C39=26H=13 mod39.
    # The Type-II target is26, and d=26 divides C39 itself.
    for u in range(39):
        t = 13 * u
        p = 169 + 840 * t
        G = 26 + 105 * t
        C = (p + 39) // 4
        assert C == 2 * G
        assert G % 13 == 0
        H = G // 13
        assert H % 3 == 2
        assert C % 39 == 13
        assert (-C) % 39 == 26
        assert C % 26 == 0
    return {
        "phase": 0,
        "type_ii_target": 26,
        "fixed_divisor_witness": 26,
    }


def verify_unit_phases() -> dict[str, object]:
    states = closure()
    misses = {state for state in states if not is_hit(state)}
    hits = states - misses
    assert len(UNITS) == 24
    assert TYPE_I_TARGET == 29
    assert len(states) == 394
    assert len(misses) == 74
    assert len(hits) == 320

    # Once an exact signed-box witness exists, adjoining another factor cannot
    # remove it. This is checked over the complete state graph.
    for state in hits:
        for r in UNITS:
            assert is_hit(transition(state, r))

    table: dict[int, dict[str, int]] = {}
    forced_unit: set[int] = set()
    for t in range(1, 13):
        center = (13 + 15 * t) % 39
        endpoints = {state for state in states if state[1] == center}
        endpoint_misses = {state for state in endpoints if not is_hit(state)}
        expected_center, expected_states, expected_misses = EXPECTED[t]
        assert center == expected_center
        assert len(endpoints) == expected_states
        assert len(endpoint_misses) == expected_misses
        if not endpoint_misses:
            forced_unit.add(t)
        table[t] = {
            "center": center,
            "endpoint_states": len(endpoints),
            "misses": len(endpoint_misses),
        }

    assert forced_unit == {3, 4, 12}
    assert FORCED == forced_unit | {0}
    assert RESIDUAL == set(range(13)) - FORCED

    return {
        "raw_states": len(states),
        "raw_hits": len(hits),
        "raw_misses": len(misses),
        "forced_unit_phases": sorted(forced_unit),
        "residual_phases": sorted(RESIDUAL),
        "phase_table": table,
    }


def verify_congruence_classes() -> dict[str, object]:
    residues = sorted((169 + 840 * t) % 10920 for t in FORCED)
    assert residues == [169, 2689, 3529, 10249]
    for t in range(13):
        p = 169 + 840 * t
        C = (p + 39) // 4
        G = 26 + 105 * t
        assert C == 52 + 210 * t == 2 * G
        assert G % 3 == 2
        assert G % 13 == t % 13
        assert C % 39 == (13 + 15 * t) % 39
    return {
        "modulus": 10920,
        "absorbed_p_residues": residues,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "h169-k39-phase-absorption-v1",
        "phase_zero": verify_phase_zero(),
        "unit_phases": verify_unit_phases(),
        "congruence_classes": verify_congruence_classes(),
        "failures": 0,
        "claim": (
            "exact h169 k39 absorption for t mod13 in {0,3,4,12}; "
            "only nine residual t phases can miss"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
