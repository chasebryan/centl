#!/usr/bin/env python3
"""Independent direct-factorization anchors for q13 -> k23 elimination."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

ANCHORS = (
    # h, p mod23, p, required origin source residues
    (121, 5, 15_840_841, {47: 8}),
    (121, 14, 21_999_721, {47: 8}),
    (289, 5, 327_480_169, {11: 5, 47: 8}),
    (289, 14, 62_135_089, {11: 5, 47: 8}),
)
EXPLICIT_D = {5: 39, 14: 169}


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


def fixed_shift_miss(p: int, k: int) -> tuple[bool, Counter[int], int, set[int]]:
    c = (p + k) // 4
    factors = factor(c)
    residues = divisor_square_residues(factors, k)
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-c) % k
    miss = type_i not in residues and type_ii not in residues
    return miss, factors, c, residues


def analyze() -> dict[str, object]:
    failures: list[dict[str, object]] = []
    rows = []

    for h, p23, p, fixed in ANCHORS:
        if not is_prime(p):
            failures.append({"kind": "anchor-not-prime", "p": p})
            continue
        if p % 840 != h:
            failures.append({"kind": "hard-class", "p": p, "actual": p % 840, "expected": h})
        if p % 13 != 3:
            failures.append({"kind": "q13-route", "p": p, "actual": p % 13})
        if p % 23 != p23:
            failures.append({"kind": "k23-center", "p": p, "actual": p % 23, "expected": p23})
        for q, r in fixed.items():
            if p % q != r:
                failures.append({"kind": "origin-residue", "p": p, "q": q, "actual": p % q, "expected": r})

        miss39, factors39, c39, _ = fixed_shift_miss(p, 39)
        if not miss39:
            failures.append({"kind": "origin-k39-not-miss", "p": p})

        miss23, factors23, c23, residues23 = fixed_shift_miss(p, 23)
        if miss23:
            failures.append({"kind": "k23-did-not-hit", "p": p})

        if c23 % 78 != 0:
            failures.append({"kind": "seed78-not-mandatory", "p": p, "C23": c23})

        d = EXPLICIT_D[p23]
        target = (-c23) % 23
        if d % 23 != target:
            failures.append({
                "kind": "explicit-D-target",
                "p": p,
                "D": d,
                "D_mod_23": d % 23,
                "target": target,
            })
        if (c23 * c23) % d != 0:
            failures.append({"kind": "explicit-D-not-divisor", "p": p, "D": d, "C23": c23})
        if d % 23 not in residues23:
            failures.append({"kind": "explicit-D-residue-not-generated", "p": p, "D": d})

        rows.append({
            "p": p,
            "hard_class": h,
            "p_mod_13": p % 13,
            "p_mod_23": p23,
            "origin_source_residues": {str(q): r for q, r in fixed.items()},
            "k39_miss": miss39,
            "C39_factorization": dict(sorted(factors39.items())),
            "C23": c23,
            "C23_factorization": dict(sorted(factors23.items())),
            "seed78_divides_C23": c23 % 78 == 0,
            "k23_hit": not miss23,
            "explicit_type_ii_D": d,
            "explicit_target": target,
        })

    return {
        "analysis": "q13-k23-branch-elimination-independent-anchors-v1",
        "anchors_checked": len(ANCHORS),
        "rows": rows,
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "direct primality, companion factorization, divisor-square replay, and explicit "
            "Type-II D verification on one prime for each hard-class/exceptional-center branch"
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
        for row in report["rows"]:
            print(
                f"p={row['p']} h={row['hard_class']} p23={row['p_mod_23']} "
                f"D={row['explicit_type_ii_D']} k23_hit={row['k23_hit']}"
            )
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
