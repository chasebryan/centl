#!/usr/bin/env python3
"""Plan, but never silently enact, a measured hybrid Lane-I traversal.

The planner consumes an analyzed survivor-frontier profile from
``analyze_profile.py`` and optionally an analyzed standalone profile and a
three-way benchmark. It does not skip finite-zero layers and does not claim a
universal optimum. Its central exact finite quantity is the C-major retention
rate required for generated-C traversal to break even with an active-target
traversal under explicit cheap-operation cost weights.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def positive(name: str, value: float) -> float:
    if not math.isfinite(value) or value <= 0:
        raise SystemExit(f"{name} must be finite and > 0")
    return value


def probability(name: str, value: float | None) -> float | None:
    if value is None:
        return None
    if not math.isfinite(value) or value < 0 or value > 1:
        raise SystemExit(f"{name} must be in [0,1]")
    return value


def parse_profile(path: Path) -> dict[str, Any]:
    obj = load_json(path)
    if obj.get("analysis") != "cbx-lane-I-shift-profile-v1":
        raise SystemExit("--profile must be analyze_profile.py JSON")
    rows = obj.get("rows")
    if not isinstance(rows, list) or not rows:
        raise SystemExit("shift profile has no rows")
    return obj


def parse_standalone(path: Path | None) -> dict[int, dict[str, Any]]:
    if path is None:
        return {}
    obj = load_json(path)
    if obj.get("analysis") != "cbx-lane-I-standalone-profile-v1":
        raise SystemExit("--standalone must be analyze_standalone.py JSON")
    rows = obj.get("rows")
    if not isinstance(rows, list):
        raise SystemExit("standalone profile has no rows")
    return {int(r["k"]): r for r in rows}


def parse_benchmark(path: Path | None) -> dict[str, Any] | None:
    if path is None:
        return None
    obj = load_json(path)
    if obj.get("benchmark") not in {"lane-I-orientation-v3", "lane-I-orientation-v2"}:
        raise SystemExit("--benchmark must be bench_i.py JSON")
    results = obj.get("results")
    if not isinstance(results, list) or not results:
        raise SystemExit("benchmark has no result rows")
    return results[0]


def choose_active_baseline(benchmark: dict[str, Any] | None, tie_tolerance: float) -> dict[str, Any]:
    if benchmark is None:
        return {
            "orientation": "p-or-shift-parity",
            "reason": "exact active work counts are equivalent; no benchmark supplied",
            "shift_to_forward_wall_ratio": None,
        }
    ratio = benchmark.get("comparison", {}).get("shift_to_forward_wall_ratio")
    if ratio is None:
        return {
            "orientation": "p-or-shift-parity",
            "reason": "benchmark lacks shift/forward wall ratio",
            "shift_to_forward_wall_ratio": None,
        }
    ratio = float(ratio)
    if abs(ratio - 1.0) <= tie_tolerance:
        orientation = "p-or-shift-parity"
        reason = f"measured shift/forward wall ratio {ratio:.6f} lies inside ±{tie_tolerance:.3f} tie band"
    elif ratio < 1.0:
        orientation = "shift-major"
        reason = f"measured shift/forward wall ratio {ratio:.6f} favors shift-major outside tie band"
    else:
        orientation = "p-major"
        reason = f"measured shift/forward wall ratio {ratio:.6f} favors p-major outside tie band"
    return {
        "orientation": orientation,
        "reason": reason,
        "shift_to_forward_wall_ratio": ratio,
    }


def plan_row(
    raw: dict[str, Any],
    standalone: dict[str, Any] | None,
    *,
    c_enum_cost: float,
    active_visit_cost: float,
    assumed_c_retention: float | None,
    active_baseline: str,
) -> dict[str, Any]:
    k = int(raw["k"])
    active = int(raw["active_visits"])
    c_candidates = int(raw["c_candidates"])
    facts = int(raw["factorizations"])
    first_hits = int(raw["first_hits"])

    # The current target-gated C-major and active-frontier engines perform the
    # same expensive factorizations on the measured work set. The differential
    # cost model therefore compares only cheap traversal work. A future exact
    # prefilter that retains fraction r of generic compatible C candidates has
    # traversal cost r*C*w_C; active traversal has A*w_A.
    if c_candidates:
        break_even = (active * active_visit_cost) / (c_candidates * c_enum_cost)
        break_even = max(0.0, min(1.0, break_even))
    else:
        break_even = 1.0
    required_pruning = 1.0 - break_even

    if assumed_c_retention is None:
        recommendation = "measure-only"
        recommendation_reason = "no --c-retention supplied; report break-even requirement only"
        c_cost = None
        active_cost = active * active_visit_cost
    else:
        c_cost = assumed_c_retention * c_candidates * c_enum_cost
        active_cost = active * active_visit_cost
        if c_cost < active_cost:
            recommendation = "C-major"
            recommendation_reason = (
                f"assumed exact C retention {assumed_c_retention:.6f} is below "
                f"break-even {break_even:.6f} under supplied traversal weights"
            )
        elif c_cost > active_cost:
            recommendation = active_baseline
            recommendation_reason = (
                f"assumed exact C retention {assumed_c_retention:.6f} exceeds "
                f"break-even {break_even:.6f} under supplied traversal weights"
            )
        else:
            recommendation = "C/active-parity"
            recommendation_reason = "modeled cheap traversal costs are equal"

    intrinsic_hits = int(standalone["hits"]) if standalone is not None else None
    intrinsic_rate = float(standalone["hit_rate_all_hard"]) if standalone is not None and standalone.get("hit_rate_all_hard") is not None else None
    if first_hits > 0:
        marginal_class = "productive-first-hit"
    elif intrinsic_hits is not None and intrinsic_hits > 0:
        marginal_class = "overlap-only-on-measured-domain"
    elif intrinsic_hits == 0:
        marginal_class = "zero-standalone-hit-on-measured-domain"
    else:
        marginal_class = "zero-marginal-hit-standalone-unknown"

    return {
        "k": k,
        "must_evaluate_for_exact_cover": True,
        "measured": {
            "active_visits": active,
            "c_candidates": c_candidates,
            "factorizations": facts,
            "first_hits": first_hits,
            "marginal_class": marginal_class,
            "standalone_hits": intrinsic_hits,
            "standalone_hit_rate_all_hard": intrinsic_rate,
        },
        "break_even": {
            "C_retention_vs_active": break_even,
            "required_C_pruning_fraction": required_pruning,
            "current_C_candidates_per_active_visit": (c_candidates / active) if active else None,
            "interpretation": (
                "an exact prefilter must retain no more than this fraction of generic compatible C candidates "
                "for C-major cheap traversal cost to beat the measured active-frontier traversal under the supplied weights"
            ),
        },
        "modeled": {
            "assumed_C_retention": assumed_c_retention,
            "C_traversal_cost": c_cost,
            "active_traversal_cost": active_cost,
            "recommendation": recommendation,
            "reason": recommendation_reason,
        },
    }


def summarize(
    profile: dict[str, Any],
    standalone: dict[int, dict[str, Any]],
    benchmark: dict[str, Any] | None,
    *,
    c_enum_cost: float,
    active_visit_cost: float,
    c_retention: float | None,
    tie_tolerance: float,
) -> dict[str, Any]:
    baseline = choose_active_baseline(benchmark, tie_tolerance)
    rows = [
        plan_row(
            r,
            standalone.get(int(r["k"])),
            c_enum_cost=c_enum_cost,
            active_visit_cost=active_visit_cost,
            assumed_c_retention=c_retention,
            active_baseline=baseline["orientation"],
        )
        for r in profile["rows"]
    ]

    generator_targets = sorted(
        rows,
        key=lambda r: (
            r["break_even"]["C_retention_vs_active"],
            r["measured"]["first_hits"],
            -r["k"],
        ),
        reverse=True,
    )

    overlap_targets = [r for r in rows if r["measured"]["marginal_class"] == "overlap-only-on-measured-domain"]
    zero_standalone = [r for r in rows if r["measured"]["marginal_class"] == "zero-standalone-hit-on-measured-domain"]

    counts: dict[str, int] = {}
    for r in rows:
        rec = r["modeled"]["recommendation"]
        counts[rec] = counts.get(rec, 0) + 1

    # Uniform exact-filter requirement: if a single C-retention guarantee were
    # used for every shift, this is the largest retention that lets C-major win
    # *all shifts that still have active targets*. Empty-frontier shifts impose
    # no useful scheduling constraint and are excluded.
    active_rows = [r for r in rows if r["measured"]["active_visits"] > 0]
    uniform_all = min((r["break_even"]["C_retention_vs_active"] for r in active_rows), default=None)
    easiest = max((r["break_even"]["C_retention_vs_active"] for r in active_rows), default=None)

    return {
        "planner": "cbx-hybrid-lane-I-v1",
        "claim": (
            "finite measured scheduling analysis only; every shift remains mathematically required unless a separate theorem removes it; "
            "recommendations depend on explicit cost/filter assumptions and do not alter CBX verdict semantics"
        ),
        "domain": {
            "lo": int(profile["lo"]),
            "hi": int(profile["hi"]),
            "i_max": int(profile["i_max"]),
            "hard_primes": int(profile["hard_primes"]),
        },
        "cost_model": {
            "C_enumeration_cost": c_enum_cost,
            "active_visit_cost": active_visit_cost,
            "common_factorization_cost": "cancels in current target-gated C-major vs active-frontier comparison because measured factorization sets are identical",
            "assumed_exact_C_retention": c_retention,
            "tie_tolerance": tie_tolerance,
        },
        "active_baseline": baseline,
        "summary": {
            "layers": len(rows),
            "active_layers": len(active_rows),
            "recommendation_counts": counts,
            "uniform_C_retention_needed_to_beat_active_on_every_active_layer": uniform_all,
            "easiest_layer_C_retention_break_even": easiest,
            "overlap_only_layers_with_standalone_hits": [r["k"] for r in overlap_targets],
            "finite_zero_standalone_layers": [r["k"] for r in zero_standalone],
        },
        "top_C_generator_research_targets": generator_targets[:20],
        "rows": rows,
    }


def print_text(report: dict[str, Any]) -> None:
    d = report["domain"]
    print("cbx.kernel measured hybrid Lane-I planner")
    print(f"domain=[{d['lo']},{d['hi']}] K_I={d['i_max']} hard={d['hard_primes']}")
    print(f"active baseline: {report['active_baseline']['orientation']}")
    print(report["active_baseline"]["reason"])
    print()
    cm = report["cost_model"]
    print(f"cheap-cost model: C-enum={cm['C_enumeration_cost']} active-visit={cm['active_visit_cost']} "
          f"assumed C retention={cm['assumed_exact_C_retention']}")
    s = report["summary"]
    print(f"layers={s['layers']} active_layers={s['active_layers']} recommendations={s['recommendation_counts']}")
    print(f"uniform retention needed to make C-major beat active on every active layer: "
          f"{s['uniform_C_retention_needed_to_beat_active_on_every_active_layer']}")
    print()
    print("easiest finite C-generator targets by break-even retention")
    for r in report["top_C_generator_research_targets"][:12]:
        b = r["break_even"]
        m = r["measured"]
        print(
            f"  k={r['k']:<4} break_even_retention={b['C_retention_vs_active']:.6f} "
            f"required_pruning={b['required_C_pruning_fraction']:.6f} "
            f"active={m['active_visits']} C={m['c_candidates']} first_hits={m['first_hits']} "
            f"class={m['marginal_class']}"
        )
    print()
    print("warning: this planner never authorizes skipping a shift; finite dead/overlap labels are research evidence only")


def main() -> int:
    ap = argparse.ArgumentParser(description="Measured hybrid Lane-I planner for cbx.kernel")
    ap.add_argument("profile", type=Path, help="analyze_profile.py JSON")
    ap.add_argument("--standalone", type=Path, help="optional analyze_standalone.py JSON")
    ap.add_argument("--benchmark", type=Path, help="optional bench_i.py JSON")
    ap.add_argument("--c-enum-cost", type=float, default=1.0,
                    help="relative cheap cost of enumerating one compatible C candidate")
    ap.add_argument("--active-visit-cost", type=float, default=1.0,
                    help="relative cheap cost of visiting one active target at one shift")
    ap.add_argument("--c-retention", type=float,
                    help="assumed exact prefilter retention fraction for compatible C candidates; omit for measure-only mode")
    ap.add_argument("--tie-tolerance", type=float, default=0.03,
                    help="relative wall-ratio band around 1 treated as p/shift timing parity")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    c_enum = positive("--c-enum-cost", args.c_enum_cost)
    active_cost = positive("--active-visit-cost", args.active_visit_cost)
    c_retention = probability("--c-retention", args.c_retention)
    if not math.isfinite(args.tie_tolerance) or args.tie_tolerance < 0:
        raise SystemExit("--tie-tolerance must be finite and >= 0")

    profile = parse_profile(args.profile)
    standalone = parse_standalone(args.standalone)
    benchmark = parse_benchmark(args.benchmark)

    if standalone:
        missing = sorted(set(int(r["k"]) for r in profile["rows"]) - set(standalone))
        if missing:
            raise SystemExit(f"standalone profile is missing shifts present in survivor profile: {missing[:12]}")

    report = summarize(
        profile,
        standalone,
        benchmark,
        c_enum_cost=c_enum,
        active_visit_cost=active_cost,
        c_retention=c_retention,
        tie_tolerance=args.tie_tolerance,
    )
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
