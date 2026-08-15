#!/usr/bin/env python3
"""Exact finite falsifier for the corrected pointwise-primitive q=3 obstruction.

A directly novel candidate can only acquire a genuinely new q=3 forbidden
class from a pointwise-primitive trap witness (Q3-POINTWISE-ABSORPTION.md).
Weak descendants add no new classes (Q3-WEAK-REDUNDANCY.md), and the exact
Dirichlet parameter domain at 3 is all of Z/3Z because 3|L.

Therefore a necessary q=3 obstruction is a union of pointwise-primitive
pullbacks covering all three parameter classes 0,1,2.  This program searches
that exact necessary obstruction on every admissible hard Type A/B target
candidate through the selected k-limit.

A zero-cover finite result is a theorem-certificate only for the tested range.
It is not universal DSC-P, Lopez-all-primes, or Erdos-Straus.
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
def trap_set(j: int) -> frozenset[int]:
    m = 4 * j - 1
    return frozenset(
        r
        for e in divisors(j)
        for r in ((-e) % m, (-4 * e) % m)
    )


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
    u = 0 if nn == 1 else (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * u) % L, L


def factor_map(n: int) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    p = 2
    while p * p <= x:
        if x % p == 0:
            a = 0
            while x % p == 0:
                x //= p
                a += 1
            out[p] = a
        p = 3 if p == 2 else p + 2
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


FM840 = factor_map(840)


def lcm_factor_map(a: dict[int, int], b: dict[int, int]) -> dict[int, int]:
    out = dict(a)
    for p, e in b.items():
        out[p] = max(out.get(p, 0), e)
    return out


def divisors_from_factor_map(fm: dict[int, int]) -> list[int]:
    out = [1]
    for p, e in fm.items():
        powers = [p**a for a in range(e + 1)]
        out = [d * pe for d in out for pe in powers]
    return out


def integer_from_factor_map(fm: dict[int, int]) -> int:
    out = 1
    for p, e in fm.items():
        out *= p**e
    return out


def q3_layers(k: int) -> tuple[int, list[int]]:
    """Return L and every earlier j with m_j/gcd(L,m_j)=3.

    If nu=v3(L), exact q=3 means v3(m_j)=nu+1 and all other prime
    exponents of m_j are absorbed by L.  Thus

        m_j = 3^(nu+1) * d,

    where d divides the prime-to-3 part of L.
    """
    M = 4 * k - 1
    fmL = lcm_factor_map(FM840, factor_map(M))
    L = integer_from_factor_map(fmL)
    nu = fmL.get(3, 0)
    rest = {p: e for p, e in fmL.items() if p != 3}
    three = 3 ** (nu + 1)
    rows: list[int] = []
    for d in divisors_from_factor_map(rest):
        m = three * d
        if m % 4 != 3:
            continue
        j = (m + 1) // 4
        if 1 <= j < k:
            # Defensive exact check of the divisor construction.
            if m // math.gcd(L, m) != 3:
                raise AssertionError((k, j, L, m))
            rows.append(j)
    return L, sorted(set(rows))


@lru_cache(maxsize=None)
def pointwise_primitive_traps(j: int) -> tuple[int, ...]:
    """Hard-compatible trap residues not absorbed by any frozen divisor parent.

    For q_j=3, n_j=m_j/3 divides L.  If an actual trap u reduces into T_i
    for any m_i|n_j, Q3-POINTWISE-ABSORPTION makes the candidate directly
    shadowed by i.  Hard candidates have r=1 mod 3, so only u=1 mod 3 can
    align with a q=3 pullback and need be retained.
    """
    m = 4 * j - 1
    if m % 3:
        return ()
    n = m // 3
    parents = [
        (d, (d + 1) // 4)
        for d in divisors(n)
        if d >= 3 and d % 4 == 3
    ]
    out: list[int] = []
    for u in trap_set(j):
        if u % 3 != 1:
            continue
        absorbed = False
        for mi, i in parents:
            if u % mi in trap_set(i):
                absorbed = True
                break
        if not absorbed:
            out.append(u)
    return tuple(sorted(out))


def admissible_candidates(k: int, L: int) -> list[tuple[int, int, int]]:
    M = 4 * k - 1
    g = math.gcd(840, M)
    out: list[tuple[int, int, int]] = []
    for h in HARD:
        for t in trap_set(k):
            if math.gcd(t, M) != 1:
                continue
            if (t - h) % g:
                continue
            cr = crt2(h, 840, t, M)
            if cr is None:
                raise AssertionError((k, h, t))
            r, L2 = cr
            if L2 != L:
                raise AssertionError((k, L, L2))
            out.append((h, t, r))
    return out


def primitive_mask(r: int, L: int, j: int) -> int:
    """Forbidden q=3 classes contributed by pointwise-primitive traps."""
    m = 4 * j - 1
    n = m // 3
    if m // math.gcd(L, m) != 3:
        raise AssertionError((j, L))
    lam = (L // n) % 3
    if lam == 0:
        raise AssertionError((j, L, n))
    inv = pow(lam, -1, 3)
    mask = 0
    for u in pointwise_primitive_traps(j):
        if (u - r) % n:
            continue
        delta = ((u - r) % m) // n
        a = (delta * inv) % 3
        mask |= 1 << a
    return mask


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=100000)
    ap.add_argument("--out", type=Path, default=Path("q3-primitive-output"))
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    counts: collections.Counter[str] = collections.Counter()
    union_hist: collections.Counter[int] = collections.Counter()
    primitive_row_hits: collections.Counter[int] = collections.Counter()
    first_two_digit = None
    first_three_or_more_hits = None
    first_full_cover = None
    cover_examples: list[dict] = []
    multi_examples: list[dict] = []

    for k in range(2, args.k_limit + 1):
        L, rows_all = q3_layers(k)
        rows = [j for j in rows_all if pointwise_primitive_traps(j)]
        counts["target_depths"] += 1
        counts["q3_layers_generated"] += len(rows_all)
        counts["q3_layers_with_primitive_traps"] += len(rows)
        if not rows:
            continue

        for h, t, r in admissible_candidates(k, L):
            counts["admissible_candidates_checked"] += 1
            mask = 0
            used: list[dict] = []
            for j in rows:
                jm = primitive_mask(r, L, j)
                if not jm:
                    continue
                primitive_row_hits[j] += 1
                mask |= jm
                used.append(
                    {
                        "j": j,
                        "mask": jm,
                        "classes": [a for a in range(3) if jm & (1 << a)],
                    }
                )

            union_hist[mask] += 1
            digits = mask.bit_count()
            if digits >= 2 and first_two_digit is None:
                first_two_digit = {
                    "k": k, "h": h, "t": t, "r": r, "L": L,
                    "mask": mask, "rows": used,
                }
            if len(used) >= 3 and first_three_or_more_hits is None:
                first_three_or_more_hits = {
                    "k": k, "h": h, "t": t, "r": r, "L": L,
                    "mask": mask, "rows": used,
                }
            if len(used) >= 3 and len(multi_examples) < args.examples:
                multi_examples.append(
                    {"k": k, "h": h, "t": t, "mask": mask, "rows": used}
                )
            if mask == 0b111:
                counts["full_primitive_q3_covers"] += 1
                rec = {
                    "k": k, "h": h, "t": t, "r": r, "L": L,
                    "rows": used,
                }
                if first_full_cover is None:
                    first_full_cover = rec
                if len(cover_examples) < args.examples:
                    cover_examples.append(rec)

        if k % 5000 == 0:
            print(
                f"progress k={k} candidates={counts['admissible_candidates_checked']} "
                f"full={counts['full_primitive_q3_covers']}",
                flush=True,
            )

    result = {
        "status": "finite exact pointwise-primitive q=3 cover falsifier",
        "k_limit": args.k_limit,
        "counts": dict(counts),
        "union_mask_histogram": {str(k): v for k, v in sorted(union_hist.items())},
        "first_two_digit_union": first_two_digit,
        "first_three_or_more_primitive_rows": first_three_or_more_hits,
        "first_full_primitive_q3_cover": first_full_cover,
        "cover_examples": cover_examples,
        "multi_row_examples": multi_examples,
        "top_primitive_row_hits": primitive_row_hits.most_common(30),
        "claim_boundary": (
            "A zero full-cover result proves only that no pointwise-primitive q=3 "
            "necessary obstruction occurs in the tested admissible finite range. "
            "Strong absorption, weak redundancy and pointwise absorption justify "
            "the primitive filter. This is not universal DSC-P, Lopez-all-primes, "
            "or Erdos-Straus."
        ),
    }
    (args.out / "q3-primitive-cover.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = [
        "# Pointwise-primitive q=3 cover finite attack",
        "",
        f"Range: `k <= {args.k_limit}`.",
        "",
        f"Admissible candidates actually requiring primitive-q3 evaluation: `{counts['admissible_candidates_checked']}`.",
        f"Full primitive q=3 covers: **`{counts['full_primitive_q3_covers']}`**.",
        "",
        "Union-mask histogram (`1,2,4` are one digit; `3,5,6` are two digits; `7` is a full cover):",
        "",
        "```text",
    ]
    for mask, count in sorted(union_hist.items()):
        report.append(f"{mask}: {count}")
    report.extend(["```", ""])
    if first_two_digit is not None:
        report.append(
            "First two-digit primitive union: "
            f"`k={first_two_digit['k']}, h={first_two_digit['h']}, t={first_two_digit['t']}`."
        )
    if first_three_or_more_hits is not None:
        report.append(
            "First candidate with at least three primitive q=3 rows: "
            f"`k={first_three_or_more_hits['k']}, h={first_three_or_more_hits['h']}, "
            f"t={first_three_or_more_hits['t']}, mask={first_three_or_more_hits['mask']}`."
        )
    report.extend([
        "",
        "A two-digit union is not an obstruction in the corrected Dirichlet domain: the third class remains available because `3|L`. A genuine local q=3 obstruction requires mask `7`.",
        "",
    ])
    (args.out / "q3-primitive-cover-report.md").write_text("\n".join(report))
    print("\n".join(report))


if __name__ == "__main__":
    main()
