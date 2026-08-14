#!/usr/bin/env python3
"""Exact finite certificates for the hard-class C_AB minimal-depth spectrum.

This probe studies

    C_AB(p) = min{k >= 1 : p mod (4k-1) is in T_k}

where T_k = {-e,-4e mod (4k-1) : e|k}, restricted to the six Mordell
hard residue classes modulo 840.

For each layer k it classifies three cases:

  * no_admissible: no unit trap residue is compatible with a hard class;
  * full_direct_shadow: every admissible candidate is already forced into
    some earlier layer by a single congruence-shadow implication;
  * dirichlet_realized: an explicit one-parameter residue class avoids all
    earlier layers, is coprime to its total period, and therefore contains
    infinitely many primes with exact C_AB depth k by Dirichlet's theorem.

The script also verifies the delayed k=104 hard-class prime p=11035249 and its
exact Type A Erdos-Straus witness.

This is mathematical research code, not a cryptographic attack.
"""

from __future__ import annotations

import argparse
import json
import math
from fractions import Fraction
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)
K104_PRIME = 11035249


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def trap_set(k: int) -> set[int]:
    m = 4 * k - 1
    return {r for e in divisors(k) for r in ((-e) % m, (-4 * e) % m)}


def is_prime_64(n: int) -> bool:
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
    # Deterministic for unsigned 64-bit integers.
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


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm = m // g
    nn = n // g
    inv = pow(mm, -1, nn)
    u = (((b - a) // g) * inv) % nn
    L = m * nn
    return (a + m * u) % L, L


def cab_depth(p: int, traps: list[set[int]], k_max: int) -> int | None:
    for k in range(1, k_max + 1):
        if p % (4 * k - 1) in traps[k]:
            return k
    return None


def admissible_pairs(k: int, traps: list[set[int]]) -> list[tuple[int, int]]:
    m = 4 * k - 1
    g = math.gcd(840, m)
    out: list[tuple[int, int]] = []
    for h in HARD:
        for t in sorted(traps[k]):
            if math.gcd(t, m) == 1 and (t - h) % g == 0:
                out.append((h, t))
    return out


def candidate_shadowed_by(
    k: int,
    h: int,
    t: int,
    j: int,
    traps: list[set[int]],
) -> bool:
    mk = 4 * k - 1
    mj = 4 * j - 1
    cr = crt2(h, 840, t, mk)
    if cr is None:
        return False
    r, L = cr
    g = math.gcd(L, mj)
    fibre_size = mj // g
    if fibre_size > len(traps[j]):
        return False
    # The candidate progression reaches precisely the residues congruent to r mod g.
    possible = set(range(r % g, mj, g))
    return possible <= traps[j]


def direct_shadow_source(
    k: int,
    h: int,
    t: int,
    traps: list[set[int]],
) -> int | None:
    for j in range(1, k):
        if candidate_shadowed_by(k, h, t, j, traps):
            return j
    return None


def parameter_constraints(
    k: int,
    h: int,
    t: int,
    traps: list[set[int]],
) -> tuple[int, int, list[tuple[int, int, set[int]]]]:
    """Return r,L and forbidden s residues for x=r+Ls at every j<k."""
    mk = 4 * k - 1
    cr = crt2(h, 840, t, mk)
    if cr is None:
        raise ValueError("incompatible candidate")
    r, L = cr
    constraints: list[tuple[int, int, set[int]]] = []
    for j in range(1, k):
        mj = 4 * j - 1
        g = math.gcd(L, mj)
        q = mj // g
        if q == 1:
            R = {0} if r % mj in traps[j] else set()
        else:
            A = L // g
            inv = pow(A, -1, q)
            R = {
                (((a - r) // g) * inv) % q
                for a in traps[j]
                if (a - r) % g == 0
            }
        if R:
            constraints.append((j, q, R))
    return r, L, constraints


def realization_certificate(
    k: int,
    pairs: list[tuple[int, int]],
    traps: list[set[int]],
    search_limit: int,
) -> dict | None:
    for h, t in pairs:
        if direct_shadow_source(k, h, t, traps) is not None:
            continue
        r, L, constraints = parameter_constraints(k, h, t, traps)
        for s in range(search_limit + 1):
            if any(s % q in R for _j, q, R in constraints):
                continue
            Q = 1
            for _j, q, _R in constraints:
                Q = math.lcm(Q, q)
            x0 = r + L * s
            M = L * Q
            if math.gcd(x0, M) != 1:
                continue
            # Exact finite validation of the certificate.
            if x0 % (4 * k - 1) not in traps[k]:
                raise AssertionError("candidate lost its target-layer hit")
            for j in range(1, k):
                if x0 % (4 * j - 1) in traps[j]:
                    raise AssertionError(f"candidate unexpectedly hits earlier layer {j}")
            return {
                "k": k,
                "h_mod_840": h,
                "target_residue": t,
                "r": r,
                "L": L,
                "s0": s,
                "Q": Q,
                "progression_modulus_M": M,
                "progression_residue_x0": x0,
                "gcd_x0_M": 1,
            }
    return None


def sieve_primes(limit: int) -> bytearray:
    b = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        b[0] = 0
    if limit >= 1:
        b[1] = 0
    for p in range(2, math.isqrt(limit) + 1):
        if b[p]:
            start = p * p
            b[start : limit + 1 : p] = b"\x00" * (((limit - start) // p) + 1)
    return b


def verify_k104(traps: list[set[int]]) -> dict:
    p = K104_PRIME
    if not is_prime_64(p):
        raise AssertionError("k=104 candidate is not prime")
    depth = cab_depth(p, traps, 104)
    if depth != 104:
        raise AssertionError(f"expected C_AB({p})=104, got {depth}")
    if p % 840 != 169 or p % 415 != 399:
        raise AssertionError("unexpected k=104 CRT residues")

    # Type A data: k=dn=4*26=104 and p=415*q-16.
    d = 4
    n = 26
    q = (p + 4 * d) // (4 * d * n - 1)
    if q != 26591:
        raise AssertionError("unexpected Type A quotient")
    u = n * q - 1
    v = n * p
    x = d * u
    y = d * v
    z = d * u * v
    if Fraction(4, p) != Fraction(1, x) + Fraction(1, y) + Fraction(1, z):
        raise AssertionError("Type A unit-fraction identity failed")

    # Exhaustively establish the first hard-class C_AB=104 occurrence through p.
    prime_bits = sieve_primes(p)
    occurrences: list[int] = []
    for value in range(2, p + 1):
        if not prime_bits[value] or value % 840 not in HARD:
            continue
        if cab_depth(value, traps, 104) == 104:
            occurrences.append(value)
    if occurrences != [p]:
        raise AssertionError(f"unexpected hard-class depth-104 occurrences: {occurrences[:20]}")

    # Explicit Dirichlet certificate discovered from the parameter reduction.
    r = 19489
    L = 69720
    s0 = 158
    x0 = r + L * s0
    if x0 != p:
        raise AssertionError("explicit k=104 parameter does not reproduce p")
    _rr, _LL, constraints = parameter_constraints(104, 169, 399, traps)
    if (_rr, _LL) != (r, L):
        raise AssertionError("unexpected CRT representation for k=104")
    if any(s0 % qj in R for _j, qj, R in constraints):
        raise AssertionError("k=104 parameter does not avoid all earlier constraints")
    Q = 1
    for _j, qj, _R in constraints:
        Q = math.lcm(Q, qj)
    M = L * Q
    if math.gcd(p, M) != 1:
        raise AssertionError("Dirichlet progression is not reduced")

    return {
        "prime": p,
        "C_AB": 104,
        "hard_class_mod_840": 169,
        "target_modulus": 415,
        "target_residue": 399,
        "type": "A",
        "d": d,
        "n": n,
        "q": q,
        "unit_fraction_solution": {"x": x, "y": y, "z": z},
        "first_hard_class_occurrence_through_p": True,
        "dirichlet_certificate": {
            "r": r,
            "L": L,
            "s0": s0,
            "Q": Q,
            "M": M,
            "gcd_prime_M": 1,
            "conclusion": "infinitely many primes in this progression have exact C_AB depth 104",
        },
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=300)
    ap.add_argument("--search-limit", type=int, default=5000)
    ap.add_argument("--out", type=Path, default=Path("cryptology-output"))
    args = ap.parse_args()
    if not (104 <= args.k_limit <= 1000):
        raise SystemExit("--k-limit must be in 104..1000")
    if args.search_limit < 1:
        raise SystemExit("--search-limit must be positive")

    args.out.mkdir(parents=True, exist_ok=True)
    traps = [set()] + [trap_set(k) for k in range(1, args.k_limit + 1)]

    rows: list[dict] = []
    counts = {"no_admissible": 0, "full_direct_shadow": 0, "dirichlet_realized": 0}
    unresolved: list[int] = []

    for k in range(1, args.k_limit + 1):
        pairs = admissible_pairs(k, traps)
        if not pairs:
            rows.append({"k": k, "status": "no_admissible", "admissible_candidates": 0})
            counts["no_admissible"] += 1
            continue

        shadow_sources = []
        unshadowed = []
        for h, t in pairs:
            j = direct_shadow_source(k, h, t, traps)
            if j is None:
                unshadowed.append((h, t))
            else:
                shadow_sources.append({"h": h, "t": t, "j": j})

        if not unshadowed:
            rows.append(
                {
                    "k": k,
                    "status": "full_direct_shadow",
                    "admissible_candidates": len(pairs),
                    "direct_shadow_sources": shadow_sources,
                }
            )
            counts["full_direct_shadow"] += 1
            continue

        cert = realization_certificate(k, unshadowed, traps, args.search_limit)
        if cert is None:
            unresolved.append(k)
            rows.append(
                {
                    "k": k,
                    "status": "unresolved_nonshadowed",
                    "admissible_candidates": len(pairs),
                    "directly_unshadowed_candidates": len(unshadowed),
                }
            )
            continue

        rows.append(
            {
                "k": k,
                "status": "dirichlet_realized",
                "admissible_candidates": len(pairs),
                "directly_unshadowed_candidates": len(unshadowed),
                "certificate": cert,
            }
        )
        counts["dirichlet_realized"] += 1

    k104 = verify_k104(traps)

    result = {
        "status": "exact finite C_AB depth-spectrum certificate experiment",
        "parameters": {"k_limit": args.k_limit, "search_limit": args.search_limit},
        "hard_classes_mod_840": list(HARD),
        "counts": counts,
        "unresolved_nonshadowed_layers": unresolved,
        "k104_delayed_realization": k104,
        "layers": rows,
        "claim_boundary": (
            "A dirichlet_realized row is a rigorous infinite-prime realization certificate. "
            "The finite observation that every non-directly-shadowed layer through the chosen "
            "k_limit receives such a certificate is not a proof that this remains true for all k."
        ),
    }

    if args.k_limit == 300 and args.search_limit >= 5000:
        expected = {
            "no_admissible": 66,
            "full_direct_shadow": 39,
            "dirichlet_realized": 195,
        }
        if counts != expected or unresolved:
            raise AssertionError(
                f"k<=300 spectrum regression: counts={counts}, unresolved={unresolved}, expected={expected}"
            )

    json_path = args.out / "depth-spectrum-probe.json"
    json_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    report = "# Exact Type A/B minimal-depth spectrum probe\n\n"
    report += f"Hard classes: `{','.join(map(str, HARD))} mod 840`.\n\n"
    report += f"Layers checked: `1..{args.k_limit}`; avoiding-parameter search limit: `{args.search_limit}`.\n\n"
    report += "## Structural classification\n\n"
    report += f"- no admissible hard-prime candidate: `{counts['no_admissible']}`\n"
    report += f"- every admissible candidate directly shadowed: `{counts['full_direct_shadow']}`\n"
    report += f"- explicit Dirichlet realization certificate: `{counts['dirichlet_realized']}`\n"
    report += f"- nonshadowed but unresolved within search bound: `{len(unresolved)}`\n\n"
    report += "## Delayed layer k=104\n\n"
    report += (
        "The unique hard-class prime with `C_AB=104` through `11035249` is "
        "`p=11035249`, with `p mod 840 = 169` and `p mod 415 = 399`. "
        "It lies just beyond the earlier `10^7` sweep.\n\n"
    )
    sol = k104["unit_fraction_solution"]
    report += (
        "Its exact Type A Erdos-Straus decomposition is:\n\n"
        f"`4/11035249 = 1/{sol['x']} + 1/{sol['y']} + 1/{sol['z']}`.\n\n"
    )
    report += (
        "The avoiding parameter class is coprime to its total period, so Dirichlet's theorem "
        "upgrades this single delayed prime into an infinite-prime exact-depth-104 result.\n\n"
    )
    if not unresolved:
        report += (
            f"Every layer through `{args.k_limit}` that survives the two simplest structural "
            "obstructions received an explicit infinite-prime realization certificate within "
            "the configured search bound. This is a finite certified pattern, not yet a theorem for all k.\n"
        )
    report_path = args.out / "depth-spectrum-probe-report.md"
    report_path.write_text(report)
    print(report)


if __name__ == "__main__":
    main()
