#!/usr/bin/env python3
"""Independent exponent-coordinate verification of multi-source QR saturation."""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import Counter

PAIR_ROWS = (
    (121, 31, 2, (19, 47), 1786, (7, 16)),
    (121, 79, 10, (19, 23), 4370, (16, 13)),
    (169, 19, 1, (11, 23), 253, (3, 4)),
    (169, 83, 21, (11, 23), 5313, (5, 9)),
    (169, 83, 21, (11, 31), 7161, (5, 10)),
    (169, 83, 21, (23, 31), 14973, (9, 10)),
    (169, 167, 42, (11, 31), 14322, (9, 19)),
    (529, 19, 1, (11, 23), 253, (3, 4)),
)
TRIPLE_ROWS = (
    (169, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
    (289, 167, 6, (11, 31, 47), 96162, (9, 19, 21)),
    (529, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (529, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
)


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


def primitive_root(p: int) -> int:
    factors = set(factorization(p - 1))
    for g in range(2, p):
        if all(pow(g, (p - 1) // q, p) != 1 for q in factors):
            return g
    raise RuntimeError(p)


def exponent_residues(seed: int, p: int) -> set[int]:
    n = p - 1
    g = primitive_root(p)
    log = {pow(g, a, p): a for a in range(n)}
    exponents = {0}
    for q, e in factorization(seed).items():
        a = log[q % p]
        local = {(j * a) % n for j in range(2 * e + 1)}
        exponents = {(x + y) % n for x in exponents for y in local}
    return exponents


def saturates_in_exponents(seed: int, p: int) -> bool:
    return exponent_residues(seed, p) == set(range(0, p - 1, 2))


def source_residue_is_positive(q: int, r: int) -> bool:
    if r == 0:
        return False
    return pow(r, (q - 1) // 2, q) == 1


def divisors_square_residues_from_factorization(factors: Counter[int], k: int) -> set[int]:
    residues = {1}
    for q, e in factors.items():
        local = {pow(q, j, k) for j in range(2 * e + 1)}
        residues = {a * b % k for a in residues for b in local}
    return residues


def fixed_shift_miss(p: int, k: int) -> tuple[bool, Counter[int]]:
    c = (p + k) // 4
    factors = factorization(c)
    residues = divisors_square_residues_from_factorization(factors, k)
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-c) % k
    return type_i not in residues and type_ii not in residues, factors


def verify_rows(rows: tuple, arity: int, failures: list[dict[str, object]]) -> int:
    checked = 0
    for h, k, base, sources, seed, residues in rows:
        checked += 1
        if len(sources) != arity:
            failures.append({"kind": "arity", "k": k, "sources": list(sources)})
        if math.lcm(base, *sources) != seed:
            failures.append({"kind": "seed", "k": k, "seed": seed})
        for q, r in zip(sources, residues):
            if r != (-k) % q:
                failures.append({"kind": "route-residue", "k": k, "q": q, "r": r})
            if q != 23 and not source_residue_is_positive(q, r):
                failures.append({"kind": "source-character", "k": k, "q": q, "r": r})
            if q == 23 and r not in {2, 3, 4, 6, 8, 9, 12, 13, 16, 18}:
                failures.append({"kind": "source-23-rigidity", "k": k, "r": r})

        if not saturates_in_exponents(seed, k):
            failures.append({"kind": "combined-not-saturating", "h": h, "k": k, "seed": seed})

        for size in range(1, arity):
            for subset in itertools.combinations(sources, size):
                partial = math.lcm(base, *subset)
                if saturates_in_exponents(partial, k):
                    failures.append({
                        "kind": "proper-subset-saturates",
                        "h": h,
                        "k": k,
                        "subset": list(subset),
                        "partial_seed": partial,
                    })
    return checked


def verify_record_anchor(failures: list[dict[str, object]]) -> dict[str, object]:
    p = 8_803_369
    if p % 840 != 169 or p % 11 != 3 or p % 23 != 4:
        failures.append({"kind": "record-anchor-congruence"})

    rows = {}
    for k in (11, 19, 23, 107):
        miss, factors = fixed_shift_miss(p, k)
        rows[str(k)] = {
            "companion": (p + k) // 4,
            "factorization": dict(sorted(factors.items())),
            "miss": miss,
        }
    if not rows["11"]["miss"] or not rows["19"]["miss"] or not rows["23"]["miss"]:
        failures.append({"kind": "record-anchor-early-hit", "rows": rows})
    if rows["107"]["miss"]:
        failures.append({"kind": "record-anchor-k107-no-hit", "rows": rows})
    if rows["19"]["factorization"] != {11: 1, 23: 1, 8699: 1}:
        failures.append({"kind": "record-anchor-C19-factorization", "row": rows["19"]})
    if pow(8699 % 19, 9, 19) != 1:
        failures.append({"kind": "record-anchor-cofactor-not-qr19"})
    return rows


def analyze() -> dict[str, object]:
    failures: list[dict[str, object]] = []
    pair_checked = verify_rows(PAIR_ROWS, 2, failures)
    triple_checked = verify_rows(TRIPLE_ROWS, 3, failures)
    anchor = verify_record_anchor(failures)
    return {
        "analysis": "multisource-qr-saturation-independent-exponent-regression-v1",
        "pair_rows_checked": pair_checked,
        "triple_rows_checked": triple_checked,
        "record_anchor": anchor,
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "independent discrete-log exponent verification of QR saturation and proper-subset "
            "minimality, plus direct divisor-square replay of the p=8803369 anchor"
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
        print(f"pairs checked: {report['pair_rows_checked']}")
        print(f"triples checked: {report['triple_rows_checked']}")
        print(f"failures: {report['failures']}")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
