#!/usr/bin/env python3
"""Analyze exact standalone per-shift Lane-I profiles."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def div(a: int, b: int) -> float | None:
    return a / b if b else None


def load(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        obj = json.load(fh)
    if obj.get("kernel") != "cbx.kernel" or obj.get("mode") != "standalone-I":
        raise SystemExit("input is not a cbx.kernel standalone-I report")
    if not isinstance(obj.get("shifts"), list) or not obj["shifts"]:
        raise SystemExit("standalone profile has no shifts")
    return obj


def summarize(obj: dict[str, Any], top: int) -> dict[str, Any]:
    hard = int(obj["hard_primes"])
    rows = []
    for raw in obj["shifts"]:
        k = int(raw["k"])
        visits = int(raw["target_visits"])
        skips = int(raw["coprime_skips"])
        facts = int(raw["factorizations"])
        hits = int(raw["hits"])
        spec = raw.get("spectrum_hits") or {}
        A, B, C = (int(spec.get(name, 0)) for name in ("A", "B", "C"))
        if visits != hard:
            raise SystemExit(f"k={k}: standalone target_visits != hard_primes")
        if facts + skips > visits:
            raise SystemExit(f"k={k}: impossible visit accounting")
        if A + B + C != hits:
            raise SystemExit(f"k={k}: spectrum hit sum != hits")
        rows.append({
            "k": k,
            "target_visits": visits,
            "coprime_skips": skips,
            "factorizations": facts,
            "hits": hits,
            "hit_rate_all_hard": div(hits, hard),
            "hits_per_factorization": div(hits, facts),
            "factorizations_per_hit": div(facts, hits),
            "spectrum_hits": {"A": A, "B": B, "C": C},
            "spectrum_share": {
                "A": div(A, hits), "B": div(B, hits), "C": div(C, hits)
            },
        })

    ks = [r["k"] for r in rows]
    if ks != sorted(ks) or any(k % 4 != 3 for k in ks):
        raise SystemExit("standalone shifts are not ordered admissible k values")

    productive = [r for r in rows if r["hits"] > 0]
    zero = [r for r in rows if r["hits"] == 0]
    by_hits = sorted(rows, key=lambda r: (r["hits"], -r["k"]), reverse=True)
    by_rate = sorted(rows, key=lambda r: (r["hit_rate_all_hard"] or 0.0, -r["k"]), reverse=True)

    gt107 = [r for r in rows if r["k"] > 107]
    gt107_productive = [r for r in gt107 if r["hits"] > 0]
    gt107_zero = [r for r in gt107 if r["hits"] == 0]

    spectrum_totals = {
        name: sum(r["spectrum_hits"][name] for r in rows)
        for name in ("A", "B", "C")
    }

    return {
        "analysis": "cbx-lane-I-standalone-profile-v1",
        "kernel": obj["kernel"],
        "version": obj.get("version"),
        "lo": int(obj["lo"]),
        "hi": int(obj["hi"]),
        "i_max": int(obj["i_max"]),
        "hard_primes": hard,
        "layers": len(rows),
        "productive_layers": len(productive),
        "zero_hit_layers": len(zero),
        "productive_k": [r["k"] for r in productive],
        "zero_hit_k": [r["k"] for r in zero],
        "above_107": {
            "layers": len(gt107),
            "productive_layers": len(gt107_productive),
            "zero_hit_layers": len(gt107_zero),
            "productive_k": [r["k"] for r in gt107_productive],
            "zero_hit_k": [r["k"] for r in gt107_zero],
            "top_by_hits": sorted(gt107_productive, key=lambda r: (r["hits"], -r["k"]), reverse=True)[:top],
        },
        "top_by_hits": by_hits[:top],
        "top_by_hit_rate": by_rate[:top],
        "spectrum_hit_events": spectrum_totals,
        "totals": {
            "target_visits": sum(r["target_visits"] for r in rows),
            "coprime_skips": sum(r["coprime_skips"] for r in rows),
            "factorizations": sum(r["factorizations"] for r in rows),
            "hit_events": sum(r["hits"] for r in rows),
        },
        "rows": rows,
        "claim": (
            "finite standalone layer strengths only; a target may hit multiple shifts, "
            "and finite zero-hit layers are not universal redundancy theorems"
        ),
    }


def print_text(r: dict[str, Any]) -> None:
    print("cbx.kernel standalone Lane-I layer profile")
    print(f"range=[{r['lo']},{r['hi']}] K_I={r['i_max']} hard={r['hard_primes']} layers={r['layers']}")
    print(f"productive={r['productive_layers']} zero-hit={r['zero_hit_layers']}")
    a = r["above_107"]
    print(f"k>107: layers={a['layers']} productive={a['productive_layers']} zero-hit={a['zero_hit_layers']}")
    print()
    print("top standalone layers")
    for row in r["top_by_hits"][:12]:
        print(f"  k={row['k']:<4} hits={row['hits']:<8} rate={row['hit_rate_all_hard']:.6f} "
              f"fact={row['factorizations']}")
    print()
    print("top standalone layers above 107")
    for row in a["top_by_hits"][:12]:
        print(f"  k={row['k']:<4} hits={row['hits']:<8} rate={row['hit_rate_all_hard']:.6f}")
    print()
    print("warning: standalone strength measures overlap as well as novelty; it is not first-hit depth")


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze cbx-standalone-i JSON")
    ap.add_argument("input", type=Path)
    ap.add_argument("--top", type=int, default=20)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.top < 1:
        raise SystemExit("--top must be >= 1")
    if not args.input.is_file():
        raise SystemExit(f"no standalone profile: {args.input}")
    report = summarize(load(args.input), args.top)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
