#!/usr/bin/env python3
"""Independent verifier for q3_primitive_cover_probe.py.

Differences from the primary implementation:
- constructs L directly with math.lcm;
- enumerates candidate q=3 moduli as divisors of 3L and then applies the exact
  quotient test, rather than using the valuation/exponent shape directly;
- reconstructs pointwise-primitive traps by repeated parent-set subtraction;
- decides the q=3 mask by evaluating x(a)=r+La for a=0,1,2 directly, rather
  than solving the affine pullback equation.

This is still a finite verifier, not a universal theorem.
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


def divisors_from_factor_map(fm: dict[int, int]) -> list[int]:
    ds = [1]
    for p, e in fm.items():
        old = ds
        ds = []
        pe = 1
        for _a in range(e + 1):
            ds.extend(d * pe for d in old)
            pe *= p
    return ds


def crt_independent(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    delta = b - a
    if delta % g:
        return None
    m1 = m // g
    n1 = n // g
    if n1 == 1:
        return a % m, m
    step = (delta // g) * pow(m1, -1, n1)
    step %= n1
    mod = m * n1
    return (a + m * step) % mod, mod


def q3_layers_independent(k: int) -> tuple[int, list[int]]:
    M = 4 * k - 1
    L = math.lcm(840, M)
    fm = factor_map(3 * L)
    rows: list[int] = []
    for m in divisors_from_factor_map(fm):
        if m % 4 != 3:
            continue
        j = (m + 1) // 4
        if not (1 <= j < k):
            continue
        if m // math.gcd(L, m) == 3:
            rows.append(j)
    return L, sorted(set(rows))


@lru_cache(maxsize=None)
def primitive_traps_independent(j: int) -> frozenset[int]:
    m = 4 * j - 1
    if m % 3:
        return frozenset()
    n = m // 3
    candidates = {u for u in trap_set(j) if u % 3 == 1}
    for mi in divisors(n):
        if mi < 3 or mi % 4 != 3:
            continue
        i = (mi + 1) // 4
        parent = trap_set(i)
        candidates = {u for u in candidates if u % mi not in parent}
        if not candidates:
            break
    return frozenset(candidates)


def target_candidates(k: int, L: int):
    M = 4 * k - 1
    g = math.gcd(840, M)
    for h in HARD:
        for t in trap_set(k):
            if math.gcd(t, M) != 1 or (t - h) % g:
                continue
            cr = crt_independent(h, 840, t, M)
            if cr is None:
                raise AssertionError((k, h, t))
            r, mod = cr
            if mod != L:
                raise AssertionError((k, L, mod))
            yield h, t, r


def direct_mask(r: int, L: int, j: int) -> int:
    m = 4 * j - 1
    prim = primitive_traps_independent(j)
    mask = 0
    for a in range(3):
        if (r + L * a) % m in prim:
            mask |= 1 << a
    return mask


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=100000)
    ap.add_argument("--out", type=Path, default=Path("q3-primitive-output"))
    ap.add_argument("--compare-primary", action="store_true")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    counts: collections.Counter[str] = collections.Counter()
    hist: collections.Counter[int] = collections.Counter()
    first_two = None
    first_three_rows = None
    first_cover = None

    for k in range(2, args.k_limit + 1):
        L, rows_all = q3_layers_independent(k)
        rows = [j for j in rows_all if primitive_traps_independent(j)]
        counts["target_depths"] += 1
        if not rows:
            continue
        for h, t, r in target_candidates(k, L):
            counts["admissible_candidates_checked"] += 1
            union = 0
            used = []
            for j in rows:
                jm = direct_mask(r, L, j)
                if jm:
                    union |= jm
                    used.append((j, jm))
            hist[union] += 1
            if union.bit_count() >= 2 and first_two is None:
                first_two = [k, h, t, union, used]
            if len(used) >= 3 and first_three_rows is None:
                first_three_rows = [k, h, t, union, used]
            if union == 7:
                counts["full_primitive_q3_covers"] += 1
                if first_cover is None:
                    first_cover = [k, h, t, used]

        if k % 10000 == 0:
            print(
                f"verify progress k={k} candidates={counts['admissible_candidates_checked']} "
                f"full={counts['full_primitive_q3_covers']}",
                flush=True,
            )

    result = {
        "status": "independent direct-evaluation verifier for primitive q=3 cover scan",
        "k_limit": args.k_limit,
        "counts": dict(counts),
        "union_mask_histogram": {str(k): v for k, v in sorted(hist.items())},
        "first_two_digit_union": first_two,
        "first_three_or_more_primitive_rows": first_three_rows,
        "first_full_primitive_q3_cover": first_cover,
        "verdict": "VERIFIED" if counts["full_primitive_q3_covers"] == 0 else "COUNTEREXAMPLE_CANDIDATE",
    }

    if args.compare_primary:
        primary_path = args.out / "q3-primitive-cover.json"
        primary = json.loads(primary_path.read_text())
        mismatches = []
        if int(primary["k_limit"]) != args.k_limit:
            mismatches.append("k_limit")
        pc = primary["counts"]
        for key in ("admissible_candidates_checked", "full_primitive_q3_covers"):
            if int(pc.get(key, 0)) != int(counts.get(key, 0)):
                mismatches.append(key)
        if primary["union_mask_histogram"] != result["union_mask_histogram"]:
            mismatches.append("union_mask_histogram")
        result["primary_mismatches"] = mismatches
        result["primary_comparison"] = "MATCH" if not mismatches else "MISMATCH"
        if mismatches:
            result["verdict"] = "MISMATCH"

    (args.out / "q3-primitive-cover-independent-verifier.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
