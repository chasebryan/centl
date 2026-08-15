#!/usr/bin/env python3
"""Independent verifier for reduced_domain_tight_probe.py.

Independence boundary:
- does not import the primary probe;
- discovers tight layers by directly scanning every earlier j rather than by
  the divisor condition m_j | qL;
- reconstructs every pullback from the defining congruence;
- checks the affine reduced-domain theorem against gcd(r+Ls,LQ) directly;
- recomputes exact direct shadows from complete attained fibres.

The verifier is intentionally slower.  Its default finite range includes the
first corrected-domain three-class q=3 cover observed at k=8378.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from functools import lru_cache
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


def divisors(n: int) -> list[int]:
    a: list[int] = []
    b: list[int] = []
    d = 1
    while d * d <= n:
        if n % d == 0:
            a.append(d)
            if d * d != n:
                b.append(n // d)
        d += 1
    return a + b[::-1]


@lru_cache(maxsize=None)
def traps(j: int) -> frozenset[int]:
    m = 4 * j - 1
    out: set[int] = set()
    for e in divisors(j):
        out.add((-e) % m)
        out.add((-4 * e) % m)
    return frozenset(out)


def crt(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    d = math.gcd(m, n)
    if (a - b) % d:
        return None
    m1 = m // d
    n1 = n // d
    if n1 == 1:
        t = 0
    else:
        t = (((b - a) // d) * pow(m1, -1, n1)) % n1
    mod = m * n1
    return (a + m * t) % mod, mod


def factor_primes(n: int) -> list[int]:
    out: list[int] = []
    p = 2
    x = n
    while p * p <= x:
        if x % p == 0:
            out.append(p)
            while x % p == 0:
                x //= p
        p = 3 if p == 2 else p + 2
    if x > 1:
        out.append(x)
    return out


def pullback_direct(r: int, L: int, j: int) -> tuple[int, frozenset[int]]:
    m = 4 * j - 1
    g = math.gcd(L, m)
    q = m // g
    R: set[int] = set()
    if q == 1:
        if r % m in traps(j):
            R.add(0)
        return q, frozenset(R)

    # Independent construction: enumerate the q parameter classes and test the
    # defining hit condition directly, instead of inverting L/g.
    for s in range(q):
        if (r + L * s) % m in traps(j):
            R.add(s)
    return q, frozenset(R)


def exact_domain_ok(s: int, r: int, L: int, Q: int) -> bool:
    return math.gcd(r + L * s, L * Q) == 1


def affine_domain_ok(s: int, r: int, L: int, Q: int) -> bool:
    for p in factor_primes(Q):
        if L % p == 0:
            continue
        if s % p == (-r * pow(L, -1, p)) % p:
            return False
    return True


def direct_shadows(r: int, L: int, k: int) -> list[dict]:
    found: list[dict] = []
    for j in range(1, k):
        m = 4 * j - 1
        g = math.gcd(L, m)
        q = m // g
        T = traps(j)
        if q > len(T):
            continue
        values = {(r + L * s) % m for s in range(q)}
        if values and values <= T:
            found.append({"j": j, "q": q})
    return found


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--k-limit", type=int, default=8500)
    ap.add_argument("--q-max", type=int, default=9)
    ap.add_argument("--out", type=Path, default=Path("reduced-domain-tight-output"))
    ap.add_argument("--compare-primary", action="store_true")
    args = ap.parse_args()

    counts = collections.Counter()
    failures: list[dict] = []

    for k in range(2, args.k_limit + 1):
        M = 4 * k - 1
        L = math.lcm(840, M)

        # Deliberately independent from the primary divisor enumeration.
        layers: list[tuple[int, int]] = []
        for j in range(1, k):
            m = 4 * j - 1
            q = m // math.gcd(L, m)
            if 1 < q <= args.q_max:
                layers.append((j, q))
        if not layers:
            continue

        target_g = math.gcd(840, M)
        for h in HARD:
            for t in traps(k):
                if (t - h) % target_g:
                    continue
                candidate = crt(h, 840, t, M)
                if candidate is None:
                    raise AssertionError("admissible CRT failure")
                r, candidate_L = candidate
                if candidate_L != L or math.gcd(r, L) != 1:
                    raise AssertionError("candidate invariant failure")

                counts["candidates_with_tight_layers"] += 1
                constraints: list[tuple[int, int, frozenset[int]]] = []
                Q = 1
                for j, expected_q in layers:
                    q, R = pullback_direct(r, L, j)
                    if q != expected_q:
                        raise AssertionError("quotient mismatch")
                    if R:
                        constraints.append((j, q, R))
                        Q = math.lcm(Q, q)

                escaped = False
                for s in range(Q):
                    affine = affine_domain_ok(s, r, L, Q)
                    exact = exact_domain_ok(s, r, L, Q)
                    if affine != exact:
                        raise AssertionError(
                            f"affine reduced-domain mismatch k={k} h={h} t={t} s={s}"
                        )
                    if not exact:
                        continue
                    if all(s % q not in R for _j, q, R in constraints):
                        escaped = True
                        break

                if escaped:
                    counts["tight_escapes"] += 1
                    continue

                counts["tight_full_domain_failures"] += 1
                ds = direct_shadows(r, L, k)
                if ds:
                    counts["tight_failures_already_direct_shadowed"] += 1
                else:
                    counts["direct_novel_tight_failures"] += 1
                failures.append(
                    {
                        "k": k,
                        "h": h,
                        "t": t,
                        "Q": Q,
                        "constraints": [
                            {"j": j, "q": q, "R": sorted(R)}
                            for j, q, R in constraints
                        ],
                        "direct_shadows": ds,
                    }
                )

        if k % 500 == 0:
            print(
                f"verify progress k={k} candidates={counts['candidates_with_tight_layers']} "
                f"fail={counts['tight_full_domain_failures']} "
                f"novel={counts['direct_novel_tight_failures']}",
                flush=True,
            )

    result = {
        "verdict": "VERIFIED" if counts["direct_novel_tight_failures"] == 0 else "NOVEL TIGHT FAILURE FOUND",
        "independent_construction": "direct scan of every earlier j; direct enumeration of parameter pullback classes",
        "k_limit": args.k_limit,
        "q_max": args.q_max,
        "counts": dict(counts),
        "failure_examples": failures[:40],
    }

    if args.compare_primary:
        primary_path = args.out / "reduced-domain-tight.json"
        primary = json.loads(primary_path.read_text())
        if int(primary["k_limit"]) != args.k_limit:
            raise AssertionError("primary and verifier k limits differ")
        if int(primary["q_max"]) != args.q_max:
            raise AssertionError("primary and verifier q limits differ")
        for field in (
            "candidates_with_tight_layers",
            "tight_escapes",
            "tight_full_domain_failures",
            "tight_failures_already_direct_shadowed",
            "direct_novel_tight_failures",
        ):
            if int(primary["counts"].get(field, 0)) != int(counts.get(field, 0)):
                raise AssertionError(
                    f"primary/verifier mismatch {field}: "
                    f"{primary['counts'].get(field,0)} != {counts.get(field,0)}"
                )
        result["primary_comparison"] = "MATCH"

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "reduced-domain-tight-independent-verifier.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
