#!/usr/bin/env python3
"""Classify class seeds and routed seeds that saturate a prime QR subgroup."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD_CLASSES = (1, 121, 169, 289, 361, 529)

SOURCE_CLASSES = {
    7: HARD_CLASSES,
    11: (169, 289, 529),
    19: (121,),
    23: HARD_CLASSES,
    31: (169, 289, 529),
    47: (121, 289),
}
RIGID_23_RESIDUES = (2, 3, 4, 6, 8, 9, 12, 13, 16, 18)

EXPECTED_NOVEL = [
    (23, 289, 4, 19, 7, 161),
    (31, 169, 8, 23, 6, 186),
    (31, 289, 8, 23, 6, 186),
    (31, 529, 8, 23, 6, 186),
    (47, 121, 36, 11, 3, 141),
    (47, 289, 16, 31, 10, 470),
    (47, 289, 28, 19, 7, 329),
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


def prime_factorization(n: int) -> Counter[int]:
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
    for q, e in prime_factorization(seed).items():
        powers = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return residues


def quadratic_residues(k: int) -> set[int]:
    return {x * x % k for x in range(1, k)}


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def route_shift(q: int, p_residue: int) -> int:
    for k in range(3, 4 * q, 4):
        if (p_residue + k) % q == 0:
            return k
    raise RuntimeError((q, p_residue))


def source_residues(q: int, h: int) -> list[int]:
    if q == 7:
        return [h % 7]
    if q == 23:
        return list(RIGID_23_RESIDUES)
    return sorted(quadratic_residues(q))


def saturates(seed: int, k: int) -> bool:
    if not is_prime(k) or k % 4 != 3 or math.gcd(seed, k) != 1:
        return False
    return divisor_square_residues(seed, k) == quadratic_residues(k)


def analyze(max_class_shift: int) -> dict[str, object]:
    baseline = []
    for k in range(3, max_class_shift + 1, 4):
        if not is_prime(k):
            continue
        for h in HARD_CLASSES:
            seed = class_seed(k, h)
            if saturates(seed, k):
                baseline.append((k, h, seed))

    routed = []
    novel = []
    for q, classes in SOURCE_CLASSES.items():
        for h in classes:
            for r in source_residues(q, h):
                k = route_shift(q, r)
                if not is_prime(k):
                    continue
                base = class_seed(k, h)
                seed = math.lcm(base, q)
                if saturates(seed, k):
                    row = (q, h, r, k, base, seed)
                    routed.append(row)
                    if not saturates(base, k) and seed != base:
                        novel.append(row)

    novel.sort()
    if novel != EXPECTED_NOVEL:
        raise SystemExit(f"novel routed saturation atlas changed: {novel!r}")

    expected_baseline_count = 17
    if len(baseline) != expected_baseline_count:
        raise SystemExit(
            f"baseline saturation count changed through {max_class_shift}: "
            f"{len(baseline)} != {expected_baseline_count}"
        )

    return {
        "analysis": "qr-saturating-route-atlas-v1",
        "max_class_shift": max_class_shift,
        "baseline_saturating_class_shift_pairs": [
            {"k": k, "h": h, "seed": seed} for k, h, seed in baseline
        ],
        "baseline_count": len(baseline),
        "routed_saturating_edges": len(routed),
        "novel_routed_saturation_upgrades": [
            {
                "source_q": q,
                "hard_class": h,
                "source_p_residue": r,
                "destination_k": k,
                "base_seed": base,
                "routed_seed": seed,
            }
            for q, h, r, k, base, seed in novel
        ],
        "novel_upgrade_count": len(novel),
        "claim": (
            "exact divisor-lattice saturation: when divisors of S^2 equal the QR subgroup "
            "at prime k=3 mod4, S|C_k makes a k-miss equivalent to QR-only prime support"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-class-shift", type=int, default=5000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze(args.max_class_shift)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"baseline saturating pairs: {report['baseline_count']}")
        print(f"novel routed upgrades: {report['novel_upgrade_count']}")
        for row in report["novel_routed_saturation_upgrades"]:
            print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
