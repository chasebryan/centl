#!/usr/bin/env python3
"""Exact q=11 character-to-companion routing and routed state closures.

This combines the rigid k=11 class theorem with exact fixed-shift state models
at k=35 and k=39.  The routing itself is elementary CRT plus quadratic
reciprocity; the state closures are finite-group theorems.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter, deque

import classify_k35_k39_forced_seeds as seeded
import classify_k35_states as k35
import classify_k39_states as k39

HARD_CLASSES = (169, 289, 529)
Q11_QR = (1, 3, 4, 5, 9)
Q11_ROUTE = {1: 43, 3: 19, 4: 7, 5: 39, 9: 35}
Q13_QR = (1, 3, 4, 9, 10, 12)
Q13_ROUTE = {1: 51, 3: 23, 4: 35, 9: 43, 10: 3, 12: 27}
EXPECTED_JACOBI_PLUS_35 = (1, 3, 4, 9, 11, 12, 13, 16, 17, 27, 29, 33)


def least_routed_shift(q: int, residue: int) -> int:
    """Least positive k with k=3 mod4 and k=-residue mod q."""
    for k in range(3, 4 * q + 1, 4):
        if (k + residue) % q == 0:
            return k
    raise RuntimeError((q, residue))


def closure_with_factors(modulus: int, factors: tuple[int, ...]) -> set[tuple[int, int]]:
    state = seeded.START
    for q in factors:
        state = k35.transition(
            state,
            seeded.direction_for_residue(modulus, q % modulus),
        )
    seen = {state}
    queue = deque([state])
    while queue:
        state = queue.popleft()
        for direction in range(k35.ORDER):
            nxt = k35.transition(state, direction)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return seen


def legendre(a: int, q: int) -> int:
    x = pow(a % q, (q - 1) // 2, q)
    if x == 1:
        return 1
    if x == q - 1:
        return -1
    return 0


def jacobi35(a: int) -> int:
    return legendre(a, 5) * legendre(a, 7)


def k35_report() -> dict[str, object]:
    states = closure_with_factors(35, (3, 11))
    admissible = {s for s in states if s[1] < 12}
    misses = {s for s in admissible if k35.is_miss(s)}
    if (len(states), len(admissible), len(misses)) != (57, 33, 15):
        raise SystemExit(
            f"k35 seed33 closure changed: {(len(states), len(admissible), len(misses))}"
        )

    jacobi_plus = tuple(sorted(a for a in range(1, 35) if __import__('math').gcd(a, 35) == 1 and jacobi35(a) == 1))
    if jacobi_plus != EXPECTED_JACOBI_PLUS_35:
        raise SystemExit(f"Jacobi-plus subgroup changed: {jacobi_plus}")

    classes = {}
    common_mask = None
    for h in HARD_CLASSES:
        center_residue = ((h + 35) // 4) % 35
        center = seeded.direction_for_residue(35, center_residue)
        exact = {s for s in states if s[1] == center}
        exact_misses = {s for s in exact if k35.is_miss(s)}
        if (len(exact), len(exact_misses)) != (2, 1):
            raise SystemExit(
                f"k35 exact-center closure changed for h={h}: "
                f"states={len(exact)} misses={len(exact_misses)}"
            )
        miss = next(iter(exact_misses))
        mask, _ = miss
        residues = tuple(sorted(k35.residue(g) for g in range(k35.ORDER) if (mask >> g) & 1))
        if residues != jacobi_plus:
            raise SystemExit(f"k35 h={h} miss mask is not Jacobi-plus subgroup: {residues}")
        if common_mask is None:
            common_mask = mask
        elif common_mask != mask:
            raise SystemExit("k35 routed exact-class miss masks diverged")
        classes[str(h)] = {
            "C35_mod35": center_residue,
            "center_coordinate": center,
            "exact_center_states": len(exact),
            "exact_center_misses": len(exact_misses),
            "unique_miss_divisor_residues": list(residues),
            "support_theorem": (
                "on p mod 11 = 9, fixed k=35 misses iff every prime factor "
                "of C35 has Jacobi symbol +1 modulo 35"
            ),
        }

    return {
        "routed_condition": "p mod 11 = 9, hence 11 divides C35",
        "forced_factors": [3, 11],
        "seed": 33,
        "states": len(states),
        "hard_admissible_states": len(admissible),
        "miss_states": len(misses),
        "jacobi_plus_subgroup_mod35": list(jacobi_plus),
        "classes": classes,
    }


def k39_report() -> dict[str, object]:
    states = closure_with_factors(39, (2, 11))
    admissible = {s for s in states if s[1] < 12}
    misses = {s for s in admissible if k39.is_miss(s)}
    legendre13 = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)
    legendre13.setdefault("+1", 0)
    legendre13.setdefault("-1", 0)
    expected = (83, 45, 9, 9, 0)
    actual = (
        len(states), len(admissible), len(misses),
        legendre13["+1"], legendre13["-1"],
    )
    if actual != expected:
        raise SystemExit(f"k39 seed22 closure changed: {actual} != {expected}")
    return {
        "routed_condition": "p mod 11 = 5, hence 11 divides C39",
        "forced_factors": [2, 11],
        "seed": 22,
        "states": len(states),
        "hard_admissible_states": len(admissible),
        "miss_states": len(misses),
        "legendre13_miss_branches": dict(sorted(legendre13.items())),
        "range_free_corollary": (
            "for h in {169,289,529}, p mod 11 = 5 and (13/p) = -1 "
            "implies a fixed k=39 hit"
        ),
    }


def verify_route_table(q: int, residues: tuple[int, ...], table: dict[int, int]) -> None:
    computed = {r: least_routed_shift(q, r) for r in residues}
    if computed != table:
        raise SystemExit(f"q={q} route table changed: {computed} != {table}")
    for r, k in table.items():
        if k % 4 != 3 or (r + k) % q:
            raise SystemExit(f"bad route q={q}, r={r}, k={k}")


def analyze() -> dict[str, object]:
    verify_route_table(11, Q11_QR, Q11_ROUTE)
    verify_route_table(13, Q13_QR, Q13_ROUTE)
    return {
        "analysis": "k11-character-to-companion-routing-v1",
        "routing_lemma": (
            "for p=1 mod4 and odd prime q, (q/p)=+1 implies p mod q is a "
            "quadratic residue; the unique k mod4q with k=3 mod4 and "
            "k=-p modq satisfies q | C_k=(p+k)/4"
        ),
        "q11_quadratic_residues": list(Q11_QR),
        "q11_least_shift_routes": {str(r): Q11_ROUTE[r] for r in Q11_QR},
        "q13_quadratic_residues": list(Q13_QR),
        "q13_least_shift_routes": {str(r): Q13_ROUTE[r] for r in Q13_QR},
        "k35_routed": k35_report(),
        "k39_routed": k39_report(),
        "claim": (
            "exact character-to-factor routing plus exact fixed-shift finite-group "
            "closures; no universal shift ceiling and no Erdős-Straus proof"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("q=11 routes:", report["q11_least_shift_routes"])
        print("k35 routed:", report["k35_routed"])
        print("k39 routed:", report["k39_routed"])
        print("q=13 routes:", report["q13_least_shift_routes"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
