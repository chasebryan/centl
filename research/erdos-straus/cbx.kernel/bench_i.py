#!/usr/bin/env python3
"""Benchmark CBX Lane-I inverse construction against p-first recognition."""
from __future__ import annotations

import argparse
import json
import math
import statistics
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
INV = ROOT / "cbx-inverse"
FWD = ROOT / "cbx-forward-i"


def ensure_built() -> None:
    if INV.is_file() and FWD.is_file():
        return
    subprocess.run(["make", "-C", str(ROOT), "cbx-inverse", "cbx-forward-i"], check=True)


def run_json(cmd: list[str]) -> tuple[dict[str, Any], float]:
    start = time.perf_counter()
    proc = subprocess.run(cmd, text=True, capture_output=True)
    elapsed = time.perf_counter() - start
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        sys.stderr.write(proc.stdout)
        raise SystemExit(f"command failed ({proc.returncode}): {' '.join(cmd)}")
    lines = [line for line in proc.stdout.splitlines() if line.strip()]
    if not lines:
        raise SystemExit(f"command produced no JSON: {' '.join(cmd)}")
    try:
        obj = json.loads(lines[-1])
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid JSON from {' '.join(cmd)}: {exc}") from exc
    return obj, elapsed


def as_int(obj: dict[str, Any], key: str) -> int:
    value = obj[key]
    if isinstance(value, bool):
        raise TypeError(key)
    return int(value)


def validate_pair(inv: dict[str, Any], fwd: dict[str, Any]) -> None:
    if inv.get("mode") != "inverse-I" or fwd.get("mode") != "forward-I":
        raise SystemExit("unexpected benchmark engine mode")
    for key in ("lo", "hi", "i_max", "hard_primes", "covered_hard_primes", "residual_hard_primes"):
        if as_int(inv, key) != as_int(fwd, key):
            raise SystemExit(f"inverse/forward mismatch for {key}: {inv[key]} != {fwd[key]}")


def ratio(a: float | int, b: float | int) -> float | None:
    return (a / b) if b else None


def finite(v: float | None) -> float | None:
    return v if v is None or math.isfinite(v) else None


def benchmark_one(lo: int, hi: int, kmax: int, segment: int, repeat: int,
                  verify_first: bool, strict_inverse: bool) -> dict[str, Any]:
    inv_base = [str(INV), "--lo", str(lo), "--hi", str(hi), "--i-max", str(kmax),
                "--segment", str(segment)]
    if strict_inverse:
        inv_base.append("--strict-c-first")
    else:
        inv_base.append("--target-gated")
    fwd_base = [str(FWD), "--lo", str(lo), "--hi", str(hi), "--i-max", str(kmax)]

    verification = None
    if verify_first:
        verification, verify_seconds = run_json(inv_base + ["--verify"])
        if as_int(verification, "verification_mismatches") != 0:
            raise SystemExit("inverse verification failed before benchmark")
        verification = {
            "targets": as_int(verification, "verification_targets"),
            "mismatches": as_int(verification, "verification_mismatches"),
            "wall_seconds": verify_seconds,
        }

    inv_times: list[float] = []
    fwd_times: list[float] = []
    inv_last: dict[str, Any] | None = None
    fwd_last: dict[str, Any] | None = None

    # Alternate order to reduce systematic warm-cache / scheduler bias.
    for rep in range(repeat):
        if rep % 2 == 0:
            inv_last, t = run_json(inv_base)
            inv_times.append(t)
            fwd_last, t = run_json(fwd_base)
            fwd_times.append(t)
        else:
            fwd_last, t = run_json(fwd_base)
            fwd_times.append(t)
            inv_last, t = run_json(inv_base)
            inv_times.append(t)
        validate_pair(inv_last, fwd_last)

    assert inv_last is not None and fwd_last is not None
    hard = as_int(inv_last, "hard_primes")
    covered = as_int(inv_last, "covered_hard_primes")
    residual = as_int(inv_last, "residual_hard_primes")
    c_candidates = as_int(inv_last, "C_candidates")
    inv_factorizations = as_int(inv_last, "factorizations")
    delta_hits = as_int(inv_last, "delta_hits")
    forward_shifts = as_int(fwd_last, "shift_candidates")
    forward_factorizations = as_int(fwd_last, "factorizations")

    inv_med = statistics.median(inv_times)
    fwd_med = statistics.median(fwd_times)

    return {
        "lo": lo,
        "hi": hi,
        "i_max": kmax,
        "segment": segment,
        "repeat": repeat,
        "candidate_mode": inv_last.get("candidate_mode"),
        "verification": verification,
        "hard_primes": hard,
        "covered_hard_primes": covered,
        "residual_hard_primes": residual,
        "cover_rate": ratio(covered, hard),
        "inverse": {
            "C_candidates": c_candidates,
            "factorizations": inv_factorizations,
            "delta_hits": delta_hits,
            "skipped_non_target": as_int(inv_last, "skipped_non_target"),
            "skipped_covered": as_int(inv_last, "skipped_covered"),
            "skipped_non_coprime": as_int(inv_last, "skipped_non_coprime"),
            "factorizations_per_prime": ratio(inv_factorizations, hard),
            "wall_seconds": inv_times,
            "median_wall_seconds": inv_med,
            "min_wall_seconds": min(inv_times),
        },
        "forward": {
            "shift_candidates": forward_shifts,
            "factorizations": forward_factorizations,
            "factorizations_per_prime": ratio(forward_factorizations, hard),
            "wall_seconds": fwd_times,
            "median_wall_seconds": fwd_med,
            "min_wall_seconds": min(fwd_times),
        },
        "comparison": {
            "inverse_to_forward_wall_ratio": finite(ratio(inv_med, fwd_med)),
            "inverse_enumerated_C_to_forward_factorizations": finite(
                ratio(c_candidates, forward_factorizations)
            ),
            "inverse_factorizations_to_forward_factorizations": finite(
                ratio(inv_factorizations, forward_factorizations)
            ),
            "interpretation": (
                "Factorization ratio measures expensive signed-box work. Enumerated-C ratio measures "
                "cheap inverse traversal overhead. Wall ratio is machine/corpus specific. "
                "Ratios below 1 favor inverse. Finite benchmark only."
            ),
        },
    }


