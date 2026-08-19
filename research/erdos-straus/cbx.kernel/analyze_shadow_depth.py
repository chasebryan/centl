#!/usr/bin/env python3
"""Exact finite earlier-layer containment search through depth three.

Consumes the k<TAB>p relation file emitted by `cbx standalone-i --sets`.
This is intentionally separate from the broad overlap graph analyzer: it asks
one sharp question for each layer whose finite hit set is already contained in
the union of earlier layers:

    is T_k contained in one, two, or three earlier T_j sets?

A negative result through depth three is an exact finite lower bound of four
on the number of earlier layers required. It is not a universal theorem.
"""
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
            if p in layers[k]:
                raise SystemExit(f"{path}:{lineno}: duplicate relation k={k} p={p}")
            layers[k].add(p)
            relations += 1
    if not layers:
        raise SystemExit(f"no hit relations: {path}")
    ks = sorted(layers)
    expected = list(range(ks[0], ks[-1] + 1, 4))
    if ks != expected:
        missing = sorted(set(expected) - set(ks))
        raise SystemExit(f"missing standalone layers: {missing[:20]}")
    return ks, dict(layers), relations


def masks_for(ks: list[int], sets: dict[int, set[int]]) -> tuple[dict[int, int], int]:
    universe = sorted({p for k in ks for p in sets[k]})
    index = {p: i for i, p in enumerate(universe)}
    masks: dict[int, int] = {}
    for k in ks:
        m = 0
        for p in sets[k]:
            m |= 1 << index[p]
        masks[k] = m
    return masks, len(universe)


def find_cover_up_to_three(target: int, earlier: list[tuple[int, int]]) -> list[int] | None:
    # One layer.
    for k, m in earlier:
        if target & ~m == 0:
            return [k]

    # Two or three layers. The inner rem test avoids constructing the full
    # three-way union unless the first two layers leave something uncovered.
    n = len(earlier)
    for ai in range(n - 1):
        ak, am = earlier[ai]
        for bi in range(ai + 1, n):
            bk, bm = earlier[bi]
            rem = target & ~(am | bm)
            if rem == 0:
                return [ak, bk]
            for ci in range(bi + 1, n):
                ck, cm = earlier[ci]
                if rem & ~cm == 0:
                    return [ak, bk, ck]
    return None


def analyze(ks: list[int], sets: dict[int, set[int]], relations: int) -> dict[str, Any]:
    masks, universe_hits = masks_for(ks, sets)
    prior_union = 0
    rows: list[dict[str, Any]] = []
    exact_counts = {1: 0, 2: 0, 3: 0}
    no_cover_through_three = 0

    for j, k in enumerate(ks):
        target = masks[k]
        novel = target & ~prior_union
        fully_shadowed = j > 0 and novel == 0
        row: dict[str, Any] = {
            "k": k,
            "hits": len(sets[k]),
            "novel_hits": novel.bit_count(),
            "fully_shadowed_by_prior_union": fully_shadowed,
            "cover_up_to_three": None,
            "exact_cover_size_if_le_3": None,
            "finite_lower_bound": None,
        }
        if fully_shadowed:
            earlier = [(e, masks[e] & target) for e in ks[:j]]
            earlier = [(e, m) for e, m in earlier if m]
            cover = find_cover_up_to_three(target, earlier)
            if cover is None:
                no_cover_through_three += 1
                row["finite_lower_bound"] = 4
            else:
                d = len(cover)
                exact_counts[d] += 1
                row["cover_up_to_three"] = cover
                row["exact_cover_size_if_le_3"] = d
                row["finite_lower_bound"] = d
        rows.append(row)
        prior_union |= target

    shadowed = [r for r in rows if r["fully_shadowed_by_prior_union"]]
    above107 = [r for r in shadowed if r["k"] > 107]
    above107_no3 = [r for r in above107 if r["exact_cover_size_if_le_3"] is None]

    return {
        "analysis": "cbx-lane-I-shadow-depth-v1",
        "layers": len(ks),
        "k_min": ks[0],
        "k_max": ks[-1],
        "relation_rows": relations,
        "unique_primes_hit_by_any_layer": universe_hits,
        "fully_shadowed_by_prior_union_layers": len(shadowed),
        "exact_cover_counts_through_three": {
            "size_1": exact_counts[1],
            "size_2": exact_counts[2],
            "size_3": exact_counts[3],
        },
        "no_exact_cover_through_three_layers": no_cover_through_three,
        "above_107": {
            "fully_shadowed_layers": len(above107),
            "exact_cover_counts_through_three": {
                "size_1": sum(r["exact_cover_size_if_le_3"] == 1 for r in above107),
                "size_2": sum(r["exact_cover_size_if_le_3"] == 2 for r in above107),
                "size_3": sum(r["exact_cover_size_if_le_3"] == 3 for r in above107),
            },
            "no_exact_cover_through_three_layers": len(above107_no3),
            "finite_minimum_cover_lower_bound": (
                4 if above107 and len(above107_no3) == len(above107) else None
            ),
            "k_without_cover_le_3": [r["k"] for r in above107_no3],
        },
        "rows": rows,
        "claim": (
            "exact finite containment search only; a lower bound of 4 means no one-, two-, "
            "or three-earlier-layer union covers the finite T_k set. It is not a universal theorem."
        ),
    }


def print_text(r: dict[str, Any]) -> None:
    c = r["exact_cover_counts_through_three"]
    a = r["above_107"]
    print("cbx.kernel finite Lane-I shadow-depth check")
    print(f"layers={r['layers']} k={r['k_min']}..{r['k_max']} shadowed={r['fully_shadowed_by_prior_union_layers']}")
    print(f"exact covers: size1={c['size_1']} size2={c['size_2']} size3={c['size_3']}")
    print(f"no cover through 3: {r['no_exact_cover_through_three_layers']}")
    print(f"k>107 shadowed={a['fully_shadowed_layers']} no-cover-through-3={a['no_exact_cover_through_three_layers']}")
    if a["finite_minimum_cover_lower_bound"]:
        print("finite lower bound for every k>107: at least 4 earlier layers")
    print("finite result only")


def main() -> int:
    ap = argparse.ArgumentParser(description="Exact finite Lane-I containment search through triples")
    ap.add_argument("input", type=Path, help="k<TAB>p relation file")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if not args.input.is_file():
        raise SystemExit(f"no relation file: {args.input}")
    ks, sets, relations = load_relations(args.input)
    report = analyze(ks, sets, relations)
    report["input"] = str(args.input)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
