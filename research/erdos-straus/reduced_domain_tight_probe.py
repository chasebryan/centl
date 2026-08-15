#!/usr/bin/env python3
"""Corrected reduced-domain probe for the Erdős-Straus Type A/B pullback system.

The primary Direct-Shadow Completeness code correctly uses

    gcd(r + L*s, L*Q) == 1

for Dirichlet reducedness.  Some later C1/C2/CN proof-mining notes instead
restricted the parameter itself to units modulo Q.  Those conditions are not
equivalent in general.

This probe uses the exact affine reduced parameter domain.  It focuses on the
small q<=9 shared cluster, where the lcm is tiny enough to enumerate exactly.
A reported tight-cluster failure is then checked against the exact direct-shadow
criterion.  Finite zero-failure output is a certificate only for the configured
range; it is not a universal proof of DSC-P or Erdős-Straus.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from functools import lru_cache
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


@lru_cache(maxsize=None)
def trap_set(k: int) -> frozenset[int]:
    m = 4 * k - 1
    return frozenset(
        r
        for e in divisors(k)
        for r in ((-e) % m, (-4 * e) % m)
    )


def prime_divisors(n: int) -> tuple[int, ...]:
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
    return tuple(out)


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm = m // g
    nn = n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * u) % L, L


def admissible_candidates(k: int) -> list[tuple[int, int, int, int]]:
    m = 4 * k - 1
    g = math.gcd(840, m)
    out: list[tuple[int, int, int, int]] = []
    for h in HARD:
        for t in trap_set(k):
            if (t - h) % g:
                continue
            cr = crt2(h, 840, t, m)
            if cr is None:
                raise AssertionError("compatible target CRT unexpectedly failed")
            r, L = cr
            if math.gcd(r, L) != 1:
                raise AssertionError("admissible target base is not coprime to L")
            out.append((h, t, r, L))
    return out


def pullback(r: int, L: int, j: int) -> tuple[int, int, frozenset[int]]:
    m = 4 * j - 1
    g = math.gcd(L, m)
    q = m // g
    if q == 1:
        R = frozenset({0}) if (r % m) in trap_set(j) else frozenset()
        return g, q, R
    inv = pow((L // g) % q, -1, q)
    R: set[int] = set()
    for u in trap_set(j):
        if (u - r) % g == 0:
            R.add((((u - r) // g) * inv) % q)
    return g, q, frozenset(R)


def reduced_parameter_ok(s: int, r: int, L: int, Q: int) -> bool:
    """Exact equivalence to gcd(r+Ls, LQ)=1 under gcd(r,L)=1."""
    if math.gcd(r, L) != 1:
        raise AssertionError("reduced-domain theorem requires gcd(r,L)=1")
    for p in prime_divisors(Q):
        if L % p == 0:
            continue
        bad = (-r * pow(L, -1, p)) % p
        if s % p == bad:
            return False
    return True


def exact_reduced_check(s: int, r: int, L: int, Q: int) -> bool:
    return math.gcd(r + L * s, L * Q) == 1


def tight_layers(L: int, k: int, q_max: int) -> list[tuple[int, int]]:
    """Enumerate q<=q_max layers from the exact divisor condition m_j | qL."""
    found: dict[int, int] = {}
    for q in range(3, q_max + 1, 2):
        for m in divisors(q * L):
            if m % 4 != 3:
                continue
            j = (m + 1) // 4
            if not (1 <= j < k):
                continue
            actual = m // math.gcd(L, m)
            if actual == q:
                found[j] = q
    return sorted(found.items())


def tight_escape(
    r: int,
    L: int,
    layers: list[tuple[int, int]],
) -> tuple[bool, int, int | None, list[tuple[int, int, frozenset[int]]]]:
    constraints: list[tuple[int, int, frozenset[int]]] = []
    Q = 1
    for j, q in layers:
        _g, actual, R = pullback(r, L, j)
        if actual != q:
            raise AssertionError("tight layer quotient changed")
        if R:
            constraints.append((j, q, R))
            Q = math.lcm(Q, q)

    if not constraints:
        return True, 1, 0, constraints

    for s in range(Q):
        if not reduced_parameter_ok(s, r, L, Q):
            continue
        if any((s % q) in R for _j, q, R in constraints):
            continue
        if not exact_reduced_check(s, r, L, Q):
            raise AssertionError("affine reduced-domain theorem disagrees with gcd")
        return True, Q, s, constraints
    return False, Q, None, constraints


def direct_shadow_sources(r: int, L: int, k: int) -> list[dict]:
    """Exact full-fibre direct-shadow criterion for one candidate."""
    out: list[dict] = []
    for j in range(1, k):
        m = 4 * j - 1
        g = math.gcd(L, m)
        q = m // g
        T = trap_set(j)
        if q > len(T):
            continue
        base = r % g
        fibre = [(base + n * g) % m for n in range(q)]
        if all(value in T for value in fibre):
            out.append({"j": j, "q": q})
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=3000)
    ap.add_argument("--q-max", type=int, default=9)
    ap.add_argument("--out", type=Path, default=Path("reduced-domain-tight-output"))
    ap.add_argument("--examples", type=int, default=40)
    args = ap.parse_args()

    if args.k_limit < 2:
        raise SystemExit("--k-limit must be >= 2")
    if args.q_max < 3 or args.q_max % 2 == 0:
        raise SystemExit("--q-max must be odd and >=3")

    args.out.mkdir(parents=True, exist_ok=True)

    counts = collections.Counter()
    active_count_hist = collections.Counter()
    full_failures: list[dict] = []
    novel_failures: list[dict] = []
    first_q3_triple_cover: dict | None = None
    maximum_Q = 1

    for k in range(2, args.k_limit + 1):
        m = 4 * k - 1
        L = math.lcm(840, m)
        layers = tight_layers(L, k, args.q_max)
        if not layers:
            continue

        for h, t, r, candidate_L in admissible_candidates(k):
            if candidate_L != L:
                raise AssertionError("candidate L mismatch")
            counts["candidates_with_tight_layers"] += 1
            ok, Q, s, constraints = tight_escape(r, L, layers)
            maximum_Q = max(maximum_Q, Q)
            active_count_hist[len(constraints)] += 1
            if ok:
                counts["tight_escapes"] += 1
                continue

            counts["tight_full_domain_failures"] += 1
            shadows = direct_shadow_sources(r, L, k)
            rec = {
                "k": k,
                "h": h,
                "t": t,
                "r": r,
                "L": L,
                "Q": Q,
                "constraints": [
                    {"j": j, "q": q, "R": sorted(R)}
                    for j, q, R in constraints
                ],
                "direct_shadows": shadows,
            }
            if len(full_failures) < args.examples:
                full_failures.append(rec)
            if not shadows:
                counts["direct_novel_tight_failures"] += 1
                if len(novel_failures) < args.examples:
                    novel_failures.append(rec)
            else:
                counts["tight_failures_already_direct_shadowed"] += 1

            q3_rows = [
                (j, R)
                for j, q, R in constraints
                if q == 3 and R
            ]
            q3_union = set().union(*(set(R) for _j, R in q3_rows)) if q3_rows else set()
            if first_q3_triple_cover is None and q3_union == {0, 1, 2}:
                first_q3_triple_cover = rec

        if k % 500 == 0:
            print(
                f"progress k={k} tight={counts['candidates_with_tight_layers']} "
                f"fail={counts['tight_full_domain_failures']} "
                f"novel_fail={counts['direct_novel_tight_failures']}",
                flush=True,
            )

    result = {
        "status": "exact corrected reduced-domain tight-cluster probe",
        "k_limit": args.k_limit,
        "q_max": args.q_max,
        "counts": dict(counts),
        "maximum_tight_period_Q": maximum_Q,
        "active_constraint_count_histogram": {
            str(k): v for k, v in sorted(active_count_hist.items())
        },
        "full_domain_failure_examples": full_failures,
        "direct_novel_failure_examples": novel_failures,
        "first_q3_three_class_cover": first_q3_triple_cover,
        "claim_boundary": (
            "The probe enumerates the exact affine Dirichlet-reduced parameter domain, not the parameter unit group. "
            "A tight failure with no direct-shadow source would be a finite counterexample to the corresponding tight-cluster DSC implication. "
            "Zero such failures in a finite range is not a universal proof."
        ),
    }
    (args.out / "reduced-domain-tight.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = [
        "# Corrected reduced-domain tight-cluster probe",
        "",
        f"Range: `k <= {args.k_limit}`, tight quotient bound: `q <= {args.q_max}`.",
        "",
        f"Candidates with tight layers: `{counts['candidates_with_tight_layers']}`.",
        f"Corrected-domain tight escapes: `{counts['tight_escapes']}`.",
        f"Full corrected-domain tight failures: `{counts['tight_full_domain_failures']}`.",
        f"Failures already directly shadowed: `{counts['tight_failures_already_direct_shadowed']}`.",
        f"Directly novel tight failures: `{counts['direct_novel_tight_failures']}`.",
        f"Maximum enumerated tight period Q: `{maximum_Q}`.",
        "",
    ]
    if first_q3_triple_cover is not None:
        report.extend(
            [
                "## First observed three-class q=3 cover",
                "",
                f"`k={first_q3_triple_cover['k']}`, `h={first_q3_triple_cover['h']}`, `t={first_q3_triple_cover['t']}`.",
                f"Direct shadows: `{first_q3_triple_cover['direct_shadows']}`.",
                "",
            ]
        )
    report.extend(
        [
            "The exact reduced parameter condition is `gcd(r+Ls,LQ)=1`. "
            "Primes already dividing L impose no restriction on s; free primes exclude one affine residue modulo p.",
            "",
        ]
    )
    (args.out / "reduced-domain-tight-report.md").write_text("\n".join(report))
    print("\n".join(report))


if __name__ == "__main__":
    main()
