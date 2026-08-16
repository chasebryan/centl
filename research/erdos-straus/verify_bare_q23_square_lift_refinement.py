#!/usr/bin/env python3
"""Independent arithmetic verification for the BARE q23 square-lift refinement."""
from __future__ import annotations

import argparse
import json
import math

Q = 23
Q2 = 529
FOUR_Q2 = 2116
H = 169
BARE_PHASES = (3, 5, 6, 8, 11, 12, 14, 15, 17, 18, 20, 21)

ROUTES = (
    {
        "name": "q17-q23",
        "source_q": 17,
        "source_residue": 15,
        "bare_p_mod19": 6,
        "seed19": 17 * 23,
        "anchor_p": 159_799_693_369,
        "anchor_n": 3,
        "anchor_s": 255_999,
        "anchor_type_i": True,
        "anchor_type_ii": True,
        "expected_candidates_through_anchor": 40,
        "expected_prime_candidates": 8,
        "expected_bare_candidates": 2,
        "expected_simultaneous_bare_candidates": 1,
        "earlier_bare_nonpersistent_p": 81_757_751_209,
    },
    {
        "name": "q23-q47",
        "source_q": 47,
        "source_residue": 28,
        "bare_p_mod19": 11,
        "seed19": 23 * 47,
        "anchor_p": 182_687_343_889,
        "anchor_n": 3,
        "anchor_s": 292_665,
        "anchor_type_i": False,
        "anchor_type_ii": True,
        "expected_candidates_through_anchor": 18,
        "expected_prime_candidates": 3,
        "expected_bare_candidates": 1,
        "expected_simultaneous_bare_candidates": 1,
        "earlier_bare_nonpersistent_p": None,
    },
)


def k_of(n: int) -> int:
    return 19 + 92 * n


def canonical_p(n: int, s: int) -> int:
    k = k_of(n)
    return k * (FOUR_Q2 * s - 1) - FOUR_Q2


def solution_period(n: int, modulus: int) -> int:
    return modulus // math.gcd(FOUR_Q2 * k_of(n), modulus)


def progression(route: dict[str, object], n: int) -> tuple[int, int] | None:
    period = math.lcm(
        solution_period(n, 840),
        solution_period(n, int(route["source_q"])),
        solution_period(n, 19),
    )
    solutions = [
        s for s in range(period)
        if canonical_p(n, s) % 840 == H
        and canonical_p(n, s) % int(route["source_q"]) == int(route["source_residue"])
        and canonical_p(n, s) % 19 == int(route["bare_p_mod19"])
    ]
    if not solutions:
        return None
    assert len(solutions) == 1
    return solutions[0], period


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    small = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for q in small:
        if n % q == 0:
            return n == q
    d = n - 1
    s = 0
    while d % 2 == 0:
        s += 1
        d //= 2
    for a in (2, 325, 9375, 28178, 450775, 9780504, 1795265022):
        if a % n == 0:
            continue
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = x * x % n
            if x == n - 1:
                break
        else:
            return False
    return True


