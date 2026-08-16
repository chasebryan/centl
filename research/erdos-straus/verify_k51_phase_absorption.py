#!/usr/bin/env python3
"""Independent exact-state verification of h169 k51 phase absorption."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

K = 51
UNITS = tuple(r for r in range(1, K) if math.gcd(r, K) == 1)
TYPE_I_TARGET = (-pow(4, -1, K)) % K
ABSORBED = frozenset({4, 5, 7, 14})
UNIT_ABSORBED = frozenset({4, 7, 14})
NONUNIT_PHASE = 5
EXPECTED_MISSES = (10, 8, 5, 6, 0, 0, 12, 0, 8, 9, 16, 9, 14, 12, 0, 6, 3)

State = tuple[frozenset[int], int]


def transition(state: State, residue: int) -> State:
    mask, center = state
    r = residue % K
    powers = {1, r, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def seed_state() -> State:
    return transition((frozenset({1}), 1), 5)


def hit(state: State) -> tuple[bool, bool]:
    mask, center = state
    return TYPE_I_TARGET in mask, (-center) % K in mask


def is_hit(state: State) -> bool:
    return any(hit(state))


def closure() -> frozenset[State]:
    start = seed_state()
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for r in UNITS:
            nxt = transition(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def center_for_phase(t: int) -> int:
    return (55 + 210 * t) % K


def shell_hits(center: int) -> bool:
    C = center % K
    return any(
        (
            (1 + C) % K == 0,
            (2 * C) % K == 0,
            (C * C + C) % K == 0,
            (4 * C + 1) % K == 0,
            (4 * C * C + 1) % K == 0,
        )
    )


def verify_nonunit_phase() -> dict[str, object]:
    for u in range(K):
        t = NONUNIT_PHASE + 17 * u
        U = 11 + 42 * t
        C = 5 * U
        assert U % 3 == 2
        assert U % 17 == 0
        assert C % K == 34
        assert (-C) % K == 17
        assert (C * C) % 17 == 0
    return {
        "phase_mod17": NONUNIT_PHASE,
        "center_mod51": 34,
        "type_ii_target": 17,
        "fixed_divisor_witness": 17,
    }


def verify_unit_closure() -> dict[str, object]:
    assert len(UNITS) == 32
    assert TYPE_I_TARGET == 38
    assert seed_state() == (frozenset({1, 5, 25}), 5)

    states = closure()
    misses: list[State] = []
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

    assert len(states) == 1403
    assert len(misses) == 244
    assert mechanism == Counter({"I+II": 542, "I-only": 392, "miss": 244, "II-only": 225})

    # Exact witnesses persist under any future prime-factor occurrence.
    for state in states:
        if is_hit(state):
            for r in UNITS:
                assert is_hit(transition(state, r))

    miss_by_center = Counter(center for _mask, center in misses)
    phase_rows = []
    for t in range(17):
        center = center_for_phase(t)
        if t == NONUNIT_PHASE:
            count = 0
            assert math.gcd(center, K) == 17
        else:
            assert math.gcd(center, K) == 1
            count = miss_by_center[center]
        phase_rows.append((t, center, count))

    assert tuple(count for _t, _center, count in phase_rows) == EXPECTED_MISSES
    assert frozenset(t for t, _center, count in phase_rows if count == 0) == ABSORBED
    assert frozenset(
        t for t, _center, count in phase_rows if count == 0 and t != NONUNIT_PHASE
    ) == UNIT_ABSORBED

    # None of the h169 center phases is absorbed by the universal {1,C,C^2} shell.
    assert all(not shell_hits(center_for_phase(t)) for t in range(17))

    return {
        "states": len(states),
        "misses": len(misses),
        "mechanisms": dict(mechanism),
        "unit_absorbed_phases": sorted(UNIT_ABSORBED),
        "phase_rows": [
            {"t": t, "center": center, "miss_states": count}
            for t, center, count in phase_rows
        ],
        "trivial_shell_phases": [],
    }


def verify_congruence_classes() -> dict[str, object]:
    residues = sorted((169 + 840 * t) % 14280 for t in ABSORBED)
    assert residues == [3529, 4369, 6049, 11929]
    for t in range(17):
        p = 169 + 840 * t
        C = (p + 51) // 4
        U = 11 + 42 * t
        assert C == 55 + 210 * t == 5 * U
        assert U % 3 == 2
        assert U % 17 == (11 + 8 * t) % 17
        assert C % 51 == center_for_phase(t)
    return {"modulus": 14280, "absorbed_p_residues": residues}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "h169-k51-phase-absorption-v1",
        "nonunit_phase": verify_nonunit_phase(),
        "unit_closure": verify_unit_closure(),
        "congruence_classes": verify_congruence_classes(),
        "absorbed_phases_mod17": sorted(ABSORBED),
        "failures": 0,
        "claim": (
            "exact h169 k51 implication: a k51 miss requires "
            "t mod17 outside {4,5,7,14}"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
