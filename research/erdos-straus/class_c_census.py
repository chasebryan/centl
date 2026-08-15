#!/usr/bin/env python3
"""Exact finite census for Operator-02 Class-C / N^act structure.

Input is a completed direct-shadow certificate directory containing
`direct-shadow-completeness.json`.  The script reconstructs fixed-negative
layers, Operator-02's active subcore, exact pullbacks, fiber peeling, and a
bounded residual-selector diagnostic without consulting the stored reduced
witness to decide any of those structures.

Finite output is proof-mining evidence only.  It does not prove universal
Direct-Shadow Completeness, Lopez Type A/B coverage, or Erdos-Straus.
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


def layer_profile(
    k: int,
    mfac: list[dict[int, int]],
) -> tuple[list[int], list[int], dict[int, int]]:
    fixed_primes = set(F840) | set(mfac[k])
    vL = {
        p: max(F840.get(p, 0), mfac[k].get(p, 0))
        for p in fixed_primes
    }
    fixed: list[int] = []
    active: list[int] = []
    for j in range(1, k):
        if all(a % 2 == 0 or p in fixed_primes for p, a in mfac[j].items()):
            fixed.append(j)
            if any(a > vL.get(p, 0) for p, a in mfac[j].items()):
                active.append(j)
    return fixed, active, vL


def pullback_constraint(
    r: int,
    L: int,
    j: int,
    traps: list[set[int]],
) -> tuple[int, frozenset[int]]:
    m = 4 * j - 1
    g = math.gcd(L, m)
    q = m // g
    R: set[int] = set()
    if q == 1:
        if any((u - r) % g == 0 for u in traps[j]):
            R.add(0)
    else:
        inv = pow((L // g) % q, -1, q)
        for u in traps[j]:
            if (u - r) % g == 0:
                R.add((((u - r) // g) * inv) % q)
    return q, frozenset(R)


def parameter_constraints(
    k: int,
    r: int,
    L: int,
    traps: list[set[int]],
) -> list[tuple[int, int, frozenset[int]]]:
    out: list[tuple[int, int, frozenset[int]]] = []
    for j in range(1, k):
        q, R = pullback_constraint(r, L, j, traps)
        if R:
            out.append((j, q, R))
    return out


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
) -> tuple[tuple[int, ...], list[dict]]:
    edges: list[dict] = []
    incident: dict[int, set[int]] = collections.defaultdict(set)
    loads: dict[int, Fraction] = collections.defaultdict(Fraction)
    active: set[int] = set()

    for j, q, R in constraints:
        if q == 1:
            raise AssertionError("directly novel candidate has active q=1 trap")
        widths: dict[int, tuple[int, int]] = {}
        support: set[int] = set()
        eid = len(edges)
        for p, a in factors[q]:
            f = fiber_width(q, R, p, a)
            widths[p] = (a, f)
            loads[p] += Fraction(f, p**a)
            incident[p].add(eid)
            support.add(p)
            active.add(p)
        edges.append({"j": j, "q": q, "R": R, "widths": widths, "support": support})

    for p in active:
        if L % p:
            loads[p] += Fraction(1, p)
        elif r % p == 0:
            raise AssertionError("candidate not reduced on progression modulus")

    edge_active = [True] * len(edges)
    queue = collections.deque(sorted(p for p in active if loads[p] < 1))
    queued = set(queue)
    while queue:
        p = queue.popleft()
        queued.discard(p)
        if p not in active or loads[p] >= 1:
            continue
        active.remove(p)
        for eid in list(incident[p]):
            if not edge_active[eid]:
                continue
            edge_active[eid] = False
            for qprime, (a, f) in edges[eid]["widths"].items():
                if qprime in active:
                    loads[qprime] -= Fraction(f, qprime**a)
                    if loads[qprime] < 1 and qprime not in queued:
                        queue.append(qprime)
                        queued.add(qprime)

    residual = [
        edge for i, edge in enumerate(edges)
        if edge_active[i] and edge["support"] <= active
    ]
    return tuple(sorted(active)), residual


def bounded_selector(
    r: int,
    L: int,
    primes: tuple[int, ...],
    residual: list[dict],
    bound: int,
) -> int | None:
    values = [0]
    for a in range(1, bound + 1):
        values.extend((a, -a))
    for s in values:
        if any(s % edge["q"] in edge["R"] for edge in residual):
            continue
        if any(L % p and (r + L * s) % p == 0 for p in primes):
            continue
        return s
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--selector-bound", type=int, default=64)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    factors = {n: factor_exp(n) for n in range(1, 4 * k_limit, 2)}
    mfac = [dict()] + [dict(factors[4 * k - 1]) for k in range(1, k_limit + 1)]
    traps = [set()] + [trap_set(k) for k in range(1, k_limit + 1)]
    profiles = {k: layer_profile(k, mfac) for k in {int(w["k"]) for w in witnesses}}

    n_hist: collections.Counter[int] = collections.Counter()
    active_hist: collections.Counter[int] = collections.Counter()
    single_q: collections.Counter[int] = collections.Counter()
    single_source: collections.Counter[str] = collections.Counter()
    single_R_size: collections.Counter[int] = collections.Counter()
    single_reduced_safe: collections.Counter[int] = collections.Counter()
    single_kernel: collections.Counter[tuple[int, ...]] = collections.Counter()
    single_selector_radius: collections.Counter[int] = collections.Counter()
    residual_edge_categories: collections.Counter[str] = collections.Counter()

    single_total = 0
    single_fiber_empty = 0
    single_nonempty = 0
    single_active_survives_fiber = 0
    single_selector_unresolved = 0
    single_class_b = 0
    single_mixed = 0
    single_min_reduced_safe: int | None = None
    examples: list[dict] = []

    for index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        fixed, active, vL = profiles[k]
        N = [j for j in fixed if jacobi(r, 4 * j - 1) == -1]
        Nset = set(N)
        Nact = [j for j in active if j in Nset]
        n_hist[len(N)] += 1
        active_hist[len(Nact)] += 1

        if len(Nact) != 1:
            continue

        single_total += 1
        j0 = Nact[0]
        q0, R0 = pullback_constraint(r, L, j0, traps)
        single_q[q0] += 1
        single_R_size[len(R0)] += 1

        class_a: list[int] = []
        class_b: list[int] = []
        for p, a in mfac[j0].items():
            old = vL.get(p, 0)
            if a <= old:
                continue
            if old > 0:
                class_a.append(p)
            else:
                class_b.append(p)
        if class_a and class_b:
            source_kind = "mixed"
            single_mixed += 1
        elif class_b:
            source_kind = "B-only"
            single_class_b += 1
        else:
            source_kind = "A-only"
        single_source[source_kind] += 1

        q_primes = [p for p, _a in factors[q0]]
        reduced_safe = 0
        for s in range(q0):
            if s in R0:
                continue
            if any(L % p and (r + L * s) % p == 0 for p in q_primes):
                continue
            reduced_safe += 1
        single_reduced_safe[reduced_safe] += 1
        single_min_reduced_safe = (
            reduced_safe if single_min_reduced_safe is None
            else min(single_min_reduced_safe, reduced_safe)
        )

        constraints = parameter_constraints(k, r, L, traps)
        primes, residual = fiber_peel(r, L, constraints, factors)
        if not primes:
            single_fiber_empty += 1
            continue

        single_nonempty += 1
        single_kernel[primes] += 1
        residual_js = {int(edge["j"]) for edge in residual}
        if j0 in residual_js:
            single_active_survives_fiber += 1

        for edge in residual:
            j = int(edge["j"])
            if j == j0:
                residual_edge_categories["unique-active-fixed-negative"] += 1
            elif j in Nset:
                residual_edge_categories["other-fixed-negative"] += 1
            elif j in fixed:
                residual_edge_categories["fixed-positive"] += 1
            else:
                residual_edge_categories["nonfixed"] += 1

        selector = bounded_selector(r, L, primes, residual, args.selector_bound)
        if selector is None:
            single_selector_unresolved += 1
        else:
            single_selector_radius[abs(selector)] += 1

        if len(examples) < 40 or j0 in residual_js or selector is None:
            examples.append({
                "candidate_index": index,
                "k": k,
                "h": int(rec["h"]),
                "t": int(rec["t"]),
                "N_size": len(N),
                "unique_active_j": j0,
                "q": q0,
                "R": sorted(R0),
                "source_kind": source_kind,
                "class_A_primes": class_a,
                "class_B_primes": class_b,
                "residual_primes": list(primes),
                "residual_edge_count": len(residual),
                "active_layer_survives_fiber": j0 in residual_js,
                "selector": selector,
            })

    result = {
        "status": "exact finite Class-C / active fixed-negative census",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "fixed_negative_size_histogram": {str(k): v for k, v in sorted(n_hist.items())},
        "active_fixed_negative_size_histogram": {str(k): v for k, v in sorted(active_hist.items())},
        "inactive_only_character_failures": sum(
            1 for rec in witnesses
            if False
        ),
        "single_active": {
            "candidates": single_total,
            "q_histogram": {str(k): v for k, v in sorted(single_q.items())},
            "valuation_source_histogram": dict(sorted(single_source.items())),
            "class_B_candidates": single_class_b,
            "mixed_source_candidates": single_mixed,
            "pullback_R_size_histogram": {str(k): v for k, v in sorted(single_R_size.items())},
            "reduced_safe_residue_count_histogram": {str(k): v for k, v in sorted(single_reduced_safe.items())},
            "minimum_reduced_safe_residues_mod_q": single_min_reduced_safe,
            "fiber_empty": single_fiber_empty,
            "fiber_nonempty": single_nonempty,
            "active_layer_survives_fiber": single_active_survives_fiber,
            "active_layer_removed_before_residual": single_nonempty - single_active_survives_fiber,
            "residual_kernel_signatures": [
                {"primes": list(sig), "count": count}
                for sig, count in single_kernel.most_common()
            ],
            "residual_edge_categories": dict(sorted(residual_edge_categories.items())),
            "selector_bound": args.selector_bound,
            "selector_unresolved": single_selector_unresolved,
            "selector_radius_histogram": {str(k): v for k, v in sorted(single_selector_radius.items())},
            "maximum_selector_radius": max(single_selector_radius, default=0),
        },
        "examples": examples[-80:],
        "claim_boundary": (
            "All counts are exact for the supplied finite candidate bundle. "
            "No finite absence of exceptions proves universal DSC-P. "
            "N^act is a character/valuation object; residual fiber edges may also come from nonfixed layers."
        ),
    }
    # Exact inactive-only count is derivable from the two histograms only after
    # candidatewise intersection, so compute it in a second cheap pass.
    inactive_only = 0
    for rec in witnesses:
        k = int(rec["k"]); r = int(rec["r"])
        fixed, active, _vL = profiles[k]
        Nset = {j for j in fixed if jacobi(r, 4 * j - 1) == -1}
        if Nset and not any(j in Nset for j in active):
            inactive_only += 1
    result["inactive_only_character_failures"] = inactive_only

    (args.out / "class-c-census.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    sa = result["single_active"]
    report = "# Class-C active-core census\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{len(witnesses)}`.\n\n"
    report += f"Character-negative but `N^act=0` (inactive-only): **`{inactive_only}`**.\n\n"
    report += f"Exactly one active fixed-negative layer: **`{single_total}`**.\n\n"
    report += f"Single-active valuation sources: `{sa['valuation_source_histogram']}`.\n\n"
    report += f"Single-active q values: `{sa['q_histogram']}`.\n\n"
    report += f"Minimum reduced-safe residues modulo the unique active q: **`{single_min_reduced_safe}`**.\n\n"
    report += f"Fiber-empty single-active candidates: **`{single_fiber_empty}`**.\n\n"
    report += f"Nonempty fiber kernels: **`{single_nonempty}`**.\n\n"
    report += f"Unique active fixed-negative layer survives into the residual fiber kernel: **`{single_active_survives_fiber}`**.\n\n"
    report += f"Bounded-selector unresolved among nonempty single-active kernels: **`{single_selector_unresolved}`**; maximum observed radius **`{max(single_selector_radius, default=0)}`**.\n\n"
    report += "Residual edge source counts:\n\n```text\n"
    for key, value in sorted(residual_edge_categories.items()):
        report += f"{key}: {value}\n"
    report += "```\n\n"
    report += (
        "Interpretation: `N^act` and the fiber residual are different resolutions. "
        "A unique active fixed-negative layer can be peeled away while nonfixed exact layers remain. "
        "Therefore a universal C1 proof must coordinate character/valuation structure with the nonfixed residual system rather than treating `N^act` alone as the whole obstruction.\n"
    )
    (args.out / "class-c-census-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
