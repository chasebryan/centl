#!/usr/bin/env python3
"""Repeated, held-out cryptology diagnostics for WS-CAND-003.

This probe asks a narrower question than crypto_probe.py:
can Type A/B fingerprints distinguish two prime sources that share p == 1 mod 840
when the second source additionally plants p == 1 mod 11,19,23?

It reports full fingerprints, masks out every feature modulus sharing a factor with
the planted extra modulus, and separately removes fully direct-shadowed h=1 layers.
It performs held-out Bernoulli naive-Bayes classification and a shuffled-label baseline
for both prime fingerprints and public toy-RSA product fingerprints.

No key recovery or cryptographic break is attempted or claimed.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from pathlib import Path

EXTRA_MODULUS = 11 * 19 * 23
STRUCTURED_MODULUS = math.lcm(840, EXTRA_MODULUS)


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


def progression_primes_unique(
    rng: random.Random,
    bits: int,
    modulus: int,
    residue: int,
    samples: int,
    exclude: set[int] | None = None,
) -> list[int]:
    low = 1 << (bits - 1)
    high = 1 << bits
    first = low + ((residue - low) % modulus)
    count = (high - first + modulus - 1) // modulus
    if count <= 0:
        raise RuntimeError("empty arithmetic progression in requested bit range")
    excluded = exclude or set()
    found: set[int] = set()
    tried: set[int] = set()
    while len(found) < samples:
        if len(tried) >= count:
            raise RuntimeError(
                f"arithmetic progression contains fewer than {samples} usable primes in requested bit range; increase --bits or reduce --samples"
            )
        idx = rng.randrange(count)
        if idx in tried:
            continue
        tried.add(idx)
        n = first + modulus * idx
        if n < high and n not in excluded and is_prime(n):
            found.add(n)
    xs = sorted(found)
    rng.shuffle(xs)
    return xs


def cab_depth(p: int, traps: list[set[int]], k_max: int) -> int | None:
    for k in range(1, k_max + 1):
        if p % (4 * k - 1) in traps[k]:
            return k
    return None


def hit_vector(p: int, traps: list[set[int]], feature_ks: list[int]) -> list[int]:
    return [int(p % (4 * k - 1) in traps[k]) for k in feature_ks]


def product_trap_set(k: int, traps: list[set[int]]) -> set[int]:
    m = 4 * k - 1
    units = [a for a in traps[k] if math.gcd(a, m) == 1]
    return {(a * b) % m for a in units for b in units}


def product_vector(N: int, product_traps: dict[int, set[int]], feature_ks: list[int]) -> list[int]:
    return [int(N % (4 * k - 1) in product_traps[k]) for k in feature_ks]


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm = m // g
    nn = n // g
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
    base = r % g
    possible = set(range(base, mj, g))
    return possible <= traps[j]


def fully_direct_shadowed_h1(k: int, traps: list[set[int]]) -> bool:
    ts = admissible_h1(k, traps)
    if not ts:
        return False
    for t in ts:
        if not any(candidate_shadowed(k, t, j, traps) for j in range(1, k)):
            return False
    return True


def feature_sets(k_fp: int, traps: list[set[int]]) -> dict[str, list[int]]:
    full = list(range(1, k_fp + 1))
    coprime = [k for k in full if math.gcd(4 * k - 1, EXTRA_MODULUS) == 1]
    deep_coprime = [k for k in coprime if k > 6]
    shadow_compressed = [k for k in full if not fully_direct_shadowed_h1(k, traps)]
    shadow_coprime = [
        k
        for k in shadow_compressed
        if math.gcd(4 * k - 1, EXTRA_MODULUS) == 1 and k > 6
    ]
    return {
        "full": full,
        "coprime_to_planted_modulus": coprime,
        "deep_coprime": deep_coprime,
        "shadow_compressed": shadow_compressed,
        "shadow_compressed_deep_coprime": shadow_coprime,
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


def bernoulli_nb_cv(
    vectors: list[list[int]], labels: list[int], folds: int, rng: random.Random
) -> float:
    if len(vectors) != len(labels) or not vectors:
        raise ValueError("empty/mismatched dataset")
    fold_indices = stratified_folds(labels, folds, rng)
    correct = total = 0
    width = len(vectors[0])
    for test in fold_indices:
        test_set = set(test)
        train = [i for i in range(len(labels)) if i not in test_set]
        class_idx = {
            0: [i for i in train if labels[i] == 0],
            1: [i for i in train if labels[i] == 1],
        }
        if not class_idx[0] or not class_idx[1]:
            raise RuntimeError("empty class in training fold")
        probs: dict[int, list[float]] = {}
        priors: dict[int, float] = {}
        for y in (0, 1):
            ids = class_idx[y]
            priors[y] = len(ids) / len(train)
            probs[y] = [
                (1 + sum(vectors[i][f] for i in ids)) / (2 + len(ids))
                for f in range(width)
            ]
        for i in test:
            scores = {}
            for y in (0, 1):
                score = math.log(priors[y])
                for f, x in enumerate(vectors[i]):
                    p = probs[y][f]
                    score += math.log(p if x else (1 - p))
                scores[y] = score
            pred = 1 if scores[1] > scores[0] else 0
            correct += int(pred == labels[i])
            total += 1
    return correct / total


def classification_suite(v0: list[list[int]], v1: list[list[int]], folds: int, seed: int) -> dict:
    vectors = v0 + v1
    labels = [0] * len(v0) + [1] * len(v1)
    observed = bernoulli_nb_cv(vectors, labels, folds, random.Random(seed))
    shuffled = labels[:]
    prng = random.Random(seed ^ 0x5A17C0DE)
    prng.shuffle(shuffled)
    baseline = bernoulli_nb_cv(
        vectors, shuffled, folds, random.Random(seed ^ 0x13579BDF)
    )
    return {
        "observed_accuracy": observed,
        "shuffled_label_accuracy": baseline,
        "advantage_over_half": observed - 0.5,
    }


def summarize_trials(values: list[float]) -> dict:
    mean = statistics.fmean(values)
    sd = statistics.stdev(values) if len(values) > 1 else 0.0
    se = sd / math.sqrt(len(values)) if values else 0.0
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
    k_max: int,
    feature_map: dict[str, list[int]],
    traps: list[set[int]],
    seed: int,
    folds: int,
) -> dict:
    rng = random.Random(seed)
    structured = progression_primes_unique(
        rng, bits, STRUCTURED_MODULUS, 1, samples
    )
    hard1 = progression_primes_unique(
        rng, bits, 840, 1, samples, exclude=set(structured)
    )
    product_traps = {
        k: product_trap_set(k, traps)
        for ks in feature_map.values()
        for k in ks
    }

    result = {"seed": seed, "prime": {}, "public_modulus": {}}
    for name, ks in feature_map.items():
        hv0 = [hit_vector(p, traps, ks) for p in hard1]
        hv1 = [hit_vector(p, traps, ks) for p in structured]
        result["prime"][name] = classification_suite(
            hv0, hv1, folds, seed + len(ks) * 17 + 1
        )

        n0 = [hard1[i] * hard1[i + 1] for i in range(0, samples - 1, 2)]
        n1 = [structured[i] * structured[i + 1] for i in range(0, samples - 1, 2)]
        pv0 = [product_vector(N, product_traps, ks) for N in n0]
        pv1 = [product_vector(N, product_traps, ks) for N in n1]
        result["public_modulus"][name] = classification_suite(
            pv0, pv1, folds, seed + len(ks) * 31 + 7
        )

    d0 = [cab_depth(p, traps, k_max) for p in hard1]
    d1 = [cab_depth(p, traps, k_max) for p in structured]
    result["depth"] = {
        "hard1_mean_resolved": statistics.fmean(d for d in d0 if d is not None),
        "structured_mean_resolved": statistics.fmean(d for d in d1 if d is not None),
        "hard1_max_resolved": max(d for d in d0 if d is not None),
        "structured_max_resolved": max(d for d in d1 if d is not None),
    }
    return result


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bits", type=int, default=39)
    ap.add_argument("--samples", type=int, default=160)
    ap.add_argument("--k-max", type=int, default=500)
    ap.add_argument("--k-fingerprint", type=int, default=80)
    ap.add_argument("--trials", type=int, default=12)
    ap.add_argument("--folds", type=int, default=5)
    ap.add_argument("--seed", type=int, default=20260814)
    ap.add_argument("--out", type=Path, default=Path("cryptology-output"))
    args = ap.parse_args()
    if not (8 <= args.bits <= 63):
        raise SystemExit("--bits must be 8..63")
    if args.samples < max(20, args.folds * 4) or args.samples % 2:
        raise SystemExit("--samples must be even and sufficiently large")
    if args.k_fingerprint > args.k_max:
        raise SystemExit("--k-fingerprint must be <= --k-max")
    if args.trials < 2:
        raise SystemExit("--trials must be >= 2")

    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    traps = [set()] + [trap_set(k) for k in range(1, args.k_max + 1)]
    fmap = feature_sets(args.k_fingerprint, traps)

    trials = [
        run_trial(
            args.bits,
            args.samples,
            args.k_max,
            fmap,
            traps,
            args.seed + i * 1009,
            args.folds,
        )
        for i in range(args.trials)
    ]

    aggregate = {"prime": {}, "public_modulus": {}}
    for domain in ("prime", "public_modulus"):
        for name in fmap:
            obs = [t[domain][name]["observed_accuracy"] for t in trials]
            shuf = [t[domain][name]["shuffled_label_accuracy"] for t in trials]
            aggregate[domain][name] = {
                "observed": summarize_trials(obs),
                "shuffled_labels": summarize_trials(shuf),
            }

    result = {
        "status": "repeated held-out cryptology diagnostic; no cryptographic break claimed",
        "parameters": {
            "bits": args.bits,
            "samples_per_prime_population_per_trial": args.samples,
            "toy_moduli_per_population_per_trial": args.samples // 2,
            "k_max": args.k_max,
            "k_fingerprint": args.k_fingerprint,
            "trials": args.trials,
            "folds": args.folds,
            "base_seed": args.seed,
            "sampling": "unique primes per population per trial; cross-label duplicate primes excluded",
        },
        "controls": {
            "shared_constraint": "p == 1 mod 840",
            "structured_extra_constraints": [
                "p == 1 mod 11",
                "p == 1 mod 19",
                "p == 1 mod 23",
            ],
            "extra_modulus": EXTRA_MODULUS,
            "structured_modulus": STRUCTURED_MODULUS,
            "mask_definition": "coprime masks retain only k with gcd(4k-1, 11*19*23)=1; deep masks also drop k<=6",
            "shadow_definition": "shadow-compressed masks remove h=1 layers fully directly shadowed by earlier Type A/B layers",
        },
        "feature_counts": {name: len(ks) for name, ks in fmap.items()},
        "feature_ks": fmap,
        "aggregate": aggregate,
        "trials": trials,
    }
    (out / "cryptology-v2.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    def line(domain: str, name: str) -> str:
        a = aggregate[domain][name]["observed"]
        b = aggregate[domain][name]["shuffled_labels"]
        return (
            f"- {name}: observed mean `{a['mean']:.4f}` "
            f"(95% mean interval `{a['approx_95pct_mean_interval'][0]:.4f}`.."
            f"`{a['approx_95pct_mean_interval'][1]:.4f}`); "
            f"shuffled-label mean `{b['mean']:.4f}`"
        )

    report = "# WS-CAND-003 cryptology probe v2\n\n"
    report += (
        "Status: repeated held-out diagnostic only. No cryptographic break or "
        "key-recovery result is claimed.\n\n"
    )
    report += (
        f"Trials: `{args.trials}`; samples/population/trial: `{args.samples}`; "
        f"toy moduli/population/trial: `{args.samples // 2}`; folds: `{args.folds}`.\n\n"
    )
    report += (
        "The two prime populations both satisfy `p == 1 mod 840`. The structured "
        "source additionally plants `p == 1 mod 11,19,23`. Full fingerprints therefore "
        "include deliberately easy signal. The coprime masks are the critical negative "
        "control: they discard every feature modulus sharing a factor with `11*19*23`; "
        "the deep masks also discard k<=6.\n\n"
    )
    report += "## Prime-source held-out classification\n\n"
    for name in fmap:
        report += line("prime", name) + "\n"
    report += "\n## Public toy-RSA-modulus held-out classification\n\n"
    for name in fmap:
        report += line("public_modulus", name) + "\n"
    report += (
        "\nInterpretation rule: robust performance above the shuffled-label baseline in "
        "the masked public-modulus experiment would justify deeper cryptologic investigation, "
        "but would still not constitute factor recovery or an RSA break. Performance collapsing "
        "to chance after masking would be an important negative result showing that the initial "
        "signal was explained by explicitly planted congruences.\n"
    )
    (out / "cryptology-v2-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
