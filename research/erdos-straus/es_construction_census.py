#!/usr/bin/env python3
"""Construction census for prime Erdős–Straus.

Standard-library only. Finite theorem-mining / falsification tool.
Does not prove Erdős–Straus.

For each Mordell-hard prime it records:
  * known exact linear-form filter survival;
  * first two-target signed-box hit in the Type-II corridor and beyond;
  * least external nonresidue prime shift;
  * whether the a=1 / c=ell factor-pair construction works;
  * small coprime (a,b) fab window.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, defaultdict


HARD = (1, 121, 169, 289, 361, 529)


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
    x = abs(n)
    if x <= 1:
        return out
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
            return out
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("jacobi modulus must be odd positive")
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


def signed_box(factors: dict[int, int], mod: int) -> set[int]:
    reach = {1 % mod}
    for r, e in factors.items():
        if math.gcd(r, mod) != 1:
            return set()
        powers = [pow(r, z, mod) for z in range(-e, e + 1)]
        reach = {(x * y) % mod for x in reach for y in powers}
        if len(reach) == math.gcd(1, 1) and False:
            pass
    return reach


def two_target_hit(p: int, k: int, trial_primes: list[int]) -> str | None:
    if k % 4 != 3 or math.gcd(k, p) != 1:
        return None
    if (p + k) % 4:
        return None
    c = (p + k) // 4
    fac = factorint(c, trial_primes)
    box = signed_box(fac, k)
    if not box:
        return None
    t_ii = (-1) % k
    t_i = (-pow(p, -1, k)) % k
    hit_ii = t_ii in box
    hit_i = t_i in box
    if hit_ii and hit_i:
        return "both"
    if hit_ii:
        return "II"
    if hit_i:
        return "I"
    return None


def all_factors_in(n: int, trial_primes: list[int], pred) -> bool:
    if n <= 1:
        return True
    return all(pred(q) for q in factorint(n, trial_primes))


def first_four_survivor(p: int, trial_primes: list[int]) -> bool:
    if not all_factors_in((p + 1) // 2, trial_primes, lambda q: q == 2 or q % 4 == 1):
        return False
    if not all_factors_in((p + 3) // 4, trial_primes, lambda q: q % 3 == 1):
        return False
    if not all_factors_in((3 * p + 1) // 4, trial_primes, lambda q: q % 3 == 1):
        return False
    if not all_factors_in(p + 2, trial_primes, lambda q: q % 8 in (1, 3)):
        return False
    return True


def four_p_plus_one_survives(p: int, trial_primes: list[int]) -> bool:
    return all_factors_in(4 * p + 1, trial_primes, lambda q: q % 4 == 1)


def p_plus_four_survives(p: int, trial_primes: list[int]) -> bool:
    return all_factors_in(p + 4, trial_primes, lambda q: q % 4 == 1)


def two_p_plus_one_survives(p: int, trial_primes: list[int]) -> bool:
    # proved below: divisor 7 mod 8 of 2p+1 solves hard p via (a,b)=(1,2)
    return all_factors_in(2 * p + 1, trial_primes, lambda q: q % 8 in (1, 3))


def has_divisor_class(n: int, mod: int, residue: int, trial_primes: list[int]) -> bool:
    fac = factorint(n, trial_primes)
    reach = {1 % mod}
    for q, e in fac.items():
        powers = [pow(q, j, mod) for j in range(e + 1)]
        reach = {(x * y) % mod for x in reach for y in powers}
        if residue % mod in reach:
            return True
    return residue % mod in reach


def fab_pair_hit(p: int, a: int, b: int, trial_primes: list[int]) -> bool:
    if math.gcd(a, b) != 1 or a >= p or b >= p:
        return False
    n = a + b * p
    target = (-p) % (4 * a * b)
    return has_divisor_class(n, 4 * a * b, target, trial_primes)


def least_nr_prime(p: int, primes: list[int]) -> int | None:
    for q in primes:
        if q < 11 or q % 4 != 3 or q == p:
            continue
        if jacobi(q, p) == -1:
            return q
    return None


def a1_ell_hit(p: int, ell: int, trial_primes: list[int]) -> bool:
    """a=1, c=ell: p^2+4ell has a factor ≡ -p (mod 4ell)."""
    n = p * p + 4 * ell
    return has_divisor_class(n, 4 * ell, (-p) % (4 * ell), trial_primes)


def first_corridor_hit(
    p: int, trial_primes: list[int], h_max: int
) -> tuple[int, str] | None:
    for h in range(h_max + 1):
        k = 4 * h + 3
        if k == p:
            continue
        kind = two_target_hit(p, k, trial_primes)
        if kind:
            return k, kind
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=200_000)
    ap.add_argument("--h-max", type=int, default=400)
    ap.add_argument("--ab-max", type=int, default=11)
    ap.add_argument("--examples", type=int, default=25)
    args = ap.parse_args()

    trial_primes = sieve_primes(math.isqrt(args.limit * args.limit + 4 * args.limit) + 100)
    # factorization of p^2+4ell needs trial up to ~p for the largest leftover
    # but leftover primality is fine as a single cofactor
    small_primes = sieve_primes(max(args.limit, 10_000))
    hard = [p for p in sieve_primes(args.limit) if p % 840 in HARD and p > 5]

    filter_names = [
        "four_core",
        "4p+1",
        "p+4",
        "2p+1",
    ]
    survivors = list(hard)
    killed = {}

    next_s = []
    for p in survivors:
        if first_four_survivor(p, small_primes):
            next_s.append(p)
    killed["four_core"] = len(survivors) - len(next_s)
    survivors = next_s

    next_s = []
    for p in survivors:
        if four_p_plus_one_survives(p, small_primes):
            next_s.append(p)
    killed["4p+1"] = len(survivors) - len(next_s)
    survivors = next_s

    next_s = []
    for p in survivors:
        if p_plus_four_survives(p, small_primes):
            next_s.append(p)
    killed["p+4"] = len(survivors) - len(next_s)
    survivors = next_s

    next_s = []
    for p in survivors:
        if two_p_plus_one_survives(p, small_primes):
            next_s.append(p)
    killed["2p+1"] = len(survivors) - len(next_s)
    six_plus = list(survivors)
    survivors = next_s

    # extra linear-form kill rates on the 2p+1 survivors
    extra_forms = {
        "8p+1": lambda p: 8 * p + 1,
        "4p-3": lambda p: 4 * p - 3,
        "2p-1": lambda p: 2 * p - 1,
        "p+8": lambda p: p + 8,
        "p+16": lambda p: p + 16,
        "16p+1": lambda p: 16 * p + 1,
        "p-4": lambda p: p - 4,
        "8p-3": lambda p: 8 * p - 3,
        "4p+9": lambda p: 4 * p + 9,
        "3p+2": lambda p: 3 * p + 2,
        "5p+1": lambda p: 5 * p + 1,
        "5p+4": lambda p: 5 * p + 4,
    }
    extra_kill = {}
    extra_pred = {
        "8p+1": lambda q: q % 4 == 1,
        "4p-3": lambda q: q % 4 == 1,
        "2p-1": lambda q: q % 4 == 1,
        "p+8": lambda q: q % 4 == 1,
        "p+16": lambda q: q % 4 == 1,
        "16p+1": lambda q: q % 4 == 1,
        "p-4": lambda q: q % 4 == 1,
        "8p-3": lambda q: q % 4 == 1,
        "4p+9": lambda q: q % 4 == 1,
        "3p+2": lambda q: q % 3 == 1,
        "5p+1": lambda q: q % 4 == 1,
        "5p+4": lambda q: q % 4 == 1,
    }
    for name, form in extra_forms.items():
        extra_kill[name] = sum(
            1
            for p in survivors
            if not all_factors_in(form(p), small_primes, extra_pred[name])
        )

    first_hit: Counter[str] = Counter()
    first_k: Counter[int] = Counter()
    first_kind: Counter[str] = Counter()
    unresolved_corridor = []
    hit_examples = []

    nr_hit = Counter()
    nr_miss = []
    a1_hit = 0
    a1_miss = []
    ab_hist: Counter[tuple[int, int]] = Counter()
    ab_unresolved = []

    pairs = [
        (a, b)
        for a in range(1, args.ab_max + 1)
        for b in range(1, args.ab_max + 1)
        if math.gcd(a, b) == 1
    ]

    nr_primes = [q for q in small_primes if q % 4 == 3]

    for p in survivors:
        hit = first_corridor_hit(p, small_primes, args.h_max)
        if hit is None:
            unresolved_corridor.append(p)
        else:
            k, kind = hit
            first_k[k] += 1
            first_kind[kind] += 1
            first_hit[f"{k}:{kind}"] += 1
            if len(hit_examples) < args.examples:
                hit_examples.append({"p": p, "k": k, "kind": kind, "C": (p + k) // 4})

        ell = least_nr_prime(p, nr_primes)
        if ell is None:
            nr_miss.append({"p": p, "reason": "no_nr_in_range"})
        else:
            kind = two_target_hit(p, ell, small_primes)
            if kind:
                nr_hit[f"{ell}:{kind}"] += 1
            else:
                nr_miss.append({"p": p, "ell": ell, "C": (p + ell) // 4})
            if a1_ell_hit(p, ell, trial_primes if p * p + 200 < trial_primes[-1] ** 2 else small_primes):
                a1_hit += 1
            else:
                a1_miss.append({"p": p, "ell": ell})

        won = None
        for a, b in pairs:
            if fab_pair_hit(p, a, b, small_primes):
                won = (a, b)
                break
        if won:
            ab_hist[won] += 1
        else:
            ab_unresolved.append(p)

    summary = {
        "limit": args.limit,
        "hard_primes": len(hard),
        "killed": killed,
        "survivors_after_2p+1": len(survivors),
        "survivor_examples": survivors[: args.examples],
        "extra_3mod4_factor_kills_on_those_survivors": extra_kill,
        "corridor": {
            "h_max": args.h_max,
            "unresolved": len(unresolved_corridor),
            "unresolved_examples": unresolved_corridor[: args.examples],
            "first_k": dict(sorted(first_k.items())),
            "first_kind": dict(first_kind),
            "first_hit": dict(sorted(first_hit.items())),
            "examples": hit_examples,
        },
        "least_nr_shift": {
            "hit_hist": dict(sorted(nr_hit.items())),
            "misses": len(nr_miss),
            "miss_examples": nr_miss[: args.examples],
        },
        "a1_c_ell": {
            "hits": a1_hit,
            "misses": len(a1_miss),
            "miss_examples": a1_miss[: args.examples],
        },
        "fab_window": {
            "ab_max": args.ab_max,
            "first_pair_hist": {f"{a},{b}": n for (a, b), n in sorted(ab_hist.items())},
            "unresolved": len(ab_unresolved),
            "unresolved_examples": ab_unresolved[: args.examples],
        },
        "claim_boundary": (
            "finite census only; not a proof of Erdős–Straus"
        ),
    }
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
