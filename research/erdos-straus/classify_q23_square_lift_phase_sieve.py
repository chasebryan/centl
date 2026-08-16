#!/usr/bin/env python3
"""Exact phase sieve for the canonical q=23 square-lift Type-II target on h=169."""
from __future__ import annotations

import argparse
import json
import math

Q = 23
Q2 = Q * Q
FOUR_Q2 = 4 * Q2  # 2116
HARD_CLASS = 169
K0 = 19
PERIOD = 4 * Q  # 92

EXPECTED_ALLOWED = (0, 3, 5, 6, 8, 11, 12, 14, 15, 17, 18, 20, 21)
EXPECTED_BLOCKED = (1, 2, 4, 7, 9, 10, 13, 16, 19, 22)

ROUTES = {
    "q17-q23": {
        "extra_source": 17,
        "required_p_mod_source": 15,
        "expected_progressions": {
            0: (2406, 3570), 3: (387, 714), 5: (1541, 3570),
            6: (126, 3570), 8: (482, 714), 11: (731, 3570),
            12: (666, 3570), 14: (446, 3570), 15: (951, 3570),
            17: (3341, 3570), 18: (654, 714), 20: (1526, 3570),
            21: (2721, 3570),
        },
    },
    "q23-q47": {
        "extra_source": 47,
        "required_p_mod_source": 28,
        "expected_progressions": {
            0: (9546, 9870), 3: (513, 1974), 5: (281, 9870),
            6: (126, 9870), 8: (230, 1974), 11: (101, 9870),
            12: (9696, 9870), 14: (6536, 9870), 15: (2421, 9870),
            17: (7541, 9870), 18: (696, 1974), 20: (1526, 9870),
            21: (6921, 9870),
        },
    },
}


def k_of(n: int) -> int:
    return K0 + PERIOD * n


def canonical_p(n: int, s: int) -> int:
    """p when the q^2-lift quotient is Qlift=k*s-1."""
    k = k_of(n)
    return k * (FOUR_Q2 * s - 1) - FOUR_Q2


def phase_allowed(n: int) -> bool:
    k = k_of(n)
    # Canonical q^2 Type-II requires p=k(4q^2*s-1)-4q^2.
    # Imposing p=169 mod840 is a linear congruence in s. Since
    # gcd(4q^2*k,840)=4*gcd(k,210), solvability is exactly:
    # gcd(k,210) | (169+k+4q^2)/4 = 576+23n.
    return (576 + Q * n) % math.gcd(k, 210) == 0


def solution_period(n: int, modulus: int) -> int:
    coefficient = FOUR_Q2 * k_of(n)
    return modulus // math.gcd(coefficient, modulus)


def route_progression(n: int, source_q: int, source_residue: int) -> tuple[int, int]:
    """Unique s progression satisfying h169 and one extra source residue."""
    period = math.lcm(solution_period(n, 840), solution_period(n, source_q))
    solutions = [
        s for s in range(period)
        if canonical_p(n, s) % 840 == HARD_CLASS
        and canonical_p(n, s) % source_q == source_residue
    ]
    if len(solutions) != 1:
        raise SystemExit((n, source_q, source_residue, period, solutions))
    return solutions[0], period


def analyze() -> dict[str, object]:
    allowed = tuple(n for n in range(Q) if phase_allowed(n))
    blocked = tuple(n for n in range(Q) if not phase_allowed(n))
    if allowed != EXPECTED_ALLOWED:
        raise SystemExit(f"allowed q23 lift phases changed: {allowed!r}")
    if blocked != EXPECTED_BLOCKED:
        raise SystemExit(f"blocked q23 lift phases changed: {blocked!r}")

    route_rows: dict[str, list[dict[str, int]]] = {}
    for name, spec in ROUTES.items():
        source_q = int(spec["extra_source"])
        source_residue = int(spec["required_p_mod_source"])
        expected = spec["expected_progressions"]
        rows = []
        actual = {}
        for n in allowed:
            s0, period = route_progression(n, source_q, source_residue)
            actual[n] = (s0, period)
            # p mod23=4 is automatic because k_n=19 mod92 and q^2|C_k.
            test_s = s0 if s0 else period
            p = canonical_p(n, test_s)
            assert p % Q == 4
            rows.append({
                "phase_n": n,
                "destination_k": k_of(n),
                "s_residue": s0,
                "s_period": period,
                "sample_positive_s": test_s,
                "sample_p": p,
            })
        if actual != expected:
            raise SystemExit(f"route progression atlas changed for {name}: {actual!r}")
        route_rows[name] = rows

    return {
        "analysis": "q23-square-lift-canonical-phase-sieve-v1",
        "q": Q,
        "hard_class": HARD_CLASS,
        "route_class": "k_n=19+92n, n mod23",
        "canonical_type_ii_equation": "p=k*(2116*s-1)-2116",
        "phase_solvability_condition": "gcd(k_n,210) divides 576+23n",
        "allowed_phases": list(allowed),
        "blocked_phases": list(blocked),
        "allowed_count": len(allowed),
        "blocked_count": len(blocked),
        "route_progressions": route_rows,
        "claim": (
            "on h169, the canonical d=23^2 Type-II target at the first-period q23^2 "
            "valuation lift is arithmetically impossible on 10 of 23 phases and possible "
            "only on the listed 13 phases; each realized pair route has one exact s "
            "progression on every allowed phase"
        ),
        "claim_boundary": (
            "phase-solvability theorem for the canonical q23^2 divisor only; other Type-I/II "
            "divisors may hit on blocked phases and allowed phases do not guarantee a hit"
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
        print(f"allowed phases: {report['allowed_phases']}")
        print(f"blocked phases: {report['blocked_phases']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
