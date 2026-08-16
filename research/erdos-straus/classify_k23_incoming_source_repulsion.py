#!/usr/bin/env python3
"""Exact incoming-positive-source repulsion theorem at fixed k=23."""
from __future__ import annotations

import argparse
import json
from collections import Counter

QR23 = {1, 2, 3, 4, 6, 8, 9, 12, 13, 16, 18}
NONIDENTITY_QR23 = QR23 - {1}

# Exponent triples (a,b,c) encode D=2^a 3^b q^c.
# Every exponent is <=2, so D divides (6q)^2.
TYPE_II_MONOMIALS = {
    # q mod23: {p mod23: (a,b,c)}
    2: {5: (2, 0, 2), 14: (1, 0, 2)},
    3: {5: (2, 1, 2), 14: (1, 1, 2)},
    4: {5: (0, 0, 2), 14: (1, 0, 1)},
    6: {5: (0, 1, 2), 14: (0, 2, 1)},
    8: {5: (1, 0, 1), 14: (0, 0, 1)},
    9: {5: (0, 2, 2), 14: (1, 1, 1)},
    12: {5: (0, 2, 1), 14: (0, 2, 2)},
    13: {5: (0, 1, 1), 14: (0, 0, 2)},
    16: {5: (0, 0, 1), 14: (2, 1, 1)},
    18: {5: (1, 1, 1), 14: (0, 1, 1)},
}

NAMED_SOURCES = {
    13: "merged recursive q13 source",
    31: "merged h=169/289/529 q31 source",
    47: "identity-residue negative control",
    59: "merged h=361 q59 source",
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


def monomial_value_mod23(q_residue: int, exponents: tuple[int, int, int]) -> int:
    a, b, c = exponents
    return pow(2, a, 23) * pow(3, b, 23) * pow(q_residue, c, 23) % 23


def analyze() -> dict[str, object]:
    inv4 = pow(4, -1, 23)
    targets = {
        p_residue: (-(p_residue * inv4)) % 23
        for p_residue in (5, 14)
    }
    if targets != {5: 16, 14: 8}:
        raise SystemExit(f"unexpected Type-II targets: {targets}")

    if set(TYPE_II_MONOMIALS) != NONIDENTITY_QR23:
        raise SystemExit("monomial table does not cover exactly QR23 minus identity")

    rows = []
    for r in sorted(NONIDENTITY_QR23):
        seed_mask = divisor_square_residues(6 * r, 23)
        # Using r as the routed prime residue is sufficient because the divisor
        # residue set depends only on q mod23.
        if seed_mask != QR23:
            raise SystemExit(f"seed 6q does not QR-saturate for q mod23={r}")
        row = {"q_mod_23": r, "seed_mask": sorted(seed_mask), "cases": []}
        for p_residue in (5, 14):
            exponents = TYPE_II_MONOMIALS[r][p_residue]
            if any(e < 0 or e > 2 for e in exponents):
                raise SystemExit((r, p_residue, exponents))
            actual = monomial_value_mod23(r, exponents)
            target = targets[p_residue]
            if actual != target:
                raise SystemExit(
                    f"bad monomial r={r} p23={p_residue}: {actual} != {target}"
                )
            row["cases"].append({
                "p_mod_23": p_residue,
                "type_ii_target": target,
                "D_exponents_2_3_q": list(exponents),
            })
        rows.append(row)

    identity_mask = divisor_square_residues(6, 23)
    identity_augmented_mask = divisor_square_residues(6 * 47, 23)
    if 47 % 23 != 1 or identity_augmented_mask != identity_mask:
        raise SystemExit("q=47 identity-residue control changed")
    if identity_mask == QR23:
        raise SystemExit("base seed6 unexpectedly QR-saturates")

    named = []
    for q, label in NAMED_SOURCES.items():
        r = q % 23
        named.append({
            "q": q,
            "q_mod_23": r,
            "source": label,
            "repels_negative_k23_centers": r in NONIDENTITY_QR23,
            "seed_6q_qr_saturates": divisor_square_residues(6 * q, 23) == QR23,
        })

    return {
        "analysis": "k23-incoming-positive-source-repulsion-v1",
        "qr23": sorted(QR23),
        "repelling_source_residues": sorted(NONIDENTITY_QR23),
        "exceptional_negative_k23_centers": [5, 14],
        "type_ii_targets": {str(k): v for k, v in targets.items()},
        "monomial_certificate_table": rows,
        "identity_residue_control": {
            "q_mod_23": 1,
            "base_seed6_mask": sorted(identity_mask),
            "q47_seed282_mask": sorted(identity_augmented_mask),
            "qr_saturating": False,
        },
        "named_current_sources": named,
        "theorem": (
            "If a positive-character prime q is routed into C23 and q mod23 is not 1, "
            "then 6q is QR-saturating modulo23. Hence the ordinary negative k23 miss "
            "centers p mod23=5,14 are impossible; the table supplies explicit Type-II "
            "divisors D|C23^2 for every nonidentity QR source residue."
        ),
        "claim_boundary": (
            "fixed k=23 branch elimination; q mod23=1 is a sharp non-saturating control"
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
        print("repelling q mod23 residues:", report["repelling_source_residues"])
        for row in report["named_current_sources"]:
            print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
