#!/usr/bin/env python3
"""Quadratic-character analysis for Type A/B shadow candidates.

This analyzer is independent of the stored avoiding witness when deciding
character-shield solvability. It reads a direct-shadow certificate bundle,
rechecks the Jacobi -1 trap signature by explicit enumeration, and then solves
the finite F_2 system from QUADRATIC-TRAP-SIGNATURE.md for every directly novel
candidate.

A solvable character system is a constructive theorem certificate: CRT and
Dirichlet give a reduced arithmetic progression containing infinitely many
primes of exact Type A/B depth k. An unsolved character system is not a
counterexample to DSC-P; it simply requires the finer exact trap geometry.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def factor_exp(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    p = 3
    while p * p <= x:
        while x % p == 0:
            out[p] = out.get(p, 0) + 1
            x //= p
        p += 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("Jacobi denominator must be positive odd")
    a %= n
    result = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                result = -result
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            result = -result
        a %= n
    return result if n == 1 else 0


def legendre_bit(a: int, p: int) -> int:
    v = pow(a % p, (p - 1) // 2, p)
    if v == 1:
        return 0
    if v == p - 1:
        return 1
    raise AssertionError(f"nonunit Legendre input modulo {p}")


def prime_list(n: int) -> list[int]:
    if n < 2:
        return []
    sieve = bytearray(b"\x01") * (n + 1)
    sieve[0:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if sieve[p]:
            start = p * p
            sieve[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [i for i in range(3, n + 1, 2) if sieve[i]]


def f2_solve(rows: list[tuple[int, int]]) -> tuple[bool, int, int | None]:
    """Return solvable, rank, and first inconsistent row index."""
    basis: dict[int, tuple[int, int]] = {}
    for row_index, (mask, rhs) in enumerate(rows, start=1):
        x, b = mask, rhs
        while x:
            pivot = x.bit_length() - 1
            if pivot in basis:
                y, c = basis[pivot]
                x ^= y
                b ^= c
            else:
                basis[pivot] = (x, b)
                break
        if x == 0 and b:
            return False, len(basis), row_index
    return True, len(basis), None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    primes = prime_list(4 * k_limit)
    p_index = {p: i for i, p in enumerate(primes)}

    factors: list[dict[int, int]] = [{} for _ in range(k_limit + 1)]
    odd_masks = [0] * (k_limit + 1)
    theorem_checks = 0
    for k in range(1, k_limit + 1):
        m = 4 * k - 1
        fac = factor_exp(m)
        factors[k] = fac
        mask = 0
        for p, a in fac.items():
            if a % 2:
                mask |= 1 << p_index[p]
        odd_masks[k] = mask
        for e in divisors(k):
            if jacobi(-e, m) != -1 or jacobi(-4 * e, m) != -1:
                raise AssertionError(f"quadratic trap theorem failed at k={k}, e={e}")
            theorem_checks += 2

    all_square = 0
    character_shield = 0
    residual = 0
    ranks: list[int] = []
    first_inconsistent_layers: collections.Counter[int] = collections.Counter()
    residual_examples: list[dict] = []

    for index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])

        fixed_mask = 0
        negative_fixed_mask = 0
        shared_relevant_negative = False
        for p in primes:
            if p > 4 * k - 1:
                break
            if L % p != 0:
                continue
            bit = 1 << p_index[p]
            fixed_mask |= bit
            neg = legendre_bit(r, p)
            if neg:
                negative_fixed_mask |= bit
                # Relevant to all-square only if p occurs to odd exponent in
                # at least one earlier modulus.
                if any((odd_masks[j] & bit) for j in range(1, k)):
                    shared_relevant_negative = True

        if not shared_relevant_negative:
            all_square += 1

        rows: list[tuple[int, int]] = []
        layer_map: list[int] = []
        for j in range(1, k):
            row = odd_masks[j]
            free = row & ~fixed_mask
            rhs = (row & negative_fixed_mask).bit_count() & 1
            rows.append((free, rhs))
            layer_map.append(j)

        solvable, rank, bad_row = f2_solve(rows)
        ranks.append(rank)
        if solvable:
            character_shield += 1
        else:
            residual += 1
            bad_layer = layer_map[bad_row - 1] if bad_row is not None else -1
            first_inconsistent_layers[bad_layer] += 1
            if len(residual_examples) < 40:
                residual_examples.append(
                    {
                        "candidate_index": index,
                        "k": k,
                        "h": int(rec["h"]),
                        "t": int(rec["t"]),
                        "first_inconsistent_layer": bad_layer,
                        "rank_before_inconsistency": rank,
                    }
                )

        if index % 5000 == 0:
            print(
                f"quadratic-shield progress {index}/{len(witnesses)} "
                f"shield={character_shield} residual={residual}",
                flush=True,
            )

    n = len(witnesses)
    result = {
        "status": "exact quadratic trap signature and F2 character-shield analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": n,
        "explicit_jacobi_trap_checks": theorem_checks,
        "all_square_shield_candidates": all_square,
        "all_square_shield_fraction": all_square / n,
        "character_shield_candidates": character_shield,
        "character_shield_fraction": character_shield / n,
        "character_residual_candidates": residual,
        "character_residual_fraction": residual / n,
        "rank_min": min(ranks) if ranks else 0,
        "rank_max": max(ranks) if ranks else 0,
        "first_inconsistent_layer_counts": {
            str(k): v for k, v in sorted(first_inconsistent_layers.items())
        },
        "residual_examples": residual_examples,
        "claim_boundary": (
            "A solvable F2 character system is a sufficient theorem certificate for a reduced avoiding progression by the quadratic character-shield theorem. "
            "An inconsistent character system does not imply union shadowing; exact trap avoidance may still succeed inside Jacobi-negative regions."
        ),
    }
    (args.out / "quadratic-trap-signature-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Quadratic trap signature and character shield\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Explicit Jacobi trap checks: **`{theorem_checks}`**, all passed.\n\n"
    report += f"All-square shield: **`{all_square}`** (`{all_square/n:.3%}`).\n\n"
    report += f"General F2 character shield: **`{character_shield}`** (`{character_shield/n:.3%}`).\n\n"
    report += f"Character residual: **`{residual}`** (`{residual/n:.3%}`).\n\n"
    report += "A character-shield success independently proves an infinite reduced exact-depth prime progression without using the stored avoiding witness. Residual candidates require the finer exact trap geometry.\n"
    (args.out / "quadratic-trap-signature-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
