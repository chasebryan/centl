#!/usr/bin/env python3
"""Enumerate genuine two-source and three-source QR-saturation synergies.

A synergy is genuine when the destination class seed is not QR-saturating,
no proper routed subset saturates it, but the named routed factors together do.
Only already-proved positive-character source nodes are admitted.
"""
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

RIGID_23_RESIDUES = {2, 3, 4, 6, 8, 9, 12, 13, 16, 18}

EXPECTED_PAIRS = [
    (121, 31, 2, (19, 47), 1786, (7, 16)),
    (121, 79, 10, (19, 23), 4370, (16, 13)),
    (169, 19, 1, (11, 23), 253, (3, 4)),
    (169, 83, 21, (11, 23), 5313, (5, 9)),
    (169, 83, 21, (11, 31), 7161, (5, 10)),
    (169, 83, 21, (23, 31), 14973, (9, 10)),
    (169, 167, 42, (11, 31), 14322, (9, 19)),
    (529, 19, 1, (11, 23), 253, (3, 4)),
]

EXPECTED_TRIPLES = [
    (169, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
    (289, 167, 6, (11, 31, 47), 96162, (9, 19, 21)),
    (529, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (529, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
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


def divisor_square_residues(seed: int, k: int) -> set[int]:
    residues = {1}
    for q, e in factorization(seed).items():
        powers = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return residues


def qr(k: int) -> set[int]:
    return {x * x % k for x in range(1, k)}


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def saturates(seed: int, k: int) -> bool:
    return (
        is_prime(k)
        and k % 4 == 3
        and math.gcd(seed, k) == 1
        and divisor_square_residues(seed, k) == qr(k)
    )


def source_route_allowed(source_q: int, h: int, destination_k: int) -> bool:
    r = (-destination_k) % source_q
    if r == 0:
        return False
    if source_q == 7:
        return r == h % 7
    if source_q == 23:
        return r in RIGID_23_RESIDUES
    return r in qr(source_q)


def row_for(h: int, k: int, base: int, sources: tuple[int, ...]) -> tuple:
    seed = math.lcm(base, *sources)
    residues = tuple((-k) % q for q in sources)
    return (h, k, base, sources, seed, residues)


def analyze(max_k: int) -> dict[str, object]:
    pairs: list[tuple] = []
    triples: list[tuple] = []

    for h in HARD_CLASSES:
        for k in range(3, max_k + 1, 4):
            if not is_prime(k):
                continue
            base = class_seed(k, h)
            if saturates(base, k):
                continue
            sources = tuple(
                q for q in ACTIVE_SOURCES[h]
                if q != k and source_route_allowed(q, h, k)
            )

            for routed in itertools.combinations(sources, 2):
                seed = math.lcm(base, *routed)
                if not saturates(seed, k):
                    continue
                if any(saturates(math.lcm(base, q), k) for q in routed):
                    continue
                pairs.append(row_for(h, k, base, routed))

            for routed in itertools.combinations(sources, 3):
                seed = math.lcm(base, *routed)
                if not saturates(seed, k):
                    continue
                if any(saturates(math.lcm(base, q), k) for q in routed):
                    continue
                if any(
                    saturates(math.lcm(base, *pair), k)
                    for pair in itertools.combinations(routed, 2)
                ):
                    continue
                triples.append(row_for(h, k, base, routed))

    pairs.sort()
    triples.sort()
    if pairs != EXPECTED_PAIRS:
        raise SystemExit(f"pair synergy atlas changed: {pairs!r}")
    if triples != EXPECTED_TRIPLES:
        raise SystemExit(f"triple synergy atlas changed: {triples!r}")

    def encode(row: tuple) -> dict[str, object]:
        h, k, base, sources, seed, residues = row
        return {
            "hard_class": h,
            "destination_k": k,
            "base_seed": base,
            "source_primes": list(sources),
            "required_source_residues": list(residues),
            "combined_seed": seed,
            "qr_subgroup_size": (k - 1) // 2,
            "proper_routed_subsets_saturate": False,
        }

    return {
        "analysis": "multisource-qr-saturation-atlas-v1",
        "max_destination_k": max_k,
        "pair_synergy_count": len(pairs),
        "triple_synergy_count": len(triples),
        "pair_synergies": [encode(row) for row in pairs],
        "triple_synergies": [encode(row) for row in triples],
        "record_anchor": {
            "p": 8803369,
            "hard_class": 169,
            "destination_k": 19,
            "source_primes": [11, 23],
            "source_residues": [3, 4],
            "C19": 2200847,
            "factorization": "11*23*8699",
            "combined_seed": 253,
        },
        "claim": (
            "exact multi-source divisor-lattice synergy: no proper routed subset "
            "saturates the destination QR subgroup, but the named combined seed does"
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
        print(f"pair synergies: {report['pair_synergy_count']}")
        print(f"triple synergies: {report['triple_synergy_count']}")
        for row in report["pair_synergies"]:
            print("PAIR", row)
        for row in report["triple_synergies"]:
            print("TRIPLE", row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
