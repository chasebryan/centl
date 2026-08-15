#!/usr/bin/env python3
"""Independent verifier for fab_dyadic_divisor_probe.py outputs.

The verifier independently reconstructs the Mordell-hard prime population,
checks that captured and unresolved primes partition it, validates the adaptive
constraint t | (p-1)/2 and d=4t-1, and checks every supplied fab certificate and
Egyptian-fraction identity using direct integer arithmetic.

It does not prove that an unresolved prime has no hit beyond --max-t; that is
exactly why the probe is a finite falsification instrument rather than a proof.
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


def verify_row(row: dict, max_t: int) -> None:
    p = int(row["p"])
    lane = row["lane"]
    t = int(row["t"])
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
    assert 1 <= t <= max_t
    assert ((p - 1) // 2) % t == 0
    assert row["adaptive_dividend"] == (p - 1) // 2
    assert m == 4 * t - 1
    assert m % 4 == 3

    if lane == "forward":
        assert k == m
        assert n == (p + m) // 4
    elif lane == "reciprocal":
        assert d == m
        assert n == (p * m + 1) // 4
    else:
        raise AssertionError(f"unknown lane: {lane}")

    assert min(a, b, c, k, d, q, D) > 0
    assert D == b * b * c
    assert (n * n) % D == 0
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
    max_t = int(summary["max_t"])
    expected = prime_sieve(limit)
    expected_set = set(expected)

    captured = [int(row["p"]) for row in rows]
    captured_set = set(captured)
    unresolved = [int(p) for p in summary["unresolved"]]
    unresolved_set = set(unresolved)

    assert len(captured) == len(captured_set), "duplicate captured prime"
    assert len(unresolved) == len(unresolved_set), "duplicate unresolved prime"
    assert captured_set.isdisjoint(unresolved_set)
    assert captured_set | unresolved_set == expected_set

    assert summary["hard_prime_count"] == len(expected)
    assert summary["captured_count"] == len(rows)
    assert summary["unresolved_count"] == len(unresolved)

    distribution: dict[tuple[str, int], int] = {}
    max_first_t = None

    for row in rows:
        verify_row(row, max_t)
        key = (row["lane"], int(row["t"]))
        distribution[key] = distribution.get(key, 0) + 1
        max_first_t = int(row["t"]) if max_first_t is None else max(max_first_t, int(row["t"]))

    claimed = {
        (row["lane"], int(row["t"])): int(row["captures"])
        for row in summary["first_success_distribution"]
    }
    assert distribution == claimed
    assert summary["max_first_success_t"] == max_first_t
    assert summary["max_first_success_d"] == ((4 * max_first_t - 1) if max_first_t is not None else None)

    verdict = {
        "hard_prime_population_checked": len(expected),
        "certificates_checked": len(rows),
        "unresolved_population_checked": len(unresolved),
        "max_first_success_t": max_first_t,
        "max_first_success_d": (4 * max_first_t - 1) if max_first_t is not None else None,
        "verdict": "VERIFIED",
        "scope": "finite adaptive-divisor certificate replay only; not a universal Erdos-Straus proof",
    }

    (args.out / "independent-verification.json").write_text(json.dumps(verdict, indent=2, sort_keys=True) + "\n")
    print(json.dumps(verdict, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
