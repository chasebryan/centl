#!/usr/bin/env python3
"""Independent exact-state verification of the h169 k35 two-branch survivor theorem."""
from __future__ import annotations

import argparse
import json
import math
from collections import deque

K = 35
UNITS = tuple(r for r in range(1, K) if math.gcd(r, K) == 1)
TYPE_I_TARGET = (-pow(4, -1, K)) % K
FINAL_CENTER = 16
TYPE_II_TARGET = (-FINAL_CENTER) % K

State = tuple[frozenset[int], int]


def legendre(a: int, p: int) -> int:
    a %= p
    if a == 0:
        return 0
    return 1 if pow(a, (p - 1) // 2, p) == 1 else -1


def h35() -> frozenset[int]:
    return frozenset(
        r for r in UNITS if legendre(r, 5) * legendre(r, 7) == 1
    )


def seed_state() -> State:
    return frozenset({1, 3, 9}), 3


def transition35(state: State, r: int) -> State:
    mask, center = state
    powers = {1, r % 35, r * r % 35}
    return (
        frozenset(a * b % 35 for a in mask for b in powers),
        center * r % 35,
    )


def status35(state: State) -> tuple[bool, bool]:
    mask, center = state
    return TYPE_I_TARGET in mask, (-center) % 35 in mask


def is_hit35(state: State) -> bool:
    return any(status35(state))


def closure35(starts: set[State], alphabet: tuple[int, ...]) -> set[State]:
    seen = set(starts)
    queue = deque(starts)
    while queue:
        state = queue.popleft()
        for r in alphabet:
            nxt = transition35(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def transition7(state: State, r: int) -> State:
    mask, center = state
    powers = {1, r % 7, r * r % 7}
    return (
        frozenset(a * b % 7 for a in mask for b in powers),
        center * r % 7,
    )


def closure7(starts: set[State]) -> set[State]:
    seen = set(starts)
    queue = deque(starts)
    while queue:
        state = queue.popleft()
        for r in range(1, 7):
            nxt = transition7(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def verify_full_endpoint() -> dict[str, object]:
    states = closure35({seed_state()}, UNITS)
    assert len(states) == 394

    endpoints = {state for state in states if state[1] == FINAL_CENTER}
    misses = {state for state in endpoints if not is_hit35(state)}
    hits = endpoints - misses
    assert (len(endpoints), len(hits), len(misses)) == (14, 8, 6)

    safe7 = frozenset({1, 2, 3, 4, 6})
    full7 = frozenset(range(1, 7))
    by_projection: dict[frozenset[int], set[State]] = {}
    for state in misses:
        proj = frozenset(x % 7 for x in state[0])
        by_projection.setdefault(proj, set()).add(state)
    assert set(by_projection) == {safe7, full7}
    assert len(by_projection[safe7]) == 5
    assert len(by_projection[full7]) == 1

    H = h35()
    assert H == frozenset({1, 3, 4, 9, 11, 12, 13, 16, 17, 27, 29, 33})
    exceptional = next(iter(by_projection[full7]))
    assert exceptional[0] == H

    assert len(H) == 12
    assert all((a * b) % 35 in H for a in H for b in H)
    assert all(pow(a, -1, 35) in H for a in H)
    assert 3 in H
    assert TYPE_I_TARGET not in H
    assert TYPE_II_TARGET not in H

    raw_hits = {state for state in states if is_hit35(state)}
    for state in raw_hits:
        for r in UNITS:
            assert is_hit35(transition35(state, r))

    return {
        "raw_states": len(states),
        "h169_center16_endpoints": len(endpoints),
        "endpoint_hits": len(hits),
        "endpoint_misses": len(misses),
        "safe_mod7_misses": len(by_projection[safe7]),
        "full_mod7_misses": len(by_projection[full7]),
        "exceptional_mask": sorted(exceptional[0]),
        "H35": sorted(H),
    }


def verify_mod7_safe_branch() -> dict[str, object]:
    seed = (frozenset({1, 2, 3}), 3)
    safe = transition7(seed, 3)
    assert safe == (frozenset({1, 2, 3, 4, 6}), 2)

    for r in range(1, 7):
        seed_next = transition7(seed, r)
        if r == 1:
            assert seed_next == seed
        elif r == 3:
            assert seed_next == safe
        else:
            assert 5 in seed_next[0]

        safe_next = transition7(safe, r)
        if r == 1:
            assert safe_next == safe
        else:
            assert 5 in safe_next[0]

    states = closure7({seed})
    assert len(states) == 9
    final = {state for state in states if state[1] == 2}
    expected_final = {
        (frozenset({1, 2, 3, 4, 6}), 2),
        (frozenset({1, 2, 3, 4, 5, 6}), 2),
    }
    assert final == expected_final

    return {
        "mod7_states": len(states),
        "final_center2_masks": [
            sorted(state[0]) for state in sorted(final, key=lambda s: len(s[0]))
        ],
        "safe_factor_pattern": (
            "exactly one prime-factor occurrence 3 mod7; every other occurrence 1 mod7"
        ),
    }


def verify_character_branch() -> dict[str, object]:
    H = h35()
    outside = frozenset(set(UNITS) - set(H))
    assert all(legendre(r, 5) == legendre(r, 7) for r in H)
    assert all(legendre(r, 5) == -legendre(r, 7) for r in outside)
    assert TYPE_I_TARGET == 26
    assert TYPE_II_TARGET == 19
    assert TYPE_I_TARGET % 7 == TYPE_II_TARGET % 7 == 5
    assert TYPE_I_TARGET in outside and TYPE_II_TARGET in outside

    h_states = closure35({seed_state()}, tuple(sorted(H)))
    assert all(mask.issubset(H) for mask, _center in h_states)
    assert all(not is_hit35(state) for state in h_states)

    return {
        "H35_size": len(H),
        "outside_size": len(outside),
        "targets": [TYPE_I_TARGET, TYPE_II_TARGET],
        "H35_only_closure_states": len(h_states),
    }


def verify_affine_chain() -> dict[str, object]:
    for t in range(5 * 7 * 31):
        p = 169 + 840 * t
        B = 8 + 35 * t
        E = 7 + 30 * t
        D = 5 + 21 * t
        F = 17 + 70 * t
        assert (p + 23) // 4 == 6 * B
        assert (p + 27) // 4 == 7 * E
        assert (p + 31) // 4 == 10 * D
        assert (p + 35) // 4 == 3 * F
        assert F % 35 == 17
        assert F - 2 * B == 1
        assert 7 * E - 6 * B == 1
        assert 10 * D - 7 * E == 1
        assert 5 * D - 3 * B == 1
        assert 3 * F - 7 * E == 2
        assert 3 * F - 10 * D == 1
        values = (B, E, D, F)
        assert all(
            math.gcd(values[i], values[j]) == 1
            for i in range(4)
            for j in range(i + 1, 4)
        )
    return {
        "t_values_checked": 5 * 7 * 31,
        "pairwise_coprime_B_E_D_F": True,
        "relations": [
            "F-2B=1",
            "7E-6B=1",
            "10D-7E=1",
            "5D-3B=1",
            "3F-7E=2",
            "3F-10D=1",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "h169-k35-two-branch-survivor-theorem-v1",
        "endpoint": verify_full_endpoint(),
        "mod7_safe_branch": verify_mod7_safe_branch(),
        "character_branch": verify_character_branch(),
        "affine_chain": verify_affine_chain(),
        "failures": 0,
        "claim": (
            "exact h169 k35 miss iff J35(F) or S7(F): either every prime factor "
            "has equal quadratic characters mod5 and mod7, or F has exactly one "
            "prime-factor occurrence 3 mod7 and all others 1 mod7"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
