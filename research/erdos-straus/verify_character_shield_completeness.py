#!/usr/bin/env python3
"""Verify the squareclass saturation / character-shield completeness theorem.

Two exact finite regressions are performed:

1. layer-only squareclass saturation through a configurable k bound;
2. if a direct-shadow certificate bundle is supplied, candidatewise equivalence
   between F_2 character-system inconsistency and the presence of a fixed-only
   Jacobi-negative earlier layer.

These computations are theorem regressions, not substitutes for the proof in
CHARACTER-SHIELD-COMPLETENESS.md.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


def primes_upto(n: int) -> list[int]:
    b = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        b[0] = 0
    if n >= 1:
        b[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if b[p]:
            start = p * p
            b[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [p for p in range(3, n + 1, 2) if b[p]]


def factor_all(n: int, primes: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    while x % 2 == 0:
        x //= 2
    for p in primes:
        if p * p > x:
            break
        while x % p == 0:
            out[p] = out.get(p, 0) + 1
            x //= p
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def rank_masks(rows: list[int]) -> int:
    basis: dict[int, int] = {}
    for value in rows:
        x = value
        while x:
            pivot = x.bit_length() - 1
            if pivot not in basis:
                basis[pivot] = x
                break
            x ^= basis[pivot]
    return len(basis)


def legendre_bit(a: int, p: int) -> int:
    v = pow(a % p, (p - 1) // 2, p)
    if v == 1:
        return 0
    if v == p - 1:
        return 1
    raise AssertionError("nonunit Legendre input")


def f2_solvable(rows: list[tuple[int, int]]) -> bool:
    basis: dict[int, tuple[int, int]] = {}
    for mask, rhs in rows:
        x, b = mask, rhs
        while x:
            pivot = x.bit_length() - 1
            if pivot not in basis:
                basis[pivot] = (x, b)
                break
            y, c = basis[pivot]
            x ^= y
            b ^= c
        if x == 0 and b:
            return False
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=3000)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    k_limit = args.k_limit
    primes = primes_upto(4 * k_limit)
    p_index = {p: i for i, p in enumerate(primes)}

    factors: list[dict[int, int]] = [{} for _ in range(k_limit + 1)]
    squareclass = [0] * (k_limit + 1)
    full_rank = [0] * (k_limit + 1)
    running_basis: dict[int, int] = {}

    for j in range(1, k_limit + 1):
        fac = factor_all(4 * j - 1, primes)
        factors[j] = fac
        mask = 0
        for p, a in fac.items():
            if a % 2:
                mask |= 1 << p_index[p]
        squareclass[j] = mask

        x = mask
        while x:
            pivot = x.bit_length() - 1
            if pivot not in running_basis:
                running_basis[pivot] = x
                break
            x ^= running_basis[pivot]
        full_rank[j] = len(running_basis)

    base_fixed = 0
    for p in (3, 5, 7):
        base_fixed |= 1 << p_index[p]

    saturation_failures: list[dict] = []
    for k in range(1, k_limit + 1):
        fixed = base_fixed
        for p in factors[k]:
            fixed |= 1 << p_index[p]

        rows = squareclass[1:k]
        free_rank = rank_masks([row & ~fixed for row in rows])
        intersection_dim = full_rank[k - 1] - free_rank if k > 1 else 0
        fixed_only_rank = rank_masks([row for row in rows if row & ~fixed == 0])

        if intersection_dim != fixed_only_rank:
            saturation_failures.append(
                {
                    "k": k,
                    "intersection_dimension": intersection_dim,
                    "fixed_only_rank": fixed_only_rank,
                }
            )

    candidate_result = None
    if args.out is not None:
        source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
        witnesses: list[dict] = source["witnesses"]
        if int(source["parameters"]["k_limit"]) > k_limit:
            raise SystemExit("--k-limit must cover the certificate bundle")

        inconsistent = 0
        direct_character_obstruction = 0
        disagreement = 0

        for rec in witnesses:
            k = int(rec["k"])
            r = int(rec["r"])
            L = int(rec["L"])

            fixed = 0
            negative_fixed = 0
            for p in primes:
                if p > 4 * k - 1:
                    break
                if L % p == 0:
                    bit = 1 << p_index[p]
                    fixed |= bit
                    if legendre_bit(r, p):
                        negative_fixed |= bit

            rows: list[tuple[int, int]] = []
            has_direct = False
            for j in range(1, k):
                row = squareclass[j]
                free = row & ~fixed
                rhs = (row & negative_fixed).bit_count() & 1
                rows.append((free, rhs))
                if free == 0 and rhs == 1:
                    has_direct = True

            is_inconsistent = not f2_solvable(rows)
            inconsistent += int(is_inconsistent)
            direct_character_obstruction += int(has_direct)
            if is_inconsistent != has_direct:
                disagreement += 1

        candidate_result = {
            "direct_novel_candidates": len(witnesses),
            "character_inconsistent_candidates": inconsistent,
            "direct_character_obstruction_candidates": direct_character_obstruction,
            "equivalence_disagreements": disagreement,
        }

    result = {
        "status": "squareclass saturation and character-shield completeness regression",
        "k_limit": k_limit,
        "saturation_failures": saturation_failures,
        "saturation_verified": not saturation_failures,
        "candidate_bundle": candidate_result,
        "claim_boundary": (
            "The proof is in CHARACTER-SHIELD-COMPLETENESS.md. This script is an exact finite regression only."
        ),
    }

    print(json.dumps(result, indent=2, sort_keys=True))
    if saturation_failures:
        raise SystemExit(1)
    if candidate_result is not None and candidate_result["equivalence_disagreements"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
