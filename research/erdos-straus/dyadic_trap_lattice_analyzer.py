#!/usr/bin/env python3
"""Finite regression verifier for DYADIC-TRAP-LATTICE.md.

The script checks:

* exact dyadic trap-coset equality T_{2^a}=-<2>;
* ord_{2^{a+2}-1}(2)=a+2;
* full multiplicative trap-coset saturation occurs only at powers of two over
  a configurable finite k-range;
* every dyadic Mersenne divisibility edge induces exact trap shadowing.

These are theorem regressions. The proofs live in DYADIC-TRAP-LATTICE.md.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def prime_divisors(n: int) -> list[int]:
    out: list[int] = []
    x = n
    p = 2
    while p * p <= x:
        if x % p == 0:
            out.append(p)
            while x % p == 0:
                x //= p
        p = 3 if p == 2 else p + 2
    if x > 1:
        out.append(x)
    return out


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


def subgroup_generated_until(m: int, generators: list[int], stop_after: int | None = None) -> set[int]:
    H = {1 % m}
    queue = [1 % m]
    while queue:
        x = queue.pop()
        for g in generators:
            y = (x * g) % m
            if y not in H:
                H.add(y)
                if stop_after is not None and len(H) > stop_after:
                    return H
                queue.append(y)
    return H


def multiplicative_order(a: int, m: int) -> int:
    x = 1
    for r in range(1, m + 1):
        x = (x * a) % m
        if x == 1:
            return r
    raise AssertionError("order search failed")


def is_power_of_two(n: int) -> bool:
    return n > 0 and n & (n - 1) == 0


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=50000)
    ap.add_argument("--a-limit", type=int, default=18)
    ap.add_argument("--out", type=Path, default=Path("dyadic-trap-output"))
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    dyadic_rows: list[dict] = []
    shadow_edges: list[dict] = []

    for a in range(args.a_limit + 1):
        k = 1 << a
        m = (1 << (a + 2)) - 1
        T = trap_set(k)
        order = multiplicative_order(2, m)
        if order != a + 2:
            raise AssertionError(f"dyadic order failed a={a}: {order}")
        H = {pow(2, r, m) for r in range(order)}
        if T != {(-h) % m for h in H}:
            raise AssertionError(f"dyadic trap-coset equality failed a={a}")
        dyadic_rows.append(
            {
                "a": a,
                "k": k,
                "m": m,
                "order_2": order,
                "trap_size": len(T),
            }
        )

    for a in range(args.a_limit + 1):
        for b in range(a + 1, args.a_limit + 1):
            ma = (1 << (a + 2)) - 1
            mb = (1 << (b + 2)) - 1
            divides = mb % ma == 0
            predicted = (b + 2) % (a + 2) == 0
            if divides != predicted:
                raise AssertionError(f"Mersenne divisibility mismatch a={a} b={b}")
            if not divides:
                continue
            Ta = trap_set(1 << a)
            Tb = trap_set(1 << b)
            image = {t % ma for t in Tb}
            if image != Ta:
                raise AssertionError(f"dyadic shadow image mismatch a={a} b={b}")
            shadow_edges.append(
                {
                    "a": a,
                    "b": b,
                    "k_earlier": 1 << a,
                    "k_later": 1 << b,
                    "m_earlier": ma,
                    "m_later": mb,
                    "quotient": mb // ma,
                }
            )

    saturated: list[int] = []
    for k in range(1, args.k_limit + 1):
        T = trap_set(k)
        H = subgroup_generated_until(4 * k - 1, prime_divisors(k), stop_after=len(T))
        if len(H) == len(T):
            # T subset -H is already proved in the main theory, but verify it
            # directly before calling the finite layer saturated.
            minus_H = {(-h) % (4 * k - 1) for h in H}
            if T == minus_H:
                saturated.append(k)
        if k % 5000 == 0:
            print(f"dyadic saturation regression {k}/{args.k_limit}", flush=True)

    expected = [k for k in range(1, args.k_limit + 1) if is_power_of_two(k)]
    if saturated != expected:
        raise AssertionError(
            f"finite saturation classification mismatch: observed={saturated} expected={expected}"
        )

    result = {
        "status": "exact dyadic trap-lattice finite regression",
        "k_limit": args.k_limit,
        "a_limit": args.a_limit,
        "dyadic_rows": dyadic_rows,
        "dyadic_shadow_edges": shadow_edges,
        "saturated_layers": saturated,
        "saturation_matches_powers_of_two": True,
        "theorem_checks": {
            "dyadic_trap_equals_negative_cyclic_subgroup": True,
            "dyadic_order_equals_a_plus_2": True,
            "mersenne_divisibility_iff_exponent_divisibility": True,
            "dyadic_divisibility_edges_are_exact_trap_shadows": True,
            "finite_full_saturation_only_at_powers_of_two": True,
        },
        "claim_boundary": (
            "The universal proofs are in DYADIC-TRAP-LATTICE.md. "
            "The k-range saturation enumeration is only a regression."
        ),
    }
    (args.out / "dyadic-trap-lattice-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Dyadic trap lattice finite regression\n\n"
    report += f"Full saturation classification checked through `k <= {args.k_limit}`.\n\n"
    report += f"Observed saturated layers: `{len(saturated)}`.\n\n"
    report += "They are exactly the powers of two in the tested range.\n\n"
    report += f"Dyadic exponents checked through `a <= {args.a_limit}`.\n\n"
    report += f"Exact dyadic shadow edges checked: `{len(shadow_edges)}`.\n\n"
    report += "All theorem regression checks passed.\n"
    (args.out / "dyadic-trap-lattice-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
