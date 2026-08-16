#!/usr/bin/env python3
"""Classify composite Jacobi-kernel saturation and extracted prime characters."""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import Counter

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
ACTIVE_SOURCES = {
    1: (7, 23),
    121: (7, 19, 23, 47),
    169: (7, 11, 23, 31),
    289: (7, 11, 23, 31, 47),
    361: (7, 23, 59),
    529: (7, 11, 23, 31),
}
RIGID_23 = {2, 3, 4, 6, 8, 9, 12, 13, 16, 18}

EXPECTED_SINGLE_COMPOSITE = [
    (1, 15, 2, 23, 46, 8),
    (121, 15, 2, 19, 38, 4),
    (121, 15, 2, 23, 46, 8),
    (121, 15, 2, 47, 94, 32),
    (121, 39, 10, 47, 470, 8),
    (169, 15, 2, 23, 46, 8),
    (169, 111, 70, 23, 1610, 4),
    (289, 15, 2, 23, 46, 8),
    (289, 15, 2, 47, 94, 32),
    (361, 15, 2, 23, 46, 8),
    (529, 15, 2, 23, 46, 8),
]
EXPECTED_PAIR_COMPOSITE = [
    (169, 51, 5, (11, 23), 1265, (4, 18)),
    (289, 35, 3, (11, 47), 1551, (9, 12)),
    (289, 39, 2, (11, 47), 1034, (5, 8)),
    (289, 51, 5, (11, 23), 1265, (4, 18)),
    (289, 215, 42, (11, 31), 14322, (5, 2)),
    (529, 51, 5, (11, 23), 1265, (4, 18)),
    (529, 171, 35, (11, 23), 8855, (5, 13)),
]
EXPECTED_EXTRACTIONS = [
    (121, 39, (47,), (8,), 13, 1),
    (169, 51, (11, 23), (4, 18), 17, 1),
    (169, 111, (23,), (4,), 37, 1),
    (289, 39, (11, 47), (5, 8), 13, 1),
    (289, 51, (11, 23), (4, 18), 17, 1),
    (289, 215, (11, 31), (5, 2), 43, 1),
    (529, 51, (11, 23), (4, 18), 17, 1),
    (529, 171, (11, 23), (5, 13), 19, 1),
]


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    d = 3
    while d * d <= n:
        if n % d == 0:
            return False
        d += 2
    return True


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


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError(n)
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


def divisor_square_residues(seed: int, k: int) -> set[int]:
    residues = {1}
    for q, e in factorization(seed).items():
        powers = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return residues


def jacobi_kernel(k: int) -> set[int]:
    return {
        u for u in range(1, k)
        if math.gcd(u, k) == 1 and jacobi(u, k) == 1
    }


def saturates(seed: int, k: int) -> bool:
    return (
        k % 4 == 3
        and math.gcd(seed, k) == 1
        and divisor_square_residues(seed, k) == jacobi_kernel(k)
    )


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def qr(q: int) -> set[int]:
    return {x * x % q for x in range(1, q)}


def source_allowed(q: int, h: int, k: int) -> bool:
    r = (-k) % q
    if r == 0:
        return False
    if q == 7:
        return r == h % 7
    if q == 23:
        return r in RIGID_23
    return r in qr(q)


def unknown_character_factor(k: int) -> int | None:
    unknown = [
        q for q, e in factorization(k).items()
        if e % 2 == 1 and 840 % q != 0
    ]
    return unknown[0] if len(unknown) == 1 else None


def fixed_character_product(h: int, k: int, unknown: int) -> int:
    product = 1
    for q, e in factorization(k).items():
        if e % 2 == 0 or q == unknown:
            continue
        # p=1 mod4, so (q/p)=(p/q); h fixes p mod q whenever q|840.
        if 840 % q != 0:
            raise RuntimeError((h, k, unknown, q))
        v = pow(h % q, (q - 1) // 2, q)
        product *= -1 if v == q - 1 else 1
    return product


def analyze(max_k: int) -> dict[str, object]:
    singles = []
    pairs = []

    for h in HARD_CLASSES:
        for k in range(3, max_k + 1, 4):
            if is_prime(k):
                continue
            base = class_seed(k, h)
            if math.gcd(base, k) != 1 or saturates(base, k):
                continue
            routed = [q for q in ACTIVE_SOURCES[h] if q != k and source_allowed(q, h, k)]

            for q in routed:
                seed = math.lcm(base, q)
                if seed != base and saturates(seed, k):
                    singles.append((h, k, base, q, seed, (-k) % q))

            for sources in itertools.combinations(routed, 2):
                seed = math.lcm(base, *sources)
                if not saturates(seed, k):
                    continue
                if any(saturates(math.lcm(base, q), k) for q in sources):
                    continue
                pairs.append((
                    h, k, base, sources, seed,
                    tuple((-k) % q for q in sources),
                ))

    singles.sort()
    pairs.sort()
    if singles != EXPECTED_SINGLE_COMPOSITE:
        raise SystemExit(f"single composite atlas changed: {singles!r}")
    if pairs != EXPECTED_PAIR_COMPOSITE:
        raise SystemExit(f"pair composite atlas changed: {pairs!r}")

    extractions = []
    for h, k, base, q, seed, r in singles:
        unknown = unknown_character_factor(k)
        if unknown is None:
            continue
        fixed = fixed_character_product(h, k, unknown)
        extractions.append((h, k, (q,), (r,), unknown, fixed))
    for h, k, base, sources, seed, residues in pairs:
        unknown = unknown_character_factor(k)
        if unknown is None:
            continue
        fixed = fixed_character_product(h, k, unknown)
        extractions.append((h, k, sources, residues, unknown, fixed))

    extractions.sort()
    if extractions != EXPECTED_EXTRACTIONS:
        raise SystemExit(f"character extraction atlas changed: {extractions!r}")

    return {
        "analysis": "jacobi-saturation-character-extraction-v1",
        "max_composite_shift": max_k,
        "single_source_composite_saturations": len(singles),
        "genuine_pair_composite_saturations": len(pairs),
        "extracted_prime_character_branches": [
            {
                "hard_class": h,
                "composite_shift": k,
                "source_primes": list(sources),
                "required_source_residues": list(residues),
                "extracted_prime": q,
                "forced_character": fixed,
            }
            for h, k, sources, residues, q, fixed in extractions
        ],
        "extraction_count": len(extractions),
        "claim": (
            "Jacobi-kernel saturation at k=3 mod4 makes a miss equivalent to "
            "Jacobi-plus prime support and forces (k/p)=+1; when all but one "
            "odd-exponent prime factor of k are class-fixed, the remaining prime "
            "character is extracted exactly"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-k", type=int, default=5000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze(args.max_k)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"single composite saturations: {report['single_source_composite_saturations']}")
        print(f"pair composite saturations: {report['genuine_pair_composite_saturations']}")
        print(f"extracted prime characters: {report['extraction_count']}")
        for row in report["extracted_prime_character_branches"]:
            print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
