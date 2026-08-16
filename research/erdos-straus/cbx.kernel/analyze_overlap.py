#!/usr/bin/env python3
"""Build exact finite containment/overlap relations among standalone Lane-I hit sets."""
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path
from typing import Any


def load_relations(path: Path) -> tuple[list[int], dict[int, set[int]], int]:
    layers: dict[int, set[int]] = collections.defaultdict(set)
    relations = 0
    with path.open("r", encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            raw = raw.strip()
            if not raw:
                continue
            parts = raw.split("\t")
            if len(parts) != 2:
                raise SystemExit(f"{path}:{lineno}: expected k<TAB>p")
            try:
                k, p = map(int, parts)
            except ValueError as exc:
                raise SystemExit(f"{path}:{lineno}: invalid integer") from exc
            if k < 3 or k % 4 != 3 or p < 2:
                raise SystemExit(f"{path}:{lineno}: invalid relation k={k} p={p}")
            before = len(layers[k])
            layers[k].add(p)
            if len(layers[k]) == before:
                raise SystemExit(f"{path}:{lineno}: duplicate relation k={k} p={p}")
            relations += 1
    if not layers:
        raise SystemExit(f"no hit relations: {path}")
    ks = sorted(layers)
    expected = list(range(ks[0], ks[-1] + 1, 4))
    if ks != expected:
        missing = sorted(set(expected) - set(ks))
        raise SystemExit(f"missing standalone layers in relation file: {missing[:20]}")
    return ks, dict(layers), relations


def make_masks(ks: list[int], sets: dict[int, set[int]]) -> tuple[dict[int, int], int]:
    universe = sorted({p for k in ks for p in sets[k]})
    index = {p: i for i, p in enumerate(universe)}
    nbytes = (len(universe) + 7) // 8
    masks: dict[int, int] = {}
    for k in ks:
        buf = bytearray(nbytes)
        for p in sets[k]:
            i = index[p]
            buf[i >> 3] |= 1 << (i & 7)
        masks[k] = int.from_bytes(buf, "little")
    return masks, len(universe)


def frac(a: int, b: int) -> float | None:
    return a / b if b else None


def analyze(ks: list[int], sets: dict[int, set[int]], relations: int,
            top: int, pair_limit: int) -> dict[str, Any]:
    masks, universe_hits = make_masks(ks, sets)
    sizes = {k: len(sets[k]) for k in ks}

    union = 0
    novelty_rows: list[dict[str, Any]] = []
    first_hit_total = 0
    for k in ks:
        m = masks[k]
        novel = m & ~union
        novel_count = novel.bit_count()
        prior_overlap = (m & union).bit_count()
        first_hit_total += novel_count
        novelty_rows.append({
            "k": k,
            "hits": sizes[k],
            "novel_hits": novel_count,
            "overlap_with_prior_union": prior_overlap,
            "novel_fraction_of_layer": frac(novel_count, sizes[k]),
            "fully_shadowed_by_prior_union": novel_count == 0,
            "cumulative_union_hits_after": (union | m).bit_count(),
        })
        union |= m

    single_containments: list[dict[str, Any]] = []
    best_prior: list[dict[str, Any]] = []
    pairwise_top: list[dict[str, Any]] = []

    for j, k in enumerate(ks):
        if j == 0:
            best_prior.append({"k": k, "best_earlier_k": None, "coverage": None, "jaccard": None})
            continue
        mk = masks[k]
        sk = sizes[k]
        best = None
        for i in range(j):
            e = ks[i]
            me = masks[e]
            inter = (mk & me).bit_count()
            union_count = sk + sizes[e] - inter
            coverage = inter / sk
            jaccard = inter / union_count if union_count else 1.0
            row = {
                "later_k": k,
                "earlier_k": e,
                "later_hits": sk,
                "earlier_hits": sizes[e],
                "intersection": inter,
                "later_covered_fraction": coverage,
                "jaccard": jaccard,
            }
            if best is None or (coverage, jaccard, inter, -e) > (
                best["later_covered_fraction"], best["jaccard"], best["intersection"], -best["earlier_k"]
            ):
                best = row
            if mk & ~me == 0:
                single_containments.append(row | {"exact_containment": True})
            pairwise_top.append(row)
        assert best is not None
        best_prior.append({
            "k": k,
            "best_earlier_k": best["earlier_k"],
            "coverage": best["later_covered_fraction"],
            "jaccard": best["jaccard"],
            "intersection": best["intersection"],
        })

    pairwise_top.sort(
        key=lambda r: (r["jaccard"], r["later_covered_fraction"], r["intersection"]),
        reverse=True,
    )

    two_layer: list[dict[str, Any]] = []
    targets_with_pair_shadow = 0
    for j, k in enumerate(ks):
        if j < 2:
            continue
        mk = masks[k]
        if any(x["later_k"] == k for x in single_containments):
            continue
        found: list[tuple[int, int]] = []
        for ai in range(j):
            a = ks[ai]
            ma = masks[a]
            missing_after_a = mk & ~ma
            if not missing_after_a:
                continue
            for bi in range(ai + 1, j):
                b = ks[bi]
                if missing_after_a & ~masks[b] == 0:
                    found.append((a, b))
                    if len(found) >= pair_limit:
                        break
            if len(found) >= pair_limit:
                break
        if found:
            targets_with_pair_shadow += 1
            two_layer.append({
                "later_k": k,
                "later_hits": sizes[k],
                "earlier_pairs": [{"a": a, "b": b} for a, b in found],
                "truncated_at": pair_limit if len(found) >= pair_limit else None,
            })

    fully_shadowed = [r["k"] for r in novelty_rows if r["fully_shadowed_by_prior_union"]]
    novel_k = [r["k"] for r in novelty_rows if r["novel_hits"] > 0]
    above107 = [k for k in ks if k > 107]

    # Greedy earlier-layer cover is heuristic and clearly labeled. It helps
    # prioritize theorem search without pretending to solve exact set cover.
    greedy: list[dict[str, Any]] = []
    for j, k in enumerate(ks):
        if j == 0:
            continue
        target = masks[k]
        remaining = target
        chosen: list[int] = []
        available = ks[:j]
        while remaining:
            best_k = None
            best_gain = 0
            for e in available:
                if e in chosen:
                    continue
                gain = (remaining & masks[e]).bit_count()
                if gain > best_gain:
                    best_gain = gain
                    best_k = e
            if best_k is None or best_gain == 0:
                break
            chosen.append(best_k)
            remaining &= ~masks[best_k]
        greedy.append({
            "k": k,
            "covered": remaining == 0,
            "earlier_layers": chosen,
            "layer_count": len(chosen) if remaining == 0 else None,
            "uncovered_hits": remaining.bit_count(),
        })

    return {
        "analysis": "cbx-lane-I-overlap-graph-v1",
        "layers": len(ks),
        "k_min": ks[0],
        "k_max": ks[-1],
        "relation_rows": relations,
        "unique_primes_hit_by_any_layer": universe_hits,
        "total_hit_events": sum(sizes.values()),
        "ordered_union_hits": union.bit_count(),
        "ordered_first_hit_total": first_hit_total,
        "novel_layers": len(novel_k),
        "novel_k": novel_k,
        "fully_shadowed_by_prior_union_layers": len(fully_shadowed),
        "fully_shadowed_by_prior_union_k": fully_shadowed,
        "above_107": {
            "layers": len(above107),
            "all_fully_shadowed_by_prior_union": all(k in fully_shadowed for k in above107),
            "single_layer_containment_candidates": [
                r for r in single_containments if r["later_k"] > 107
            ],
            "two_layer_containment_targets": [
                r for r in two_layer if r["later_k"] > 107
            ],
        },
        "exact_single_layer_containments": single_containments,
        "exact_single_layer_containment_count": len(single_containments),
        "exact_two_layer_containment_targets": two_layer,
        "exact_two_layer_containment_target_count": targets_with_pair_shadow,
        "best_earlier_single_overlap": best_prior,
        "top_pairwise_similarity": pairwise_top[:top],
        "ordered_novelty": novelty_rows,
        "greedy_earlier_cover": greedy,
        "claim": (
            "finite exact set relations only; pair/single containment candidates are theorem leads, "
            "not universal signed-box shadow theorems; greedy covers are heuristic summaries"
        ),
    }


def print_text(r: dict[str, Any]) -> None:
    print("cbx.kernel finite Lane-I overlap graph")
    print(f"layers={r['layers']} k={r['k_min']}..{r['k_max']} relations={r['relation_rows']}")
    print(f"unique hit primes={r['unique_primes_hit_by_any_layer']} hit events={r['total_hit_events']}")
    print(f"novel layers={r['novel_layers']} fully shadowed by prior union={r['fully_shadowed_by_prior_union_layers']}")
    print(f"exact single-layer containments={r['exact_single_layer_containment_count']}")
    print(f"targets with exact earlier two-layer cover={r['exact_two_layer_containment_target_count']}")
    print()
    print("top pairwise similarities")
    for x in r["top_pairwise_similarity"][:12]:
        print(
            f"  {x['later_k']} <- {x['earlier_k']}  intersection={x['intersection']} "
            f"coverage={x['later_covered_fraction']:.6f} jaccard={x['jaccard']:.6f}"
        )
    print()
    print("warning: finite containment is a proof target, not a universal theorem")


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze exact standalone Lane-I hit-set relations")
    ap.add_argument("input", type=Path, help="k<TAB>p relation file from cbx standalone-i --sets")
    ap.add_argument("--top", type=int, default=30)
    ap.add_argument("--pair-limit", type=int, default=20)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.top < 1 or args.pair_limit < 1:
        raise SystemExit("--top and --pair-limit must be >= 1")
    if not args.input.is_file():
        raise SystemExit(f"no relation file: {args.input}")
    ks, sets, relations = load_relations(args.input)
    report = analyze(ks, sets, relations, args.top, args.pair_limit)
    report["input"] = str(args.input)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
