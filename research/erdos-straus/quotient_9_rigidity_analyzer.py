#!/usr/bin/env python3
"""Finite exact regression for QUOTIENT-9-RIGIDITY.md.

For every configured base j, set K=9j-2 and compare:

    exact unrestricted shadow T_K mod (4j-1) subset T_j

against the proved classification:

    K prime, or K/2 prime, or (j,K)=(2,16).

The script explicitly enumerates divisors and trap residues. It is a theorem
falsifier/regression, not the proof itself.
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


def is_prime(n: int, spf: list[int]) -> bool:
    return n >= 2 and spf[n] == n


def trap_set(k: int, spf: list[int]) -> set[int]:
    m = 4 * k - 1
    return {
        r
        for e in divisors_from_factor(factor(k, spf))
        for r in ((-e) % m, (-4 * e) % m)
    }


def exact_shadow(j: int, K: int, spf: list[int]) -> bool:
    m = 4 * j - 1
    base = trap_set(j, spf)
    return {t % m for t in trap_set(K, spf)} <= base


def predicted(j: int, K: int, spf: list[int]) -> str | None:
    if is_prime(K, spf):
        return "prime"
    if K % 2 == 0 and is_prime(K // 2, spf):
        return "twice_prime"
    if j == 2 and K == 16:
        return "exception_16"
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--j-limit", type=int, default=100000)
    ap.add_argument("--out", type=Path, default=Path("quotient-9-output"))
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    max_k = 9 * args.j_limit - 2
    spf = spf_sieve(max_k)

    class_counts: collections.Counter[str] = collections.Counter()
    factor_shape_counts: collections.Counter[str] = collections.Counter()
    exact_shadow_count = 0
    mismatches: list[dict] = []
    examples: list[dict] = []

    for j in range(1, args.j_limit + 1):
        K = 9 * j - 2
        kind = predicted(j, K, spf)
        shadow = exact_shadow(j, K, spf)
        if shadow:
            exact_shadow_count += 1
            class_counts[kind or "unexpected"] += 1
            fac = factor(K, spf)
            factor_shape_counts["*".join(str(a) for a in sorted(fac.values()))] += 1
            if len(examples) < args.examples:
                examples.append(
                    {
                        "j": j,
                        "K": K,
                        "kind": kind,
                        "factorization": fac,
                    }
                )

        if shadow != (kind is not None):
            mismatches.append(
                {
                    "j": j,
                    "K": K,
                    "exact_shadow": shadow,
                    "predicted_kind": kind,
                    "factorization": factor(K, spf),
                }
            )

        if j % 10000 == 0:
            print(
                f"q=9 rigidity regression {j}/{args.j_limit} "
                f"shadows={exact_shadow_count} mismatches={len(mismatches)}",
                flush=True,
            )

    if mismatches:
        raise AssertionError(f"quotient-9 rigidity mismatch: {mismatches[:10]}")

    result = {
        "status": "exact quotient-9 rigidity finite regression",
        "j_limit": args.j_limit,
        "children_checked": args.j_limit,
        "full_unrestricted_shadows": exact_shadow_count,
        "classification_counts": dict(sorted(class_counts.items())),
        "shadow_factor_shape_counts": dict(sorted(factor_shape_counts.items())),
        "classification_mismatches": 0,
        "examples": examples,
        "theorem_checks": {
            "shadow_iff_prime_or_twice_prime_or_j2_k16": True,
            "all_exact_trap_sets_explicitly_enumerated": True,
        },
        "claim_boundary": (
            "The universal proof is in QUOTIENT-9-RIGIDITY.md. "
            "This is a finite exact regression only."
        ),
    }
    (args.out / "quotient-9-rigidity-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Quotient-9 rigidity regression\n\n"
    report += f"Bases checked: `1 <= j <= {args.j_limit}`.\n\n"
    report += f"Exact unrestricted full shadows: **`{exact_shadow_count}`**.\n\n"
    report += "Classification counts:\n\n"
    for kind, count in sorted(class_counts.items()):
        report += f"- `{kind}`: `{count}`\n"
    report += "\nClassification mismatches: **`0`**.\n\n"
    report += (
        "Every target trap set was explicitly enumerated and reduced modulo the source modulus. "
        "The finite data exactly matches the proved prime / twice-prime / K=16 classification.\n"
    )
    (args.out / "quotient-9-rigidity-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
