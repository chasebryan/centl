#!/usr/bin/env python3
"""Independent exact-state verification of the Route-A k51 sector normal form."""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import Counter, deque

K51 = 51
UNITS51 = tuple(r for r in range(1, K51) if math.gcd(r, K51) == 1)
TYPE_I_51 = (-pow(4, -1, K51)) % K51
ROUTE_CENTER_51 = 25
TYPE_II_51 = (-ROUTE_CENTER_51) % K51
SINGLE_KILLERS = frozenset({10, 26, 28, 38, 46, 50})

CORR5 = frozenset({
    frozenset({1,2,4,5,7,10,11,13,16,23,25,29,31,32,35,37,43,47}),
    frozenset({1,2,4,5,7,13,16,19,20,22,23,25,31,32,35,40,44,47,49}),
    frozenset({1,2,4,5,7,8,13,14,16,19,20,22,23,25,31,32,35,40,41,44,47,49}),
    frozenset({1,2,4,5,7,8,10,13,14,16,19,20,22,23,25,31,32,35,37,40,41,44,47,49}),
    frozenset({1,2,4,5,7,10,11,13,16,19,20,22,23,25,29,31,32,35,37,40,43,44,47,49}),
})

CORR_REACHABILITY = (
    (37, 47),
    (32, 40),
    (5, 8, 32),
    (7, 7, 23),
    (5, 37, 40),
)

State = tuple[frozenset[int], int]


def transition(k: int, state: State, residue: int) -> State:
    mask, center = state
    r = residue % k
    powers = {1, r, r * r % k}
    return (
        frozenset(a * b % k for a in mask for b in powers),
        center * r % k,
    )


def seed51() -> State:
    return transition(51, (frozenset({1}), 1), 5)


def hit51(state: State) -> tuple[bool, bool]:
    mask, center = state
    return TYPE_I_51 in mask, (-center) % 51 in mask


def is_hit51(state: State) -> bool:
    return any(hit51(state))


