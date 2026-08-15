#!/usr/bin/env python3
"""Replay the one-shot Erdős–Straus theorem-mining filters.

Standard-library only.  This is a finite theorem falsifier / census tool.
It does not prove Erdős–Straus.

Checks:
  * six Mordell-hard residue classes mod 840;
  * the four exact shifted-factor restrictions in FAB-HARD-FIRST-FILTERS.md;
  * FOUR-P-PLUS-ONE-FILTER.md;
  * P-PLUS-FOUR-FILTER.md;
  * optional binary-remainder divisor coverage for prime r == 3 (mod 4).

For r == 3 (mod 4), put A=(p+r)/4 and N=p*A.  After subtracting
1/A from 4/p, the remaining binary fraction is r/N.  It splits into
two unit fractions iff N^2 has a divisor d == -N (mod r).  For prime
r != p, gcd(N,r)=1, so the complementary divisor N^2/d automatically
lies in the same target class and both binary denominators are integral.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD = {1, 121, 169, 289, 361, 529}


def sieve_primes(n: int) -> list[int]:
    if n < 2:
        return []
    bs = bytearray(b"\x01") * (n + 1)
    bs[:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            start = p * p
            bs[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [i for i, v in enumerate(bs) if v]


def factorint(n: int, trial_primes: list[int]) -> dict[int, int]:
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


def first_four_survivor(p: int, trial_primes: list[int]) -> bool:
    # 1. (p+1)/2 has only odd prime factors 1 mod 4.
    f = factorint((p + 1) // 2, trial_primes)
    if any(q != 2 and q % 4 != 1 for q in f):
        return False

    # 2. (p+3)/4 has only prime factors 1 mod 3.
    f = factorint((p + 3) // 4, trial_primes)
    if any(q % 3 != 1 for q in f):
        return False

    # 3. (3p+1)/4 has only prime factors 1 mod 3.
    f = factorint((3 * p + 1) // 4, trial_primes)
    if any(q % 3 != 1 for q in f):
        return False

    # 4. p+2 has only prime factors 1 or 3 mod 8.
    f = factorint(p + 2, trial_primes)
    if any(q % 8 not in (1, 3) for q in f):
        return False

    return True


def four_p_plus_one_survives(p: int, trial_primes: list[int]) -> bool:
    """Failure of FOUR-P-PLUS-ONE-FILTER: all prime factors are 1 mod 4."""
    return all(q % 4 == 1 for q in factorint(4 * p + 1, trial_primes))


def p_plus_four_survives(p: int, trial_primes: list[int]) -> bool:
    """Failure of P-PLUS-FOUR-FILTER: all prime factors are 1 mod 4."""
    return all(q % 4 == 1 for q in factorint(p + 4, trial_primes))


def reachable_divisor_residues_square(
    p: int, A: int, mod: int, trial_primes: list[int]
) -> set[int]:
    """Residues mod `mod` attained by divisors of (p*A)^2.

    We know p is prime.  A is factored independently.  Exponent ranges are
    doubled because the binary criterion uses N^2.
    """
    f = factorint(A, trial_primes)
    f[p] = f.get(p, 0) + 1

    reach = {1 % mod}
    for q, e in f.items():
        powers = [pow(q, j, mod) for j in range(2 * e + 1)]
        reach = {(x * y) % mod for x in reach for y in powers}
        if len(reach) == mod:
            break
    return reach


def binary_r_hit(p: int, r: int, trial_primes: list[int]) -> bool:
    if r <= 1 or r % 4 != 3:
        raise ValueError("r must be >1 and 3 mod 4")
    if (p + r) % 4:
        return False
    A = (p + r) // 4
    N_mod_r = (p % r) * (A % r) % r
    target = (-N_mod_r) % r
    reach = reachable_divisor_residues_square(p, A, r, trial_primes)
    return target in reach


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=500_000)
    ap.add_argument(
        "--r-max",
        type=int,
        default=200,
        help="test prime binary numerators r == 3 mod 4 up to this bound",
    )
    ap.add_argument("--examples", type=int, default=20)
    args = ap.parse_args()

    if args.limit < 2:
        raise SystemExit("--limit must be >= 2")

    # All factored shifted forms are <= 4*limit+1.  In the binary test N can
    # be quadratic in p, but only A=(p+r)/4 is independently factored because
    # p itself is already known prime.  Trial primes through sqrt(4L+1) are
    # therefore enough for the default theorem-mining ranges.
    trial_primes = sieve_primes(math.isqrt(4 * args.limit + 1) + 1)
    primes = sieve_primes(args.limit)
    hard = [p for p in primes if p % 840 in HARD]

    four_survivors: list[int] = []
    six_survivors: list[int] = []
    killed_4p1 = 0
    killed_p4_after_4p1 = 0

    for p in hard:
        if not first_four_survivor(p, trial_primes):
            continue
        four_survivors.append(p)
        if not four_p_plus_one_survives(p, trial_primes):
            killed_4p1 += 1
            continue
        if not p_plus_four_survives(p, trial_primes):
            killed_p4_after_4p1 += 1
            continue
        six_survivors.append(p)

    r_primes = [r for r in sieve_primes(args.r_max) if r % 4 == 3]
    min_r_hist: Counter[int] = Counter()
    binary_unresolved: list[int] = []
    binary_examples: list[dict] = []

    for p in four_survivors:
        hits = [r for r in r_primes if binary_r_hit(p, r, trial_primes)]
        if not hits:
            binary_unresolved.append(p)
        else:
            min_r_hist[min(hits)] += 1
            if len(binary_examples) < args.examples:
                binary_examples.append({"p": p, "first_r": min(hits), "hits": hits[:8]})

    summary = {
        "limit": args.limit,
        "hard_primes": len(hard),
        "first_four_survivors": len(four_survivors),
        "four_p_plus_one_kills": killed_4p1,
        "p_plus_four_additional_kills": killed_p4_after_4p1,
        "first_six_survivors": len(six_survivors),
        "binary_r_max": args.r_max,
        "binary_test_population": "first-four survivors",
        "binary_unresolved": len(binary_unresolved),
        "binary_unresolved_examples": binary_unresolved[: args.examples],
        "first_binary_r_histogram": dict(sorted(min_r_hist.items())),
        "binary_examples": binary_examples,
        "claim_boundary": (
            "finite census/falsifier only; zero unresolved in a finite range is not a "
            "universal Erdős–Straus proof"
        ),
    }
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
