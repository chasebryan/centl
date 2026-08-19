#!/usr/bin/env python3
"""Summarize cbx.kernel observations and falsify empirical K policies."""
from __future__ import annotations

import argparse
import collections
import json
import math
import statistics
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parent
POLICIES = ("log", "log2", "spectrum-log")
SPECTRUM_MULT = {"A": 1.0, "B": 1.15, "C": 1.30}


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


def iter_records(path: Path, scan: dict[str, int]) -> Iterable[dict[str, Any]]:
    """Yield complete CBX records; ignore only a final crash-truncated JSON line."""
    with path.open("r", encoding="utf-8") as fh:
        lineno = 0
        while True:
            line = fh.readline()
            if not line:
                break
            lineno += 1
            if not line.strip():
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError as exc:
                # A hard crash can leave exactly one partial final append. The
                # resumed runtime trims it too, but analysis should be safe even
                # before the run is resumed.
                if not line.endswith("\n") and fh.read(1) == "":
                    scan["truncated_tail_ignored"] += 1
                    print(f"warning: ignoring crash-truncated final record at {path}:{lineno}",
                          file=sys.stderr)
                    break
                raise SystemExit(f"{path}:{lineno}: invalid JSON: {exc}") from exc
            if obj.get("kernel") == "cbx.kernel":
                yield obj


def grade_key(r: dict[str, Any]) -> tuple[Any, ...]:
    g = r.get("grade", {})
    return (
        r.get("n"), g.get("fab_max"), g.get("i_max"), g.get("i_realized"),
        g.get("n_ell_max"), g.get("l_max"), g.get("policy"), g.get("policy_scale"),
    )


def dedupe(records: Iterable[dict[str, Any]]) -> tuple[list[dict[str, Any]], int]:
    """Keep one record per (n, grade), preferring sweep over home."""
    chosen: dict[tuple[Any, ...], dict[str, Any]] = {}
    observations = 0
    for r in records:
        observations += 1
        key = grade_key(r)
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


def i_record_sequence(records: list[dict[str, Any]], predicate=lambda _r: True) -> list[dict[str, Any]]:
    """Running observed record sequence K_obs(X)=max_{p<=X} k_I*(p)."""
    hits = sorted(
        (r for r in records if predicate(r) and r.get("I", {}).get("hit")),
        key=lambda r: int(r["n"]),
    )
    out: list[dict[str, Any]] = []
    record = -1
    for r in hits:
        k = int(r["I"]["first_k"])
        if k > record:
            record = k
            out.append({
                "n": int(r["n"]),
                "spectrum": r.get("spectrum"),
                "R": bool(r.get("W", {}).get("R")),
                "fab": bool(r.get("W", {}).get("fab")),
                "k_I": k,
                "omega": int(r.get("I", {}).get("omega") or 0),
                "Omega": int(r.get("I", {}).get("Omega") or 0),
                "box_size": int(r.get("I", {}).get("box_size") or 0),
            })
    return out


def policy_basis(n: int, spectrum: str | None, policy: str) -> float:
    lp = math.log(max(n, 3))
    if policy == "log":
        return lp
    if policy == "log2":
        return lp * lp
    if policy == "spectrum-log":
        return SPECTRUM_MULT.get(spectrum, 1.0) * lp
    raise ValueError(policy)


def policy_bound(n: int, spectrum: str | None, policy: str, scale: float, cap: int | None) -> int:
    value = scale * policy_basis(n, spectrum, policy)
    bound = max(3, int(math.ceil(value)))
    if cap is not None:
        bound = min(bound, cap)
    return bound