def closure(k: int, starts: set[State], alphabet: tuple[int, ...]) -> frozenset[State]:
    seen = set(starts)
    queue = deque(starts)
    while queue:
        state = queue.popleft()
        for r in alphabet:
            nxt = transition(k, state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def legendre(a: int, p: int) -> int:
    a %= p
    assert a != 0
    return 1 if pow(a, (p - 1) // 2, p) == 1 else -1


def h51() -> frozenset[int]:
    return frozenset(
        r for r in UNITS51 if legendre(r, 3) * legendre(r, 17) == 1
    )


def route_state_from_occurrences(occurrences: tuple[int, ...]) -> State:
    state = seed51()
    for r in occurrences:
        state = transition(51, state, r)
    return state


def verify_route_parameterization() -> dict[str, object]:
    for u in range(51 * 17):
        t = 199 + 391 * u
        p = 169 + 840 * t
        R = 107 + 210 * u
        K = 11 + 42 * t
        C19 = (p + 19) // 4
        C51 = (p + 51) // 4
        assert p % 840 == 169
        assert p % 17 == 15
        assert p % 23 == 4
        assert C19 == 391 * R
        assert C51 == 5 * K
        assert K == 8369 + 16422 * u
        assert K % 51 == 5
        assert math.gcd(K, 51) == 1
        assert C51 % 51 == ROUTE_CENTER_51
        assert 5 * K - 391 * R == 8
        assert math.gcd(R, K) == 1
    return {
        "route_instances_checked": 51 * 17,
        "t_parameter": "199+391u",
        "K_mod51": 5,
        "C51_mod51": ROUTE_CENTER_51,
        "gcd_R_K": 1,
    }


def verify_full_closure() -> tuple[dict[str, object], frozenset[State]]:
    assert seed51() == (frozenset({1, 5, 25}), 5)
    assert TYPE_I_51 == 38
    assert TYPE_II_51 == 26

    states = closure(51, {seed51()}, UNITS51)
    route_misses = frozenset(
        state for state in states
        if state[1] == ROUTE_CENTER_51 and not is_hit51(state)
    )
    assert len(states) == 1403
    assert len(route_misses) == 14

    # Hit persistence and mask monotonicity are checked over the entire graph.
    for state in states:
        mask, _center = state
        for r in UNITS51:
            nxt = transition(51, state, r)
            assert mask.issubset(nxt[0])
            if is_hit51(state):
                assert is_hit51(nxt)

    killers = frozenset(r for r in UNITS51 if is_hit51(transition(51, seed51(), r)))
    assert killers == SINGLE_KILLERS
    mechanisms = {}
    for r in sorted(killers):
        ti, tii = hit51(transition(51, seed51(), r))
        mechanisms[r] = "I" if ti and not tii else "II" if tii and not ti else "I+II"
    assert mechanisms == {10:"II", 26:"I", 28:"I", 38:"I", 46:"II", 50:"II"}

    return ({
        "states": len(states),
        "route_center_misses": len(route_misses),
        "single_occurrence_killers": sorted(killers),
        "single_killer_mechanisms": mechanisms,
    }, route_misses)


def verify_character_sector(route_misses: frozenset[State]) -> dict[str, object]:
    H = h51()
    expected = frozenset({1,4,5,11,13,14,16,19,20,23,25,29,41,43,44,49})
    assert H == expected
    assert len(H) == 16
    assert 5 in H
    assert TYPE_I_51 not in H
    assert TYPE_II_51 not in H
    assert all((a * b) % 51 in H for a in H for b in H)
    assert all(pow(a, -1, 51) in H for a in H)

    h_states = closure(51, {seed51()}, tuple(sorted(H)))
    h_endpoints = frozenset(state for state in h_states if state[1] == ROUTE_CENTER_51)
    assert len(h_states) == 88
    assert len(h_endpoints) == 6
    assert all(not is_hit51(state) for state in h_endpoints)
    assert all(mask.issubset(H) for mask, _center in h_endpoints)

    full_h_masks = frozenset(
        state for state in route_misses if state[0].issubset(H)
    )
    assert full_h_masks == h_endpoints

    return {
        "H51": sorted(H),
        "H51_size": len(H),
        "H51_closure_states": len(h_states),
        "route_H51_miss_masks": len(h_endpoints),
    }


def transition17(state: State, residue: int) -> State:
    return transition(17, state, residue)


def seed17() -> State:
    return (frozenset({1, 5, 8}), 5)


def hit17(state: State) -> bool:
    mask, _center = state
    return 4 in mask or 9 in mask


def state17(occurrences: tuple[int, ...]) -> State:
    state = seed17()
    for r in occurrences:
        state = transition17(state, r)
    return state


def verify_mod17_sector(route_misses: frozenset[State]) -> dict[str, object]:
    units17 = tuple(range(1, 17))
    qr17 = frozenset(pow(x, 2, 17) for x in units17)
    nr17 = frozenset(set(units17) - set(qr17))
    assert qr17 == frozenset({1,2,4,8,9,13,15,16})
    assert nr17 == frozenset({3,5,6,7,10,11,12,14})

    states17 = closure(17, {seed17()}, units17)
    endpoint17 = frozenset(state for state in states17 if state[1] == 8)
    safe_endpoint17 = frozenset(state for state in endpoint17 if not hit17(state))
    assert len(states17) == 88
    assert len(endpoint17) == 6
    assert safe_endpoint17 == frozenset({
        (frozenset({1,5,6,8,13}), 8),
        (frozenset({1,2,5,6,7,8,13,14,15}), 8),
    })

    survivor_skeletons: dict[int, frozenset[tuple[int, ...]]] = {}
    for size in range(5):
        survivors = frozenset(
            tuple(comb)
            for comb in itertools.combinations_with_replacement(sorted(nr17), size)
            if not hit17(state17(tuple(comb)))
        )
        survivor_skeletons[size] = survivors
    assert {n: len(v) for n, v in survivor_skeletons.items()} == {0:1, 1:4, 2:3, 3:2, 4:0}
    assert survivor_skeletons[1] == frozenset({(5,), (6,), (7,), (10,)})
    assert survivor_skeletons[3] == frozenset({(5,5,5), (5,5,7)})

    # K=5 mod17 is a nonresidue, so only odd NR skeleton sizes can occur.
    odd_skeletons = tuple(sorted(survivor_skeletons[1] | survivor_skeletons[3]))
    skeleton_states = {state17(sk) for sk in odd_skeletons}
    qr_states = closure(17, skeleton_states, tuple(sorted(qr17)))
    safe_qr_states = frozenset(state for state in qr_states if not hit17(state))
    assert len(safe_qr_states) == 5

    n5 = state17((5,))
    n6 = state17((6,))
    n7 = state17((7,))
    n10 = state17((10,))
    n555 = state17((5,5,5))
    n557 = state17((5,5,7))
    assert n6 == n555

    # Pin the complete target-avoiding QR continuation graph needed for the
    # fixed final product. All unspecified QR transitions hit.
    safe_rows = {}
    for label, state in {
        "N5": n5,
        "N6": n6,
        "N7": n7,
        "N10": n10,
        "N557": n557,
    }.items():
        row = {}
        for r in sorted(qr17):
            nxt = transition17(state, r)
            if not hit17(nxt):
                row[r] = (nxt[1], len(nxt[0]))
        safe_rows[label] = row
    assert safe_rows == {
        "N5": {1:(8,5), 8:(13,9)},
        "N6": {1:(13,9)},
        "N7": {1:(1,5), 8:(8,9)},
        "N10": {1:(16,8)},
        "N557": {1:(8,9)},
    }

    accepted_patterns = ((5,), (5,5,7), (7,8))
    for pattern in accepted_patterns:
        state = state17(pattern)
        assert state[1] == 8
        assert not hit17(state)
        product = math.prod(pattern) % 17
        assert product == 5

    # Exactly five full Route-A miss masks have target-free mod17 projection.
    mod17_safe_full = frozenset(
        state for state in route_misses
        if 4 not in {x % 17 for x in state[0]}
        and 9 not in {x % 17 for x in state[0]}
    )
    assert len(mod17_safe_full) == 5

    return {
        "mod17_states": len(states17),
        "mod17_center8_endpoints": len(endpoint17),
        "mod17_safe_endpoints": len(safe_endpoint17),
        "nr_survivor_counts": {str(n): len(v) for n, v in survivor_skeletons.items()},
        "accepted_non1_occurrence_patterns": [list(x) for x in accepted_patterns],
        "full_route_S17_miss_masks": len(mod17_safe_full),
    }


def verify_sector_union(route_misses: frozenset[State]) -> dict[str, object]:
    H = h51()
    h_sector = frozenset(state for state in route_misses if state[0].issubset(H))
    s17_sector = frozenset(
        state for state in route_misses
        if 4 not in {x % 17 for x in state[0]}
        and 9 not in {x % 17 for x in state[0]}
    )
    overlap = h_sector & s17_sector
    explained = h_sector | s17_sector
    residual = frozenset(state[0] for state in route_misses - explained)
    assert (len(h_sector), len(s17_sector), len(overlap), len(explained)) == (6,5,2,9)
    assert residual == CORR5

    reached = set()
    for skeleton in CORR_REACHABILITY:
        assert math.prod(skeleton) % 51 == 5
        state = route_state_from_occurrences(tuple(skeleton))
        assert state[1] == ROUTE_CENTER_51
        assert not is_hit51(state)
        assert state[0] in CORR5
        reached.add(state[0])
    assert reached == set(CORR5)

    return {
        "H51_masks": len(h_sector),
        "S17_masks": len(s17_sector),
        "overlap_masks": len(overlap),
        "explained_union_masks": len(explained),
        "CORR5_masks": len(residual),
        "CORR5_sizes": sorted(len(mask) for mask in residual),
        "CORR5_short_reachability_skeletons": [list(x) for x in CORR_REACHABILITY],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    full, route_misses = verify_full_closure()
    report = {
        "analysis": "route-a-k51-sector-normal-form-v1",
        "route": verify_route_parameterization(),
        "full_closure": full,
        "character_sector": verify_character_sector(route_misses),
        "mod17_sector": verify_mod17_sector(route_misses),
        "sector_union": verify_sector_union(route_misses),
        "failures": 0,
        "claim": (
            "Route-A k51 center25 has 14 exact miss masks; H51 and the exact S17 "
            "factor grammar explain 9 of them, leaving exactly five CRT-correlation "
            "modes, while six single factor residue classes are immediate killers"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
