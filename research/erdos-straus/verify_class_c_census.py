#!/usr/bin/env python3
"""Independent verifier for class_c_census.py.

This verifier intentionally uses a different fiber-elimination control flow: it
recomputes all current local loads from scratch after each peel instead of
maintaining incremental loads.  It independently reconstructs N, N^act,
valuation sources, the unique-active pullback, residual kernels, and bounded
selectors, then compares the resulting summary to `class-c-census.json`.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from fractions import Fraction
from pathlib import Path

F840 = {3: 1, 5: 1, 7: 1}


def divisors(n: int) -> list[int]:
    out: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            out.append(d)
            if d * d != n:
                out.append(n // d)
    return sorted(out)


def factor(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    p = 3
    while p * p <= x:
        while x % p == 0:
            out[p] = out.get(p, 0) + 1
            x //= p
        p += 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def traps(k: int) -> set[int]:
    m = 4 * k - 1
    return {x for e in divisors(k) for x in ((-e) % m, (-4 * e) % m)}


def jacobi(a: int, n: int) -> int:
    a %= n
    s = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                s = -s
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            s = -s
        a %= n
    return s if n == 1 else 0


def pullback(r: int, L: int, j: int, T: list[set[int]]) -> tuple[int, frozenset[int]]:
    m = 4 * j - 1
    g = math.gcd(L, m)
    q = m // g
    if q == 1:
        R = {0} if any((u - r) % g == 0 for u in T[j]) else set()
        return q, frozenset(R)
    inv = pow((L // g) % q, -1, q)
    R = {
        (((u - r) // g) * inv) % q
        for u in T[j]
        if (u - r) % g == 0
    }
    return q, frozenset(R)


def fiber_width(q: int, R: frozenset[int], p: int, a: int) -> int:
    pa = p**a
    c = q // pa
    if c == 1:
        return len(R)
    buckets: collections.Counter[int] = collections.Counter(x % c for x in R)
    return max(buckets.values(), default=0)


def brute_recompute_peel(
    r: int,
    L: int,
    edges: list[dict],
) -> tuple[tuple[int, ...], list[dict]]:
    active_edges = list(edges)
    active_primes = sorted({p for e in active_edges for p in e["factors"]})
    while True:
        chosen = None
        for p in active_primes:
            incident = [e for e in active_edges if p in e["factors"]]
            if not incident:
                continue
            load = Fraction(0)
            for edge in incident:
                a = edge["factors"][p]
                load += Fraction(fiber_width(edge["q"], edge["R"], p, a), p**a)
            if L % p:
                load += Fraction(1, p)
            elif r % p == 0:
                raise AssertionError("non-reduced target progression")
            if load < 1:
                chosen = p
                break
        if chosen is None:
            break
        active_edges = [e for e in active_edges if chosen not in e["factors"]]
        active_primes = sorted({p for e in active_edges for p in e["factors"]})
    return tuple(active_primes), active_edges


def selector(r: int, L: int, primes: tuple[int, ...], edges: list[dict], bound: int) -> int | None:
    values = [0]
    for a in range(1, bound + 1):
        values.extend((a, -a))
    for s in values:
        if any(s % e["q"] in e["R"] for e in edges):
            continue
        if any(L % p and (r + L * s) % p == 0 for p in primes):
            continue
        return s
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    claimed = json.loads((args.out / "class-c-census.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    K = int(source["parameters"]["k_limit"])
    bound = int(claimed["single_active"]["selector_bound"])

    fac = [dict()] + [factor(4 * k - 1) for k in range(1, K + 1)]
    T = [set()] + [traps(k) for k in range(1, K + 1)]
    profiles: dict[int, tuple[list[int], list[int], dict[int, int]]] = {}
    for k in {int(w["k"]) for w in witnesses}:
        fixed_primes = set(F840) | set(fac[k])
        vL = {p: max(F840.get(p, 0), fac[k].get(p, 0)) for p in fixed_primes}
        fixed: list[int] = []
        active: list[int] = []
        for j in range(1, k):
            if all(a % 2 == 0 or p in fixed_primes for p, a in fac[j].items()):
                fixed.append(j)
                if any(a > vL.get(p, 0) for p, a in fac[j].items()):
                    active.append(j)
        profiles[k] = fixed, active, vL

    n_hist: collections.Counter[int] = collections.Counter()
    a_hist: collections.Counter[int] = collections.Counter()
    q_hist: collections.Counter[int] = collections.Counter()
    source_hist: collections.Counter[str] = collections.Counter()
    rsize: collections.Counter[int] = collections.Counter()
    safe_hist: collections.Counter[int] = collections.Counter()
    sig_hist: collections.Counter[tuple[int, ...]] = collections.Counter()
    edge_categories: collections.Counter[str] = collections.Counter()
    radius_hist: collections.Counter[int] = collections.Counter()
    inactive_only = single = fiber_empty = fiber_nonempty = active_survives = unresolved = 0

    for rec in witnesses:
        k = int(rec["k"]); r = int(rec["r"]); L = int(rec["L"])
        fixed, active, vL = profiles[k]
        N = {j for j in fixed if jacobi(r, 4 * j - 1) == -1}
        A = [j for j in active if j in N]
        n_hist[len(N)] += 1
        a_hist[len(A)] += 1
        if N and not A:
            inactive_only += 1
        if len(A) != 1:
            continue

        single += 1
        j0 = A[0]
        q0, R0 = pullback(r, L, j0, T)
        q_hist[q0] += 1
        rsize[len(R0)] += 1

        ca = cb = False
        for p, exponent in fac[j0].items():
            old = vL.get(p, 0)
            if exponent > old:
                if old:
                    ca = True
                else:
                    cb = True
        source_hist["mixed" if ca and cb else "B-only" if cb else "A-only"] += 1

        qf = factor(q0)
        safe = sum(
            1 for s in range(q0)
            if s not in R0
            and all(not (L % p and (r + L * s) % p == 0) for p in qf)
        )
        safe_hist[safe] += 1

        edges: list[dict] = []
        for j in range(1, k):
            q, R = pullback(r, L, j, T)
            if not R:
                continue
            if q == 1:
                raise AssertionError("direct novelty contradicted by q=1 full pullback")
            edges.append({"j": j, "q": q, "R": R, "factors": factor(q)})
        primes, residual = brute_recompute_peel(r, L, edges)
        if not primes:
            fiber_empty += 1
            continue
        fiber_nonempty += 1
        sig_hist[primes] += 1
        residual_js = {int(e["j"]) for e in residual}
        if j0 in residual_js:
            active_survives += 1
        for edge in residual:
            j = int(edge["j"])
            if j == j0:
                edge_categories["unique-active-fixed-negative"] += 1
            elif j in N:
                edge_categories["other-fixed-negative"] += 1
            elif j in fixed:
                edge_categories["fixed-positive"] += 1
            else:
                edge_categories["nonfixed"] += 1
        s = selector(r, L, primes, residual, bound)
        if s is None:
            unresolved += 1
        else:
            radius_hist[abs(s)] += 1

    actual = {
        "fixed_negative_size_histogram": {str(k): v for k, v in sorted(n_hist.items())},
        "active_fixed_negative_size_histogram": {str(k): v for k, v in sorted(a_hist.items())},
        "inactive_only_character_failures": inactive_only,
        "single_active": {
            "candidates": single,
            "q_histogram": {str(k): v for k, v in sorted(q_hist.items())},
            "valuation_source_histogram": dict(sorted(source_hist.items())),
            "class_B_candidates": source_hist.get("B-only", 0),
            "mixed_source_candidates": source_hist.get("mixed", 0),
            "pullback_R_size_histogram": {str(k): v for k, v in sorted(rsize.items())},
            "reduced_safe_residue_count_histogram": {str(k): v for k, v in sorted(safe_hist.items())},
            "minimum_reduced_safe_residues_mod_q": min(safe_hist) if safe_hist else None,
            "fiber_empty": fiber_empty,
            "fiber_nonempty": fiber_nonempty,
            "active_layer_survives_fiber": active_survives,
            "active_layer_removed_before_residual": fiber_nonempty - active_survives,
            "residual_kernel_signatures": [
                {"primes": list(sig), "count": count}
                for sig, count in sig_hist.most_common()
            ],
            "residual_edge_categories": dict(sorted(edge_categories.items())),
            "selector_bound": bound,
            "selector_unresolved": unresolved,
            "selector_radius_histogram": {str(k): v for k, v in sorted(radius_hist.items())},
            "maximum_selector_radius": max(radius_hist, default=0),
        },
    }

    keys = ["fixed_negative_size_histogram", "active_fixed_negative_size_histogram", "inactive_only_character_failures", "single_active"]
    mismatches = [key for key in keys if claimed[key] != actual[key]]
    verdict = "VERIFIED" if not mismatches else "MISMATCH"
    output = {
        "verdict": verdict,
        "k_limit": K,
        "direct_novel_candidates_checked": len(witnesses),
        "single_active_candidates_checked": single,
        "mismatched_sections": mismatches,
        "independent_control_flow": "fiber loads recomputed from scratch after each peel",
    }
    (args.out / "class-c-census-independent-verifier.json").write_text(
        json.dumps(output, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(output, indent=2, sort_keys=True))
    if mismatches:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
