#!/usr/bin/env python3
"""Finite regression verifier for RECIPROCITY-TOWER-SHADOWS.md.

Checks:

1. Jacobi-saturated layers through a configurable k range by comparing the
   exact trap cardinality with phi(4k-1)/2;
2. direct explicit trap reduction for the three proved reciprocity towers
   based at j=1,2,4 over many odd lift parameters c;
3. the divisor-Jacobi reciprocity lemma for every tested lifted depth.

The universal proofs live in RECIPROCITY-TOWER-SHADOWS.md. This script is a
falsifier/regression only.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


def spf_sieve(n: int) -> list[int]:
    spf = list(range(n + 1))
    if n >= 1:
        spf[1] = 1
    for p in range(2, math.isqrt(n) + 1):
        if spf[p] == p:
            for x in range(p * p, n + 1, p):
                if spf[x] == x:
                    spf[x] = p
    return spf


def factor_from_spf(n: int, spf: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    while n > 1:
        p = spf[n]
        out[p] = out.get(p, 0) + 1
        n //= p
    return out


def tau_from_factor(fac: dict[int, int]) -> int:
    out = 1
    for a in fac.values():
        out *= a + 1
    return out


def phi_from_factor(n: int, fac: dict[int, int]) -> int:
    out = n
    for p in fac:
        out -= out // p
    return out


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=50000)
    ap.add_argument("--c-limit", type=int, default=1001)
    ap.add_argument("--out", type=Path, default=Path("reciprocity-tower-output"))
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    max_n = 4 * args.k_limit - 1
    spf = spf_sieve(max_n)

    saturated: list[int] = []
    for k in range(1, args.k_limit + 1):
        kfac = factor_from_spf(k, spf)
        tau_k = tau_from_factor(kfac)
        correction = 0
        if k % 4 == 0:
            correction = tau_from_factor(factor_from_spf(k // 4, spf))
        trap_size = 2 * tau_k - 1 - correction

        m = 4 * k - 1
        ph = phi_from_factor(m, factor_from_spf(m, spf))
        if 2 * trap_size == ph:
            saturated.append(k)

        if k % 10000 == 0:
            print(f"Jacobi saturation regression {k}/{args.k_limit}", flush=True)

    if saturated != [1, 2, 4]:
        raise AssertionError(f"unexpected Jacobi-saturated layers: {saturated}")

    base_results: list[dict] = []
    total_lifts = 0
    total_divisor_checks = 0

    for base in (1, 2, 4):
        m = 4 * base - 1
        T_base = trap_set(base)
        tested = 0
        largest_depth = base

        for c in range(1, args.c_limit + 1, 2):
            K = (m * c * c + 1) // 4
            if 4 * K - 1 != m * c * c:
                raise AssertionError("square-lift identity failed")

            # Verify the reciprocity lemma directly on every divisor.
            for e in divisors(K):
                if math.gcd(e, m) != 1:
                    raise AssertionError(f"lift divisor not a unit base={base} c={c} e={e}")
                if jacobi(e, m) != 1:
                    raise AssertionError(
                        f"reciprocity divisor lemma failed base={base} c={c} K={K} e={e}"
                    )
                total_divisor_checks += 1

            image = {t % m for t in trap_set(K)}
            if not image <= T_base:
                raise AssertionError(
                    f"tower shadow failed base={base} c={c} K={K} extra={sorted(image - T_base)}"
                )

            tested += 1
            total_lifts += 1
            largest_depth = max(largest_depth, K)

        base_results.append(
            {
                "base_layer": base,
                "base_modulus": m,
                "odd_c_values_tested": tested,
                "largest_lift_depth": largest_depth,
                "all_direct_shadows_verified": True,
            }
        )

    result = {
        "status": "exact reciprocity tower finite regression",
        "k_limit": args.k_limit,
        "c_limit": args.c_limit,
        "jacobi_saturated_layers": saturated,
        "total_tower_lifts_checked": total_lifts,
        "total_lift_divisors_checked": total_divisor_checks,
        "base_results": base_results,
        "theorem_checks": {
            "finite_jacobi_saturation_only_1_2_4": True,
            "square_lift_identity": True,
            "every_lift_divisor_jacobi_positive_at_base": True,
            "every_tested_lift_fully_shadowed": True,
        },
        "claim_boundary": (
            "The classification and reciprocity-tower shadow proofs are in RECIPROCITY-TOWER-SHADOWS.md. "
            "The finite ranges here are regression checks only."
        ),
    }
    (args.out / "reciprocity-tower-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Reciprocity tower finite regression\n\n"
    report += f"Jacobi saturation checked through `k <= {args.k_limit}`.\n\n"
    report += f"Observed saturated layers: `{saturated}`.\n\n"
    report += f"Odd lift parameters tested through `c <= {args.c_limit}` for each of bases `1,2,4`.\n\n"
    report += f"Total tower lifts checked: **`{total_lifts}`**.\n\n"
    report += f"Total lift divisors checked against the reciprocity lemma: **`{total_divisor_checks}`**.\n\n"
    for row in base_results:
        report += (
            f"- base `{row['base_layer']}` (modulus `{row['base_modulus']}`): "
            f"`{row['odd_c_values_tested']}` lifts, largest depth `{row['largest_lift_depth']}`, all shadowed.\n"
        )
    report += "\nAll theorem regression checks passed.\n"
    (args.out / "reciprocity-tower-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
