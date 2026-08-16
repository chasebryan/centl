#!/usr/bin/env python3
"""Independent regression for lopez_ab_complete_sqrt_audit.py."""
from __future__ import annotations

import argparse
import json
import math

import lopez_ab_complete_sqrt_audit as fast


def prime_flags(n: int) -> bytearray:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for q in range(2, math.isqrt(n) + 1):
        if bs[q]:
            bs[q * q:n + 1:q] = b"\x00" * (((n - q * q) // q) + 1)
    return bs


def naive_first_ab(p: int, K: int) -> dict[str, int | str] | None:
    for k in range(1, K + 1):
        m = 4 * k - 1
        residue = p % m
        for e in range(1, math.isqrt(k) + 1):
            if k % e:
                continue
            parameters = (e,) if e * e == k else (e, k // e)
            for s in parameters:
                # Historical auditor preference: Type B before Type A.
                n = s
                d = k // s
                if residue == (-n) % m:
                    return {"type": "B", "k": k, "m": m, "d": d, "n_parameter": n}
                d = s
                n = k // s
                if residue == (-4 * d) % m:
                    return {"type": "A", "k": k, "m": m, "d": d, "n_parameter": n}
    return None


def analyze(limit: int) -> dict[str, object]:
    mismatches: list[dict[str, object]] = []
    flags = prime_flags(limit)
    compared = 0

    for p in range(5, limit + 1):
        if not flags[p] or p % 4 != 1:
            continue
        # Safe direct ceiling for the independent old-coordinate check.
        direct = naive_first_ab(p, (p + 1) // 2)
        report = fast.audit(p)
        got = report["first_type_ab"]
        compared += 1
        if (direct is None) != (got is None):
            mismatches.append({"kind": "existence", "p": p, "direct": direct, "sqrt": got})
            continue
        if direct is not None and got is not None:
            for key in ("type", "k", "m", "d", "n_parameter"):
                if direct[key] != got[key]:
                    mismatches.append(
                        {"kind": "first-certificate", "p": p, "key": key, "direct": direct, "sqrt": got}
                    )
                    break

    pinned = {}
    for p in (193, 1009, 2521, 9658489):
        report = fast.audit(p)
        pinned[str(p)] = {
            "type_a_certificate_count": report["type_a_certificate_count"],
            "type_b_canonical_certificate_count": report["type_b_canonical_certificate_count"],
            "first_type_ab": report["first_type_ab"],
            "type_a_offset_bound": report["type_a_offset_bound"],
            "type_b_offset_bound": report["type_b_offset_bound"],
        }

    expected = {
        "193": {"type": "B", "k": 4},
        "1009": {"type": "B", "k": 3},
        "2521": {"type": "B", "k": 22},
        "9658489": {"type": "B", "k": 2622},
    }
    for p, row in expected.items():
        first = pinned[p]["first_type_ab"]
        if first is None or first["type"] != row["type"] or first["k"] != row["k"]:
            mismatches.append({"kind": "pinned-first", "p": int(p), "expected": row, "actual": first})

    if pinned["193"]["type_a_certificate_count"] != 0:
        mismatches.append({"kind": "193-type-a", "actual": pinned["193"]})
    if pinned["2521"]["type_a_certificate_count"] != 0:
        mismatches.append({"kind": "2521-type-a", "actual": pinned["2521"]})
    if pinned["9658489"]["type_a_offset_bound"] != 3108:
        mismatches.append({"kind": "9658489-a-width", "actual": pinned["9658489"]})
    if pinned["9658489"]["type_b_offset_bound"] != 1554:
        mismatches.append({"kind": "9658489-b-width", "actual": pinned["9658489"]})

    return {
        "analysis": "lopez-ab-complete-sqrt-audit-regression-v1",
        "prime_limit": limit,
        "p1mod4_primes_compared": compared,
        "pinned": pinned,
        "mismatches": len(mismatches),
        "mismatch_examples": mismatches[:20],
        "claim": "independent finite cross-check of two exact coordinates; not evidence that Lopez is universally true",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=5000)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.limit)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"p == 1 mod 4 primes compared: {report['p1mod4_primes_compared']}")
        print(f"mismatches: {report['mismatches']}")
        print(f"pinned: {report['pinned']}")
    return 1 if report["mismatches"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
