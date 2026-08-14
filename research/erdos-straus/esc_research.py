#!/usr/bin/env python3
"""Reproducible Type A/B depth and shadow analysis for WS-CAND-003.

This program deliberately separates discovery from CENTL algebraic certification.
It generates exact finite combinatorial certificates that are independently
rechecked by verify_research.py.  centl_certify.py then asks the repository's
CENTL binary to verify the resulting Egyptian-fraction and polynomial-family
identities exactly.

No output of this program is a proof of the Erdos-Straus conjecture or of
novelty/priority in the literature.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter, defaultdict
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)
ROOT = Path(__file__).resolve().parents[2]
EXPECTED_FRONTIER = Path(__file__).with_name("expected-frontier.json")


def divisors(n: int) -> list[int]:
    lo, hi = [], []
    for d in range(1, math.isqrt(n) + 1):
        if n % d == 0:
            lo.append(d)
            if d * d != n:
                hi.append(n // d)
    return lo + hi[::-1]


def tau(n: int) -> int:
    return len(divisors(n))


def trap_count_formula(k: int) -> int:
    out = 2 * tau(k) - 1
    if k % 4 == 0:
        out -= tau(k // 4)
    return out


def prime_sieve(limit: int) -> list[int]:
    flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        flags[0] = 0
    if limit >= 1:
        flags[1] = 0
    for p in range(2, math.isqrt(limit) + 1):
        if flags[p]:
            start = p * p
            count = ((limit - start) // p) + 1
            flags[start : limit + 1 : p] = b"\x00" * count
    return [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]


def witnesses_at(p: int, k: int, ds: list[int] | None = None) -> list[dict]:
    if ds is None:
        ds = divisors(k)
    m = 4 * k - 1
    found = []

    for d in ds:
        n = k // d
        num = p + 4 * d
        if num % m == 0:
            q = num // m
            if q > 0:
                found.append({"type": "A", "d": d, "n": n, "k": k, "m": m, "q": q})

    for n in ds:
        d = k // n
        num = p + n
        if num % m == 0:
            q = num // m
            if q > 0:
                found.append({"type": "B", "d": d, "n": n, "k": k, "m": m, "q": q})

    found.sort(key=lambda w: (w["type"], w["d"] + w["n"], w["d"], w["n"], w["q"]))
    return found


def scan_first_hits(primes: list[int], k_max: int, divs: list[list[int]], traps: list[set[int]]) -> tuple[dict[int, dict], list[dict]]:
    unresolved = set(primes)
    first: dict[int, dict] = {}
    hazard = []

    for k in range(1, k_max + 1):
        if not unresolved:
            break
        m = 4 * k - 1
        before = len(unresolved)
        solved = []
        for p in unresolved:
            if p % m not in traps[k]:
                continue
            hits = witnesses_at(p, k, divs[k])
            if hits:
                first[p] = hits[0]
                solved.append(p)
        for p in solved:
            unresolved.remove(p)
        hazard.append({"k": k, "m": m, "before": before, "new": len(solved), "remaining": len(unresolved)})

    return first, hazard


def record_frontier(first: dict[int, dict]) -> list[dict]:
    out = []
    record = -1
    for p in sorted(first):
        w = first[p]
        if w["k"] > record:
            record = w["k"]
            out.append({
                "p": p,
                "r840": p % 840,
                "C_AB": w["k"],
                "type": w["type"],
                "d": w["d"],
                "n": w["n"],
                "m": w["m"],
                "q": w["q"],
            })
    return out


def crt2(a: int, m: int, b: int, n: int) -> tuple[int, int] | None:
    g = math.gcd(m, n)
    if (b - a) % g:
        return None
    mm, nn = m // g, n // g
    if nn == 1:
        t = 0
    else:
        t = (((b - a) // g) * pow(mm, -1, nn)) % nn
    L = m * nn
    return (a + m * t) % L, L


def admissible_pairs(k: int, mod: list[int], traps: list[set[int]]) -> set[tuple[int, int]]:
    m = mod[k]
    g = math.gcd(840, m)
    out = set()
    for h in HARD:
        for t in traps[k]:
            if math.gcd(t, m) != 1:
                continue
            if t % g != h % g:
                continue
            out.add((h, t))
    return out


def analyse_shadow(k: int, mod: list[int], traps: list[set[int]]) -> dict:
    pairs = admissible_pairs(k, mod, traps)
    if not pairs:
        return {"k": k, "m": mod[k], "pairs": 0, "shadowed": {}, "novel_pairs": []}

    mk = mod[k]
    L = math.lcm(840, mk)
    tests = []

    for j in range(1, k):
        mj = mod[j]
        g = math.gcd(L, mj)
        fibre_size = mj // g
        if fibre_size > len(traps[j]):
            continue
        counts = Counter(r % g for r in traps[j])
        full_bases = {base for base, count in counts.items() if count == fibre_size}
        if full_bases:
            tests.append((j, g, full_bases))

    shadowed: dict[tuple[int, int], list[int]] = {}
    novel = []
    for h, t in sorted(pairs):
        cr = crt2(h, 840, t, mk)
        if cr is None:
            raise RuntimeError(f"unexpected incompatible admissible pair k={k} h={h} t={t}")
        r, _ = cr
        sources = [j for j, g, bases in tests if r % g in bases]
        if sources:
            shadowed[(h, t)] = sources
        else:
            novel.append((h, t))

    return {"k": k, "m": mk, "pairs": len(pairs), "shadowed": shadowed, "novel_pairs": novel}


def shadow_certificate(k: int, h: int, t: int, j: int, mod: list[int]) -> dict:
    mk, mj = mod[k], mod[j]
    cr = crt2(h, 840, t, mk)
    if cr is None:
        raise RuntimeError("cannot certify incompatible CRT pair")
    r, L = cr
    g = math.gcd(L, mj)
    return {
        "k": k,
        "h": h,
        "t": t,
        "m_k": mk,
        "source_j": j,
        "m_j": mj,
        "crt_r": r,
        "crt_modulus": L,
        "fibre_gcd": g,
        "fibre_base": r % g,
        "fibre_size": mj // g,
    }


def ancestry_reports(shadows: dict[int, dict], mod: list[int]) -> tuple[list[dict], list[dict], dict]:
    edge_counts = Counter()
    for k, a in shadows.items():
        for sources in a["shadowed"].values():
            for j in sources:
                edge_counts[(j, k)] += 1

    edges = []
    quotient_counts = Counter()
    for (j, k), count in sorted(edge_counts.items()):
        mj, mk = mod[j], mod[k]
        divides = mk % mj == 0
        q = mk // mj if divides else None
        s = None
        identity_ok = False
        if divides:
            if q % 4 != 1:
                raise RuntimeError(f"unexpected ancestry quotient {q} for j={j}, k={k}")
            s = (q - 1) // 4
            identity_ok = k == q * j - s
            if not identity_ok:
                raise RuntimeError(f"ancestry identity failed for j={j}, k={k}, q={q}")
            quotient_counts[q] += count
        edges.append({
            "j": j,
            "k": k,
            "m_j": mj,
            "m_k": mk,
            "shadowed_class_relations": count,
            "modulus_divides": divides,
            "quotient": q,
            "s": s,
            "k_equals_qj_minus_s": identity_ok,
        })

    uniform = []
    family_points: dict[int, list[dict]] = defaultdict(list)
    for k, a in shadows.items():
        if not a["shadowed"] or a["novel_pairs"]:
            continue
        source_sets = [set(xs) for xs in a["shadowed"].values()]
        common = set.intersection(*source_sets) if source_sets else set()
        for j in sorted(common):
            if mod[k] % mod[j] != 0:
                continue
            q = mod[k] // mod[j]
            if q % 4 != 1:
                continue
            s = (q - 1) // 4
            point = {"j": j, "k": k, "quotient": q, "s": s, "m_j": mod[j], "m_k": mod[k]}
            uniform.append(point)
            family_points[q].append(point)

    families = []
    for q, points in sorted(family_points.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        families.append({
            "quotient": q,
            "s": (q - 1) // 4,
            "observed_uniform_full_shadow_points": points,
            "count": len(points),
            "status": "candidate pattern, not an infinite-family theorem",
        })

    stats = {
        "unique_layer_edges": len(edges),
        "shadowed_class_source_relations": sum(edge_counts.values()),
        "divisible_edge_count": sum(1 for e in edges if e["modulus_divides"]),
        "nondivisible_edge_count": sum(1 for e in edges if not e["modulus_divides"]),
        "quotient_relation_counts": {str(q): c for q, c in sorted(quotient_counts.items())},
    }
    return edges, families, stats


def witnessed_global_novelty(first: dict[int, dict], mod: list[int]) -> list[dict]:
    grouped: dict[tuple[int, int, int], list[int]] = defaultdict(list)
    for p, w in first.items():
        k = w["k"]
        grouped[(k, p % 840, p % mod[k])].append(p)
    out = []
    for (k, h, t), ps in sorted(grouped.items()):
        out.append({
            "k": k,
            "m_k": mod[k],
            "h": h,
            "t": t,
            "witness_primes": sorted(ps),
            "meaning": "each listed first-hit prime is an explicit counterexample to union-shadowing of this class by all earlier layers",
        })
    return out


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, indent=2, sort_keys=True) + "\n")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=10_000_000)
    ap.add_argument("--k-max", type=int, default=3000)
    ap.add_argument("--out", type=Path, default=Path("research-output"))
    args = ap.parse_args()

    if args.limit < 1000 or args.k_max < 3:
        raise SystemExit("limit and k-max are too small for the research contract")

    out = args.out
    out.mkdir(parents=True, exist_ok=True)

    print(f"[1/8] precomputing Type A/B layers through k={args.k_max}", flush=True)
    mod = [0] * (args.k_max + 1)
    divs: list[list[int]] = [[] for _ in range(args.k_max + 1)]
    traps: list[set[int]] = [set() for _ in range(args.k_max + 1)]
    cardinality_checks = []
    for k in range(1, args.k_max + 1):
        mod[k] = 4 * k - 1
        divs[k] = divisors(k)
        traps[k] = {r for d in divs[k] for r in ((-d) % mod[k], (-4 * d) % mod[k])}
        expected = trap_count_formula(k)
        if len(traps[k]) != expected:
            raise RuntimeError(f"trap cardinality theorem failed at k={k}: {len(traps[k])} != {expected}")
        cardinality_checks.append({"k": k, "observed": len(traps[k]), "formula": expected})

    print(f"[2/8] sieving hard primes through {args.limit}", flush=True)
    primes = prime_sieve(args.limit)
    first, hazard = scan_first_hits(primes, args.k_max, divs, traps)
    unresolved = sorted(set(primes) - set(first))
    frontier = record_frontier(first)

    expected = json.loads(EXPECTED_FRONTIER.read_text())
    if args.limit >= 10_000_000 and args.k_max >= 2622:
        got_pc = [(x["p"], x["C_AB"]) for x in frontier if x["p"] <= 10_000_000]
        exp_pc = [(x["p"], x["C_AB"]) for x in expected]
        if got_pc != exp_pc:
            raise RuntimeError(f"frontier regression: got {got_pc}, expected {exp_pc}")
        for x in expected:
            hits = witnesses_at(x["p"], x["C_AB"], divs[x["C_AB"]])
            expected_witness = (x["type"], x["d"], x["n"], x["q"])
            available = {(w["type"], w["d"], w["n"], w["q"]) for w in hits}
            if expected_witness not in available:
                raise RuntimeError(f"frontier witness regression for p={x['p']}")

    write_json(out / "frontier.json", frontier)
    write_json(out / "hazard.json", hazard)
    write_json(out / "trap-cardinality-checks.json", cardinality_checks)

    print("[3/8] computing exact direct-shadow map", flush=True)
    shadows: dict[int, dict] = {}
    layer_summary = []
    cert_path = out / "direct-shadow-certificates.jsonl"
    with cert_path.open("w") as certs:
        for k in range(1, args.k_max + 1):
            a = analyse_shadow(k, mod, traps)
            shadows[k] = a
            layer_summary.append({
                "k": k,
                "m": mod[k],
                "admissible_classes": a["pairs"],
                "direct_shadowed_classes": len(a["shadowed"]),
                "direct_novel_classes": len(a["novel_pairs"]),
                "direct_novelty_fraction": (len(a["novel_pairs"]) / a["pairs"]) if a["pairs"] else 0.0,
            })
            if a["pairs"] and not a["novel_pairs"]:
                for (h, t), sources in sorted(a["shadowed"].items()):
                    cert = shadow_certificate(k, h, t, min(sources), mod)
                    cert["all_direct_sources"] = sources
                    certs.write(json.dumps(cert, sort_keys=True) + "\n")
            if k % 250 == 0:
                print(f"  shadow progress k={k}", flush=True)

    fully_shadowed = [r for r in layer_summary if r["admissible_classes"] and r["direct_novel_classes"] == 0]
    completely_fresh = [r for r in layer_summary if r["admissible_classes"] and r["direct_shadowed_classes"] == 0]
    partial = [r for r in layer_summary if r["direct_shadowed_classes"] and r["direct_novel_classes"]]
    write_json(out / "shadow-layer-summary.json", {
        "k_max": args.k_max,
        "fully_shadowed": fully_shadowed,
        "completely_fresh": completely_fresh,
        "partial": partial,
        "layers": layer_summary,
    })

    print("[4/8] classifying shadow ancestry", flush=True)
    edges, families, ancestry_stats = ancestry_reports(shadows, mod)
    write_json(out / "ancestry-edges.json", edges)
    write_json(out / "ancestry-candidate-families.json", families)
    write_json(out / "ancestry-summary.json", ancestry_stats)

    print("[5/8] certifying witnessed non-union-shadow classes", flush=True)
    global_novel = witnessed_global_novelty(first, mod)
    write_json(out / "witnessed-global-novelty.json", global_novel)

    print("[6/8] writing finite research summary", flush=True)
    report = [
        "# Automated Erdős-Straus Type A/B research run",
        "",
        f"- hard-prime limit: `{args.limit}`",
        f"- layer limit: `{args.k_max}`",
        f"- selected hard primes: `{len(primes)}`",
        f"- resolved Type A/B first hits: `{len(first)}`",
        f"- unresolved: `{len(unresolved)}`",
        f"- frontier records: `{len(frontier)}`",
        f"- fully direct-shadowed layers: `{len(fully_shadowed)}`",
        f"- completely direct-fresh layers: `{len(completely_fresh)}`",
        f"- partially direct-shadowed layers: `{len(partial)}`",
        f"- unique direct-shadow layer edges: `{ancestry_stats['unique_layer_edges']}`",
        f"- modulus-divisibility ancestry edges: `{ancestry_stats['divisible_edge_count']}`",
        f"- non-divisibility shadow edges: `{ancestry_stats['nondivisible_edge_count']}`",
        f"- witnessed globally non-union-shadowed classes: `{len(global_novel)}`",
        "",
        "## Frontier",
        "",
        "| p | C_AB | type | d | n | m | q |",
        "|---:|---:|:---:|---:|---:|---:|---:|",
    ]
    for x in frontier:
        report.append(f"| {x['p']} | {x['C_AB']} | {x['type']} | {x['d']} | {x['n']} | {x['m']} | {x['q']} |")
    report += [
        "",
        "## Interpretation discipline",
        "",
        "Direct freshness means that no single earlier layer covers the whole admissible CRT class. It does not by itself exclude collective union-shadowing by multiple earlier layers. A first-hit prime is stronger: it is an explicit witness that its current CRT class is not covered by the union of all earlier Type A/B traps.",
        "",
        "The ancestry family file groups observed finite patterns. It does not promote them to infinite-family theorems.",
    ]
    (out / "report.md").write_text("\n".join(report) + "\n")

    print("[7/8] writing machine-readable run metadata", flush=True)
    metadata = {
        "schema": 1,
        "problem": "Erdos-Straus Lopez Type A/B witness-depth and shadow structure",
        "limit": args.limit,
        "k_max": args.k_max,
        "hard_classes_mod_840": HARD,
        "hard_prime_count": len(primes),
        "resolved_count": len(first),
        "unresolved": unresolved,
        "max_C_AB_observed": max((w["k"] for w in first.values()), default=None),
        "frontier_record_count": len(frontier),
        "scientific_status": "WS-CAND-003 Wellspring Candidate; no claim of Erdos-Straus proof or established novelty priority",
    }
    write_json(out / "run-metadata.json", metadata)

    print("[8/8] hashing outputs", flush=True)
    files = sorted(p for p in out.iterdir() if p.is_file() and p.name != "SHA256SUMS")
    manifest = "".join(f"{sha256(p)}  {p.name}\n" for p in files)
    (out / "SHA256SUMS").write_text(manifest)

    print("DONE", flush=True)
    print(json.dumps(metadata, indent=2), flush=True)


if __name__ == "__main__":
    main()
