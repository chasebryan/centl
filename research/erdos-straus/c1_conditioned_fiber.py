#!/usr/bin/env python3
"""Conditioned-fiber analyzer for the smallest recurring C1 kernels.

Replays a completed direct-shadow bundle, reconstructs single-active C1
residual kernels with class_c_census.py, and measures exact variable-
elimination geometry for signatures {11,13} and {3,11,13}.

The implementation uses integer bitsets only as a representation of exact
finite residue sets. No sampling or probabilistic test is used.
"""
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

import class_c_census as cc

PRIMES = (3, 11, 13)


def factor_dict(n: int) -> dict[int, int]:
    return dict(cc.factor_exp(n))


def reduced_bad_parameter(r: int, L: int, p: int) -> int | None:
    if L % p == 0:
        return None
    return (-r * pow(L, -1, p)) % p


def coordinate_domains(
    r: int,
    L: int,
    residual: list[dict],
) -> tuple[dict[int, int], dict[int, list[int]]]:
    maxexp = {p: 0 for p in PRIMES}
    for edge in residual:
        for p, a in cc.factor_exp(edge["q"]):
            if p in maxexp:
                maxexp[p] = max(maxexp[p], a)

    domains: dict[int, list[int]] = {}
    for p in PRIMES:
        modulus = p ** maxexp[p] if maxexp[p] else 1
        values = list(range(modulus))
        bad = reduced_bad_parameter(r, L, p)
        if bad is not None:
            values = [x for x in values if x % p != bad]

        for edge in residual:
            fac = factor_dict(edge["q"])
            if set(fac) == {p}:
                q = edge["q"]
                R = edge["R"]
                values = [x for x in values if x % q not in R]
        domains[p] = values
    return maxexp, domains


def pair_forbidden(edge: dict, a11: int, b13: int) -> bool:
    fac = factor_dict(edge["q"])
    e11 = fac.get(11, 0)
    e13 = fac.get(13, 0)
    r11 = a11 % (11**e11) if e11 else 0
    r13 = b13 % (13**e13) if e13 else 0
    return any(
        (not e11 or v % (11**e11) == r11)
        and (not e13 or v % (13**e13) == r13)
        for v in edge["R"]
    )


def analyse_1113(r: int, L: int, residual: list[dict]) -> dict:
    maxexp, domains = coordinate_domains(r, L, residual)
    D11 = domains[11]
    D13 = domains[13]
    mixed = [e for e in residual if set(factor_dict(e["q"])) == {11, 13}]
    coarse = [e for e in mixed if factor_dict(e["q"])[13] == 1]
    fine13 = [e for e in mixed if factor_dict(e["q"])[13] > 1]

    base13 = sorted({b % 13 for b in D13})
    min_base13 = 99
    min_full13 = 10**9
    fine_new_hits = 0

    for a in D11:
        coarse_safe_base = [
            b0 for b0 in base13
            if not any(pair_forbidden(e, a, b0) for e in coarse)
        ]
        min_base13 = min(min_base13, len(coarse_safe_base))

        full_safe_coarse = [
            b for b in D13
            if not any(pair_forbidden(e, a, b) for e in coarse)
        ]
        full_safe_all = [
            b for b in full_safe_coarse
            if not any(pair_forbidden(e, a, b) for e in fine13)
        ]
        fine_new_hits += len(full_safe_coarse) - len(full_safe_all)
        min_full13 = min(min_full13, len(full_safe_all))

    return {
        "max_exponents": {str(p): maxexp[p] for p in (11, 13)},
        "unary_full_domain_sizes": {"11": len(D11), "13": len(D13)},
        "unary_base_domain_sizes": {
            "11": len({a % 11 for a in D11}),
            "13": len(base13),
        },
        "minimum_safe_base13_classes_per_full11": min_base13,
        "minimum_safe_full13_values_per_full11": min_full13,
        "fine13_new_hits_after_coarse_pair_stage": fine_new_hits,
    }


