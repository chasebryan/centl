#!/usr/bin/env python3
"""Independent exact-state verification of the Route-B k47 survivor normal form."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

K = 47
UNITS = tuple(range(1, K))
QR = frozenset(pow(x, 2, K) for x in UNITS)
NR = frozenset(set(UNITS) - set(QR))
TYPE_I_TARGET = (-pow(4, -1, K)) % K
ROUTE_CENTER = 7
TYPE_II_TARGET = (-ROUTE_CENTER) % K

FULL_QR = frozenset({
    1, 2, 3, 4, 6, 7, 8, 9, 12, 14, 16, 17, 18, 21, 24, 25,
    27, 28, 32, 34, 36, 37, 42,
})
THIN = frozenset({
    1, 2, 3, 4, 6, 7, 8, 9, 12, 14, 16, 18, 21, 24, 27, 32,
    34, 36, 42,
})
SEED_MASK = frozenset({1, 2, 3, 4, 6, 9, 12, 18, 36})
MID_MASK = frozenset({1, 2, 3, 4, 6, 7, 9, 12, 14, 18, 21, 27, 34, 36, 42})

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
    state: State = (frozenset({1}), 1)
    for q in (2, 3):
        state = transition(state, q)
    return state


def status(state: State) -> tuple[bool, bool]:
    mask, center = state
    return TYPE_I_TARGET in mask, (-center) % K in mask


def is_hit(state: State) -> bool:
    return any(status(state))


def closure(alphabet: tuple[int, ...]) -> frozenset[State]:
    start = seed_state()
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for r in alphabet:
            nxt = transition(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def verify_route_parameterization() -> dict[str, object]:
    for u in range(1081):
        t = 705 + 1081 * u
        p = 169 + 840 * t
        R = 137 + 210 * u
        B = 8 + 35 * t
        J = 9 + 35 * t

        assert p % 840 == 169
        assert p % 23 == 4
        assert p % 47 == 28
        assert t % 47 == 0

        C19 = (p + 19) // 4
        C23 = (p + 23) // 4
        C47 = (p + 47) // 4
        assert C19 == 1081 * R
        assert C23 == 6 * B
        assert C47 == 6 * J
        assert J == B + 1

        assert B % 47 == 8
        assert J % 47 == 9
        assert C47 % 47 == ROUTE_CENTER
        assert J % 47 != 0

        assert 6 * B - 1081 * R == 1
        assert 6 * J - 1081 * R == 7
        assert R % 7 == 4
        assert math.gcd(B, J) == 1
        assert math.gcd(R, J) == 1

    return {
        "route_instances_checked": 1081,
        "t_mod47": 0,
        "B_mod47": 8,
        "J_mod47": 9,
        "C47_mod47": ROUTE_CENTER,
        "J_equals_B_plus_1": True,
        "gcd_B_J": 1,
        "gcd_R_J": 1,
    }


def verify_full_closure() -> dict[str, object]:
    assert QR == FULL_QR
    assert len(QR) == 23
    assert len(NR) == 23
    assert TYPE_I_TARGET == 35
    assert TYPE_II_TARGET == 40
    assert TYPE_I_TARGET in NR
    assert TYPE_II_TARGET in NR
    assert 2 in QR and 3 in QR

    start = seed_state()
    assert start == (SEED_MASK, 6)

    states = closure(UNITS)
    misses = {state for state in states if not is_hit(state)}
    hits = states - misses
    assert len(states) == 1079
    assert len(misses) == 196
    assert len(hits) == 883

    mechanism = Counter()
    for state in states:
        type_i, type_ii = status(state)
        if type_i and type_ii:
            mechanism["I+II"] += 1
        elif type_i:
            mechanism["I-only"] += 1
        elif type_ii:
            mechanism["II-only"] += 1
        else:
            mechanism["miss"] += 1
    assert mechanism == Counter({"I+II": 594, "miss": 196, "I-only": 221, "II-only": 68})

    route_misses = {state for state in misses if state[1] == ROUTE_CENTER}
    assert route_misses == {(FULL_QR, ROUTE_CENTER), (THIN, ROUTE_CENTER)}
    assert THIN == FULL_QR - {17, 25, 28, 37}
    assert len(THIN) == 19

    # Exact witnesses persist and masks are monotone under every future factor.
    for state in states:
        mask, _center = state
        for r in UNITS:
            nxt = transition(state, r)
            assert mask.issubset(nxt[0])
            if is_hit(state):
                assert is_hit(nxt)

    # State-level converse engine for the QR-support theorem: every center-7
    # miss mask is contained in QR47, so a nonresidue prime-factor residue in
    # the divisor mask is incompatible with a miss.
    assert all(mask.issubset(QR) for mask, _center in route_misses)
    for state in states:
        if state[1] == ROUTE_CENTER and not state[0].issubset(QR):
            assert is_hit(state)

    return {
        "states": len(states),
        "hits": len(hits),
        "misses": len(misses),
        "mechanisms": dict(mechanism),
        "route_center": ROUTE_CENTER,
        "route_center_misses": 2,
        "full_qr_mask_size": len(FULL_QR),
        "thin_mask_size": len(THIN),
        "thin_missing_qr_residues": sorted(FULL_QR - THIN),
    }


def verify_qr_support_and_thin_grammar() -> dict[str, object]:
    qr_alphabet = tuple(sorted(QR))
    states = closure(qr_alphabet)
    assert len(states) == 66

    center7 = {state for state in states if state[1] == ROUTE_CENTER}
    assert center7 == {(FULL_QR, ROUTE_CENTER), (THIN, ROUTE_CENTER)}
    assert all(not is_hit(state) for state in center7)

    # Factor insertion commutes on the exact QR state graph.
    for state in states:
        for r in qr_alphabet:
            for s in qr_alphabet:
                assert transition(transition(state, r), s) == transition(transition(state, s), r)

    start = seed_state()
    mid = transition(start, 3)
    thin_from_9 = transition(start, 9)
    thin_from_33 = transition(mid, 3)
    assert mid == (MID_MASK, 18)
    assert thin_from_9 == (THIN, ROUTE_CENTER)
    assert thin_from_33 == (THIN, ROUTE_CENTER)

    safe_states = {state for state in states if state[0].issubset(THIN)}
    assert safe_states == {start, mid, (THIN, ROUTE_CENTER)}

    labels = {
        start: "SEED",
        mid: "MID",
        (THIN, ROUTE_CENTER): "THIN",
    }
    expected_safe = {
        "SEED": {1: "SEED", 3: "MID", 9: "THIN"},
        "MID": {1: "MID", 3: "THIN"},
        "THIN": {1: "THIN"},
    }
    actual_safe: dict[str, dict[int, str]] = {}
    for state, label in labels.items():
        row: dict[int, str] = {}
        for r in qr_alphabet:
            nxt = transition(state, r)
            if nxt[0].issubset(THIN):
                assert nxt in labels
                row[r] = labels[nxt]
        actual_safe[label] = row
    assert actual_safe == expected_safe

    # These three safe states plus commutativity and monotone masks prove the
    # exact THIN grammar: after deleting residue-1 occurrences, the only
    # possible multisets are {9} or {3,3}.
    return {
        "qr_only_states": len(states),
        "qr_center7_states": len(center7),
        "safe_states_inside_thin": len(safe_states),
        "safe_transition_table": actual_safe,
        "thin_non1_occurrence_multisets": [[9], [3, 3]],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "route-b-k47-survivor-normal-form-v1",
        "route": verify_route_parameterization(),
        "full_closure": verify_full_closure(),
        "qr_support_and_thin_grammar": verify_qr_support_and_thin_grammar(),
        "failures": 0,
        "claim": (
            "on realized Route B, k47 misses iff every prime factor of J=B+1 "
            "is QR mod47; the miss state is exactly THIN or FULL_QR, and THIN "
            "occurs iff the non-1 prime-factor occurrence residues are {9} or {3,3}"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
