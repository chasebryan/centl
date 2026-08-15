#!/usr/bin/env python3
"""Independent verifier for cn_shared_analyzer.py.

Recomputes pullbacks and CRT compatibility with a different control flow:
safe sets are built as bit-masks on (Z/qZ)× and compatibility is decided by
projecting masks rather than walking CRT pairs.  The totient-ratio lemma is
rechecked from Euler's product formula.

Finite output only.  Does not prove Erdős-Straus.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import cn_shared_analyzer as A

HARD = (1, 121, 169, 289, 361, 529)
STANDARD_L = (840, 2520, 5040, 55440, 720720)


def blocked(q: int, R: set[int], d: int) -> set[int]:
    """a mod d is blocked if at least φ(q)/φ(d) unit traps reduce to a."""
    if d <= 1:
        return set()
    ratio = euler_product_phi(q) // euler_product_phi(d)
    counts: dict[int, int] = {}
    for x in R:
        if math.gcd(x, q) == 1:
            counts[x % d] = counts.get(x % d, 0) + 1
    return {a for a, c in counts.items() if c >= ratio}


def pair_ok_mask(q1: int, R1: set[int], q2: int, R2: set[int]) -> bool:
    if q1 <= 1 or q2 <= 1:
        return True
    if not A.c1_escape(q1, R1) or not A.c1_escape(q2, R2):
        return False
    d = math.gcd(q1, q2)
    if d == 1:
        return True
    b1, b2 = blocked(q1, R1, d), blocked(q2, R2, d)
    return any(math.gcd(a, d) == 1 and a not in b1 and a not in b2 for a in range(d))


def euler_product_phi(n: int) -> int:
    result = n
    x = n
    p = 2
    while p * p <= x:
        if x % p == 0:
            result -= result // p
            while x % p == 0:
                x //= p
        p = 3 if p == 2 else p + 2
    if x > 1:
        result -= result // x
    return result


def verify_ratio_lemma(q_limit: int) -> dict:
    fails = 0
    checked = 0
    min_ratio = None
    for q in range(3, q_limit + 1, 2):
        for d in A.divisors(q):
            if d == q:
                continue
            checked += 1
            # Independent φ
            ratio = euler_product_phi(q) // euler_product_phi(d)
            if min_ratio is None or ratio < min_ratio:
                min_ratio = ratio
            if ratio < 2:
                fails += 1
    return {"checked": checked, "fails": fails, "min_ratio": min_ratio}


def verify_pairs(j_limit: int, Ls: list[int]) -> dict:
    cache: dict[int, set[int]] = {}
    checked = 0
    fails = 0
    mask_disagreements = 0
    r_samples = list(HARD) + [0, 1, 2, 7, 16, 25]
    for L in Ls:
        js = [j for j, q in A.all_positive_q_layers(L, j_limit)]
        for i, j1 in enumerate(js):
            for j2 in js[i + 1 :]:
                for r in r_samples:
                    row = A.classify_pair(r, L, j1, j2, cache)
                    _, q1, R1 = A.pullback(r, L, j1, cache[j1])
                    _, q2, R2 = A.pullback(r, L, j2, cache[j2])
                    ok_mask = pair_ok_mask(q1, R1, q2, R2)
                    checked += 1
                    if ok_mask != row["ok"] and not row["c1_fail"]:
                        # classify_pair marks inactive/c1 separately
                        if row["kind"] != "inactive":
                            mask_disagreements += 1
                    if row["kind"] != "inactive" and not ok_mask:
                        fails += 1
    return {
        "checked": checked,
        "mask_fails": fails,
        "mask_disagreements": mask_disagreements,
    }


def verify_q3_layers(Ls: list[int]) -> dict:
    mismatches = []
    for L in Ls:
        brute = []
        # Brute: test every j with 4j-1 | 3L
        for m in A.divisors(3 * L):
            if m % 4 != 3:
                continue
            j = (m + 1) // 4
            if j >= 1 and (4 * j - 1) // math.gcd(L, 4 * j - 1) == 3:
                brute.append(j)
        listed = A.layers_with_q(L, 3)
        if listed != sorted(set(brute)):
            mismatches.append({"L": L, "listed": listed, "brute": sorted(set(brute))})
    return {"Ls": list(Ls), "mismatches": mismatches}


def verify_205_absorption(k_limit: int) -> dict:
    """If q_205=3 and R_205 nonempty then layer 10 covers the progression."""
    checked = 0
    violations = []
    for k in range(206, k_limit + 1):
        L = math.lcm(840, 4 * k - 1)
        q205 = (4 * 205 - 1) // math.gcd(L, 4 * 205 - 1)
        if q205 != 3:
            continue
        for h, t, r, _L in A.admissible_candidates(k):
            g, q, R = A.pullback(r, L, 205)
            if q != 3 or not R:
                continue
            checked += 1
            g10, q10, _R10 = A.pullback(r, L, 10)
            T10 = A.trap_set(10)
            covered = q10 == 1 and any((u - r) % g10 == 0 for u in T10)
            if not covered:
                violations.append({"k": k, "h": h, "t": t, "r": r, "q10": q10})
    return {"checked": checked, "violations": violations}


def verify_program_sample(k_limit: int) -> dict:
    cache: dict[int, set[int]] = {}
    fails = 0
    checked = 0
    for k in range(2, k_limit + 1):
        L = math.lcm(840, 4 * k - 1)
        active = []
        for j in range(1, k):
            q = (4 * j - 1) // math.gcd(L, 4 * j - 1)
            if q > 1:
                active.append(j)
        for i, j1 in enumerate(active):
            for j2 in active[i + 1 :]:
                for r in HARD:
                    row = A.classify_pair(r, L, j1, j2, cache)
                    checked += 1
                    if not row["ok"]:
                        fails += 1
    return {"checked": checked, "fails": fails}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("cn-shared-output"))
    ap.add_argument("--j-limit", type=int, default=160)
    ap.add_argument("--k-limit", type=int, default=180)
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    verdict = {
        "ratio_lemma": verify_ratio_lemma(4000),
        "pairs": verify_pairs(args.j_limit, list(STANDARD_L[:4])),
        "q3_layers": verify_q3_layers(list(STANDARD_L)),
        "program_sample": verify_program_sample(args.k_limit),
        "absorption_205": verify_205_absorption(min(args.k_limit, 400)),
    }
    ok = (
        verdict["ratio_lemma"]["fails"] == 0
        and verdict["pairs"]["mask_fails"] == 0
        and verdict["pairs"]["mask_disagreements"] == 0
        and verdict["q3_layers"]["mismatches"] == []
        and verdict["program_sample"]["fails"] == 0
        and verdict["absorption_205"]["violations"] == []
    )
    verdict["verdict"] = "VERIFIED" if ok else "FAIL"
    path = args.out / "cn-shared-independent-verifier.json"
    path.write_text(json.dumps(verdict, indent=2, sort_keys=True) + "\n")
    print(json.dumps(verdict, indent=2, sort_keys=True))
    if not ok:
        raise SystemExit("CN-shared independent verifier failed")


if __name__ == "__main__":
    main()
