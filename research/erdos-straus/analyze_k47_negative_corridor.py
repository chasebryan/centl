#!/usr/bin/env python3
"""Finite theorem-mining analysis of negative-Legendre k=47 misses.

Consumes a CBX standalone hit-relation TSV and asks which earlier classified
corridor shifts cover the hard primes that miss k=47 with (47/p)=-1.

The direction-resolved analysis maps each finite target to every compatible
one-packet representative class from the exact forced-6 k=47 state theorem.
The mapping is deliberately set-valued: uniqueness is reported only when it
emerges from the exact state classes and the finite corpus.

No finite cover is promoted to a universal theorem.
"""
from __future__ import annotations

import argparse
import itertools
import json
from collections import Counter, defaultdict, deque
from pathlib import Path

import classify_k47_forced6_states as forced6
import classify_k47_states as k47

PRIOR = (3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43)
COMPANION_PRIOR = PRIOR[:-1]
ONE_PACKET_DIRECTIONS = (1, 7, 9, 11, 17, 19, 27, 29, 35, 37, 45)


def load(path: Path, hi: int | None):
    hits: dict[int, set[int]] = defaultdict(set)
    universe: set[int] = set()
    with path.open("r", encoding="utf-8") as fh:
        for line_no, raw in enumerate(fh, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) != 2:
                raise SystemExit(f"{path}:{line_no}: expected 'k p'")
            k, p = map(int, parts)
            if hi is None or p <= hi:
                hits[k].add(p)
                universe.add(p)
    return hits, universe


def legendre47_negative(p: int) -> bool:
    return pow(p % 47, 23, 47) == 46


def minimum_covers(
    targets: set[int],
    hits: dict[int, set[int]],
    shifts: tuple[int, ...],
):
    for r in range(1, len(shifts) + 1):
        covers = []
        for comb in itertools.combinations(shifts, r):
            if targets <= set().union(*(hits[k] for k in comb)):
                covers.append(comb)
        if covers:
            return covers
    return []


def factor_with_exp(n: int) -> list[tuple[int, int]]:
    if n < 1:
        raise ValueError("factorization input must be positive")
    out = []
    q = 2
    while q * q <= n:
        if n % q == 0:
            e = 0
            while n % q == 0:
                n //= q
                e += 1
            out.append((q, e))
        q = 3 if q == 2 else q + 2
    if n > 1:
        out.append((n, 1))
    return out


def actual_k47_state(p: int) -> tuple[int, int]:
    C = (p + 47) // 4
    state = (1, 0)
    for q, e in factor_with_exp(C):
        residue = q % k47.MOD
        if residue == 0:
            raise SystemExit(
                f"unexpected non-unit factor 47 in C47 for p={p}; "
                "the fixed-k state model requires unit factor residues"
            )
        direction = k47.LOG[residue]
        for _ in range(e):
            state = k47.transition(state, direction)
    return state


def closure_from(
    start: tuple[int, int],
    directions: tuple[int, ...] | range,
) -> set[tuple[int, int]]:
    seen = {start}
    q = deque([start])
    while q:
        state = q.popleft()
        for direction in directions:
            nxt = k47.transition(state, direction)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def one_packet_miss_classes() -> dict[int, set[tuple[int, int]]]:
    """Return exact miss states reachable by one r-packet plus arbitrary QR units."""
    start = forced6.forced_start()
    classes: dict[int, set[tuple[int, int]]] = {}
    even_directions = range(0, k47.N, 2)
    for r in ONE_PACKET_DIRECTIONS:
        seed = k47.transition(start, r)
        classes[r] = {
            state
            for state in closure_from(seed, even_directions)
            if k47.is_miss(state)
        }

    forced_negative_misses = {
        state
        for state in forced6.closure()
        if k47.is_miss(state) and state[1] % 2 == 1
    }
    represented = set().union(*classes.values())
    if represented != forced_negative_misses:
        raise SystemExit(
            "one-packet direction classes no longer equal the exact 80-state "
            "negative-character forced-6 miss family"
        )
    if len(represented) != 80:
        raise SystemExit(
            f"one-packet negative miss family changed: {len(represented)} != 80"
        )
    if any(not states for states in classes.values()):
        raise SystemExit("one-packet direction alphabet contains an empty class")
    return classes


