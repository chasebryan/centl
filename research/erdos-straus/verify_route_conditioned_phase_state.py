#!/usr/bin/env python3
"""Verify route-local endpoint modes and Route-B parity/support coupling."""
from __future__ import annotations

import argparse
import json
import math
from collections import deque
from fractions import Fraction

QR19 = frozenset(pow(x, 2, 19) for x in range(1, 19))
QR31 = frozenset(pow(x, 2, 31) for x in range(1, 31))
S19 = frozenset(t for t in range(19) if (9 + t) % 19 in QR19)
S31 = frozenset(t for t in range(31) if (5 + 21 * t) % 31 in QR31)
S39 = frozenset({1, 2, 5, 6, 7, 8, 9, 10, 11})
S43 = frozenset(set(range(43)) - {2, 28, 30})
S47 = frozenset(set(range(47)) - {1, 5, 6, 10, 13, 21, 23, 36, 37, 38, 40, 42, 44})
S51 = frozenset(set(range(17)) - {4, 5, 7, 14})
S55 = frozenset(set(range(11)) - {5, 6, 7, 10})

ROUTE_A_T0 = 199
ROUTE_A_STEP = 391
ROUTE_B_T0 = 705
ROUTE_B_STEP = 1081

State = tuple[frozenset[int], int]


def transition(k: int, state: State, residue: int) -> State:
    mask, center = state
    r = residue % k
    powers = {1, r, r * r % k}
    return (
        frozenset(a * b % k for a in mask for b in powers),
        center * r % k,
    )


