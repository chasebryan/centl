#!/usr/bin/env python3
"""Exact class-conditioned state closures for small prime fixed shifts.

This extends the class-seed law to k=11,19,31,47 and records the branches
where every miss state lies entirely in the quadratic-residue subgroup.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
SHIFTS = (11, 19, 31, 47)

EXPECTED = {
    11: {
        3: (25, 9, 7, 2),
        15: (15, 5, 5, 0),
    },
    19: {
        1: (439, 136, 81, 55),
        5: (132, 44, 28, 16),
        7: (51, 18, 15, 3),
        35: (27, 9, 9, 0),
    },
    31: {
        2: (760, 118, 88, 30),
        10: (75, 18, 18, 0),
        14: (153, 23, 22, 1),
        70: (45, 15, 15, 0),
    },
    47: {
        6: (1079, 196, 116, 80),
        42: (97, 24, 24, 0),
    },
}

RANGE_FREE_BRANCHES = {
    11: {15: (169, 289, 529)},
    19: {35: (121,)},
    31: {10: (169, 289), 70: (529,)},
    47: {42: (121, 289)},
}


def prime_factors(n: int) -> list[int]:
    out = []
    q = 2
    while q * q <= n:
        while n % q == 0:
            out.append(q)
            n //= q
        q += 1
    if n > 1:
        out.append(n)
    return out


def primitive_root(p: int) -> int:
    phi = p - 1
    factors = sorted(set(prime_factors(phi)))
    for g in range(2, p):
        if all(pow(g, phi // q, p) != 1 for q in factors):
            return g
    raise RuntimeError(f"no primitive root for prime {p}")


class Model:
    def __init__(self, k: int):
        self.k = k
        self.n = k - 1
        self.g = primitive_root(k)
        self.log = {pow(self.g, a, k): a for a in range(self.n)}
        self.all_mask = (1 << self.n) - 1
        self.type_i = self.log[(-pow(4, -1, k)) % k]
        self.minus_one = self.n // 2
        self.qr_mask = sum(1 << a for a in range(0, self.n, 2))

    def rotate(self, mask: int, a: int) -> int:
        a %= self.n
        if not a:
            return mask
        return ((mask << a) | (mask >> (self.n - a))) & self.all_mask

    def transition(self, state: tuple[int, int], a: int) -> tuple[int, int]:
        mask, center = state
        return (
            mask | self.rotate(mask, a) | self.rotate(mask, 2 * a),
            (center + a) % self.n,
        )

    def seed_state(self, seed: int) -> tuple[int, int]:
        state = (1, 0)
        for q in prime_factors(seed):
            state = self.transition(state, self.log[q % self.k])
        return state

    def closure(self, seed: int) -> set[tuple[int, int]]:
        start = self.seed_state(seed)
        seen = {start}
        queue = deque([start])
        while queue:
            state = queue.popleft()
            for a in range(self.n):
                nxt = self.transition(state, a)
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        return seen

    def is_miss(self, state: tuple[int, int]) -> bool:
        mask, center = state
        type_ii = (center + self.minus_one) % self.n
        return not ((mask >> self.type_i) & 1) and not ((mask >> type_ii) & 1)

    def center_residue(self, center: int) -> int:
        return pow(self.g, center, self.k)


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def analyze_seed(model: Model, seed: int) -> dict[str, object]:
    states = model.closure(seed)
    misses = {state for state in states if model.is_miss(state)}
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)
    legendre.setdefault("+1", 0)
    legendre.setdefault("-1", 0)
    center_residues = sorted({model.center_residue(center) for _, center in misses})
    qr_residues = sorted({pow(x, 2, model.k) for x in range(1, model.k)})
    miss_masks_qr_only = all((mask & ~model.qr_mask) == 0 for mask, _ in misses)

    row = {
        "seed": seed,
        "states": len(states),
        "hit_states": len(states) - len(misses),
        "miss_states": len(misses),
        "legendre_miss_branches": dict(sorted(legendre.items())),
        "miss_center_residues": center_residues,
        "qr_center_projection_complete": center_residues == qr_residues,
        "all_miss_masks_inside_qr_subgroup": miss_masks_qr_only,
        "negative_character_branch_annihilated": legendre["-1"] == 0,
    }
    expected = EXPECTED[model.k][seed]
    actual = (row["states"], row["miss_states"], legendre["+1"], legendre["-1"])
    if actual != expected:
        raise SystemExit(
            f"k={model.k} seed={seed} regression changed: {actual!r} != {expected!r}"
        )
    if row["negative_character_branch_annihilated"]:
        if not row["qr_center_projection_complete"] or not miss_masks_qr_only:
            raise SystemExit(
                f"k={model.k} seed={seed}: annihilated branch lost QR-support structure"
            )
    return row


def analyze() -> dict[str, object]:
    shifts = {}
    decision_tree = {str(h): [] for h in HARD_CLASSES}

    for k in SHIFTS:
        model = Model(k)
        seeds = {h: class_seed(k, h) for h in HARD_CLASSES}
        reports = {
            str(seed): analyze_seed(model, seed)
            for seed in sorted(set(seeds.values()))
        }
        shifts[str(k)] = {
            "class_seed": {str(h): seeds[h] for h in HARD_CLASSES},
            "seed_reports": reports,
        }
        for seed, classes in RANGE_FREE_BRANCHES.get(k, {}).items():
            report = reports[str(seed)]
            if not report["negative_character_branch_annihilated"]:
                raise SystemExit(f"declared range-free branch failed at k={k}, seed={seed}")
            for h in classes:
                if seeds[h] != seed:
                    raise SystemExit(f"class seed mismatch at k={k}, h={h}")
                decision_tree[str(h)].append({
                    "k": k,
                    "necessary_for_fixed_shift_miss": f"({k}/p)=+1",
                    "factor_support": (
                        f"every prime factor of C_{k}=(p+{k})/4 is a quadratic residue modulo {k}"
                    ),
                })

    return {
        "analysis": "small-prime-class-conditioned-character-atlas-v1",
        "hard_classes": list(HARD_CLASSES),
        "shifts": shifts,
        "survivor_decision_tree": decision_tree,
        "claim": (
            "exact finite-group fixed-shift theorem: on the listed class/shift branches, "
            "a miss has QR-only divisor support; therefore a negative Legendre character "
            "forces a hit. This is range-free at the fixed shift, not an Erdős-Straus proof."
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
        for k in SHIFTS:
            print(f"k={k}")
            for seed, row in report["shifts"][str(k)]["seed_reports"].items():
                print(
                    f"  seed={seed:>2} states={row['states']:>4} misses={row['miss_states']:>3} "
                    f"Legendre={row['legendre_miss_branches']}"
                )
        print("survivor decision tree")
        for h in HARD_CLASSES:
            print(f"  h={h}: {report['survivor_decision_tree'][str(h)]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
