#!/usr/bin/env python3
"""Exact residual-gcd atlas for the current multi-source QR-saturation synergies."""
from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass

HARD_CLASSES = (1, 121, 169, 289, 361, 529)

PAIR_SYNERGIES = (
    (121, 31, 2, (19, 47), 1786, (7, 16)),
    (121, 79, 10, (19, 23), 4370, (16, 13)),
    (169, 19, 1, (11, 23), 253, (3, 4)),
    (169, 83, 21, (11, 23), 5313, (5, 9)),
    (169, 83, 21, (11, 31), 7161, (5, 10)),
    (169, 83, 21, (23, 31), 14973, (9, 10)),
    (169, 167, 42, (11, 31), 14322, (9, 19)),
    (529, 19, 1, (11, 23), 253, (3, 4)),
)

TRIPLE_SYNERGIES = (
    (169, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
    (289, 167, 6, (11, 31, 47), 96162, (9, 19, 21)),
    (529, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (529, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
)

EXPECTED_PAIR_FULL_COPRIME = {
    (121, 79, (19, 23)),
    (169, 19, (11, 23)),
    (529, 19, (11, 23)),
}
EXPECTED_NONTRIVIAL_GCD_VALUES = {2, 3, 13, 17}


@dataclass(frozen=True)
class Form:
    name: str
    seed: int
    slope: int
    intercept: int

    def value(self, t: int) -> int:
        return self.slope * t + self.intercept


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def route_parameter(h: int, sources: tuple[int, ...], residues: tuple[int, ...]) -> tuple[int, int]:
    modulus = math.prod(sources)
    matches = [
        r
        for r in range(modulus)
        if all((840 * r + h) % q == a for q, a in zip(sources, residues))
    ]
    if len(matches) != 1:
        raise SystemExit(
            f"expected one routed parameter class for h={h}, sources={sources}: {matches}"
        )
    return matches[0], modulus


def residual_form(h: int, shift: int, seed: int, r0: int, modulus: int, name: str) -> Form:
    numerator0 = 840 * r0 + h + shift
    if numerator0 % (4 * seed):
        raise SystemExit((h, shift, seed, r0, numerator0))
    slope_numerator = 210 * modulus
    if slope_numerator % seed:
        raise SystemExit((h, shift, seed, modulus, slope_numerator))
    return Form(name, seed, slope_numerator // seed, numerator0 // (4 * seed))


def exact_gcd_values(a: Form, b: Form) -> tuple[int, tuple[int, ...]]:
    determinant = abs(a.slope * b.intercept - b.slope * a.intercept)
    if determinant == 0:
        raise SystemExit(f"parallel residual forms: {a} {b}")

    # Any common divisor of a(t), b(t) divides this determinant. Divisibility by
    # each divisor of the determinant depends only on t modulo determinant, so
    # one complete residue period gives the exact range-free gcd value set.
    values = {
        math.gcd(a.value(t), b.value(t))
        for t in range(determinant)
    }
    if any(determinant % g for g in values):
        raise SystemExit((a, b, determinant, values))
    return determinant, tuple(sorted(values))


def encode_synergy(kind: str, row: tuple) -> dict[str, object]:
    h, destination, base, sources, combined_seed, residues = row
    r0, modulus = route_parameter(h, sources, residues)

    forms = [
        residual_form(h, q, class_seed(q, h), r0, modulus, f"A{q}")
        for q in sources
    ]
    forms.append(residual_form(h, destination, combined_seed, r0, modulus, "R"))

    gcd_rows = []
    for i, left in enumerate(forms):
        for right in forms[i + 1 :]:
            determinant, values = exact_gcd_values(left, right)
            gcd_rows.append(
                {
                    "left": left.name,
                    "right": right.name,
                    "determinant": determinant,
                    "values": list(values),
                }
            )

    source_names = {f"A{q}" for q in sources}
    source_pairs_coprime = all(
        row_["values"] == [1]
        for row_ in gcd_rows
        if row_["left"] in source_names and row_["right"] in source_names
    )
    all_residuals_pairwise_coprime = all(row_["values"] == [1] for row_ in gcd_rows)

    return {
        "kind": kind,
        "hard_class": h,
        "destination_k": destination,
        "base_seed": base,
        "source_primes": list(sources),
        "required_source_residues": list(residues),
        "combined_seed": combined_seed,
        "route_parameter_r0": r0,
        "route_parameter_modulus": modulus,
        "forms": [
            {
                "name": f.name,
                "seed": f.seed,
                "slope": f.slope,
                "intercept": f.intercept,
            }
            for f in forms
        ],
        "gcd_pairs": gcd_rows,
        "source_residuals_pairwise_coprime": source_pairs_coprime,
        "all_residuals_pairwise_coprime": all_residuals_pairwise_coprime,
    }


def analyze() -> dict[str, object]:
    pair_rows = [encode_synergy("pair", row) for row in PAIR_SYNERGIES]
    triple_rows = [encode_synergy("triple", row) for row in TRIPLE_SYNERGIES]

    pair_source_coprime = sum(bool(row["source_residuals_pairwise_coprime"]) for row in pair_rows)
    triple_source_coprime = sum(bool(row["source_residuals_pairwise_coprime"]) for row in triple_rows)
    pair_full_coprime = {
        (row["hard_class"], row["destination_k"], tuple(row["source_primes"]))
        for row in pair_rows
        if row["all_residuals_pairwise_coprime"]
    }
    nontrivial = {
        g
        for row in pair_rows + triple_rows
        for pair in row["gcd_pairs"]
        for g in pair["values"]
        if g > 1
    }

    if pair_source_coprime != 8:
        raise SystemExit(f"pair source-coprime count changed: {pair_source_coprime}")
    if triple_source_coprime != 5:
        raise SystemExit(f"triple source-coprime count changed: {triple_source_coprime}")
    if pair_full_coprime != EXPECTED_PAIR_FULL_COPRIME:
        raise SystemExit(f"full-coprime pair atlas changed: {pair_full_coprime}")
    if nontrivial != EXPECTED_NONTRIVIAL_GCD_VALUES:
        raise SystemExit(f"nontrivial residual gcd values changed: {nontrivial}")

    return {
        "analysis": "routed-residual-gcd-atlas-v1",
        "pair_synergy_count": len(pair_rows),
        "triple_synergy_count": len(triple_rows),
        "pair_source_residuals_pairwise_coprime": pair_source_coprime,
        "triple_source_residuals_pairwise_coprime": triple_source_coprime,
        "fully_pairwise_coprime_pair_synergies": [
            {"hard_class": h, "destination_k": k, "source_primes": list(sources)}
            for h, k, sources in sorted(pair_full_coprime)
        ],
        "only_nontrivial_gcd_values_anywhere": sorted(nontrivial),
        "pair_synergies": pair_rows,
        "triple_synergies": triple_rows,
        "claim": (
            "exact range-free gcd atlas for seed-stripped source residuals and the "
            "multi-source-saturated destination residual on the current synergy branches"
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
        print(f"pair synergies: {report['pair_synergy_count']}")
        print(f"triple synergies: {report['triple_synergy_count']}")
        print(
            "pair source residuals pairwise coprime: "
            f"{report['pair_source_residuals_pairwise_coprime']}"
        )
        print(
            "triple source residuals pairwise coprime: "
            f"{report['triple_source_residuals_pairwise_coprime']}"
        )
        print(
            "only nontrivial gcd values: "
            f"{report['only_nontrivial_gcd_values_anywhere']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
