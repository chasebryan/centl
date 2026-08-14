#!/usr/bin/env python3
"""Mine the prime-power coordinate core of Type A/B shadow pullbacks.

Input: a direct-shadow-completeness.json bundle produced by
`direct_shadow_completeness_probe.py`.

For every already-certified directly novel candidate this analyzer:

1. reconstructs the exact pulled-back forbidden systems R_j mod q_j;
2. decomposes the total parameter period into odd prime-power coordinates;
3. combines all unary (single-prime-support) constraints on each coordinate;
4. chooses a canonical unary-safe local value, preferring 1;
5. tests the resulting CRT assignment against all multi-prime constraints;
6. if needed, uses the independently certified reduced witness only as a
   *guide* to choose local coordinate values, changing one prime-power
   coordinate at a time until all constraints are satisfied;
7. verifies the repaired assignment directly against every R_j.

The resulting `guided_repair_count` is an explicit upper bound on the Hamming
distance from the canonical unary-safe assignment to a satisfying local
assignment. It is not claimed to be minimal. Because the target witness is
used to guide the repair, this is a proof-mining diagnostic, not an independent
proof of witness existence.
"""
from __future__ import annotations

import argparse
import collections
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


def crt_pair_coprime(a: int, m: int, b: int, n: int) -> tuple[int, int]:
    return (a + (((b - a) * pow(m, -1, n)) % n) * m) % (m * n), m * n


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


