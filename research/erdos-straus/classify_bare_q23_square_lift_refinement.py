#!/usr/bin/env python3
"""Refine the h169 q23 square-lift phase sieve by the exact k19 BARE centers.

This is an exact module of the candidate Type-II decomposition framework, not a
closed decomposition method. BARE supplies a fixed p mod19 center on each
realized route; intersecting that center with the canonical d=23^2 event removes
phase n=0 and leaves one arithmetic s-progression on each of the other 12
canonical phases.
"""
from __future__ import annotations

import argparse
import json
import math

Q = 23
FOUR_Q2 = 4 * Q * Q  # 2116
HARD_CLASS = 169
K0 = 19
PERIOD = 4 * Q

PARENT_ALLOWED = (0, 3, 5, 6, 8, 11, 12, 14, 15, 17, 18, 20, 21)
EXPECTED_BARE_ALLOWED = (3, 5, 6, 8, 11, 12, 14, 15, 17, 18, 20, 21)

ROUTES = {
    "q17-q23": {
        "extra_source": 17,
        "required_p_mod_source": 15,
        "bare_p_mod_19": 6,
        "k19_seed": 17 * 23,
        "expected_progressions": {
            3: (11811, 13566), 5: (65801, 67830), 6: (17976, 67830),
            8: (10478, 13566), 11: (61421, 67830), 12: (7806, 67830),
            14: (18296, 67830), 15: (43791, 67830), 17: (31901, 67830),
            18: (654, 13566), 20: (55076, 67830), 21: (38421, 67830),
        },
    },
    "q23-q47": {
        "extra_source": 47,
        "required_p_mod_source": 28,
        "bare_p_mod_19": 11,
        "k19_seed": 23 * 47,
        "expected_progressions": {
            3: (30123, 37506), 5: (39761, 187530), 6: (49476, 187530),
            8: (4178, 37506), 11: (19841, 187530), 12: (19566, 187530),
            14: (16406, 187530), 15: (180081, 187530), 17: (37151, 187530),
            18: (30306, 37506), 20: (80486, 187530), 21: (164841, 187530),
        },
    },
}


def k_of(n: int) -> int:
    return K0 + PERIOD * n


def canonical_p(n: int, s: int) -> int:
    k = k_of(n)
    return k * (FOUR_Q2 * s - 1) - FOUR_Q2


def solution_period(n: int, modulus: int) -> int:
    return modulus // math.gcd(FOUR_Q2 * k_of(n), modulus)


def bare_route_progression(
    n: int,
    source_q: int,
    source_residue: int,
    bare_p_mod_19: int,
) -> tuple[int, int] | None:
    period = math.lcm(
        solution_period(n, 840),
        solution_period(n, source_q),
        solution_period(n, 19),
    )
    solutions = [
        s for s in range(period)
        if canonical_p(n, s) % 840 == HARD_CLASS
        and canonical_p(n, s) % source_q == source_residue
        and canonical_p(n, s) % 19 == bare_p_mod_19
    ]
    if not solutions:
        return None
    if len(solutions) != 1:
        raise SystemExit((n, source_q, source_residue, bare_p_mod_19, period, solutions))
    return solutions[0], period


def analyze() -> dict[str, object]:
    route_rows: dict[str, list[dict[str, int]]] = {}

    for name, spec in ROUTES.items():
        actual: dict[int, tuple[int, int]] = {}
        rows = []
        for n in PARENT_ALLOWED:
            progression = bare_route_progression(
                n,
                int(spec["extra_source"]),
                int(spec["required_p_mod_source"]),
                int(spec["bare_p_mod_19"]),
            )
            if progression is None:
                continue
            s0, period = progression
            actual[n] = (s0, period)
            test_s = s0 if s0 else period
            p = canonical_p(n, test_s)
            assert p % 840 == HARD_CLASS
            assert p % int(spec["extra_source"]) == int(spec["required_p_mod_source"])
            assert p % 19 == int(spec["bare_p_mod_19"])
            assert p % Q == 4
            rows.append({
                "phase_n": n,
                "destination_k": k_of(n),
                "s_residue": s0,
                "s_period": period,
                "sample_positive_s": test_s,
                "sample_p": p,
            })

        if tuple(sorted(actual)) != EXPECTED_BARE_ALLOWED:
            raise SystemExit(f"BARE allowed phases changed for {name}: {sorted(actual)!r}")
        if actual != spec["expected_progressions"]:
            raise SystemExit(f"BARE progression atlas changed for {name}: {actual!r}")
        route_rows[name] = rows

    # Structural explanation for n=0: the q23 square lift would occur at k19
    # itself. But BARE has C19 = (17*23)R or (23*47)R with every prime of R
    # congruent 1 mod19. Since 23 != 1 mod19, R cannot contain another factor
    # 23, so 23^2 cannot divide C19 in BARE mode.
    assert 23 % 19 != 1

    return {
        "analysis": "bare-q23-square-lift-phase-refinement-v1",
        "framework_status": "proved exact module inside candidate decomposition framework",
        "hard_class": HARD_CLASS,
        "parent_canonical_phases": list(PARENT_ALLOWED),
        "bare_canonical_phases": list(EXPECTED_BARE_ALLOWED),
        "removed_by_bare": [0],
        "bare_phase_count": len(EXPECTED_BARE_ALLOWED),
        "route_progressions": route_rows,
        "claim": (
            "intersecting the exact k19 BARE centers with the canonical q23^2 Type-II event "
            "removes phase n=0 and leaves exactly the other 12 parent-allowed phases on both "
            "realized h169 routes"
        ),
        "claim_boundary": (
            "necessary modular refinement only; p mod19 at the BARE center is not sufficient "
            "for BARE, which additionally requires the remaining k19 cofactor to have all "
            "prime support 1 mod19; no decomposition method or ES proof is claimed"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"BARE canonical phases: {report['bare_canonical_phases']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