def best_residual_subcovers(
    targets: set[int],
    hits: dict[int, set[int]],
    shifts: tuple[int, ...],
    sizes=(1, 2, 3),
):
    rows = []
    for r in sizes:
        if r > len(shifts):
            continue
        best_left = None
        examples = []
        for comb in itertools.combinations(shifts, r):
            covered = set().union(*(hits[k] for k in comb))
            left = len(targets - covered)
            if best_left is None or left < best_left:
                best_left = left
                examples = [comb]
            elif left == best_left:
                examples.append(comb)
        rows.append(
            {
                "cover_size": r,
                "minimum_residual": best_left,
                "example": list(examples[0]) if examples else None,
                "number_of_best_subsets": len(examples),
            }
        )
    return rows


def direction_analysis(
    targets: set[int],
    hits: dict[int, set[int]],
):
    classes = one_packet_miss_classes()
    compatible: dict[int, tuple[int, ...]] = {}
    by_direction: dict[int, set[int]] = {
        r: set() for r in ONE_PACKET_DIRECTIONS
    }

    for p in targets:
        state = actual_k47_state(p)
        if not k47.is_miss(state):
            raise SystemExit(f"target p={p} is not an actual k=47 miss state")
        directions = tuple(
            r for r in ONE_PACKET_DIRECTIONS if state in classes[r]
        )
        if not directions:
            raise SystemExit(
                f"target p={p} has no compatible one-packet representative"
            )
        compatible[p] = directions
        for r in directions:
            by_direction[r].add(p)

    cardinality = Counter(len(v) for v in compatible.values())
    rows = []
    for r in ONE_PACKET_DIRECTIONS:
        dtargets = by_direction[r]
        local_hits = {
            k: hits[k] & dtargets for k in COMPANION_PRIOR
        }
        min_covers = minimum_covers(
            dtargets, local_hits, COMPANION_PRIOR
        )
        singleton = [
            k for k in COMPANION_PRIOR if dtargets <= local_hits[k]
        ]
        pair = [
            list(comb)
            for comb in itertools.combinations(COMPANION_PRIOR, 2)
            if dtargets <= (local_hits[comb[0]] | local_hits[comb[1]])
        ]
        rows.append(
            {
                "direction_log": r,
                "direction_residue": pow(
                    k47.PRIMITIVE_ROOT, r, k47.MOD
                ),
                "abstract_miss_states_in_class": len(classes[r]),
                "compatible_finite_targets": len(dtargets),
                "shift_capture": [
                    {
                        "k": k,
                        "captured": len(local_hits[k]),
                        "left": len(dtargets - local_hits[k]),
                    }
                    for k in COMPANION_PRIOR
                ],
                "singleton_eliminators": singleton,
                "pair_eliminators": pair,
                "minimum_finite_cover_size": (
                    len(min_covers[0]) if min_covers else None
                ),
                "minimum_finite_cover_example": (
                    list(min_covers[0]) if min_covers else None
                ),
                "number_of_minimum_finite_covers": len(min_covers),
                "best_residual_by_cover_size": best_residual_subcovers(
                    dtargets, local_hits, COMPANION_PRIOR
                ),
            }
        )

    return {
        "representative_directions": list(ONE_PACKET_DIRECTIONS),
        "representative_residues": [
            pow(k47.PRIMITIVE_ROOT, r, k47.MOD)
            for r in ONE_PACKET_DIRECTIONS
        ],
        "abstract_negative_forced6_miss_states": 80,
        "compatible_direction_count_histogram": {
            str(k): v for k, v in sorted(cardinality.items())
        },
        "finite_direction_relation_is_a_partition": cardinality == Counter(
            {1: len(targets)}
        ),
        "rows": rows,
    }


