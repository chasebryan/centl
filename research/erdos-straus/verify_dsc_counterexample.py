#!/usr/bin/env python3
"""Exact independent verifier for the deposited Direct-Shadow Completeness counterexample.

This verifier does not search for a witness.  It checks a fixed constructive
candidate and proves two facts exactly:

1. three earlier q=3 Type A/B rows cover every integer parameter s;
2. no single earlier Type A/B row directly shadows the candidate.

The second statement is finite despite the enormous target depth because the
Direct-shadow smoothness theorem proves that every direct-shadow modulus uses
only primes already dividing L.  The verifier enumerates every such smooth
modulus below the target modulus and checks its complete attained fibre.

This falsifies universal DSC-0 and DSC-P only.  It is not an Erdős-Straus
counterexample.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

# Constructed target.
TARGET_DIVISOR = 2_218_779_486
TARGET_COFACTOR = 1_900_986_818
K = 4_217_870_554_934_815_548
M = 16_871_482_219_739_262_191
T = 16_871_482_210_864_144_247
L = 14_172_045_064_580_980_240_440

# Two hard siblings.  Either one alone is a counterexample to DSC-0 / DSC-P.
HARD = (361, 529)

# Exact prime support of L.  2 is omitted because every Type A/B modulus is odd.
ODD_L_PRIMES = (3, 5, 7, 19, 229, 433, 487, 3823, 4_809_977)

# Three earlier rows.  (j, divisor e, trap multiplier c) means u = -c*e mod m_j.
COVER_ROWS = (
    (6820, 20, 4),
    (8602, 506, 1),
    (9790, 89, 4),
)


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    p = 3
    while p * p <= n:
        if n % p == 0:
            return False
        p += 2
    return True


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int]:
    g = math.gcd(m, n)
    if (b - a) % g:
        raise AssertionError("incompatible CRT data")
    mm, nn = m // g, n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    mod = m * nn
    return (a + m * u) % mod, mod


def trap_hit(i: int, residue: int) -> bool:
    """Exact Type A/B trap membership without factoring i.

    For m=4i-1 and y in [0,m), y is a trap iff either
      y = m-e for some e|i,
    or
      y = m-4e for some e|i.
    The e=i endpoint in the second box gives y=m-1, already caught by e=1
    in the first box.
    """
    m = 4 * i - 1
    y = residue % m
    if y == 0:
        return False
    delta = m - y
    if i % delta == 0:
        return True
    if delta % 4 == 0:
        e = delta // 4
        if e and i % e == 0:
            return True
    return False


def generate_smooth(primes: tuple[int, ...], limit: int) -> list[int]:
    """All positive integers < limit with prime support contained in primes."""
    out: list[int] = []

    def rec(index: int, value: int) -> None:
        if index == len(primes):
            out.append(value)
            return
        p = primes[index]
        x = value
        while x < limit:
            rec(index + 1, x)
            if x > (limit - 1) // p:
                break
            x *= p

    rec(0, 1)
    return out


def direct_shadow(r: int, m: int) -> bool:
    """Check the complete attained fibre for one earlier modulus m=4i-1."""
    i = (m + 1) // 4
    g = math.gcd(L, m)
    q = m // g
    for s in range(q):
        if not trap_hit(i, (r + L * s) % m):
            return False
    return True


def verify_cover(r: int) -> list[dict]:
    rows: list[dict] = []
    classes: set[int] = set()
    for j, e, c in COVER_ROWS:
        m = 4 * j - 1
        if j % e:
            raise AssertionError(f"e={e} does not divide j={j}")
        u = (-c * e) % m
        g = math.gcd(L, m)
        q = m // g
        if q != 3:
            raise AssertionError(f"row {j} has q={q}, expected 3")
        if (u - r) % g:
            raise AssertionError(f"row {j} trap is not in the candidate fibre")
        step = (L // g) % 3
        a = (((u - r) // g) * pow(step, -1, 3)) % 3
        if (r + L * a) % m != u:
            raise AssertionError(f"row {j} pullback reconstruction failed")
        if not trap_hit(j, u):
            raise AssertionError(f"row {j} stored trap is not a Type A/B trap")
        classes.add(a)
        rows.append({"j": j, "m": m, "e": e, "c": c, "u": u, "q": q, "class": a})

    if classes != {0, 1, 2}:
        raise AssertionError(f"cover rows do not cover Z/3Z: {classes}")
    return rows


def main() -> None:
    if K != TARGET_DIVISOR * TARGET_COFACTOR:
        raise AssertionError("target factorization K=d*n failed")
    if M != 4 * K - 1:
        raise AssertionError("M != 4K-1")
    if T != (-4 * TARGET_DIVISOR) % M:
        raise AssertionError("target residue is not the declared -4d trap")
    if K % TARGET_DIVISOR:
        raise AssertionError("target trap divisor does not divide K")
    if math.gcd(M, 840) != 1:
        raise AssertionError("construction expected gcd(M,840)=1")
    if L != 840 * M:
        raise AssertionError("L != lcm(840,M) in the coprime construction")

    # Verify the declared prime support rather than trusting labels.
    for p in ODD_L_PRIMES:
        if not is_prime(p):
            raise AssertionError(f"declared support element {p} is not prime")
    if math.prod((19, 229, 433, 487, 3823, 4_809_977)) != M:
        raise AssertionError("target modulus factorization mismatch")

    smooth = generate_smooth(ODD_L_PRIMES, M)
    if len(smooth) != 270_836:
        raise AssertionError(f"unexpected smooth-modulus count: {len(smooth)}")
    earlier_moduli = [m for m in smooth if m > 1 and m % 4 == 3]
    if len(earlier_moduli) != 135_402:
        raise AssertionError(f"unexpected Type A/B smooth-modulus count: {len(earlier_moduli)}")

    results: list[dict] = []
    for h in HARD:
        r, mod = crt2(h, 840, T, M)
        if mod != L:
            raise AssertionError("candidate CRT modulus mismatch")
        if r % 840 != h or r % M != T:
            raise AssertionError("candidate CRT residue mismatch")
        if math.gcd(r, L) != 1:
            raise AssertionError("candidate base is not coprime to L")

        cover = verify_cover(r)

        shadows: list[dict] = []
        checked = 0
        for m in earlier_moduli:
            i = (m + 1) // 4
            if i >= K:
                continue
            checked += 1
            if direct_shadow(r, m):
                shadows.append({"j": i, "m": m})
                break

        if shadows:
            raise AssertionError(f"hard class {h} has a direct shadow: {shadows[0]}")

        results.append(
            {
                "h": h,
                "r": r,
                "cover_rows": cover,
                "covered_parameter_classes_mod_3": sorted({row["class"] for row in cover}),
                "smooth_direct_shadow_moduli_checked": checked,
                "direct_shadows": shadows,
                "verdict": "DIRECTLY NOVEL BUT UNION-SHADOWED",
            }
        )

    report = {
        "status": "exact constructive counterexample to universal Direct-Shadow Completeness",
        "target": {
            "k": K,
            "m": M,
            "target_divisor": TARGET_DIVISOR,
            "target_cofactor": TARGET_COFACTOR,
            "t": T,
            "L": L,
        },
        "odd_L_prime_support": list(ODD_L_PRIMES),
        "smooth_numbers_below_target": len(smooth),
        "type_ab_smooth_moduli_below_target": len(earlier_moduli),
        "hard_siblings": results,
        "conclusion": {
            "DSC_0": "FALSE",
            "DSC_P": "FALSE",
            "erdos_straus": "NOT DECIDED BY THIS RESULT",
        },
    }

    out = Path("dsc-counterexample.json")
    out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
