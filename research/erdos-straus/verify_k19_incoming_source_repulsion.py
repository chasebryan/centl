#!/usr/bin/env python3
"""Independent group/certificate verification for h=289 k19 source repulsion."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

QR19 = {1, 4, 5, 6, 7, 9, 11, 16, 17}
H = {1, 7, 11}
REPELLING = QR19 - H
TARGETS = {2: 9, 3: 4, 14: 6}
MONOMIALS = {
    4: {2: (1, 1), 3: (0, 1), 14: (2, 1)},
    5: {2: (2, 2), 3: (1, 2), 14: (0, 2)},
    6: {2: (2, 1), 3: (1, 1), 14: (0, 1)},
    9: {2: (0, 1), 3: (2, 1), 14: (1, 1)},
    16: {2: (0, 2), 3: (2, 2), 14: (1, 2)},
    17: {2: (1, 2), 3: (0, 2), 14: (2, 2)},
}

ANCHORS = (
    # label, routed q, required p mod q, origin fixed residues, origin k,
    # negative p mod19, prime p
    ("q17", 17, 15, {11: 4, 23: 18}, 51, 2, 123_985_129),
    ("q17", 17, 15, {11: 4, 23: 18}, 51, 3, 116_759_449),
    ("q17", 17, 15, {11: 4, 23: 18}, 51, 14, 311_852_809),
    ("q43", 43, 24, {11: 5, 31: 2}, 215, 2, 817_957_849),
    ("q43", 43, 24, {11: 5, 31: 2}, 215, 3, 571_619_449),
    ("q43", 43, 24, {11: 5, 31: 2}, 215, 14, 1_606_240_729),
)


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    q = 3
    while q * q <= n:
        if n % q == 0:
            return False
        q += 2
    return True


def factor(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    x = n
    q = 2
    while q * q <= x:
        while x % q == 0:
            out[q] += 1
            x //= q
        q += 1 if q == 2 else 2
    if x > 1:
        out[x] += 1
    return out


def divisor_square_residues(factors: Counter[int], k: int) -> set[int]:
    residues = {1}
    for q, e in factors.items():
        local = {pow(q, j, k) for j in range(2 * e + 1)}
        residues = {a * b % k for a in residues for b in local}
    return residues


def fixed_shift_miss(p: int, k: int) -> tuple[bool, int, Counter[int], set[int]]:
    c = (p + k) // 4
    factors = factor(c)
    residues = divisor_square_residues(factors, k)
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-c) % k
    return type_i not in residues and type_ii not in residues, c, factors, residues


def group_cosets(r: int) -> set[int]:
    # Divisors of 7^2 supply H={1,7,11}. A routed q contributes q^0,q^1,q^2.
    return {h * pow(r, e, 19) % 19 for h in H for e in range(3)}


def analyze() -> dict[str, object]:
    failures: list[dict[str, object]] = []
    residue_rows = []

    # Independent quotient-group check of the saturation criterion.
    for r in sorted(QR19):
        mask = group_cosets(r)
        saturates = mask == QR19
        expected = r in REPELLING
        if saturates != expected:
            failures.append({
                "kind": "coset-saturation",
                "q_mod_19": r,
                "mask": sorted(mask),
                "actual": saturates,
                "expected": expected,
            })
        certs = []
        if expected:
            for p19, target in sorted(TARGETS.items()):
                a, b = MONOMIALS[r][p19]
                value = pow(7, a, 19) * pow(r, b, 19) % 19
                if value != target:
                    failures.append({
                        "kind": "symbolic-D",
                        "q_mod_19": r,
                        "p_mod_19": p19,
                        "value": value,
                        "target": target,
                    })
                certs.append({
                    "p_mod_19": p19,
                    "target": target,
                    "D_exponents_7_q": [a, b],
                    "verified_residue": value,
                })
        residue_rows.append({
            "q_mod_19": r,
            "coset_union": sorted(mask),
            "saturates": saturates,
            "certificates": certs,
        })

    anchor_rows = []
    for label, q, qres, fixed, origin_k, p19, p in ANCHORS:
        if not is_prime(p):
            failures.append({"kind": "anchor-not-prime", "p": p})
            continue
        if p % 840 != 289:
            failures.append({"kind": "hard-class", "p": p, "actual": p % 840})
        if p % q != qres or p % 19 != p19:
            failures.append({"kind": "route-residue", "p": p, "q": q})
        for source, residue in fixed.items():
            if p % source != residue:
                failures.append({
                    "kind": "origin-source-residue",
                    "p": p,
                    "source": source,
                    "actual": p % source,
                    "expected": residue,
                })

        origin_miss, _, origin_factors, _ = fixed_shift_miss(p, origin_k)
        if not origin_miss:
            failures.append({"kind": "origin-not-miss", "p": p, "k": origin_k})

        miss19, c19, factors19, residues19 = fixed_shift_miss(p, 19)
        if miss19:
            failures.append({"kind": "k19-did-not-hit", "p": p})
        if c19 % (7 * q) != 0:
            failures.append({
                "kind": "routed-seed-not-mandatory",
                "p": p,
                "q": q,
                "C19": c19,
            })

        a, b = MONOMIALS[q % 19][p19]
        d = (7 ** a) * (q ** b)
        target = (-c19) % 19
        if d % 19 != target:
            failures.append({
                "kind": "explicit-D-target",
                "p": p,
                "D": d,
                "actual": d % 19,
                "target": target,
            })
        if (c19 * c19) % d != 0:
            failures.append({"kind": "explicit-D-not-divisor", "p": p, "D": d})
        if d % 19 not in residues19:
            failures.append({"kind": "explicit-D-not-generated", "p": p, "D": d})

        anchor_rows.append({
            "label": label,
            "p": p,
            "p_mod_19": p19,
            "routed_q": q,
            "q_mod_19": q % 19,
            "origin_k": origin_k,
            "origin_k_miss": origin_miss,
            "origin_factorization": dict(sorted(origin_factors.items())),
            "C19": c19,
            "C19_factorization": dict(sorted(factors19.items())),
            "k19_hit": not miss19,
            "explicit_type_ii_D": d,
            "type_ii_target": target,
        })

    return {
        "analysis": "h289-k19-source-repulsion-independent-v1",
        "residue_rows": residue_rows,
        "anchors_checked": len(ANCHORS),
        "anchor_rows": anchor_rows,
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "independent QR(19)/H coset verification plus direct prime/factorization replay "
            "of all three negative centers for routed q17 and q43 recursive sources"
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
        print(f"anchors checked: {report['anchors_checked']}")
        print(f"failures: {report['failures']}")
        for row in report["anchor_rows"]:
            print(row)
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
