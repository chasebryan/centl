#!/usr/bin/env python3
"""Finite theorem-mining analysis of negative-Legendre k=47 misses.

Consumes a CBX standalone hit-relation TSV and asks which earlier classified
corridor shifts cover the hard primes that miss k=47 with (47/p)=-1.
No finite cover is promoted to a universal theorem.
"""
from __future__ import annotations

import argparse
import itertools
import json
from collections import Counter, defaultdict
from pathlib import Path

PRIOR = (3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43)


def load(path: Path, hi: int | None):
    hits: dict[int, set[int]] = defaultdict(set)
    universe: set[int] = set()
    with path.open("r", encoding="utf-8") as fh:
        for line_no, raw in enumerate(fh, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) != 2:
                raise SystemExit(f"{path}:{line_no}: expected 'k p'")
            k, p = map(int, parts)
            if hi is None or p <= hi:
                hits[k].add(p)
                universe.add(p)
    return hits, universe


def legendre47_negative(p: int) -> bool:
    return pow(p % 47, 23, 47) == 46


def minimum_cover(targets: set[int], hits: dict[int, set[int]]):
    for r in range(1, len(PRIOR) + 1):
        for comb in itertools.combinations(PRIOR, r):
            if targets <= set().union(*(hits[k] for k in comb)):
                return list(comb)
    return None


def analyze(path: Path, hi: int | None):
    hits, universe = load(path, hi)
    if 47 not in hits:
        raise SystemExit("relation file has no k=47 rows")
    for k in PRIOR:
        if k not in hits:
            raise SystemExit(f"relation file has no k={k} rows")

    target = {p for p in universe if p not in hits[47] and legendre47_negative(p)}
    first = Counter()
    for p in target:
        earlier = [k for k in PRIOR if p in hits[k]]
        first[str(min(earlier)) if earlier else "none"] += 1

    remaining = set(target)
    ordered = []
    for k in PRIOR:
        before = len(remaining)
        caught = remaining & hits[k]
        remaining -= caught
        ordered.append({
            "k": k,
            "before": before,
            "newly_caught": len(caught),
            "after": len(remaining),
        })

    min_cover = minimum_cover(target, hits)
    return {
        "analysis": "k47-negative-legendre-corridor-v1",
        "hi": hi,
        "hard_universe_from_relation_union": len(universe),
        "negative_legendre_k47_misses": len(target),
        "first_prior_hit_histogram": dict(sorted(first.items(), key=lambda kv: (kv[0] == "none", int(kv[0]) if kv[0] != "none" else 10**9))),
        "ordered_residual": ordered,
        "residual_after_prior_corridor": len(remaining),
        "minimum_finite_cover_size": len(min_cover) if min_cover else None,
        "minimum_finite_cover_example": min_cover,
        "claim": "exact finite relation-set analysis only; no universal cross-shift containment theorem",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("relations", type=Path)
    ap.add_argument("--hi", type=int)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.relations, args.hi)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"negative-Legendre k47 misses: {report['negative_legendre_k47_misses']}")
        for row in report["ordered_residual"]:
            print(f"k={row['k']}: {row['before']} -> {row['after']} (caught {row['newly_caught']})")
        print(f"minimum finite cover: {report['minimum_finite_cover_example']}")
        print("warning: finite theorem-mining evidence only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
