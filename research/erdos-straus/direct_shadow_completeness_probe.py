#!/usr/bin/env python3
"""Brutal finite attack on Direct-Shadow Completeness.

For every hard-class-compatible Type A/B candidate (k,h,t) through a chosen
k-limit, this program asks a stronger question than the layer-level spectrum
probe:

  If no single earlier layer directly shadows the candidate, can we exhibit
  an integer in the candidate progression that avoids *every* earlier layer?

Such an integer is an exact witness that the candidate is NOT jointly/union
shadowed by the collection of earlier layers.  We also search for a reduced
avoiding class; when gcd(x0,LQ)=1, Dirichlet gives infinitely many primes of
exact depth k in that same candidate.

A bounded search failure is NOT a counterexample. Only an explicit witness is
promoted to a theorem certificate. The purpose is to try to kill the conjecture
and, if it survives a finite range, freeze exact witnesses for every candidate.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


def divisors(n: int) -> list[int]:
    lo, hi = [], []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * u) % L, L


def admissible_pairs(k: int, traps: list[set[int]]) -> list[tuple[int, int]]:
    m = 4 * k - 1
    g = math.gcd(840, m)
    return [
        (h, t)
        for h in HARD
        for t in sorted(traps[k])
        if math.gcd(t, m) == 1 and (t - h) % g == 0
    ]


def parameter_constraints(
    k: int, h: int, t: int, traps: list[set[int]]
) -> tuple[int, int, list[tuple[int, int, frozenset[int]]], list[int]]:
    """Return r,L, forbidden parameter residues, and direct-shadow sources."""
    mk = 4 * k - 1
    cr = crt2(h, 840, t, mk)
    if cr is None:
        raise ValueError("incompatible candidate")
    r, L = cr
    constraints: list[tuple[int, int, frozenset[int]]] = []
    direct: list[int] = []
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
            if len(R) == q:
                direct.append(j)
            constraints.append((j, q, frozenset(R)))
    constraints.sort(key=lambda c: (-(len(c[2]) / c[1]), c[1], c[0]))
    return r, L, constraints, direct


def find_both_witnesses(
    r: int,
    L: int,
    constraints: list[tuple[int, int, frozenset[int]]],
    limit: int,
) -> tuple[tuple[int, int] | None, tuple[int, int, int] | None]:
    """One scan: first avoiding integer and first reduced avoiding class."""
    Q = 1
    for _j, q, _R in constraints:
        Q = math.lcm(Q, q)
    M = L * Q
    integer: tuple[int, int] | None = None
    for s in range(limit + 1):
        if any((s % q) in R for _j, q, R in constraints):
            continue
        x0 = r + L * s
        if integer is None:
            integer = (s, x0)
        if math.gcd(x0, M) == 1:
            return integer, (s, x0, Q)
    return integer, None


def exact_validate(k: int, h: int, t: int, x0: int, traps: list[set[int]]) -> None:
    if x0 % 840 != h:
        raise AssertionError("hard-class residue mismatch")
    if x0 % (4 * k - 1) != t:
        raise AssertionError("target residue mismatch")
    for j in range(1, k):
        if x0 % (4 * j - 1) in traps[j]:
            raise AssertionError(f"witness hits earlier layer {j}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=1000)
    ap.add_argument("--search-limit", type=int, default=1000000)
    ap.add_argument("--centl-count", type=int, default=24)
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    args = ap.parse_args()
    if not (10 <= args.k_limit <= 3000):
        raise SystemExit("--k-limit must be in 10..3000")
    if args.search_limit < 100:
        raise SystemExit("--search-limit must be >= 100")

    args.out.mkdir(parents=True, exist_ok=True)
    traps = [set()] + [trap_set(k) for k in range(1, args.k_limit + 1)]

    counts = {
        "admissible_candidates": 0,
        "directly_shadowed_candidates": 0,
        "direct_novel_candidates": 0,
        "integer_avoiding_witnesses": 0,
        "reduced_avoiding_witnesses": 0,
    }
    witnessed: list[dict] = []
    unresolved_integer: list[dict] = []
    unresolved_reduced: list[dict] = []
    hardest: list[dict] = []

    for k in range(1, args.k_limit + 1):
        for h, t in admissible_pairs(k, traps):
            counts["admissible_candidates"] += 1
            r, L, constraints, direct = parameter_constraints(k, h, t, traps)
            if direct:
                counts["directly_shadowed_candidates"] += 1
                continue
            counts["direct_novel_candidates"] += 1

            iw, rw = find_both_witnesses(r, L, constraints, args.search_limit)
            if iw is None:
                unresolved_integer.append({"k": k, "h": h, "t": t})
                continue

            s_int, x_int = iw
            exact_validate(k, h, t, x_int, traps)
            counts["integer_avoiding_witnesses"] += 1
            rec = {
                "k": k,
                "h": h,
                "t": t,
                "m": 4 * k - 1,
                "r": r,
                "L": L,
                "integer_witness_s": s_int,
                "integer_witness_x": x_int,
            }

            if rw is None:
                unresolved_reduced.append({"k": k, "h": h, "t": t, "integer_witness_s": s_int})
            else:
                s_red, x_red, Q = rw
                exact_validate(k, h, t, x_red, traps)
                if math.gcd(x_red, L * Q) != 1:
                    raise AssertionError("reduced witness is not reduced")
                rec.update({
                    "reduced_witness_s": s_red,
                    "reduced_witness_x": x_red,
                    "Q": Q,
                    "progression_modulus": L * Q,
                })
                counts["reduced_avoiding_witnesses"] += 1
                hardest.append(rec)
            witnessed.append(rec)

        if k % 100 == 0:
            print(
                f"progress k={k} direct_novel={counts['direct_novel_candidates']} "
                f"unresolved_int={len(unresolved_integer)} unresolved_reduced={len(unresolved_reduced)}",
                flush=True,
            )

    hardest.sort(key=lambda r: (-int(r.get("reduced_witness_s", -1)), -r["k"], r["h"], r["t"]))

    verdict = "FINITE RANGE SURVIVES"
    if unresolved_integer:
        verdict = "BOUNDED SEARCH INCONCLUSIVE"
    elif unresolved_reduced:
        verdict = "UNION-SHADOW CONJECTURE SURVIVES; PRIME-REALIZATION SEARCH INCONCLUSIVE"

    result = {
        "status": "finite candidatewise attack on Direct-Shadow Completeness",
        "parameters": {"k_limit": args.k_limit, "search_limit": args.search_limit},
        "hard_classes_mod_840": list(HARD),
        "counts": counts,
        "verdict": verdict,
        "unresolved_integer_candidates": unresolved_integer,
        "unresolved_reduced_candidates": unresolved_reduced,
        "hardest_reduced_witnesses": hardest[:50],
        "witnesses": witnessed,
        "claim_boundary": (
            "If unresolved_integer_candidates is empty, every directly novel candidate in the finite range has an explicit integer avoiding all earlier layers, so no candidate in that range is union-shadowed. "
            "If unresolved_reduced_candidates is also empty, every such candidate has a reduced avoiding progression and hence infinitely many prime realizations by Dirichlet. "
            "No finite range proves the universal conjecture."
        ),
    }
    (args.out / "direct-shadow-completeness.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    centl = [
        "# Auto-generated exact progression identities for the hardest direct-shadow witnesses.",
        "# CENTL certifies algebra only; the independent verifier certifies modular avoidance.",
    ]
    for rec in hardest[: args.centl_count]:
        k, h, t, m, r, L = rec["k"], rec["h"], rec["t"], rec["m"], rec["r"], rec["L"]
        a, b = (r - h) // 840, L // 840
        c, d = (r - t) // m, L // m
        centl.append(f"# k={k} h={h} t={t} reduced_s={rec['reduced_witness_s']}")
        centl.append(f"equal | {r} + {L}*s | {h} + 840*({a} + {b}*s) | s:rational")
        centl.append(f"equal | {r} + {L}*s | {t} + {m}*({c} + {d}*s) | s:rational")
    (args.out / "direct-shadow-hardest.centl").write_text("\n".join(centl) + "\n")

    report = "# Direct-Shadow Completeness finite attack\n\n"
    report += f"Range: `k <= {args.k_limit}`; witness search `0 <= s <= {args.search_limit}`.\n\n"
    report += f"Verdict: **{verdict}**\n\n"
    for key, value in counts.items():
        report += f"- {key.replace('_', ' ')}: `{value}`\n"
    report += f"- unresolved integer candidates: `{len(unresolved_integer)}`\n"
    report += f"- unresolved reduced candidates: `{len(unresolved_reduced)}`\n\n"
    if hardest:
        report += "## Hardest reduced witnesses\n\n| k | h | t | s | x |\n|---:|---:|---:|---:|---:|\n"
        for rec in hardest[:20]:
            report += f"| {rec['k']} | {rec['h']} | {rec['t']} | {rec['reduced_witness_s']} | {rec['reduced_witness_x']} |\n"
    report += "\nAn explicit integer witness disproves joint/union coverage for that candidate. A reduced witness additionally gives an infinite exact-depth prime progression by Dirichlet. Finite survival is evidence, not a universal proof.\n"
    (args.out / "direct-shadow-completeness-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
