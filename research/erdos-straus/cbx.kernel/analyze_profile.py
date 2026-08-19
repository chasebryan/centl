#!/usr/bin/env python3
"""Analyze exact JSON emitted by cbx-profile-i."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def div(a: int, b: int) -> float | None:
    return a / b if b else None


def load_profile(path: str) -> dict[str, Any]:
    if path == "-":
        obj = json.load(sys.stdin)
    else:
        with Path(path).open("r", encoding="utf-8") as fh:
            obj = json.load(fh)
    if obj.get("kernel") != "cbx.kernel" or obj.get("mode") != "profile-I":
        raise SystemExit("input is not a cbx.kernel profile-I report")
    if not isinstance(obj.get("shifts"), list) or not obj["shifts"]:
        raise SystemExit("profile has no shift rows")
    return obj


def enrich(row: dict[str, Any]) -> dict[str, Any]:
    k = int(row["k"])
    active = int(row["active_visits"])
    c_candidates = int(row["c_candidates"])
    coprime_skips = int(row["coprime_skips"])
    fact = int(row["factorizations"])
    hits = int(row["first_hits"])
    spec = row.get("spectrum_hits") or {}
    A, B, C = (int(spec.get(name, 0)) for name in ("A", "B", "C"))
    if A + B + C != hits:
        raise SystemExit(f"k={k}: spectrum hit sum does not equal first_hits")
    if fact + coprime_skips > active:
        raise SystemExit(f"k={k}: impossible active/factorization accounting")
    return {
        "k": k,
        "active_visits": active,
        "c_candidates": c_candidates,
        "coprime_skips": coprime_skips,
        "factorizations": fact,
        "first_hits": hits,
        "spectrum_hits": {"A": A, "B": B, "C": C},
        "first_hit_fraction_of_active": div(hits, active),
        "first_hits_per_factorization": div(hits, fact),
        "first_hits_per_C_candidate": div(hits, c_candidates),
        "factorizations_per_first_hit": div(fact, hits),
        "C_candidates_per_first_hit": div(c_candidates, hits),
        "C_candidates_per_factorization": div(c_candidates, fact),
        "spectrum_share": {
            "A": div(A, hits),
            "B": div(B, hits),
            "C": div(C, hits),
        },
    }


def summarize(obj: dict[str, Any], top: int) -> dict[str, Any]:
    rows = [enrich(r) for r in obj["shifts"]]
    ks = [r["k"] for r in rows]
    if ks != sorted(ks) or any(k % 4 != 3 for k in ks):
        raise SystemExit("profile shifts are not ordered admissible k values")

    hard = int(obj["hard_primes"])
    covered = int(obj["covered_hard_primes"])
    residual = int(obj["residual_hard_primes"])
    total_hits = sum(r["first_hits"] for r in rows)
    if covered + residual != hard:
        raise SystemExit("profile cover accounting does not close")
    if total_hits != covered:
        raise SystemExit("sum of per-shift first hits does not equal covered target count")

    productive = [r for r in rows if r["first_hits"] > 0]
    dead_factoring = [r for r in rows if r["factorizations"] > 0 and r["first_hits"] == 0]
    zero_active = [r for r in rows if r["active_visits"] == 0]

    by_hits = sorted(rows, key=lambda r: (r["first_hits"], -r["k"]), reverse=True)
    by_shift_eff = sorted(
        productive,
        key=lambda r: (r["first_hits_per_factorization"] or 0.0, r["first_hits"], -r["k"]),
        reverse=True,
    )
    by_generation_density = sorted(
        productive,
        key=lambda r: (r["first_hits_per_C_candidate"] or 0.0, r["first_hits"], -r["k"]),
        reverse=True,
    )
    dead_by_work = sorted(dead_factoring, key=lambda r: (r["factorizations"], r["k"]), reverse=True)

    cumulative = 0
    depth_quantiles: dict[str, int | None] = {"p50": None, "p90": None, "p99": None}
    thresholds = {"p50": 0.50, "p90": 0.90, "p99": 0.99}
    for r in rows:
        cumulative += r["first_hits"]
        if covered:
            for name, frac in thresholds.items():
                if depth_quantiles[name] is None and cumulative / covered >= frac:
                    depth_quantiles[name] = r["k"]

    spectrum_totals = {
        name: sum(r["spectrum_hits"][name] for r in rows)
        for name in ("A", "B", "C")
    }

    totals = {
        "active_visits": sum(r["active_visits"] for r in rows),
        "c_candidates": sum(r["c_candidates"] for r in rows),
        "coprime_skips": sum(r["coprime_skips"] for r in rows),
        "factorizations": sum(r["factorizations"] for r in rows),
        "first_hits": total_hits,
        "spectrum_hits": spectrum_totals,
    }

    return {
        "analysis": "cbx-lane-I-shift-profile-v1",
        "kernel": obj["kernel"],
        "version": obj.get("version"),
        "lo": int(obj["lo"]),
        "hi": int(obj["hi"]),
        "i_max": int(obj["i_max"]),
        "hard_primes": hard,
        "covered_hard_primes": covered,
        "residual_hard_primes": residual,
        "productive_shifts": len(productive),
        "dead_factoring_shifts": len(dead_factoring),
        "zero_active_shifts": len(zero_active),
        "first_hit_depth_quantiles": depth_quantiles,
        "totals": totals,
        "aggregate": {
            "first_hits_per_factorization": div(total_hits, totals["factorizations"]),
            "first_hits_per_C_candidate": div(total_hits, totals["c_candidates"]),
            "C_candidates_per_factorization": div(totals["c_candidates"], totals["factorizations"]),
        },
        "top_first_hit_count": by_hits[:top],
        "top_shift_major_efficiency": by_shift_eff[:top],
        "top_C_major_generation_density": by_generation_density[:top],
        "largest_finite_dead_work": dead_by_work[:top],
        "productive_k": [r["k"] for r in productive],
        "dead_factoring_k": [r["k"] for r in dead_factoring],
        "rows": rows,
        "claim": (
            "finite profile only; rankings identify empirical theorem/generator targets, "
            "not universally optimal scheduling rules"
        ),
    }


def print_text(r: dict[str, Any]) -> None:
    print("cbx.kernel Lane-I per-shift profile")
    print(f"range: [{r['lo']},{r['hi']}]  K_I={r['i_max']}  hard={r['hard_primes']}")
    print(f"covered={r['covered_hard_primes']} residual={r['residual_hard_primes']}  "
          f"productive shifts={r['productive_shifts']} dead-factor shifts={r['dead_factoring_shifts']}")
    print(f"first-hit depth quantiles: {r['first_hit_depth_quantiles']}")
    print()
    print("top first-hit shifts")
    for row in r["top_first_hit_count"][:12]:
        print(f"  k={row['k']:<4} hits={row['first_hits']:<8} active={row['active_visits']:<8} "
              f"fact={row['factorizations']:<8} C={row['c_candidates']}")
    print()
    print("top C-major generation-density targets")
    for row in r["top_C_major_generation_density"][:12]:
        print(f"  k={row['k']:<4} hits/C={row['first_hits_per_C_candidate']}  "
              f"hits={row['first_hits']:<8} C={row['c_candidates']}")
    print()
    print("largest finite dead-factor shifts")
    for row in r["largest_finite_dead_work"][:12]:
        print(f"  k={row['k']:<4} fact={row['factorizations']:<8} active={row['active_visits']}")
    print()
    print("warning: finite rankings are research targets, not universal scheduler theorems")


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze cbx-profile-i JSON")
    ap.add_argument("input", help="profile JSON file, or - for stdin")
    ap.add_argument("--top", type=int, default=20)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.top < 1:
        raise SystemExit("--top must be >= 1")
    report = summarize(load_profile(args.input), args.top)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
