#!/usr/bin/env python3
"""Exact prime-power kernel analyzer for Type A/B shadow pullbacks.

Reads `direct-shadow-completeness.json`, reconstructs every directly novel
candidate, and applies the exact local-load peeling lemma from SHADOW-KERNEL.md.

The analyzer uses the augmented load that includes the one local residue needed
to keep `r + Ls` coprime to each parameter prime p not dividing L. Therefore a
candidate whose augmented kernel peels completely receives an *independent
constructive existence proof* of a reduced avoiding parameter assignment at
the level of the peeling lemma; it does not use the stored reduced witness to
decide peelability.

Candidates with a residual kernel are not failures. They are the finite
small-prime cores on which stronger local reasoning is still required.
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


def peel_kernel(
    r: int,
    L: int,
    constraints: list[tuple[int, int, frozenset[int]]],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> dict:
    """Apply exact augmented local-load peeling with rational arithmetic."""

    # Directly novel candidates should never contain q=1 active constraints.
    if any(q == 1 for _j, q, _R in constraints):
        raise AssertionError("directly novel candidate contains a q=1 complete constraint")

    edges: list[dict] = []
    incident: dict[int, set[int]] = collections.defaultdict(set)
    active_primes: set[int] = set()
    loads: dict[int, Fraction] = collections.defaultdict(Fraction)

    for edge_id, (j, q, R) in enumerate(constraints):
        fe = factors[q]
        support = {p for p, _a in fe}
        if not support:
            continue
        edge = {
            "j": j,
            "q": q,
            "R_size": len(R),
            "factors": dict(fe),
            "support": support,
        }
        edges.append(edge)
        eid = len(edges) - 1
        for p, a in fe:
            active_primes.add(p)
            incident[p].add(eid)
            loads[p] += Fraction(len(R), p**a)

    # Reducedness contributes one forbidden class mod p whenever p does not
    # divide L. If p|L, admissibility implies r is already nonzero mod p.
    reduced_extra: dict[int, Fraction] = {}
    for p in active_primes:
        if L % p == 0:
            if r % p == 0:
                raise AssertionError("admissible candidate is not reduced modulo L")
            reduced_extra[p] = Fraction(0, 1)
        else:
            reduced_extra[p] = Fraction(1, p)
            loads[p] += Fraction(1, p)

    active_edges = [True] * len(edges)
    active = set(active_primes)
    peel_order: list[dict] = []

    # Queue all currently peelable primes. Loads only decrease as edges vanish.
    queue = collections.deque(sorted(p for p in active if loads[p] < 1))
    queued = set(queue)

    while queue:
        p = queue.popleft()
        queued.discard(p)
        if p not in active or loads[p] >= 1:
            continue

        peel_order.append(
            {
                "p": p,
                "load_num": loads[p].numerator,
                "load_den": loads[p].denominator,
            }
        )
        active.remove(p)

        for eid in list(incident[p]):
            if not active_edges[eid]:
                continue
            active_edges[eid] = False
            edge = edges[eid]
            for qprime in edge["support"]:
                if qprime not in active:
                    continue
                a = edge["factors"][qprime]
                loads[qprime] -= Fraction(edge["R_size"], qprime**a)
                if loads[qprime] < 1 and qprime not in queued:
                    queue.append(qprime)
                    queued.add(qprime)

    residual_edges = [
        edges[i]
        for i, is_active in enumerate(active_edges)
        if is_active and edges[i]["support"] <= active
    ]

    residual_loads = {
        p: {"num": loads[p].numerator, "den": loads[p].denominator}
        for p in sorted(active)
    }

    return {
        "fully_peeled": not active,
        "peeled_coordinates": len(peel_order),
        "residual_prime_count": len(active),
        "residual_primes": sorted(active),
        "residual_edge_count": len(residual_edges),
        "residual_loads": residual_loads,
        "peel_order": peel_order,
    }


def primes_upto(n: int) -> list[int]:
    if n < 2:
        return []
    b = bytearray(b"\x01") * (n + 1)
    b[0:2] = b"\x00\x00"
    for p in range(2, math.isqrt(n) + 1):
        if b[p]:
            start = p * p
            b[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [i for i in range(2, n + 1) if b[i]]


def universal_bound(k_limit: int, traps: list[set[int]]) -> dict:
    bad: list[dict] = []
    first_guaranteed: int | None = None
    values: list[dict] = []
    for p in primes_upto(4 * k_limit):
        if p == 2:
            continue
        total = 1 + sum(
            len(traps[j])
            for j in range(1, k_limit)
            if (4 * j - 1) % p == 0
        )
        B = Fraction(total, p)
        values.append({"p": p, "num": B.numerator, "den": B.denominator, "lt_one": B < 1})
        if B >= 1:
            bad.append({"p": p, "num": B.numerator, "den": B.denominator})
    if bad:
        last_bad = bad[-1]["p"]
        first_guaranteed = next((v["p"] for v in values if v["p"] > last_bad and v["lt_one"]), None)
    return {
        "nonuniversally_peeled_primes": bad,
        "first_prime_above_last_bad": first_guaranteed,
        "last_bad_prime": bad[-1]["p"] if bad else None,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--examples", type=int, default=20)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])
    traps = [set()] + [trap_set(k) for k in range(1, k_limit + 1)]
    factors = {q: factor_exp(q) for q in range(1, 4 * k_limit, 2)}

    full = 0
    kernel_size_counts: collections.Counter[int] = collections.Counter()
    max_prime_counts: collections.Counter[int] = collections.Counter()
    kernel_signatures: collections.Counter[tuple[int, ...]] = collections.Counter()
    examples: list[dict] = []
    largest_kernel = -1
    largest_max_prime = -1

    for index, rec in enumerate(witnesses, start=1):
        k, h, t = int(rec["k"]), int(rec["h"]), int(rec["t"])
        r, L, cons = parameter_constraints(k, h, t, traps)
        result = peel_kernel(r, L, cons, factors)

        if result["fully_peeled"]:
            full += 1
        size = int(result["residual_prime_count"])
        kernel_size_counts[size] += 1
        signature = tuple(result["residual_primes"])
        kernel_signatures[signature] += 1
        maxp = max(signature) if signature else 0
        max_prime_counts[maxp] += 1

        if size > largest_kernel or maxp > largest_max_prime:
            largest_kernel = max(largest_kernel, size)
            largest_max_prime = max(largest_max_prime, maxp)
            examples.append(
                {
                    "candidate_index": index,
                    "k": k,
                    "h": h,
                    "t": t,
                    "kernel": result,
                }
            )
            examples = examples[-args.examples :]

        if index % 2000 == 0:
            print(
                f"shadow-kernel progress {index}/{len(witnesses)} "
                f"full={full} largest_kernel={largest_kernel} max_prime={largest_max_prime}",
                flush=True,
            )

    top_signatures = [
        {"primes": list(sig), "count": count}
        for sig, count in kernel_signatures.most_common(30)
    ]

    ub = universal_bound(k_limit, traps)
    result = {
        "status": "exact augmented prime-power shadow-kernel analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "fully_peeled_candidates": full,
        "fully_peeled_fraction": full / len(witnesses),
        "kernel_size_counts": {str(k): v for k, v in sorted(kernel_size_counts.items())},
        "max_residual_prime_counts": {str(k): v for k, v in sorted(max_prime_counts.items())},
        "largest_residual_kernel_size": largest_kernel,
        "largest_residual_prime": largest_max_prime,
        "top_kernel_prime_signatures": top_signatures,
        "record_examples": examples,
        "universal_candidate_independent_bound": ub,
        "claim_boundary": (
            "A fully peeled row is a direct consequence of the exact local-load lemma and proves existence of a reduced avoiding assignment without using the stored witness. "
            "A residual kernel is not evidence of union coverage; it only marks the part not decided by this peeling criterion."
        ),
    }
    (args.out / "shadow-kernel-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Exact prime-power shadow kernel\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{len(witnesses)}`.\n\n"
    report += f"Fully resolved by augmented peeling alone: **`{full}`** (`{full/len(witnesses):.3%}`).\n\n"
    report += f"Largest residual kernel: `{largest_kernel}` prime coordinates.\n\n"
    report += f"Largest residual prime observed: `{largest_max_prime}`.\n\n"
    report += f"Universal first-bound last bad prime: `{ub['last_bad_prime']}`; first prime above it with B_p(k)<1: `{ub['first_prime_above_last_bad']}`.\n\n"
    report += "A residual kernel is not a counterexample. It is the small-prime core left after every coordinate certified peelable by the exact local-load lemma has been removed.\n"
    (args.out / "shadow-kernel-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
