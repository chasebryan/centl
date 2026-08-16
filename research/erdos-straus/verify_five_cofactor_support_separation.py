#!/usr/bin/env python3
"""Regression verifier for five-cofactor support separation on realized h169 routes."""
from __future__ import annotations

import argparse
import json
import math

JOINT_PERIOD = 17 * 23 * 47
ROUTES = (
    {
        "name": "q17-q23",
        "S": 17 * 23,
        "conditions": ((17, 15), (23, 4)),
        "expected_matches": 47,
        "first_t": 199,
        "last_t": 18185,
    },
    {
        "name": "q23-q47",
        "S": 23 * 47,
        "conditions": ((23, 4), (47, 28)),
        "expected_matches": 17,
        "first_t": 705,
        "last_t": 18001,
    },
)


def h169_coordinates(t: int) -> tuple[int, int, int, int, int, int]:
    p = 169 + 840 * t
    C19 = (p + 19) // 4
    B = 8 + 35 * t
    E = 7 + 30 * t
    D = 5 + 21 * t
    F = 17 + 70 * t
    return p, C19, B, E, D, F


def verify_base_chain() -> dict[str, object]:
    # Pin the companion identities over a full product period of every route
    # modulus used below. The markdown proof establishes them algebraically.
    for t in range(JOINT_PERIOD):
        p, C19, B, E, D, F = h169_coordinates(t)
        assert C19 == 47 + 210 * t
        assert (p + 23) // 4 == 6 * B == C19 + 1
        assert (p + 27) // 4 == 7 * E == C19 + 2
        assert (p + 31) // 4 == 10 * D == C19 + 3
        assert (p + 35) // 4 == 3 * F == C19 + 4

        assert 7 * E - 6 * B == 1
        assert 10 * D - 7 * E == 1
        assert 5 * D - 3 * B == 1
        assert F - 2 * B == 1
        assert 3 * F - 10 * D == 1
        assert 3 * F - 7 * E == 2

        values = (B, E, D, F)
        assert all(
            math.gcd(values[i], values[j]) == 1
            for i in range(4)
            for j in range(i + 1, 4)
        )

    return {
        "t_values_checked": JOINT_PERIOD,
        "B_E_D_F_pairwise_coprime": True,
    }


def route_holds(p: int, conditions: tuple[tuple[int, int], ...]) -> bool:
    return all(p % q == residue for q, residue in conditions)


def verify_routes() -> list[dict[str, object]]:
    reports = []
    for route in ROUTES:
        S = int(route["S"])
        conditions = tuple(route["conditions"])
        matches: list[int] = []

        assert S % 2 == 1
        assert S % 3 == 1

        for t in range(JOINT_PERIOD):
            p, C19, B, E, D, F = h169_coordinates(t)
            if not route_holds(p, conditions):
                continue

            matches.append(t)
            assert C19 % S == 0
            R = C19 // S

            assert C19 == S * R
            assert 6 * B - S * R == 1
            assert 7 * E - S * R == 2
            assert 10 * D - S * R == 3
            assert 3 * F - S * R == 4

            assert R % 2 == 1
            assert C19 % 3 == 2
            assert R % 3 == 2

            values = (R, B, E, D, F)
            gcd_matrix = [
                math.gcd(values[i], values[j])
                for i in range(5)
                for j in range(i + 1, 5)
            ]
            assert gcd_matrix == [1] * 10

        assert len(matches) == int(route["expected_matches"])
        assert matches[0] == int(route["first_t"])
        assert matches[-1] == int(route["last_t"])

        reports.append(
            {
                "route": route["name"],
                "S": S,
                "matches_in_joint_period": len(matches),
                "first_t": matches[0],
                "last_t": matches[-1],
                "five_way_pairwise_coprime": True,
                "R_mod3": 2,
            }
        )

    return reports


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "realized-h169-five-cofactor-support-separation-v1",
        "base_chain": verify_base_chain(),
        "routes": verify_routes(),
        "pairwise_pairs": 10,
        "failures": 0,
        "claim": (
            "regression verification of the exact route theorem that "
            "R,B,E,D,F are pairwise coprime on both realized h169 routes"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
