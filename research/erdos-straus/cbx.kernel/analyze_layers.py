#!/usr/bin/env python3
"""Analyze per-k telemetry emitted by cbx-inverse --layers."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


def read_layers(path: Path) -> list[dict[str, int]]:
    rows: list[dict[str, int]] = []
    with path.open("r", encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        required = {
            "k", "C_candidates", "hard_targets", "skipped_non_target",
            "skipped_covered", "skipped_non_coprime", "factorizations",
            "delta_hits", "new_covered",
        }
        if set(reader.fieldnames or ()) != required:
            raise SystemExit(f"unexpected layer telemetry columns: {reader.fieldnames}")
        for lineno, row in enumerate(reader, 2):
            try:
                parsed = {key: int(value) for key, value in row.items()}
            except (TypeError, ValueError) as exc:
                raise SystemExit(f"{path}:{lineno}: invalid integer field") from exc
            if parsed["k"] < 3 or parsed["k"] % 4 != 3:
                raise SystemExit(f"{path}:{lineno}: invalid admissible shift k={parsed['k']}")
            rows.append(parsed)
    if not rows:
        raise SystemExit(f"no layer telemetry rows: {path}")
    return rows


def div(a: int, b: int) -> float | None:
    return a / b if b else None


def summarize(rows: list[dict[str, int]]) -> dict[str, Any]:
    enriched: list[dict[str, Any]] = []
    cumulative_cover = 0
    cumulative_factorizations = 0
    for row in rows:
        cumulative_cover += row["new_covered"]
        cumulative_factorizations += row["factorizations"]
        item: dict[str, Any] = dict(row)
        item.update({
            "new_cover_per_factorization": div(row["new_covered"], row["factorizations"]),
            "delta_per_factorization": div(row["delta_hits"], row["factorizations"]),
            "hard_target_rate": div(row["hard_targets"], row["C_candidates"]),
            "covered_skip_rate_among_hard": div(row["skipped_covered"], row["hard_targets"]),
            "cumulative_new_covered": cumulative_cover,
            "cumulative_factorizations": cumulative_factorizations,
        })
        enriched.append(item)

    factored = [r for r in enriched if r["factorizations"] > 0]
    productive = [r for r in enriched if r["new_covered"] > 0]
    dead_factoring = [r for r in enriched if r["factorizations"] > 0 and r["new_covered"] == 0]
    zero_factor = [r for r in enriched if r["factorizations"] == 0]

    top_new = sorted(enriched, key=lambda r: (r["new_covered"], -r["k"]), reverse=True)
    top_eff = sorted(
        factored,
        key=lambda r: (r["new_cover_per_factorization"] or 0.0, r["new_covered"], -r["k"]),
        reverse=True,
    )
    worst_work = sorted(
        dead_factoring,
        key=lambda r: (r["factorizations"], r["k"]),
        reverse=True,
    )

    total = {
        key: sum(r[key] for r in rows)
        for key in (
            "C_candidates", "hard_targets", "skipped_non_target", "skipped_covered",
            "skipped_non_coprime", "factorizations", "delta_hits", "new_covered"
        )
    }

    return {
        "analysis": "cbx-inverse-layer-efficiency-v1",
        "layers": len(rows),
        "k_min": min(r["k"] for r in rows),
        "k_max": max(r["k"] for r in rows),
        "productive_layers": len(productive),
        "factoring_layers": len(factored),
        "dead_factoring_layers": len(dead_factoring),
        "zero_factor_layers": len(zero_factor),
        "totals": total,
        "aggregate": {
            "new_cover_per_factorization": div(total["new_covered"], total["factorizations"]),
            "hard_target_rate": div(total["hard_targets"], total["C_candidates"]),
            "covered_skip_fraction_of_hard": div(total["skipped_covered"], total["hard_targets"]),
        },
        "productive_k": [r["k"] for r in productive],
        "dead_factoring_k": [r["k"] for r in dead_factoring],
        "top_new_cover": top_new[:20],
        "top_efficiency": top_eff[:20],
        "worst_dead_work": worst_work[:20],
        "rows": enriched,
        "claim": "finite telemetry only; zero marginal cover is not a proof of universal redundancy",
    }


def print_text(report: dict[str, Any]) -> None:
    t = report["totals"]
    print("cbx.kernel inverse-I layer efficiency")
    print(f"layers: {report['layers']}  k={report['k_min']}..{report['k_max']}")
    print(f"productive: {report['productive_layers']}  dead-with-factorization: {report['dead_factoring_layers']}  "
          f"zero-factor: {report['zero_factor_layers']}")
    print(f"total C: {t['C_candidates']}  hard encounters: {t['hard_targets']}  "
          f"factorizations: {t['factorizations']}  new cover: {t['new_covered']}")
    print()
    print("top marginal cover")
    for r in report["top_new_cover"][:12]:
        print(f"  k={r['k']:<4} new={r['new_covered']:<8} fact={r['factorizations']:<8} "
              f"eff={r['new_cover_per_factorization']}")
    print()
    print("largest finite dead-work layers")
    for r in report["worst_dead_work"][:12]:
        print(f"  k={r['k']:<4} fact={r['factorizations']:<8} delta={r['delta_hits']:<8} "
              f"hard={r['hard_targets']:<8} covered-skip={r['skipped_covered']}")
    print()
    print("warning: finite zero marginal cover is evidence for theorem hunting, not a redundancy theorem")


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze cbx-inverse --layers TSV")
    ap.add_argument("input", type=Path)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if not args.input.is_file():
        raise SystemExit(f"no layer telemetry file: {args.input}")
    report = summarize(read_layers(args.input))
    report["input"] = str(args.input)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
