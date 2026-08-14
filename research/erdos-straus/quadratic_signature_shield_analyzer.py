#!/usr/bin/env python3
"""Exact quadratic-signature shield analyzer for Type A/B candidates.

The analyzer uses only the target CRT candidate (k,h,t,r,L), not the stored
avoiding witness, to decide whether local quadratic signatures prove exact
first-hit realizability.

For each earlier layer j it computes the complete local Legendre-sign image of
T_j. After restricting by the target's fixed prime signs, the unsafe sign set
is an affine subspace of the remaining free sign bits. The analyzer classifies
that restriction as:

* empty: automatically safe;
* full: one direct quadratic-signature obstruction;
* effective codimension one: one required XOR safety equation;
* higher codimension: an affine unsafe set.

It then checks whether every higher-codimension unsafe set is contained in the
violation hyperplane of one codimension-one safety equation. Gaussian
elimination checks the codimension-one backbone for consistency.

A solved signature shield is an independent sufficient certificate for a
reduced avoiding arithmetic progression by CRT and Dirichlet. A direct
quadratic-signature obstruction is only a failure of this coarse certificate;
it does NOT imply an exact Type A/B hit or failure of DSC-P.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path


def sieve_spf(n: int) -> list[int]:
    spf = list(range(n + 1))
    for p in range(2, math.isqrt(n) + 1):
        if spf[p] == p:
            for x in range(p * p, n + 1, p):
                if spf[x] == x:
                    spf[x] = p
    return spf


def factor(n: int, spf: list[int]) -> dict[int, int]:
    out: dict[int, int] = {}
    while n > 1:
        p = spf[n]
        out[p] = out.get(p, 0) + 1
        n //= p
    return out


def divisors_from_factorization(fac: dict[int, int]) -> list[int]:
    out = [1]
    for p, a in fac.items():
        out = [d * p**e for d in out for e in range(a + 1)]
    return out


def legendre_bit(a: int, p: int) -> int:
    v = pow(a % p, (p - 1) // 2, p)
    if v == 1:
        return 0
    if v == p - 1:
        return 1
    raise AssertionError(f"nonunit Legendre input a={a} p={p}")


def rank_and_span(generators: list[int]) -> tuple[int, set[int]]:
    basis: dict[int, int] = {}
    for value in generators:
        x = value
        while x:
            pivot = x.bit_length() - 1
            if pivot in basis:
                x ^= basis[pivot]
            else:
                basis[pivot] = x
                break
    span = {0}
    for value in basis.values():
        span |= {x ^ value for x in list(span)}
    return len(basis), span


def independent_masks(values: list[int]) -> list[int]:
    basis: dict[int, int] = {}
    chosen: list[int] = []
    for value in values:
        x = value
        while x:
            pivot = x.bit_length() - 1
            if pivot in basis:
                x ^= basis[pivot]
            else:
                basis[pivot] = x
                chosen.append(value)
                break
    return chosen


def gaussian(
    equations: list[tuple[int, int, int]],
) -> tuple[dict[int, tuple[int, int, int]], int | None]:
    basis: dict[int, tuple[int, int, int]] = {}
    for mask, rhs, source_j in equations:
        x, b = mask, rhs
        while x:
            pivot = x.bit_length() - 1
            if pivot in basis:
                y, c, _ = basis[pivot]
                x ^= y
                b ^= c
            else:
                basis[pivot] = (x, b, source_j)
                break
        if x == 0 and b:
            return basis, source_j
    return basis, None


def localize_global_pattern(pattern: int, bits: list[int]) -> int:
    out = 0
    for i, global_index in enumerate(bits):
        if (pattern >> global_index) & 1:
            out |= 1 << i
    return out


def all_affine_annihilators(
    global_support: int,
    forbidden_global: set[int],
    global_prime_count: int,
) -> list[tuple[int, int]]:
    bits = [i for i in range(global_prime_count) if (global_support >> i) & 1]
    patterns = [localize_global_pattern(x, bits) for x in forbidden_global]
    x0 = patterns[0]
    differences = [x ^ x0 for x in patterns[1:]]
    out: list[tuple[int, int]] = []
    for w in range(1, 1 << len(bits)):
        if all(((w & d).bit_count() & 1) == 0 for d in differences):
            global_mask = 0
            for i, global_index in enumerate(bits):
                if (w >> i) & 1:
                    global_mask |= 1 << global_index
            const = (w & x0).bit_count() & 1
            out.append((global_mask, const))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    ap.add_argument("--examples", type=int, default=30)
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    spf = sieve_spf(4 * k_limit + 10)
    primes = [p for p in range(3, 4 * k_limit + 10, 2) if spf[p] == p]
    p_index = {p: i for i, p in enumerate(primes)}

    layers: list[dict | None] = [None] * (k_limit + 1)
    quotient_dimension_counts: collections.Counter[int] = collections.Counter()
    explicit_signature_set_checks = 0

    for k in range(1, k_limit + 1):
        m = 4 * k - 1
        mfac = factor(m, spf)
        local_primes = tuple(sorted(mfac))
        squareclass_global = 0
        for p, a in mfac.items():
            if a % 2:
                squareclass_global |= 1 << p_index[p]

        generators: list[int] = []
        for ell in factor(k, spf):
            signature = 0
            for i, p in enumerate(local_primes):
                if legendre_bit(ell, p):
                    signature |= 1 << i
            generators.append(signature)

        rank_h, span_h = rank_and_span(generators)
        eta = 0
        for i, p in enumerate(local_primes):
            if p % 4 == 3:
                eta |= 1 << i
        trap_signatures = {eta ^ h for h in span_h}
        quotient_dimension = len(local_primes) - rank_h
        quotient_dimension_counts[quotient_dimension] += 1

        actual_signatures: set[int] = set()
        for e in divisors_from_factorization(factor(k, spf)):
            a = 0
            b = 0
            for i, p in enumerate(local_primes):
                a |= legendre_bit(-e, p) << i
                b |= legendre_bit(-4 * e, p) << i
            actual_signatures.add(a)
            actual_signatures.add(b)
            explicit_signature_set_checks += 2
        if actual_signatures != trap_signatures:
            raise AssertionError(f"trap-signature coset regression failed at k={k}")

        layers[k] = {
            "m": m,
            "local_primes": local_primes,
            "squareclass_global": squareclass_global,
            "trap_signatures": trap_signatures,
            "quotient_dimension": quotient_dimension,
        }

    base_fixed = 0
    for p in (3, 5, 7):
        base_fixed |= 1 << p_index[p]

    counts: collections.Counter[str] = collections.Counter()
    higher_constraints = 0
    higher_single_shadowed = 0
    single_shadow_sources: collections.Counter[int] = collections.Counter()
    direct_signature_examples: list[dict] = []
    rescued_examples: list[dict] = []
    unexpected_examples: list[dict] = []

    for candidate_index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        target_layer = layers[k]
        assert target_layer is not None

        fixed_mask = base_fixed
        for p in target_layer["local_primes"]:
            fixed_mask |= 1 << p_index[p]

        negative_fixed = 0
        fixed_primes = {3, 5, 7, *target_layer["local_primes"]}
        for p in fixed_primes:
            if L % p == 0 and legendre_bit(r, p):
                negative_fixed |= 1 << p_index[p]

        jacobi_direct_negative = False
        equations: list[tuple[int, int, int]] = []
        higher: list[tuple[int, set[int], int, int]] = []
        direct_signature_layers: list[int] = []

        for j in range(1, k):
            layer = layers[j]
            assert layer is not None

            if layer["squareclass_global"] & ~fixed_mask == 0:
                if (layer["squareclass_global"] & negative_fixed).bit_count() & 1:
                    jacobi_direct_negative = True

            free_global_bits: list[int] = []
            fixed_local_signature = 0
            for local_i, p in enumerate(layer["local_primes"]):
                global_bit = 1 << p_index[p]
                if fixed_mask & global_bit:
                    if negative_fixed & global_bit:
                        fixed_local_signature |= 1 << local_i
                else:
                    free_global_bits.append(global_bit)

            free_count = len(free_global_bits)
            forbidden_local: set[int] = set()
            for signature in layer["trap_signatures"]:
                compatible = True
                pattern = 0
                free_i = 0
                for local_i, p in enumerate(layer["local_primes"]):
                    global_bit = 1 << p_index[p]
                    if fixed_mask & global_bit:
                        if ((signature >> local_i) & 1) != ((fixed_local_signature >> local_i) & 1):
                            compatible = False
                            break
                    else:
                        if (signature >> local_i) & 1:
                            pattern |= 1 << free_i
                        free_i += 1
                if compatible:
                    forbidden_local.add(pattern)

            if not forbidden_local:
                continue
            if len(forbidden_local) == 1 << free_count:
                direct_signature_layers.append(j)
                continue

            log_size = len(forbidden_local).bit_length() - 1
            if 1 << log_size != len(forbidden_local):
                raise AssertionError("affine intersection size is not a power of two")
            effective_codimension = free_count - log_size

            if effective_codimension == 1:
                x0 = next(iter(forbidden_local))
                differences = [x ^ x0 for x in forbidden_local]
                candidate_forms = [
                    w
                    for w in range(1, 1 << free_count)
                    if all(((w & d).bit_count() & 1) == 0 for d in differences)
                ]
                independent = independent_masks(candidate_forms)
                if len(independent) != 1:
                    raise AssertionError("codimension-one forbidden set lacks one annihilator")
                w = independent[0]
                forbidden_rhs = (w & x0).bit_count() & 1
                global_mask = 0
                for free_i, global_bit in enumerate(free_global_bits):
                    if (w >> free_i) & 1:
                        global_mask |= global_bit
                equations.append((global_mask, forbidden_rhs ^ 1, j))
            else:
                global_support = 0
                for global_bit in free_global_bits:
                    global_support |= global_bit
                forbidden_global: set[int] = set()
                for pattern in forbidden_local:
                    value = 0
                    for free_i, global_bit in enumerate(free_global_bits):
                        if (pattern >> free_i) & 1:
                            value |= global_bit
                    forbidden_global.add(value)
                higher.append((global_support, forbidden_global, j, effective_codimension))

        if jacobi_direct_negative:
            counts["jacobi_character_residual"] += 1
        else:
            counts["jacobi_character_shield_solved"] += 1

        if direct_signature_layers:
            counts["direct_signature_residual"] += 1
            if len(direct_signature_examples) < args.examples:
                direct_signature_examples.append(
                    {
                        "candidate_index": candidate_index,
                        "k": k,
                        "h": int(rec["h"]),
                        "t": int(rec["t"]),
                        "direct_signature_layers": direct_signature_layers[:20],
                    }
                )
            continue

        _basis, inconsistent_at = gaussian(equations)
        if inconsistent_at is not None:
            counts["collective_codim1_inconsistency"] += 1
            if len(unexpected_examples) < args.examples:
                unexpected_examples.append(
                    {
                        "candidate_index": candidate_index,
                        "k": k,
                        "h": int(rec["h"]),
                        "t": int(rec["t"]),
                        "kind": "codim1_inconsistency",
                        "source_layer": inconsistent_at,
                    }
                )
            continue

        equation_map: dict[int, list[tuple[int, int]]] = collections.defaultdict(list)
        for mask, safe_rhs, source_j in equations:
            equation_map[mask].append((safe_rhs, source_j))

        all_higher_shadowed = True
        for global_support, forbidden_global, target_j, effective_codimension in higher:
            higher_constraints += 1
            shadow_source = None
            for mask, forbidden_rhs in all_affine_annihilators(
                global_support, forbidden_global, len(primes)
            ):
                for safe_rhs, source_j in equation_map.get(mask, ()):
                    if safe_rhs != forbidden_rhs:
                        shadow_source = source_j
                        break
                if shadow_source is not None:
                    break
            if shadow_source is None:
                all_higher_shadowed = False
                if len(unexpected_examples) < args.examples:
                    unexpected_examples.append(
                        {
                            "candidate_index": candidate_index,
                            "k": k,
                            "h": int(rec["h"]),
                            "t": int(rec["t"]),
                            "kind": "unshadowed_higher_signature_constraint",
                            "earlier_layer": target_j,
                            "effective_codimension": effective_codimension,
                        }
                    )
            else:
                higher_single_shadowed += 1
                single_shadow_sources[shadow_source] += 1

        if all_higher_shadowed:
            counts["quadratic_signature_shield_solved"] += 1
            if jacobi_direct_negative:
                counts["rescued_beyond_jacobi"] += 1
                if len(rescued_examples) < args.examples:
                    rescued_examples.append(
                        {
                            "candidate_index": candidate_index,
                            "k": k,
                            "h": int(rec["h"]),
                            "t": int(rec["t"]),
                        }
                    )
        else:
            counts["unresolved_signature_system"] += 1

        if candidate_index % 5000 == 0:
            print(
                f"signature-shield progress {candidate_index}/{len(witnesses)} "
                f"solved={counts['quadratic_signature_shield_solved']} "
                f"direct={counts['direct_signature_residual']} "
                f"higher={higher_constraints} higher_shadowed={higher_single_shadowed}",
                flush=True,
            )

    n = len(witnesses)
    result = {
        "status": "exact quadratic-signature shield analysis",
        "k_limit": k_limit,
        "direct_novel_candidates": n,
        "explicit_trap_signature_checks": explicit_signature_set_checks,
        "quotient_dimension_counts": {
            str(k): v for k, v in sorted(quotient_dimension_counts.items())
        },
        "jacobi_character_shield_solved": counts["jacobi_character_shield_solved"],
        "jacobi_character_residual": counts["jacobi_character_residual"],
        "quadratic_signature_shield_solved": counts["quadratic_signature_shield_solved"],
        "quadratic_signature_shield_solved_fraction": counts["quadratic_signature_shield_solved"] / n,
        "direct_signature_residual": counts["direct_signature_residual"],
        "rescued_beyond_jacobi": counts["rescued_beyond_jacobi"],
        "collective_codim1_inconsistency": counts["collective_codim1_inconsistency"],
        "higher_codimension_constraints": higher_constraints,
        "higher_constraints_single_shadowed": higher_single_shadowed,
        "unresolved_signature_system": counts["unresolved_signature_system"],
        "top_signature_shadow_sources": [
            {"j": j, "count": count}
            for j, count in single_shadow_sources.most_common(40)
        ],
        "direct_signature_examples": direct_signature_examples,
        "rescued_beyond_jacobi_examples": rescued_examples,
        "unexpected_examples": unexpected_examples,
        "claim_boundary": (
            "A solved quadratic-signature shield is an independent sufficient certificate for a reduced avoiding progression. "
            "A direct signature residual means only that one earlier layer is unavoidable at this coarse local-character resolution; exact trap residues may still be avoided. "
            "Finite absence of collective signature obstruction is not promoted to a universal theorem without proof."
        ),
    }
    (args.out / "quadratic-signature-shield-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Quadratic-signature shield\n\n"
    report += f"Range: `k <= {k_limit}`; directly novel candidates: `{n}`.\n\n"
    report += f"Explicit trap-signature coset checks: **`{explicit_signature_set_checks}`**.\n\n"
    report += f"Jacobi character shield solved: **`{counts['jacobi_character_shield_solved']}`** (`{counts['jacobi_character_shield_solved']/n:.3%}`).\n\n"
    report += f"Full local quadratic-signature shield solved: **`{counts['quadratic_signature_shield_solved']}`** (`{counts['quadratic_signature_shield_solved']/n:.3%}`).\n\n"
    report += f"Rescued beyond Jacobi by finer local signs: **`{counts['rescued_beyond_jacobi']}`**.\n\n"
    report += f"Direct quadratic-signature residual: **`{counts['direct_signature_residual']}`**.\n\n"
    report += f"Collective codimension-one inconsistencies without a direct signature obstruction: **`{counts['collective_codim1_inconsistency']}`**.\n\n"
    report += f"Higher-codimension unsafe constraints examined: **`{higher_constraints}`**.\n\n"
    report += f"Higher constraints shadowed by one codimension-one signature constraint: **`{higher_single_shadowed}`**.\n\n"
    report += f"Unresolved collective signature systems: **`{counts['unresolved_signature_system']}`**.\n\n"
    report += (
        "A signature-shield success independently proves an infinite reduced exact-depth prime progression by CRT and Dirichlet. "
        "A residual is only a limitation of quadratic-signature resolution, not a failure of exact Type A/B avoidance.\n"
    )
    (args.out / "quadratic-signature-shield-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
