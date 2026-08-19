#!/usr/bin/env python3
"""Finite regression for the exact BEC post-k23 transition chain through k35."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

from analyze_q23_blocked_phase_geometry import (
    BLOCKED_PHASES,
    EXPECTED,
    ROUTES,
    phase_progression,
)
from audit_q23_blocked_phase_ancestry import first_post23_hit
from verify_bec_k27_k31_transition import (
    g27_from_factorization,
    q31_from_factorization,
)
from verify_k35_two_branch_survivor_theorem import h35
from verify_q23_square_lift_phase_sieve import (
    factor,
    fixed_shift_status,
    is_prime,
    k_of,
    sieve,
)

EXPECTED_CHAIN_COUNTS = {
    "R": 64,
    "LR": 64,
    "LLR": 7,
    "LLL": 13,
}

H35 = h35()


def j35_from_factorization(F: int, primes: list[int]) -> bool:
    factors = factor(F, primes)
    return all((q % 35) in H35 for q in factors)


def s7_from_factorization(F: int, primes: list[int]) -> bool:
    factors = factor(F, primes)
    special = 0
    for q, exponent in factors.items():
        residue = q % 7
        if residue == 3:
            if exponent != 1:
                return False
            special += 1
        elif residue == 1:
            continue
        else:
            return False
    return special == 1


def m35_from_factorization(F: int, primes: list[int]) -> tuple[bool, bool, bool]:
    j35 = j35_from_factorization(F, primes)
    s7 = s7_from_factorization(F, primes)
    return j35 or s7, j35, s7


def selector(g27: bool, q31: bool, m35: bool) -> str:
    if not g27:
        return "R"
    if not q31:
        return "LR"
    if not m35:
        return "LLR"
    return "LLL"


def actual_prefix(first_k: int) -> str:
    if first_k == 27:
        return "R"
    if first_k == 31:
        return "LR"
    if first_k == 35:
        return "LLR"
    assert first_k > 35
    return "LLL"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    max_p = max(row[0] for table in EXPECTED.values() for row in table.values())
    max_k = max(k_of(n) for n in BLOCKED_PHASES)
    primes = sieve(math.isqrt((max_p + max_k) // 4) + 1)

    predicted = Counter()
    actual = Counter()
    m35_branch_counts = Counter()
    route_counts = {route.name: Counter() for route in ROUTES}
    checked = 0

    for route in ROUTES:
        for n in BLOCKED_PHASES:
            limit_p = EXPECTED[route.name][n][0]
            destination_k = k_of(n)
            residue, modulus = phase_progression(n, route)
            p = residue if residue >= 2 else residue + modulus

            while p <= limit_p:
                if is_prime(p):
                    miss19, _i19, _ii19, _f19 = fixed_shift_status(p, 19, primes)
                    miss23, _i23, _ii23, _f23 = fixed_shift_status(p, 23, primes)
                    if miss19 and miss23:
                        checked += 1
                        t = (p - 169) // 840
                        assert p == 169 + 840 * t
                        E = 7 + 30 * t
                        D = 5 + 21 * t
                        F = 17 + 70 * t
                        assert (p + 27) // 4 == 7 * E
                        assert (p + 31) // 4 == 10 * D
                        assert (p + 35) // 4 == 3 * F

                        g27, _mode, _skeleton = g27_from_factorization(E, primes)
                        q31 = q31_from_factorization(D, primes)
                        m35, j35, s7 = m35_from_factorization(F, primes)

                        miss27, _i27, _ii27, _f27 = fixed_shift_status(p, 27, primes)
                        miss31, _i31, _ii31, _f31 = fixed_shift_status(p, 31, primes)
                        miss35, _i35, _ii35, _f35 = fixed_shift_status(p, 35, primes)
                        assert g27 == miss27
                        assert q31 == miss31
                        assert m35 == miss35, (p, F, m35, j35, s7, miss35)

                        pred = selector(g27, q31, m35)
                        first = first_post23_hit(p, destination_k, primes)
                        assert first is not None
                        act = actual_prefix(int(first["k"]))
                        assert pred == act, (p, pred, act, first)

                        predicted[pred] += 1
                        actual[act] += 1
                        route_counts[route.name][pred] += 1

                        if g27 and q31:
                            if j35 and s7:
                                m35_branch_counts["J35+S7"] += 1
                            elif j35:
                                m35_branch_counts["J35"] += 1
                            elif s7:
                                m35_branch_counts["S7"] += 1
                            else:
                                m35_branch_counts["HIT"] += 1
                p += modulus

    assert checked == 148
    assert dict(sorted(predicted.items())) == EXPECTED_CHAIN_COUNTS
    assert predicted == actual
    assert sum(m35_branch_counts.values()) == 20

    report = {
        "analysis": "bec-k27-k35-transition-chain-v1",
        "simultaneous_k19_k23_survivors_checked": checked,
        "selector_counts": dict(sorted(predicted.items())),
        "actual_prefix_counts": dict(sorted(actual.items())),
        "k35_branch_counts_within_LL": dict(sorted(m35_branch_counts.items())),
        "route_selector_counts": {
            route: dict(sorted(counts.items()))
            for route, counts in route_counts.items()
        },
        "theorem": {
            "R": "not G27(E)",
            "LR": "G27(E) and not Q31(D)",
            "LLR": "G27(E) and Q31(D) and not M35(F)",
            "LLL_prefix": "G27(E) and Q31(D) and M35(F)",
            "M35": "J35(F) or S7(F)",
        },
        "deep_residual_after_k35": predicted["LLL"],
        "failures": 0,
        "claim": (
            "finite regression of the range-free exact chained selector: G27, Q31, "
            "and M35 determine the live BEC path through k35 on all 148 audited "
            "simultaneous k19/k23 survivors"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