def print_text(report: dict[str, Any]) -> None:
    print("cbx.kernel Lane-I orientation benchmark")
    print("finite timings only; lower ratio favors inverse")
    print()
    for row in report["results"]:
        print(f"X=[{row['lo']},{row['hi']}]  K_I={row['i_max']}  hard={row['hard_primes']}  "
              f"inverse={row['candidate_mode']}")
        print(f"  cover:   {row['covered_hard_primes']} hit / {row['residual_hard_primes']} residual")
        print(f"  inverse: enumerated_C={row['inverse']['C_candidates']}  "
              f"factorizations={row['inverse']['factorizations']}  "
              f"median={row['inverse']['median_wall_seconds']:.6f}s")
        print(f"  forward: factorizations={row['forward']['factorizations']}  "
              f"median={row['forward']['median_wall_seconds']:.6f}s")
        print(f"  factorization ratio inverse/forward: "
              f"{row['comparison']['inverse_factorizations_to_forward_factorizations']:.6f}")
        print(f"  enumeration ratio C/forward-factorizations: "
              f"{row['comparison']['inverse_enumerated_C_to_forward_factorizations']:.6f}")
        print(f"  wall ratio inverse/forward: "
              f"{row['comparison']['inverse_to_forward_wall_ratio']:.6f}")
        if row["verification"]:
            print(f"  verified: {row['verification']['targets']} targets, "
                  f"{row['verification']['mismatches']} mismatches")
        print()


def main() -> int:
    ap = argparse.ArgumentParser(description="Benchmark CBX inverse-I against p-first Lane-I")
    ap.add_argument("--lo", type=int, default=2)
    ap.add_argument("--hi", type=int, action="append", required=True,
                    help="upper endpoint; may be repeated")
    ap.add_argument("--i-max", type=int, action="append", default=None,
                    help="Lane-I bound; may be repeated (default 400)")
    ap.add_argument("--segment", type=int, default=1_000_000)
    ap.add_argument("--repeat", type=int, default=3)
    ap.add_argument("--strict-inverse", action="store_true",
                    help="benchmark the ungated strict-C-first inverse baseline")
    ap.add_argument("--no-verify", action="store_true",
                    help="skip the pre-benchmark inverse-vs-forward theorem check")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if args.lo < 0 or any(x < max(2, args.lo) for x in args.hi):
        raise SystemExit("each --hi must be >= max(2,--lo)")
    k_values = args.i_max or [400]
    if any(k < 3 for k in k_values):
        raise SystemExit("each --i-max must be >= 3")
    if args.segment < 1 or args.segment > 100_000_000:
        raise SystemExit("--segment must be in 1..100000000")
    if args.repeat < 1:
        raise SystemExit("--repeat must be >= 1")

    ensure_built()
    results = []
    for hi in args.hi:
        for kmax in k_values:
            results.append(benchmark_one(args.lo, hi, kmax, args.segment, args.repeat,
                                         not args.no_verify, args.strict_inverse))

    report = {
        "kernel": "cbx.kernel",
        "benchmark": "lane-I-orientation-v2",
        "claim": "finite empirical benchmark only",
        "results": results,
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
