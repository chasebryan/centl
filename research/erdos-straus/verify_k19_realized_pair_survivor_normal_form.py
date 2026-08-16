#!/usr/bin/env python3
"""Independent explicit-state and finite-prime regression for the realized k19 pair normal form."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

K = 19
H = 169
QR19 = frozenset(x * x % K for x in range(1, K))
ROUTES = (
    {
        "name": "q17-q23",
        "source_primes": (17, 23),
        "required_p_mod_sources": (15, 4),
        "source_residues_mod_19": (17, 4),
        "seed": 17 * 23,
        "bare_center": 6,
        "expected_routes_10m": 14,
        "expected_misses_10m": 3,
        "first_full_qr_miss": 3_780_169,
    },
    {
        "name": "q23-q47",
        "source_primes": (23, 47),
        "required_p_mod_sources": (4, 28),
        "source_residues_mod_19": (4, 9),
        "seed": 23 * 47,
        "bare_center": 11,
        "expected_routes_10m": 4,
        "expected_misses_10m": 3,
        "first_full_qr_miss": 592_369,
    },
)


def transition(
    state: tuple[frozenset[int], int], residue: int
) -> tuple[frozenset[int], int]:
    mask, center = state
    local = (1, residue % K, residue * residue % K)
    return (
        frozenset(a * b % K for a in mask for b in local),
        center * residue % K,
    )


def closure(
    start: tuple[frozenset[int], int]
) -> frozenset[tuple[frozenset[int], int]]:
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for residue in range(1, K):
            child = transition(state, residue)
            if child not in seen:
                seen.add(child)
                queue.append(child)
    return frozenset(seen)


def is_miss(state: tuple[frozenset[int], int]) -> bool:
    mask, center = state
    type_i = (-pow(4, -1, K)) % K
    return type_i not in mask and (-center) % K not in mask


def p_center(state: tuple[frozenset[int], int]) -> int:
    return 4 * state[1] % K


def verify_exact_states() -> list[dict[str, object]]:
    rows = []
    for route in ROUTES:
        start = (frozenset({1}), 1)
        for residue in route["source_residues_mod_19"]:
            start = transition(start, residue)

        states = closure(start)
        misses = tuple(state for state in states if is_miss(state))
        full = tuple(state for state in misses if state[0] == QR19)
        partial = tuple(state for state in misses if state[0] != QR19)

        assert len(states) == 41
        assert len(misses) == 10
        assert len(full) == 9
        assert {p_center(state) for state in full} == set(QR19)
        assert partial == (start,)
        assert p_center(start) == route["bare_center"]
        assert len(start[0]) == 7

        stabilizer = tuple(
            residue for residue in range(1, K)
            if transition(start, residue) == start
        )
        mask_stabilizer = tuple(
            residue for residue in range(1, K)
            if transition(start, residue)[0] == start[0]
        )
        assert stabilizer == (1,)
        assert mask_stabilizer == (1,)

        # A direct monotonicity check: every non-1 residue strictly grows the
        # bare mask, so once an additional residual factor leaves the bare
        # state it can never return to it.
        for residue in range(2, K):
            assert len(transition(start, residue)[0]) > len(start[0])

        rows.append({
            "name": route["name"],
            "bare_center": p_center(start),
            "bare_mask": sorted(start[0]),
            "state_count": len(states),
            "miss_count": len(misses),
            "full_qr_miss_count": len(full),
            "partial_miss_count": len(partial),
            "bare_stabilizer": list(stabilizer),
        })
    return rows


def sieve(limit: int) -> bytearray:
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
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
        exponent = 0
        while x % q == 0:
            x //= q
            exponent += 1
        out[q] = exponent
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisor_square_residues(factors: dict[int, int]) -> frozenset[int]:
    residues = {1}
    for q, exponent in factors.items():
        powers = [pow(q, j, K) for j in range(2 * exponent + 1)]
        residues = {a * b % K for a in residues for b in powers}
    return frozenset(residues)


def finite_regression(limit: int) -> list[dict[str, object]]:
    prime = sieve(limit)
    trial_primes = [q for q in range(2, math.isqrt(limit) + 2) if prime[q]]
    rows = []

    for route in ROUTES:
        counts: Counter[str] = Counter()
        first_full = None
        for p in range(H, limit + 1, 840):
            if not prime[p]:
                continue
            if any(
                p % q != residue
                for q, residue in zip(
                    route["source_primes"], route["required_p_mod_sources"]
                )
            ):
                continue

            counts["route_primes"] += 1
            c = (p + K) // 4
            assert c % route["seed"] == 0
            factors = factor(c, trial_primes)
            mask = divisor_square_residues(factors)
            type_i = (-pow(4, -1, K)) % K
            miss = type_i not in mask and (-c) % K not in mask
            if not miss:
                continue

            counts["misses"] += 1
            residual = c // int(route["seed"])
            residual_factors = factor(residual, trial_primes)
            bare_support = all(q % K == 1 for q in residual_factors)

            if bare_support:
                counts["bare_misses"] += 1
                # The exact theorem predicts the unique bare center.
                assert p % K == route["bare_center"]
            elif mask == QR19:
                counts["full_qr_misses"] += 1
                if first_full is None:
                    first_full = p
            else:
                counts["forbidden_intermediate_misses"] += 1

        if limit == 10_000_000:
            assert counts["route_primes"] == route["expected_routes_10m"]
            assert counts["misses"] == route["expected_misses_10m"]
            assert counts["full_qr_misses"] == route["expected_misses_10m"]
            assert counts["bare_misses"] == 0
            assert counts["forbidden_intermediate_misses"] == 0
            assert first_full == route["first_full_qr_miss"]

        rows.append({
            "name": route["name"],
            "route_primes": counts["route_primes"],
            "misses": counts["misses"],
            "bare_misses": counts["bare_misses"],
            "full_qr_misses": counts["full_qr_misses"],
            "forbidden_intermediate_misses": counts["forbidden_intermediate_misses"],
            "first_full_qr_miss": first_full,
        })

    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=10_000_000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "k19-realized-pair-survivor-normal-form-independent-v1",
        "exact_state_checks": verify_exact_states(),
        "finite_prime_regression": finite_regression(args.limit),
        "limit": args.limit,
        "failures": 0,
        "claim": (
            "independently verifies the two-mode exact-state normal form and checks actual "
            "h169 route primes through the requested bound for forbidden intermediate misses"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
