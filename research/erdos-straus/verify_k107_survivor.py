#!/usr/bin/env python3
"""Exact finite certificate for the corrected 100M corridor survivor."""
from __future__ import annotations

import json
import math
from fractions import Fraction

P = 8_803_369
K = 107
SHIFTS = tuple(range(3, 108, 4))


def factor_with_exp(n: int) -> list[tuple[int, int]]:
    out = []
    q = 2
    while q * q <= n:
        if n % q == 0:
            e = 0
            while n % q == 0:
                n //= q
                e += 1
            out.append((q, e))
        q = 3 if q == 2 else q + 2
    if n > 1:
        out.append((n, 1))
    return out


def signed_box_hit(p: int, k: int) -> bool:
    C = (p + k) // 4
    if 4 * C != p + k:
        return False
    if math.gcd(C, k) != 1:
        raise SystemExit(f"non-unit fixed-shift state: p={p}, k={k}, C={C}")
    reach = {1 % k}
    for q, e in factor_with_exp(C):
        r = q % k
        inv = pow(r, -1, k)
        packet = {1}
        x = 1
        for _ in range(e):
            x = (x * r) % k
            packet.add(x)
        x = 1
        for _ in range(e):
            x = (x * inv) % k
            packet.add(x)
        reach = {(a * b) % k for a in reach for b in packet}
    return bool(reach & {(-1) % k, (-pow(p, -1, k)) % k})


def analyze() -> dict[str, object]:
    outcomes = {k: signed_box_hit(P, k) for k in SHIFTS}
    hits = [k for k in SHIFTS if outcomes[k]]
    first_hit = hits[0] if hits else None

    C = (P + K) // 4
    fac = factor_with_exp(C)
    expected_fac = [(3, 2), (11, 2), (43, 1), (47, 1)]
    if fac != expected_fac:
        raise SystemExit(f"k=107 factorization changed: {fac!r}")

    B = 3**2 * 43 * 47
    D = 1
    T = 11**2
    if B * D * T != C:
        raise SystemExit("B*D*T does not equal C107")
    if B % K != K - 1:
        raise SystemExit("Type-II ratio is no longer -1 mod 107")
    if (B + D) % K:
        raise SystemExit("k=107 no longer divides B+D")
    A = (B + D) // K

    x = B * D * T
    y = P * A * D * T
    z = P * A * B * T
    if Fraction(1, x) + Fraction(1, y) + Fraction(1, z) != Fraction(4, P):
        raise SystemExit("reconstructed Type-II unit-fraction identity failed")

    return {
        "analysis": "k107-corrected-100m-survivor-v1",
        "p": P,
        "configured_shifts": list(SHIFTS),
        "hit_shifts": hits,
        "first_hit": first_hit,
        "misses_before_107": all(not outcomes[k] for k in SHIFTS if k < K),
        "C107": C,
        "C107_factorization": [[q, e] for q, e in fac],
        "type": "II",
        "B": B,
        "D": D,
        "T": T,
        "A": A,
        "B_mod_107": B % K,
        "denominators": [x, y, z],
        "claim": "exact certificate for one finite 100M-corridor prime; not a universal shift bound",
    }


def main() -> int:
    report = analyze()
    if report["first_hit"] != 107 or not report["misses_before_107"]:
        raise SystemExit("corrected survivor first-hit regression failed")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
