#!/usr/bin/env python3
"""Exact finite spectrum-conditioned overlap analysis for CBX Lane I.

Input is the exact ``k<TAB>p`` relation exported by ``cbx standalone-i
--sets``.  Each relation is classified from ``p mod 840`` into spectrum A, B,
or C, then one-, two-, and three-earlier-layer containment is searched inside
each spectrum independently.

Empty spectrum slices are reported separately and are never counted as
nontrivial containment theorems.
"""
from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path
from typing import Any

SPEC_RESIDUES = {
    "A": {1, 121},
    "B": {169, 289},
    "C": {361, 529},
}


def spectrum_of(p: int) -> str:
    r = p % 840
    for name, residues in SPEC_RESIDUES.items():
        if r in residues:
            return name
    raise ValueError(f"p={p} is not in a Mordell-hard spectrum")


def load_relations(path: Path) -> tuple[list[int], dict[str, dict[int, set[int]]], int]:
    by_spec: dict[str, dict[int, set[int]]] = {
        name: collections.defaultdict(set) for name in SPEC_RESIDUES
    }
    all_k: set[int] = set()
    rows = 0
    seen: set[tuple[int, int]] = set()
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
            key = (k, p)
            if key in seen:
                raise SystemExit(f"{path}:{lineno}: duplicate relation k={k} p={p}")
            seen.add(key)
            all_k.add(k)
            try:
                spec = spectrum_of(p)
            except ValueError as exc:
                raise SystemExit(f"{path}:{lineno}: {exc}") from exc
            by_spec[spec][k].add(p)
            rows += 1

    if not all_k:
        raise SystemExit(f"no relations in {path}")
    ks = sorted(all_k)
    expected = list(range(ks[0], ks[-1] + 1, 4))
    if ks != expected:
        missing = sorted(set(expected) - set(ks))
        raise SystemExit(f"missing layers in relation file: {missing[:20]}")

    # Materialize empty slices so every spectrum has the same k domain.
    normalized: dict[str, dict[int, set[int]]] = {}
    for spec in SPEC_RESIDUES:
        normalized[spec] = {k: set(by_spec[spec].get(k, set())) for k in ks}
    return ks, normalized, rows


def bit_masks(ks: list[int], sets: dict[int, set[int]]) -> tuple[dict[int, int], int]:
    universe = sorted({p for k in ks for p in sets[k]})
    index = {p: i for i, p in enumerate(universe)}
    masks: dict[int, int] = {}
    for k in ks:
        m = 0
        for p in sets[k]:
            m |= 1 << index[p]
        masks[k] = m
    return masks, len(universe)