def evaluate_policy(records: list[dict[str, Any]], policy: str, scale: float, cap: int | None,
                    predicate=lambda _r: True) -> dict[str, Any]:
    tested = failures = 0
    first_failure = None
    worst = None
    deficits: list[int] = []
    for r in sorted(records, key=lambda x: int(x.get("n") or 0)):
        if not predicate(r) or not r.get("I", {}).get("hit"):
            continue
        tested += 1
        n = int(r["n"])
        k = int(r["I"]["first_k"])
        b = policy_bound(n, r.get("spectrum"), policy, scale, cap)
        if b < k:
            failures += 1
            d = k - b
            deficits.append(d)
            item = {"n": n, "spectrum": r.get("spectrum"), "R": bool(r.get("W", {}).get("R")),
                    "required_k": k, "policy_k": b, "deficit": d}
            if first_failure is None:
                first_failure = item
            if worst is None or d > worst["deficit"]:
                worst = item
    return {
        "policy": policy,
        "scale": scale,
        "cap": cap,
        "tested_hits": tested,
        "failures": failures,
        "failure_rate": failures / tested if tested else None,
        "first_failure": first_failure,
        "worst_failure": worst,
        "max_deficit": max(deficits) if deficits else 0,
    }


def empirical_scale(records: list[dict[str, Any]], policy: str,
                    predicate=lambda _r: True) -> dict[str, Any]:
    """Conservative observed scale c with c*basis(p) >= k_I*(p) on measured hits."""
    tested = 0
    worst: dict[str, Any] | None = None
    for r in records:
        if not predicate(r) or not r.get("I", {}).get("hit"):
            continue
        tested += 1
        n = int(r["n"])
        k = int(r["I"]["first_k"])
        basis = policy_basis(n, r.get("spectrum"), policy)
        if basis <= 0:
            continue
        ratio = k / basis
        if worst is None or ratio > worst["required_scale"]:
            worst = {
                "n": n,
                "spectrum": r.get("spectrum"),
                "R": bool(r.get("W", {}).get("R")),
                "k_I": k,
                "basis": basis,
                "required_scale": ratio,
            }
    return {
        "policy": policy,
        "tested_hits": tested,
        "conservative_required_scale": worst["required_scale"] if worst else None,
        "witness": worst,
        "claim": "finite empirical envelope only",
    }


def empirical_envelopes(records: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        policy: {
            "all": empirical_scale(records, policy),
            "R": empirical_scale(records, policy, lambda r: bool(r.get("W", {}).get("R"))),
        }
        for policy in POLICIES
    }


def summarize(records: list[dict[str, Any]], observations: int, scan: dict[str, int]) -> dict[str, Any]:
    valid = [r for r in records if r.get("hard") and r.get("prime")]
    strata: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
    for r in valid:
        for key in classify(r):
            strata[key].append(r)

    output: dict[str, Any] = {
        "kernel": "cbx.kernel",
        "analysis": "xray-depth-v3",
        "observations": observations,
        "unique_grade_targets": len(records),
        "valid_hard_prime_targets": len(valid),
        "duplicate_observations": observations - len(records),
        "truncated_tail_ignored": scan["truncated_tail_ignored"],
        "I_record_sequence": i_record_sequence(valid),
        "I_record_sequence_R": i_record_sequence(valid, lambda r: bool(r.get("W", {}).get("R"))),
        "empirical_envelopes": empirical_envelopes(valid),
        "strata": {},
    }

    for name, rs in sorted(strata.items()):
        i_depths = [int(r["I"]["first_k"]) for r in rs if r.get("I", {}).get("hit")]
        l_depths = [int(r["L"]["first_a"]) for r in rs if r.get("L", {}).get("hit")]
        n_ells = [int(r["N"]["ell"]) for r in rs if r.get("N", {}).get("hit")]
        i_bounds = [int(r.get("grade", {}).get("i_realized") or 0) for r in rs]
        output["strata"][name] = {
            "targets": len(rs),
            "production_letters": sum(bool(r.get("production_letter")) for r in rs),
            "I_first_k": depth_summary(i_depths, len(rs)),
            "N_first_ell": depth_summary(n_ells, len(rs)),
            "L_first_a": depth_summary(l_depths, len(rs)),
            "I_realized_bound": {"min": min(i_bounds) if i_bounds else None,
                                 "max": max(i_bounds) if i_bounds else None},
        }
    return output


def fmt_rate(v: float | None) -> str:
    return "n/a" if v is None else f"{100*v:6.2f}%"


