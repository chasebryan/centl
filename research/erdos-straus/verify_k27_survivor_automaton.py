#!/usr/bin/env python3
"""Independent exact-state verification of the h169 k27 survivor automaton."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, defaultdict, deque

K = 27
UNITS = tuple(r for r in range(1, K) if math.gcd(r, K) == 1)
TYPE_I_TARGET = (-pow(4, -1, K)) % K

State = tuple[frozenset[int], int]


def seed_state() -> State:
    # h169 gives C27 = 7E with E = 7 + 30t.  The mandatory seed is 7.
    return frozenset({1, 7, 22}), 7


def transition(state: State, r: int) -> State:
    mask, center = state
    r %= K
    powers = {1, r, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def hit(state: State) -> tuple[bool, bool]:
    mask, center = state
    type_i = TYPE_I_TARGET in mask
    type_ii = (-center) % K in mask
    return type_i, type_ii


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


def minimize(states: frozenset[State]) -> list[frozenset[int]]:
    ordered = sorted(states, key=lambda s: (tuple(sorted(s[0])), s[1]))
    index = {state: i for i, state in enumerate(ordered)}
    delta = [
        [index[transition(state, r)] for r in UNITS]
        for state in ordered
    ]
    terminal = [any(hit(state)) for state in ordered]

    blocks: list[set[int]] = [
        {i for i, flag in enumerate(terminal) if flag},
        {i for i, flag in enumerate(terminal) if not flag},
    ]
    blocks = [block for block in blocks if block]

    while True:
        block_of: dict[int, int] = {}
        for block_id, block in enumerate(blocks):
            for state_id in block:
                block_of[state_id] = block_id

        changed = False
        refined: list[set[int]] = []
        for block in blocks:
            groups: dict[tuple[int, ...], set[int]] = defaultdict(set)
            for state_id in block:
                signature = tuple(block_of[target] for target in delta[state_id])
                groups[signature].add(state_id)
            if len(groups) > 1:
                changed = True
            refined.extend(groups.values())

        blocks = refined
        if not changed:
            break

    return [frozenset(block) for block in blocks]


def verify_affine_chain() -> dict[str, object]:
    # A complete 27*31 period is more than enough to pin the identities and
    # coprimality consequences independently of any finite prime census.
    for t in range(27 * 31):
        p = 169 + 840 * t
        C23 = (p + 23) // 4
        C27 = (p + 27) // 4
        C31 = (p + 31) // 4
        B = 8 + 35 * t
        E = 7 + 30 * t
        D = 5 + 21 * t
        assert C23 == 6 * B
        assert C27 == 7 * E
        assert C31 == 10 * D
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
        "E_mod_3": 1,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert UNITS == (1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 17, 19, 20, 22, 23, 25, 26)
    assert TYPE_I_TARGET == 20
    assert seed_state() == (frozenset({1, 7, 22}), 7)

    states = closure()
    misses = [state for state in states if not any(hit(state))]
    hits = [state for state in states if any(hit(state))]

    assert len(states) == 132
    assert len(misses) == 44
    assert len(hits) == 88
    assert len({mask for mask, _center in misses}) == 36

    mechanism_counts = Counter(hit(state) for state in states)
    assert mechanism_counts[(False, False)] == 44
    assert mechanism_counts[(True, False)] == 20
    assert mechanism_counts[(False, True)] == 6
    assert mechanism_counts[(True, True)] == 62

    # The complete hit set is absorbing under every admissible prime residue.
    # This turns the quotient's hit class into a genuine terminal framework state.
    for state in hits:
        for r in UNITS:
            assert any(hit(transition(state, r)))

    immediate_hit_residues = frozenset(
        r for r in UNITS if any(hit(transition(seed_state(), r)))
    )
    assert immediate_hit_residues == frozenset({20, 23, 26})

    quotient = minimize(states)
    ordered = sorted(states, key=lambda s: (tuple(sorted(s[0])), s[1]))
    class_sizes = sorted(len(block) for block in quotient)
    class_size_histogram = Counter(class_sizes)

    assert len(quotient) == 30
    assert class_size_histogram == Counter({1: 23, 2: 5, 11: 1, 88: 1})

    hit_blocks = []
    miss_blocks = []
    for block in quotient:
        flags = {any(hit(ordered[state_id])) for state_id in block}
        assert len(flags) == 1
        if True in flags:
            hit_blocks.append(block)
        else:
            miss_blocks.append(block)

    assert len(hit_blocks) == 1
    assert len(hit_blocks[0]) == 88
    assert len(miss_blocks) == 29
    assert sum(len(block) for block in miss_blocks) == 44

    report = {
        "analysis": "h169-k27-survivor-automaton-v1",
        "raw_states": len(states),
        "raw_hits": len(hits),
        "raw_misses": len(misses),
        "distinct_miss_masks": 36,
        "mechanisms": {
            "miss": mechanism_counts[(False, False)],
            "type_i_only": mechanism_counts[(True, False)],
            "type_ii_only": mechanism_counts[(False, True)],
            "type_i_and_ii": mechanism_counts[(True, True)],
        },
        "type_i_target": TYPE_I_TARGET,
        "seed_mask": sorted(seed_state()[0]),
        "seed_center": seed_state()[1],
        "immediate_hit_residues": sorted(immediate_hit_residues),
        "quotient_states": len(quotient),
        "quotient_survivor_classes": len(miss_blocks),
        "quotient_terminal_classes": len(hit_blocks),
        "quotient_class_size_histogram": {
            str(size): count for size, count in sorted(class_size_histogram.items())
        },
        "terminal_hit_class_size": len(hit_blocks[0]),
        "hit_set_absorbing": True,
        "affine_chain": verify_affine_chain(),
        "failures": 0,
        "claim": (
            "exact h169 k27 residue-state closure: 132 raw states with 44 misses; "
            "behavioral minimization gives 30 classes, namely 29 survivor classes "
            "and one absorbing terminal hit class"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
