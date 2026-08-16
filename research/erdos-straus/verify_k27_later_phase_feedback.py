#!/usr/bin/env python3
"""Verify exact feedback from landed later phase coordinates into k27 mode geometry."""
from __future__ import annotations

import argparse
import json
import math
from fractions import Fraction

K = 27
TYPE_I_TARGET = 20
QR27 = frozenset({1, 4, 7, 10, 13, 16, 19, 22, 25})

S13 = frozenset({1, 2, 5, 6, 7, 8, 9, 10, 11})
S17 = frozenset({0, 1, 2, 3, 6, 8, 9, 10, 11, 12, 13, 15, 16})
S31 = frozenset({0, 2, 6, 7, 8, 9, 11, 12, 14, 15, 19, 22, 27, 28, 29})
S43 = frozenset(set(range(43)) - {2, 28, 30})
S47 = frozenset(set(range(47)) - {1, 5, 6, 10, 13, 21, 23, 36, 37, 38, 40, 42, 44})
S11 = frozenset(set(range(11)) - {5, 6, 7, 10})

SKELETONS = {
    "Q": [()],
    "A": [(2, 14)],
    "B": [
        (8, 17),
        (5, 11),
        (2, 2, 2, 17),
        (2, 2, 14, 14),
        (8, 14, 14, 14),
        (5, 5, 11, 11),
        (2, 2, 2, 14, 14, 14),
    ],
    "C": [(2, 2), (8, 14), (2, 2, 2, 14)],
    "D": [(2, 17), (14, 14), (2, 14, 14, 14)],
    "E": [(5, 5)],
    "F": [(11, 11)],
}

EXPECTED = {
    11: {"phase": 6, "residue": 11, "modes": {"B", "F"}, "kind": "NR"},
    13: {"phase": 8, "residue": 13, "modes": {"Q", "E"}, "kind": "QR"},
    17: {"phase": 6, "residue": 17, "modes": {"B", "D"}, "kind": "NR"},
    19: {"phase": 8, "residue": 19, "modes": {"Q"}, "kind": "QR"},
    31: {"phase": 7, "residue": 4, "modes": {"Q", "A", "D"}, "kind": "QR"},
    43: {"phase": 27, "residue": 16, "modes": {"Q"}, "kind": "QR"},
    47: {"phase": 17, "residue": 20, "modes": set(), "kind": "KILL"},
}


def advance(state: tuple[frozenset[int], int], residue: int) -> tuple[frozenset[int], int]:
    mask, center = state
    r = residue % K
    powers = {1, r, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def hit(state: tuple[frozenset[int], int]) -> bool:
    mask, center = state
    return TYPE_I_TARGET in mask or (-center) % K in mask


def seed_state() -> tuple[frozenset[int], int]:
    return advance((frozenset({1}), 1), 7)


def skeleton_states() -> dict[str, list[tuple[tuple[int, ...], tuple[frozenset[int], int]]]]:
    out = {}
    seed = seed_state()
    for mode, skeletons in SKELETONS.items():
        rows = []
        for skeleton in skeletons:
            state = seed
            for residue in skeleton:
                state = advance(state, residue)
            assert not hit(state), (mode, skeleton)
            rows.append((skeleton, state))
        out[mode] = rows
    return out


def qr_live_modes(residue: int, states: dict[str, list[tuple[tuple[int, ...], tuple[frozenset[int], int]]]]) -> set[str]:
    live = set()
    for mode, rows in states.items():
        outcomes = [not hit(advance(state, residue)) for _skeleton, state in rows]
        # Behavioral-mode consistency is part of the landed seven-mode theorem.
        assert len(set(outcomes)) == 1, (residue, mode, outcomes)
        if outcomes[0]:
            live.add(mode)
    return live


def nr_modes_containing(residue: int) -> set[str]:
    return {
        mode
        for mode, skeletons in SKELETONS.items()
        if any(residue in skeleton for skeleton in skeletons)
    }


def phase_for_factor(q: int) -> int:
    return (-7 * pow(30, -1, q)) % q


def verify_feedback() -> list[dict[str, object]]:
    states = skeleton_states()
    assert seed_state() == (frozenset({1, 7, 22}), 7)
    assert not hit(seed_state())

    rows = []
    for q, expected in EXPECTED.items():
        phase = phase_for_factor(q)
        residue = q % K
        assert phase == expected["phase"]
        assert residue == expected["residue"]
        assert (7 + 30 * phase) % q == 0

        if expected["kind"] == "QR":
            assert residue in QR27
            modes = qr_live_modes(residue, states)
        elif expected["kind"] == "NR":
            assert residue not in QR27
            modes = nr_modes_containing(residue)
        else:
            assert expected["kind"] == "KILL"
            assert residue not in QR27
            assert hit(advance(seed_state(), residue))
            modes = set()

        assert modes == expected["modes"], (q, modes, expected["modes"])
        rows.append({
            "prime": q,
            "phase": phase,
            "residue_mod27": residue,
            "kind": expected["kind"],
            "k27_nr_modes": sorted(modes),
        })

    # The later standalone phase envelopes still allow the new useful phases.
    assert 8 in S13
    assert 6 in S17
    assert 7 in S31
    assert 27 in S43
    assert 17 in S47
    # The q=11 feedback is redundant once k55 survival is assumed.
    assert 6 not in S11

    return rows


def verify_phase_contraction() -> dict[str, object]:
    s47_star = frozenset(set(S47) - {17})
    assert len(S47) == 34
    assert len(s47_star) == 33

    general_modulus = 31 * 13 * 43 * 47 * 17 * 11
    general_survivors = 15 * 9 * 40 * 33 * 13 * 7
    assert general_modulus == 152_304_581
    assert general_survivors == 16_216_200
    general_fraction = Fraction(general_survivors, general_modulus)
    assert general_fraction == Fraction(113_400, 1_065_067)

    route_a_modulus = 19 * 31 * 13 * 43 * 47 * 11
    route_a_survivors = 9 * 15 * 9 * 40 * 33 * 7
    assert route_a_modulus == 170_222_767
    assert route_a_survivors == 11_226_600
    route_a_fraction = Fraction(route_a_survivors, route_a_modulus)
    assert route_a_fraction == Fraction(1_020_600, 15_474_797)

    return {
        "S47_before": sorted(S47),
        "S47_after_k27": sorted(s47_star),
        "general": {
            "phase_modulus": general_modulus,
            "survivor_classes": general_survivors,
            "reduced_fraction": f"{general_fraction.numerator}/{general_fraction.denominator}",
            "survivor_fraction": float(general_fraction),
        },
        "route_a": {
            "phase_modulus": route_a_modulus,
            "survivor_classes": route_a_survivors,
            "reduced_fraction": f"{route_a_fraction.numerator}/{route_a_fraction.denominator}",
            "survivor_fraction": float(route_a_fraction),
        },
        "route_b_scalar_changed": False,
        "route_b_reason": "Route B ancestry fixes t mod47 = 0, already outside the newly forbidden phase17.",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "k27-later-phase-feedback-v1",
        "feedback": verify_feedback(),
        "phase_contraction": verify_phase_contraction(),
        "failures": 0,
        "claim": (
            "later CRT phase coordinates force rational prime factors into E and thereby restrict "
            "the exact k27 NR-skeleton mode; in particular t mod47=17 is incompatible with a "
            "k27 miss, shrinking the k47 survivor phase set from34 to33"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
