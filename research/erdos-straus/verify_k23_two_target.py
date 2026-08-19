#!/usr/bin/env python3
"""Independent finite regression for K23-TWO-TARGET-FILTER.md.

Standard-library only. The proof is in the theorem note; this program checks
that the exact signed-box predicate, divisor-square Type-I target, and the
closed-form Branch A/B classification agree on a finite hard-prime corpus.
"""
from __future__ import annotations

import argparse
import json
import math

HARD = (1, 121, 169, 289, 361, 529)
MOD = 23
QR23 = {pow(x, 2, MOD) for x in range(1, MOD)}


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


def signed_box(fac: dict[int, int], mod: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        if math.gcd(q, mod) != 1:
            raise ValueError(f"nonunit factor {q} modulo {mod}")
        local = {pow(q, z, mod) for z in range(-e, e + 1)}
        reach = {(a * b) % mod for a in reach for b in local}
    return reach


def square_divisor_residues(fac: dict[int, int], mod: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        local = {pow(q, f, mod) for f in range(0, 2 * e + 1)}
        reach = {(a * b) % mod for a in reach for b in local}
    return reach


def theorem_classification(fac: dict[int, int]) -> tuple[bool, str, int, int]:
    """Return (combined_miss, branch, e_plus, e_minus)."""
    pure_qr = all((q % MOD) in QR23 for q in fac)
    if pure_qr:
        return True, "A", 0, 0

    thin = fac.get(2, 0) == 1 and fac.get(3, 0) == 1
    e_plus = 0
    e_minus = 0

    if thin:
        for q, e in fac.items():
            if q in (2, 3):
                continue
            r = q % MOD
            if r in QR23:
                if r != 1:
                    thin = False
                    break
            elif r == 5:
                e_plus += e
            elif r == 14:
                e_minus += e
            else:
                thin = False
                break

    if thin and e_plus + e_minus <= 2:
        combined_miss = (e_plus, e_minus) in {
            (0, 0),
            (1, 0),
            (0, 1),
            (1, 1),
        }
        return combined_miss, "B", e_plus, e_minus

    return False, "hit", e_plus, e_minus


def run(limit: int) -> dict[str, object]:
    if limit < 100:
        raise SystemExit("--limit must be >= 100")

    primes = sieve(limit)
    trial = [q for q in primes if q <= math.isqrt((limit + 23) // 4) + 1]
    hard = [p for p in primes if p % 840 in HARD]

    mismatches: list[dict[str, object]] = []
    type_i_equivalence_mismatches = 0
    branch_counts: dict[str, int] = {}
    actual_hits = 0
    actual_misses = 0
    type_ii_misses = 0
    type_i_rescues_of_type_ii = 0

    for p in hard:
        C = (p + 23) // 4
        fac = factor(C, trial)
        box = signed_box(fac, MOD)
        div2 = square_divisor_residues(fac, MOD)

        type_ii = 22 in box
        type_i_box = (-pow(p, -1, MOD)) % MOD in box
        type_i_divisor = 17 in div2
        if type_i_box != type_i_divisor:
            type_i_equivalence_mismatches += 1

        actual_hit = type_i_box or type_ii
        predicted_miss, branch, e_plus, e_minus = theorem_classification(fac)
        predicted_hit = not predicted_miss

        if actual_hit:
            actual_hits += 1
        else:
            actual_misses += 1
            key = branch if branch == "A" else f"B({e_plus},{e_minus})"
            branch_counts[key] = branch_counts.get(key, 0) + 1

        if not type_ii:
            type_ii_misses += 1
            if type_i_box:
                type_i_rescues_of_type_ii += 1

        if predicted_hit != actual_hit and len(mismatches) < 20:
            mismatches.append(
                {
                    "p": p,
                    "C": C,
                    "factors": fac,
                    "type_i": type_i_box,
                    "type_ii": type_ii,
                    "predicted_miss": predicted_miss,
                    "branch": branch,
                    "e_plus": e_plus,
                    "e_minus": e_minus,
                }
            )

    return {
        "analysis": "k23-two-target-regression-v1",
        "limit": limit,
        "hard_primes": len(hard),
        "actual_hits": actual_hits,
        "actual_misses": actual_misses,
        "type_ii_misses": type_ii_misses,
        "type_i_rescues_of_type_ii": type_i_rescues_of_type_ii,
        "branch_counts": dict(sorted(branch_counts.items())),
        "classification_mismatches": len(mismatches),
        "type_i_divisor_equivalence_mismatches": type_i_equivalence_mismatches,
        "mismatch_examples": mismatches,
        "claim": "finite regression of a separately proved exact classification",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="verify exact k=23 two-target classification")
    ap.add_argument("--limit", type=int, default=50_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    report = run(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("k=23 exact two-target regression")
        for key in (
            "limit",
            "hard_primes",
            "actual_hits",
            "actual_misses",
            "type_ii_misses",
            "type_i_rescues_of_type_ii",
            "classification_mismatches",
            "type_i_divisor_equivalence_mismatches",
        ):
            print(f"{key}={report[key]}")
        print(f"branch_counts={report['branch_counts']}")

    if report["classification_mismatches"]:
        return 1
    if report["type_i_divisor_equivalence_mismatches"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