def analyze_spectrum(name: str, ks: list[int], sets: dict[int, set[int]], top: int) -> dict[str, Any]:
    masks, universe_size = bit_masks(ks, sets)
    sizes = {k: len(sets[k]) for k in ks}
    nonempty = [k for k in ks if sizes[k] > 0]
    zero = [k for k in ks if sizes[k] == 0]

    prior_union = 0
    novelty: list[dict[str, Any]] = []
    for k in ks:
        m = masks[k]
        novel = m & ~prior_union
        novelty.append({
            "k": k,
            "hits": sizes[k],
            "novel_hits": novel.bit_count(),
            "fully_shadowed_by_prior_union": sizes[k] > 0 and novel == 0,
        })
        prior_union |= m

    exact1: list[dict[str, int]] = []
    exact2: list[dict[str, Any]] = []
    exact3: list[dict[str, Any]] = []
    best_single: list[dict[str, Any]] = []

    for j, k in enumerate(ks):
        mk = masks[k]
        if not mk or j == 0:
            continue
        best: tuple[float, int, int] | None = None
        for i in range(j):
            a = ks[i]
            ma = masks[a]
            inter = (mk & ma).bit_count()
            cov = inter / sizes[k]
            candidate = (cov, inter, -a)
            if best is None or candidate > best:
                best = candidate
            if mk & ~ma == 0:
                exact1.append({"later_k": k, "earlier_k": a, "hits": sizes[k]})
        if best is not None:
            best_single.append({
                "k": k,
                "earlier_k": -best[2],
                "coverage": best[0],
                "intersection": best[1],
            })

    targets1 = {r["later_k"] for r in exact1}
    for j, k in enumerate(ks):
        mk = masks[k]
        if not mk or j < 2 or k in targets1:
            continue
        found = None
        for ai in range(j - 1):
            a = ks[ai]
            missing = mk & ~masks[a]
            if not missing:
                continue
            for bi in range(ai + 1, j):
                b = ks[bi]
                if missing & ~masks[b] == 0:
                    found = (a, b)
                    break
            if found:
                break
        if found:
            exact2.append({"later_k": k, "earlier_layers": list(found), "hits": sizes[k]})

    targets2 = {r["later_k"] for r in exact2}
    for j, k in enumerate(ks):
        mk = masks[k]
        if not mk or j < 3 or k in targets1 or k in targets2:
            continue
        found = None
        for ai in range(j - 2):
            a = ks[ai]
            ma = masks[a]
            for bi in range(ai + 1, j - 1):
                b = ks[bi]
                missing = mk & ~(ma | masks[b])
                if not missing:
                    continue
                for ci in range(bi + 1, j):
                    c = ks[ci]
                    if missing & ~masks[c] == 0:
                        found = (a, b, c)
                        break
                if found:
                    break
            if found:
                break
        if found:
            exact3.append({"later_k": k, "earlier_layers": list(found), "hits": sizes[k]})

    shadowed = [r["k"] for r in novelty if r["fully_shadowed_by_prior_union"]]
    novel_k = [r["k"] for r in novelty if r["novel_hits"] > 0]
    best_single.sort(key=lambda r: (r["coverage"], r["intersection"], -r["k"]), reverse=True)

    return {
        "spectrum": name,
        "hard_primes_hit_by_any_layer": universe_size,
        "hit_events": sum(sizes.values()),
        "nonempty_layers": len(nonempty),
        "zero_hit_layers": zero,
        "novel_layers": len(novel_k),
        "novel_k": novel_k,
        "fully_shadowed_by_prior_union_layers": len(shadowed),
        "fully_shadowed_by_prior_union_k": shadowed,
        "exact_single_layer_containment_count": len(exact1),
        "exact_single_layer_containments": exact1,
        "exact_two_layer_containment_target_count": len(exact2),
        "exact_two_layer_containment_targets": exact2,
        "exact_three_layer_containment_target_count": len(exact3),
        "exact_three_layer_containment_targets": exact3,
        "best_earlier_single_overlap": best_single[:top],
        "ordered_novelty": novelty,
        "above_107": {
            "nonempty_layers": sum(1 for k in nonempty if k > 107),
            "fully_shadowed_layers": sum(1 for k in shadowed if k > 107),
            "single_containment_targets": [r for r in exact1 if r["later_k"] > 107],
            "two_containment_targets": [r for r in exact2 if r["later_k"] > 107],
            "three_containment_targets": [r for r in exact3 if r["later_k"] > 107],
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Exact spectrum-conditioned CBX Lane-I overlap analysis")
    ap.add_argument("input", type=Path, help="k<TAB>p relation file from cbx standalone-i --sets")
    ap.add_argument("--top", type=int, default=20)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if args.top < 1:
        raise SystemExit("--top must be >= 1")
    if not args.input.is_file():
        raise SystemExit(f"no relation file: {args.input}")

    ks, by_spec, relations = load_relations(args.input)
    spectra = {name: analyze_spectrum(name, ks, by_spec[name], args.top) for name in ("A", "B", "C")}
    report = {
        "analysis": "cbx-lane-I-spectrum-overlap-v1",
        "input": str(args.input),
        "layers": len(ks),
        "k_min": ks[0],
        "k_max": ks[-1],
        "relation_rows": relations,
        "spectra": spectra,
        "exact_containment_counts": {
            name: {
                "size_1": spectra[name]["exact_single_layer_containment_count"],
                "size_2": spectra[name]["exact_two_layer_containment_target_count"],
                "size_3": spectra[name]["exact_three_layer_containment_target_count"],
            }
            for name in ("A", "B", "C")
        },
        "claim": (
            "finite exact spectrum-conditioned relations only; empty slices are reported separately and "
            "not counted as nontrivial containments; any small cover is a theorem target, not a universal shadow theorem"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("cbx.kernel spectrum-conditioned Lane-I overlap")
        print(f"layers={report['layers']} relations={relations}")
        for name in ("A", "B", "C"):
            r = spectra[name]
            c = report["exact_containment_counts"][name]
            print(
                f"{name}: nonempty={r['nonempty_layers']} novel={r['novel_layers']} "
                f"shadowed={r['fully_shadowed_by_prior_union_layers']} "
                f"exact1={c['size_1']} exact2={c['size_2']} exact3={c['size_3']}"
            )
        print("warning: finite spectrum containment is a theorem lead, not a universal proof")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
