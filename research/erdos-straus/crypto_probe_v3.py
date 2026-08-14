#!/usr/bin/env python3
"""High-vs-low Type A/B depth transmission experiment for WS-CAND-003.

Both prime sources satisfy p == 1 mod 840. One source selects primes with
C_AB(p) below a configured floor; the other selects primes that survive every
Type A/B layer below that floor. Toy RSA moduli pair factors from the same
source. The critical public-key test uses only features at k >= depth_floor,
so it cannot simply read the no-hit conditions used to define the labels.

This is a source-fingerprint experiment, not factorization or key recovery.
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


def progression_selected_unique(
    rng: random.Random,
    bits: int,
    samples: int,
    predicate,
    exclude: set[int] | None = None,
) -> tuple[list[int], int]:
    modulus, residue = 840, 1
    low = 1 << (bits - 1)
    high = 1 << bits
    first = low + ((residue - low) % modulus)
    count = (high - first + modulus - 1) // modulus
    excluded = exclude or set()
    found: set[int] = set()
    tried: set[int] = set()
    primes_seen = 0
    while len(found) < samples:
        if len(tried) >= count:
            raise RuntimeError("exhausted progression before collecting requested source")
        idx = rng.randrange(count)
        if idx in tried:
            continue
        tried.add(idx)
        n = first + modulus * idx
        if n >= high or n in excluded or not is_prime(n):
            continue
        primes_seen += 1
        d = predicate(n)
        if d:
            found.add(n)
    xs = sorted(found)
    rng.shuffle(xs)
    return xs, primes_seen


def hit_vector(p: int, traps: list[set[int]], ks: list[int]) -> list[int]:
    return [int(p % (4 * k - 1) in traps[k]) for k in ks]


def product_trap_set(k: int, traps: list[set[int]]) -> set[int]:
    m = 4 * k - 1
    units = [a for a in traps[k] if math.gcd(a, m) == 1]
    return {(a * b) % m for a in units for b in units}


def product_vector(N: int, product_traps: dict[int, set[int]], ks: list[int]) -> list[int]:
    return [int(N % (4 * k - 1) in product_traps[k]) for k in ks]


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
    inv = pow(mm, -1, nn)
    t = (((b - a) // g) * inv) % nn
    L = m * nn
    return (a + m * t) % L, L


def admissible_h1(k: int, traps: list[set[int]]) -> list[int]:
    m = 4 * k - 1
    g = math.gcd(840, m)
    return sorted(t for t in traps[k] if math.gcd(t, m) == 1 and t % g == 1 % g)


def candidate_shadowed(k: int, t: int, j: int, traps: list[set[int]]) -> bool:
    mk, mj = 4 * k - 1, 4 * j - 1
    cr = crt2(1, 840, t, mk)
    if cr is None:
        return False
    r, L = cr
    g = math.gcd(L, mj)
    fibre_size = mj // g
    if fibre_size > len(traps[j]):
        return False
    return set(range(r % g, mj, g)) <= traps[j]


def fully_direct_shadowed_h1(k: int, traps: list[set[int]]) -> bool:
    ts = admissible_h1(k, traps)
    if not ts:
        return False
    return all(
        any(candidate_shadowed(k, t, j, traps) for j in range(1, k))
        for t in ts
    )


def feature_sets(depth_floor: int, k_fp: int, traps: list[set[int]]) -> dict[str, list[int]]:
    full = list(range(1, k_fp + 1))
    post = list(range(depth_floor, k_fp + 1))
    post_strict = list(range(depth_floor + 5, k_fp + 1))
    shadow_post = [k for k in post if not fully_direct_shadowed_h1(k, traps)]
    shadow_post_strict = [
        k for k in post_strict if not fully_direct_shadowed_h1(k, traps)
    ]
    return {
        "full": full,
        "post_selection": post,
        "post_selection_plus5": post_strict,
        "shadow_compressed_post_selection": shadow_post,
        "shadow_compressed_post_selection_plus5": shadow_post_strict,
    }


def stratified_folds(labels: list[int], folds: int, rng: random.Random) -> list[list[int]]:
    by_class = {0: [], 1: []}
    for i, y in enumerate(labels):
        by_class[y].append(i)
    for xs in by_class.values():
        rng.shuffle(xs)
    out = [[] for _ in range(folds)]
    for y in (0, 1):
        for pos, idx in enumerate(by_class[y]):
            out[pos % folds].append(idx)
    return out


def bernoulli_nb_cv(vectors: list[list[int]], labels: list[int], folds: int, rng: random.Random) -> float:
    fold_indices = stratified_folds(labels, folds, rng)
    width = len(vectors[0])
    correct = total = 0
    for test in fold_indices:
        test_set = set(test)
        train = [i for i in range(len(labels)) if i not in test_set]
        ids = {y: [i for i in train if labels[i] == y] for y in (0, 1)}
        probs = {}
        priors = {}
        for y in (0, 1):
            priors[y] = len(ids[y]) / len(train)
            probs[y] = [
                (1 + sum(vectors[i][f] for i in ids[y])) / (2 + len(ids[y]))
                for f in range(width)
            ]
        for i in test:
            scores = {}
            for y in (0, 1):
                score = math.log(priors[y])
                for f, x in enumerate(vectors[i]):
                    p = probs[y][f]
                    score += math.log(p if x else 1 - p)
                scores[y] = score
            pred = 1 if scores[1] > scores[0] else 0
            correct += int(pred == labels[i])
            total += 1
    return correct / total


def suite(v0: list[list[int]], v1: list[list[int]], folds: int, seed: int) -> dict:
    vectors = v0 + v1
    labels = [0] * len(v0) + [1] * len(v1)
    observed = bernoulli_nb_cv(vectors, labels, folds, random.Random(seed))
    shuffled = labels[:]
    random.Random(seed ^ 0x4C4F5045).shuffle(shuffled)
    baseline = bernoulli_nb_cv(vectors, shuffled, folds, random.Random(seed ^ 0xABCD1234))
    return {"observed_accuracy": observed, "shuffled_label_accuracy": baseline}


def summarize(values: list[float]) -> dict:
    mean = statistics.fmean(values)
    sd = statistics.stdev(values) if len(values) > 1 else 0.0
    se = sd / math.sqrt(len(values))
    return {
        "trials": len(values),
        "mean": mean,
        "stdev": sd,
        "min": min(values),
        "max": max(values),
        "approx_95pct_mean_interval": [mean - 1.96 * se, mean + 1.96 * se],
    }


def run_trial(
    bits: int,
    samples: int,
    depth_floor: int,
    k_max: int,
    fmap: dict[str, list[int]],
    traps: list[set[int]],
    folds: int,
    seed: int,
) -> dict:
    rng = random.Random(seed)

    depth_cache: dict[int, int | None] = {}

    def depth(n: int) -> int | None:
        if n not in depth_cache:
            depth_cache[n] = cab_depth(n, traps, k_max)
        return depth_cache[n]

    high, high_primes_seen = progression_selected_unique(
        rng,
        bits,
        samples,
        lambda n: depth(n) is None or depth(n) >= depth_floor,
    )
    low, low_primes_seen = progression_selected_unique(
        rng,
        bits,
        samples,
        lambda n: depth(n) is not None and depth(n) < depth_floor,
        exclude=set(high),
    )

    product_traps = {
        k: product_trap_set(k, traps)
        for ks in fmap.values()
        for k in ks
    }
    result = {
        "seed": seed,
        "source_sampling": {
            "low_source_primes_examined": low_primes_seen,
            "high_source_primes_examined": high_primes_seen,
        },
        "prime": {},
        "public_modulus": {},
    }
    for name, ks in fmap.items():
        p0 = [hit_vector(p, traps, ks) for p in low]
        p1 = [hit_vector(p, traps, ks) for p in high]
        result["prime"][name] = suite(p0, p1, folds, seed + len(ks) * 13)

        n0 = [low[i] * low[i + 1] for i in range(0, samples - 1, 2)]
        n1 = [high[i] * high[i + 1] for i in range(0, samples - 1, 2)]
        v0 = [product_vector(N, product_traps, ks) for N in n0]
        v1 = [product_vector(N, product_traps, ks) for N in n1]
        result["public_modulus"][name] = suite(v0, v1, folds, seed + len(ks) * 29 + 7)

    low_depths = [depth(p) for p in low]
    high_depths = [depth(p) for p in high]
    result["depth"] = {
        "low_mean": statistics.fmean(d for d in low_depths if d is not None),
        "low_max": max(d for d in low_depths if d is not None),
        "high_mean_resolved": statistics.fmean(d for d in high_depths if d is not None) if any(d is not None for d in high_depths) else None,
        "high_max_resolved": max((d for d in high_depths if d is not None), default=None),
        "high_unresolved_above_kmax": sum(d is None for d in high_depths),
    }
    return result


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bits", type=int, default=39)
    ap.add_argument("--samples", type=int, default=120)
    ap.add_argument("--depth-floor", type=int, default=25)
    ap.add_argument("--k-max", type=int, default=500)
    ap.add_argument("--k-fingerprint", type=int, default=120)
    ap.add_argument("--trials", type=int, default=10)
    ap.add_argument("--folds", type=int, default=5)
    ap.add_argument("--seed", type=int, default=20260814)
    ap.add_argument("--out", type=Path, default=Path("cryptology-output"))
    args = ap.parse_args()
    if not (8 <= args.bits <= 63):
        raise SystemExit("--bits must be 8..63")
    if args.samples < max(20, args.folds * 4) or args.samples % 2:
        raise SystemExit("--samples must be even and sufficiently large")
    if not (2 <= args.depth_floor < args.k_fingerprint <= args.k_max):
        raise SystemExit("require 2 <= depth_floor < k_fingerprint <= k_max")

    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    traps = [set()] + [trap_set(k) for k in range(1, args.k_max + 1)]
    fmap = feature_sets(args.depth_floor, args.k_fingerprint, traps)

    trials = [
        run_trial(
            args.bits,
            args.samples,
            args.depth_floor,
            args.k_max,
            fmap,
            traps,
            args.folds,
            args.seed + i * 1013,
        )
        for i in range(args.trials)
    ]

    aggregate = {"prime": {}, "public_modulus": {}}
    for domain in aggregate:
        for name in fmap:
            obs = [t[domain][name]["observed_accuracy"] for t in trials]
            shuf = [t[domain][name]["shuffled_label_accuracy"] for t in trials]
            aggregate[domain][name] = {
                "observed": summarize(obs),
                "shuffled_labels": summarize(shuf),
            }

    result = {
        "status": "high-vs-low C_AB source transmission diagnostic; no cryptographic break claimed",
        "parameters": vars(args) | {"out": str(args.out)},
        "source_definition": {
            "common": "p == 1 mod 840",
            "low": f"C_AB(p) < {args.depth_floor}",
            "high": f"C_AB(p) >= {args.depth_floor}, or unresolved through k_max",
            "public_samples": "N=pq with both toy factors drawn from the same source label",
        },
        "critical_control": (
            f"post-selection feature sets use only k >= {args.depth_floor}; "
            "they omit all lower layers whose absence directly defines the high-depth source"
        ),
        "feature_counts": {name: len(ks) for name, ks in fmap.items()},
        "feature_ks": fmap,
        "aggregate": aggregate,
        "trials": trials,
    }
    (out / "cryptology-v3.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    def row(domain: str, name: str) -> str:
        a = aggregate[domain][name]["observed"]
        b = aggregate[domain][name]["shuffled_labels"]
        lo, hi = a["approx_95pct_mean_interval"]
        return (
            f"- {name}: observed `{a['mean']:.4f}` "
            f"(95% mean interval `{lo:.4f}`..`{hi:.4f}`); "
            f"shuffled `{b['mean']:.4f}`"
        )

    report = "# WS-CAND-003 cryptology probe v3\n\n"
    report += "Status: high-vs-low Type A/B depth source-transmission experiment. No factorization or key-recovery claim.\n\n"
    report += (
        f"Both sources satisfy `p == 1 mod 840`. Low source: `C_AB < {args.depth_floor}`. "
        f"High source: `C_AB >= {args.depth_floor}`. Each trial uses `{args.samples}` primes/source "
        f"and `{args.samples // 2}` toy moduli/source.\n\n"
    )
    report += (
        f"The critical control uses only fingerprint layers `k >= {args.depth_floor}`, "
        "thereby excluding every lower no-hit condition used to select the high-depth factors.\n\n"
    )
    report += "## Prime fingerprint\n\n"
    for name in fmap:
        report += row("prime", name) + "\n"
    report += "\n## Public toy-RSA product fingerprint\n\n"
    for name in fmap:
        report += row("public_modulus", name) + "\n"
    report += (
        "\nDecision rule: a reproducible public-modulus signal in the post-selection and "
        "shadow-compressed post-selection features would show that a secret factor-selection "
        "property leaves a detectable distributional trace in N=pq. It would still not reveal "
        "the factors or constitute an RSA break. Chance-level post-selection performance is a "
        "clean negative result.\n"
    )
    (out / "cryptology-v3-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
