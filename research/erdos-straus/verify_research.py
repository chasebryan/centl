#!/usr/bin/env python3
"""Independent verifier for outputs of esc_research.py.

The verifier intentionally uses explicit residue fibres for direct-shadow
certificates rather than the optimized Counter-based discovery implementation.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


def divisors(n: int) -> list[int]:
    out = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            out.append(d)
            if d * d != n:
                out.append(n // d)
    return sorted(out)


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for d in divisors(k) for r in ((-d) % m, (-4 * d) % m)}


def tau(n: int) -> int:
    return len(divisors(n))


def trap_formula(k: int) -> int:
    v = 2 * tau(k) - 1
    if k % 4 == 0:
        v -= tau(k // 4)
    return v


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    L = math.lcm(m, n)
    # Deliberately simple search over the smaller reduced modulus.
    nn = n // g
    for u in range(nn):
        x = a + m * u
        if x % n == b % n:
            return x % L, L
    return None


def is_prime_trial(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    d = 3
    while d * d <= n:
        if n % d == 0:
            return False
        d += 2
    return True


def verify_frontier(out: Path) -> int:
    frontier = json.loads((out / "frontier.json").read_text())
    checks = 0
    for row in frontier:
        p = row["p"]
        C = row["C_AB"]
        assert is_prime_trial(p), f"frontier p is not prime: {p}"
        for k in range(1, C):
            assert p % (4 * k - 1) not in trap_set(k), f"smaller Type A/B hit: p={p} k={k}"
            checks += 1
        assert p % (4 * C - 1) in trap_set(C), f"missing hit at claimed depth: p={p} C={C}"
        assert C == row["d"] * row["n"]
        assert row["m"] == 4 * C - 1
        if row["type"] == "A":
            assert p + 4 * row["d"] == row["q"] * row["m"]
        elif row["type"] == "B":
            assert p + row["n"] == row["q"] * row["m"]
        else:
            raise AssertionError(f"unknown type {row['type']}")
    return checks


def verify_cardinality(out: Path) -> int:
    rows = json.loads((out / "trap-cardinality-checks.json").read_text())
    for row in rows:
        k = row["k"]
        explicit = len(trap_set(k))
        formula = trap_formula(k)
        assert explicit == row["observed"] == row["formula"] == formula, f"cardinality mismatch k={k}"
    return len(rows)


def verify_direct_shadow(out: Path) -> int:
    count = 0
    path = out / "direct-shadow-certificates.jsonl"
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        c = json.loads(line)
        k, h, t, j = c["k"], c["h"], c["t"], c["source_j"]
        mk, mj = 4 * k - 1, 4 * j - 1
        assert mk == c["m_k"] and mj == c["m_j"]
        assert h in HARD
        assert t in trap_set(k)
        assert math.gcd(t, mk) == 1
        assert t % math.gcd(840, mk) == h % math.gcd(840, mk)
        cr = crt2(h, 840, t, mk)
        assert cr is not None
        r, L = cr
        assert r == c["crt_r"] and L == c["crt_modulus"]
        g = math.gcd(L, mj)
        assert g == c["fibre_gcd"]
        fibre = set(range(r % g, mj, g))
        assert len(fibre) == c["fibre_size"]
        assert fibre <= trap_set(j), f"invalid shadow certificate k={k}, pair=({h},{t}), j={j}"
        count += 1
    return count


def verify_witnessed_global_novelty(out: Path) -> tuple[int, int]:
    rows = json.loads((out / "witnessed-global-novelty.json").read_text())
    classes = 0
    primes = 0
    for row in rows:
        k, h, t = row["k"], row["h"], row["t"]
        mk = 4 * k - 1
        assert row["m_k"] == mk
        assert h in HARD
        assert t in trap_set(k)
        for p in row["witness_primes"]:
            assert is_prime_trial(p)
            assert p % 840 == h
            assert p % mk == t
            for j in range(1, k):
                assert p % (4 * j - 1) not in trap_set(j), f"global-novelty witness was captured earlier: p={p}, j={j}"
            primes += 1
        classes += 1
    return classes, primes


def verify_ancestry(out: Path) -> int:
    edges = json.loads((out / "ancestry-edges.json").read_text())
    for e in edges:
        j, k = e["j"], e["k"]
        mj, mk = 4 * j - 1, 4 * k - 1
        assert e["m_j"] == mj and e["m_k"] == mk
        divides = mk % mj == 0
        assert divides == e["modulus_divides"]
        if divides:
            q = mk // mj
            assert e["quotient"] == q
            assert q % 4 == 1
            s = (q - 1) // 4
            assert e["s"] == s
            assert k == q * j - s
            assert e["k_equals_qj_minus_s"] is True
    return len(edges)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("research-output"))
    args = ap.parse_args()
    out = args.out

    frontier_checks = verify_frontier(out)
    cardinality = verify_cardinality(out)
    shadow = verify_direct_shadow(out)
    global_classes, global_primes = verify_witnessed_global_novelty(out)
    ancestry = verify_ancestry(out)

    summary = {
        "frontier_rejected_lower_levels_checked": frontier_checks,
        "trap_cardinality_layers_checked": cardinality,
        "direct_shadow_certificates_checked": shadow,
        "witnessed_global_nonunion_shadow_classes_checked": global_classes,
        "first_hit_prime_witnesses_checked": global_primes,
        "ancestry_edges_checked": ancestry,
        "verdict": "VERIFIED",
    }
    (out / "independent-verification.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
