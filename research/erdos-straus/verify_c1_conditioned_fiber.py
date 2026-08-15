#!/usr/bin/env python3
"""Independent verifier for c1_conditioned_fiber.py.

Residual kernels are reconstructed with verify_class_c_census.py, whose peel
recomputes loads from scratch after every coordinate removal.  The conditioned
fibers are then checked from exact forbidden residue tuples.
"""
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

import verify_class_c_census as iv

PRIMES = (3, 11, 13)
F840 = {3: 1, 5: 1, 7: 1}


def bad_parameter(r: int, L: int, p: int) -> int | None:
    return None if L % p == 0 else (-r * pow(L, -1, p)) % p


def domains(r: int, L: int, residual: list[dict]) -> tuple[dict[int, int], dict[int, list[int]]]:
    exponents = {p: 0 for p in PRIMES}
    for edge in residual:
        for p, a in edge["factors"].items():
            if p in exponents:
                exponents[p] = max(exponents[p], a)

    out: dict[int, list[int]] = {}
    for p in PRIMES:
        modulus = p ** exponents[p] if exponents[p] else 1
        vals = list(range(modulus))
        bad = bad_parameter(r, L, p)
        if bad is not None:
            vals = [x for x in vals if x % p != bad]
        for edge in residual:
            if set(edge["factors"]) == {p}:
                vals = [x for x in vals if x % edge["q"] not in edge["R"]]
        out[p] = vals
    return exponents, out


def edge_hits(edge: dict, coords: dict[int, int]) -> bool:
    return any(
        all(coords[p] % (p**a) == v % (p**a) for p, a in edge["factors"].items())
        for v in edge["R"]
    )


def verify_1113(r: int, L: int, residual: list[dict]) -> dict:
    exp, dom = domains(r, L, residual)
    D11, D13 = dom[11], dom[13]
    pair = [e for e in residual if set(e["factors"]) == {11, 13}]
    coarse = [e for e in pair if e["factors"][13] == 1]
    fine = [e for e in pair if e["factors"][13] > 1]
    base13 = sorted({b % 13 for b in D13})

    min_base = 99
    min_full = 10**9
    fine_new = 0
    for a in D11:
        safe_base = [
            b for b in base13
            if not any(edge_hits(e, {11: a, 13: b}) for e in coarse)
        ]
        min_base = min(min_base, len(safe_base))

        safe_coarse = [
            b for b in D13
            if not any(edge_hits(e, {11: a, 13: b}) for e in coarse)
        ]
        safe_all = [
            b for b in safe_coarse
            if not any(edge_hits(e, {11: a, 13: b}) for e in fine)
        ]
        fine_new += len(safe_coarse) - len(safe_all)
        min_full = min(min_full, len(safe_all))

    return {
        "minimum_safe_base13_classes_per_full11": min_base,
        "minimum_safe_full13_values_per_full11": min_full,
        "fine13_new_hits_after_coarse_pair_stage": fine_new,
        "unary_full11": len(D11),
        "unary_base11": len({a % 11 for a in D11}),
        "unary_base13": len(base13),
    }


