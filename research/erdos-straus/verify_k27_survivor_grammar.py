#!/usr/bin/env python3
"""Independent exact-state verification of the h169 k27 survivor grammar."""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import Counter, deque

K = 27
UNITS = tuple(r for r in range(1, K) if math.gcd(r, K) == 1)
QR = frozenset({1, 4, 7, 10, 13, 16, 19, 22, 25})
NR = frozenset(set(UNITS) - set(QR))
TYPE_I_TARGET = (-pow(4, -1, K)) % K

EXPECTED_SKELETONS = frozenset(
    {
        (),
        (2, 2),
        (2, 14),
        (2, 17),
        (5, 5),
        (5, 11),
        (8, 14),
        (8, 17),
        (11, 11),
        (14, 14),
        (2, 2, 2, 14),
        (2, 2, 2, 17),
        (2, 2, 14, 14),
        (2, 14, 14, 14),
        (5, 5, 11, 11),
        (8, 14, 14, 14),
        (2, 2, 2, 14, 14, 14),
    }
)

MODE_SKELETONS = {
    "Q": {()},
    "A": {(2, 14)},
    "B": {
        (8, 17),
        (5, 11),
        (2, 2, 2, 17),
        (2, 2, 14, 14),
        (8, 14, 14, 14),
        (5, 5, 11, 11),
        (2, 2, 2, 14, 14, 14),
    },
    "C": {(2, 2), (8, 14), (2, 2, 2, 14)},
    "D": {(2, 17), (14, 14), (2, 14, 14, 14)},
    "E": {(5, 5)},
    "F": {(11, 11)},
}

EXPECTED_TRANSITIONS = {
    "Q": {r: "Q" for r in QR},
    "A": {1: "A", 4: "C", 7: "D", 10: "HIT", 13: "HIT", 16: "HIT", 19: "HIT", 22: "HIT", 25: "HIT"},
    "B": {1: "B", 4: "HIT", 7: "HIT", 10: "HIT", 13: "HIT", 16: "HIT", 19: "HIT", 22: "HIT", 25: "HIT"},
    "C": {1: "C", 4: "HIT", 7: "B", 10: "HIT", 13: "HIT", 16: "HIT", 19: "HIT", 22: "HIT", 25: "HIT"},
    "D": {1: "D", 4: "B", 7: "HIT", 10: "HIT", 13: "HIT", 16: "HIT", 19: "HIT", 22: "HIT", 25: "HIT"},
    "E": {1: "E", 4: "HIT", 7: "HIT", 10: "HIT", 13: "B", 16: "HIT", 19: "HIT", 22: "HIT", 25: "HIT"},
    "F": {1: "F", 4: "HIT", 7: "HIT", 10: "HIT", 13: "HIT", 16: "HIT", 19: "HIT", 22: "HIT", 25: "B"},
}

State = tuple[frozenset[int], int]


def seed_state() -> State:
    return frozenset({1, 7, 22}), 7


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


def state_from_occurrences(occurrences: tuple[int, ...]) -> State:
    state = seed_state()
    for r in occurrences:
        state = transition(state, r)
    return state


