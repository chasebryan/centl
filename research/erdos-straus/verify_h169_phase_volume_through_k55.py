#!/usr/bin/env python3
"""Verify h169 k51/k55 phase absorption and CRT survivor-volume contraction."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque
from fractions import Fraction

S39 = frozenset({1, 2, 5, 6, 7, 8, 9, 10, 11})
A43 = frozenset({2, 28, 30})
S43 = frozenset(set(range(43)) - set(A43))
A47 = frozenset({1, 5, 6, 10, 13, 21, 23, 36, 37, 38, 40, 42, 44})
S47 = frozenset(set(range(47)) - set(A47))
A51 = frozenset({4, 5, 7, 14})
S51 = frozenset(set(range(17)) - set(A51))
A55 = frozenset({5, 6, 7, 10})
S55 = frozenset(set(range(11)) - set(A55))

EXPECTED_51_PHASE_MISSES = (10, 8, 5, 6, 0, 0, 12, 0, 8, 9, 16, 9, 14, 12, 0, 6, 3)
EXPECTED_55_PHASE_MISSES = (6, 6, 3, 1, 1, 0, 0, 0, 6, 6, 0)

State = tuple[frozenset[int], int]


def transition(k: int, state: State, r: int) -> State:
    mask, center = state
    r %= k
    powers = {1, r, r * r % k}
    return (
        frozenset(a * b % k for a in mask for b in powers),
        center * r % k,
    )


def seed_state(k: int, seed_factors: tuple[int, ...]) -> State:
    state: State = (frozenset({1}), 1)
    for q in seed_factors:
        state = transition(k, state, q)
    return state


def closure(k: int, seed_factors: tuple[int, ...]) -> frozenset[State]:
    units = tuple(r for r in range(1, k) if math.gcd(r, k) == 1)
    start = seed_state(k, seed_factors)
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for r in units:
            nxt = transition(k, state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def classify(k: int, states: frozenset[State]) -> tuple[Counter[str], list[State]]:
    type_i_target = (-pow(4, -1, k)) % k
    mechanisms: Counter[str] = Counter()
    misses = []
    for mask, center in states:
        type_i = type_i_target in mask
        type_ii = (-center) % k in mask
        if type_i and type_ii:
            mechanisms["I+II"] += 1
        elif type_i:
            mechanisms["I-only"] += 1
        elif type_ii:
            mechanisms["II-only"] += 1
        else:
            mechanisms["miss"] += 1
            misses.append((mask, center))
    return mechanisms, misses


def is_hit(k: int, state: State) -> bool:
    mask, center = state
    return ((-pow(4, -1, k)) % k) in mask or (-center) % k in mask


def shell_hits(k: int, center: int) -> bool:
    c = center % k
    return any(
        (
            (1 + c) % k == 0,
            (2 * c) % k == 0,
            (c * c + c) % k == 0,
            (4 * c + 1) % k == 0,
            (4 * c * c + 1) % k == 0,
        )
    )


def verify_k51() -> dict[str, object]:
    k = 51
    units = tuple(r for r in range(1, k) if math.gcd(r, k) == 1)
    states = closure(k, (5,))
    mechanisms, misses = classify(k, states)
    assert len(states) == 1403
    assert mechanisms == Counter({"I+II": 542, "I-only": 392, "miss": 244, "II-only": 225})

    for state in states:
        if is_hit(k, state):
            for r in units:
                assert is_hit(k, transition(k, state, r))

    miss_by_center = Counter(center for _mask, center in misses)
    rows = []
    for t in range(17):
        center = (55 + 210 * t) % k
        count = miss_by_center[center] if math.gcd(center, k) == 1 else 0
        rows.append((t, center, count))

    assert tuple(count for _t, _center, count in rows) == EXPECTED_51_PHASE_MISSES
    absorbed = frozenset(t for t, _center, count in rows if count == 0)
    assert absorbed == A51

    for u in range(51):
        t = 5 + 17 * u
        Kco = 11 + 42 * t
        C = 5 * Kco
        assert Kco % 17 == 0
        assert C % k == 34
        assert (C * C) % 17 == 0
        assert (-C) % k == 17

    type_i_target = (-pow(4, -1, k)) % k
    assert type_i_target == 38
    assert all(not shell_hits(k, (55 + 210 * t) % k) for t in range(17))

    return {
        "states": len(states),
        "misses": len(misses),
        "mechanisms": dict(mechanisms),
        "absorbed_phases_mod17": sorted(absorbed),
        "survivor_phases_mod17": sorted(S51),
        "phase_rows": [{"t": t, "center": c, "miss_states": n} for t, c, n in rows],
        "trivial_shell_phases": [],
    }


def verify_k55() -> dict[str, object]:
    k = 55
    units = tuple(r for r in range(1, k) if math.gcd(r, k) == 1)
    states = closure(k, (2, 7))
    mechanisms, misses = classify(k, states)
    assert len(states) == 509
    assert mechanisms == Counter({"I+II": 284, "miss": 126, "I-only": 84, "II-only": 15})

    for state in states:
        if is_hit(k, state):
            for r in units:
                assert is_hit(k, transition(k, state, r))

    miss_by_center = Counter(center for _mask, center in misses)
    rows = []
    for t in range(11):
        center = (56 + 210 * t) % k
        count = miss_by_center[center] if math.gcd(center, k) == 1 else 0
        rows.append((t, center, count))

    assert tuple(count for _t, _center, count in rows) == EXPECTED_55_PHASE_MISSES
    absorbed = frozenset(t for t, _center, count in rows if count == 0)
    assert absorbed == A55

    type_i_target = (-pow(4, -1, k)) % k
    assert type_i_target == 41

    C7 = 56 + 210 * 7
    assert C7 % k == type_i_target
    assert (4 * C7 + 1) % k == 0

    for u in range(55):
        t = 10 + 11 * u
        L = 4 + 15 * t
        C = 14 * L
        assert L % 11 == 0
        assert C % k == 11
        assert (C * C) % 44 == 0
        assert (-C) % k == 44

    shell_phases = frozenset(
        t for t in range(11) if shell_hits(k, (56 + 210 * t) % k)
    )
    assert shell_phases == {7}

    return {
        "states": len(states),
        "misses": len(misses),
        "mechanisms": dict(mechanisms),
        "absorbed_phases_mod11": sorted(absorbed),
        "survivor_phases_mod11": sorted(S55),
        "phase_rows": [{"t": t, "center": c, "miss_states": n} for t, c, n in rows],
        "trivial_shell_phases": sorted(shell_phases),
    }


def verify_phase_volume() -> dict[str, object]:
    moduli = (13, 43, 47, 17, 11)
    survivor_sizes = (len(S39), len(S43), len(S47), len(S51), len(S55))
    assert survivor_sizes == (9, 40, 34, 13, 7)

    for i, a in enumerate(moduli):
        for b in moduli[i + 1 :]:
            assert math.gcd(a, b) == 1

    modulus = math.prod(moduli)
    survivors = math.prod(survivor_sizes)
    excluded = modulus - survivors
    assert modulus == 4_913_051
    assert survivors == 1_113_840
    assert excluded == 3_799_211

    fraction = Fraction(survivors, modulus)
    assert math.gcd(survivors, modulus) == 221
    assert fraction == Fraction(5040, 22231)

    return {
        "moduli": list(moduli),
        "survivor_sizes": list(survivor_sizes),
        "phase_modulus": modulus,
        "survivor_classes": survivors,
        "excluded_classes": excluded,
        "survivor_class_ratio": f"{survivors}/{modulus}",
        "survivor_fraction_reduced": f"{fraction.numerator}/{fraction.denominator}",
        "survivor_fraction": float(fraction),
        "excluded_fraction": float(1 - fraction),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "h169-phase-volume-through-k55-v1",
        "k51": verify_k51(),
        "k55": verify_k55(),
        "phase_volume": verify_phase_volume(),
        "failures": 0,
        "claim": (
            "simultaneous survival of the named h169 phase filters at k39,k43,k47,k51,k55 "
            "requires t to lie in 1,113,840 of 4,913,051 CRT phase classes; this is an exact "
            "necessary phase restriction, not a termination theorem"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
