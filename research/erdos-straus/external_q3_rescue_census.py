#!/usr/bin/env python3
"""Exact finite census of external q==3 mod 4 binary/two-target rescues.

For each Mordell-hard prime p <= X and each prime q <= Q with

    q == 3 (mod 4),
    q < p,
    (q/p) = -1,

this program tests the exact fixed-shift two-target criterion at k=q.  It
factors C=(p+q)/4, constructs residues of divisors of C^2 modulo q, and asks
whether either

    -4^{-1} (Type I)
    -C       (Type II)

is present.  By ES-BINARY-LANE-I-EQUIVALENCE.md this is exactly the external
binary-q rescue test.

The search is finite.  Zero unresolved targets below a chosen X/Q pair is
finite evidence only and is not an Erdős-Straus proof.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

HARD = (1, 121, 169, 289, 361, 529)


def sieve_flags(n: int) -> bytearray:
    bs = bytearray(b"\x01") * (n + 1)
    if n >= 0:
        bs[0] = 0
    if n >= 1:
        bs[1] = 0
    for p in range(2, math.isqrt(n) + 1):
        if bs[p]:
            bs[p * p : n + 1 : p] = b"\x00" * (((n - p * p) // p) + 1)
    return bs


def primes_from_flags(flags: bytearray, hi: int) -> list[int]:
    return [p for p in range(2, hi + 1) if flags[p]]


def factor(n: int, trial: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    x = n
    for r in trial:
        if r * r > x:
            break
        if x % r:
            continue
        e = 0
        while x % r == 0:
            x //= r
            e += 1
        out[r] = e
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def legendre_q_over_p_for_hard_p(p: int, q: int) -> int:
    """Return (q/p), using p==1 mod 4 to transfer to the small prime q."""
    # Quadratic reciprocity has no sign because p == 1 mod 4:
    # (q/p) = (p/q).
    a = p % q
    if a == 0:
        return 0
    v = pow(a, (q - 1) // 2, q)
    return -1 if v == q - 1 else v


def divisor_square_representatives(
    fac: dict[int, int], mod: int
) -> dict[int, int]:
    """Map each attained divisor residue of C^2 to one literal divisor."""
    reach: dict[int, int] = {1: 1}
    for r, e in fac.items():
        local: list[tuple[int, int]] = []
        residue = 1
        integer = 1
        for _ in range(2 * e + 1):
            local.append((residue, integer))
            residue = residue * r % mod
            integer *= r

        nxt: dict[int, int] = {}
        for base_residue, base_integer in reach.items():
            for local_residue, local_integer in local:
                rr = base_residue * local_residue % mod
                if rr not in nxt:
                    nxt[rr] = base_integer * local_integer
        reach = nxt
    return reach


def analyze(limit: int, q_max: int, include_hits: bool) -> dict[str, object]:
    if limit < 2:
        raise ValueError("limit must be >= 2")
    if q_max < 3:
        raise ValueError("q_max must be >= 3")

    sieve_hi = max(limit, q_max)
    flags = sieve_flags(sieve_hi)
    hard = [
        p for p in range(2, limit + 1)
        if flags[p] and p % 840 in HARD
    ]
    q_candidates = [
        q for q in range(3, q_max + 1, 4)
        if flags[q]
    ]

    max_c = (limit + q_max) // 4
    trial_hi = math.isqrt(max_c) + 1
    trial = primes_from_flags(flags, trial_hi)

    histogram: Counter[int] = Counter()
    unresolved: list[int] = []
    hit_rows: list[dict[str, object]] = []
    external_tests = 0
    deepest: dict[str, object] | None = None

    for p in hard:
        row: dict[str, object] | None = None
        for q in q_candidates:
            if q >= p:
                break
            if legendre_q_over_p_for_hard_p(p, q) != -1:
                continue

            external_tests += 1
            C = (p + q) // 4
            fac = factor(C, trial)
            reps = divisor_square_representatives(fac, q)
            tau_i = (-pow(4, -1, q)) % q
            tau_ii = (-C) % q
            hit_i = tau_i in reps
            hit_ii = tau_ii in reps
            if not (hit_i or hit_ii):
                continue

            row = {
                "p": p,
                "q": q,
                "C": C,
                "factorization": fac,
                "type_i": hit_i,
                "type_ii": hit_ii,
                "type_i_target": tau_i,
                "type_ii_target": tau_ii,
                "type_i_divisor": reps.get(tau_i),
                "type_ii_divisor": reps.get(tau_ii),
                "divisor_residue_count": len(reps),
            }
            histogram[q] += 1
            if deepest is None or q > int(deepest["q"]):
                deepest = dict(row)
            if include_hits:
                hit_rows.append(dict(row))
            break

        if row is None:
            unresolved.append(p)

    report: dict[str, object] = {
        "analysis": "external-q3-binary-rescue-census-v1",
        "limit": limit,
        "q_max": q_max,
        "hard_primes": len(hard),
        "external_q_tests": external_tests,
        "covered_hard_primes": len(hard) - len(unresolved),
        "unresolved_hard_primes": len(unresolved),
        "unresolved": unresolved,
        "first_success_histogram": {
            str(q): histogram[q] for q in sorted(histogram)
        },
        "deepest_first_success": deepest,
        "claim": (
            "exact finite census only; zero unresolved below the configured "
            "bounds is not a universal theorem"
        ),
    }
    if include_hits:
        report["hits"] = hit_rows
    return report


def validate(report: dict[str, object]) -> None:
    if report["analysis"] != "external-q3-binary-rescue-census-v1":
        raise SystemExit("unexpected analysis tag")
    hard = int(report["hard_primes"])
    covered = int(report["covered_hard_primes"])
    unresolved = int(report["unresolved_hard_primes"])
    if covered + unresolved != hard:
        raise SystemExit("coverage accounting mismatch")
    if unresolved != len(report["unresolved"]):
        raise SystemExit("unresolved list/count mismatch")
    if sum(report["first_success_histogram"].values()) != covered:
        raise SystemExit("first-success histogram does not sum to coverage")

    deepest = report["deepest_first_success"]
    if deepest is not None:
        C = int(deepest["C"])
        for key in ("type_i_divisor", "type_ii_divisor"):
            d = deepest[key]
            if d is not None and (C * C) % int(d):
                raise SystemExit(f"{key} is not a divisor of C^2")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=100_000)
    ap.add_argument("--q-max", type=int, default=419)
    ap.add_argument("--json", action="store_true")
    ap.add_argument(
        "--hits",
        action="store_true",
        help="include one first-success row for every covered hard prime",
    )
    ap.add_argument(
        "--require-complete",
        action="store_true",
        help="exit nonzero if any hard prime is unresolved at the configured q ceiling",
    )
    args = ap.parse_args()

    report = analyze(args.limit, args.q_max, args.hits)
    validate(report)

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(
            f"hard={report['hard_primes']} covered={report['covered_hard_primes']} "
            f"unresolved={report['unresolved_hard_primes']} "
            f"external-tests={report['external_q_tests']}"
        )
        print(f"first-success histogram: {report['first_success_histogram']}")
        print(f"deepest: {report['deepest_first_success']}")
        print("warning: finite census only; Erdős-Straus remains open")

    if args.require_complete and report["unresolved_hard_primes"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