def closure(starts: set[State], alphabet: tuple[int, ...]) -> set[State]:
    seen = set(starts)
    queue = deque(starts)
    while queue:
        state = queue.popleft()
        for r in alphabet:
            nxt = transition(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def minimize(states: set[State], alphabet: tuple[int, ...]) -> tuple[dict[State, int], dict[int, set[State]]]:
    ordered = sorted(states, key=lambda s: (s[1], len(s[0]), tuple(sorted(s[0]))))
    index = {state: i for i, state in enumerate(ordered)}
    trans = [[index[transition(state, r)] for r in alphabet] for state in ordered]
    part = [1 if is_hit(state) else 0 for state in ordered]

    while True:
        signatures: dict[tuple[object, ...], int] = {}
        new_part: list[int] = []
        for i, state in enumerate(ordered):
            signature = (part[i], tuple(part[j] for j in trans[i]))
            if signature not in signatures:
                signatures[signature] = len(signatures)
            new_part.append(signatures[signature])
        if len(set(new_part)) == len(set(part)):
            part = new_part
            break
        part = new_part

    state_class = {state: part[i] for i, state in enumerate(ordered)}
    classes: dict[int, set[State]] = {}
    for state, cls in state_class.items():
        classes.setdefault(cls, set()).add(state)
    return state_class, classes


def verify_raw_closure() -> dict[str, object]:
    states = closure({seed_state()}, UNITS)
    hits = {state for state in states if is_hit(state)}
    misses = states - hits
    hard_misses = {state for state in misses if state[1] in QR}

    assert TYPE_I_TARGET == 20
    assert len(states) == 132
    assert len(hits) == 88
    assert len(misses) == 44
    assert len(hard_misses) == 28

    # Exact persistence and commutativity of factor insertion.
    for state in states:
        if is_hit(state):
            for r in UNITS:
                assert is_hit(transition(state, r))
        for r in UNITS:
            for s in UNITS:
                assert transition(transition(state, r), s) == transition(transition(state, s), r)

    return {
        "states": len(states),
        "hits": len(hits),
        "misses": len(misses),
        "h169_compatible_misses": len(hard_misses),
        "hard_misses": hard_misses,
    }


def verify_nr_skeletons() -> dict[str, object]:
    counts: dict[int, int] = {}
    survivors_by_size: dict[int, set[tuple[int, ...]]] = {}
    nr_sorted = tuple(sorted(NR))

    for size in range(8):
        survivors = {
            tuple(multiset)
            for multiset in itertools.combinations_with_replacement(nr_sorted, size)
            if not is_hit(state_from_occurrences(tuple(multiset)))
        }
        survivors_by_size[size] = survivors
        counts[size] = len(survivors)

    assert counts == {0: 1, 1: 6, 2: 9, 3: 8, 4: 6, 5: 2, 6: 1, 7: 0}

    singleton_killers = {
        r for r in NR if is_hit(state_from_occurrences((r,)))
    }
    assert singleton_killers == {20, 23, 26}

    # E=1 mod3. QR27 units are exactly1 mod3 and NR27 units exactly2 mod3,
    # so actual h169 factorizations have an even number of NR occurrences.
    assert all(r % 3 == 1 for r in QR)
    assert all(r % 3 == 2 for r in NR)

    actual = set().union(*(survivors_by_size[size] for size in (0, 2, 4, 6)))
    assert actual == set(EXPECTED_SKELETONS)
    assert len(actual) == 17

    # Since every size7 NR multiset hits and hits are absorbing, no larger
    # NR multiset can be part of a miss.
    assert not survivors_by_size[7]

    return {
        "survivor_counts_by_nr_occurrences": counts,
        "singleton_killers": sorted(singleton_killers),
        "h169_even_nr_skeletons": len(actual),
        "skeletons": sorted(actual, key=lambda x: (len(x), x)),
    }


def verify_qr_completion(hard_misses: set[State]) -> dict[str, object]:
    skeleton_states = {
        state_from_occurrences(skeleton) for skeleton in EXPECTED_SKELETONS
    }
    assert len(skeleton_states) == 12

    qr_alphabet = tuple(sorted(QR))
    states = closure(skeleton_states, qr_alphabet)
    hits = {state for state in states if is_hit(state)}
    misses = states - hits
    assert len(states) == 47
    assert len(hits) == 19
    assert len(misses) == 28
    assert misses == hard_misses

    state_class, classes = minimize(states, qr_alphabet)
    assert len(classes) == 8
    hit_classes = {
        state_class[state] for state in states if is_hit(state)
    }
    assert len(hit_classes) == 1
    hit_class = next(iter(hit_classes))
    assert len(classes[hit_class]) == 19

    mode_class: dict[str, int] = {}
    for mode, skeletons in MODE_SKELETONS.items():
        classes_seen = {
            state_class[state_from_occurrences(tuple(skeleton))]
            for skeleton in skeletons
        }
        assert len(classes_seen) == 1
        cls = next(iter(classes_seen))
        assert cls != hit_class
        mode_class[mode] = cls
    assert len(set(mode_class.values())) == 7

    class_mode = {cls: mode for mode, cls in mode_class.items()}
    class_mode[hit_class] = "HIT"

    for mode, skeletons in MODE_SKELETONS.items():
        representative = state_from_occurrences(tuple(next(iter(skeletons))))
        for r in qr_alphabet:
            target = transition(representative, r)
            target_mode = class_mode[state_class[target]]
            assert target_mode == EXPECTED_TRANSITIONS[mode][r]

    # The hit behavioral class is absorbing under every QR completion.
    for state in classes[hit_class]:
        for r in qr_alphabet:
            assert state_class[transition(state, r)] == hit_class

    return {
        "raw_qr_completion_states": len(states),
        "raw_misses": len(misses),
        "raw_hits": len(hits),
        "minimal_behavioral_classes": len(classes),
        "live_modes": sorted(MODE_SKELETONS),
        "hit_classes": 1,
        "transition_table": EXPECTED_TRANSITIONS,
    }


def verify_affine_chain() -> dict[str, object]:
    for t in range(27 * 31):
        p = 169 + 840 * t
        B = 8 + 35 * t
        E = 7 + 30 * t
        D = 5 + 21 * t
        assert (p + 23) // 4 == 6 * B
        assert (p + 27) // 4 == 7 * E
        assert (p + 31) // 4 == 10 * D
        assert E % 3 == 1
        assert 7 * E - 6 * B == 1
        assert 10 * D - 7 * E == 1
        assert 5 * D - 3 * B == 1
        assert math.gcd(B, E) == 1
        assert math.gcd(E, D) == 1
        assert math.gcd(B, D) == 1
    return {
        "t_values_checked": 27 * 31,
        "relations": ["7E-6B=1", "10D-7E=1", "5D-3B=1"],
        "pairwise_coprime": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert QR == frozenset({1, 4, 7, 10, 13, 16, 19, 22, 25})
    assert NR == frozenset({2, 5, 8, 11, 14, 17, 20, 23, 26})
    assert set().union(*MODE_SKELETONS.values()) == set(EXPECTED_SKELETONS)
    assert sum(len(v) for v in MODE_SKELETONS.values()) == 17

    raw = verify_raw_closure()
    skeletons = verify_nr_skeletons()
    qr_completion = verify_qr_completion(raw["hard_misses"])
    affine = verify_affine_chain()

    report = {
        "analysis": "h169-k27-survivor-grammar-v1",
        "raw_closure": {k: v for k, v in raw.items() if k != "hard_misses"},
        "nr_skeletons": skeletons,
        "qr_completion": qr_completion,
        "affine_chain": affine,
        "failures": 0,
        "claim": (
            "exact h169 k27 iff survivor grammar: 17 possible even-NR skeletons, "
            "followed by a seven-mode QR-completion automaton plus one absorbing hit class"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
