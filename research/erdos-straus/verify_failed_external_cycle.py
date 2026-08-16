#!/usr/bin/env python3
"""Exact regression for EXTERNAL-NR-FAILED-CYCLE-COUNTEREXAMPLE.md.

The fixture p=118801 has the directed external-NR cycle

    113 -> 37 -> 929 -> 113

and every associated binary/two-target shift fails. The same prime is solved
at k=59. This script independently reconstructs all of those claims using
integer factorization and exact finite residue sets.
"""
from __future__ import annotations

P = 118_801
CYCLE = (113, 37, 929)
NEXT = {113: 37, 37: 929, 929: 113}
EXPECTED = {
    113: (339, 29_785, {5: 1, 7: 1, 23: 1, 37: 1}, 75, 178),
    37: (111, 29_728, {2: 5, 929: 1}, 26, 62),
    929: (2787, 30_397, {113: 1, 269: 1}, 9, 27),
}


def factor(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    q = 2
    while q * q <= x:
        if x % q:
            q = 3 if q == 2 else q + 2
            continue
        e = 0
        while x % q == 0:
            x //= q
            e += 1
        out[q] = e
        q = 3 if q == 2 else q + 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def legendre(a: int, p: int) -> int:
    a %= p
    if a == 0:
        return 0
    v = pow(a, (p - 1) // 2, p)
    return -1 if v == p - 1 else v


def divisor_box_square(fac: dict[int, int], mod: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        vals = {pow(q, f, mod) for f in range(2 * e + 1)}
        reach = {(x * y) % mod for x in reach for y in vals}
    return reach


def signed_box(fac: dict[int, int], mod: int) -> set[int]:
    reach = {1}
    for q, e in fac.items():
        inv = pow(q, -1, mod)
        vals = {1}
        qp = 1
        qi = 1
        for _ in range(1, e + 1):
            qp = qp * q % mod
            qi = qi * inv % mod
            vals.add(qp)
            vals.add(qi)
        reach = {(x * y) % mod for x in reach for y in vals}
    return reach


def check_cycle() -> None:
    assert P % 840 == 361
    assert factor(P) == {P: 1}

    for q in CYCLE:
        assert legendre(q, P) == -1
        R = q if q % 4 == 3 else 3 * q
        C = (P + R) // 4
        exp_R, exp_C, exp_fac, exp_dsize, exp_ssize = EXPECTED[q]
        assert R == exp_R
        assert C == exp_C
        fac = factor(C)
        assert fac == exp_fac

        nxt = NEXT[q]
        assert fac.get(nxt, 0) == 1
        assert legendre(nxt, P) == -1
        for r in fac:
            if r != nxt:
                assert legendre(r, P) == 1

        D = divisor_box_square(fac, R)
        tau_i = (-pow(4, -1, R)) % R
        tau_ii = (-C) % R
        assert len(D) == exp_dsize
        assert tau_i not in D
        assert tau_ii not in D

        fac_n = dict(fac)
        fac_n[P] = 1
        S = signed_box(fac_n, R)
        assert len(S) == exp_ssize
        assert (R - 1) not in S


def check_escape() -> None:
    k = 59
    C = (P + k) // 4
    assert C == 29_715
    fac = factor(C)
    assert fac == {3: 1, 5: 1, 7: 1, 283: 1}
    D = divisor_box_square(fac, k)
    tau_i = (-pow(4, -1, k)) % k
    tau_ii = (-C) % k
    assert tau_i == 44
    assert tau_ii == 21
    assert tau_i in D
    assert tau_ii in D
    assert (C * C) % 21 == 0
    assert 21 % k == tau_ii
    assert (C * C) % 21_225 == 0
    assert 21_225 % k == tau_i


def main() -> int:
    check_cycle()
    check_escape()
    print("OK failed external-NR cycle: 113 -> 37 -> 929 -> 113")
    print("OK all three exact two-target and binary collisions fail")
    print("OK escape shift k=59 hits both exact targets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
