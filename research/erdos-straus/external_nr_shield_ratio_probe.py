#!/usr/bin/env python3
"""Exact finite falsifier for the m=1 external-nonresidue shield-ratio target.

Standard-library only.  This script does NOT prove Erdős-Straus.

For each Mordell-hard prime p, optionally after imposing the four exact
counterexample filters from FAB-HARD-FIRST-FILTERS.md, it scans external primes

    ell == 3 (mod 4),   (ell/p) = -1,

sets

    C = (p + ell)/4,

and tests whether the exact fixed-k divisor-ratio target

    -p^{-1} (mod ell)

is attained using only signed powers of 2,3,5,7 actually available in C:

    2^z2 3^z3 5^z5 7^z7,
    -v_q(C) <= zq <= v_q(C).

A hit is an exact strong sufficient certificate by
FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md.

The number of external primes searched is a finite falsification parameter,
not a proposed universal bound.
"""

from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD = {1, 121, 169, 289, 361, 529}
SHIELD = (2, 3, 5, 7)


def sieve(n: int) -> list[int]:
    if n < 2:
        return []
    bs = bytearray(b"\x01") * (n + 1)
    bs[0:2] = b"\x00\x00"
    for q in range(2, math.isqrt(n) + 1):
        if bs[q]:
            start = q * q
            bs[start : n + 1 : q] = b"\x00" * (((n - start) // q) + 1)
    return [i for i, flag in enumerate(bs) if flag]


def legendre(a: int, p: int) -> int:
    a %= p
    if a == 0:
        return 0
    x = pow(a, (p - 1) // 2, p)
    return -1 if x == p - 1 else x


def factor(n: int, trial_primes: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial_primes:
        if q * q > x:
            break
        if x % q == 0:
            e = 0
            while x % q == 0:
                x //= q
                e += 1
            out[q] = e
        if x == 1:
            break
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def survives_first_four(p: int, trial_primes: list[int]) -> bool:
    f = factor((p + 1) // 2, trial_primes)
    if any(q != 2 and q % 4 != 1 for q in f):
        return False

    f = factor((p + 3) // 4, trial_primes)
    if any(q % 3 != 1 for q in f):
        return False

    f = factor((3 * p + 1) // 4, trial_primes)
    if any(q % 3 != 1 for q in f):
        return False

    f = factor(p + 2, trial_primes)
    if any(q % 8 not in (1, 3) for q in f):
        return False

    return True


def shield_valuations(C: int) -> tuple[int, int, int, int]:
    vals: list[int] = []
    for q in SHIELD:
        e = 0
        x = C
        while x % q == 0:
            x //= q
            e += 1
        vals.append(e)
    return tuple(vals)  # type: ignore[return-value]


def shield_ratio_witness(
    p: int, ell: int
) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int], int] | None:
    C = (p + ell) // 4
    vals = shield_valuations(C)
    target = (-pow(p, -1, ell)) % ell

    # Dynamic programming also stores one signed exponent witness.
    states: dict[int, tuple[int, int, int, int]] = {1 % ell: (0, 0, 0, 0)}

    for idx, (q, e) in enumerate(zip(SHIELD, vals)):
        q_inv = pow(q, -1, ell)
        next_states: dict[int, tuple[int, int, int, int]] = {}
        for residue, witness in states.items():
            for z in range(-e, e + 1):
                if z >= 0:
                    factor_residue = pow(q, z, ell)
                else:
                    factor_residue = pow(q_inv, -z, ell)
                new_residue = residue * factor_residue % ell
                new_witness = list(witness)
                new_witness[idx] = z
                next_states.setdefault(new_residue, tuple(new_witness))
        states = next_states

    witness = states.get(target)
    if witness is None:
        return None
    return witness, vals, C


def first_external_hit(
    p: int,
    ell_primes: list[int],
    max_external: int,
) -> dict | None:
    rank = 0
    for ell in ell_primes:
        if ell == p:
            continue
        if legendre(ell, p) != -1:
            continue
        rank += 1
        hit = shield_ratio_witness(p, ell)
        if hit is not None:
            witness, vals, C = hit
            return {
                "rank": rank,
                "ell": ell,
                "C": C,
                "valuations_2_3_5_7": list(vals),
                "signed_exponents_2_3_5_7": list(witness),
            }
        if rank >= max_external:
            return None
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=10_000_000)
    ap.add_argument("--ell-search-limit", type=int, default=100_000)
    ap.add_argument("--max-external", type=int, default=300)
    ap.add_argument(
        "--first-four-only",
        action="store_true",
        help="restrict to primes surviving the four exact hard-prime filters",
    )
    ap.add_argument("--examples", type=int, default=25)
    args = ap.parse_args()

    max_needed = max(args.limit, args.ell_search_limit)
    primes = sieve(max_needed)
    hard_primes = [p for p in primes if p <= args.limit and p % 840 in HARD]

    # The largest first-four shifted factor is below 3*limit/4, so trial
    # primes through sqrt(3*limit/4 + 1) suffice.
    trial_bound = math.isqrt(3 * args.limit // 4 + 2) + 2
    trial_primes = [q for q in primes if q <= trial_bound]

    if args.first_four_only:
        population = [p for p in hard_primes if survives_first_four(p, trial_primes)]
    else:
        population = hard_primes

    ell_primes = [
        ell
        for ell in primes
        if 11 <= ell <= args.ell_search_limit and ell % 4 == 3
    ]

    failures: list[int] = []
    hit_rank = Counter()
    hit_ell = Counter()
    hit_ratio = Counter()
    examples: list[dict] = []
    hardest: dict | None = None

    for p in population:
        hit = first_external_hit(p, ell_primes, args.max_external)
        if hit is None:
            failures.append(p)
            continue

        rank = int(hit["rank"])
        ell = int(hit["ell"])
        exps = tuple(hit["signed_exponents_2_3_5_7"])
        hit_rank[rank] += 1
        hit_ell[ell] += 1
        hit_ratio[str(exps)] += 1

        row = {"p": p, **hit}
        if hardest is None or rank > int(hardest["rank"]):
            hardest = row
        if len(examples) < args.examples:
            examples.append(row)

    result = {
        "limit": args.limit,
        "hard_primes": len(hard_primes),
        "population": len(population),
        "population_kind": (
            "first-four theorem survivors" if args.first_four_only else "all hard primes"
        ),
        "ell_search_limit": args.ell_search_limit,
        "max_external": args.max_external,
        "failures": len(failures),
        "failure_examples": failures[: args.examples],
        "hardest_hit": hardest,
        "hit_rank_histogram": dict(sorted(hit_rank.items())),
        "most_common_ell": hit_ell.most_common(20),
        "most_common_signed_ratios": hit_ratio.most_common(25),
        "examples": examples,
        "claim_boundary": (
            "finite exact falsifier only; zero failures at finite limit/search depth "
            "is not a universal Erdős-Straus proof"
        ),
    }
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
