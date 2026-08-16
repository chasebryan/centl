#!/usr/bin/env python3
"""Exact routed bottlenecks arising from the k=19 and k=23 branches.

This file uses only the multiplicative unit group modulo the fixed shift.
A state records divisor-square residues of C_k^2 together with C_k mod k.
The closures are finite and exact; no prime-range extrapolation is used.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import deque

HARD_CLASSES = (1, 121, 169, 289, 361, 529)


def prime_factors(n: int) -> list[int]:
    out: list[int] = []
    q = 2
    while q * q <= n:
        while n % q == 0:
            out.append(q)
            n //= q
        q += 1 if q == 2 else 2
    if n > 1:
        out.append(n)
    return out


def legendre(a: int, p: int) -> int:
    a %= p
    if a == 0:
        return 0
    v = pow(a, (p - 1) // 2, p)
    return -1 if v == p - 1 else 1


def route_shift(q: int, p_residue: int) -> int:
    for k in range(3, 4 * q, 4):
        if (p_residue + k) % q == 0:
            return k
    raise RuntimeError((q, p_residue))


class UnitStateModel:
    def __init__(self, k: int):
        self.k = k
        self.units = [u for u in range(1, k) if math.gcd(u, k) == 1]
        self.index = {u: i for i, u in enumerate(self.units)}
        self.type_i = (-pow(4, -1, k)) % k

    def transition(self, state: tuple[int, int], a: int) -> tuple[int, int]:
        mask, center = state
        out = 0
        local = (1, a, a * a % self.k)
        for i, u in enumerate(self.units):
            if (mask >> i) & 1:
                for v in local:
                    out |= 1 << self.index[u * v % self.k]
        return out, center * a % self.k

    def seed_state(self, seed: int) -> tuple[int, int]:
        state = (1 << self.index[1], 1)
        for q in prime_factors(seed):
            state = self.transition(state, q % self.k)
        return state

    def closure(self, seed: int) -> set[tuple[int, int]]:
        start = self.seed_state(seed)
        seen = {start}
        queue = deque([start])
        while queue:
            state = queue.popleft()
            for a in self.units:
                nxt = self.transition(state, a)
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        return seen

    def is_miss(self, state: tuple[int, int]) -> bool:
        mask, center = state
        type_ii = (-center) % self.k
        return (
            not ((mask >> self.index[self.type_i]) & 1)
            and not ((mask >> self.index[type_ii]) & 1)
        )

    def p_residue(self, center: int) -> int:
        return 4 * center % self.k

    def mask_residues(self, mask: int) -> list[int]:
        return [u for i, u in enumerate(self.units) if (mask >> i) & 1]


def analyze_k23() -> dict[str, object]:
    model = UnitStateModel(23)
    states = model.closure(6)
    misses = [s for s in states if model.is_miss(s)]
    negative = [
        s for s in misses
        if legendre(model.p_residue(s[1]), 23) == -1
    ]
    routes = sorted(
        (model.p_residue(center), route_shift(23, model.p_residue(center)))
        for _, center in negative
    )
    if (len(states), len(misses), len(negative), routes) != (
        49,
        15,
        2,
        [(5, 87), (14, 55)],
    ):
        raise SystemExit("k=23 routed-negative regression changed")
    return {
        "seed": 6,
        "states": len(states),
        "miss_states": len(misses),
        "negative_character_miss_states": len(negative),
        "negative_character_p_residue_routes": [
            {"p_mod_23": r, "routed_shift": k} for r, k in routes
        ],
        "theorem": (
            "For every Mordell-hard prime, a k=23 miss with (23/p)=-1 "
            "forces p mod 23 to be 5 or 14. These cases route the factor 23 "
            "into C_87 or C_55 respectively."
        ),
    }


def analyze_k15() -> dict[str, object]:
    # On h=121, p mod 19 = 4 routes 19 into C_15. The h=121 class also
    # forces 2|C_15, so the routed seed is 38.
    model = UnitStateModel(15)
    states = model.closure(38)
    misses = [s for s in states if model.is_miss(s)]
    exact = [s for s in misses if model.p_residue(s[1]) == 1]
    if len(exact) != 1:
        raise SystemExit("k=15 exact h=121 routed branch is no longer unique")
    mask, center = exact[0]
    residues = model.mask_residues(mask)
    jacobi_plus = [
        u for u in model.units
        if legendre(u, 3) * legendre(u, 5) == 1
    ]
    expected = [1, 2, 4, 8]
    if residues != expected or jacobi_plus != expected:
        raise SystemExit("k=15 unique miss mask lost Jacobi-plus identity")
    if (len(states), len(misses), model.p_residue(center)) != (12, 4, 1):
        raise SystemExit("k=15 routed closure constants changed")
    return {
        "hard_class": 121,
        "routing_p_mod_19": 4,
        "routed_factor": 19,
        "shift": 15,
        "class_seed": 2,
        "routed_seed": 38,
        "states": len(states),
        "miss_states_all_centers": len(misses),
        "exact_class_miss_states": len(exact),
        "exact_p_mod_15": 1,
        "unique_miss_divisor_mask": residues,
        "jacobi_plus_subgroup_mod_15": jacobi_plus,
        "theorem": (
            "On h=121 and p mod 19=4, fixed k=15 misses iff every prime "
            "factor of C_15=(p+15)/4 lies in the Jacobi-plus subgroup "
            "{1,2,4,8} mod 15."
        ),
    }


def analyze_k55() -> dict[str, object]:
    # On the k=23 negative branch p mod23=14, 23|C_55. For h=1,169 the
    # class-conditioned k=55 seed is 14, so the routed seed is 14*23=322.
    model = UnitStateModel(55)
    states = model.closure(322)
    misses = [s for s in states if model.is_miss(s)]
    class_rows = []
    for h in (1, 169):
        exact = [
            s for s in misses
            if model.p_residue(s[1]) % 5 == h % 5
        ]
        if len(exact) != 1:
            raise SystemExit(f"k=55 routed branch h={h} lost unique miss")
        mask, center = exact[0]
        p55 = model.p_residue(center)
        if p55 % 11 != 1:
            raise SystemExit(f"k=55 routed branch h={h} no longer forces p mod11=1")
        class_rows.append({
            "h_mod_840": h,
            "p_mod_55_at_miss": p55,
            "p_mod_11_at_miss": p55 % 11,
            "unique_miss_divisor_mask_size": len(model.mask_residues(mask)),
        })
    if (len(states), len(misses)) != (85, 5):
        raise SystemExit("k=55 routed seed-322 closure constants changed")
    return {
        "routing_p_mod_23": 14,
        "routed_factor": 23,
        "shift": 55,
        "classes": [1, 169],
        "class_seed": 14,
        "routed_seed": 322,
        "states": len(states),
        "miss_states_all_centers": len(misses),
        "exact_class_rows": class_rows,
        "theorem": (
            "For h in {1,169} and p mod23=14, a fixed k=55 miss forces "
            "p mod11=1. Therefore either k=55 hits, or 11 is routed next "
            "into C_43=(p+43)/4."
        ),
    }


def analyze() -> dict[str, object]:
    return {
        "analysis": "k19-k23-routed-bottlenecks-v1",
        "k23_negative_branch": analyze_k23(),
        "k19_to_k15_branch": analyze_k15(),
        "k23_to_k55_branch": analyze_k55(),
        "claim_boundary": (
            "All stated closures are exact finite-group fixed-shift results. "
            "They constrain routed survivor branches but do not prove a finite "
            "universal shift ceiling or the Erdős-Straus conjecture."
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
        k23 = report["k23_negative_branch"]
        k15 = report["k19_to_k15_branch"]
        k55 = report["k23_to_k55_branch"]
        print(
            f"k23: {k23['states']} states, {k23['miss_states']} misses, "
            f"{k23['negative_character_miss_states']} negative-character misses"
        )
        print(
            f"k15 routed h121: {k15['exact_class_miss_states']} exact miss, "
            f"mask={k15['unique_miss_divisor_mask']}"
        )
        print(
            f"k55 routed h1/h169: {k55['states']} states, "
            f"exact misses force p mod11=1"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
