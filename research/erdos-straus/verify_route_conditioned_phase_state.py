#!/usr/bin/env python3
"""Verify route-conditioned phase volume and Route-B mode/parity coupling."""
from __future__ import annotations

import argparse
import json
import math
from collections import deque
from fractions import Fraction

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
    # Route A fixes t mod17 and therefore the k51 endpoint center.
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

    # Route B fixes t mod47 and therefore the k47 endpoint center.
    assert ROUTE_B_T0 % 47 == 0
    assert ROUTE_B_STEP % 47 == 0
    assert 0 in S47
    center47 = (54 + 210 * 0) % 47
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


def route_a_survives(u: int) -> bool:
    t = ROUTE_A_T0 + ROUTE_A_STEP * u
    assert t % 17 == 12
    return (
        t % 13 in S39
        and t % 43 in S43
        and t % 47 in S47
        and t % 11 in S55
    )


def route_b_survives(u: int) -> bool:
    t = ROUTE_B_T0 + ROUTE_B_STEP * u
    assert t % 47 == 0
    return (
        t % 13 in S39
        and t % 43 in S43
        and t % 17 in S51
        and t % 11 in S55
    )


def verify_route_phase_volumes() -> dict[str, object]:
    route_a_moduli = (13, 43, 47, 11)
    route_b_moduli = (13, 43, 17, 11)
    assert all(math.gcd(ROUTE_A_STEP, m) == 1 for m in route_a_moduli)
    assert all(math.gcd(ROUTE_B_STEP, m) == 1 for m in route_b_moduli)

    ma = math.prod(route_a_moduli)
    mb = math.prod(route_b_moduli)
    assert ma == 289_003
    assert mb == 104_533

    na = sum(route_a_survives(u) for u in range(ma))
    nb = sum(route_b_survives(u) for u in range(mb))
    assert na == 85_680
    assert nb == 32_760

    fa = Fraction(na, ma)
    fb = Fraction(nb, mb)
    assert fa == Fraction(85_680, 289_003)
    assert fb == Fraction(2_520, 8_041)

    # Independent multiplicative check from the exact survivor-set sizes.
    assert na == len(S39) * len(S43) * len(S47) * len(S55)
    assert nb == len(S39) * len(S43) * len(S51) * len(S55)

    return {
        "route_a": {
            "phase_modulus": ma,
            "survivor_classes": na,
            "fraction_exact": f"{na}/{ma}",
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
    # THIN permits only residue-1 occurrences plus either {9} or {3,3}.
    # Rational prime2 has residue2 mod47, so any even J is incompatible.
    assert 2 % 47 not in {1, 3, 9}

    for u in range(2 * 47):
        t = ROUTE_B_T0 + ROUTE_B_STEP * u
        D = 5 + 21 * t
        J = 9 + 35 * t
        assert (J % 2 == 1) == (t % 2 == 0)
        assert (t % 2 == 0) == (u % 2 == 1)
        assert math.gcd(D, J) == math.gcd(2, t + 1)
        if t % 2 == 1:
            assert J % 2 == 0
            assert D % 2 == 0
            assert math.gcd(D, J) == 2
        else:
            assert J % 2 == 1
            assert D % 2 == 1
            assert math.gcd(D, J) == 1

    mb = 104_533
    thin_envelope_count = sum(
        route_b_survives(u) and (u % 2 == 1)
        for u in range(2 * mb)
    )
    assert thin_envelope_count == 32_760
    thin_fraction = Fraction(thin_envelope_count, 2 * mb)
    assert thin_fraction == Fraction(1_260, 8_041)

    return {
        "thin_requires_t_even": True,
        "thin_requires_u_odd": True,
        "t_odd_forces_full_qr": True,
        "t_odd_gcd_D_J": 2,
        "t_even_gcd_D_J": 1,
        "thin_phase_parity_modulus": 2 * mb,
        "thin_phase_parity_classes": thin_envelope_count,
        "thin_phase_parity_fraction_reduced": (
            f"{thin_fraction.numerator}/{thin_fraction.denominator}"
        ),
        "thin_phase_parity_fraction": float(thin_fraction),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "route-conditioned-phase-state-v1",
        "fixed_route_endpoints": verify_fixed_route_endpoints(),
        "route_phase_volumes": verify_route_phase_volumes(),
        "route_b_mode_parity": verify_route_b_mode_parity(),
        "failures": 0,
        "claim": (
            "after route selection, Route A fixes the k51 phase and Route B fixes "
            "the k47 phase; Route-B THIN further forces t even/u odd and switches "
            "off the D-J 2-adic overlap"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