def exact_state_analysis(
    targets: set[int],
    hits: dict[int, set[int]],
):
    classes = one_packet_miss_classes()
    by_state: dict[tuple[int, int], set[int]] = defaultdict(set)
    for p in targets:
        by_state[actual_k47_state(p)].add(p)

    rows = []
    cover_hist = Counter()
    for state, stargets in sorted(
        by_state.items(), key=lambda item: (-len(item[1]), item[0])
    ):
        local_hits = {
            k: hits[k] & stargets for k in COMPANION_PRIOR
        }
        min_covers = minimum_covers(
            stargets, local_hits, COMPANION_PRIOR
        )
        compatible_directions = [
            r for r in ONE_PACKET_DIRECTIONS if state in classes[r]
        ]
        if len(compatible_directions) != 1:
            raise SystemExit(
                "exact negative forced-6 miss state does not have exactly one "
                f"one-packet representative class: state={state}, "
                f"directions={compatible_directions}"
            )
        cover_size = len(min_covers[0]) if min_covers else None
        cover_hist[str(cover_size)] += 1
        rows.append(
            {
                "mask": state[0],
                "mask_hex": hex(state[0]),
                "center_log": state[1],
                "representative_direction": compatible_directions[0],
                "representative_residue": pow(
                    k47.PRIMITIVE_ROOT,
                    compatible_directions[0],
                    k47.MOD,
                ),
                "finite_targets": len(stargets),
                "shift_capture": [
                    {
                        "k": k,
                        "captured": len(local_hits[k]),
                        "left": len(stargets - local_hits[k]),
                    }
                    for k in COMPANION_PRIOR
                ],
                "minimum_finite_cover_size": cover_size,
                "minimum_finite_cover_example": (
                    list(min_covers[0]) if min_covers else None
                ),
                "number_of_minimum_finite_covers": len(min_covers),
                "best_residual_by_cover_size": best_residual_subcovers(
                    stargets, local_hits, COMPANION_PRIOR
                ),
            }
        )

    abstract_states = set().union(*classes.values())
    return {
        "abstract_negative_forced6_miss_states": len(abstract_states),
        "realized_exact_states": len(by_state),
        "unrealized_exact_states": len(abstract_states - set(by_state)),
        "finite_targets": len(targets),
        "minimum_cover_size_histogram_over_realized_states": dict(
            sorted(cover_hist.items(), key=lambda kv: int(kv[0]))
        ),
        "rows": rows,
    }


def analyze(path: Path, hi: int | None):
    hits, universe = load(path, hi)
    if 47 not in hits:
        raise SystemExit("relation file has no k=47 rows")
    for k in PRIOR:
        if k not in hits:
            raise SystemExit(f"relation file has no k={k} rows")

    target = {
        p
        for p in universe
        if p not in hits[47] and legendre47_negative(p)
    }
    first = Counter()
    for p in target:
        earlier = [k for k in PRIOR if p in hits[k]]
        first[str(min(earlier)) if earlier else "none"] += 1

    remaining = set(target)
    ordered = []
    for k in PRIOR:
        before = len(remaining)
        caught = remaining & hits[k]
        remaining -= caught
        ordered.append(
            {
                "k": k,
                "before": before,
                "newly_caught": len(caught),
                "after": len(remaining),
            }
        )

    min_covers = minimum_covers(target, hits, PRIOR)
    return {
        "analysis": "k47-negative-legendre-corridor-v2-direction-resolved",
        "hi": hi,
        "hard_universe_from_relation_union": len(universe),
        "negative_legendre_k47_misses": len(target),
        "first_prior_hit_histogram": dict(
            sorted(
                first.items(),
                key=lambda kv: (
                    kv[0] == "none",
                    int(kv[0]) if kv[0] != "none" else 10**9,
                ),
            )
        ),
        "ordered_residual": ordered,
        "residual_after_prior_corridor": len(remaining),
        "minimum_finite_cover_size": (
            len(min_covers[0]) if min_covers else None
        ),
        "minimum_finite_cover_example": (
            list(min_covers[0]) if min_covers else None
        ),
        "number_of_minimum_finite_covers": len(min_covers),
        "direction_resolved": direction_analysis(target, hits),
        "exact_state_resolved": exact_state_analysis(target, hits),
        "claim": (
            "exact finite relation-set and exact fixed-k state analysis only; "
            "no universal cross-shift containment theorem"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("relations", type=Path)
    ap.add_argument("--hi", type=int)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.relations, args.hi)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(
            "negative-Legendre k47 misses: "
            f"{report['negative_legendre_k47_misses']}"
        )
        for row in report["ordered_residual"]:
            print(
                f"k={row['k']}: {row['before']} -> {row['after']} "
                f"(caught {row['newly_caught']})"
            )
        print(
            "minimum finite cover: "
            f"{report['minimum_finite_cover_example']}"
        )
        d = report["direction_resolved"]
        print(
            "direction compatibility cardinality: "
            f"{d['compatible_direction_count_histogram']}"
        )
        for row in d["rows"]:
            print(
                f"r={row['direction_log']:2d} "
                f"(residue {row['direction_residue']:2d}): "
                f"targets={row['compatible_finite_targets']:3d}; "
                f"minimum cover={row['minimum_finite_cover_example']}"
            )
        s = report["exact_state_resolved"]
        print(
            "exact-state finite cover histogram: "
            f"{s['minimum_cover_size_histogram_over_realized_states']}"
        )
        print("warning: finite theorem-mining evidence only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