def print_records(label: str, seq: list[dict[str, Any]], limit: int = 12) -> None:
    print(f"{label}: {len(seq)} record events")
    for r in seq[-limit:]:
        print(f"  n={r['n']:<12d} k_I*={r['k_I']:<4d} spec={r['spectrum']} R={str(r['R']).lower()} "
              f"omega={r['omega']} Omega={r['Omega']} box={r['box_size']}")
    print()


def print_envelopes(report: dict[str, Any]) -> None:
    print("conservative finite empirical K scales")
    for policy in POLICIES:
        row = report["empirical_envelopes"][policy]
        a = row["all"]
        rr = row["R"]
        print(f"  {policy:12s} all={a['conservative_required_scale']!r} witness={a['witness']}")
        print(f"  {'':12s} R  ={rr['conservative_required_scale']!r} witness={rr['witness']}")
    print("  these are measured envelopes, not asymptotic claims")
    print()


def print_text(report: dict[str, Any]) -> None:
    print("cbx.kernel X-ray depth analysis")
    print(f"observations:           {report['observations']}")
    print(f"unique grade targets:   {report['unique_grade_targets']}")
    print(f"duplicate observations: {report['duplicate_observations']}")
    print(f"truncated tail ignored: {report['truncated_tail_ignored']}")
    print()
    for name in ("all", "R", "fab-only", "linear", "spectrum:A", "spectrum:B", "spectrum:C"):
        s = report["strata"].get(name)
        if not s:
            continue
        print(f"[{name}] targets={s['targets']} production_letters={s['production_letters']}")
        for label, key in (("I k*", "I_first_k"), ("N ell*", "N_first_ell"), ("L a*", "L_first_a")):
            d = s[key]
            print(f"  {label:7s} hit={fmt_rate(d['hit_rate'])} min={d['min']} p50={d['p50']} "
                  f"p90={d['p90']} p99={d['p99']} max={d['max']}")
        print()
    print_records("I running frontier (all)", report["I_record_sequence"])
    print_records("I running frontier (R)", report["I_record_sequence_R"])
    print_envelopes(report)
    if "candidate_policy" in report:
        p = report["candidate_policy"]
        print(f"candidate K policy: {p['policy']} scale={p['scale']} cap={p['cap']}")
        print(f"  tested={p['tested_hits']} failures={p['failures']} rate={fmt_rate(p['failure_rate'])}")
        print(f"  first_failure={p['first_failure']}")
        print(f"  worst_failure={p['worst_failure']}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze cbx.kernel JSONL observations")
    ap.add_argument("--run", default="default", help="named CBX run (default: default)")
    ap.add_argument("--input", type=Path, default=None, help="explicit observations JSONL path")
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    ap.add_argument("--candidate-policy", choices=POLICIES, default=None,
                    help="falsify an experimental K(p) policy against observed I depths")
    ap.add_argument("--candidate-scale", type=float, default=1.0)
    ap.add_argument("--candidate-cap", type=int, default=None)
    ap.add_argument("--candidate-R-only", action="store_true",
                    help="test policy only on the R stratum")
    args = ap.parse_args()

    if not math.isfinite(args.candidate_scale) or args.candidate_scale <= 0:
        raise SystemExit("--candidate-scale must be finite and positive")
    if args.candidate_cap is not None and args.candidate_cap < 3:
        raise SystemExit("--candidate-cap must be >= 3")
    path = args.input or (ROOT / "observations" / f"{args.run}.jsonl")
    if not path.is_file():
        raise SystemExit(f"no observation file: {path}")

    scan = {"truncated_tail_ignored": 0}
    records, observations = dedupe(iter_records(path, scan))
    report = summarize(records, observations, scan)
    report["run"] = args.run
    report["input"] = str(path)
    if args.candidate_policy:
        pred = (lambda r: bool(r.get("W", {}).get("R"))) if args.candidate_R_only else (lambda _r: True)
        report["candidate_policy"] = evaluate_policy(records, args.candidate_policy,
                                                     args.candidate_scale, args.candidate_cap, pred)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())