#!/usr/bin/env python3
"""Exact k=7 support theorem and rigid positive k=23 route atlas.

The state model is the divisor-square residue closure of C_k^2 in the unit
group modulo k. All closures below are exact finite-group computations.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
QR7 = {1, 2, 4}
QR11 = {1, 3, 4, 5, 9}
QR19 = {1, 4, 5, 6, 7, 9, 11, 16, 17}
QR23 = {1, 2, 3, 4, 6, 8, 9, 12, 13, 16, 18}
JACOBI_PLUS_15 = {1, 2, 4, 8}
RIGID_K23_RESIDUES = (2, 3, 4, 6, 8, 9, 12, 13, 16, 18)


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

    def mask_residues(self, mask: int) -> set[int]:
        return {u for i, u in enumerate(self.units) if (mask >> i) & 1}


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def route_shift(q: int, p_residue: int) -> int:
    for k in range(3, 4 * q, 4):
        if (p_residue + k) % q == 0:
            return k
    raise RuntimeError((q, p_residue))


def support_rows(model: UnitStateModel, seed: int) -> dict[int, list[set[int]]]:
    rows: dict[int, list[set[int]]] = {}
    for mask, center in model.closure(seed):
        if not model.is_miss((mask, center)):
            continue
        rows.setdefault(model.p_residue(center), []).append(model.mask_residues(mask))
    return rows


def analyze_k7() -> dict[str, object]:
    seeds = {h: class_seed(7, h) for h in HARD_CLASSES}
    if set(seeds.values()) != {2}:
        raise SystemExit(f"unexpected k=7 hard seeds: {seeds}")
    model = UnitStateModel(7)
    states = model.closure(2)
    misses = [s for s in states if model.is_miss(s)]
    rows = support_rows(model, 2)
    if len(states) != 9 or len(misses) != 3:
        raise SystemExit("k=7 closure constants changed")
    if set(rows) != QR7:
        raise SystemExit(f"k=7 miss centers changed: {sorted(rows)}")
    if any(len(masks) != 1 or masks[0] != QR7 for masks in rows.values()):
        raise SystemExit("k=7 miss masks are no longer exactly QR(7)")
    return {
        "hard_class_seed": 2,
        "states": len(states),
        "miss_states": len(misses),
        "hard_p_mod_7": sorted(QR7),
        "unique_miss_mask": sorted(QR7),
        "theorem": (
            "For every Mordell-hard prime, fixed k=7 misses iff every prime "
            "factor of C_7=(p+7)/4 is a quadratic residue modulo 7."
        ),
    }


def analyze_k23() -> dict[str, object]:
    seeds = {h: class_seed(23, h) for h in HARD_CLASSES}
    if set(seeds.values()) != {6}:
        raise SystemExit(f"unexpected k=23 hard seeds: {seeds}")
    model = UnitStateModel(23)
    states = model.closure(6)
    rows = support_rows(model, 6)
    total_misses = sum(len(v) for v in rows.values())
    if len(states) != 49 or total_misses != 15:
        raise SystemExit("k=23 closure constants changed")

    rigid = {}
    for r in RIGID_K23_RESIDUES:
        masks = rows.get(r, [])
        if len(masks) != 1 or masks[0] != QR23:
            raise SystemExit(f"k=23 residue {r} lost rigid QR support")
        rigid[str(r)] = {
            "route_shift": route_shift(23, r),
            "unique_miss_mask": sorted(QR23),
        }

    exceptional = {
        str(r): sorted(len(mask) for mask in rows.get(r, []))
        for r in (1, 5, 14)
    }
    if exceptional != {"1": [9, 11, 21], "5": [19], "14": [19]}:
        raise SystemExit(f"k=23 exceptional geometry changed: {exceptional}")

    return {
        "hard_class_seed": 6,
        "states": len(states),
        "miss_states": total_misses,
        "rigid_qr_support_p_mod_23": rigid,
        "exceptional_p_mod_23_mask_sizes": exceptional,
        "theorem": (
            "For p mod23 in {2,3,4,6,8,9,12,13,16,18}, a fixed k=23 "
            "miss is equivalent to QR-only prime support of C_23 modulo23. "
            "The only exceptional miss residues are 1,5,14."
        ),
    }


def assert_exact_support(k: int, seed: int, allowed: set[int], expected_states: int, expected_misses: int) -> None:
    model = UnitStateModel(k)
    states = model.closure(seed)
    misses = [s for s in states if model.is_miss(s)]
    if (len(states), len(misses)) != (expected_states, expected_misses):
        raise SystemExit(f"k={k} seed={seed} closure changed")
    if any(model.mask_residues(mask) != allowed for mask, _ in misses):
        raise SystemExit(f"k={k} seed={seed} lost exact support mask")


def analyze_low_routes() -> dict[str, object]:
    # r=8 -> 23|C15, valid on all hard classes.
    model15 = UnitStateModel(15)
    rows15 = support_rows(model15, 46)
    if len(model15.closure(46)) != 12:
        raise SystemExit("k=15 seed46 closure changed")
    for h in HARD_CLASSES:
        p15 = h % 15
        masks = rows15.get(p15, [])
        if len(masks) != 1 or masks[0] != JACOBI_PLUS_15:
            raise SystemExit(f"k=15 routed support changed for h={h}")

    # r=12 -> 23|C11. On h=169,289,529 the class seed is 15.
    assert_exact_support(11, 345, QR11, 15, 5)

    # r=4 -> 23|C19. h=289 uses class seed7; h=121 uses class seed35.
    assert_exact_support(19, 161, QR19, 27, 9)
    assert_exact_support(19, 805, QR19, 27, 9)

    routes = {
        "p_mod_23_8": {
            "classes": list(HARD_CLASSES),
            "lower_shift": 15,
            "lower_scale": 46,
            "upper_shift": 23,
            "upper_scale": 6,
            "residual_equation": "3*B - 23*A = 1",
            "gcd_A_B": 1,
            "lower_support": "every prime factor of A is Jacobi-plus modulo 15",
            "upper_support": "every prime factor of B is a quadratic residue modulo 23",
        },
        "p_mod_23_12": {
            "classes": [169, 289, 529],
            "lower_shift": 11,
            "lower_scale": 345,
            "upper_shift": 23,
            "upper_scale": 6,
            "residual_equation": "2*B - 115*A = 1",
            "gcd_A_B": 1,
            "lower_support": "every prime factor of A is a quadratic residue modulo 11",
            "upper_support": "every prime factor of B is a quadratic residue modulo 23",
        },
        "p_mod_23_4_h289": {
            "classes": [289],
            "lower_shift": 19,
            "lower_scale": 161,
            "upper_shift": 23,
            "upper_scale": 6,
            "residual_equation": "6*B - 161*A = 1",
            "gcd_A_B": 1,
            "lower_support": "every prime factor of A is a quadratic residue modulo 19",
            "upper_support": "every prime factor of B is a quadratic residue modulo 23",
        },
        "p_mod_23_4_h121": {
            "classes": [121],
            "lower_shift": 19,
            "lower_scale": 805,
            "upper_shift": 23,
            "upper_scale": 6,
            "residual_equation": "6*B - 805*A = 1",
            "gcd_A_B": 1,
            "lower_support": "every prime factor of A is a quadratic residue modulo 19",
            "upper_support": "every prime factor of B is a quadratic residue modulo 23",
        },
        "p_mod_23_16": {
            "classes": list(HARD_CLASSES),
            "lower_shift": 7,
            "lower_scale": 46,
            "upper_shift": 23,
            "upper_scale": 6,
            "residual_equation": "3*B - 23*A = 2",
            "gcd_A_B_divides": 2,
            "lower_support": "every prime factor of A is a quadratic residue modulo 7",
            "upper_support": "every prime factor of B is a quadratic residue modulo 23",
        },
    }
    return routes


def analyze() -> dict[str, object]:
    return {
        "analysis": "k7-k23-rigid-support-route-atlas-v1",
        "k7": analyze_k7(),
        "k23": analyze_k23(),
        "low_shift_rigid_routes": analyze_low_routes(),
        "claim_boundary": (
            "Exact fixed-shift support and affine-coupling theorems only. "
            "The residual equations admit finite realizations and are not contradictions."
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
        print("k=7 universal hard support: 9 states / 3 exact QR-support misses")
        print("k=23: 49 states / 15 misses; ten positive residues are rigid QR-support branches")
        for name, row in report["low_shift_rigid_routes"].items():
            print(f"{name}: {row['residual_equation']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