def local_residue(
    q: int,
    choice: dict[int, int],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> int:
    a, m = 0, 1
    for p, e in factors[q]:
        pe = p**e
        a, m = crt_pair_coprime(a, m, choice[p] % pe, pe)
    return a


def violated(
    constraints: list[tuple[int, int, frozenset[int]]],
    choice: dict[int, int],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> list[int]:
    return [
        i
        for i, (_j, q, R) in enumerate(constraints)
        if local_residue(q, choice, factors) in R
    ]


def canonical_assignment(
    constraints: list[tuple[int, int, frozenset[int]]],
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> tuple[dict[int, int], dict[int, int], dict[int, list[tuple[int, frozenset[int]]]]]:
    max_exp: dict[int, int] = {}
    unary: dict[int, list[tuple[int, frozenset[int]]]] = collections.defaultdict(list)
    for _j, q, R in constraints:
        fe = factors[q]
        for p, a in fe:
            max_exp[p] = max(max_exp.get(p, 0), a)
        if len(fe) == 1:
            p, a = fe[0]
            unary[p].append((a, R))

    choice: dict[int, int] = {}
    for p, A in max_exp.items():
        modulus = p**A

        def forbidden(v: int) -> bool:
            return any(v % (p**a) in R for a, R in unary.get(p, ()))

        if not forbidden(1):
            value = 1
        else:
            value = next((v for v in range(modulus) if not forbidden(v)), None)
            if value is None:
                raise AssertionError("combined unary constraints cover an entire coordinate")
        choice[p] = value
    return choice, max_exp, unary


def guided_repair(
    constraints: list[tuple[int, int, frozenset[int]]],
    canonical: dict[int, int],
    max_exp: dict[int, int],
    target_s: int,
    factors: dict[int, tuple[tuple[int, int], ...]],
) -> tuple[dict[int, int], list[int], int]:
    choice = dict(canonical)
    target = {p: target_s % (p**A) for p, A in max_exp.items()}
    changed: list[int] = []

    while True:
        bad = violated(constraints, choice, factors)
        if not bad:
            return choice, changed, 0

        i = bad[0]
        _j, q, _R = constraints[i]
        candidates = [p for p, _e in factors[q] if choice[p] != target[p]]
        if not candidates:
            raise AssertionError("certified target witness appears to violate a pulled-back constraint")

        # Prefer a coordinate that participates in the largest number of
        # currently violated constraints. This is deterministic and local.
        scored: list[tuple[int, int]] = []
        for p in candidates:
            score = sum(
                1
                for ii in bad
                if any(pp == p for pp, _e in factors[constraints[ii][1]])
            )
            scored.append((score, p))
        _score, p = max(scored)
        choice[p] = target[p]
        if p not in changed:
            changed.append(p)
        else:
            raise AssertionError("repair attempted to change the same coordinate twice")


def combine_assignment(choice: dict[int, int], max_exp: dict[int, int]) -> tuple[int, int]:
    s, Q = 0, 1
    for p in sorted(choice):
        modulus = p ** max_exp[p]
        s, Q = crt_pair_coprime(s, Q, choice[p] % modulus, modulus)
    return s, Q


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--examples", type=int, default=2)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])
    traps = [set()] + [trap_set(k) for k in range(1, k_limit + 1)]
    factors = {q: factor_exp(q) for q in range(1, 4 * k_limit, 2)}

    repair_counts: collections.Counter[int] = collections.Counter()
    support_counts: collections.Counter[int] = collections.Counter()
    canonical_solved = 0
    records_by_repair: dict[int, list[dict]] = collections.defaultdict(list)
    max_repair = -1

    for index, rec in enumerate(witnesses, start=1):
        k, h, t = int(rec["k"]), int(rec["h"]), int(rec["t"])
        target_s = int(rec["reduced_witness_s"])
        r, L, cons = parameter_constraints(k, h, t, traps)

        for _j, q, _R in cons:
            support_counts[len(factors[q])] += 1

        canonical, max_exp, _unary = canonical_assignment(cons, factors)
        canonical_bad = violated(cons, canonical, factors)
        if not canonical_bad:
            canonical_solved += 1

        repaired, changed, _ = guided_repair(
            cons, canonical, max_exp, target_s, factors
        )
        final_bad = violated(cons, repaired, factors)
        if final_bad:
            raise AssertionError("guided repair did not produce a satisfying local assignment")

        repair = len(changed)
        repair_counts[repair] += 1
        max_repair = max(max_repair, repair)

        if len(records_by_repair[repair]) < args.examples:
            s_local, Q_local = combine_assignment(repaired, max_exp)
            # Check the reconstructed local CRT assignment directly.
            if any(s_local % q in R for _j, q, R in cons):
                raise AssertionError("combined repaired assignment violates a constraint")
            records_by_repair[repair].append(
                {
                    "candidate_index": index,
                    "k": k,
                    "h": h,
                    "t": t,
                    "r": r,
                    "L": L,
                    "certified_target_s": target_s,
                    "guided_repair_count": repair,
                    "changed_prime_coordinates": changed,
                    "repaired_s_mod_Q": s_local,
                    "Q": Q_local,
                }
            )

        if index % 2000 == 0:
            print(
                f"coordinate-core progress {index}/{len(witnesses)} "
                f"canonical={canonical_solved} max_repair={max_repair}",
                flush=True,
            )

    n = len(witnesses)
    cumulative = 0
    repair_table = []
    for repair in sorted(repair_counts):
        count = repair_counts[repair]
        cumulative += count
        repair_table.append(
            {
                "repair": repair,
                "count": count,
                "fraction": count / n,
                "cumulative_fraction": cumulative / n,
            }
        )

    result = {
        "status": "prime-power coordinate proof-mining diagnostic",
        "k_limit": k_limit,
        "direct_novel_candidates": n,
        "canonical_unary_safe_solved": canonical_solved,
        "canonical_unary_safe_fraction": canonical_solved / n,
        "max_guided_repair_count": max_repair,
        "repair_table": repair_table,
        "constraint_support_arity_counts": {str(k): v for k, v in sorted(support_counts.items())},
        "examples_by_repair_count": {str(k): v for k, v in sorted(records_by_repair.items())},
        "claim_boundary": (
            "The guided repair uses each candidate's already-certified reduced witness to choose replacement local coordinate values. "
            "The final repaired assignment is independently checked against every pulled-back constraint, so the repair count is an explicit upper bound on distance from the canonical unary-safe basepoint to a satisfying assignment. "
            "It is not necessarily minimal and is not an independent proof of witness existence."
        ),
    }
    (args.out / "shadow-coordinate-core.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Shadow prime-power coordinate core\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Canonical unary-safe assignment already solves: `{canonical_solved}` (`{canonical_solved/n:.3%}`).\n\n"
    report += f"Maximum guided repair count: **`{max_repair}` prime-power coordinates**.\n\n"
    report += "| repair coordinates | candidates | cumulative |\n|---:|---:|---:|\n"
    for row in repair_table:
        report += f"| {row['repair']} | {row['count']} | {row['cumulative_fraction']:.3%} |\n"
    report += "\nThe repair count is an explicit upper bound, not a proven minimum. The certified reduced witness guides which local values are tried; the repaired assignment is then checked exactly against every earlier pullback constraint.\n"
    (args.out / "shadow-coordinate-core-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
