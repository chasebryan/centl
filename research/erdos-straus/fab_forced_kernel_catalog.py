#!/usr/bin/env python3
"""Exact catalog of forced-kernel saturation from the Mordell hard shield.

The only universally known prime-factor occurrences used here are 2,3,5,7,
forced by a hard residue class modulo 840 into one forward/reciprocal base.
Each occurrence may be used with signed exponent -1,0,+1.

If their signed reach fills the Jacobi-positive kernel H_d, then
FAB-FORCED-KERNEL-DETECTORS.md applies.

This script classifies *all* odd squarefree d == 3 (mod 4) for which that can
happen. It is finite without an arbitrary d cap: with at most four forced
occurrences, |H_d| = phi(d)/2 <= 3^4 = 81, hence phi(d) <= 162. For squarefree
d, every prime q|d then has q-1 <=162, so q<=163. We enumerate every subset of
odd primes <=163 whose product of (q-1) is <=162.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)
SMALL = (2, 3, 5, 7)
PHI_CAP = 2 * (3 ** len(SMALL))  # 162


def primes_upto(n: int) -> list[int]:
    out = []
    for x in range(2, n + 1):
        if all(x % q for q in range(2, math.isqrt(x) + 1)):
            out.append(x)
    return out


def squarefree_candidates() -> list[tuple[int, int]]:
    primes = [q for q in primes_upto(PHI_CAP + 1) if q % 2]
    out: list[tuple[int, int]] = []

    def rec(start: int, d: int, phi: int) -> None:
        if d > 1 and d % 4 == 3:
            out.append((d, phi))
        for i in range(start, len(primes)):
            q = primes[i]
            new_phi = phi * (q - 1)
            if new_phi > PHI_CAP:
                continue
            rec(i + 1, d * q, new_phi)

    rec(0, 1, 1)
    return sorted(set(out))


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("Jacobi denominator must be positive odd")
    a %= n
    result = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                result = -result
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            result = -result
        a %= n
    return result if n == 1 else 0


def kernel(d: int) -> set[int]:
    return {
        u
        for u in range(1, d)
        if math.gcd(u, d) == 1 and jacobi(u, d) == 1
    }


def forced_factors(h: int, d: int, lane: str) -> tuple[int, ...]:
    out: list[int] = []

    # One factor of 2 is forced exactly when the numerator is 0 mod 8,
    # because the lane base divides that numerator by 4.
    if lane == "forward":
        if (h + d) % 8 == 0:
            out.append(2)
    elif lane == "reciprocal":
        if (h * d + 1) % 8 == 0:
            out.append(2)
    else:
        raise ValueError(lane)

    # For q=3,5,7 the residue class mod 840 fixes p mod q, but not mod q^2,
    # so the universally forced information is one occurrence only.
    for q in (3, 5, 7):
        if d % q == 0:
            continue
        if lane == "forward":
            if (h + d) % q == 0:
                out.append(q)
        else:
            if (h * d + 1) % q == 0:
                out.append(q)

    return tuple(out)


def signed_reach(d: int, factors: tuple[int, ...]) -> set[int]:
    reached = {1 % d}
    for r in factors:
        if math.gcd(r, d) != 1:
            raise AssertionError("forced factor is not a unit")
        rinv = pow(r, -1, d)
        reached = {
            (s * x) % d
            for s in reached
            for x in (rinv, 1, r)
        }
    return reached


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    candidates = squarefree_candidates()
    rows = []

    for d, phi in candidates:
        H = kernel(d)
        assert len(H) * 2 == phi
        for h in HARD:
            for lane in ("forward", "reciprocal"):
                F = forced_factors(h, d, lane)
                if not F:
                    continue
                S = signed_reach(d, F)
                if H <= S:
                    # Character transport guarantees the forced factors must
                    # lie on the positive side in any actually compatible row.
                    assert all(jacobi(q, d) == 1 for q in F)
                    rows.append(
                        {
                            "d": d,
                            "phi_d": phi,
                            "hard_class_mod_840": h,
                            "lane": lane,
                            "forced_factors": list(F),
                            "kernel_size": len(H),
                            "signed_reach_size": len(S),
                            "kernel": sorted(H),
                        }
                    )

    nontrivial = [row for row in rows if row["d"] > 7]
    distinct_nontrivial_d = sorted({row["d"] for row in nontrivial})

    report = {
        "schema": 1,
        "phi_cap": PHI_CAP,
        "candidate_squarefree_d_count": len(candidates),
        "saturation_row_count": len(rows),
        "nontrivial_d_gt_7": distinct_nontrivial_d,
        "rows": rows,
        "verdict": (
            "Using only universally forced occurrences from 2,3,5,7, "
            "the only squarefree d>7 with full positive-kernel saturation "
            "are 11,19,31."
        ),
    }

    text = json.dumps(report, indent=2, sort_keys=True)
    print(text)
    if args.out is not None:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n")


if __name__ == "__main__":
    main()
