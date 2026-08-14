#!/usr/bin/env python3
"""Exploratory cryptology diagnostics for WS-CAND-003.

This is a distribution/fingerprint experiment, not a cryptanalytic attack.
It generates small deterministic prime populations, computes Type A/B depth
and hit fingerprints, and compares public product-trap fingerprints of toy
RSA moduli. The true factors are retained only for scoring.
"""

from __future__ import annotations

import argparse
import json
import math
import random
from collections import Counter
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


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
    # Deterministic for n < 2^64.
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


def random_prime(rng: random.Random, bits: int, predicate=lambda p: True) -> int:
    low = 1 << (bits - 1)
    high = 1 << bits
    while True:
        n = rng.randrange(low, high) | 1
        if predicate(n) and is_prime(n):
            return n


def progression_prime(rng: random.Random, bits: int, modulus: int, residue: int) -> int:
    low = 1 << (bits - 1)
    high = 1 << bits
    first = low + ((residue - low) % modulus)
    count = max(1, (high - first + modulus - 1) // modulus)
    while True:
        n = first + modulus * rng.randrange(count)
        if n < high and is_prime(n):
            return n


def safe_prime(rng: random.Random, bits: int) -> int:
    while True:
        r = random_prime(rng, bits - 1)
        p = 2 * r + 1
        if p.bit_length() == bits and is_prime(p):
            return p


def cab_depth(p: int, traps: list[set[int]], k_max: int) -> int | None:
    for k in range(1, k_max + 1):
        if p % (4 * k - 1) in traps[k]:
            return k
    return None


def hit_vector(p: int, traps: list[set[int]], k_fingerprint: int) -> list[int]:
    return [int(p % (4 * k - 1) in traps[k]) for k in range(1, k_fingerprint + 1)]


def product_traps(traps: list[set[int]], k_fingerprint: int) -> list[set[int]]:
    out = [set() for _ in range(k_fingerprint + 1)]
    for k in range(1, k_fingerprint + 1):
        m = 4 * k - 1
        units = [a for a in traps[k] if math.gcd(a, m) == 1]
        out[k] = {(a * b) % m for a in units for b in units}
    return out


def public_product_vector(N: int, prod: list[set[int]], k_fingerprint: int) -> list[int]:
    return [int(N % (4 * k - 1) in prod[k]) for k in range(1, k_fingerprint + 1)]


def total_variation(a: Counter, b: Counter) -> float:
    keys = set(a) | set(b)
    sa, sb = sum(a.values()), sum(b.values())
    if not sa or not sb:
        return 0.0
    return 0.5 * sum(abs(a[k] / sa - b[k] / sb) for k in keys)


def summarize(name: str, primes: list[int], traps: list[set[int]], k_max: int, k_fp: int) -> dict:
    depths = [cab_depth(p, traps, k_max) for p in primes]
    hist = Counter(str(d) if d is not None else f">{k_max}" for d in depths)
    vectors = [hit_vector(p, traps, k_fp) for p in primes]
    rates = [sum(v[i] for v in vectors) / len(vectors) for i in range(k_fp)]
    resolved = [d for d in depths if d is not None]
    return {
        "name": name,
        "count": len(primes),
        "min_prime": min(primes),
        "max_prime": max(primes),
        "resolved": len(resolved),
        "unresolved": len(primes) - len(resolved),
        "mean_C_AB_resolved": (sum(resolved) / len(resolved)) if resolved else None,
        "max_C_AB_resolved": max(resolved) if resolved else None,
        "C_AB_histogram": dict(sorted(hist.items(), key=lambda kv: (kv[0].startswith(">"), int(kv[0][1:]) if kv[0].startswith(">") else int(kv[0])))),
        "hit_rates_k1_to_kfp": rates,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bits", type=int, default=31)
    ap.add_argument("--samples", type=int, default=160)
    ap.add_argument("--k-max", type=int, default=500)
    ap.add_argument("--k-fingerprint", type=int, default=80)
    ap.add_argument("--seed", type=int, default=20260814)
    ap.add_argument("--out", type=Path, default=Path("cryptology-output"))
    args = ap.parse_args()
    if not (8 <= args.bits <= 63):
        raise SystemExit("--bits must be between 8 and 63 for this deterministic probe")
    if args.k_fingerprint > args.k_max:
        raise SystemExit("--k-fingerprint must be <= --k-max")

    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    rng = random.Random(args.seed)
    traps = [set()] + [trap_set(k) for k in range(1, args.k_max + 1)]
    prod = product_traps(traps, args.k_fingerprint)

    # A deliberately planted deeper-congruence family. It shares p == 1 mod 840
    # with the hard1 control while additionally forcing p == 1 mod 11, 19, 23.
    structured_modulus = math.lcm(840, 11, 19, 23)

    populations: dict[str, list[int]] = {}
    populations["random"] = [random_prime(rng, args.bits) for _ in range(args.samples)]
    populations["blum"] = [random_prime(rng, args.bits, lambda p: p % 4 == 3) for _ in range(args.samples)]
    populations["safe"] = [safe_prime(rng, args.bits) for _ in range(args.samples)]
    populations["hard840"] = [
        progression_prime(rng, args.bits, 840, HARD[rng.randrange(len(HARD))])
        for _ in range(args.samples)
    ]
    populations["hard1"] = [progression_prime(rng, args.bits, 840, 1) for _ in range(args.samples)]
    populations["structured_hard1"] = [
        progression_prime(rng, args.bits, structured_modulus, 1)
        for _ in range(args.samples)
    ]

    summaries = {name: summarize(name, ps, traps, args.k_max, args.k_fingerprint) for name, ps in populations.items()}

    depth_hists = {}
    for name, ps in populations.items():
        counter = Counter()
        for p in ps:
            d = cab_depth(p, traps, args.k_max)
            counter[str(d) if d is not None else f">{args.k_max}"] += 1
        depth_hists[name] = counter

    tv = {}
    names = sorted(populations)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            tv[f"{a}__vs__{b}"] = total_variation(depth_hists[a], depth_hists[b])

    # Pair adjacent primes inside each population into toy RSA moduli.
    public = {}
    rsa_examples = {}
    for name, ps in populations.items():
        moduli = [(ps[i] * ps[i + 1], ps[i], ps[i + 1]) for i in range(0, len(ps) - 1, 2)]
        vecs = [public_product_vector(N, prod, args.k_fingerprint) for N, _, _ in moduli]
        public[name] = {
            "moduli": len(moduli),
            "product_trap_hit_rates_k1_to_kfp": [sum(v[i] for v in vecs) / len(vecs) for i in range(args.k_fingerprint)] if vecs else [],
        }
        rsa_examples[name] = [
            {"N": N, "p": p, "q": q, "p_C_AB": cab_depth(p, traps, args.k_max), "q_C_AB": cab_depth(q, traps, args.k_max)}
            for N, p, q in moduli[:5]
        ]

    result = {
        "status": "exploratory cryptology diagnostic; no cryptographic break claimed",
        "seed": args.seed,
        "bits": args.bits,
        "samples_per_population": args.samples,
        "k_max": args.k_max,
        "k_fingerprint": args.k_fingerprint,
        "structured_hard1_modulus": structured_modulus,
        "structured_constraints": ["p == 1 mod 840", "p == 1 mod 11", "p == 1 mod 19", "p == 1 mod 23"],
        "populations": summaries,
        "C_AB_histogram_total_variation": tv,
        "public_modulus_product_trap": public,
    }
    (out / "cryptology-probe.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    (out / "toy-rsa-examples-private-for-scoring.json").write_text(json.dumps(rsa_examples, indent=2, sort_keys=True) + "\n")

    # A compact report prioritizing the controlled hard1 comparison.
    a = summaries["hard1"]
    b = summaries["structured_hard1"]
    controlled_tv = tv["hard1__vs__structured_hard1"]
    report = "# WS-CAND-003 cryptology probe\n\n"
    report += "Status: exploratory diagnostic only; no cryptographic break claimed.\n\n"
    report += f"- bits: `{args.bits}`\n- samples per population: `{args.samples}`\n- C_AB search depth: `{args.k_max}`\n- fingerprint depth: `{args.k_fingerprint}`\n- deterministic seed: `{args.seed}`\n\n"
    report += "## Controlled prime-source comparison\n\n"
    report += "Both populations below satisfy `p == 1 mod 840`. The structured population additionally satisfies `p == 1 mod 11, 19, 23`. This isolates deeper planted congruence structure from the shared mod-840 condition.\n\n"
    report += f"- hard1 mean resolved C_AB: `{a['mean_C_AB_resolved']}`; max: `{a['max_C_AB_resolved']}`\n"
    report += f"- structured_hard1 mean resolved C_AB: `{b['mean_C_AB_resolved']}`; max: `{b['max_C_AB_resolved']}`\n"
    report += f"- empirical C_AB-histogram total-variation distance: `{controlled_tv:.6f}`\n\n"
    report += "A nonzero finite-sample distance is not by itself a cryptographic distinguisher. The next step is repeated train/test experiments, confidence intervals, and conditioning on all planted constraints.\n\n"
    report += "## Public toy-RSA diagnostic\n\n"
    report += "For each toy modulus `N=pq`, the probe computes whether `N mod (4k-1)` lies in the product of the unit Type A/B trap residues at layer k. This uses only N, but membership is merely compatibility with both factors being trapped at k. It is not evidence of factor recovery.\n"
    (out / "cryptology-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
