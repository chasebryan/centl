#!/usr/bin/env python3
"""Measure threshold pre-shadow load and empirical survivor depletion.

For a fixed hard residue class h mod 840 and survival threshold D, this script
computes the exact fraction of admissible layer-k Type A/B candidates that are
directly shadowed by some earlier j < D. It then samples three prime populations:

  baseline: p == h mod 840
  low:      p == h mod 840 and C_AB(p) < D
  high:     p == h mod 840 and C_AB(p) >= D

and compares later-layer hit rates. The theorem-level invariant checked here is
that the high population can never occupy a candidate class pre-shadowed by an
earlier j < D.

This is arithmetic-structure research. It makes no cryptographic break claim.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo, hi = [], []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for d in divisors(k) for r in ((-d) % m, (-4 * d) % m)}


def is_prime(n: int) -> bool:
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
        s += 1
        d //= 2
    for a in (2, 325, 9375, 28178, 450775, 9780504, 1795265022):
        if a % n == 0:
            continue
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = (x * x) % n
            if x == n - 1:
                break
        else:
            return False
    return True


def cab_depth(p: int, traps: list[set[int]], k_max: int) -> int | None:
    for k in range(1, k_max + 1):
        if p % (4 * k - 1) in traps[k]:
            return k
    return None


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
    inv = pow(mm, -1, nn)
    t = (((b - a) // g) * inv) % nn
    L = m * nn
    return (a + m * t) % L, L


def admissible_pairs(k: int, h: int, traps: list[set[int]]) -> list[tuple[int, int]]:
    m = 4 * k - 1
    g = math.gcd(840, m)
    return sorted(
        (h, t)
        for t in traps[k]
        if math.gcd(t, m) == 1 and t % g == h % g
    )


def candidate_shadowed_by(k: int, h: int, t: int, j: int, traps: list[set[int]]) -> bool:
    mk, mj = 4 * k - 1, 4 * j - 1
    cr = crt2(h, 840, t, mk)
    if cr is None:
        return False
    r, L = cr
    g = math.gcd(L, mj)
    fibre_size = mj // g
    if fibre_size > len(traps[j]):
        return False
    possible = set(range(r % g, mj, g))
    return possible <= traps[j]


def preshadow_map(
    depth_floor: int,
    k_fingerprint: int,
    h: int,
    traps: list[set[int]],
) -> dict[int, dict]:
    out: dict[int, dict] = {}
    for k in range(depth_floor, k_fingerprint + 1):
        pairs = admissible_pairs(k, h, traps)
        shadowed = []
        novel = []
        sources: dict[str, list[int]] = {}
        for _, t in pairs:
            js = [
                j
                for j in range(1, depth_floor)
                if candidate_shadowed_by(k, h, t, j, traps)
            ]
            if js:
                shadowed.append(t)
                sources[str(t)] = js
            else:
                novel.append(t)
        out[k] = {
            "k": k,
            "m": 4 * k - 1,
            "admissible_classes": len(pairs),
            "preshadowed_classes": len(shadowed),
            "unshadowed_classes": len(novel),
            "sigma": (len(shadowed) / len(pairs)) if pairs else None,
            "preshadowed_residues": shadowed,
            "unshadowed_residues": novel,
            "sources": sources,
        }
    return out


def sample_progression_primes(
    rng: random.Random,
    bits: int,
    h: int,
    count: int,
    predicate,
    exclude: set[int] | None = None,
) -> tuple[list[int], int]:
    modulus = 840
    low = 1 << (bits - 1)
    high = 1 << bits
    first = low + ((h - low) % modulus)
    slots = (high - first + modulus - 1) // modulus
    seen_slots: set[int] = set()
    excluded = exclude or set()
    found: set[int] = set()
    primes_examined = 0
    while len(found) < count:
        if len(seen_slots) >= slots:
            raise RuntimeError("exhausted progression before collecting requested sample")
        idx = rng.randrange(slots)
        if idx in seen_slots:
            continue
        seen_slots.add(idx)
        n = first + modulus * idx
        if n >= high or n in excluded or not is_prime(n):
            continue
        primes_examined += 1
        if predicate(n):
            found.add(n)
    xs = sorted(found)
    rng.shuffle(xs)
    return xs, primes_examined


def pearson(xs: list[float], ys: list[float]) -> float | None:
    if len(xs) != len(ys) or len(xs) < 2:
        return None
    mx, my = statistics.fmean(xs), statistics.fmean(ys)
    dx = [x - mx for x in xs]
    dy = [y - my for y in ys]
    den = math.sqrt(sum(x * x for x in dx) * sum(y * y for y in dy))
    if den == 0:
        return None
    return sum(x * y for x, y in zip(dx, dy)) / den


def hit_rate(ps: list[int], k: int, traps: list[set[int]]) -> float:
    m = 4 * k - 1
    return sum(p % m in traps[k] for p in ps) / len(ps)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bits", type=int, default=39)
    ap.add_argument("--samples", type=int, default=600)
    ap.add_argument("--h", type=int, default=1)
    ap.add_argument("--depth-floor", type=int, default=25)
    ap.add_argument("--k-max", type=int, default=500)
    ap.add_argument("--k-fingerprint", type=int, default=120)
    ap.add_argument("--seed", type=int, default=20260814)
    ap.add_argument("--out", type=Path, default=Path("cryptology-output"))
    args = ap.parse_args()
    if not (8 <= args.bits <= 63):
        raise SystemExit("--bits must be 8..63")
    if args.samples < 50:
        raise SystemExit("--samples must be at least 50")
    if not (2 <= args.depth_floor <= args.k_fingerprint <= args.k_max):
        raise SystemExit("require 2 <= depth_floor <= k_fingerprint <= k_max")

    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    traps = [set()] + [trap_set(k) for k in range(1, args.k_max + 1)]
    pmap = preshadow_map(args.depth_floor, args.k_fingerprint, args.h, traps)

    rng = random.Random(args.seed)
    depth_cache: dict[int, int | None] = {}

    def depth(n: int) -> int | None:
        if n not in depth_cache:
            depth_cache[n] = cab_depth(n, traps, args.k_max)
        return depth_cache[n]

    baseline, baseline_examined = sample_progression_primes(
        rng, args.bits, args.h, args.samples, lambda _n: True
    )
    used = set(baseline)
    low, low_examined = sample_progression_primes(
        rng,
        args.bits,
        args.h,
        args.samples,
        lambda n: depth(n) is not None and depth(n) < args.depth_floor,
        exclude=used,
    )
    used |= set(low)
    high, high_examined = sample_progression_primes(
        rng,
        args.bits,
        args.h,
        args.samples,
        lambda n: depth(n) is None or depth(n) >= args.depth_floor,
        exclude=used,
    )

    layers = []
    theorem_violations = []
    for k in range(args.depth_floor, args.k_fingerprint + 1):
        info = pmap[k]
        m = info["m"]
        pre = set(info["preshadowed_residues"])
        base_rate = hit_rate(baseline, k, traps)
        low_rate = hit_rate(low, k, traps)
        high_rate = hit_rate(high, k, traps)
        bad = [p for p in high if p % m in pre]
        if bad:
            theorem_violations.append({"k": k, "primes": bad[:20], "count": len(bad)})
        layers.append(
            info
            | {
                "baseline_hit_rate": base_rate,
                "low_hit_rate": low_rate,
                "high_hit_rate": high_rate,
                "baseline_minus_high": base_rate - high_rate,
                "low_minus_high": low_rate - high_rate,
                "high_preshadowed_hits": len(bad),
            }
        )

    if theorem_violations:
        raise SystemExit(f"threshold-shadow theorem violation in finite sample: {theorem_violations[:3]}")

    eligible = [r for r in layers if r["sigma"] is not None]
    sigmas = [float(r["sigma"]) for r in eligible]
    corr_baseline = pearson(sigmas, [r["baseline_minus_high"] for r in eligible])
    corr_low = pearson(sigmas, [r["low_minus_high"] for r in eligible])

    fully = [r["k"] for r in eligible if r["sigma"] == 1.0]
    partial = [r["k"] for r in eligible if 0.0 < r["sigma"] < 1.0]
    fresh = [r["k"] for r in eligible if r["sigma"] == 0.0]

    result = {
        "status": "threshold-shadow arithmetic diagnostic; no cryptographic break claimed",
        "parameters": {
            "bits": args.bits,
            "samples_per_population": args.samples,
            "hard_class_h_mod_840": args.h,
            "depth_floor": args.depth_floor,
            "k_max": args.k_max,
            "k_fingerprint": args.k_fingerprint,
            "seed": args.seed,
        },
        "sampling": {
            "baseline_primes_examined": baseline_examined,
            "low_primes_examined": low_examined,
            "high_primes_examined": high_examined,
            "populations_are_pairwise_disjoint": True,
        },
        "theorem_check": {
            "statement": "C_AB(p) >= D excludes every later candidate directly shadowed by any j < D",
            "violations": theorem_violations,
            "verdict": "VERIFIED IN FINITE SAMPLE",
        },
        "layer_counts": {
            "fully_preshadowed": len(fully),
            "partially_preshadowed": len(partial),
            "zero_preshadow_load": len(fresh),
        },
        "fully_preshadowed_layers": fully,
        "partially_preshadowed_layers": partial,
        "zero_preshadow_load_layers": fresh,
        "correlations": {
            "pearson_sigma_vs_baseline_minus_high_hit_rate": corr_baseline,
            "pearson_sigma_vs_low_minus_high_hit_rate": corr_low,
            "interpretation": "descriptive finite-sample correlation only; theorem is the support exclusion, not a probabilistic law",
        },
        "layers": layers,
    }
    (out / "threshold-shadow-probe.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    ranked = sorted(
        (r for r in eligible if r["sigma"] > 0),
        key=lambda r: (-r["sigma"], r["k"]),
    )[:20]
    report = "# Threshold-shadow depletion probe\n\n"
    report += (
        f"Hard class: `{args.h} mod 840`; threshold `D={args.depth_floor}`; "
        f"layers `{args.depth_floor}..{args.k_fingerprint}`; "
        f"`{args.samples}` primes in each of baseline/low/high populations.\n\n"
    )
    report += (
        "Exact theorem check: no sampled high-depth prime occupied a later candidate "
        "directly shadowed by a layer below D. Verdict: `VERIFIED IN FINITE SAMPLE`.\n\n"
    )
    report += (
        f"Layer counts: fully pre-shadowed `{len(fully)}`, partially pre-shadowed "
        f"`{len(partial)}`, zero pre-shadow load `{len(fresh)}`.\n\n"
    )
    report += (
        f"Pearson correlation sigma_D(k) vs baseline-minus-high hit-rate depletion: "
        f"`{corr_baseline if corr_baseline is not None else 'undefined'}`.\n\n"
    )
    report += (
        f"Pearson correlation sigma_D(k) vs low-minus-high hit-rate depletion: "
        f"`{corr_low if corr_low is not None else 'undefined'}`.\n\n"
    )
    report += "## Highest pre-shadow loads\n\n"
    report += "| k | m | classes | pre-shadowed | sigma | baseline hit | low hit | high hit |\n"
    report += "|---:|---:|---:|---:|---:|---:|---:|---:|\n"
    for r in ranked:
        report += (
            f"| {r['k']} | {r['m']} | {r['admissible_classes']} | "
            f"{r['preshadowed_classes']} | {r['sigma']:.4f} | "
            f"{r['baseline_hit_rate']:.4f} | {r['low_hit_rate']:.4f} | "
            f"{r['high_hit_rate']:.4f} |\n"
        )
    report += (
        "\nThe correlations are exploratory. The rigorous result is the support restriction: "
        "a deep survivor cannot occupy any later CRT candidate that is already implied by an "
        "earlier rejected layer.\n"
    )
    (out / "threshold-shadow-probe-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
