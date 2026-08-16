#!/usr/bin/env python3
"""Exact post-hoc Lane-I Type-I/Type-II root-geometry analyzer for cbx.kernel.

Consumes CBX observation JSONL without changing cover semantics.  For every
Lane-I hit it reopens only the observed first shift k, factors C=(p+k)/4,
and enumerates Div(C^2) exactly.  This identifies which exact fixed-shift
mechanisms are present at the first hit:

  Type I : 4d == -1 (mod k)
  Type II: d  == -C (mod k)

For Type-II witnesses d=s*b^2, C^2/d=s*c^2, C=s*b*c with s squarefree,
root comparability is classified as b|c, c|b, or incomparable.  The analyzer
is observational: it does not add a lane and does not alter W->I->N->L.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

REL_B_DIV_C = 1
REL_C_DIV_B = 2
REL_INCOMPARABLE = 4


def primes_upto(limit: int) -> list[int]:
    if limit < 2:
        return []
    sieve = bytearray(b"\x01") * (limit + 1)
    sieve[:2] = b"\x00\x00"
    for p in range(2, math.isqrt(limit) + 1):
        if sieve[p]:
            start = p * p
            sieve[start : limit + 1 : p] = b"\x00" * (((limit - start) // p) + 1)
    return [i for i, flag in enumerate(sieve) if flag]


MR_BASES_64 = (2, 325, 9375, 28178, 450775, 9780504, 1795265022)


def is_prime64(n: int) -> bool:
    if n < 2:
        return False
    small = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    for p in small:
        if n == p:
            return True
        if n % p == 0:
            return False
    d = n - 1
    s = 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for a in MR_BASES_64:
        if a % n == 0:
            continue
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(1, s):
            x = (x * x) % n
            if x == n - 1:
                break
        else:
            return False
    return True


def pollard_rho(n: int) -> int:
    if n % 2 == 0:
        return 2
    if n % 3 == 0:
        return 3
    # Deterministic parameter schedule keeps analysis reproducible.
    for c in range(1, 128):
        x = 2 + c
        y = x
        d = 1
        for _ in range(2_000_000):
            x = (x * x + c) % n
            y = (y * y + c) % n
            y = (y * y + c) % n
            d = math.gcd(abs(x - y), n)
            if d == 1:
                continue
            if d != n:
                return d
            break
    raise RuntimeError(f"Pollard-rho failed to split {n}")


def factor_residual(n: int, out: list[int]) -> None:
    if n == 1:
        return
    if is_prime64(n):
        out.append(n)
        return
    d = pollard_rho(n)
    factor_residual(d, out)
    factor_residual(n // d, out)


def factor_with_primes(n: int, primes: Iterable[int]) -> list[tuple[int, int]]:
    if n < 1:
        raise ValueError("factor input must be positive")
    flat: list[int] = []
    rem = n
    for p in primes:
        if p * p > rem:
            break
        while rem % p == 0:
            flat.append(p)
            rem //= p
    if rem > 1:
        factor_residual(rem, flat)
    flat.sort()
    out: list[tuple[int, int]] = []
    for p in flat:
        if out and out[-1][0] == p:
            q, e = out[-1]
            out[-1] = (q, e + 1)
        else:
            out.append((p, 1))
    return out


def relation_name(mask: int) -> str:
    comparable = bool(mask & (REL_B_DIV_C | REL_C_DIV_B))
    interior = bool(mask & REL_INCOMPARABLE)
    if comparable and interior:
        return "mixed"
    if interior:
        return "interior-only"
    if comparable:
        return "boundary-only"
    return "n/a"


def mechanism_name(type_i: bool, type_ii: bool) -> str:
    if type_i and type_ii:
        return "both"
    if type_i:
        return "type-I-only"
    if type_ii:
        return "type-II-only"
    return "none"


def classify_pair(p: int, k: int, primes: list[int] | None = None) -> dict[str, object]:
    if p < 2 or k < 3:
        raise ValueError("p>=2 and k>=3 required")
    if k % 4 != 3:
        raise ValueError(f"k={k} is not 3 mod 4")
    if math.gcd(p, k) != 1:
        raise ValueError(f"gcd(p,k) != 1 for p={p}, k={k}")
    if (p + k) % 4:
        raise ValueError(f"p+k is not divisible by 4 for p={p}, k={k}")

    C = (p + k) // 4
    if primes is None:
        primes = primes_upto(min(math.isqrt(C), 10_000))
    factors = factor_with_primes(C, primes)

    type_i_target = (-pow(4, -1, k)) % k
    type_ii_target = (-C) % k

    type_i_witnesses = 0
    type_ii_witnesses = 0
    rel_mask = 0
    boundary_witness: tuple[int, int, int] | None = None
    interior_witness: tuple[int, int, int] | None = None

    def visit(i: int, d_mod: int, s: int, b: int, c: int,
              b_div_c: bool, c_div_b: bool) -> None:
        nonlocal type_i_witnesses, type_ii_witnesses, rel_mask
        nonlocal boundary_witness, interior_witness

        if i == len(factors):
            if d_mod == type_i_target:
                type_i_witnesses += 1
            if d_mod != type_ii_target:
                return

            type_ii_witnesses += 1
            witness = (s, b, c)
            if s * b * c != C:
                raise AssertionError("root reconstruction failed")

            if b_div_c:
                rel_mask |= REL_B_DIV_C
            if c_div_b:
                rel_mask |= REL_C_DIV_B
            if not b_div_c and not c_div_b:
                rel_mask |= REL_INCOMPARABLE
                if interior_witness is None or witness < interior_witness:
                    interior_witness = witness
            else:
                if boundary_witness is None or witness < boundary_witness:
                    boundary_witness = witness
            return

        q, e = factors[i]
        q_mod_pow = 1 % k
        for u in range(2 * e + 1):
            parity = u & 1
            beta = (u - parity) // 2
            gamma = (2 * e - u - parity) // 2
            visit(
                i + 1,
                (d_mod * q_mod_pow) % k,
                s * (q ** parity),
                b * (q ** beta),
                c * (q ** gamma),
                b_div_c and beta <= gamma,
                c_div_b and gamma <= beta,
            )
            q_mod_pow = (q_mod_pow * (q % k)) % k

    visit(0, 1 % k, 1, 1, 1, True, True)

    type_i = type_i_witnesses > 0
    type_ii = type_ii_witnesses > 0
    if not (type_i or type_ii):
        raise ValueError(
            f"supplied Lane-I hit has no divisor-square target at p={p}, k={k}"
        )

    return {
        "p": p,
        "first_k": k,
        "C": C,
        "factors_C": [[q, e] for q, e in factors],
        "mechanism": mechanism_name(type_i, type_ii),
        "type_i": type_i,
        "type_ii": type_ii,
        "type_i_witnesses": type_i_witnesses,
        "type_ii_witnesses": type_ii_witnesses,
        "type_ii_region": relation_name(rel_mask),
        "relations": {
            "b_divides_c": bool(rel_mask & REL_B_DIV_C),
            "c_divides_b": bool(rel_mask & REL_C_DIV_B),
            "incomparable": bool(rel_mask & REL_INCOMPARABLE),
        },
        "boundary_witness": (
            None if boundary_witness is None else
            {"s": boundary_witness[0], "b": boundary_witness[1], "c": boundary_witness[2]}
        ),
        "interior_witness": (
            None if interior_witness is None else
            {"s": interior_witness[0], "b": interior_witness[1], "c": interior_witness[2]}
        ),
    }


def quantile_nearest(values: list[int], q: float) -> int | None:
    if not values:
        return None
    xs = sorted(values)
    idx = max(0, min(len(xs) - 1, math.ceil(q * len(xs)) - 1))
    return xs[idx]


def depth_stats(values: list[int]) -> dict[str, int | None]:
    return {
        "count": len(values),
        "p50": quantile_nearest(values, 0.50),
        "p90": quantile_nearest(values, 0.90),
        "p99": quantile_nearest(values, 0.99),
        "max": max(values) if values else None,
    }


def load_hits(paths: list[Path]) -> tuple[list[tuple[int, int, str | None]], int]:
    # Deduplicate exact (p,k) observations.  A prime appearing with different
    # first_k values is preserved as separate evidence rather than silently
    # collapsed; the summary exposes the count of such conflicts.
    seen: dict[tuple[int, int], str | None] = {}
    raw_hits = 0
    for path in paths:
        with path.open("r", encoding="utf-8") as fh:
            for lineno, line in enumerate(fh, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError as exc:
                    raise ValueError(f"{path}:{lineno}: invalid JSON: {exc}") from exc
                lane = row.get("I")
                if not isinstance(lane, dict) or not lane.get("hit"):
                    continue
                p = int(row["n"])
                k = int(lane["first_k"])
                if k <= 0:
                    raise ValueError(f"{path}:{lineno}: I.hit=true with first_k={k}")
                spectrum = row.get("spectrum")
                seen.setdefault((p, k), spectrum if isinstance(spectrum, str) else None)
                raw_hits += 1
    hits = [(p, k, spectrum) for (p, k), spectrum in sorted(seen.items())]
    return hits, raw_hits


def summarize(rows: list[dict[str, object]], raw_hits: int) -> dict[str, object]:
    mechanism = Counter(str(r["mechanism"]) for r in rows)
    region = Counter(str(r["type_ii_region"]) for r in rows if r["type_ii"])
    spectra = Counter(str(r.get("spectrum")) for r in rows if r.get("spectrum") is not None)

    by_prime: dict[int, set[int]] = defaultdict(set)
    for r in rows:
        by_prime[int(r["p"])].add(int(r["first_k"]))
    first_k_conflicts = sum(1 for ks in by_prime.values() if len(ks) > 1)

    depth_groups: dict[str, list[int]] = defaultdict(list)
    for r in rows:
        k = int(r["first_k"])
        depth_groups["all"].append(k)
        depth_groups[str(r["mechanism"])].append(k)
        if r["type_ii"]:
            depth_groups[f"type-II/{r['type_ii_region']}"].append(k)

    max_k = max((int(r["first_k"]) for r in rows), default=None)
    records = []
    if max_k is not None:
        records = [r for r in rows if int(r["first_k"]) == max_k]

    return {
        "analyzer": "cbx-lane-I-root-geometry-v1",
        "raw_lane_i_hit_rows": raw_hits,
        "unique_p_k_hits": len(rows),
        "unique_primes": len(by_prime),
        "primes_with_conflicting_first_k": first_k_conflicts,
        "mechanism_counts": dict(sorted(mechanism.items())),
        "type_ii_region_counts": dict(sorted(region.items())),
        "spectrum_counts": dict(sorted(spectra.items())),
        "depth": {name: depth_stats(vals) for name, vals in sorted(depth_groups.items())},
        "max_first_k": max_k,
        "max_first_k_records": [
            {
                "p": int(r["p"]),
                "first_k": int(r["first_k"]),
                "mechanism": r["mechanism"],
                "type_ii_region": r["type_ii_region"],
                "boundary_witness": r["boundary_witness"],
                "interior_witness": r["interior_witness"],
            }
            for r in records
        ],
        "claim_boundary": (
            "finite exact post-hoc classification of observed Lane-I first hits; "
            "not an Erdős-Straus proof and not a Lopez-all-primes disproof"
        ),
    }


def self_test() -> None:
    cases = [
        (1009, 3, "both", "boundary-only", (11, 1, 23), None),
        (2521, 23, "both", "interior-only", None, (2, 2, 159)),
        (8803369, 107, "type-II-only", "boundary-only", (1, 11, 200079), None),
    ]
    max_c = max((p + k) // 4 for p, k, *_ in cases)
    primes = primes_upto(min(math.isqrt(max_c), 10_000))
    for p, k, mechanism, region, boundary, interior in cases:
        row = classify_pair(p, k, primes)
        assert row["mechanism"] == mechanism, (p, row)
        assert row["type_ii_region"] == region, (p, row)
        if boundary is not None:
            got = row["boundary_witness"]
            assert got == {"s": boundary[0], "b": boundary[1], "c": boundary[2]}, (p, row)
        else:
            assert row["boundary_witness"] is None, (p, row)
        if interior is not None:
            got = row["interior_witness"]
            assert got == {"s": interior[0], "b": interior[1], "c": interior[2]}, (p, row)
        else:
            assert row["interior_witness"] is None, (p, row)
    print("cbx Lane-I root geometry self-test OK")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("inputs", nargs="*", type=Path, help="CBX observation JSONL files")
    ap.add_argument("--rows", type=Path, help="write enriched unique p/k rows as JSONL")
    ap.add_argument("--json", action="store_true", help="emit machine-readable summary")
    ap.add_argument("--p", type=int, help="classify one supplied prime/pair")
    ap.add_argument("--k", type=int, help="shift for --p")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        self_test()
        return 0

    if args.p is not None:
        if args.k is None:
            ap.error("--p requires --k")
        row = classify_pair(args.p, args.k)
        print(json.dumps(row, sort_keys=True))
        return 0

    if args.k is not None:
        ap.error("--k requires --p")
    if not args.inputs:
        ap.error("provide at least one observation JSONL file, or use --p/--k")

    hits, raw_hits = load_hits(args.inputs)
    if not hits:
        summary = summarize([], raw_hits)
        print(json.dumps(summary, sort_keys=True) if args.json else "no Lane-I hits")
        return 0

    max_c = max((p + k) // 4 for p, k, _ in hits)
    primes = primes_upto(min(math.isqrt(max_c), 10_000))

    rows: list[dict[str, object]] = []
    for p, k, spectrum in hits:
        row = classify_pair(p, k, primes)
        if spectrum is not None:
            row["spectrum"] = spectrum
        rows.append(row)

    if args.rows:
        args.rows.parent.mkdir(parents=True, exist_ok=True)
        with args.rows.open("w", encoding="utf-8") as fh:
            for row in rows:
                fh.write(json.dumps(row, sort_keys=True) + "\n")

    summary = summarize(rows, raw_hits)
    if args.json:
        print(json.dumps(summary, sort_keys=True))
    else:
        print("CBX Lane-I exact root geometry")
        print(f"unique p/k hits: {summary['unique_p_k_hits']}")
        print(f"mechanisms: {summary['mechanism_counts']}")
        print(f"Type-II regions: {summary['type_ii_region_counts']}")
        print(f"max first k: {summary['max_first_k']}")
        for rec in summary["max_first_k_records"]:
            print(
                f"  p={rec['p']} k={rec['first_k']} {rec['mechanism']} "
                f"Type-II={rec['type_ii_region']}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
