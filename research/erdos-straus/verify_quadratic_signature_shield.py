#!/usr/bin/env python3
"""Independent verifier for the quadratic-signature shield analysis.

Unlike `quadratic_signature_shield_analyzer.py`, this verifier constructs each
layer's trap-signature set directly by enumerating the divisors e|k and taking
the local Legendre signatures of -e and -4e. It does not use the affine-coset
formula to construct the unsafe signature set.

The verifier recomputes, for every directly novel candidate in the supplied
certificate bundle:

* Jacobi-character shield status;
* direct full-signature obstruction status;
* consistency of the effective-codimension-one safety equations;
* every higher-codimension signature constraint;
* containment of each such higher constraint in the violation hyperplane of
  one codimension-one safety equation.

A disagreement or an unshadowed higher constraint causes failure. The stored
integer/reduced avoiding witness is never used for the signature decision.
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


def divisors(n: int, spf: list[int]) -> list[int]:
    out = [1]
    for p, a in factor(n, spf).items():
        out = [d * p**e for d in out for e in range(a + 1)]
    return out


def legendre_bit(a: int, p: int) -> int:
    value = pow(a % p, (p - 1) // 2, p)
    if value == 1:
        return 0
    if value == p - 1:
        return 1
    raise AssertionError(f"nonunit Legendre input a={a} p={p}")


def independent(values: list[int]) -> list[int]:
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


def gaussian_consistent(equations: list[tuple[int, int]]) -> bool:
    basis: dict[int, tuple[int, int]] = {}
    for mask, rhs in equations:
        x, b = mask, rhs
        while x:
            pivot = x.bit_length() - 1
            if pivot in basis:
                y, c = basis[pivot]
                x ^= y
                b ^= c
            else:
                basis[pivot] = (x, b)
                break
        if x == 0 and b:
            return False
    return True


def localize(pattern: int, bits: list[int]) -> int:
    out = 0
    for i, bit in enumerate(bits):
        if (pattern >> bit) & 1:
            out |= 1 << i
    return out


def affine_annihilators(
    support: int,
    forbidden: set[int],
    prime_count: int,
) -> list[tuple[int, int]]:
    bits = [i for i in range(prime_count) if (support >> i) & 1]
    patterns = [localize(x, bits) for x in forbidden]
    x0 = patterns[0]
    differences = [x ^ x0 for x in patterns[1:]]
    out: list[tuple[int, int]] = []
    for w in range(1, 1 << len(bits)):
        if all(((w & d).bit_count() & 1) == 0 for d in differences):
            global_mask = 0
            for i, bit in enumerate(bits):
                if (w >> i) & 1:
                    global_mask |= 1 << bit
            out.append((global_mask, (w & x0).bit_count() & 1))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("direct-shadow-output"))
    args = ap.parse_args()

    source = json.loads((args.out / "direct-shadow-completeness.json").read_text())
    witnesses: list[dict] = source["witnesses"]
    k_limit = int(source["parameters"]["k_limit"])

    spf = sieve_spf(4 * k_limit + 10)
    primes = [p for p in range(3, 4 * k_limit + 10, 2) if spf[p] == p]
    p_index = {p: i for i, p in enumerate(primes)}

    layers: list[dict | None] = [None] * (k_limit + 1)
    for k in range(1, k_limit + 1):
        m = 4 * k - 1
        mfac = factor(m, spf)
        local_primes = tuple(sorted(mfac))
        squareclass = 0
        for p, a in mfac.items():
            if a % 2:
                squareclass |= 1 << p_index[p]

        trap_signatures: set[int] = set()
        for e in divisors(k, spf):
            for value in (-e, -4 * e):
                signature = 0
                for i, p in enumerate(local_primes):
                    signature |= legendre_bit(value, p) << i
                trap_signatures.add(signature)
        layers[k] = {
            "local_primes": local_primes,
            "squareclass": squareclass,
            "trap_signatures": trap_signatures,
        }

    base_fixed = sum(1 << p_index[p] for p in (3, 5, 7))
    counts: collections.Counter[str] = collections.Counter()
    higher_total = 0
    higher_shadowed = 0

    for candidate_index, rec in enumerate(witnesses, start=1):
        k = int(rec["k"])
        r = int(rec["r"])
        L = int(rec["L"])
        target = layers[k]
        assert target is not None

        fixed = base_fixed
        for p in target["local_primes"]:
            fixed |= 1 << p_index[p]

        negative = 0
        for p in {3, 5, 7, *target["local_primes"]}:
            if L % p == 0 and legendre_bit(r, p):
                negative |= 1 << p_index[p]

        jacobi_residual = False
        direct_signature = False
        equations: list[tuple[int, int]] = []
        higher: list[tuple[int, set[int]]] = []

        for j in range(1, k):
            layer = layers[j]
            assert layer is not None
            if layer["squareclass"] & ~fixed == 0:
                if (layer["squareclass"] & negative).bit_count() & 1:
                    jacobi_residual = True

            free_global_bits: list[int] = []
            fixed_local = 0
            for local_i, p in enumerate(layer["local_primes"]):
                global_bit = 1 << p_index[p]
                if fixed & global_bit:
                    if negative & global_bit:
                        fixed_local |= 1 << local_i
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
                    if fixed & global_bit:
                        if ((signature >> local_i) & 1) != ((fixed_local >> local_i) & 1):
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
                direct_signature = True
                continue

            log_size = len(forbidden_local).bit_length() - 1
            if 1 << log_size != len(forbidden_local):
                raise AssertionError("explicit trap signature intersection is not affine")
            effective_codimension = free_count - log_size

            if effective_codimension == 1:
                x0 = next(iter(forbidden_local))
                differences = [x ^ x0 for x in forbidden_local]
                forms = [
                    w
                    for w in range(1, 1 << free_count)
                    if all(((w & d).bit_count() & 1) == 0 for d in differences)
                ]
                basis = independent(forms)
                if len(basis) != 1:
                    raise AssertionError("bad codimension-one explicit signature set")
                w = basis[0]
                mask = 0
                for i, global_bit in enumerate(free_global_bits):
                    if (w >> i) & 1:
                        mask |= global_bit
                forbidden_rhs = (w & x0).bit_count() & 1
                equations.append((mask, forbidden_rhs ^ 1))
            else:
                support = 0
                for global_bit in free_global_bits:
                    support |= global_bit
                forbidden_global: set[int] = set()
                for pattern in forbidden_local:
                    value = 0
                    for i, global_bit in enumerate(free_global_bits):
                        if (pattern >> i) & 1:
                            value |= global_bit
                    forbidden_global.add(value)
                higher.append((support, forbidden_global))

        if jacobi_residual:
            counts["jacobi_residual"] += 1
        else:
            counts["jacobi_solved"] += 1

        if direct_signature:
            counts["direct_signature_residual"] += 1
            continue

        if not gaussian_consistent(equations):
            counts["collective_codim1_inconsistency"] += 1
            continue

        equation_map: dict[int, set[int]] = collections.defaultdict(set)
        for mask, rhs in equations:
            equation_map[mask].add(rhs)

        all_shadowed = True
        for support, forbidden in higher:
            higher_total += 1
            found = False
            for mask, forbidden_rhs in affine_annihilators(
                support, forbidden, len(primes)
            ):
                if any(safe_rhs != forbidden_rhs for safe_rhs in equation_map.get(mask, ())):
                    found = True
                    break
            if found:
                higher_shadowed += 1
            else:
                all_shadowed = False

        if all_shadowed:
            counts["signature_solved"] += 1
            if jacobi_residual:
                counts["rescued_beyond_jacobi"] += 1
        else:
            counts["unresolved_signature_system"] += 1

        if candidate_index % 5000 == 0:
            print(
                f"signature verifier {candidate_index}/{len(witnesses)} "
                f"solved={counts['signature_solved']} direct={counts['direct_signature_residual']} "
                f"higher={higher_total} shadowed={higher_shadowed}",
                flush=True,
            )

    result = {
        "verdict": "VERIFIED"
        if counts["collective_codim1_inconsistency"] == 0
        and counts["unresolved_signature_system"] == 0
        and higher_total == higher_shadowed
        else "FAILED",
        "k_limit": k_limit,
        "direct_novel_candidates": len(witnesses),
        "jacobi_character_shield_solved": counts["jacobi_solved"],
        "jacobi_character_residual": counts["jacobi_residual"],
        "quadratic_signature_shield_solved": counts["signature_solved"],
        "direct_signature_residual": counts["direct_signature_residual"],
        "rescued_beyond_jacobi": counts["rescued_beyond_jacobi"],
        "collective_codim1_inconsistency": counts["collective_codim1_inconsistency"],
        "higher_codimension_constraints": higher_total,
        "higher_constraints_single_shadowed": higher_shadowed,
        "unresolved_signature_system": counts["unresolved_signature_system"],
        "method": "explicit divisor enumeration of local trap signatures",
        "claim_boundary": (
            "This verifies a finite quadratic-signature certificate result only. "
            "A direct signature residual is not an exact Type A/B obstruction."
        ),
    }
    (args.out / "quadratic-signature-shield-independent-verifier.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(result, indent=2, sort_keys=True))
    if result["verdict"] != "VERIFIED":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
