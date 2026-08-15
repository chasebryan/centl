#!/usr/bin/env python3
"""Independent finite checks for the 2026-08-15 two-target companion theorems.

Standard-library only. These are regression checks of proved identities and
classifications on a finite hard-prime range. They do not prove Erdős–Straus.
"""
from __future__ import annotations

import math
import sys


HARD = (1, 121, 169, 289, 361, 529)
QR7 = {1, 2, 4}
H15 = {1, 2, 4, 8}


def sieve(n: int) -> list[int]:
    bs = bytearray(b"\x01") * (n + 1)
    bs[:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return [i for i, v in enumerate(bs) if v]


def factor(n: int, trial: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial:
        if q * q > x:
            break
        if x % q == 0:
            e = 0
            while x % q == 0:
                x //= q
                e += 1
            out[q] = e
        if x == 1:
            return out
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def divisors_from(fac: dict[int, int]) -> list[int]:
    divs = [1]
    for q, e in fac.items():
        divs = [d * q**i for d in divs for i in range(e + 1)]
    return divs


def box(fac: dict[int, int], mod: int) -> set[int]:
    reach = {1}
    for r, e in fac.items():
        if math.gcd(r, mod) != 1:
            return set()
        pw = [pow(r, z, mod) for z in range(-e, e + 1)]
        reach = {(x * y) % mod for x in reach for y in pw}
    return reach


def check_two_p_plus_one(hard: list[int], trial: list[int]) -> None:
    checked = 0
    for p in hard:
        n = 2 * p + 1
        fac = factor(n, trial)
        for k in divisors_from(fac):
            if k % 8 != 7:
                continue
            t = (p + k) // 8
            q, rem = divmod(n, k)
            if rem:
                raise SystemExit(f"2p+1 divisor failure p={p} k={k}")
            # 4/p = 1/(2t) + 1/(q t) + 1/(2 p q t)
            left = 4 * 2 * t * q * t * 2 * p * q * t
            # clearer: compare 4 * (2t) * (q t) * (2 p q t) == p * sum of other triples
            x, y, z = 2 * t, q * t, 2 * p * q * t
            if 4 * x * y * z != p * (y * z + x * z + x * y):
                raise SystemExit(f"identity failure p={p} k={k} t={t} q={q}")
            checked += 1
            break
    if checked == 0:
        raise SystemExit("no 2p+1 certificates in range")
    print(f"OK 2p+1 identities: {checked}")


def check_q7_equivalence(hard: list[int], trial: list[int]) -> None:
    for p in hard:
        if p == 7:
            continue
        C = (p + 7) // 4
        fac = factor(C, trial)
        B = box(fac, 7)
        ii = 6 in B
        i = ((-pow(p, -1, 7)) % 7) in B
        qr_only = all(q % 7 in QR7 for q in fac)
        if ii != i:
            raise SystemExit(f"q7 Type I/II split p={p} I={i} II={ii}")
        if qr_only == ii:
            raise SystemExit(f"q7 QR mismatch p={p} qr_only={qr_only} hit={ii}")
    print(f"OK q=7 Type I/II equivalence: {len(hard)}")


def check_k15_htrap(hard: list[int], trial: list[int]) -> None:
    for p in hard:
        C = (p + 15) // 4
        fac = factor(C, trial)
        B = box(fac, 15)
        trapped = all(q % 15 in H15 for q in fac)
        if trapped and not B <= H15:
            raise SystemExit(f"H-trap box escaped p={p} box={B}")
        if trapped:
            if 14 in B or ((-pow(p, -1, 15)) % 15) in B:
                raise SystemExit(f"H-trap hit a target p={p}")
        # outside-H primes 7,13,14 must Type-II hit
        residues = {q % 15 for q in fac}
        if residues & {7, 13, 14}:
            if 14 not in B:
                raise SystemExit(f"outside-H missed Type II p={p} res={residues}")
        if 11 in residues and fac.get(2, 0) >= 2:
            if 14 not in B:
                raise SystemExit(f"11-packet v2>=2 missed Type II p={p}")
    print(f"OK k=15 H-trap / outside-H hits: {len(hard)}")


def check_hard_residues_mod15(hard: list[int]) -> None:
    bad = [p for p in hard if p % 15 not in (1, 4)]
    if bad:
        raise SystemExit(f"hard residue not 1 or 4 mod 15: {bad[:5]}")
    print("OK hard residues mod 15")


def main() -> None:
    limit = 50_000
    trial = sieve(20_000)
    hard = [p for p in sieve(limit) if p % 840 in HARD and p > 15]
    check_hard_residues_mod15(hard)
    check_two_p_plus_one(hard, trial)
    check_q7_equivalence(hard, trial)
    check_k15_htrap(hard, trial)
    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    sys.exit(main())