def verify_31113(r: int, L: int, residual: list[dict]) -> dict:
    pair_summary = verify_1113(r, L, residual)
    exp, dom = domains(r, L, residual)
    D3, D11, D13 = dom[3], dom[11], dom[13]
    pair_edges = [e for e in residual if set(e["factors"]) == {11, 13}]
    three_edges = [
        e for e in residual
        if 3 in e["factors"] and len(e["factors"]) > 1
    ]

    base11 = sorted({a % 11 for a in D11})
    base13 = sorted({b % 13 for b in D13})
    max_f3 = 0
    max_f9 = 0
    fine81_new = 0

    for a in base11:
        for b in base13:
            f3: set[int] = set()
            f9: set[int] = set()
            f81: set[int] = set()
            for edge in three_edges:
                e3 = edge["factors"][3]
                chosen = []
                for v in edge["R"]:
                    if 11 in edge["factors"] and v % 11 != a:
                        continue
                    if 13 in edge["factors"] and v % 13 != b:
                        continue
                    chosen.append(v % (3**e3))
                if e3 == 1:
                    f3.update(chosen)
                elif e3 == 2:
                    f9.update(chosen)
                elif e3 == 4:
                    f81.update(chosen)
                else:
                    raise AssertionError(f"unexpected 3 exponent {e3}")
            max_f3 = max(max_f3, len(f3))
            coarse9 = {x for c in f3 for x in range(9) if x % 3 == c} | f9
            max_f9 = max(max_f9, len(coarse9))
            fine81_new += sum(1 for x in f81 if x % 9 not in coarse9)

    # Exact pair masks over full D13.
    all_b_mask = (1 << len(D13)) - 1
    masks = [0] * len(D11)
    for edge in pair_edges:
        e11 = edge["factors"][11]
        e13 = edge["factors"][13]
        for ia, a in enumerate(D11):
            for ib, b in enumerate(D13):
                if masks[ia] & (1 << ib):
                    continue
                if edge_hits(edge, {11: a, 13: b}):
                    masks[ia] |= 1 << ib

    # Precompile each 3-edge by its non-3 coordinate residues.
    d3_masks: dict[tuple[int, int], int] = {}
    for a in range(1, exp[3] + 1):
        mod = 3**a
        for residue in range(mod):
            mask = 0
            for c in D3:
                if c % mod == residue:
                    mask |= 1 << c
            d3_masks[(a, residue)] = mask

    compiled = []
    for edge in three_edges:
        e3 = edge["factors"][3]
        others = tuple(p for p in (11, 13) if p in edge["factors"])
        table: dict[tuple[int, ...], int] = collections.defaultdict(int)
        for v in edge["R"]:
            key = tuple(v % (p ** edge["factors"][p]) for p in others)
            table[key] |= d3_masks[(e3, v % (3**e3))]
        compiled.append((edge, others, table))

    base3mask = sum(1 << c for c in D3)
    min_pair = 10**9
    min_three = 10**9
    counts: set[int] = set()

    for ia, a in enumerate(D11):
        safe_b = all_b_mask & ~masks[ia]
        min_pair = min(min_pair, safe_b.bit_count())
        while safe_b:
            bit = safe_b & -safe_b
            ib = bit.bit_length() - 1
            safe_b -= bit
            b = D13[ib]
            forbidden = 0
            for edge, others, table in compiled:
                key = tuple(
                    (a if p == 11 else b) % (p ** edge["factors"][p])
                    for p in others
                )
                forbidden |= table.get(key, 0)
            n = (base3mask & ~forbidden).bit_count()
            counts.add(n)
            min_three = min(min_three, n)

    return {
        **pair_summary,
        "minimum_safe_full13_values_per_full11_all_pair_rows": min_pair,
        "maximum_collective_forbidden_mod3_classes": max_f3,
        "maximum_collective_forbidden_mod9_classes": max_f9,
        "fine81_new_hits_after_mod9_stage": fine81_new,
        "minimum_safe_full3_values_per_safe_1113_pair": min_three,
        "observed_safe_full3_counts": sorted(counts),
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    claimed = json.loads((args.out / "c1-conditioned-fiber.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    K = int(source["parameters"]["k_limit"])

    wanted1113 = {int(x["candidate_index"]): x for x in claimed["certificates_1113"]}
    wanted31113 = {int(x["candidate_index"]): x for x in claimed["certificates_31113"]}
    wanted = set(wanted1113) | set(wanted31113)

    fac = [dict()] + [iv.factor(4 * k - 1) for k in range(1, K + 1)]
    T = [set()] + [iv.traps(k) for k in range(1, K + 1)]
    profiles: dict[int, tuple[list[int], list[int]]] = {}
    for index in wanted:
        rec = witnesses[index - 1]
        k = int(rec["k"])
        if k in profiles:
            continue
        fixed_primes = set(F840) | set(fac[k])
        vL = {p: max(F840.get(p, 0), fac[k].get(p, 0)) for p in fixed_primes}
        fixed: list[int] = []
        active: list[int] = []
        for j in range(1, k):
            if all(a % 2 == 0 or p in fixed_primes for p, a in fac[j].items()):
                fixed.append(j)
                if any(a > vL.get(p, 0) for p, a in fac[j].items()):
                    active.append(j)
        profiles[k] = (fixed, active)

    checked1113 = 0
    checked31113 = 0
    global1113 = {
        "min_base13": 99,
        "min_full13": 10**9,
        "fine13_new": 0,
    }
    global31113 = {
        "min_unary_full11": 10**9,
        "min_unary_base11": 99,
        "min_unary_base13": 99,
        "min_base13": 99,
        "min_full13": 10**9,
        "fine13_new": 0,
        "max_f3": 0,
        "max_f9": 0,
        "fine81_new": 0,
        "min_three": 10**9,
        "safe3_counts": set(),
    }

    for index in sorted(wanted):
        rec = witnesses[index - 1]
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        fixed, active = profiles[k]
        N = {j for j in fixed if iv.jacobi(r, 4 * j - 1) == -1}
        A = [j for j in active if j in N]
        if len(A) != 1:
            raise AssertionError(f"candidate {index} is not independently single-active")

        edges: list[dict] = []
        for j in range(1, k):
            q, R = iv.pullback(r, L, j, T)
            if not R:
                continue
            if q == 1:
                raise AssertionError("q=1 direct-shadow contradiction")
            edges.append({"j": j, "q": q, "R": R, "factors": iv.factor(q)})
        primes, residual = iv.brute_recompute_peel(r, L, edges)

        if index in wanted1113:
            if primes != (11, 13):
                raise AssertionError(f"candidate {index}: expected (11,13), got {primes}")
            s = verify_1113(r, L, residual)
            global1113["min_base13"] = min(global1113["min_base13"], s["minimum_safe_base13_classes_per_full11"])
            global1113["min_full13"] = min(global1113["min_full13"], s["minimum_safe_full13_values_per_full11"])
            global1113["fine13_new"] += s["fine13_new_hits_after_coarse_pair_stage"]
            checked1113 += 1
        else:
            if primes != (3, 11, 13):
                raise AssertionError(f"candidate {index}: expected (3,11,13), got {primes}")
            s = verify_31113(r, L, residual)
            global31113["min_unary_full11"] = min(global31113["min_unary_full11"], s["unary_full11"])
            global31113["min_unary_base11"] = min(global31113["min_unary_base11"], s["unary_base11"])
            global31113["min_unary_base13"] = min(global31113["min_unary_base13"], s["unary_base13"])
            global31113["min_base13"] = min(global31113["min_base13"], s["minimum_safe_base13_classes_per_full11"])
            global31113["min_full13"] = min(global31113["min_full13"], s["minimum_safe_full13_values_per_full11_all_pair_rows"])
            global31113["fine13_new"] += s["fine13_new_hits_after_coarse_pair_stage"]
            global31113["max_f3"] = max(global31113["max_f3"], s["maximum_collective_forbidden_mod3_classes"])
            global31113["max_f9"] = max(global31113["max_f9"], s["maximum_collective_forbidden_mod9_classes"])
            global31113["fine81_new"] += s["fine81_new_hits_after_mod9_stage"]
            global31113["min_three"] = min(global31113["min_three"], s["minimum_safe_full3_values_per_safe_1113_pair"])
            global31113["safe3_counts"].update(s["observed_safe_full3_counts"])
            checked31113 += 1

    expected1113 = claimed["signature_1113"]
    expected31113 = claimed["signature_31113"]
    comparisons = {
        "signature_1113_count": (checked1113, int(claimed["signature_1113_count"])),
        "signature_31113_count": (checked31113, int(claimed["signature_31113_count"])),
        "1113_min_base13": (global1113["min_base13"], expected1113["minimum_safe_base13_classes_per_full11"]),
        "1113_min_full13": (global1113["min_full13"], expected1113["minimum_safe_full13_values_per_full11"]),
        "1113_fine13_new": (global1113["fine13_new"], expected1113["fine13_new_hits_after_coarse_pair_stage"]),
        "31113_min_unary_full11": (global31113["min_unary_full11"], expected31113["minimum_unary_full11_domain"]),
        "31113_min_unary_base11": (global31113["min_unary_base11"], expected31113["minimum_unary_base11_classes"]),
        "31113_min_unary_base13": (global31113["min_unary_base13"], expected31113["minimum_unary_base13_classes"]),
        "31113_min_base13": (global31113["min_base13"], expected31113["minimum_safe_base13_classes_per_full11"]),
        "31113_min_full13": (global31113["min_full13"], expected31113["minimum_safe_full13_values_per_full11"]),
        "31113_fine13_new": (global31113["fine13_new"], expected31113["fine13_new_hits_after_coarse_pair_stage"]),
        "31113_max_f3": (global31113["max_f3"], expected31113["maximum_collective_forbidden_mod3_classes"]),
        "31113_max_f9": (global31113["max_f9"], expected31113["maximum_collective_forbidden_mod9_classes"]),
        "31113_fine81_new": (global31113["fine81_new"], expected31113["fine81_new_hits_after_mod9_stage"]),
        "31113_min_three": (global31113["min_three"], expected31113["minimum_safe_full3_values_per_safe_1113_pair"]),
        "31113_safe3_counts": (sorted(global31113["safe3_counts"]), expected31113["observed_safe_full3_counts"]),
    }
    mismatches = [name for name, (actual, expected) in comparisons.items() if actual != expected]

    result = {
        "verdict": "VERIFIED" if not mismatches else "MISMATCH",
        "k_limit": K,
        "conditioned_candidates_checked": len(wanted),
        "signature_1113_checked": checked1113,
        "signature_31113_checked": checked31113,
        "independent_residual_control_flow": "recompute all local loads after each fiber peel",
        "mismatched_fields": mismatches,
        "comparisons": {name: {"actual": a, "expected": e} for name, (a, e) in comparisons.items()},
    }
    (args.out / "c1-conditioned-fiber-independent-verifier.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(result, indent=2, sort_keys=True))
    if mismatches:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
