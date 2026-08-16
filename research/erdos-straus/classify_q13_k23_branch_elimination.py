#!/usr/bin/env python3
"""Exact q13 -> k23 recursive branch-elimination theorem.

The merged composite Jacobi-saturation theorem supplies conditional q=13
positive-character sources on h=121 and h=289. This classifier pins the
subroute p mod13=3, proves that the routed seed 78 QR-saturates modulo23,
and records explicit Type-II divisors killing the two negative k=23 centers.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

ORIGIN_BRANCHES = {
    121: {47: 8},
    289: {11: 5, 47: 8},
}
EXCEPTIONAL_K23 = {
    5: 39,
    14: 169,
}


def factorization(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    d = 2
    while d * d <= n:
        while n % d == 0:
            out[d] += 1
            n //= d
        d += 1 if d == 2 else 2
    if n > 1:
        out[n] += 1
    return out


def divisor_square_residues(seed: int, k: int) -> set[int]:
    residues = {1}
    for q, e in factorization(seed).items():
        local = {pow(q, j, k) for j in range(2 * e + 1)}
        residues = {a * b % k for a in residues for b in local}
    return residues


def quadratic_residues(k: int) -> set[int]:
    return {x * x % k for x in range(1, k)}


def analyze() -> dict[str, object]:
    q13_residue = (-23) % 13
    if q13_residue != 3:
        raise SystemExit("q13 -> k23 route residue changed")
    if q13_residue not in quadratic_residues(13):
        raise SystemExit("p mod13=3 is no longer a positive q13 character")

    seed = math.lcm(6, 13)
    if seed != 78:
        raise SystemExit("routed k23 seed changed")
    seed_mask = divisor_square_residues(seed, 23)
    qr23 = quadratic_residues(23)
    if seed_mask != qr23:
        raise SystemExit("seed78 no longer QR-saturates modulo23")

    inv4 = pow(4, -1, 23)
    rows = []
    for p_residue, d in sorted(EXCEPTIONAL_K23.items()):
        center = p_residue * inv4 % 23
        target = (-center) % 23
        if d % 23 != target:
            raise SystemExit(
                f"explicit Type-II divisor changed for p mod23={p_residue}: "
                f"D={d} gives {d % 23}, target={target}"
            )
        if seed * seed % d != 0:
            raise SystemExit(f"D={d} does not divide seed78^2")
        rows.append({
            "p_mod_23": p_residue,
            "C23_mod_23": center,
            "type_ii_target": target,
            "explicit_divisor_D": d,
            "D_divides_78_squared": True,
        })

    return {
        "analysis": "q13-k23-recursive-branch-elimination-v1",
        "origin_extracted_q13_branches": [
            {
                "hard_class": h,
                "origin_shift": 39,
                "fixed_source_residues": {str(q): r for q, r in fixed.items()},
                "origin_miss_extracts": "(13/p)=+1",
            }
            for h, fixed in sorted(ORIGIN_BRANCHES.items())
        ],
        "q13_route": {
            "destination_k": 23,
            "required_p_mod_13": q13_residue,
            "routed_factor": 13,
            "base_seed": 6,
            "routed_seed": seed,
            "seed_divisor_mask": sorted(seed_mask),
            "qr23": sorted(qr23),
            "qr_saturating": True,
        },
        "eliminated_k23_exceptional_centers": rows,
        "theorem": (
            "On either merged q13 extraction branch, refine to p mod13=3. "
            "Then 13|C23 and 78|C23. If p mod23 is 5 or14, fixed k=23 "
            "hits Type II explicitly with D=39 or D=169 respectively."
        ),
        "claim_boundary": (
            "conditional recursive branch elimination only; positive k23 residue branches remain"
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
        print("q13 -> k23 recursive branch elimination")
        print("seed78 QR-saturates modulo23")
        for row in report["eliminated_k23_exceptional_centers"]:
            print(
                f"p mod23={row['p_mod_23']}: "
                f"Type-II target={row['type_ii_target']}, D={row['explicit_divisor_D']}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
