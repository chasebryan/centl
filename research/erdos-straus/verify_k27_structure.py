#!/usr/bin/env python3
"""Independent finite regression for K27-TWO-TARGET-STRUCTURE.md.

The proof is in the theorem note. This standard-library verifier checks the
coordinate identities and proved implications on a finite Mordell-hard prime
corpus without calling CBX.
"""
from __future__ import annotations

import argparse
import json
import math

HARD = (1, 121, 169, 289, 361, 529)
MOD = 27
LOG = {pow(2, i, MOD): i for i in range(18)}
QR27 = {pow(x, 2, MOD) for x in range(1, MOD) if math.gcd(x, MOD) == 1}
EVEN = set(range(0, 18, 2))


def sieve(n: int) -> list[int]:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return [i for i, v in enumerate(bs) if v]


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


def add_sets(a: set[int], b: set[int]) -> set[int]:
    return {(x + y) % 18 for x in a for y in b}


def signed_logs(fac: dict[int, int]) -> set[int]:
    reach = {0}
    for q, e in fac.items():
        ell = LOG[q % MOD]
        local = {(z * ell) % 18 for z in range(-e, e + 1)}
        reach = add_sets(reach, local)
    return reach


def divisor_logs(fac: dict[int, int]) -> set[int]:
    reach = {0}
    for q, e in fac.items():
        ell = LOG[q % MOD]
        local = {(f * ell) % 18 for f in range(0, 2 * e + 1)}
        reach = add_sets(reach, local)
    return reach


def center_log(fac: dict[int, int]) -> int:
    return sum(e * LOG[q % MOD] for q, e in fac.items()) % 18


def qr_divisor_logs(fac: dict[int, int]) -> set[int]:
    reach = {0}
    for q, e in fac.items():
        ell = LOG[q % MOD]
        if ell % 2:
            continue
        local = {(f * ell) % 18 for f in range(0, 2 * e + 1)}
        reach = add_sets(reach, local)
    return reach


def run(limit: int) -> dict[str, object]:
    primes = sieve(limit)
    hard = [p for p in primes if p % 840 in HARD]
    trial = [q for q in primes if q <= math.isqrt((limit + 27) // 4) + 1]

    qr_identity_failures = 0
    wheel_failures = 0
    parity_failures = 0
    coordinate_failures = 0
    pure_qr_failures = 0
    full_qr_failures = 0
    e2_companion_failures = 0

    pure_qr = 0
    full_qr_with_nr = 0
    e2_cases = 0
    e2_hits = 0
    e2_misses = 0
    examples: list[dict[str, object]] = []

    expected_qr = {x for x in range(1, MOD) if math.gcd(x, MOD) == 1 and x % 3 == 1}
    if QR27 != expected_qr:
        qr_identity_failures += 1

    for p in hard:
        P = (p - 1) // 4
        C = P + 7
        fac = factor(C, trial)

        if P % 6 or C % 6 != 1:
            wheel_failures += 1

        nr_units: list[int] = []
        for q, e in fac.items():
            ell = LOG[q % MOD]
            if ell % 2:
                nr_units.extend([ell] * e)
        nr_val = len(nr_units)
        if nr_val % 2:
            parity_failures += 1

        S = signed_logs(fac)
        D = divisor_logs(fac)
        c = center_log(fac)
        type_ii_s = 9 in S
        type_ii_d = ((9 + c) % 18) in D
        type_i_s = ((7 - c) % 18) in S
        type_i_d = 7 in D
        if type_i_s != type_i_d or type_ii_s != type_ii_d:
            coordinate_failures += 1

        if nr_val == 0:
            pure_qr += 1
            if type_i_d or type_ii_d:
                pure_qr_failures += 1

        DQ = qr_divisor_logs(fac)
        if nr_val > 0 and DQ == EVEN:
            full_qr_with_nr += 1
            if not (type_i_d and type_ii_d):
                full_qr_failures += 1

        if nr_val == 2:
            e2_cases += 1
            alpha, beta = nr_units
            O = {
                alpha % 18,
                beta % 18,
                (alpha + 2 * beta) % 18,
                (2 * alpha + beta) % 18,
            }
            pred_i = any(((7 - o) % 18) in DQ for o in O)
            pred_ii = any(((9 + c - o) % 18) in DQ for o in O)
            if pred_i != type_i_d or pred_ii != type_ii_d:
                e2_companion_failures += 1
                if len(examples) < 20:
                    examples.append({
                        "p": p,
                        "C": C,
                        "factors": fac,
                        "alpha": alpha,
                        "beta": beta,
                        "O": sorted(O),
                        "DQ": sorted(DQ),
                        "c": c,
                        "actual_type_i": type_i_d,
                        "actual_type_ii": type_ii_d,
                        "pred_type_i": pred_i,
                        "pred_type_ii": pred_ii,
                    })
            if type_i_d or type_ii_d:
                e2_hits += 1
            else:
                e2_misses += 1

    return {
        "analysis": "k27-two-target-structure-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "pure_qr_cases": pure_qr,
        "full_qr_with_nonresidue_cases": full_qr_with_nr,
        "e2_cases": e2_cases,
        "e2_hits": e2_hits,
        "e2_misses": e2_misses,
        "failures": {
            "qr_identity": qr_identity_failures,
            "wheel": wheel_failures,
            "nonresidue_parity": parity_failures,
            "coordinate_equivalence": coordinate_failures,
            "pure_qr_theorem": pure_qr_failures,
            "full_qr_theorem": full_qr_failures,
            "e2_four_companion": e2_companion_failures,
        },
        "failure_examples": examples,
        "claim": "finite regression of separately proved structural identities",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="verify exact k=27 structural reductions")
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.limit < 100:
        raise SystemExit("--limit must be >= 100")

    report = run(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("k=27 structural regression")
        print(json.dumps(report, indent=2, sort_keys=True))

    return 1 if any(report["failures"].values()) else 0


if __name__ == "__main__":
    raise SystemExit(main())
