#!/usr/bin/env python3
"""Shared-factor CN analyzer for Type A/B active-core escape.

Proves-by-search the remaining C2/CN shared-factor geometries after the
lift-room and union-bound theorems.  Independently recomputes every
pullback; no stored witness is consulted.

This is a theorem falsifier / finite certificate generator.  It does not
prove universal DSC-P, López coverage, or Erdős-Straus.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path


def divisors(n: int) -> list[int]:
    lo: list[int] = []
    hi: list[int] = []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def prime_divisors(n: int) -> list[int]:
    out: list[int] = []
    x = abs(n)
    p = 2
    while p * p <= x:
        if x % p == 0:
            out.append(p)
            while x % p == 0:
                x //= p
        p = 3 if p == 2 else p + 2
    if x > 1:
        out.append(x)
    return out


def phi(n: int) -> int:
    result = n
    for p in prime_divisors(n):
        result -= result // p
    return result


def trap_set(j: int) -> set[int]:
    m = 4 * j - 1
    return {r for e in divisors(j) for r in ((-e) % m, (-4 * e) % m)}


def totient_ratio(q: int, d: int) -> int:
    """Exact φ(q)/φ(d) for d|q. Integer because the reduction of units is regular."""
    if d <= 0 or q % d != 0:
        raise ValueError("d must be a positive divisor of q")
    pq, pd = phi(q), phi(d)
    if pq % pd != 0:
        raise AssertionError(f"φ({q})={pq} not divisible by φ({d})={pd}")
    return pq // pd


def pullback(r: int, L: int, j: int, traps: set[int] | None = None) -> tuple[int, int, set[int]]:
    m = 4 * j - 1
    g = math.gcd(L, m)
    q = m // g
    T = traps if traps is not None else trap_set(j)
    R: set[int] = set()
    if q == 1:
        return g, q, R
    inv = pow((L // g) % q, -1, q)
    for u in T:
        if (u - r) % g == 0:
            R.add((((u - r) // g) * inv) % q)
    return g, q, R


def units(q: int) -> list[int]:
    return [s for s in range(q) if math.gcd(s, q) == 1]


def c1_escape(q: int, R: set[int]) -> bool:
    """U \\ R nonempty. Uses pigeonhole when φ(q) > |R|; else scans units."""
    if q <= 1:
        return True
    if phi(q) > len(R):
        return True
    return any(math.gcd(s, q) == 1 and s not in R for s in range(q))


def safe_units(q: int, R: set[int]) -> list[int]:
    return [s for s in units(q) if s not in R]


def blocked_projections(q: int, R: set[int], d: int) -> set[int]:
    """Residues a mod d whose every unit lift to mod q lies in R."""
    if d <= 1:
        return set()
    ratio = totient_ratio(q, d)
    counts: dict[int, int] = {}
    for x in R:
        if math.gcd(x, q) == 1:
            a = x % d
            counts[a] = counts.get(a, 0) + 1
    return {a for a, c in counts.items() if c >= ratio}


def pair_compatible_fast(q1: int, R1: set[int], q2: int, R2: set[int]) -> bool:
    if q1 <= 1 or q2 <= 1:
        return c1_escape(q1, R1) and c1_escape(q2, R2)
    if not c1_escape(q1, R1) or not c1_escape(q2, R2):
        return False
    d = math.gcd(q1, q2)
    if d == 1:
        return True
    b1 = blocked_projections(q1, R1, d)
    b2 = blocked_projections(q2, R2, d)
    for a in range(d):
        if math.gcd(a, d) != 1:
            continue
        if a not in b1 and a not in b2:
            return True
    return False


def crt_pair(a1: int, q1: int, a2: int, q2: int) -> int | None:
    d = math.gcd(q1, q2)
    if (a1 - a2) % d != 0:
        return None
    # Standard CRT to modulus lcm.
    lcm = q1 // d * q2
    # Solve x ≡ a1 (mod q1), x ≡ a2 (mod q2).
    inv = pow((q1 // d) % (q2 // d), -1, q2 // d)
    t = ((a2 - a1) // d * inv) % (q2 // d)
    return (a1 + q1 * t) % lcm


def pair_compatible(S1: list[int], q1: int, S2: list[int], q2: int) -> bool:
    d = math.gcd(q1, q2)
    if d == 1:
        return bool(S1) and bool(S2)
    proj2 = {a % d for a in S2}
    return any(a % d in proj2 for a in S1)


def simultaneous_escape(constraints: list[tuple[int, set[int]]]) -> bool:
    """Decide simultaneous reduced escape.

    Roomy layers (lift-room over gcd with the lcm of the others, or
    union-bound) are peeled first.  Only tight small-q layers are
    backtracked, and then only over the forbidden projections, not U.
    """
    cons = [(q, set(R)) for q, R in constraints if q > 1]
    if not cons:
        return True
    if any(not c1_escape(q, R) for q, R in cons):
        return False
    # Union bound
    if sum(len(R) / max(phi(q), 1) for q, R in cons) < 1 - 1e-15:
        return True
    # Peel globally roomy layers: roomy over gcd(q, lcm of other q's).
    changed = True
    while changed and cons:
        changed = False
        lcm_all = 1
        for q, _ in cons:
            lcm_all = math.lcm(lcm_all, q)
        keep: list[tuple[int, set[int]]] = []
        for i, (q, R) in enumerate(cons):
            lcm_rest = 1
            for j, (q2, _) in enumerate(cons):
                if j == i:
                    continue
                lcm_rest = math.lcm(lcm_rest, q2)
            d = math.gcd(q, lcm_rest)
            if d == 1 or lift_room(q, R, d):
                changed = True
                continue
            keep.append((q, R))
        cons = keep
    if not cons:
        return True
    # Remaining tight cluster: backtrack, generating S only for small q.
    cons.sort(key=lambda qr: phi(qr[0]))

    def rec(idx: int, a: int, mod: int) -> bool:
        if idx == len(cons):
            return math.gcd(a, mod) == 1 or mod == 1
        q, R = cons[idx]
        if not c1_escape(q, R):
            return False
        # Build candidate residues: if q is large, iterate complement via blocked
        if q <= 4096:
            S = safe_units(q, R)
        else:
            # should have been peeled; fallback pigeonhole sample
            S = []
            for s in range(q):
                if math.gcd(s, q) == 1 and s not in R:
                    S.append(s)
                    if len(S) >= 8:
                        break
        if not S:
            return False
        if mod == 1:
            for s in S:
                if rec(idx + 1, s, q):
                    return True
            return False
        d = math.gcd(mod, q)
        for s in S:
            if (a - s) % d != 0:
                continue
            x = crt_pair(a, mod, s, q)
            if x is None:
                continue
            new_mod = mod // d * q
            if rec(idx + 1, x, new_mod):
                return True
        return False

    return rec(0, 0, 1)


def lift_room(q: int, R: set[int], d: int) -> bool:
    if d == 1:
        return True
    if q % d != 0:
        raise ValueError("d must divide q")
    return totient_ratio(q, d) > len(R)


def classify_pair(r: int, L: int, j1: int, j2: int, cache: dict[int, set[int]]) -> dict:
    if j1 not in cache:
        cache[j1] = trap_set(j1)
    if j2 not in cache:
        cache[j2] = trap_set(j2)
    g1, q1, R1 = pullback(r, L, j1, cache[j1])
    g2, q2, R2 = pullback(r, L, j2, cache[j2])
    s1_ok = c1_escape(q1, R1)
    s2_ok = c1_escape(q2, R2)
    d = math.gcd(q1, q2) if q1 > 1 and q2 > 1 else 1
    c1_fail = (q1 > 1 and not s1_ok) or (q2 > 1 and not s2_ok)
    if q1 <= 1 or q2 <= 1:
        kind = "inactive"
        ok = not c1_fail
    elif d == 1:
        kind = "coprime"
        ok = s1_ok and s2_ok
    else:
        room1 = lift_room(q1, R1, d)
        room2 = lift_room(q2, R2, d)
        compat = pair_compatible_fast(q1, R1, q2, R2)
        if room1 or room2:
            kind = "lift-room"
            ok = compat
        elif q1 == q2:
            kind = "same-q-tight"
            ok = compat
        else:
            kind = "mixed-tight"
            ok = compat
    return {
        "j1": j1,
        "j2": j2,
        "r": r,
        "L": L,
        "q1": q1,
        "q2": q2,
        "g1": g1,
        "g2": g2,
        "d": d,
        "|R1|": len(R1),
        "|R2|": len(R2),
        "kind": kind,
        "ok": ok,
        "c1_fail": c1_fail,
        "R1": sorted(R1),
        "R2": sorted(R2),
    }


def layers_with_q(L: int, q_target: int, j_limit: int | None = None) -> list[int]:
    """Every j whose pullback modulus is exactly q_target.

    Theorem: 4j-1 divides q_target * L, so the list is finite and exact.
    """
    out: list[int] = []
    bound = q_target * L
    for m in divisors(bound):
        if m % 4 != 3:
            continue
        j = (m + 1) // 4
        if j < 1:
            continue
        if j_limit is not None and j > j_limit:
            continue
        g = math.gcd(L, m)
        if m // g == q_target:
            out.append(j)
    return sorted(set(out))


def all_positive_q_layers(L: int, j_limit: int) -> list[tuple[int, int]]:
    rows: list[tuple[int, int]] = []
    for j in range(1, j_limit + 1):
        m = 4 * j - 1
        g = math.gcd(L, m)
        q = m // g
        if q > 1:
            rows.append((j, q))
    return rows


def scan_standard_pairs(Ls: list[int], j_limit: int, r_samples: list[int]) -> dict:
    cache: dict[int, set[int]] = {}
    counts = collections.Counter()
    fails: list[dict] = []
    c1_fails: list[dict] = []
    q3_comp: list[dict] = []
    kinds = collections.Counter()
    max_r_size = 0
    checked = 0
    for L in Ls:
        js = [j for j, q in all_positive_q_layers(L, j_limit)]
        for i, j1 in enumerate(js):
            for j2 in js[i + 1 :]:
                for r in r_samples:
                    row = classify_pair(r, L, j1, j2, cache)
                    checked += 1
                    kinds[row["kind"]] += 1
                    max_r_size = max(max_r_size, row["|R1|"], row["|R2|"])
                    if row["c1_fail"]:
                        c1_fails.append(row)
                    if not row["ok"]:
                        fails.append(row)
                    if (
                        row["q1"] == 3
                        and row["q2"] == 3
                        and not row["ok"]
                    ):
                        q3_comp.append(row)
    return {
        "checked": checked,
        "kinds": dict(kinds),
        "fails": len(fails),
        "c1_fails": len(c1_fails),
        "q3_complementary": len(q3_comp),
        "max_|R|": max_r_size,
        "fail_examples": fails[:20],
        "q3_examples": q3_comp[:20],
        "c1_examples": c1_fails[:10],
    }


def complementary_r_candidates(L: int, j1: int, j2: int, cache: dict[int, set[int]]) -> list[int]:
    """Every r that could make (j1,j2) a complementary q=3 cover.

    A complementary cover requires one of
        r+L ∈ T_{j1} (mod m1) and r+2L ∈ T_{j2} (mod m2),
        r+2L ∈ T_{j1} (mod m1) and r+L ∈ T_{j2} (mod m2).
    Those are finitely many CRT classes, so the search is exact.
    """
    m1, m2 = 4 * j1 - 1, 4 * j2 - 1
    T1 = cache.setdefault(j1, trap_set(j1))
    T2 = cache.setdefault(j2, trap_set(j2))
    out: set[int] = set()
    for shift1, shift2 in ((1, 2), (2, 1)):
        for u1 in T1:
            r1 = (u1 - shift1 * L) % m1
            for u2 in T2:
                r2 = (u2 - shift2 * L) % m2
                if (r1 - r2) % math.gcd(m1, m2) != 0:
                    continue
                r = crt_pair(r1, m1, r2, m2)
                if r is not None:
                    out.add(r)
    return sorted(out)


def scan_q3_complete(Ls: list[int]) -> dict:
    """Exact complementary-cover search on every q=3 pair for each L."""
    cache: dict[int, set[int]] = {}
    checked = 0
    fails: list[dict] = []
    complementary = 0
    pairs = 0
    empty_S = 0
    for L in Ls:
        js = layers_with_q(L, 3)
        for i, j1 in enumerate(js):
            for j2 in js[i + 1 :]:
                pairs += 1
                for r in complementary_r_candidates(L, j1, j2, cache):
                    row = classify_pair(r, L, j1, j2, cache)
                    checked += 1
                    if row["c1_fail"]:
                        empty_S += 1
                    if not row["ok"]:
                        fails.append(row)
                        if row["q1"] == 3 and row["q2"] == 3:
                            complementary += 1
    return {
        "pairs": pairs,
        "checked": checked,
        "fails": len(fails),
        "complementary": complementary,
        "c1_empty_S": empty_S,
        "fail_examples": fails[:20],
        "q3_layers": {str(L): layers_with_q(L, 3) for L in Ls},
    }


def scan_program_L(k_limit: int, r_hard: tuple[int, ...]) -> dict:
    """L = lcm(840, 4k-1), j < k, hard residues r."""
    cache: dict[int, set[int]] = {}
    counts = collections.Counter()
    fails: list[dict] = []
    q_hist = collections.Counter()
    nact_q_sets: list[dict] = []
    checked = 0
    q3_comp = 0
    max_cluster = 0
    for k in range(2, k_limit + 1):
        L = math.lcm(840, 4 * k - 1)
        js_q = [(j, (4 * j - 1) // math.gcd(L, 4 * j - 1)) for j in range(1, k)]
        active = [(j, q) for j, q in js_q if q > 1]
        qs = [q for _, q in active]
        for q in qs:
            q_hist[q] += 1
        max_cluster = max(max_cluster, len(active))
        # Pairwise among active j, for each hard r.
        for i, (j1, _) in enumerate(active):
            for j2, _ in active[i + 1 :]:
                for r in r_hard:
                    row = classify_pair(r, L, j1, j2, cache)
                    checked += 1
                    counts[row["kind"]] += 1
                    if not row["ok"]:
                        fails.append(row)
                    if row["q1"] == 3 and row["q2"] == 3 and not row["ok"]:
                        q3_comp += 1
        if k <= min(k_limit, 80):
            nact_q_sets.append(
                {"k": k, "n_qgt1": len(active), "qs": sorted({q for _, q in active})[:30]}
            )
    return {
        "k_limit": k_limit,
        "checked": checked,
        "kinds": dict(counts),
        "fails": len(fails),
        "q3_complementary": q3_comp,
        "max_qgt1_cluster": max_cluster,
        "top_q": q_hist.most_common(20),
        "fail_examples": fails[:20],
        "sample_q_sets": nact_q_sets[:15],
    }


def scan_triples(Ls: list[int], j_limit: int, r_samples: list[int]) -> dict:
    cache: dict[int, set[int]] = {}
    checked = 0
    fails: list[dict] = []
    c1 = 0
    for L in Ls:
        js = [j for j, q in all_positive_q_layers(L, j_limit)]
        for i, j1 in enumerate(js):
            for i2, j2 in enumerate(js[i + 1 :], start=i + 1):
                for j3 in js[i2 + 1 :]:
                    for r in r_samples:
                        rows = [
                            classify_pair(r, L, j1, j2, cache),
                            classify_pair(r, L, j1, j3, cache),
                            classify_pair(r, L, j2, j3, cache),
                        ]
                        cons = []
                        c1_fail = False
                        for j in (j1, j2, j3):
                            _, q, R = pullback(r, L, j, cache.setdefault(j, trap_set(j)))
                            if q > 1:
                                if not safe_units(q, R):
                                    c1_fail = True
                                cons.append((q, R))
                        ok = (not c1_fail) and simultaneous_escape(cons)
                        checked += 1
                        if c1_fail:
                            c1 += 1
                        if not ok:
                            fails.append(
                                {
                                    "L": L,
                                    "r": r,
                                    "js": [j1, j2, j3],
                                    "qs": [c[0] for c in cons],
                                    "c1_fail": c1_fail,
                                    "pair_kinds": [row["kind"] for row in rows],
                                }
                            )
    return {
        "checked": checked,
        "fails": len(fails),
        "c1_fails": c1,
        "fail_examples": fails[:20],
    }


def scan_quads(Ls: list[int], j_limit: int, r_samples: list[int]) -> dict:
    cache: dict[int, set[int]] = {}
    checked = 0
    fails: list[dict] = []
    for L in Ls:
        js = [j for j, q in all_positive_q_layers(L, j_limit)]
        n = len(js)
        for a in range(n):
            for b in range(a + 1, n):
                for c in range(b + 1, n):
                    for d in range(c + 1, n):
                        quad = (js[a], js[b], js[c], js[d])
                        for r in r_samples:
                            cons = []
                            c1_fail = False
                            for j in quad:
                                _, q, R = pullback(
                                    r, L, j, cache.setdefault(j, trap_set(j))
                                )
                                if q > 1:
                                    if not safe_units(q, R):
                                        c1_fail = True
                                    cons.append((q, R))
                            ok = (not c1_fail) and simultaneous_escape(cons)
                            checked += 1
                            if not ok:
                                fails.append(
                                    {
                                        "L": L,
                                        "r": r,
                                        "js": list(quad),
                                        "qs": [x[0] for x in cons],
                                        "c1_fail": c1_fail,
                                    }
                                )
    return {"checked": checked, "fails": len(fails), "fail_examples": fails[:20]}


def hunt_q3_any_L(j_limit: int, L_multiples: int = 8) -> dict:
    """Search complementary q=3 covers over constructed L that activate both layers."""
    cache: dict[int, set[int]] = {}
    hits: list[dict] = []
    checked = 0
    candidates = [j for j in range(1, j_limit + 1) if (4 * j - 1) % 3 == 0]
    for i, j1 in enumerate(candidates):
        for j2 in candidates[i + 1 :]:
            m1, m2 = 4 * j1 - 1, 4 * j2 - 1
            g1, g2 = m1 // 3, m2 // 3
            L0 = math.lcm(g1, g2)
            for t in range(1, L_multiples + 1):
                if t % 3 == 0:
                    continue
                L = L0 * t
                if math.gcd(L, m1) != g1 or math.gcd(L, m2) != g2:
                    continue
                for r in complementary_r_candidates(L, j1, j2, cache):
                    checked += 1
                    row = classify_pair(r, L, j1, j2, cache)
                    if not row["ok"] and row["q1"] == 3 and row["q2"] == 3:
                        hits.append(row)
                        if len(hits) >= 20:
                            return {
                                "checked": checked,
                                "hits": len(hits),
                                "examples": hits[:20],
                            }
    return {"checked": checked, "hits": len(hits), "examples": hits[:20]}


def crt_hard_trap(h: int, t: int, m: int) -> int:
    """CRT: r ≡ h (mod 840), r ≡ t (mod m). Requires t ≡ h (mod gcd(840,m))."""
    d = math.gcd(840, m)
    if (t - h) % d != 0:
        raise ValueError("incompatible hard/trap pair")
    return crt_pair(h, 840, t, m)


def admissible_candidates(k: int) -> list[tuple[int, int, int, int]]:
    """Yield (h, t, r, L) for hard-compatible traps at depth k."""
    m = 4 * k - 1
    L = math.lcm(840, m)
    out: list[tuple[int, int, int, int]] = []
    T = trap_set(k)
    g = math.gcd(840, m)
    for h in HARD:
        for t in T:
            if (t - h) % g == 0:
                r = crt_hard_trap(h, t, m)
                out.append((h, t, r, L))
    return out


def shared_factor_pairs(active: list[tuple[int, int]]) -> list[tuple[int, int]]:
    """Pairs of earlier layers whose pullback moduli share a prime."""
    by_p: dict[int, list[int]] = {}
    for j, q in active:
        for p in prime_divisors(q):
            by_p.setdefault(p, []).append(j)
    pairs: set[tuple[int, int]] = set()
    for js in by_p.values():
        uniq = sorted(set(js))
        for i, j1 in enumerate(uniq):
            for j2 in uniq[i + 1 :]:
                pairs.add((j1, j2))
    return sorted(pairs)


def scan_admissible_program(k_limit: int, pair_j_cap: int | None = None) -> dict:
    """C2/CN on actual Type A/B candidates: r = CRT(h, t), L = lcm(840, 4k-1).

    Coprime pairs are already proved (C2-coprime).  This scan therefore
    checks only shared-factor pairs, plus tight q<=9 triples.
    """
    del pair_j_cap  # retained for call-site compatibility
    cache: dict[int, set[int]] = {}
    pair_checked = 0
    pair_fails: list[dict] = []
    c1_fails = 0
    kinds = collections.Counter()
    n_cand = 0
    q3_comp = 0
    max_active = 0
    max_shared_pairs = 0
    triple_checked = 0
    triple_fails = 0
    for k in range(2, k_limit + 1):
        cands = admissible_candidates(k)
        n_cand += len(cands)
        L = math.lcm(840, 4 * k - 1)
        active_j = []
        for j in range(1, k):
            q = (4 * j - 1) // math.gcd(L, 4 * j - 1)
            if q > 1:
                active_j.append((j, q))
        max_active = max(max_active, len(active_j))
        pairs_all = shared_factor_pairs(active_j)
        qmap = {j: q for j, q in active_j}
        pairs = []
        for j1, j2 in pairs_all:
            q1, q2 = qmap[j1], qmap[j2]
            d = math.gcd(q1, q2)
            tau1 = 2 * len(divisors(j1))
            tau2 = 2 * len(divisors(j2))
            # Uniform lift-room: |R| <= |T| <= 2 tau(j), independent of r.
            if d > 1 and (
                tau1 < totient_ratio(q1, d) or tau2 < totient_ratio(q2, d)
            ):
                kinds["uniform-lift-room"] += len(cands)
                continue
            # Uniform same-q pigeonhole: |R1 ∪ R2| <= 2τ(j1)+2τ(j2) < φ(q).
            if q1 == q2 and tau1 + tau2 < phi(q1):
                kinds["uniform-same-q"] += len(cands)
                continue
            pairs.append((j1, j2))
        max_shared_pairs = max(max_shared_pairs, len(pairs))
        tight_j = [j for j, q in active_j if q <= 9]
        for h, t, r, _L in cands:
            for j1, j2 in pairs:
                row = classify_pair(r, L, j1, j2, cache)
                pair_checked += 1
                kinds[row["kind"]] += 1
                if row["c1_fail"]:
                    c1_fails += 1
                if not row["ok"]:
                    pair_fails.append(
                        {
                            "k": k,
                            "h": h,
                            "t": t,
                            "r": r,
                            **{
                                kk: row[kk]
                                for kk in ("j1", "j2", "q1", "q2", "R1", "R2", "kind")
                            },
                        }
                    )
                if row["q1"] == 3 and row["q2"] == 3 and not row["ok"]:
                    q3_comp += 1
            if len(tight_j) >= 3:
                for a in range(len(tight_j)):
                    for b in range(a + 1, len(tight_j)):
                        for c in range(b + 1, len(tight_j)):
                            cons = []
                            c1 = False
                            for j in (tight_j[a], tight_j[b], tight_j[c]):
                                _, q, R = pullback(
                                    r, L, j, cache.setdefault(j, trap_set(j))
                                )
                                if q > 1:
                                    if not c1_escape(q, R):
                                        c1 = True
                                    cons.append((q, R))
                            triple_checked += 1
                            if c1 or not simultaneous_escape(cons):
                                triple_fails += 1
    return {
        "k_limit": k_limit,
        "candidates": n_cand,
        "pair_checked": pair_checked,
        "pair_fails": len(pair_fails),
        "pair_fail_examples": pair_fails[:20],
        "c1_fails": c1_fails,
        "kinds": dict(kinds),
        "q3_complementary": q3_comp,
        "max_active": max_active,
        "max_shared_pairs": max_shared_pairs,
        "triple_tight_checked": triple_checked,
        "triple_tight_fails": triple_fails,
    }


def scan_admissible_tight(k_limit: int) -> dict:
    """All hard-admissible candidates; only q<=9 shared pairs and triples."""
    cache: dict[int, set[int]] = {}
    pair_ok = pair_fail = c1 = 0
    kinds: collections.Counter[str] = collections.Counter()
    fails: list[dict] = []
    triple_ok = triple_fail = 0
    n_cand = 0
    for k in range(2, k_limit + 1):
        cands = admissible_candidates(k)
        n_cand += len(cands)
        L = math.lcm(840, 4 * k - 1)
        active: list[tuple[int, int]] = []
        for j in range(1, k):
            q = (4 * j - 1) // math.gcd(L, 4 * j - 1)
            if 1 < q <= 9:
                active.append((j, q))
        pairs = shared_factor_pairs(active)
        js = [j for j, _ in active]
        for h, t, r, _L in cands:
            for j1, j2 in pairs:
                row = classify_pair(r, L, j1, j2, cache)
                kinds[row["kind"]] += 1
                if row["c1_fail"]:
                    c1 += 1
                if row["ok"]:
                    pair_ok += 1
                else:
                    pair_fail += 1
                    fails.append(
                        {
                            "k": k,
                            "h": h,
                            "t": t,
                            "r": r,
                            "j1": j1,
                            "j2": j2,
                            "q1": row["q1"],
                            "q2": row["q2"],
                            "R1": row["R1"],
                            "R2": row["R2"],
                        }
                    )
            if 3 <= len(js) <= 12:
                for a in range(len(js)):
                    for b in range(a + 1, len(js)):
                        for c in range(b + 1, len(js)):
                            cons = []
                            bad = False
                            for j in (js[a], js[b], js[c]):
                                _, q, R = pullback(
                                    r, L, j, cache.setdefault(j, trap_set(j))
                                )
                                if q > 1:
                                    if not c1_escape(q, R):
                                        bad = True
                                    cons.append((q, R))
                            if bad or not simultaneous_escape(cons):
                                triple_fail += 1
                            else:
                                triple_ok += 1
    novel_fails = []
    for f in fails:
        L = math.lcm(840, 4 * f["k"] - 1)
        g, q, R = pullback(f["r"], L, 10, cache.setdefault(10, trap_set(10)))
        shadowed = q == 1 and any((u - f["r"]) % g == 0 for u in cache[10])
        if not shadowed:
            novel_fails.append(f)
    return {
        "k_limit": k_limit,
        "candidates": n_cand,
        "pair_ok": pair_ok,
        "pair_fail": pair_fail,
        "c1_fails": c1,
        "kinds": dict(kinds),
        "fail_pairs": [((f["j1"], f["j2"])) for f in fails],
        "fail_pair_counts": {
            f"{a},{b}": c
            for (a, b), c in collections.Counter((f["j1"], f["j2"]) for f in fails).items()
        },
        "fails": fails,
        "novel_fails": novel_fails,
        "triple_ok": triple_ok,
        "triple_fail": triple_fail,
    }


def ratio_lemma_check(q_limit: int) -> dict:
    fails = []
    checked = 0
    min_ratio = None
    for q in range(3, q_limit + 1, 2):
        for d in divisors(q):
            if d == q or d == 0:
                continue
            checked += 1
            ratio = totient_ratio(q, d)
            if min_ratio is None or ratio < min_ratio:
                min_ratio = ratio
            if ratio < 2:
                fails.append({"q": q, "d": d, "ratio": ratio})
    return {"checked": checked, "fails": fails, "min_ratio": min_ratio}


HARD = (1, 121, 169, 289, 361, 529)
STANDARD_L = (840, 2520, 5040, 55440, 720720)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path("cn-shared-output"))
    ap.add_argument("--j-limit", type=int, default=160)
    ap.add_argument("--triple-j-limit", type=int, default=60)
    ap.add_argument("--quad-j-limit", type=int, default=32)
    ap.add_argument("--k-limit", type=int, default=1500)
    ap.add_argument("--program-k-limit", type=int, default=200)
    ap.add_argument("--q3-j-limit", type=int, default=80)
    ap.add_argument("--skip-triples", action="store_true", default=True)
    ap.add_argument("--skip-quads", action="store_true", default=True)
    ap.add_argument("--skip-q3-hunt", action="store_true", default=True)
    ap.add_argument("--run-unrestricted", action="store_true")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    r_samples = list(HARD) + [0, 1, 2, 3, 4, 5, 7, 8, 11, 13, 16, 17, 25, 32, 64]

    print("stage: ratio lemma", flush=True)
    report: dict = {
        "claim_boundary": (
            "Finite certificates plus exact lift-room / totient-ratio lemmas. "
            "Does not prove Erdős-Straus, López-all-primes, or unconstrained DSC-P."
        ),
        "ratio_lemma": ratio_lemma_check(5000),
    }
    print("stage: standard pairs", flush=True)
    report["standard_pairs"] = scan_standard_pairs(list(STANDARD_L[:4]), args.j_limit, r_samples)
    print("stage: q3 complete", flush=True)
    report["q3_complete"] = scan_q3_complete(list(STANDARD_L))
    print("stage: program L (hard r, all active pairs)", flush=True)
    report["program_L"] = scan_program_L(args.program_k_limit, HARD)
    print("stage: admissible tight q<=9", flush=True)
    report["admissible_tight"] = scan_admissible_tight(args.k_limit)
    if args.run_unrestricted:
        args.skip_q3_hunt = False
        args.skip_triples = False
        args.skip_quads = False
    if not args.skip_q3_hunt:
        print("stage: q3 hunt", flush=True)
        report["q3_hunt"] = hunt_q3_any_L(args.q3_j_limit, L_multiples=8)
    if not args.skip_triples:
        print("stage: triples", flush=True)
        report["triples"] = scan_triples(list(STANDARD_L[:3]), args.triple_j_limit, list(HARD) + [1, 2, 16])
    if not args.skip_quads:
        print("stage: quads", flush=True)
        report["quads"] = scan_quads(list(STANDARD_L[:2]), args.quad_j_limit, list(HARD)[:3] + [1])

    out_json = args.out / "cn-shared.json"
    out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")

    lines = [
        "# CN-shared analyzer report",
        "",
        f"- ratio-lemma checks: {report['ratio_lemma']['checked']}, fails={len(report['ratio_lemma']['fails'])}, min_ratio={report['ratio_lemma']['min_ratio']}",
        f"- standard pairs checked: {report['standard_pairs']['checked']}, fails={report['standard_pairs']['fails']}, c1={report['standard_pairs']['c1_fails']}, kinds={report['standard_pairs']['kinds']}",
        f"- q3 complete: pairs={report['q3_complete']['pairs']}, checked={report['q3_complete']['checked']}, fails={report['q3_complete']['fails']}, complementary={report['q3_complete']['complementary']}",
        f"- program L k<={report['program_L']['k_limit']}: checked={report['program_L']['checked']}, fails={report['program_L']['fails']}, q3_comp={report['program_L']['q3_complementary']}, max_cluster={report['program_L']['max_qgt1_cluster']}",
        f"- admissible tight k<={report['admissible_tight']['k_limit']}: cands={report['admissible_tight']['candidates']}, pair_ok={report['admissible_tight']['pair_ok']}, pair_fail={report['admissible_tight']['pair_fail']}, novel_fails={len(report['admissible_tight']['novel_fails'])}, triples_ok={report['admissible_tight']['triple_ok']}, triple_fail={report['admissible_tight']['triple_fail']}",
    ]
    if "q3_hunt" in report:
        lines.append(
            f"- q3 hunt: checked={report['q3_hunt']['checked']}, hits={report['q3_hunt']['hits']}"
        )
    if "triples" in report:
        lines.append(
            f"- triples: checked={report['triples']['checked']}, fails={report['triples']['fails']}"
        )
    if "quads" in report:
        lines.append(
            f"- quads: checked={report['quads']['checked']}, fails={report['quads']['fails']}"
        )
    lines.append("")
    lines.append("q=3 layers by L:")
    for L, js in report["q3_complete"]["q3_layers"].items():
        lines.append(f"  L={L}: {js}")
    lines.append("")
    (args.out / "cn-shared-report.md").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
