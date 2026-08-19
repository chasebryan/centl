#!/usr/bin/env python3
"""Benchmark three exact CBX Lane-I traversal orientations."""
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
SHIFT = ROOT / "cbx-shift-i"


def ensure_built() -> None:
    if INV.is_file() and FWD.is_file() and SHIFT.is_file():
        return
    subprocess.run(
        ["make", "-C", str(ROOT), "cbx-inverse", "cbx-forward-i", "cbx-shift-i"],
        check=True,
    )


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


def validate_engines(inv: dict[str, Any], fwd: dict[str, Any], shift: dict[str, Any]) -> None:
    if inv.get("mode") != "inverse-I" or fwd.get("mode") != "forward-I" or shift.get("mode") != "shift-I":
        raise SystemExit("unexpected benchmark engine mode")
    for key in ("lo", "hi", "i_max", "hard_primes", "covered_hard_primes", "residual_hard_primes"):
        values = (as_int(inv, key), as_int(fwd, key), as_int(shift, key))
        if len(set(values)) != 1:
            raise SystemExit(f"engine mismatch for {key}: inverse={values[0]} forward={values[1]} shift={values[2]}")


def ratio(a: float | int, b: float | int) -> float | None:
    return (a / b) if b else None


def finite(v: float | None) -> float | None:
    return v if v is None or math.isfinite(v) else None


def benchmark_one(lo: int, hi: int, kmax: int, segment: int, repeat: int,
                  verify_first: bool, strict_inverse: bool) -> dict[str, Any]:
    inv_base = [str(INV), "--lo", str(lo), "--hi", str(hi), "--i-max", str(kmax),
                "--segment", str(segment)]
    inv_base.append("--strict-c-first" if strict_inverse else "--target-gated")
    fwd_base = [str(FWD), "--lo", str(lo), "--hi", str(hi), "--i-max", str(kmax)]
    shift_base = [str(SHIFT), "--lo", str(lo), "--hi", str(hi), "--i-max", str(kmax),
                  "--segment", str(segment)]

    verification: dict[str, Any] | None = None
    if verify_first:
        inv_check, inv_verify_seconds = run_json(inv_base + ["--verify"])
        shift_check, shift_verify_seconds = run_json(shift_base + ["--verify"])
        if as_int(inv_check, "verification_mismatches") != 0:
            raise SystemExit("inverse verification failed before benchmark")
        if as_int(shift_check, "verification_mismatches") != 0:
            raise SystemExit("shift-major verification failed before benchmark")
        verification = {
            "inverse": {
                "targets": as_int(inv_check, "verification_targets"),
                "mismatches": as_int(inv_check, "verification_mismatches"),
                "wall_seconds": inv_verify_seconds,
            },
            "shift": {
                "targets": as_int(shift_check, "verification_targets"),
                "mismatches": as_int(shift_check, "verification_mismatches"),
                "wall_seconds": shift_verify_seconds,
            },
        }

    commands = {"inverse": inv_base, "forward": fwd_base, "shift": shift_base}
    times: dict[str, list[float]] = {name: [] for name in commands}
    last: dict[str, dict[str, Any]] = {}
    orders = [
        ("inverse", "forward", "shift"),
        ("forward", "shift", "inverse"),
        ("shift", "inverse", "forward"),
    ]

    for rep in range(repeat):
        for name in orders[rep % len(orders)]:
            obj, elapsed = run_json(commands[name])
            last[name] = obj
            times[name].append(elapsed)
        validate_engines(last["inverse"], last["forward"], last["shift"])

    inv = last["inverse"]
    fwd = last["forward"]
    shift = last["shift"]
    hard = as_int(inv, "hard_primes")
    covered = as_int(inv, "covered_hard_primes")
    residual = as_int(inv, "residual_hard_primes")

    inv_enum = as_int(inv, "C_candidates")
    inv_fact = as_int(inv, "factorizations")
    fwd_shifts = as_int(fwd, "shift_candidates")
    fwd_fact = as_int(fwd, "factorizations")
    shift_visits = as_int(shift, "active_visits")
    shift_fact = as_int(shift, "factorizations")

    med = {name: statistics.median(v) for name, v in times.items()}

    return {
        "lo": lo,
        "hi": hi,
        "i_max": kmax,
        "segment": segment,
        "repeat": repeat,
        "candidate_mode": inv.get("candidate_mode"),
        "verification": verification,
        "hard_primes": hard,
        "covered_hard_primes": covered,
        "residual_hard_primes": residual,
        "cover_rate": ratio(covered, hard),
        "inverse": {
            "C_candidates": inv_enum,
            "factorizations": inv_fact,
            "delta_hits": as_int(inv, "delta_hits"),
            "skipped_non_target": as_int(inv, "skipped_non_target"),
            "skipped_covered": as_int(inv, "skipped_covered"),
            "skipped_non_coprime": as_int(inv, "skipped_non_coprime"),
            "factorizations_per_prime": ratio(inv_fact, hard),
            "wall_seconds": times["inverse"],
            "median_wall_seconds": med["inverse"],
            "min_wall_seconds": min(times["inverse"]),
        },
        "forward": {
            "shift_candidates": fwd_shifts,
            "factorizations": fwd_fact,
            "factorizations_per_prime": ratio(fwd_fact, hard),
            "wall_seconds": times["forward"],
            "median_wall_seconds": med["forward"],
            "min_wall_seconds": min(times["forward"]),
        },
        "shift": {
            "active_visits": shift_visits,
            "coprime_skips": as_int(shift, "coprime_skips"),
            "factorizations": shift_fact,
            "factorizations_per_prime": ratio(shift_fact, hard),
            "wall_seconds": times["shift"],
            "median_wall_seconds": med["shift"],
            "min_wall_seconds": min(times["shift"]),
        },
        "comparison": {
            # Backward-compatible inverse keys.
            "inverse_to_forward_wall_ratio": finite(ratio(med["inverse"], med["forward"])),
            "inverse_enumerated_C_to_forward_factorizations": finite(ratio(inv_enum, fwd_fact)),
            "inverse_factorizations_to_forward_factorizations": finite(ratio(inv_fact, fwd_fact)),
            # Third orientation.
            "shift_to_forward_wall_ratio": finite(ratio(med["shift"], med["forward"])),
            "shift_active_visits_to_forward_shift_candidates": finite(ratio(shift_visits, fwd_shifts)),
            "shift_factorizations_to_forward_factorizations": finite(ratio(shift_fact, fwd_fact)),
            "interpretation": (
                "Factorization ratios measure expensive signed-box work. C-candidate and active-visit "
                "ratios measure traversal overhead. Wall ratios are machine/corpus specific. "
                "Ratios below 1 favor the named non-forward orientation. Finite benchmark only."
            ),
        },
    }


