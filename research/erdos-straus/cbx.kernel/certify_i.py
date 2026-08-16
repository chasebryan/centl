#!/usr/bin/env python3
"""Produce an exact finite certificate for the minimal observed Lane-I ceiling."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
FWD = ROOT / "cbx-forward-i"
SHIFT = ROOT / "cbx-shift-i"


def ensure_built() -> None:
    if FWD.is_file() and SHIFT.is_file():
        return
    subprocess.run(["make", "-C", str(ROOT), "cbx-forward-i", "cbx-shift-i"], check=True)


def run_json(cmd: list[str]) -> dict[str, Any]:
    p = subprocess.run(cmd, text=True, capture_output=True)
    if p.returncode != 0:
        raise SystemExit(
            f"command failed ({p.returncode}): {' '.join(cmd)}\n{p.stderr}{p.stdout}"
        )
    lines = [line for line in p.stdout.splitlines() if line.strip()]
    if not lines:
        raise SystemExit(f"command emitted no JSON: {' '.join(cmd)}")
    try:
        return json.loads(lines[-1])
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid JSON from {' '.join(cmd)}: {exc}") from exc


def read_hits(path: Path) -> dict[int, int]:
    out: dict[int, int] = {}
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        parts = raw.split("\t")
        if len(parts) != 2:
            raise SystemExit(f"{path}:{lineno}: expected p<TAB>k")
        p, k = map(int, parts)
        if p in out:
            raise SystemExit(f"{path}:{lineno}: duplicate prime {p}")
        out[p] = k
    return out


def read_set(path: Path) -> set[int]:
    out: set[int] = set()
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        p = int(raw)
        if p in out:
            raise SystemExit(f"{path}:{lineno}: duplicate prime {p}")
        out.add(p)
    return out


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_hits_bytes(hits: dict[int, int]) -> bytes:
    return "".join(f"{p}\t{hits[p]}\n" for p in sorted(hits)).encode()


def canonical_set_bytes(values: set[int]) -> bytes:
    return "".join(f"{p}\n" for p in sorted(values)).encode()


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Certify the exact finite minimal Lane-I ceiling on a hard-prime interval"
    )
    ap.add_argument("--lo", type=int, default=2)
    ap.add_argument("--hi", type=int, required=True)
    ap.add_argument("--i-max", type=int, default=400)
    ap.add_argument("--segment", type=int, default=1_000_000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if args.lo < 0 or args.hi < max(2, args.lo):
        raise SystemExit("--hi must be >= max(2,--lo)")
    if args.i_max < 3:
        raise SystemExit("--i-max must be >= 3")
    if args.segment < 1 or args.segment > 100_000_000:
        raise SystemExit("--segment must be in 1..100000000")

    ensure_built()
    with tempfile.TemporaryDirectory(prefix="cbx-certify-i-") as td:
        t = Path(td)
        f_hits = t / "forward-hits.tsv"
        f_res = t / "forward-residuals.txt"
        s_hits = t / "shift-hits.tsv"
        s_res = t / "shift-residuals.txt"

        fwd = run_json([
            str(FWD), "--lo", str(args.lo), "--hi", str(args.hi),
            "--i-max", str(args.i_max), "--hits", str(f_hits),
            "--residuals", str(f_res),
        ])
        shift = run_json([
            str(SHIFT), "--lo", str(args.lo), "--hi", str(args.hi),
            "--i-max", str(args.i_max), "--segment", str(args.segment),
            "--verify", "--hits", str(s_hits), "--residuals", str(s_res),
        ])

        fh = read_hits(f_hits)
        sh = read_hits(s_hits)
        fr = read_set(f_res)
        sr = read_set(s_res)
        if fh != sh:
            raise SystemExit("forward/shift exact first-hit maps disagree")
        if fr != sr:
            raise SystemExit("forward/shift residual sets disagree")
        if set(fh) & fr:
            raise SystemExit("hit and residual sets overlap")

        hard = int(fwd["hard_primes"])
        if hard != int(shift["hard_primes"]) or hard != len(fh) + len(fr):
            raise SystemExit("hard-prime accounting does not close")
        if int(shift.get("verification_mismatches", 0)) != 0:
            raise SystemExit("shift-major verification mismatch")

        sufficient = not fr
        deepest = max(fh.values()) if fh else None
        witnesses = sorted(p for p, k in fh.items() if k == deepest) if deepest is not None else []
        predecessor = deepest - 4 if deepest is not None and deepest >= 7 else None

        hit_bytes = canonical_hits_bytes(fh)
        residual_bytes = canonical_set_bytes(fr)
        report: dict[str, Any] = {
            "kernel": "cbx.kernel",
            "certificate": "finite-minimal-Lane-I-ceiling-v1",
            "lo": args.lo,
            "hi": args.hi,
            "tested_i_max": args.i_max,
            "hard_primes": hard,
            "covered_hard_primes": len(fh),
            "residual_hard_primes": len(fr),
            "sufficient_through_domain": sufficient,
            "minimal_sufficient_ceiling": deepest if sufficient else None,
            "previous_admissible_ceiling": predecessor if sufficient else None,
            "deepest_first_hit": deepest,
            "deepest_witness_count": len(witnesses),
            "deepest_witnesses": witnesses,
            "cross_check": {
                "forward_mode": fwd.get("mode"),
                "shift_mode": shift.get("mode"),
                "shift_verification_targets": int(shift.get("verification_targets", 0)),
                "shift_verification_mismatches": int(shift.get("verification_mismatches", 0)),
                "exact_first_hit_map_equal": True,
                "exact_residual_set_equal": True,
            },
            "canonical_sha256": {
                "hits_tsv": digest_bytes(hit_bytes),
                "residuals_txt": digest_bytes(residual_bytes),
            },
            "logic": (
                "If residual_hard_primes=0, max_p k_I*(p) is sufficient on the finite domain. "
                "A prime whose first hit equals that maximum witnesses that every smaller admissible "
                "ceiling is insufficient on the same domain."
            ),
            "claim": (
                "exact finite computational certificate only; no assertion for primes outside the "
                "stated interval and no Erdős–Straus proof"
            ),
        }

        if args.json:
            print(json.dumps(report, indent=2, sort_keys=True))
        else:
            print("cbx.kernel finite minimal Lane-I ceiling certificate")
            print(f"domain: [{args.lo},{args.hi}] hard primes={hard}")
            print(f"tested K_I={args.i_max} covered={len(fh)} residual={len(fr)}")
            if sufficient:
                print(f"minimal finite sufficient ceiling: K_I={deepest}")
                print(f"previous admissible ceiling: {predecessor}")
                print(f"witnesses at K_I={deepest}: {witnesses}")
            else:
                print("tested ceiling is not sufficient on this finite domain")
            print(f"hits sha256: {report['canonical_sha256']['hits_tsv']}")
            print(f"residuals sha256: {report['canonical_sha256']['residuals_txt']}")
            print("finite certificate only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
