#!/usr/bin/env python3
"""Independent arithmetic verification for the realized k19/k23 survivor coupling."""
from __future__ import annotations

import argparse
import json
import math
from collections import deque

ANCHORS = (
    {
        "name": "q17-q23-full",
        "p": 3_780_169,
        "seed": 17 * 23,
        "mode": "FULL_QR",
        "required": ((17, 15), (23, 4)),
    },
    {
        "name": "q17-q23-bare",
        "p": 33_996_649,
        "seed": 17 * 23,
        "mode": "BARE",
        "required": ((17, 15), (23, 4)),
    },
    {
        "name": "q23-q47-full",
        "p": 592_369,
        "seed": 23 * 47,
        "mode": "FULL_QR",
        "required": ((23, 4), (47, 28)),
    },
    {
        "name": "q23-q47-bare",
        "p": 118_637_569,
        "seed": 23 * 47,
        "mode": "BARE",
        "required": ((23, 4), (47, 28)),
    },
)


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


def factor(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    q = 2
    while q * q <= x:
        while x % q == 0:
            out[q] = out.get(q, 0) + 1
            x //= q
        q += 1 if q == 2 else 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisor_square_residues(factors: dict[int, int], k: int) -> frozenset[int]:
    residues = {1}
    for q, exponent in factors.items():
        powers = [pow(q, j, k) for j in range(2 * exponent + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return frozenset(residues)


def qrs(k: int) -> frozenset[int]:
    return frozenset(x * x % k for x in range(1, k))


def fixed_shift_miss(c: int, k: int, mask: frozenset[int]) -> bool:
    type_i = (-pow(4, -1, k)) % k
    return type_i not in mask and (-c) % k not in mask


def verify_anchor(anchor: dict[str, object]) -> dict[str, object]:
    p = int(anchor["p"])
    seed = int(anchor["seed"])
    assert is_prime(p)
    assert p % 840 == 169
    for q, residue in anchor["required"]:
        assert p % q == residue

    c19 = (p + 19) // 4
    c23 = (p + 23) // 4
    assert c23 - c19 == 1
    assert c19 % seed == 0
    assert c23 % 6 == 0
    r = c19 // seed
    b = c23 // 6
    assert 6 * b - seed * r == 1
    assert math.gcd(b, r) == 1

    f19 = factor(c19)
    f23 = factor(c23)
    fr = factor(r)
    fb = factor(b)
    mask19 = divisor_square_residues(f19, 19)
    mask23 = divisor_square_residues(f23, 23)
    assert fixed_shift_miss(c19, 19, mask19)
    assert fixed_shift_miss(c23, 23, mask23)
    assert mask23 == qrs(23)
    assert all(q % 23 in qrs(23) for q in fb)

    if anchor["mode"] == "FULL_QR":
        assert mask19 == qrs(19)
        assert all(q % 19 in qrs(19) for q in fr)
    else:
        assert mask19 != qrs(19)
        assert len(mask19) == 7
        assert all(q % 19 == 1 for q in fr)
        assert p % 19 in (6, 11)

    return {
        "name": anchor["name"],
        "p": p,
        "mode": anchor["mode"],
        "C19": c19,
        "C19_factorization": f19,
        "R": r,
        "R_factorization": fr,
        "C23": c23,
        "C23_factorization": f23,
        "B": b,
        "B_factorization": fb,
        "gcd_B_R": math.gcd(b, r),
        "k19_mask_size": len(mask19),
        "k23_mask_size": len(mask23),
    }


def explicit_k23_center4() -> dict[str, object]:
    k = 23

    def transition(
        state: tuple[frozenset[int], int], a: int
    ) -> tuple[frozenset[int], int]:
        mask, center = state
        local = (1, a % k, a * a % k)
        return (
            frozenset(u * v % k for u in mask for v in local),
            center * a % k,
        )

    start = (frozenset({1}), 1)
    start = transition(start, 2)
    start = transition(start, 3)
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for a in range(1, k):
            child = transition(state, a)
            if child not in seen:
                seen.add(child)
                queue.append(child)

    type_i = (-pow(4, -1, k)) % k
    misses = [
        state for state in seen
        if type_i not in state[0] and (-state[1]) % k not in state[0]
    ]
    center4 = [state for state in misses if 4 * state[1] % k == 4]
    assert len(seen) == 49
    assert len(misses) == 15
    assert len(center4) == 1
    assert center4[0][0] == qrs(k)
    return {
        "state_count": len(seen),
        "miss_count": len(misses),
        "center4_miss_count": len(center4),
        "center4_mask_size": len(center4[0][0]),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = {
        "analysis": "k19-k23-realized-survivor-coupling-independent-v1",
        "k23_center4_exact_state": explicit_k23_center4(),
        "anchors": [verify_anchor(anchor) for anchor in ANCHORS],
        "failures": 0,
        "claim": (
            "independently verifies the consecutive-companion residual identities, coprimality, "
            "k23 center4 QR rigidity, and both FULL_QR/BARE realized examples on each route"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
