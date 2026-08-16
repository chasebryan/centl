#!/usr/bin/env python3
"""Summarize cbx.kernel JSONL observations into X-ray depth distributions."""
from __future__ import annotations

import argparse
import collections
import json
import math
import statistics
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parent


def percentile(xs: list[int], q: float) -> int | None:
    if not xs:
        return None
    ys = sorted(xs)
    if len(ys) == 1:
        return ys[0]
    pos = q * (len(ys) - 1)
    lo = int(math.floor(pos))
    hi = int(math.ceil(pos))
    if lo == hi:
        return ys[lo]
    return int(round(ys[lo] + (ys[hi] - ys[lo]) * (pos - lo)))


def depth_summary(xs: list[int], total: int) -> dict[str, Any]:
    return {
        "hits": len(xs),
        "misses": total - len(xs),
        "hit_rate": (len(xs) / total) if total else None,
        "min": min(xs) if xs else None,
        "p50": percentile(xs, 0.50),
        "p90": percentile(xs, 0.90),
        "p99": percentile(xs, 0.99),
        "max": max(xs) if xs else None,
        "mean": statistics.fmean(xs) if xs else None,
    }


def iter_records(path: Path) -> Iterable[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as fh:
        for lineno, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError as exc:
                raise SystemExit(f"{path}:{lineno}: invalid JSON: {exc}") from exc
            if obj.get("kernel") != "cbx.kernel":
                continue
            yield obj


def dedupe(records: Iterable[dict[str, Any]]) -> tuple[list[dict[str, Any]], int]:
    """Keep one record per (n, grade), preferring sweep over home."""
    chosen: dict[tuple[Any, ...], dict[str, Any]] = {}
    observations = 0
    for r in records:
        observations += 1
        g = r.get("grade", {})
        key = (
            r.get("n"),
            g.get("fab_max"),
            g.get("i_max"),
            g.get("i_realized"),
            g.get("n_ell_max"),
            g.get("l_max"),
            g.get("policy"),
            g.get("policy_scale"),
        )
        old = chosen.get(key)
        if old is None or (old.get("via") == "home" and r.get("via") == "sweep"):
            chosen[key] = r
    return list(chosen.values()), observations


def classify(r: dict[str, Any]) -> list[str]:
    w = r.get("W", {})
    out = ["all"]
    spec = r.get("spectrum")
    if spec:
        out.append(f"spectrum:{spec}")
    if w.get("R"):
        out.append("R")
        if w.get("fab"):
            out.append("R+fab")
    else:
        out.append("non-R")
    if w.get("linear"):
        out.append("linear")
    if w.get("fab") and not w.get("linear"):
        out.append("fab-only")
    if r.get("production_letter"):
        out.append("production-letter")
    return out


def summarize(records: list[dict[str, Any]], observations: int) -> dict[str, Any]:
    strata: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
    for r in records:
        if not r.get("hard") or not r.get("prime"):
            continue
        for key in classify(r):
            strata[key].append(r)

    output: dict[str, Any] = {
        "kernel": "cbx.kernel",
        "analysis": "xray-depth-v1",
        "observations": observations,
        "unique_grade_targets": len(records),
        "duplicate_observations": observations - len(records),
        "strata": {},
    }

    for name, rs in sorted(strata.items()):
        i_depths = [int(r["I"]["first_k"]) for r in rs if r.get("I", {}).get("hit")]
        l_depths = [int(r["L"]["first_a"]) for r in rs if r.get("L", {}).get("hit")]
        n_ells = [int(r["N"]["ell"]) for r in rs if r.get("N", {}).get("hit")]
        i_bounds = [int(r.get("grade", {}).get("i_realized") or 0) for r in rs]
        production_letters = sum(bool(r.get("production_letter")) for r in rs)
        output["strata"][name] = {
            "targets": len(rs),
            "production_letters": production_letters,
            "I_first_k": depth_summary(i_depths, len(rs)),
            "N_first_ell": depth_summary(n_ells, len(rs)),
            "L_first_a": depth_summary(l_depths, len(rs)),
            "I_realized_bound": {
                "min": min(i_bounds) if i_bounds else None,
                "max": max(i_bounds) if i_bounds else None,
            },
        }
    return output


def fmt_rate(v: float | None) -> str:
    return "n/a" if v is None else f"{100*v:6.2f}%"


def print_text(report: dict[str, Any]) -> None:
    print("cbx.kernel X-ray depth analysis")
    print(f"observations:          {report['observations']}")
    print(f"unique grade targets:  {report['unique_grade_targets']}")
    print(f"duplicate observations:{report['duplicate_observations']}")
    print()
    for name in ("all", "R", "fab-only", "linear", "spectrum:A", "spectrum:B", "spectrum:C"):
        s = report["strata"].get(name)
        if not s:
            continue
        print(f"[{name}] targets={s['targets']} production_letters={s['production_letters']}")
        for label, key in (("I k*", "I_first_k"), ("N ell*", "N_first_ell"), ("L a*", "L_first_a")):
            d = s[key]
            print(
                f"  {label:7s} hit={fmt_rate(d['hit_rate'])} "
                f"min={d['min']} p50={d['p50']} p90={d['p90']} "
                f"p99={d['p99']} max={d['max']}"
            )
        print()


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze cbx.kernel JSONL observations")
    ap.add_argument("--run", default="default", help="named CBX run (default: default)")
    ap.add_argument("--input", type=Path, default=None, help="explicit observations JSONL path")
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = ap.parse_args()

    path = args.input or (ROOT / "observations" / f"{args.run}.jsonl")
    if not path.is_file():
        raise SystemExit(f"no observation file: {path}")

    records, observations = dedupe(iter_records(path))
    report = summarize(records, observations)
    report["run"] = args.run
    report["input"] = str(path)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
