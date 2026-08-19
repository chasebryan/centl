#!/usr/bin/env python3
"""Independent finite regression for K35-TWO-TARGET-STRUCTURE.md.

This program does not use CBX hit tables.  It independently generates
Mordell-hard primes, factors C=(p+35)/4, builds the exact divisor residue box
of C^2 modulo 35, and checks:

* C always lies in H=<3>, the Jacobi +1 subgroup;
* outside-H valuation is even;
* pure-H support misses both exact targets;
* full H-part divisor mass plus an outside factor hits;
* for E_out=2, the four-companion criterion is equivalent to direct target
  membership.

Finite agreement is regression evidence for the separately proved group
identities.  It is not a proof of Erdős-Straus.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

MOD = 35
HARD = (1, 121, 169, 289, 361, 529)
H = {pow(3, a, MOD) for a in range(12)}
S = 6
TYPE_I = (-pow(4, -1, MOD)) % MOD

COORD: dict[int, tuple[int, int]] = {}
for eps in (0, 1):
    for a in range(12):
        COORD[(pow(S, eps, MOD) * pow(3, a, MOD)) % MOD] = (eps, a)
if len(COORD) != 24:
    raise RuntimeError("failed to coordinatize the unit group modulo 35")


def sieve_flags(n: int) -> bytearray:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return bs


def primes_up_to(n: int) -> list[int]:
    bs = sieve_flags(n)
    return [p for p in range(2, n + 1) if bs[p]]


def factor(n: int, trial: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial:
        if q * q > x:
            break
        if x % q:
            continue
        e = 0
        while x % q == 0:
            x //= q
            e += 1
        out[q] = e
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisor_box(fac: dict[int, int]) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, f, MOD) for f in range(2 * e + 1)}
        reach = {(x * y) % MOD for x in reach for y in vals}
    return reach


def h_part_data(fac: dict[int, int]) -> tuple[set[int], list[int], int]:
    D_H = {0}
    outside: list[int] = []
    for q, e in fac.items():
        eps, a = COORD[q % MOD]
        if eps:
            outside.extend([a] * e)
        else:
            vals = {(f * a) % 12 for f in range(2 * e + 1)}
            D_H = {(x + y) % 12 for x in D_H for y in vals}
    return D_H, outside, len(outside)


def four_companion_hit(C: int, fac: dict[int, int]) -> bool:
    D_H, outside, E = h_part_data(fac)
    if E != 2:
        raise ValueError("four_companion_hit requires E_out=2")
    alpha, beta = outside
    O = {
        alpha,
        beta,
        (alpha + 2 * beta) % 12,
        (2 * alpha + beta) % 12,
    }
    eps, c = COORD[C % MOD]
    if eps != 0:
        raise AssertionError("hard C must lie in H")
    type_i = any(((8 - o) % 12) in D_H for o in O)
    type_ii = any(((c + 6 - o) % 12) in D_H for o in O)
    return type_i or type_ii


def analyze(limit: int) -> dict[str, object]:
    flags = sieve_flags(limit)
    hard = [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]
    trial = primes_up_to(math.isqrt((limit + 35) // 4) + 2)

    errors: list[dict[str, object]] = []
    categories: Counter[str] = Counter()
    e2_checked = 0
    full_h_checks = 0

    for p in hard:
        C = (p + 35) // 4
        fac = factor(C, trial)
        if C % MOD not in H:
            errors.append({"kind": "C-outside-H", "p": p, "C": C})
            continue

        D_H, outside, E = h_part_data(fac)
        if E % 2:
            errors.append({"kind": "odd-outside-valuation", "p": p, "C": C, "E": E})
            continue

        D = divisor_box(fac)
        direct_hit = TYPE_I in D or ((-C) % MOD) in D
        categories[f"E={E}:{'hit' if direct_hit else 'miss'}"] += 1

        if E == 0 and direct_hit:
            errors.append({"kind": "pure-H-hit", "p": p, "C": C})

        if E > 0 and D_H == set(range(12)):
            full_h_checks += 1
            if not direct_hit:
                errors.append({"kind": "full-H-miss", "p": p, "C": C, "E": E})

        if E == 2:
            e2_checked += 1
            predicted_hit = four_companion_hit(C, fac)
            if predicted_hit != direct_hit:
                errors.append({
                    "kind": "E2-companion-mismatch",
                    "p": p,
                    "C": C,
                    "factorization": fac,
                    "predicted_hit": predicted_hit,
                    "direct_hit": direct_hit,
                })

    return {
        "analysis": "k35-structural-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "type_i_divisor_target": TYPE_I,
        "H": sorted(H),
        "coordinates": {
            "minus_one": COORD[34],
            "type_i": COORD[TYPE_I],
        },
        "categories": dict(sorted(categories.items())),
        "E2_cases_checked": e2_checked,
        "full_H_cases_checked": full_h_checks,
        "mismatches": len(errors),
        "mismatch_examples": errors[:20],
        "claim": "finite regression of separately proved exact structural identities",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.limit < 35:
        raise SystemExit("--limit must be >= 35")
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for k, v in report.items():
            print(f"{k}: {v}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