def closure(k: int, seed_factors: tuple[int, ...]) -> frozenset[State]:
    alphabet = tuple(r for r in range(1, k) if math.gcd(r, k) == 1)
    state: State = (frozenset({1}), 1)
    for q in seed_factors:
        state = transition(k, state, q)
    seen = {state}
    queue = deque([state])
    while queue:
        current = queue.popleft()
        for r in alphabet:
            nxt = transition(k, current, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def is_hit(k: int, state: State) -> bool:
    mask, center = state
    type_i_target = (-pow(4, -1, k)) % k
    return type_i_target in mask or (-center) % k in mask


def verify_fixed_route_endpoints() -> dict[str, object]:
    assert ROUTE_A_T0 % 17 == 12
    assert ROUTE_A_STEP % 17 == 0
    assert 12 in S51
    center51 = (55 + 210 * 12) % 51
    assert center51 == 25
    states51 = closure(51, (5,))
    misses51 = {
        state for state in states51
        if state[1] == center51 and not is_hit(51, state)
    }
    assert len(states51) == 1403
    assert len(misses51) == 14

    assert ROUTE_B_T0 % 47 == 0
    assert ROUTE_B_STEP % 47 == 0
    assert 0 in S47
    center47 = (54 + 210 * ROUTE_B_T0) % 47
    assert center47 == 7
    states47 = closure(47, (2, 3))
    misses47 = {
        state for state in states47
        if state[1] == center47 and not is_hit(47, state)
    }
    assert len(states47) == 1079
    assert len(misses47) == 2
    assert sorted(len(mask) for mask, _center in misses47) == [19, 23]

    return {
        "route_a": {
            "fixed_t_mod17": 12,
            "k51_center": center51,
            "k51_endpoint_misses": len(misses51),
        },
        "route_b": {
            "fixed_t_mod47": 0,
            "k47_center": center47,
            "k47_endpoint_misses": len(misses47),
            "k47_modes": ["THIN", "FULL_QR"],
        },
    }


def mapped_count(t0: int, step: int, modulus: int, allowed: frozenset[int]) -> int:
    assert math.gcd(step, modulus) == 1
    return sum((t0 + step * u) % modulus in allowed for u in range(modulus))


def verify_strong_route_phase_envelopes() -> dict[str, object]:
    assert QR19 == frozenset({1, 4, 5, 6, 7, 9, 11, 16, 17})
    assert QR31 == frozenset({1, 2, 4, 5, 7, 8, 9, 10, 14, 16, 18, 19, 20, 25, 28})
    assert S19 == frozenset({0, 2, 7, 8, 11, 14, 15, 16, 17})
    assert S31 == frozenset({0, 2, 6, 7, 8, 9, 11, 12, 14, 15, 19, 22, 27, 28, 29})

    route_a_filters = (
        (19, S19), (31, S31), (13, S39), (43, S43), (47, S47), (11, S55)
    )
    route_b_filters = (
        (19, S19), (31, S31), (13, S39), (43, S43), (17, S51), (11, S55)
    )

    for modulus, allowed in route_a_filters:
        assert mapped_count(ROUTE_A_T0, ROUTE_A_STEP, modulus, allowed) == len(allowed)
    for modulus, allowed in route_b_filters:
        assert mapped_count(ROUTE_B_T0, ROUTE_B_STEP, modulus, allowed) == len(allowed)

    ma = math.prod(modulus for modulus, _allowed in route_a_filters)
    mb = math.prod(modulus for modulus, _allowed in route_b_filters)
    na = math.prod(len(allowed) for _modulus, allowed in route_a_filters)
    nb = math.prod(len(allowed) for _modulus, allowed in route_b_filters)
    assert (ma, na) == (170_222_767, 11_566_800)
    assert (mb, nb) == (61_569_937, 4_422_600)

    fa = Fraction(na, ma)
    fb = Fraction(nb, mb)
    assert fa == Fraction(11_566_800, 170_222_767)
    assert fb == Fraction(340_200, 4_736_149)

    return {
        "route_a": {
            "phase_modulus": ma,
            "survivor_classes": na,
            "fraction_reduced": f"{fa.numerator}/{fa.denominator}",
            "fraction": float(fa),
        },
        "route_b": {
            "phase_modulus": mb,
            "survivor_classes": nb,
            "count_ratio": f"{nb}/{mb}",
            "fraction_reduced": f"{fb.numerator}/{fb.denominator}",
            "fraction": float(fb),
        },
    }


def verify_route_b_mode_parity() -> dict[str, object]:
    # THIN permits residue-1 occurrences plus exactly {9} or {3,3}; rational
    # prime2 has residue2 mod47, so any even J is incompatible with THIN.
    assert 2 % 47 not in {1, 3, 9}

    for u in range(2 * 47):
        t = ROUTE_B_T0 + ROUTE_B_STEP * u
        D = 5 + 21 * t
        J = 9 + 35 * t
        assert (J % 2 == 1) == (t % 2 == 0)
        assert (t % 2 == 0) == (u % 2 == 1)
        assert math.gcd(D, J) == math.gcd(2, t + 1)
        if t % 2:
            assert J % 2 == 0 and D % 2 == 0
            assert math.gcd(D, J) == 2
        else:
            assert J % 2 == 1 and D % 2 == 1
            assert math.gcd(D, J) == 1

    mb = 61_569_937
    nb = 4_422_600
    thin_modulus = 2 * mb
    thin_classes = nb
    thin_fraction = Fraction(thin_classes, thin_modulus)
    assert thin_modulus == 123_139_874
    assert thin_fraction == Fraction(170_100, 4_736_149)

    return {
        "thin_requires_t_even": True,
        "thin_requires_u_odd": True,
        "t_odd_forces_full_qr": True,
        "t_odd_gcd_D_J": 2,
        "t_even_gcd_D_J": 1,
        "thin_phase_parity_modulus": thin_modulus,
        "thin_phase_parity_classes": thin_classes,
        "thin_phase_parity_fraction_reduced": f"{thin_fraction.numerator}/{thin_fraction.denominator}",
        "thin_phase_parity_fraction": float(thin_fraction),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "route-conditioned-phase-mode-state-v2",
        "fixed_route_endpoints": verify_fixed_route_endpoints(),
        "strong_route_phase_envelopes": verify_strong_route_phase_envelopes(),
        "route_b_mode_parity": verify_route_b_mode_parity(),
        "failures": 0,
        "claim": (
            "over the landed k19/k31 route phase envelope, Route A fixes a 14-state k51 endpoint; "
            "Route B fixes THIN|FULL_QR at k47, with THIN forcing t even/u odd and removing "
            "the D-J 2-adic overlap"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