def analyse_31113(r: int, L: int, residual: list[dict]) -> dict:
    pair = analyse_1113(r, L, residual)
    maxexp, domains = coordinate_domains(r, L, residual)
    D3, D11, D13 = domains[3], domains[11], domains[13]

    pair_edges = [e for e in residual if set(factor_dict(e["q"])) == {11, 13}]
    coarse_pair = [e for e in pair_edges if factor_dict(e["q"])[13] == 1]
    fine_pair = [e for e in pair_edges if factor_dict(e["q"])[13] > 1]
    three_edges = [
        e for e in residual
        if 3 in factor_dict(e["q"]) and len(factor_dict(e["q"])) > 1
    ]

    base11 = sorted({a % 11 for a in D11})
    base13 = sorted({b % 13 for b in D13})

    for edge in three_edges:
        fac = factor_dict(edge["q"])
        if fac.get(11, 0) > 1 or fac.get(13, 0) > 1:
            raise AssertionError(
                f"unexpected fine non-3 coordinate in 3-coupled row j={edge['j']} q={edge['q']}"
            )

    max_forbidden_mod3 = 0
    max_forbidden_mod9 = 0
    fine81_new_hits = 0

    for a0 in base11:
        for b0 in base13:
            f3: set[int] = set()
            f9: set[int] = set()
            f81: set[int] = set()
            for edge in three_edges:
                fac = factor_dict(edge["q"])
                e3 = fac[3]
                selected: list[int] = []
                for v in edge["R"]:
                    if 11 in fac and v % 11 != a0:
                        continue
                    if 13 in fac and v % 13 != b0:
                        continue
                    selected.append(v % (3**e3))
                if e3 == 1:
                    f3.update(selected)
                elif e3 == 2:
                    f9.update(selected)
                elif e3 == 4:
                    f81.update(selected)
                else:
                    raise AssertionError(f"unexpected 3-exponent {e3}")

            max_forbidden_mod3 = max(max_forbidden_mod3, len(f3))
            coarse9 = {x for r3 in f3 for x in range(9) if x % 3 == r3} | f9
            max_forbidden_mod9 = max(max_forbidden_mod9, len(coarse9))
            fine81_new_hits += sum(1 for v in f81 if v % 9 not in coarse9)

    bmask_by_exp: dict[int, dict[int, int]] = {}
    for exp in range(1, maxexp[13] + 1):
        buckets: dict[int, int] = collections.defaultdict(int)
        modulus = 13**exp
        for index, b in enumerate(D13):
            buckets[b % modulus] |= 1 << index
        bmask_by_exp[exp] = buckets
    all_b_mask = (1 << len(D13)) - 1

    def pair_masks(edges: list[dict]) -> list[int]:
        masks = [0] * len(D11)
        for edge in edges:
            fac = factor_dict(edge["q"])
            e11 = fac[11]
            e13 = fac[13]
            forbidden_by_11: dict[int, set[int]] = collections.defaultdict(set)
            for v in edge["R"]:
                forbidden_by_11[v % (11**e11)].add(v % (13**e13))
            for ia, a in enumerate(D11):
                residues = forbidden_by_11.get(a % (11**e11))
                if not residues:
                    continue
                mask = 0
                for rb in residues:
                    mask |= bmask_by_exp[e13].get(rb, 0)
                masks[ia] |= mask
        return masks

    coarse_pair_masks = pair_masks(coarse_pair)
    all_pair_masks = pair_masks(pair_edges)
    fine13_new_full_hits = sum(
        ((all_pair_masks[i] & ~coarse_pair_masks[i]) & all_b_mask).bit_count()
        for i in range(len(D11))
    )

    base3_mask = sum(1 << c for c in D3)
    d3mask_by_exp: dict[int, dict[int, int]] = {}
    for exp in range(1, maxexp[3] + 1):
        buckets: dict[int, int] = collections.defaultdict(int)
        modulus = 3**exp
        for c in D3:
            buckets[c % modulus] |= 1 << c
        d3mask_by_exp[exp] = buckets

    three_maps: list[
        tuple[dict[int, int], tuple[int, ...], dict[tuple[int, ...], int]]
    ] = []
    for edge in three_edges:
        fac = factor_dict(edge["q"])
        e3 = fac[3]
        others = tuple(p for p in (11, 13) if p in fac)
        table: dict[tuple[int, ...], int] = collections.defaultdict(int)
        for v in edge["R"]:
            key = tuple(v % (p ** fac[p]) for p in others)
            table[key] |= d3mask_by_exp[e3].get(v % (3**e3), 0)
        three_maps.append((fac, others, table))

    min_pair_extensions = 10**9
    min_safe3 = 10**9
    safe3_counts: collections.Counter[int] = collections.Counter()

    for ia, a in enumerate(D11):
        safe_b_mask = all_b_mask & ~all_pair_masks[ia]
        min_pair_extensions = min(min_pair_extensions, safe_b_mask.bit_count())

        while safe_b_mask:
            bit = safe_b_mask & -safe_b_mask
            ib = bit.bit_length() - 1
            safe_b_mask -= bit
            b = D13[ib]

            forbidden3 = 0
            for fac, others, table in three_maps:
                key = tuple(
                    (a if p == 11 else b) % (p ** fac[p])
                    for p in others
                )
                forbidden3 |= table.get(key, 0)

            safe_count = (base3_mask & ~forbidden3).bit_count()
            safe3_counts[safe_count] += 1
            min_safe3 = min(min_safe3, safe_count)

    pair["minimum_safe_full13_values_per_full11_all_pair_rows"] = min_pair_extensions
    pair["fine13_new_hits_after_coarse_pair_stage"] = fine13_new_full_hits

    return {
        "pair_stage": pair,
        "max_exponents": {str(p): maxexp[p] for p in PRIMES},
        "unary_full_domain_sizes": {str(p): len(domains[p]) for p in PRIMES},
        "maximum_collective_forbidden_mod3_classes": max_forbidden_mod3,
        "maximum_collective_forbidden_mod9_classes": max_forbidden_mod9,
        "fine81_new_hits_after_mod9_stage": fine81_new_hits,
        "minimum_safe_full3_values_per_safe_1113_pair": min_safe3,
        "safe_full3_count_histogram": {
            str(k): v for k, v in sorted(safe3_counts.items())
        },
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    factors = {n: cc.factor_exp(n) for n in range(1, 4 * k_limit, 2)}
    mfac = [dict()] + [dict(factors[4 * k - 1]) for k in range(1, k_limit + 1)]
    traps = [set()] + [cc.trap_set(k) for k in range(1, k_limit + 1)]
    profiles = {
        k: cc.layer_profile(k, mfac)
        for k in {int(w["k"]) for w in witnesses}
    }

    count_single = 0
    cert1113: list[dict] = []
    cert31113: list[dict] = []

    for index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        fixed, active, _vL = profiles[k]
        Nset = {j for j in fixed if cc.jacobi(r, 4 * j - 1) == -1}
        Nact = [j for j in active if j in Nset]
        if len(Nact) != 1:
            continue
        count_single += 1

        constraints = cc.parameter_constraints(k, r, L, traps)
        primes, residual = cc.fiber_peel(r, L, constraints, factors)

        common = {
            "candidate_index": index,
            "k": k,
            "h": int(rec["h"]),
            "t": int(rec["t"]),
            "r": r,
            "L": L,
            "active_j": Nact[0],
            "residual_primes": list(primes),
            "residual_edge_count": len(residual),
        }

        if primes == (11, 13):
            cert1113.append({
                **common,
                "conditioned": analyse_1113(r, L, residual),
            })
        elif primes == (3, 11, 13):
            cert31113.append({
                **common,
                "conditioned": analyse_31113(r, L, residual),
            })

    if not cert1113 or not cert31113:
        raise AssertionError("expected conditioned-fiber families are missing")

    result = {
        "status": "exact finite C1 conditioned-fiber certificate",
        "k_limit": k_limit,
        "single_active_candidates": count_single,
        "signature_1113_count": len(cert1113),
        "signature_31113_count": len(cert31113),
        "signature_1113": {
            "minimum_safe_base13_classes_per_full11": min(
                x["conditioned"]["minimum_safe_base13_classes_per_full11"]
                for x in cert1113
            ),
            "minimum_safe_full13_values_per_full11": min(
                x["conditioned"]["minimum_safe_full13_values_per_full11"]
                for x in cert1113
            ),
            "fine13_new_hits_after_coarse_pair_stage": sum(
                x["conditioned"]["fine13_new_hits_after_coarse_pair_stage"]
                for x in cert1113
            ),
        },
        "signature_31113": {
            "minimum_unary_full11_domain": min(
                x["conditioned"]["unary_full_domain_sizes"]["11"]
                for x in cert31113
            ),
            "minimum_unary_base11_classes": min(
                x["conditioned"]["pair_stage"]["unary_base_domain_sizes"]["11"]
                for x in cert31113
            ),
            "minimum_unary_base13_classes": min(
                x["conditioned"]["pair_stage"]["unary_base_domain_sizes"]["13"]
                for x in cert31113
            ),
            "minimum_safe_base13_classes_per_full11": min(
                x["conditioned"]["pair_stage"]["minimum_safe_base13_classes_per_full11"]
                for x in cert31113
            ),
            "minimum_safe_full13_values_per_full11": min(
                x["conditioned"]["pair_stage"]["minimum_safe_full13_values_per_full11_all_pair_rows"]
                for x in cert31113
            ),
            "fine13_new_hits_after_coarse_pair_stage": sum(
                x["conditioned"]["pair_stage"]["fine13_new_hits_after_coarse_pair_stage"]
                for x in cert31113
            ),
            "maximum_collective_forbidden_mod3_classes": max(
                x["conditioned"]["maximum_collective_forbidden_mod3_classes"]
                for x in cert31113
            ),
            "maximum_collective_forbidden_mod9_classes": max(
                x["conditioned"]["maximum_collective_forbidden_mod9_classes"]
                for x in cert31113
            ),
            "fine81_new_hits_after_mod9_stage": sum(
                x["conditioned"]["fine81_new_hits_after_mod9_stage"]
                for x in cert31113
            ),
            "minimum_safe_full3_values_per_safe_1113_pair": min(
                x["conditioned"]["minimum_safe_full3_values_per_safe_1113_pair"]
                for x in cert31113
            ),
            "observed_safe_full3_counts": sorted({
                int(key)
                for x in cert31113
                for key in x["conditioned"]["safe_full3_count_histogram"]
            }),
        },
        "certificates_1113": cert1113,
        "certificates_31113": cert31113,
        "claim_boundary": (
            "Exact only for the supplied finite bundle; universal conditioned-fiber positivity remains open."
        ),
    }

    (args.out / "c1-conditioned-fiber.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    a = result["signature_1113"]
    b = result["signature_31113"]
    report = f"""# C1 conditioned-fiber replay

Range: `k <= {k_limit}`.

Single-active candidates reconstructed: **`{count_single}`**.

`{{11,13}}` systems: **`{len(cert1113)}`**. Minimum safe full 13-fiber per surviving full 11 value: **`{a['minimum_safe_full13_values_per_full11']}`**. Fine `13^2` new hits after the coarse pair stage: **`{a['fine13_new_hits_after_coarse_pair_stage']}`**.

`{{3,11,13}}` systems: **`{len(cert31113)}`**. Every unary-safe 11 value retains at least **`{b['minimum_safe_base13_classes_per_full11']}`** safe base-13 classes and at least **`{b['minimum_safe_full13_values_per_full11']}`** full 13 values. Fine `13^2` new hits: **`{b['fine13_new_hits_after_coarse_pair_stage']}`**.

The 3-linear rows collectively forbid at most **`{b['maximum_collective_forbidden_mod3_classes']}`** class mod 3; after mod-9 rows the total is at most **`{b['maximum_collective_forbidden_mod9_classes']}`** classes mod 9. Fine `3^4` new hits after that stage: **`{b['fine81_new_hits_after_mod9_stage']}`**.

Minimum safe full 3-fiber per surviving `(11,13)` pair: **`{b['minimum_safe_full3_values_per_safe_1113_pair']}`**. Observed safe 3-fiber sizes: `{b['observed_safe_full3_counts']}`.

This is a finite theorem-certificate, not universal C1.
"""
    (args.out / "c1-conditioned-fiber-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
