#!/usr/bin/env python3
"""Analyze the exact six-consecutive Lane-I corridor residual.

The first six classified Lane-I shifts are k=3,7,11,15,19,23.  Writing
P=(p-1)/4, their shifted integers are exactly P+1,...,P+6.

This tool consumes a standalone CBX hit-relation TSV (k<TAB>p), regenerates
the Mordell-hard prime universe up to --hi independently, subtracts the six
classified hit sets, and profiles the surviving finite residual.  It also
records two theorem-mining diagnostics:

* the exact k=23 Branch-A/Branch-B classification from
  K23-TWO-TARGET-FILTER.md;
* the k=27 quadratic-residue/nonresidue structure.  Since hard p have
  P == 0 (mod 6), C_27=P+7 == 1 (mod 3), so the total valuation of prime
  factors q == 2 (mod 3) is even.  Those are exactly the quadratic
  nonresidue unit classes modulo 27.

All output is finite evidence.  No finite residual profile is a universal
shift bound or a proof of Erdős-Straus.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path
from typing import Iterable

HARD = (1, 121, 169, 289, 361, 529)
CORRIDOR = (3, 7, 11, 15, 19, 23)
QR23 = {pow(x, 2, 23) for x in range(1, 23)}
QR27 = {pow(x, 2, 27) for x in range(1, 27) if math.gcd(x, 27) == 1}


def sieve_flags(n: int) -> bytearray:
    if n < 1:
        return bytearray(n + 1)
    bs = bytearray(b"\x01") * (n + 1)
    bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return bs


def hard_primes(hi: int) -> list[int]:
    bs = sieve_flags(hi)
    return [p for p in range(2, hi + 1) if bs[p] and p % 840 in HARD]


def trial_primes(n: int) -> list[int]:
    bs = sieve_flags(n)
    return [p for p in range(2, n + 1) if bs[p]]


def factor(n: int, trial: Iterable[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for q in trial:
        if q * q > x:
            break
        if x % q:
            continue
        e = 0
        while x % q == 0:
            x //= q
            e += 1
        out[q] = e
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def load_hits(path: Path, hi: int) -> dict[int, set[int]]:
    hits: dict[int, set[int]] = collections.defaultdict(set)
    with path.open("r", encoding="utf-8") as fh:
        for line_no, raw in enumerate(fh, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) != 2:
                raise SystemExit(f"{path}:{line_no}: expected k p")
            k, p = map(int, parts)
            if p <= hi:
                hits[k].add(p)
    return hits


def k23_branch(fac: dict[int, int]) -> tuple[str, int, int]:
    """Return the exact combined-miss branch label for a known k=23 miss."""
    if all((q % 23) in QR23 for q in fac):
        return "A", 0, 0

    thin = fac.get(2, 0) == 1 and fac.get(3, 0) == 1
    e_plus = 0
    e_minus = 0
    if thin:
        for q, e in fac.items():
            if q in (2, 3):
                continue
            r = q % 23
            if r in QR23:
                if r != 1:
                    thin = False
                    break
            elif r == 5:
                e_plus += e
            elif r == 14:
                e_minus += e
            else:
                thin = False
                break

    if thin and (e_plus, e_minus) in {(0, 0), (1, 0), (0, 1), (1, 1)}:
        return "B", e_plus, e_minus
    return "unclassified", e_plus, e_minus


def first_later_hit(p: int, hits: dict[int, set[int]]) -> int | None:
    later = [k for k, ps in hits.items() if k > 23 and p in ps]
    return min(later) if later else None


def analyze(path: Path, hi: int) -> dict[str, object]:
    hits = load_hits(path, hi)
    hard = hard_primes(hi)
    hard_set = set(hard)

    for k in CORRIDOR:
        if k not in hits:
            raise SystemExit(f"relation file has no k={k} rows")

    corridor_cover = set().union(*(hits[k] for k in CORRIDOR)) & hard_set
    residual = sorted(hard_set - corridor_cover)

    max_c = (hi + 27) // 4
    trial = trial_primes(math.isqrt(max_c) + 1)

    next_hist: collections.Counter[str] = collections.Counter()
    hard_hist: collections.Counter[str] = collections.Counter()
    k23_hist: collections.Counter[str] = collections.Counter()
    k27_hist: collections.Counter[str] = collections.Counter()
    k27_nrval_hist: collections.Counter[str] = collections.Counter()
    rows: list[dict[str, object]] = []

    for p in residual:
        P = (p - 1) // 4
        if P % 6 != 0:
            raise SystemExit(f"hard-prime wheel invariant failed at p={p}")

        nxt = first_later_hit(p, hits)
        next_hist[str(nxt) if nxt is not None else "none"] += 1
        hard_hist[str(p % 840)] += 1

        fac23 = factor(P + 6, trial)
        branch, e_plus, e_minus = k23_branch(fac23)
        if branch == "unclassified":
            raise SystemExit(f"p={p}: six-shift residual violates exact k=23 miss theorem")
        k23_key = branch if branch == "A" else f"B({e_plus},{e_minus})"
        k23_hist[k23_key] += 1

        c27 = P + 7
        if c27 % 3 != 1:
            raise SystemExit(f"p={p}: C27 mod-3 invariant failed")
        fac27 = factor(c27, trial)
        nr_val = sum(e for q, e in fac27.items() if (q % 27) not in QR27)
        if nr_val % 2:
            raise SystemExit(f"p={p}: C27 nonresidue valuation parity failed")
        k27_nrval_hist[str(nr_val)] += 1

        pure_qr27 = nr_val == 0
        hit27 = p in hits.get(27, set())
        k27_key = (
            "hit/nonpure" if hit27 and not pure_qr27 else
            "hit/pure" if hit27 else
            "miss/pure" if pure_qr27 else
            "miss/nonpure"
        )
        k27_hist[k27_key] += 1

        rows.append({
            "p": p,
            "hard_class": p % 840,
            "P": P,
            "next_hit_k": nxt,
            "k23_branch": k23_key,
            "k27_hit": hit27,
            "k27_pure_qr": pure_qr27,
            "k27_nonresidue_valuation": nr_val,
        })

    return {
        "analysis": "six-consecutive-lane-I-corridor-v1",
        "hi": hi,
        "corridor_shifts": list(CORRIDOR),
        "hard_primes": len(hard),
        "corridor_covered": len(corridor_cover),
        "residual": len(residual),
        "residual_fraction": len(residual) / len(hard) if hard else None,
        "next_hit_histogram": dict(sorted(next_hist.items(), key=lambda kv: (kv[0] == "none", int(kv[0]) if kv[0] != "none" else 10**18))),
        "hard_class_histogram": dict(sorted(hard_hist.items(), key=lambda kv: int(kv[0]))),
        "k23_combined_miss_branches": dict(sorted(k23_hist.items())),
        "k27_qr_split": dict(sorted(k27_hist.items())),
        "k27_nonresidue_valuation_histogram": dict(sorted(k27_nrval_hist.items(), key=lambda kv: int(kv[0]))),
        "exact_invariants": {
            "hard_prime_P_mod_6": 0,
            "C27_mod_3": 1,
            "QR27_equals_units_1_mod_3": QR27 == {x for x in range(1, 27) if math.gcd(x, 27) == 1 and x % 3 == 1},
            "C27_nonresidue_valuation_even": True,
        },
        "rows": rows,
        "claim": "exact finite residual profile; no universal finite-shift claim",
    }


def print_text(r: dict[str, object]) -> None:
    print("six-consecutive Lane-I corridor residual")
    print(f"X={r['hi']} hard={r['hard_primes']} covered={r['corridor_covered']} residual={r['residual']}")
    print(f"next hits: {r['next_hit_histogram']}")
    print(f"k23 branches: {r['k23_combined_miss_branches']}")
    print(f"k27 QR split: {r['k27_qr_split']}")
    print(f"k27 NR valuation: {r['k27_nonresidue_valuation_histogram']}")
    print("warning: finite profile only")


def main() -> int:
    ap = argparse.ArgumentParser(description="analyze the exact six-shift Lane-I corridor residual")
    ap.add_argument("relations", type=Path)
    ap.add_argument("--hi", type=int, required=True)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if not args.relations.is_file():
        raise SystemExit(f"no relation file: {args.relations}")
    if args.hi < 23:
        raise SystemExit("--hi must be >= 23")

    report = analyze(args.relations, args.hi)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
