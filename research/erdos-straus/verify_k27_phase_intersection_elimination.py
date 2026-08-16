#!/usr/bin/env python3
"""Verify exact intersections among the landed k27 phase-selector mode sets."""
from __future__ import annotations

import argparse
import json
import math
from itertools import combinations

SELECTORS = {
    "tau13=8": {"modulus": 13, "phase": 8, "modes": frozenset({"Q", "E"})},
    "tau17=6": {"modulus": 17, "phase": 6, "modes": frozenset({"B", "D"})},
    "tau19=8": {"modulus": 19, "phase": 8, "modes": frozenset({"Q"})},
    "tau31=7": {"modulus": 31, "phase": 7, "modes": frozenset({"Q", "A", "D"})},
    "tau43=27": {"modulus": 43, "phase": 27, "modes": frozenset({"Q"})},
}

EXPECTED_PAIRS = {
    ("tau13=8", "tau17=6"): {"modes": set(), "crt": (125, 221)},
    ("tau13=8", "tau19=8"): {"modes": {"Q"}},
    ("tau13=8", "tau31=7"): {"modes": {"Q"}, "crt": (255, 403)},
    ("tau13=8", "tau43=27"): {"modes": {"Q"}, "crt": (177, 559)},
    ("tau17=6", "tau19=8"): {"modes": set(), "crt": (93, 323)},
    ("tau17=6", "tau31=7"): {"modes": {"D"}, "crt": (346, 527)},
    ("tau17=6", "tau43=27"): {"modes": set(), "crt": (329, 731)},
    ("tau19=8", "tau31=7"): {"modes": {"Q"}},
    ("tau19=8", "tau43=27"): {"modes": {"Q"}},
    ("tau31=7", "tau43=27"): {"modes": {"Q"}, "crt": (1316, 1333)},
}


def crt_pair(m: int, a: int, n: int, b: int) -> tuple[int, int]:
    assert math.gcd(m, n) == 1
    k = ((b - a) * pow(m, -1, n)) % n
    x = a + m * k
    modulus = m * n
    return x % modulus, modulus


def route_b_u_for_t_phase(modulus: int, phase: int) -> int:
    # t = 705 + 1081u.
    return ((phase - 705) * pow(1081, -1, modulus)) % modulus


def verify_pairs() -> list[dict[str, object]]:
    rows = []
    names = list(SELECTORS)
    seen = set()
    for a, b in combinations(names, 2):
        key = (a, b)
        expected = EXPECTED_PAIRS[key]
        intersection = set(SELECTORS[a]["modes"]) & set(SELECTORS[b]["modes"])
        assert intersection == set(expected["modes"]), (key, intersection)

        ma = int(SELECTORS[a]["modulus"])
        pa = int(SELECTORS[a]["phase"])
        mb = int(SELECTORS[b]["modulus"])
        pb = int(SELECTORS[b]["phase"])
        crt = crt_pair(ma, pa, mb, pb)
        if "crt" in expected:
            assert crt == expected["crt"], (key, crt, expected["crt"])

        rows.append({
            "selectors": [a, b],
            "intersection": sorted(intersection),
            "crt_phase": crt[0],
            "crt_modulus": crt[1],
            "contradiction": not intersection,
        })
        seen.add(key)

    assert seen == set(EXPECTED_PAIRS)
    return rows


def verify_route_b() -> dict[str, object]:
    # Route-B BARE forces tau19=8. tau17=6 is the contradictory selector.
    u17 = route_b_u_for_t_phase(17, 6)
    u19 = route_b_u_for_t_phase(19, 8)
    assert u17 == 10
    assert u19 == 16
    bare_bad_u = crt_pair(17, u17, 19, u19)
    assert bare_bad_u == (282, 323)

    # The tau17=6 + tau31=7 phase pair selects k27 mode D.
    t_pair = crt_pair(17, 6, 31, 7)
    assert t_pair == (346, 527)
    u_pair = route_b_u_for_t_phase(527, 346)
    assert u_pair == 299

    # tau31=7 cannot be k31 BARE; Route-B BARE at k19 would force tau19=8,
    # which collides with tau17=6 at k27. Therefore simultaneous survival
    # forces FULL_QR at both k19 and k31, with k27 mode D.
    assert 7 not in {0, 19, 29}
    assert set(SELECTORS["tau17=6"]["modes"]) & set(SELECTORS["tau19=8"]["modes"]) == set()
    assert set(SELECTORS["tau17=6"]["modes"]) & set(SELECTORS["tau31=7"]["modes"]) == {"D"}

    return {
        "route_b_bare": {
            "tau19": 8,
            "tau17_forbidden": 6,
            "u_mod17_forbidden": u17,
            "bare_u_mod19": u19,
            "excluded_u_mod323": bare_bad_u[0],
        },
        "route_b_tau17_6_tau31_7": {
            "t_mod527": t_pair[0],
            "u_mod527": u_pair,
            "forced_k19_mode": "FULL_QR",
            "forced_k27_mode": "D",
            "forced_k31_mode": "FULL_QR",
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "k27-phase-intersection-elimination-v1",
        "pairwise": verify_pairs(),
        "route_b": verify_route_b(),
        "failures": 0,
        "claim": (
            "exact intersections of landed phase-selector mode sets produce three pairwise k27 "
            "contradictions, multiple Q selectors, and the unique non-Q selector "
            "tau17=6 plus tau31=7 -> k27 mode D; on Route B that phase pair also forces "
            "FULL_QR at k19 and k31"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
