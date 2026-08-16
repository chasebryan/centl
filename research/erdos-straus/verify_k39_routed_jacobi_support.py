#!/usr/bin/env python3
"""Exact Jacobi-plus support theorem for the q=11 -> k=39 routed branch."""
from __future__ import annotations

import argparse
import json
import math

import classify_k11_routed_companion_states as routed
import classify_k39_states as k39

EXPECTED_JACOBI_PLUS_39 = (1, 2, 4, 5, 8, 10, 11, 16, 20, 22, 25, 32)


def legendre(a: int, q: int) -> int:
    x = pow(a % q, (q - 1) // 2, q)
    if x == 1:
        return 1
    if x == q - 1:
        return -1
    return 0


def jacobi39(a: int) -> int:
    return legendre(a, 3) * legendre(a, 13)


def analyze() -> dict[str, object]:
    states = routed.closure_with_factors(39, (2, 11))
    admissible = {s for s in states if s[1] < 12}
    misses = {s for s in admissible if k39.is_miss(s)}
    if (len(states), len(admissible), len(misses)) != (83, 45, 9):
        raise SystemExit("routed k39 closure constants changed")

    jacobi_plus = tuple(
        sorted(a for a in range(1, 39) if math.gcd(a, 39) == 1 and jacobi39(a) == 1)
    )
    if jacobi_plus != EXPECTED_JACOBI_PLUS_39:
        raise SystemExit(f"Jacobi-plus subgroup changed: {jacobi_plus}")

    rows = []
    distinct_masks = set()
    for mask, center in sorted(misses, key=lambda s: (s[1], s[0])):
        residues = tuple(
            sorted(k39.residue(g) for g in range(k39.core.ORDER) if (mask >> g) & 1)
        )
        distinct_masks.add(residues)
        if any(jacobi39(a) != 1 for a in residues):
            raise SystemExit(
                f"routed k39 miss escaped Jacobi-plus subgroup: center={center}, D={residues}"
            )
        center_residue = k39.residue(center)
        if jacobi39(center_residue) != 1:
            raise SystemExit(f"routed k39 miss center is Jacobi-negative: {center_residue}")
        rows.append({
            "center_coordinate": center,
            "center_residue": center_residue,
            "divisor_residues": list(residues),
        })

    type_i_residue = k39.residue(k39.TYPE_I)
    minus_one_residue = (-1) % 39
    if jacobi39(type_i_residue) != -1 or jacobi39(minus_one_residue) != -1:
        raise SystemExit("k39 targets no longer lie in the Jacobi-negative coset")

    # If all prime factors of C39 are Jacobi-plus, every divisor residue of
    # C39^2 is Jacobi-plus.  Since C39 itself is Jacobi-plus on this routed
    # miss branch, both -1/4 and -C39 are Jacobi-negative and cannot occur.
    return {
        "analysis": "k39-routed-jacobi-support-v1",
        "seed": 22,
        "states": len(states),
        "hard_admissible_states": len(admissible),
        "miss_states": len(misses),
        "jacobi_plus_subgroup_mod39": list(jacobi_plus),
        "distinct_miss_divisor_masks": [list(row) for row in sorted(distinct_masks)],
        "all_miss_masks_subset_of_Jacobi_plus": True,
        "type_i_residue": type_i_residue,
        "type_i_jacobi39": -1,
        "minus_one_jacobi39": -1,
        "support_theorem": (
            "for h in {169,289,529} and p mod11=5, fixed k=39 misses iff "
            "every prime factor of C39=(p+39)/4 has Jacobi symbol +1 modulo39"
        ),
        "rows": rows,
        "claim": "exact fixed-shift support theorem from the complete seed-22 closure",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("Jacobi-plus subgroup:", report["jacobi_plus_subgroup_mod39"])
        print("distinct miss masks:", report["distinct_miss_divisor_masks"])
        print(report["support_theorem"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