def print_text(report: dict[str, Any]) -> None:
    print("cbx.kernel Lane-I orientation benchmark")
    print("p-major forward vs C-major inverse vs shift-major frontier")
    print("finite timings only; lower ratio favors the named non-forward orientation")
    print()
    for row in report["results"]:
        print(f"X=[{row['lo']},{row['hi']}]  K_I={row['i_max']}  hard={row['hard_primes']}  "
              f"inverse={row['candidate_mode']}")
        print(f"  cover:   {row['covered_hard_primes']} hit / {row['residual_hard_primes']} residual")
        print(f"  inverse: enumerated_C={row['inverse']['C_candidates']}  "
              f"factorizations={row['inverse']['factorizations']}  "
              f"median={row['inverse']['median_wall_seconds']:.6f}s")
        print(f"  forward: shifts={row['forward']['shift_candidates']}  "
              f"factorizations={row['forward']['factorizations']}  "
              f"median={row['forward']['median_wall_seconds']:.6f}s")
        print(f"  shift:   active_visits={row['shift']['active_visits']}  "
              f"factorizations={row['shift']['factorizations']}  "
              f"median={row['shift']['median_wall_seconds']:.6f}s")
        print(f"  inverse factorization ratio: "
              f"{row['comparison']['inverse_factorizations_to_forward_factorizations']:.6f}")
        print(f"  inverse enumeration ratio:   "
              f"{row['comparison']['inverse_enumerated_C_to_forward_factorizations']:.6f}")
        print(f"  inverse wall ratio:          "
              f"{row['comparison']['inverse_to_forward_wall_ratio']:.6f}")
        print(f"  shift factorization ratio:   "
              f"{row['comparison']['shift_factorizations_to_forward_factorizations']:.6f}")
        print(f"  shift active-visit ratio:    "
              f"{row['comparison']['shift_active_visits_to_forward_shift_candidates']:.6f}")
        print(f"  shift wall ratio:            "
              f"{row['comparison']['shift_to_forward_wall_ratio']:.6f}")
        if row["verification"]:
            print(f"  verified inverse: {row['verification']['inverse']['targets']} targets, "
                  f"{row['verification']['inverse']['mismatches']} mismatches")
            print(f"  verified shift:   {row['verification']['shift']['targets']} targets, "
                  f"{row['verification']['shift']['mismatches']} mismatches")
        print()


def main() -> int:
    ap = argparse.ArgumentParser(description="Benchmark three exact CBX Lane-I orientations")
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
                    help="skip pre-benchmark inverse/shift theorem checks")
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
        "benchmark": "lane-I-orientation-v3",
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
