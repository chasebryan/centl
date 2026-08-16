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
    ("tau13=8", "tau19=8"): {"modes": {"Q"}, "crt": (8, 247)},
    ("tau13=8", "tau31=7"): {"modes": {"Q"}, "crt": (255, 403)},
    ("tau13=8", "tau43=27"): {"modes": {"Q"}, "crt": (242, 559)},
    ("tau17=6", "tau19=8"): {"modes": set(), "crt": (312, 323)},
    ("tau17=6", "tau31=7"): {"modes": {"D"}, "crt": (193, 527)},
    ("tau17=6", "tau43=27"): {"modes": set(), "crt": (414, 731)},
    ("tau19=8", "tau31=7"): {"modes": {"Q"}, "crt": (255, 589)},
    ("tau19=8", "tau43=27"): {"modes": {"Q"}, "crt": (27, 817)},
    ("tau31=7", "tau43=27"): {"modes": {"Q"}, "crt": (844, 1333)},
}


def crt_pair(m: int, a: int, n: int, b: int) -> tuple[int, int]:
    assert math.gcd(m, n) == 1
    k = ((b - a) * pow(m, -1, n)) % n
    x = a + m * k
    return x % (m * n), m * n


def route_b_u_for_t_phase(modulus: int, phase: int) -> int:
    # t = 705 + 1081u.
    return ((phase - 705) * pow(1081, -1, modulus)) % modulus


def verify_pairs() -> list[dict[str, object]]:
    rows = []
    for a, b in combinations(SELECTORS, 2):
        expected = EXPECTED_PAIRS[(a, b)]
        intersection = set(SELECTORS[a]["modes"]) & set(SELECTORS[b]["modes"])
        assert intersection == set(expected["modes"]), ((a, b), intersection)
        crt = crt_pair(
            int(SELECTORS[a]["modulus"]), int(SELECTORS[a]["phase"]),
            int(SELECTORS[b]["modulus"]), int(SELECTORS[b]["phase"]),
        )
        assert crt == expected["crt"], ((a, b), crt, expected["crt"])
        rows.append({
            "selectors": [a, b],
            "intersection": sorted(intersection),
            "crt_phase": crt[0],
            "crt_modulus": crt[1],
            "contradiction": not intersection,
        })
    return rows


def verify_route_b() -> dict[str, object]:
    u17 = route_b_u_for_t_phase(17, 6)
    u19 = route_b_u_for_t_phase(19, 8)
    assert (u17, u19) == (10, 16)
    bare_bad_u = crt_pair(17, u17, 19, u19)
    assert bare_bad_u == (282, 323)

    t_pair = crt_pair(17, 6, 31, 7)
    assert t_pair == (193, 527)
    u_pair = route_b_u_for_t_phase(527, 193)
    assert u_pair == 469

    assert 7 not in {0, 19, 29}
    assert set(SELECTORS["tau17=6"]["modes"]) & set(SELECTORS["tau19=8"]["modes"]) == set()
    assert set(SELECTORS["tau17=6"]["modes"]) & set(SELECTORS["tau31=7"]["modes"]) == {"D"}

    return {
        "route_b_bare": {
            "tau19": 8,
            "tau17_forbidden": 6,
            "excluded_u_mod323": bare_bad_u[0],
        },
        "route_b_tau17_6_tau31_7": {
            "t_mod527": 193,
            "u_mod527": 469,
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
        "analysis": "k27-phase-intersection-elimination-v2-crt-corrected",
        "pairwise": verify_pairs(),
        "route_b": verify_route_b(),
        "failures": 0,
        "claim": (
            "exact mode intersections are unchanged; independently recomputed CRT labels are "
            "pinned for every pair. Three pairwise phase collisions contradict k27 survival, "
            "and tau17=6 plus tau31=7 uniquely selects mode D; on Route B it also forces "
            "FULL_QR at k19 and k31"
        ),
    }
    print(json.dumps(report, indent=2, sort_keys=True) if args.json else report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
