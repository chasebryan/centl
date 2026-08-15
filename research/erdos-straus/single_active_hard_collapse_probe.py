#!/usr/bin/env python3
"""Falsify the hard-class single-active quotient collapse.

For every hard-compatible Type A/B target candidate through the configured
layer bound, this script reconstructs all fixed-squareclass earlier towers,
counts the active fixed-negative core, and records the excess quotient when
that core has size exactly one.

Primary construction: fixed-squareclass layers are generated directly as
m = d*s^2 from squarefree d dividing rad(lcm(840,4k-1)).

Conjecture under attack:
    |N^act| = 1  =>  q in {3,5,9}
for the six Mordell-hard classes modulo 840.

The universal theorem already proved elsewhere gives only q=p or p^2.  This
probe attacks the much sharper small-prime restriction.  A finite clean run is
not a proof.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


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
        a = 0
        while n % p == 0:
            n //= p
            a += 1
        out[p] = a
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
    return {x for e in divisors(k) for x in ((-e) % m, (-4 * e) % m)}


def squarefree_divisors(primes: list[int]) -> list[int]:
    out = [1]
    for p in primes:
        out += [d * p for d in out]
    return out


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm = m // g
    nn = n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * u) % L, L


def jacobi(a: int, n: int) -> int:
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
    ap.add_argument("--k-limit", type=int, default=100_000)
    ap.add_argument("--out", type=Path, default=Path("single-active-collapse-output"))
    ap.add_argument("--stop-on-counterexample", action="store_true")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    K = args.k_limit
    spf = spf_sieve(4 * K)
    q_hist: Counter[int] = Counter()
    source_hist: Counter[str] = Counter()
    single_by_h: Counter[int] = Counter()
    hard_candidates = 0
    single_active = 0
    counterexamples: list[dict] = []
    first_examples: dict[int, dict] = {}

    for k in range(1, K + 1):
        M = 4 * k - 1
        Mf = factor(M, spf)
        L = math.lcm(840, M)
        fixed_primes = sorted(set(Mf) | {3, 5, 7})

        # For each possible negative squarefree ancestor d, keep only enough
        # information to decide whether it contributes 0, 1, or >=2 active
        # fixed-negative layers.  If it contributes exactly one, retain q.
        tower_state: list[tuple[int, int, int | None]] = []
        for d in squarefree_divisors(fixed_primes):
            if d >= M or d % 4 != 3:
                continue
            s_max = math.isqrt((M - 1) // d)
            count = 0
            first_q: int | None = None
            for s in range(1, s_max + 1, 2):
                m = d * s * s
                q = m // math.gcd(L, m)
                if q > 1:
                    count += 1
                    if first_q is None:
                        first_q = q
                    if count >= 2:
                        break
            if count:
                tower_state.append((d, count, first_q))

        if not tower_state:
            continue

        compatibility_modulus = math.gcd(840, M)
        for t in trap_set(k):
            for h in HARD:
                if (h - t) % compatibility_modulus:
                    continue
                cr = crt2(h, 840, t, M)
                if cr is None:
                    raise AssertionError("compatible hard/target pair failed CRT")
                r, _ = cr
                hard_candidates += 1

                total = 0
                unique_q: int | None = None
                unique_d: int | None = None
                for d, count, first_q in tower_state:
                    if jacobi(r, d) != -1:
                        continue
                    total += count
                    if total > 1:
                        break
                    unique_q = first_q
                    unique_d = d

                if total != 1:
                    continue

                if unique_q is None or unique_d is None:
                    raise AssertionError("single-active candidate lacks quotient")
                single_active += 1
                q_hist[unique_q] += 1
                single_by_h[h] += 1

                qf = factor(unique_q, spf)
                if len(qf) != 1:
                    source_kind = "multi-prime"
                else:
                    p, exponent = next(iter(qf.items()))
                    source_kind = "A" if L % p == 0 else "B"
                    if source_kind == "B" and exponent != 2:
                        source_kind = "B-parity-violation"
                source_hist[source_kind] += 1

                first_examples.setdefault(
                    unique_q,
                    {
                        "k": k,
                        "M": M,
                        "h": h,
                        "t": t,
                        "r": r,
                        "d": unique_d,
                        "q": unique_q,
                        "source_kind": source_kind,
                    },
                )

                if unique_q not in {3, 5, 9} or source_kind != "A":
                    counterexamples.append(
                        {
                            "k": k,
                            "M": M,
                            "h": h,
                            "t": t,
                            "r": r,
                            "d": unique_d,
                            "q": unique_q,
                            "source_kind": source_kind,
                        }
                    )
                    if args.stop_on_counterexample:
                        break
            if args.stop_on_counterexample and counterexamples:
                break
        if args.stop_on_counterexample and counterexamples:
            break

        if k % 10_000 == 0:
            print(
                f"progress k={k}/{K} hard_candidates={hard_candidates} "
                f"single_active={single_active} counterexamples={len(counterexamples)}",
                flush=True,
            )

    result = {
        "status": "exact finite hard-class single-active quotient falsification",
        "construction": "direct square-lift tower generation m=d*s^2",
        "k_limit": K,
        "hard_classes_mod_840": list(HARD),
        "hard_compatible_target_candidates": hard_candidates,
        "single_active_candidates": single_active,
        "q_histogram": {str(q): n for q, n in sorted(q_hist.items())},
        "valuation_source_histogram": dict(sorted(source_hist.items())),
        "single_active_by_h": {str(h): n for h, n in sorted(single_by_h.items())},
        "first_example_by_q": {str(q): rec for q, rec in sorted(first_examples.items())},
        "counterexample_count": len(counterexamples),
        "counterexamples": counterexamples[:100],
        "conjecture_tested": "hard-compatible |N^act|=1 implies q in {3,5,9} and Class A",
        "claim_boundary": (
            "A zero counterexample count is finite evidence only. The proved universal theorem is only q=p or p^2."
        ),
    }
    (args.out / "single-active-hard-collapse.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Hard-class single-active quotient falsification\n\n"
    report += f"Range: `k <= {K}`.\n\n"
    report += f"Hard-compatible Type A/B target candidates: **`{hard_candidates}`**.\n\n"
    report += f"Candidates with `|N^act|=1`: **`{single_active}`**.\n\n"
    report += f"Observed q distribution: `{dict(sorted(q_hist.items()))}`.\n\n"
    report += f"Valuation source distribution: `{dict(sorted(source_hist.items()))}`.\n\n"
    report += f"Counterexamples to `q in {{3,5,9}}` and Class-A-only: **`{len(counterexamples)}`**.\n\n"
    report += "This is an exact finite falsification result, not a universal proof.\n"
    (args.out / "single-active-hard-collapse-report.md").write_text(report)
    print(report)

    if counterexamples:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
