#!/usr/bin/env python3
"""Verify exact QR-factor selectors for the landed h169 k27 seven-mode grammar."""
from __future__ import annotations

import argparse
import json

MODES = ("Q", "A", "B", "C", "D", "E", "F")
QR27 = frozenset({1, 4, 7, 10, 13, 16, 19, 22, 25})
HIT = "HIT"

TRANSITIONS = {
    "Q": {1:"Q",4:"Q",7:"Q",10:"Q",13:"Q",16:"Q",19:"Q",22:"Q",25:"Q"},
    "A": {1:"A",4:"C",7:"D",10:HIT,13:HIT,16:HIT,19:HIT,22:HIT,25:HIT},
    "B": {1:"B",4:HIT,7:HIT,10:HIT,13:HIT,16:HIT,19:HIT,22:HIT,25:HIT},
    "C": {1:"C",4:HIT,7:"B",10:HIT,13:HIT,16:HIT,19:HIT,22:HIT,25:HIT},
    "D": {1:"D",4:"B",7:HIT,10:HIT,13:HIT,16:HIT,19:HIT,22:HIT,25:HIT},
    "E": {1:"E",4:HIT,7:HIT,10:HIT,13:"B",16:HIT,19:HIT,22:HIT,25:HIT},
    "F": {1:"F",4:HIT,7:HIT,10:HIT,13:HIT,16:HIT,19:HIT,22:HIT,25:"B"},
}

EXPECTED_ONE = {
    1: set(MODES),
    4: {"Q","A","D"},
    7: {"Q","A","C"},
    10: {"Q"},
    13: {"Q","E"},
    16: {"Q"},
    19: {"Q"},
    22: {"Q"},
    25: {"Q","F"},
}

PHASE_EXAMPLES = {
    7: (0, 21),
    13: (8, 73),
    19: (8, 84),
    31: (7, 224),
    37: (1, 593),
    43: (27, 801),
    79: (34, 1456),
    103: (65, 4597),
}


def survive_once(mode: str, r: int) -> bool:
    return TRANSITIONS[mode][r] != HIT


def survive_twice(mode: str, r: int) -> bool:
    first = TRANSITIONS[mode][r]
    if first == HIT:
        return False
    return TRANSITIONS[first][r] != HIT


def E_of_t(t: int) -> int:
    return 7 + 30 * t


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert set(TRANSITIONS) == set(MODES)
    assert all(set(row) == set(QR27) for row in TRANSITIONS.values())

    one = {}
    for r in sorted(QR27):
        live = {m for m in MODES if survive_once(m, r)}
        assert live == EXPECTED_ONE[r]
        one[r] = sorted(live)

    one_occurrence_q_selectors = frozenset(r for r, live in EXPECTED_ONE.items() if live == {"Q"})
    assert one_occurrence_q_selectors == frozenset({10,16,19,22})

    two_occurrence_q_selectors = {}
    for r in (4,7,13,25):
        live = {m for m in MODES if survive_twice(m, r)}
        assert live == {"Q"}
        two_occurrence_q_selectors[r] = sorted(live)

    # Residue1 never changes a live mode.
    assert all(TRANSITIONS[m][1] == m for m in MODES)

    # Exact rational-prime phases q|E and q^2|E.
    phase_rows = []
    for q, (t1_expected, t2_expected) in PHASE_EXAMPLES.items():
        assert q > 3
        t1 = (-7 * pow(30, -1, q)) % q
        t2 = (-7 * pow(30, -1, q*q)) % (q*q)
        assert (t1, t2) == (t1_expected, t2_expected)
        assert E_of_t(t1) % q == 0
        assert E_of_t(t2) % (q*q) == 0
        phase_rows.append({
            "q": q,
            "q_mod27": q % 27,
            "q_divides_E_t_mod_q": t1,
            "q2_divides_E_t_mod_q2": t2,
            "one_occurrence_modes": one[q % 27],
        })

    # Route-B k19 BARE defect center phase is t=8 mod19.
    # This automatically forces rational prime19 into E.
    for n in range(40):
        t = 8 + 19*n
        assert E_of_t(t) % 19 == 0
    assert 19 % 27 == 19
    assert EXPECTED_ONE[19] == {"Q"}

    # Q is stable under every QR residue, so after the selector fires the entire
    # surviving E support is QR27.
    assert all(TRANSITIONS["Q"][r] == "Q" for r in QR27)

    report = {
        "analysis": "k27-qr-factor-mode-selectors-v1",
        "qr27": sorted(QR27),
        "one_occurrence_live_modes": {str(r): one[r] for r in sorted(one)},
        "one_occurrence_Q_selectors": sorted(one_occurrence_q_selectors),
        "two_occurrence_Q_selectors": sorted(two_occurrence_q_selectors),
        "phase_examples": phase_rows,
        "route_b_bare": {
            "t_mod19": 8,
            "forced_factor": 19,
            "forced_k27_mode_on_miss": "Q",
            "E_support": "QR27",
        },
        "failures": 0,
        "claim": (
            "QR residues 10,16,19,22 select k27 mode Q after one occurrence; "
            "residues 4,7,13,25 select Q after two occurrences; in particular "
            "Route-B k19 BARE forces 19|E, so any k27 miss is mode Q with all E factors QR27"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
