#!/usr/bin/env python3
"""Exact regression for the k=47 companion-factor absorption theorem.

This checks only algebraic/group-theoretic statements. It does not use a finite
prime range and does not prove Erdős-Straus beyond the states explicitly
absorbed by the theorem.
"""
from __future__ import annotations

from collections import Counter
from fractions import Fraction
import math

import classify_k47_forced6_states as hard
import classify_k47_states as core

Q = 47
ONE_PACKET_DIRECTIONS = (1, 7, 9, 11, 17, 19, 27, 29, 35, 37, 45)
ABSORPTION = {
    3: {"gap": 11, "center_log": 7},
    7: {"gap": 10, "center_log": 19},
    27: {"gap": 5, "center_log": 1},
}
EXPECTED_CENTER_COUNTS = {
    1: 13,
    3: 2,
    9: 7,
    11: 9,
    19: 13,
    21: 3,
    27: 3,
    29: 11,
    37: 10,
    39: 6,
    45: 3,
}
EXPECTED_AFTER_BY_DIRECTION = {
    1: 6,
    7: 1,
    9: 7,
    11: 2,
    17: 5,
    19: 7,
    27: 6,
    29: 3,
    35: 3,
    37: 8,
    45: 6,
}


def closure_from(start: tuple[int, int], directions) -> set[tuple[int, int]]:
    seen = {start}
    todo = [start]
    while todo:
        state = todo.pop()
        for a in directions:
            nxt = core.transition(state, a)
            if nxt not in seen:
                seen.add(nxt)
                todo.append(nxt)
    return seen


def one_packet_classes() -> dict[int, set[tuple[int, int]]]:
    seed = hard.forced_start()
    even = tuple(range(0, core.N, 2))
    return {
        r: {
            state
            for state in closure_from(core.transition(seed, r), even)
            if core.is_miss(state)
        }
        for r in ONE_PACKET_DIRECTIONS
    }


def check_generic_trigger_modular() -> None:
    assert 4 * Q + 1 == 189
    for k, row in ABSORPTION.items():
        assert k % 4 == 3
        assert 189 % k == 0
        assert (Q - k) // 4 == row["gap"]
        assert core.LOG[row["gap"]] == row["center_log"]
        assert (4 * Q + 1) % k == 0

        # If C_k = Q*t, then p = 4*Q*t-k.  Modulo k, p == -t.
        # The signed-box element Q/C_k == 1/t must therefore equal -p^-1.
        for t in range(1, k + 1):
            if math.gcd(t, k) != 1:
                continue
            pmod = (4 * Q * t - k) % k
            assert pmod == (-t) % k
            ratio = pow(t, -1, k)
            type_i = (-pow(pmod, -1, k)) % k
            assert ratio == type_i


def check_explicit_type_i_identity() -> None:
    for k in ABSORPTION:
        scale = 189 // k
        for t in range(1, 101):
            p = 188 * t - k
            A = scale * t - 1
            assert A == (t + p) // k
            assert (t + p) % k == 0
            lhs = Fraction(4, p)
            rhs = (
                Fraction(1, A * Q * p)
                + Fraction(1, Q * t)
                + Fraction(1, A * Q * t)
            )
            assert lhs == rhs


def check_abstract_k47_reduction() -> None:
    negative_misses = {
        state
        for state in hard.closure()
        if core.is_miss(state) and state[1] % 2 == 1
    }
    assert len(negative_misses) == 80

    center_counts = Counter(center for _mask, center in negative_misses)
    assert dict(sorted(center_counts.items())) == EXPECTED_CENTER_COUNTS
    assert center_counts[7] == 0
    assert center_counts[19] == 13
    assert center_counts[1] == 13

    killed_centers = {1, 19}
    surviving = {state for state in negative_misses if state[1] not in killed_centers}
    assert len(surviving) == 54

    classes = one_packet_classes()
    union = set().union(*classes.values())
    assert union == negative_misses
    multiplicity = Counter(
        sum(state in classes[r] for r in ONE_PACKET_DIRECTIONS)
        for state in negative_misses
    )
    assert multiplicity == Counter({1: 80})

    after = {
        r: sum(state in surviving for state in classes[r])
        for r in ONE_PACKET_DIRECTIONS
    }
    assert after == EXPECTED_AFTER_BY_DIRECTION
    assert sum(after.values()) == 54

    print("OK generic divisor trigger for d=47 and k=3,7,27")
    print("OK explicit Type-I identities")
    print(f"OK abstract k47 negative miss reduction: 80 -> {len(surviving)}")
    print(f"surviving one-packet counts: {after}")


def main() -> int:
    check_generic_trigger_modular()
    check_explicit_type_i_identity()
    check_abstract_k47_reduction()
    print("ALL CHECKS PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
