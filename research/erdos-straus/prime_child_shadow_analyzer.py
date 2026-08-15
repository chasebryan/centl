#!/usr/bin/env python3
"""Finite regression for PRIME-CHILD-SHADOWS.md.

Checks:

1. for every quotient q=1 mod 4 in a configured range and all base layers j
   in a finite range, every prime ancestry child K=qj-(q-1)/4 is fully
   shadowed by j;
2. for q=5 through a much larger j range, unrestricted full shadowing occurs
   if and only if K=5j-1 is prime.

The universal proofs are in PRIME-CHILD-SHADOWS.md.
"""
from __future__ import annotations

import argparse
import collections
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


def is_prime_spf(n: int, spf: list[int]) -> bool:
    return n >= 2 and spf[n] == n


def factor(n: int, spf: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    while n > 1:
        p = spf[n]
        out[p] = out.get(p, 0) + 1
        n //= p
    return out


def divisors_from_factor(fac: dict[int, int]) -> list[int]:
    out = [1]
    for p, a in fac.items():
        out = [d * p**e for d in out for e in range(a + 1)]
    return out


def trap_set(k: int, spf: list[int]) -> set[int]:
    m = 4 * k - 1
    return {
        r
        for e in divisors_from_factor(factor(k, spf))
        for r in ((-e) % m, (-4 * e) % m)
    }


def full_projection_shadow(j: int, K: int, spf: list[int]) -> bool:
    m = 4 * j - 1
    base = trap_set(j, spf)
    return {t % m for t in trap_set(K, spf)} <= base


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--q-max", type=int, default=101)
    ap.add_argument("--j-general", type=int, default=2000)
    ap.add_argument("--j-q5", type=int, default=50000)
    ap.add_argument("--out", type=Path, default=Path("prime-child-output"))
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    max_k = max(
        args.q_max * args.j_general,
        5 * args.j_q5,
        args.j_q5,
    ) + 10
    spf = spf_sieve(max_k)

    quotient_counts: collections.Counter[int] = collections.Counter()
    prime_child_checks = 0
    prime_child_failures: list[dict] = []

    for q in range(5, args.q_max + 1, 4):
        s = (q - 1) // 4
        for j in range(1, args.j_general + 1):
            K = q * j - s
            if not is_prime_spf(K, spf):
                continue
            prime_child_checks += 1
            quotient_counts[q] += 1
            if (4 * K - 1) != q * (4 * j - 1):
                raise AssertionError("ancestry identity failed")
            if not full_projection_shadow(j, K, spf):
                prime_child_failures.append({"q": q, "j": j, "K": K})

    if prime_child_failures:
        raise AssertionError(f"prime-child theorem regression failures: {prime_child_failures[:10]}")

    q5_prime = 0
    q5_composite = 0
    q5_shadow = 0
    q5_mismatches: list[dict] = []
    for j in range(1, args.j_q5 + 1):
        K = 5 * j - 1
        prime = is_prime_spf(K, spf)
        shadow = full_projection_shadow(j, K, spf)
        q5_prime += int(prime)
        q5_composite += int(not prime)
        q5_shadow += int(shadow)
        if prime != shadow:
            q5_mismatches.append(
                {"j": j, "K": K, "prime": prime, "shadow": shadow}
            )
        if j % 10000 == 0:
            print(
                f"q=5 rigidity regression {j}/{args.j_q5} "
                f"prime={q5_prime} shadow={q5_shadow}",
                flush=True,
            )

    if q5_mismatches:
        raise AssertionError(f"q=5 rigidity mismatch: {q5_mismatches[:10]}")

    result = {
        "status": "exact prime-child shadow finite regression",
        "q_max": args.q_max,
        "j_general": args.j_general,
        "j_q5": args.j_q5,
        "general_prime_child_checks": prime_child_checks,
        "general_prime_child_failures": len(prime_child_failures),
        "prime_child_counts_by_q": {
            str(q): count for q, count in sorted(quotient_counts.items())
        },
        "q5_prime_children": q5_prime,
        "q5_composite_children": q5_composite,
        "q5_full_shadows": q5_shadow,
        "q5_prime_shadow_mismatches": len(q5_mismatches),
        "theorem_checks": {
            "all_tested_prime_children_shadow": True,
            "q5_shadow_iff_prime": True,
        },
        "claim_boundary": (
            "The universal prime-child and quotient-5 rigidity proofs are in PRIME-CHILD-SHADOWS.md. "
            "These finite enumerations are regression checks only."
        ),
    }
    (args.out / "prime-child-shadow-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Prime-child shadow regression\n\n"
    report += (
        f"General ancestry quotients checked: `q=5,9,...,{args.q_max}` "
        f"with `j <= {args.j_general}`.\n\n"
    )
    report += f"Prime-child shadow checks: **`{prime_child_checks}`**, all passed.\n\n"
    report += f"Quotient-5 rigidity checked through `j <= {args.j_q5}`.\n\n"
    report += f"q=5 prime children: **`{q5_prime}`**.\n\n"
    report += f"q=5 full unrestricted shadows: **`{q5_shadow}`**.\n\n"
    report += "Prime/shadow mismatches: **`0`**.\n\n"
    report += "All theorem regression checks passed.\n"
    (args.out / "prime-child-shadow-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
