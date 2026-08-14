#!/usr/bin/env python3
"""Exact fiber-load kernel analyzer for Type A/B shadow pullbacks.

This implements the theorem in FIBER-SHADOW-KERNEL.md. It does not use the
stored avoiding witness to decide peelability. A candidate whose augmented
fiber kernel becomes empty receives an independent constructive existence
proof for a reduced avoiding parameter assignment by reverse extension.

Residual kernels are recorded for proof mining. The script also tests a simple
canonical local basepoint on each residual kernel, but that diagnostic is not
used to claim universal completeness.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from fractions import Fraction
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


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


def factor_exp(n: int) -> tuple[tuple[int, int], ...]:
    if n == 1:
        return ()
    out: list[tuple[int, int]] = []
    x = n
    p = 3
    while p * p <= x:
        if x % p == 0:
            a = 0
            while x % p == 0:
                x //= p
                a += 1
            out.append((p, a))
        p += 2
    if x > 1:
        out.append((x, 1))
    return tuple(out)


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * u) % L, L


def crt_coprime(a: int, m: int, b: int, n: int) -> tuple[int, int]:
    if m == 1:
        return b % n, n
    u = ((b - a) * pow(m, -1, n)) % n
    return (a + m * u) % (m * n), m * n


def parameter_constraints(
    k: int,
    h: int,
    t: int,
    traps: list[set[int]],
) -> tuple[int, int, list[tuple[int, int, frozenset[int]]]]:
    cr = crt2(h, 840, t, 4 * k - 1)
    if cr is None:
        raise AssertionError("incompatible candidate")
    r, L = cr
    out: list[tuple[int, int, frozenset[int]]] = []
    for j in range(1, k):
        mj = 4 * j - 1
        g = math.gcd(L, mj)
        q = mj // g
        R: set[int] = set()
        if q == 1:
            if any((u - r) % g == 0 for u in traps[j]):
                R.add(0)
        else:
            inv = pow((L // g) % q, -1, q)
            for u in traps[j]:
                if (u - r) % g == 0:
                    R.add((((u - r) // g) * inv) % q)
        if R:
            out.append((j, q, frozenset(R)))
    return r, L, out


def fiber_width(q: int, R: frozenset[int], p: int, a: int) -> int:
    pa = p**a
    c = q // pa
    if c == 1:
        return len(R)
    counts: dict[int, int] = collections.defaultdict(int)
    for value in R:
        counts[value % c] += 1
    return max(counts.values(), default=0)


def fiber_peel(
    r: int,
    L: int,
    constraints: list[tuple[int, int, frozenset[int]]],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> dict:
    if any(q == 1 for _j, q, _R in constraints):
        raise AssertionError("directly novel candidate has an active q=1 constraint")

    edges: list[dict] = []
    incident: dict[int, set[int]] = collections.defaultdict(set)
    loads: dict[int, Fraction] = collections.defaultdict(Fraction)
    active: set[int] = set()

    for j, q, R in constraints:
        fe = factors[q]
        widths: dict[int, tuple[int, int]] = {}
        support: set[int] = set()
        eid = len(edges)
        for p, a in fe:
            f = fiber_width(q, R, p, a)
            widths[p] = (a, f)
            loads[p] += Fraction(f, p**a)
            incident[p].add(eid)
            support.add(p)
            active.add(p)
        edges.append(
            {
                "j": j,
                "q": q,
                "R": R,
                "factors": fe,
                "widths": widths,
                "support": support,
            }
        )

    for p in active:
        if L % p:
            loads[p] += Fraction(1, p)
        elif r % p == 0:
            raise AssertionError("candidate is not reduced modulo L")

    edge_active = [True] * len(edges)
    queue = collections.deque(sorted(p for p in active if loads[p] < 1))
    queued = set(queue)
    order: list[dict] = []

    while queue:
        p = queue.popleft()
        queued.discard(p)
        if p not in active or loads[p] >= 1:
            continue
        order.append(
            {
                "p": p,
                "load_num": loads[p].numerator,
                "load_den": loads[p].denominator,
            }
        )
        active.remove(p)
        for eid in list(incident[p]):
            if not edge_active[eid]:
                continue
            edge_active[eid] = False
            edge = edges[eid]
            for qprime, (a, f) in edge["widths"].items():
                if qprime in active:
                    loads[qprime] -= Fraction(f, qprime**a)
                    if loads[qprime] < 1 and qprime not in queued:
                        queue.append(qprime)
                        queued.add(qprime)

    residual = [
        edge
        for i, edge in enumerate(edges)
        if edge_active[i] and edge["support"] <= active
    ]
    return {
        "fully_peeled": not active,
        "residual_primes": tuple(sorted(active)),
        "residual_edges": residual,
        "peel_order": order,
    }


def local_value_for_q(
    q: int,
    choices: dict[int, int],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> int:
    a, m = 0, 1
    for p, e in factors[q]:
        pe = p**e
        a, m = crt_coprime(a, m, choices[p] % pe, pe)
    return a


def canonical_kernel_test(
    r: int,
    L: int,
    primes: tuple[int, ...],
    edges: list[dict],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> dict:
    if not primes:
        return {"satisfied": True, "violations": 0}

    max_exp: dict[int, int] = {p: 1 for p in primes}
    unary: dict[int, list[tuple[int, frozenset[int]]]] = collections.defaultdict(list)
    for edge in edges:
        fe = edge["factors"]
        for p, a in fe:
            if p in max_exp:
                max_exp[p] = max(max_exp[p], a)
        if len(fe) == 1:
            p, a = fe[0]
            if p in max_exp:
                unary[p].append((a, edge["R"]))

    choice: dict[int, int] = {}
    for p in primes:
        modulus = p ** max_exp[p]
        reduced_forbidden = None if L % p == 0 else (-r * pow(L, -1, p)) % p

        def bad(v: int) -> bool:
            if reduced_forbidden is not None and v % p == reduced_forbidden:
                return True
            return any(v % (p**a) in R for a, R in unary.get(p, ()))

        if not bad(1):
            choice[p] = 1
        else:
            value = next((v for v in range(modulus) if not bad(v)), None)
            if value is None:
                return {"satisfied": False, "violations": -1, "unary_saturated_prime": p}
            choice[p] = value

    violations = 0
    for edge in edges:
        if local_value_for_q(edge["q"], choice, factors) in edge["R"]:
            violations += 1
    return {
        "satisfied": violations == 0,
        "violations": violations,
        "choice": choice,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])
    traps = [set()] + [trap_set(k) for k in range(1, k_limit + 1)]
    factors = {q: factor_exp(q) for q in range(1, 4 * k_limit, 2)}

    full = 0
    canonical = 0
    size_counts: collections.Counter[int] = collections.Counter()
    signature_counts: collections.Counter[tuple[int, ...]] = collections.Counter()
    max_prime_counts: collections.Counter[int] = collections.Counter()
    violation_counts: collections.Counter[int] = collections.Counter()
    examples: list[dict] = []
    largest_kernel = 0
    largest_prime = 0

    for index, rec in enumerate(witnesses, start=1):
        k, h, t = int(rec["k"]), int(rec["h"]), int(rec["t"])
        r, L, constraints = parameter_constraints(k, h, t, traps)
        peeled = fiber_peel(r, L, constraints, factors)
        primes = peeled["residual_primes"]
        size_counts[len(primes)] += 1
        signature_counts[primes] += 1
        mp = max(primes) if primes else 0
        max_prime_counts[mp] += 1
        if peeled["fully_peeled"]:
            full += 1
            canonical += 1
            violation_counts[0] += 1
        else:
            test = canonical_kernel_test(
                r, L, primes, peeled["residual_edges"], factors
            )
            violation_counts[int(test["violations"])] += 1
            if test["satisfied"]:
                canonical += 1

            if len(examples) < args.examples or len(primes) > largest_kernel or mp > largest_prime:
                examples.append(
                    {
                        "candidate_index": index,
                        "k": k,
                        "h": h,
                        "t": t,
                        "residual_primes": list(primes),
                        "residual_edge_count": len(peeled["residual_edges"]),
                        "canonical_kernel_test": test,
                    }
                )
                examples = examples[-args.examples :]

        largest_kernel = max(largest_kernel, len(primes))
        largest_prime = max(largest_prime, mp)

        if index % 2000 == 0:
            print(
                f"fiber-kernel progress {index}/{len(witnesses)} "
                f"fully_peeled={full} canonical={canonical} "
                f"largest_kernel={largest_kernel} largest_prime={largest_prime}",
                flush=True,
            )

    top_signatures = [
        {"primes": list(sig), "count": count}
        for sig, count in signature_counts.most_common(40)
    ]
    result = {
        "status": "exact augmented fiber shadow-kernel analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "fully_peeled_candidates": full,
        "fully_peeled_fraction": full / len(witnesses),
        "canonical_kernel_satisfied_candidates": canonical,
        "canonical_kernel_satisfied_fraction": canonical / len(witnesses),
        "kernel_size_counts": {str(k): v for k, v in sorted(size_counts.items())},
        "largest_residual_kernel_size": largest_kernel,
        "largest_residual_prime": largest_prime,
        "max_residual_prime_counts": {str(k): v for k, v in sorted(max_prime_counts.items())},
        "canonical_violation_counts": {str(k): v for k, v in sorted(violation_counts.items())},
        "top_kernel_prime_signatures": top_signatures,
        "examples": examples,
        "claim_boundary": (
            "Fiber peeling uses only the reconstructed pullback system and the exact fiber-load theorem, not the stored avoiding witness. "
            "An empty fiber kernel independently proves existence of a reduced avoiding assignment by reverse extension. "
            "The canonical residual-kernel test is a deterministic proof-mining diagnostic; a failed canonical test is not evidence of union coverage."
        ),
    }
    (args.out / "shadow-fiber-kernel-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    n = len(witnesses)
    report = "# Exact fiber shadow kernel\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Fiber kernel empty: **`{full}`** (`{full/n:.3%}`).\n\n"
    report += f"Fiber kernel empty or canonical residual kernel already satisfied: **`{canonical}`** (`{canonical/n:.3%}`).\n\n"
    report += f"Largest residual kernel: `{largest_kernel}` prime coordinates.\n\n"
    report += f"Largest residual prime: `{largest_prime}`.\n\n"
    report += "| residual kernel size | candidates |\n|---:|---:|\n"
    for size, count in sorted(size_counts.items()):
        report += f"| {size} | {count} |\n"
    report += "\nAn empty fiber kernel is an independent constructive existence result from the local fiber-load theorem. Nonempty kernels are the remaining small-prime proof targets.\n"
    (args.out / "shadow-fiber-kernel-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
