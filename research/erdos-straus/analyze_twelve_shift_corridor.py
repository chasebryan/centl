#!/usr/bin/env python3
"""Exact finite census for the twelve consecutive Lane-I shifts k=3..47."""
from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path

SHIFTS = tuple(range(3, 48, 4))


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
    for k in SHIFTS:
        if k not in hits:
            raise SystemExit(f"relation file has no k={k} rows")
    return hits, universe


def analyze(path: Path, hi: int | None):
    hits, universe = load(path, hi)
    remaining = set(universe)
    rows = []
    for k in SHIFTS:
        caught = remaining & hits[k]
        remaining -= caught
        rows.append({"k": k, "translate_index": (k + 1) // 4, "new_hits": len(caught), "residual": len(remaining)})

    next_hist = Counter()
    for p in remaining:
        later = [k for k, ps in hits.items() if k > 47 and p in ps]
        next_hist[str(min(later)) if later else "none"] += 1

    return {
        "analysis": "twelve-consecutive-two-target-corridor-v1",
        "hi": hi,
        "hard_universe_from_relation_union": len(universe),
        "shifts": list(SHIFTS),
        "translate_indices": list(range(1, 13)),
        "progression": rows,
        "residual": len(remaining),
        "residual_primes": sorted(remaining),
        "next_hit_histogram": dict(sorted(next_hist.items(), key=lambda kv: (kv[0] == "none", int(kv[0]) if kv[0] != "none" else 10**9))),
        "claim": "finite exact relation-set census; fixed-shift classifications are separate range-free theorems",
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
        print(f"hard universe: {report['hard_universe_from_relation_union']}")
        for row in report["progression"]:
            print(f"k={row['k']:2d} (P+{row['translate_index']:2d}): +{row['new_hits']:5d}, residual={row['residual']:5d}")
        print(f"survivors: {report['residual_primes']}")
        print("warning: finite census only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
