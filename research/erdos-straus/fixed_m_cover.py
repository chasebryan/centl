#!/usr/bin/env python3
"""Fixed-M Type-II covering search for Mordell-hard classes.

Independent of the corridor program. For a fixed multiplier M with 210 | M,
every hard prime lies in one of finitely many residue classes r mod 4M.
On each such class the shift k = (-r) mod 4M is constant, M divides (p+k)/4,
and Type II holds uniformly if -1 lies in the signed box of M modulo k.

A complete hit on every reduced hard subclass would prove prime Erdős–Straus.
This program only decides the finite covering question for given M.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import Counter


HARD = (1, 121, 169, 289, 361, 529)


def signed_box(factors: dict[int, int], mod: int) -> set[int] | None:
    if mod <= 1:
        return None
    reach = {1 % mod}
    for r, e in factors.items():
        if math.gcd(r, mod) != 1:
            return None
        powers = [pow(r, z, mod) for z in range(-e, e + 1)]
        nxt = set()
        for x in reach:
            for y in powers:
                nxt.add((x * y) % mod)
        reach = nxt
    return reach


def factor_from_exponents(exps: dict[int, int]) -> dict[int, int]:
    return {p: e for p, e in exps.items() if e > 0}


def hard_subclasses(mod: int) -> list[int]:
    out = []
    for r in range(1, mod, 2):
        if r % 840 in HARD and math.gcd(r, mod) == 1:
            out.append(r)
    return out


def class_report(M: int, factors: dict[int, int]) -> dict:
    mod = 4 * M
    rows = []
    hits = 0
    misses = []
    skipped = 0
    for r in hard_subclasses(mod):
        k = (-r) % mod
        if k == 0:
            k = mod
        if k % 4 != 3:
            skipped += 1
            continue
        box = signed_box(factors, k)
        if box is None:
            misses.append({"r": r, "k": k, "reason": "gcd(M,k)>1"})
            continue
        hit = ((-1) % k) in box
        rows.append(
            {
                "r": r,
                "r_mod840": r % 840,
                "k": k,
                "box": len(box),
                "hit": hit,
            }
        )
        if hit:
            hits += 1
        else:
            misses.append({"r": r, "k": k, "r_mod840": r % 840, "box": len(box)})
    return {
        "M": M,
        "mod": mod,
        "factors": factors,
        "subclasses": len(rows) + skipped,
        "checked": len(rows),
        "hits": hits,
        "misses": len(misses),
        "skipped_bad_k": skipped,
        "miss_examples": misses[:12],
        "hit_examples": [row for row in rows if row["hit"]][:8],
    }


def primorial_powers(primes: list[int], max_exp: list[int]) -> list[tuple[int, dict[int, int]]]:
    ranges = [range(0, e + 1) for e in max_exp]
    out = []
    for ex in itertools.product(*ranges):
        fac = {p: e for p, e in zip(primes, ex) if e}
        if not fac:
            continue
        M = 1
        for p, e in fac.items():
            M *= p**e
        out.append((M, fac))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["scan", "one"], default="scan")
    ap.add_argument("--M", type=int, default=210)
    args = ap.parse_args()

    if args.mode == "one":
        # factor M by trial
        x = args.M
        fac: dict[int, int] = {}
        d = 2
        while d * d <= x:
            while x % d == 0:
                fac[d] = fac.get(d, 0) + 1
                x //= d
            d += 1 if d == 2 else 2
        if x > 1:
            fac[x] = fac.get(x, 0) + 1
        rep = class_report(args.M, fac)
        print(json.dumps(rep, indent=2, sort_keys=True))
        return

    # Require 210 | M so that hard classes split cleanly.
    primes = [2, 3, 5, 7, 11, 13]
    # exponents chosen so the search stays finite and exact
    grid = primorial_powers(primes, [6, 4, 3, 2, 1, 1])
    summaries = []
    complete = []
    best = None
    for M, fac in grid:
        if M % 210 != 0:
            continue
        if M > 30030 * 4:
            continue
        rep = class_report(M, fac)
        rec = {
            "M": M,
            "factors": fac,
            "checked": rep["checked"],
            "hits": rep["hits"],
            "misses": rep["misses"],
            "hit_rate": (rep["hits"] / rep["checked"]) if rep["checked"] else None,
        }
        summaries.append(rec)
        if rep["checked"] and rep["misses"] == 0:
            complete.append(rec)
        if best is None or rec["hits"] > best["hits"] or (
            rec["hits"] == best["hits"] and rec["misses"] < best["misses"]
        ):
            best = rec

    summaries.sort(key=lambda s: (-s["hits"], s["misses"], s["M"]))
    print(
        json.dumps(
            {
                "candidates_with_210_dividing_M": len(summaries),
                "complete_covers": complete,
                "best": best,
                "top": summaries[:20],
                "claim_boundary": (
                    "finite covering check only; a complete cover would prove "
                    "prime ES, a miss does not disprove ES"
                ),
            },
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
