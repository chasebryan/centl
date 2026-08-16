#!/usr/bin/env python3
"""Independent finite regression for the exact BEC k27/k31 selector theorem.

The theorem itself is the composition of two range-free exact modules:

- K27-SURVIVOR-GRAMMAR.md: k27 misses iff G27(E);
- K31-SURVIVOR-NORMAL-FORM.md: k31 misses iff Q31(D).

This verifier independently reconstructs G27 from the closed-form residue
rules, Q31 from prime-factor support, then replays the 148 simultaneous
k19/k23 survivors from the q23 ancestry specimen. It verifies that those
predicates select R, LR, or the deeper LL prefix before consulting the
recorded later first-hit category.
"""
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
from verify_k27_survivor_grammar import (
    EXPECTED_SKELETONS,
    MODE_SKELETONS,
    QR as QR27,
)
from verify_k31_survivor_normal_form import QR as QR31
from verify_q23_square_lift_phase_sieve import (
    factor,
    fixed_shift_status,
    is_prime,
    k_of,
    sieve,
)

EXPECTED_SELECTOR_COUNTS = {
    "R": 64,
    "LR": 64,
    "LL": 20,
}


def skeleton_mode(skeleton: tuple[int, ...]) -> str | None:
    matches = [mode for mode, skeletons in MODE_SKELETONS.items() if skeleton in skeletons]
    assert len(matches) <= 1
    return matches[0] if matches else None


def qr_completion_survives(mode: str, qr_occurrences: tuple[int, ...]) -> bool:
    counts = Counter(qr_occurrences)
    residues = set(qr_occurrences)

    if mode == "Q":
        return residues.issubset(QR27)
    if mode == "A":
        return residues.issubset({1, 4, 7}) and counts[4] <= 1 and counts[7] <= 1
    if mode == "B":
        return residues.issubset({1})
    if mode == "C":
        return residues.issubset({1, 7}) and counts[7] <= 1
    if mode == "D":
        return residues.issubset({1, 4}) and counts[4] <= 1
    if mode == "E":
        return residues.issubset({1, 13}) and counts[13] <= 1
    if mode == "F":
        return residues.issubset({1, 25}) and counts[25] <= 1
    raise AssertionError(f"unknown k27 mode: {mode}")


def g27_from_factorization(E: int, primes: list[int]) -> tuple[bool, str | None, tuple[int, ...]]:
    """Exact closed-form G27(E) predicate from the landed survivor grammar."""
    factors = factor(E, primes)
    nr: list[int] = []
    qr: list[int] = []

    for q, exponent in factors.items():
        residue = q % 27
        assert math.gcd(residue, 27) == 1, (E, q, residue)
        bucket = qr if residue in QR27 else nr
        bucket.extend([residue] * exponent)

    skeleton = tuple(sorted(nr))
    qr_occurrences = tuple(sorted(qr))

    if skeleton not in EXPECTED_SKELETONS:
        return False, None, skeleton
    mode = skeleton_mode(skeleton)
    assert mode is not None
    return qr_completion_survives(mode, qr_occurrences), mode, skeleton


def q31_from_factorization(D: int, primes: list[int]) -> bool:
    """Exact Q31(D): every rational prime factor is nonzero QR mod31."""
    factors = factor(D, primes)
    for q in factors:
        residue = q % 31
        if residue == 0 or residue not in QR31:
            return False
    return True


def selector(g27: bool, q31: bool) -> str:
    if not g27:
        return "R"
    if not q31:
        return "LR"
    return "LL"


def actual_prefix(first_k: int) -> str:
    if first_k == 27:
        return "R"
    if first_k == 31:
        return "LR"
    assert first_k > 31
    return "LL"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    max_p = max(row[0] for table in EXPECTED.values() for row in table.values())
    max_k = max(k_of(n) for n in BLOCKED_PHASES)
    max_companion = (max_p + max_k) // 4
    primes = sieve(math.isqrt(max_companion) + 1)

    predicted = Counter()
    actual = Counter()
    k27_modes = Counter()
    route_predicted = {route.name: Counter() for route in ROUTES}
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
                        assert (p + 27) // 4 == 7 * E
                        assert (p + 31) // 4 == 10 * D

                        g27, mode, skeleton = g27_from_factorization(E, primes)
                        q31 = q31_from_factorization(D, primes)

                        miss27, _i27, _ii27, _f27 = fixed_shift_status(p, 27, primes)
                        miss31, _i31, _ii31, _f31 = fixed_shift_status(p, 31, primes)
                        assert g27 == miss27, (p, E, mode, skeleton, g27, miss27)
                        assert q31 == miss31, (p, D, q31, miss31)

                        pred = selector(g27, q31)
                        first = first_post23_hit(p, destination_k, primes)
                        assert first is not None
                        act = actual_prefix(int(first["k"]))
                        assert pred == act, (p, pred, act, first)

                        predicted[pred] += 1
                        actual[act] += 1
                        route_predicted[route.name][pred] += 1
                        if g27:
                            assert mode is not None
                            k27_modes[mode] += 1
                p += modulus

    assert checked == 148
    assert dict(sorted(predicted.items())) == EXPECTED_SELECTOR_COUNTS
    assert predicted == actual

    report = {
        "analysis": "bec-k27-k31-transition-selector-v1",
        "simultaneous_k19_k23_survivors_checked": checked,
        "selector_counts": dict(sorted(predicted.items())),
        "actual_prefix_counts": dict(sorted(actual.items())),
        "k27_survivor_mode_counts": dict(sorted(k27_modes.items())),
        "route_selector_counts": {
            route: dict(sorted(counts.items()))
            for route, counts in route_predicted.items()
        },
        "theorem": {
            "R": "not G27(E)",
            "LR": "G27(E) and not Q31(D)",
            "LL_prefix": "G27(E) and Q31(D)",
        },
        "failures": 0,
        "claim": (
            "independent finite regression of the range-free exact composition theorem: "
            "the k27 survivor grammar and k31 QR-support criterion select the first two "
            "live post-k23 BEC transitions exactly on all 148 audited survivors"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
