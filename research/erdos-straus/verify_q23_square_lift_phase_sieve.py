#!/usr/bin/env python3
"""Independent arithmetic and earliest-anchor verification for the q23 square-lift phase sieve."""
from __future__ import annotations

import argparse
import json
import math

Q = 23
Q2 = 529
FOUR_Q2 = 2116
H = 169

ROUTES = (
    {
        "name": "q17-q23",
        "source_q": 17,
        "source_residue": 15,
        "seed19": 17 * 23,
        "anchor_p": 3_051_374_929,
        "anchor_n": 8,
        "anchor_k": 755,
        "anchor_s": 1910,
        "anchor_type_i": False,
        "anchor_type_ii": True,
        "expected_candidates_through_anchor": 38,
    },
    {
        "name": "q23-q47",
        "source_q": 47,
        "source_residue": 28,
        "seed19": 23 * 47,
        "anchor_p": 13_874_535_529,
        "anchor_n": 3,
        "anchor_k": 295,
        "anchor_s": 22_227,
        "anchor_type_i": True,
        "anchor_type_ii": True,
        "expected_candidates_through_anchor": 60,
    },
)


def k_of(n: int) -> int:
    return 19 + 92 * n


def canonical_p(n: int, s: int) -> int:
    k = k_of(n)
    return k * (FOUR_Q2 * s - 1) - FOUR_Q2


def allowed_phases() -> tuple[int, ...]:
    return tuple(
        n for n in range(Q)
        if (576 + Q * n) % math.gcd(k_of(n), 210) == 0
    )


def solution_period(n: int, modulus: int) -> int:
    return modulus // math.gcd(FOUR_Q2 * k_of(n), modulus)


def route_progression(n: int, source_q: int, source_residue: int) -> tuple[int, int]:
    period = math.lcm(solution_period(n, 840), solution_period(n, source_q))
    solutions = [
        s for s in range(period)
        if canonical_p(n, s) % 840 == H
        and canonical_p(n, s) % source_q == source_residue
    ]
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


def canonical_q2_root_geometry(c: int) -> dict[str, object]:
    """Root geometry of d=q^2 at a genuine q^2|C lift.

    d=q^2 gives s=1,b=q,c=C/q.  Since q^2|C, b divides c, so every
    successful canonical q^2 Type-II certificate is on the Lopez-A boundary.
    """
    assert c % Q2 == 0
    b = Q
    c_root = c // Q
    assert c_root % b == 0
    assert b * c_root == c
    return {
        "s": 1,
        "b": b,
        "c": c_root,
        "relation": "b-divides-c",
        "lopez_boundary": "A",
        "incomparable": False,
    }


def candidate_values(route: dict[str, object], limit: int):
    for n in allowed_phases():
        s0, period = route_progression(n, int(route["source_q"]), int(route["source_residue"]))
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

    simultaneous = []
    prime_candidates = 0
    for p, n, k, s in candidates:
        if not is_prime(p):
            continue
        prime_candidates += 1
        assert p % 840 == H
        assert p % 23 == 4
        assert p % int(route["source_q"]) == int(route["source_residue"])

        miss19, _i19, _ii19, _f19 = fixed_shift_status(p, 19, primes)
        miss23, _i23, _ii23, _f23 = fixed_shift_status(p, 23, primes)
        if not (miss19 and miss23):
            continue

        # Every generated p is a canonical q23^2 Type-II event at k.
        c = (p + k) // 4
        assert c % Q2 == 0
        quotient = c // Q2
        assert quotient % k == k - 1
        geometry = canonical_q2_root_geometry(c)
        assert geometry["relation"] == "b-divides-c"
        assert geometry["lopez_boundary"] == "A"
        assert geometry["incomparable"] is False
        missk, type_i, type_ii, factors = fixed_shift_status(p, k, primes)
        assert not missk
        assert type_ii
        simultaneous.append((p, n, k, s, type_i, type_ii, factors, quotient))

    assert simultaneous
    first = min(simultaneous, key=lambda row: row[0])
    assert first[0] == anchor
    assert first[1] == int(route["anchor_n"])
    assert first[2] == int(route["anchor_k"])
    assert first[3] == int(route["anchor_s"])
    assert first[4] == bool(route["anchor_type_i"])
    assert first[5] == bool(route["anchor_type_ii"])

    p, n, k, s, type_i, type_ii, factors, quotient = first
    c19 = (p + 19) // 4
    c23 = (p + 23) // 4
    f19 = factor(c19, primes)
    f23 = factor(c23, primes)
    lift_c = (p + k) // 4
    geometry = canonical_q2_root_geometry(lift_c)
    return {
        "name": route["name"],
        "canonical_candidates_through_anchor": len(candidates),
        "prime_candidates_through_anchor": prime_candidates,
        "simultaneous_k19_k23_survivors_through_anchor": len(simultaneous),
        "earliest_anchor": {
            "p": p,
            "phase_n": n,
            "destination_k": k,
            "s": s,
            "C19": c19,
            "C19_factorization": f19,
            "C23": c23,
            "C23_factorization": f23,
            "lift_companion": lift_c,
            "lift_factorization": factors,
            "lift_quotient_Q": quotient,
            "Q_mod_k": quotient % k,
            "type_i": type_i,
            "type_ii": type_ii,
            "canonical_type_ii_root_geometry": geometry,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert allowed_phases() == (0, 3, 5, 6, 8, 11, 12, 14, 15, 17, 18, 20, 21)
    max_anchor = max(int(route["anchor_p"]) for route in ROUTES)
    primes = sieve(math.isqrt((max_anchor + 1951) // 4) + 1)

    report = {
        "analysis": "q23-square-lift-phase-sieve-independent-v1",
        "allowed_phases": list(allowed_phases()),
        "routes": [verify_route(route, primes) for route in ROUTES],
        "failures": 0,
        "claim": (
            "independently reconstructs the phase condition and route progressions, exhaustively "
            "checks every canonical candidate below the named anchors, and verifies that every "
            "successful canonical d=23^2 Type-II event is a b|c Lopez-A boundary certificate"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
