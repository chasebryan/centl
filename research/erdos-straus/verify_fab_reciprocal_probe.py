#!/usr/bin/env python3
"""Independent verifier for fab_reciprocal_probe.py outputs.

This verifier does not rediscover divisors or repeat the signed-residue search.
It independently sieves the claimed hard-prime population, checks that there is
exactly one supplied certificate for every selected prime, and verifies each
certificate, square-divisor claim, congruence, and Egyptian-fraction identity
with direct integer arithmetic.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


def prime_sieve(limit: int) -> list[int]:
    flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        flags[0] = 0
    if limit >= 1:
        flags[1] = 0
    for p in range(2, math.isqrt(limit) + 1):
        if flags[p]:
            start = p * p
            flags[start : limit + 1 : p] = b"\x00" * (((limit - start) // p) + 1)
    return [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]


def verify_row(row: dict) -> None:
    p = int(row["p"])
    lane = row["lane"]
    m = int(row["m"])
    n = int(row["square_base"])
    D = int(row["D"])

    a = int(row["a"])
    b = int(row["b"])
    c = int(row["c"])
    k = int(row["k"])
    d = int(row["d"])
    q = int(row["q"])
    x = int(row["x"])
    y = int(row["y"])
    z = int(row["z"])

    assert p % 840 in HARD
    assert m >= 3 and m % 4 == 3
    assert min(a, b, c, k, d, q, D) > 0

    if lane == "forward":
        assert k == m
        assert n == (p + m) // 4
        assert D == b * b * c
    elif lane == "reciprocal":
        assert d == m
        assert n == (p * m + 1) // 4
        assert D == b * b * c
    else:
        raise AssertionError(f"unknown lane: {lane}")

    assert (n * n) % D == 0
    assert (4 * D + 1) % m == 0
    assert 4 * D % m == (-1) % m

    assert k % 4 == 3
    assert d % 4 == 3
    assert p + k == 4 * a * b * c
    assert p * d + 1 == 4 * b * c * q
    assert k * d == 1 + 4 * b * b * c
    assert q == a * d - b
    assert k * q == a + b * p

    assert x == a * b * c
    assert y == a * c * q
    assert z == b * c * p * q

    # Exact verification of 4/p = 1/x + 1/y + 1/z.
    assert 4 * x * y * z == p * (y * z + x * z + x * y)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    summary = json.loads((args.out / "summary.json").read_text())
    rows = [
        json.loads(line)
        for line in (args.out / "first-success-certificates.jsonl").read_text().splitlines()
        if line.strip()
    ]

    limit = int(summary["limit"])
    expected_primes = prime_sieve(limit)
    supplied_primes = [int(row["p"]) for row in rows]

    assert len(supplied_primes) == len(set(supplied_primes)), "duplicate prime certificates"
    assert sorted(supplied_primes) == expected_primes, "certificate population differs from independent hard-prime sieve"
    assert summary["hard_prime_count"] == len(expected_primes)
    assert summary["captured_count"] == len(rows)
    assert summary["unresolved_count"] == 0
    assert summary["unresolved"] == []

    observed_distribution: dict[tuple[str, int], int] = {}
    max_m = None

    for row in rows:
        verify_row(row)
        key = (row["lane"], int(row["m"]))
        observed_distribution[key] = observed_distribution.get(key, 0) + 1
        max_m = int(row["m"]) if max_m is None else max(max_m, int(row["m"]))

    claimed_distribution = {
        (row["lane"], int(row["m"])): int(row["captures"])
        for row in summary["first_success_distribution"]
    }
    assert observed_distribution == claimed_distribution
    assert summary["max_first_success_m"] == max_m

    verdict = {
        "hard_prime_population_checked": len(expected_primes),
        "certificates_checked": len(rows),
        "distinct_first_success_buckets": len(observed_distribution),
        "max_first_success_m": max_m,
        "verdict": "VERIFIED",
        "scope": "finite certificate replay only; not a universal Erdos-Straus proof",
    }

    path = args.out / "independent-verification.json"
    path.write_text(json.dumps(verdict, indent=2, sort_keys=True) + "\n")
    print(json.dumps(verdict, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
