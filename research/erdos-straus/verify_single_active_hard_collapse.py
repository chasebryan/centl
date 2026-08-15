#!/usr/bin/env python3
"""Independent verifier for the hard-class single-active quotient probe.

Unlike the primary probe, this implementation first enumerates the actual
earlier layers m_j=4j-1, groups them by squarefree kernel, and then queries
those groups for each target.  It does not generate fixed layers as d*s^2.
The two implementations should agree on the complete finite census.
"""
from __future__ import annotations

import argparse
import bisect
import collections
import json
import math
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
    out: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            out.append(d)
            if d * d != n:
                out.append(n // d)
    return sorted(out)


def traps(k: int) -> set[int]:
    m = 4 * k - 1
    return {x for e in divisors(k) for x in ((-e) % m, (-4 * e) % m)}


def sf_kernel(f: dict[int, int]) -> int:
    out = 1
    for p, a in f.items():
        if a % 2:
            out *= p
    return out


def squarefree_divisors(primes: list[int]) -> list[int]:
    out = [1]
    for p in primes:
        out += [d * p for d in out]
    return out


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
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
    ap.add_argument("--primary", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=Path("single-active-collapse-output"))
    args = ap.parse_args()
    claimed = json.loads(args.primary.read_text())
    K = int(claimed["k_limit"])
    args.out.mkdir(parents=True, exist_ok=True)

    spf = spf_sieve(4 * K)
    fact: list[dict[int, int]] = [dict()] * (K + 1)
    groups: dict[int, list[int]] = collections.defaultdict(list)
    for j in range(1, K + 1):
        m = 4 * j - 1
        f = factor(m, spf)
        fact[j] = f
        groups[sf_kernel(f)].append(m)

    q_hist: collections.Counter[int] = collections.Counter()
    source_hist: collections.Counter[str] = collections.Counter()
    hard_candidates = 0
    single_active = 0
    counterexamples: list[dict] = []

    for k in range(1, K + 1):
        M = 4 * k - 1
        L = math.lcm(840, M)
        fixed_primes = sorted(set(fact[k]) | {3, 5, 7})
        tower_state: list[tuple[int, int, int | None]] = []

        for d in squarefree_divisors(fixed_primes):
            if d >= M or d % 4 != 3:
                continue
            arr = groups.get(d)
            if not arr:
                continue
            stop = bisect.bisect_left(arr, M)
            count = 0
            first_q: int | None = None
            for m in arr[:stop]:
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

        g = math.gcd(840, M)
        for t in traps(k):
            for h in HARD:
                if (h - t) % g:
                    continue
                cr = crt2(h, 840, t, M)
                if cr is None:
                    raise AssertionError("CRT failure on compatible target")
                r, _ = cr
                hard_candidates += 1
                total = 0
                unique_q: int | None = None
                for d, count, q in tower_state:
                    if jacobi(r, d) == -1:
                        total += count
                        if total > 1:
                            break
                        unique_q = q
                if total != 1:
                    continue
                if unique_q is None:
                    raise AssertionError("missing unique q")
                single_active += 1
                q_hist[unique_q] += 1
                qf = factor(unique_q, spf)
                if len(qf) != 1:
                    source = "multi-prime"
                else:
                    p, a = next(iter(qf.items()))
                    source = "A" if L % p == 0 else "B"
                    if source == "B" and a != 2:
                        source = "B-parity-violation"
                source_hist[source] += 1
                if unique_q not in {3, 5, 9} or source != "A":
                    counterexamples.append({"k": k, "h": h, "t": t, "q": unique_q, "source": source})

        if k % 10_000 == 0:
            print(
                f"verify progress k={k}/{K} hard_candidates={hard_candidates} "
                f"single_active={single_active}",
                flush=True,
            )

    expected = {
        "hard_compatible_target_candidates": claimed["hard_compatible_target_candidates"],
        "single_active_candidates": claimed["single_active_candidates"],
        "q_histogram": claimed["q_histogram"],
        "valuation_source_histogram": claimed["valuation_source_histogram"],
        "counterexample_count": claimed["counterexample_count"],
    }
    actual = {
        "hard_compatible_target_candidates": hard_candidates,
        "single_active_candidates": single_active,
        "q_histogram": {str(q): n for q, n in sorted(q_hist.items())},
        "valuation_source_histogram": dict(sorted(source_hist.items())),
        "counterexample_count": len(counterexamples),
    }
    mismatches = [key for key in expected if expected[key] != actual[key]]
    result = {
        "verdict": "VERIFIED" if not mismatches else "MISMATCH",
        "k_limit": K,
        "independent_construction": "enumerated earlier m_j grouped by squarefree kernel",
        "mismatched_fields": mismatches,
        "expected": expected,
        "actual": actual,
        "counterexamples": counterexamples[:100],
    }
    (args.out / "single-active-hard-collapse-independent-verifier.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(result, indent=2, sort_keys=True))
    if mismatches:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