def sieve(limit: int) -> list[int]:
    prime = bytearray(b"\x01") * (limit + 1)
    prime[0:2] = b"\x00\x00"
    for q in range(2, math.isqrt(limit) + 1):
        if prime[q]:
            start = q * q
            prime[start : limit + 1 : q] = b"\x00" * (((limit - start) // q) + 1)
    return [q for q in range(2, limit + 1) if prime[q]]


def factor(n: int, primes: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in primes:
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


def divisor_square_residues(factors: dict[int, int], k: int) -> frozenset[int]:
    residues = {1}
    for q, exponent in factors.items():
        powers = [pow(q, j, k) for j in range(2 * exponent + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return frozenset(residues)


def fixed_shift_status(p: int, k: int, primes: list[int]) -> tuple[bool, bool, bool, dict[int, int]]:
    c = (p + k) // 4
    factors = factor(c, primes)
    mask = divisor_square_residues(factors, k)
    type_i_target = (-pow(4, -1, k)) % k
    type_ii_target = (-c) % k
    type_i = type_i_target in mask
    type_ii = type_ii_target in mask
    return (not type_i and not type_ii), type_i, type_ii, factors


def candidate_values(route: dict[str, object], limit: int):
    for n in BARE_PHASES:
        row = progression(route, n)
        assert row is not None
        s0, period = row
        s = s0 if s0 > 0 else period
        while True:
            p = canonical_p(n, s)
            if p > limit:
                break
            if p > 0:
                yield p, n, k_of(n), s
            s += period


def verify_route(route: dict[str, object], primes: list[int]) -> dict[str, object]:
    anchor = int(route["anchor_p"])
    candidates = sorted(candidate_values(route, anchor))
    assert len(candidates) == int(route["expected_candidates_through_anchor"])

    prime_candidates = []
    bare_candidates = []
    simultaneous_bare = []

    for p, n, k, s in candidates:
        if not is_prime(p):
            continue
        prime_candidates.append((p, n, k, s))

        c19 = (p + 19) // 4
        seed = int(route["seed19"])
        assert c19 % seed == 0
        r = c19 // seed
        fr = factor(r, primes)
        bare_support = all(q % 19 == 1 for q in fr)
        if not bare_support:
            continue

        miss19, _i19, _ii19, f19 = fixed_shift_status(p, 19, primes)
        assert miss19
        assert len(divisor_square_residues(f19, 19)) == 7
        bare_candidates.append((p, n, k, s, r, fr))

        miss23, i23, ii23, f23 = fixed_shift_status(p, 23, primes)
        if not miss23:
            continue

        c = (p + k) // 4
        assert c % Q2 == 0
        quotient = c // Q2
        assert quotient % k == k - 1
        missk, type_i, type_ii, fk = fixed_shift_status(p, k, primes)
        assert not missk
        assert type_ii
        simultaneous_bare.append(
            (p, n, k, s, r, fr, f19, f23, fk, quotient, type_i, type_ii)
        )

    assert len(prime_candidates) == int(route["expected_prime_candidates"])
    assert len(bare_candidates) == int(route["expected_bare_candidates"])
    assert len(simultaneous_bare) == int(route["expected_simultaneous_bare_candidates"])

    first = min(simultaneous_bare, key=lambda row: row[0])
    assert first[0] == anchor
    assert first[1] == int(route["anchor_n"])
    assert first[3] == int(route["anchor_s"])
    assert first[10] == bool(route["anchor_type_i"])
    assert first[11] == bool(route["anchor_type_ii"])

    earlier = route["earlier_bare_nonpersistent_p"]
    earlier_control = None
    if earlier is not None:
        matches = [row for row in bare_candidates if row[0] == int(earlier)]
        assert len(matches) == 1
        p0, n0, k0, s0, r0, fr0 = matches[0]
        miss23, i23, ii23, f23 = fixed_shift_status(p0, 23, primes)
        assert not miss23
        earlier_control = {
            "p": p0,
            "phase_n": n0,
            "destination_k": k0,
            "s": s0,
            "R": r0,
            "R_factorization": fr0,
            "k23_type_i": i23,
            "k23_type_ii": ii23,
            "k23_factorization": f23,
            "reason_excluded_from_persistent_state": "k23 already hits",
        }

    p, n, k, s, r, fr, f19, f23, fk, quotient, type_i, type_ii = first
    return {
        "name": route["name"],
        "canonical_center_candidates_through_anchor": len(candidates),
        "prime_candidates_through_anchor": len(prime_candidates),
        "actual_bare_candidates_through_anchor": len(bare_candidates),
        "simultaneous_k19_k23_bare_candidates_through_anchor": len(simultaneous_bare),
        "earlier_bare_nonpersistent_control": earlier_control,
        "earliest_persistent_bare_anchor": {
            "p": p,
            "phase_n": n,
            "destination_k": k,
            "s": s,
            "R": r,
            "R_factorization": fr,
            "C19": (p + 19) // 4,
            "C19_factorization": f19,
            "C23": (p + 23) // 4,
            "C23_factorization": f23,
            "lift_companion": (p + k) // 4,
            "lift_factorization": fk,
            "lift_quotient_Q": quotient,
            "Q_mod_k": quotient % k,
            "type_i": type_i,
            "type_ii": type_ii,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    # n=0 is incompatible with the BARE centers on both routes.
    for route in ROUTES:
        assert progression(route, 0) is None
        assert tuple(n for n in (0,) + BARE_PHASES if progression(route, n) is not None) == BARE_PHASES

    max_anchor = max(int(route["anchor_p"]) for route in ROUTES)
    primes = sieve(math.isqrt((max_anchor + 1951) // 4) + 1)

    report = {
        "analysis": "bare-q23-square-lift-refinement-independent-v1",
        "bare_canonical_phases": list(BARE_PHASES),
        "routes": [verify_route(route, primes) for route in ROUTES],
        "failures": 0,
        "claim": (
            "independently reconstructs the BARE-center phase refinement and exhausts every "
            "canonical center-compatible candidate below the named anchors, separating actual "
            "BARE support from mere center compatibility and preserving the prior k23 survivor condition"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
