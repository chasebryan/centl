#!/usr/bin/env python3
"""Regression verifier for the exact post-k23 companion ladder.

The infinite identities are proved algebraically in POST-K23-COMPANION-LADDER.md.
This script pins the h169 residue window, early support-overlap table, and both
realized route specializations over one complete joint 17*23*47 route period.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

H = 169
STEP = 840
PERIOD = 17 * 23 * 47

SEED_GCD_210 = {
    1: 7,
    2: 10,
    3: 3,
    4: 2,
    5: 1,
    6: 6,
    7: 5,
    8: 14,
}

ALLOWED_OLD_SUPPORT_OVERLAP = {
    1: {1},
    2: {2},
    3: {3},
    4: {2, 4},
    5: {1},
    6: {6},
    7: {1},
    8: {2, 4, 8},
}

ROUTES = (
    {
        "name": "q17-q23",
        "S": 17 * 23,
        "conditions": ((17, 15), (23, 4)),
        "expected_t_count": 47,
    },
    {
        "name": "q23-q47",
        "S": 23 * 47,
        "conditions": ((23, 4), (47, 28)),
        "expected_t_count": 17,
    },
)


def companion_data(t: int, j: int) -> tuple[int, int, int, int, int]:
    p = H + STEP * t
    C19 = (p + 19) // 4
    C23 = (p + 23) // 4
    B = C23 // 6
    k = 23 + 4 * j
    Cj = (p + k) // 4
    return p, C19, C23, B, Cj


def route_holds(p: int, conditions: tuple[tuple[int, int], ...]) -> bool:
    return all(p % q == r for q, r in conditions)


def verify_general_window() -> dict[str, object]:
    overlap_counts: dict[int, Counter[int]] = {j: Counter() for j in range(1, 9)}

    for t in range(PERIOD):
        p, C19, C23, B, _ = companion_data(t, 1)
        assert p == H + STEP * t
        assert C19 == 47 + 210 * t
        assert C23 == 48 + 210 * t
        assert C23 == C19 + 1
        assert C23 == 6 * B
        assert B == 8 + 35 * t
        assert B % 35 == 8
        assert math.gcd(C19, 210) == 1
        assert math.gcd(C19, C23) == 1

        for j in range(1, 9):
            _p, c19, c23, b, Cj = companion_data(t, j)
            assert c19 == C19 and c23 == C23 and b == B
            assert Cj == C23 + j
            assert Cj == 6 * B + j
            assert Cj == C19 + j + 1
            assert Cj % 210 == (48 + j) % 210
            assert math.gcd(Cj, 210) == SEED_GCD_210[j]
            assert math.gcd(Cj, C23) == math.gcd(j, C23)
            assert math.gcd(Cj, C19) == math.gcd(j + 1, C19)

            overlap = math.gcd(Cj, C19 * C23)
            assert overlap in ALLOWED_OLD_SUPPORT_OVERLAP[j]
            overlap_counts[j][overlap] += 1

            if j in (1, 5, 7):
                assert overlap == 1

    return {
        "t_period_checked": PERIOD,
        "seed_gcd_210": SEED_GCD_210,
        "old_support_overlap_counts": {
            j: dict(sorted(counts.items()))
            for j, counts in overlap_counts.items()
        },
        "fully_fresh_support_j": [1, 5, 7],
    }


def verify_routes() -> list[dict[str, object]]:
    reports = []
    for route in ROUTES:
        S = int(route["S"])
        conditions = tuple(route["conditions"])
        matching_t = []

        for t in range(PERIOD):
            p, C19, C23, B, _ = companion_data(t, 1)
            if not route_holds(p, conditions):
                continue
            matching_t.append(t)
            assert C19 % S == 0
            R = C19 // S
            assert 6 * B - S * R == 1
            assert math.gcd(B, R) == 1

            for j in range(1, 9):
                _p, _c19, _c23, _b, Cj = companion_data(t, j)
                assert Cj == 6 * B + j
                assert Cj == S * R + j + 1
                assert math.gcd(Cj, B) == math.gcd(j, B)
                assert math.gcd(Cj, R) == math.gcd(j + 1, R)

        assert len(matching_t) == int(route["expected_t_count"])
        reports.append(
            {
                "route": route["name"],
                "S": S,
                "matching_t_in_joint_period": len(matching_t),
                "first_t": matching_t[0],
                "last_t": matching_t[-1],
            }
        )

    return reports


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "post-k23-companion-ladder-v1",
        "general_window": verify_general_window(),
        "routes": verify_routes(),
        "failures": 0,
        "claim": (
            "regression verification of the h169 companion ladder, Euclidean support-renewal "
            "laws, fixed k27..k55 seed window, and both realized B/R route specializations"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
