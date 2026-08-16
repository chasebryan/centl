#!/usr/bin/env python3
"""Regression verification for the universal signed-box trivial-divisor shell."""
from __future__ import annotations

import argparse
import json
import math


def direct(k: int, C: int, d: int) -> tuple[bool, bool]:
    assert C > 0 and d > 0 and (C * C) % d == 0
    return (4 * d + 1) % k == 0, (d + C) % k == 0


def selector_conditions(k: int, C: int) -> dict[str, tuple[bool, bool]]:
    return {
        "d=1": ((4 + 1) % k == 0, (1 + C) % k == 0),
        "d=C": ((4 * C + 1) % k == 0, (2 * C) % k == 0),
        "d=C2": ((4 * C * C + 1) % k == 0, (C * C + C) % k == 0),
    }


def verify_shell() -> dict[str, object]:
    checked = 0
    for k in range(3, 200, 2):
        for residue in range(k):
            C = residue + k  # positive representative with the desired residue
            expected = selector_conditions(k, C)
            actual = {
                "d=1": direct(k, C, 1),
                "d=C": direct(k, C, C),
                "d=C2": direct(k, C, C * C),
            }
            assert actual == expected
            assert expected["d=C"][1] == (C % k == 0)
            checked += 1
    return {"odd_moduli_checked": 99, "center_residues_checked": checked}


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    for d in range(2, math.isqrt(n) + 1):
        if n % d == 0:
            return False
    return True


def verify_prime_3mod4_shell() -> dict[str, object]:
    primes = [k for k in range(7, 200, 4) if is_prime(k)]
    for k in primes:
        inv4 = pow(4, -1, k)
        type_i_center = (-inv4) % k
        centers = set()
        for C in range(k):
            conditions = selector_conditions(k, C)
            if any(any(pair) for pair in conditions.values()):
                centers.add(C)
            assert not conditions["d=C2"][0]
        assert centers == {0, k - 1, type_i_center}
    return {"primes_checked": primes}


def verify_k43() -> dict[str, object]:
    k = 43
    inv4 = pow(4, -1, k)
    target_i = (-inv4) % k
    assert target_i == 32
    phases: dict[int, tuple[int, str, str]] = {}
    for t in range(43):
        C = 53 + 210 * t
        c = C % 43
        if c == 0:
            phases[t] = (c, "Type II", "d=C")
            assert direct(43, C, C)[1]
        elif c == 42:
            phases[t] = (c, "Type II", "d=1")
            assert direct(43, C, 1)[1]
        elif c == target_i:
            phases[t] = (c, "Type I", "d=C")
            assert direct(43, C, C)[0]
    assert phases == {
        2: (0, "Type II", "d=C"),
        28: (42, "Type II", "d=1"),
        30: (32, "Type I", "d=C"),
    }
    return {"absorbed_t_phases": sorted(phases), "details": phases}


def squarefree_kernel(n: int) -> int:
    kernel = 1
    p = 2
    while p * p <= n:
        parity = 0
        while n % p == 0:
            n //= p
            parity ^= 1
        if parity:
            kernel *= p
        p += 1
    if n > 1:
        kernel *= n
    return kernel


def verify_typeii_roots() -> dict[str, object]:
    checked = 0
    for C in range(1, 500):
        s = squarefree_kernel(C)
        u2 = C // s
        u = math.isqrt(u2)
        assert u * u == u2

        # d=1 -> (1,1,C)
        assert 1 == 1 * 1 * 1
        assert C == 1 * 1 * C

        # d=C -> (s,u,u)
        assert C == s * u * u

        # d=C^2 -> (1,C,1)
        assert C == 1 * C * 1
        checked += 1
    return {"C_values_checked": checked}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "signed-box-trivial-divisor-selector-shell-v1",
        "shell": verify_shell(),
        "prime_3mod4": verify_prime_3mod4_shell(),
        "k43": verify_k43(),
        "typeii_roots": verify_typeii_roots(),
        "failures": 0,
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
