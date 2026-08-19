#!/usr/bin/env python3
"""Independent direct-factorization checks for the k7/k23 support atlas."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
QR7 = {1, 2, 4}
QR11 = {1, 3, 4, 5, 9}
QR19 = {1, 4, 5, 6, 7, 9, 11, 16, 17}
QR23 = {1, 2, 3, 4, 6, 8, 9, 12, 13, 16, 18}
JACOBI_PLUS_15 = {1, 2, 4, 8}
RIGID_K23_RESIDUES = {2, 3, 4, 6, 8, 9, 12, 13, 16, 18}


def sieve(limit: int) -> bytearray:
    prime = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        prime[0] = 0
    if limit >= 1:
        prime[1] = 0
    for q in range(2, math.isqrt(limit) + 1):
        if prime[q]:
            start = q * q
            prime[start : limit + 1 : q] = b"\x00" * (((limit - start) // q) + 1)
    return prime


def factor(n: int, trial_primes: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial_primes:
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


def divisor_square_residues(factors: dict[int, int], k: int) -> set[int]:
    residues = {1}
    for q, e in factors.items():
        powers = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return residues


def fixed_shift_miss(p: int, k: int, trial_primes: list[int]) -> tuple[bool, dict[int, int]]:
    companion = (p + k) // 4
    factors = factor(companion, trial_primes)
    residues = divisor_square_residues(factors, k)
    type_i = (-pow(4, -1, k)) % k
    type_ii = (-companion) % k
    return type_i not in residues and type_ii not in residues, factors


def support(factors: dict[int, int], k: int, allowed: set[int]) -> bool:
    return all(q % k in allowed for q in factors)


def analyze(limit: int) -> dict[str, object]:
    prime = sieve(limit)
    trial_primes = [q for q in range(2, math.isqrt(limit) + 2) if q < len(prime) and prime[q]]
    counts: Counter[str] = Counter()
    failures: list[dict[str, object]] = []

    for p in range(2, limit + 1):
        if not prime[p] or p % 840 not in HARD_CLASSES:
            continue
        h = p % 840

        miss7, factors7 = fixed_shift_miss(p, 7, trial_primes)
        qr7 = support(factors7, 7, QR7)
        counts["k7_hard_primes"] += 1
        counts["k7_misses"] += int(miss7)
        if miss7 != qr7:
            failures.append({"kind": "k7-support", "p": p, "miss": miss7, "support": qr7})

        r23 = p % 23
        if r23 in RIGID_K23_RESIDUES:
            miss23, factors23 = fixed_shift_miss(p, 23, trial_primes)
            qr23 = support(factors23, 23, QR23)
            counts[f"k23_r{r23}_total"] += 1
            counts[f"k23_r{r23}_miss"] += int(miss23)
            if miss23 != qr23:
                failures.append({
                    "kind": "k23-rigid-support",
                    "p": p,
                    "p_mod_23": r23,
                    "miss": miss23,
                    "support": qr23,
                })

        if r23 == 8:
            miss15, factors15 = fixed_shift_miss(p, 15, trial_primes)
            plus15 = support(factors15, 15, JACOBI_PLUS_15)
            counts["route_r8_total"] += 1
            counts["route_r8_k15_miss"] += int(miss15)
            if miss15 != plus15:
                failures.append({"kind": "route-r8-k15-support", "p": p})
            A = ((p + 15) // 4) // 46
            B = ((p + 23) // 4) // 6
            if 3 * B - 23 * A != 1 or math.gcd(A, B) != 1:
                failures.append({"kind": "route-r8-equation", "p": p, "A": A, "B": B})

        if r23 == 12 and h in (169, 289, 529):
            miss11, factors11 = fixed_shift_miss(p, 11, trial_primes)
            qr11 = support(factors11, 11, QR11)
            counts["route_r12_total"] += 1
            counts["route_r12_k11_miss"] += int(miss11)
            if miss11 != qr11:
                failures.append({"kind": "route-r12-k11-support", "p": p, "h": h})
            A = ((p + 11) // 4) // 345
            B = ((p + 23) // 4) // 6
            if 2 * B - 115 * A != 1 or math.gcd(A, B) != 1:
                failures.append({"kind": "route-r12-equation", "p": p, "A": A, "B": B})

        if r23 == 4 and h in (121, 289):
            miss19, factors19 = fixed_shift_miss(p, 19, trial_primes)
            qr19 = support(factors19, 19, QR19)
            counts[f"route_r4_h{h}_total"] += 1
            counts[f"route_r4_h{h}_k19_miss"] += int(miss19)
            if miss19 != qr19:
                failures.append({"kind": "route-r4-k19-support", "p": p, "h": h})
            scale = 805 if h == 121 else 161
            A = ((p + 19) // 4) // scale
            B = ((p + 23) // 4) // 6
            if 6 * B - scale * A != 1 or math.gcd(A, B) != 1:
                failures.append({"kind": "route-r4-equation", "p": p, "h": h, "A": A, "B": B})

        if r23 == 16:
            A = ((p + 7) // 4) // 46
            B = ((p + 23) // 4) // 6
            counts["route_r16_total"] += 1
            if 3 * B - 23 * A != 2 or math.gcd(A, B) not in (1, 2):
                failures.append({"kind": "route-r16-equation", "p": p, "A": A, "B": B})

    required = [
        "k7_misses",
        "k23_r8_miss",
        "k23_r12_miss",
        "k23_r16_miss",
        "route_r8_k15_miss",
        "route_r12_k11_miss",
        "route_r4_h121_k19_miss",
        "route_r4_h289_k19_miss",
    ]
    for key in required:
        if counts[key] == 0:
            failures.append({"kind": "missing-realization", "counter": key})

    return {
        "analysis": "k7-k23-rigid-support-independent-regression-v1",
        "limit": limit,
        "counts": dict(sorted(counts.items())),
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": "finite direct-factorization regression only; theorem closures are checked separately",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=2_000_000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"limit: {report['limit']}")
        print(f"failures: {report['failures']}")
        for key, value in report["counts"].items():
            print(f"{key}: {value}")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
