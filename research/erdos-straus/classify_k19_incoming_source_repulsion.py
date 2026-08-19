#!/usr/bin/env python3
"""Exact h=289 incoming-positive-source repulsion theorem at k=19."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

QR19 = {1, 4, 5, 6, 7, 9, 11, 16, 17}
BASE_SUBGROUP = {1, 7, 11}
REPELLING_QR19 = QR19 - BASE_SUBGROUP
NEGATIVE_MISS_CENTERS = {2, 3, 14}

# D=7^a q^b. Every exponent <=2, hence D|(7q)^2.
TYPE_II_MONOMIALS = {
    4: {2: (1, 1), 3: (0, 1), 14: (2, 1)},
    5: {2: (2, 2), 3: (1, 2), 14: (0, 2)},
    6: {2: (2, 1), 3: (1, 1), 14: (0, 1)},
    9: {2: (0, 1), 3: (2, 1), 14: (1, 1)},
    16: {2: (0, 2), 3: (2, 2), 14: (1, 2)},
    17: {2: (1, 2), 3: (0, 2), 14: (2, 2)},
}

NAMED_SOURCES = {
    11: "positive q11 non-repelling subgroup control",
    17: "extracted h=289 q17 source",
    23: "merged positive q23 source",
    43: "extracted h=289 q43 source",
    47: "merged h=289 q47 source",
}


def factorization(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    q = 2
    while q * q <= n:
        while n % q == 0:
            out[q] += 1
            n //= q
        q += 1 if q == 2 else 2
    if n > 1:
        out[n] += 1
    return out


def divisor_square_residues(seed: int, k: int) -> set[int]:
    residues = {1}
    for q, e in factorization(seed).items():
        local = {pow(q, j, k) for j in range(2 * e + 1)}
        residues = {a * b % k for a in residues for b in local}
    return residues


def augmented_residues(base_seed: int, k: int, q_residue: int) -> set[int]:
    base = divisor_square_residues(base_seed, k)
    local_q = {pow(q_residue, j, k) for j in range(3)}
    return {a * b % k for a in base for b in local_q}


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
        for q, e in factorization(seed).items():
            for _ in range(e):
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


def monomial_mod19(q_residue: int, exponents: tuple[int, int]) -> int:
    a, b = exponents
    return pow(7, a, 19) * pow(q_residue, b, 19) % 19


def analyze() -> dict[str, object]:
    if math.gcd(210, (289 + 19) // 4) != 7:
        raise SystemExit("h=289 k19 class seed is no longer 7")
    base_mask = divisor_square_residues(7, 19)
    if base_mask != BASE_SUBGROUP:
        raise SystemExit(f"seed7 mask changed: {sorted(base_mask)}")
    if not BASE_SUBGROUP < QR19:
        raise SystemExit("seed7 mask is not a proper QR(19) subgroup")

    # Reproduce the exact ordinary seed7 miss-center geometry.
    model = UnitStateModel(19)
    states = model.closure(7)
    misses = [state for state in states if model.is_miss(state)]
    miss_centers = {model.p_residue(center) for _, center in misses}
    negative_centers = {
        r for r in miss_centers
        if pow(r, 9, 19) == 18
    }
    if len(states) != 51 or len(misses) != 18:
        raise SystemExit("ordinary seed7 closure constants changed")
    if negative_centers != NEGATIVE_MISS_CENTERS:
        raise SystemExit(f"negative miss centers changed: {sorted(negative_centers)}")

    inv4 = pow(4, -1, 19)
    targets = {r: (-(r * inv4)) % 19 for r in sorted(NEGATIVE_MISS_CENTERS)}
    if targets != {2: 9, 3: 4, 14: 6}:
        raise SystemExit(f"unexpected Type-II targets: {targets}")

    rows = []
    for r in sorted(QR19):
        mask = augmented_residues(7, 19, r)
        saturates = mask == QR19
        expected = r in REPELLING_QR19
        if saturates != expected:
            raise SystemExit(
                f"symbolic seed7q saturation mismatch r={r}: {saturates} != {expected}"
            )
        row = {
            "q_mod_19": r,
            "repelling": expected,
            "augmented_mask": sorted(mask),
        }
        if expected:
            certs = []
            for p19 in sorted(NEGATIVE_MISS_CENTERS):
                exponents = TYPE_II_MONOMIALS[r][p19]
                if any(e < 0 or e > 2 for e in exponents):
                    raise SystemExit((r, p19, exponents))
                actual = monomial_mod19(r, exponents)
                if actual != targets[p19]:
                    raise SystemExit(
                        f"bad D monomial q19={r} p19={p19}: "
                        f"{actual} != {targets[p19]}"
                    )
                certs.append({
                    "p_mod_19": p19,
                    "type_ii_target": targets[p19],
                    "D_exponents_7_q": list(exponents),
                })
            row["explicit_type_ii_certificates"] = certs
        rows.append(row)

    named = []
    for q, label in NAMED_SOURCES.items():
        r = q % 19
        named.append({
            "q": q,
            "q_mod_19": r,
            "source": label,
            "positive_mod_19": r in QR19,
            "repels_negative_h289_k19_centers": r in REPELLING_QR19,
        })

    return {
        "analysis": "h289-k19-incoming-positive-source-repulsion-v1",
        "ordinary_seed7_closure": {
            "states": len(states),
            "misses": len(misses),
            "negative_miss_centers": sorted(negative_centers),
        },
        "qr19": sorted(QR19),
        "seed7_subgroup": sorted(BASE_SUBGROUP),
        "repelling_source_residues": sorted(REPELLING_QR19),
        "type_ii_targets": {str(k): v for k, v in targets.items()},
        "source_residue_rows": rows,
        "named_current_sources": named,
        "theorem": (
            "On hard class h=289, let a positive-character prime q route into C19. "
            "If q mod19 lies outside the seed7 subgroup {1,7,11}, then seed7q "
            "QR-saturates modulo19 and the three ordinary negative seed7 miss centers "
            "p mod19=2,3,14 are impossible."
        ),
        "claim_boundary": (
            "conditional fixed k=19 elimination on h=289; source residues 1,7,11 are sharp controls"
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
        print("h289 k19 repelling q residues:", report["repelling_source_residues"])
        print("negative miss centers:", report["ordinary_seed7_closure"]["negative_miss_centers"])
        for row in report["named_current_sources"]:
            print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
