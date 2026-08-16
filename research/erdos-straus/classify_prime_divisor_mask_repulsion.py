#!/usr/bin/env python3
"""Source-independent divisor-mask repulsion atlas at prime destinations."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

from classify_recursive_character_promotion import (
    BASE_SOURCES,
    State,
    candidate_promotions,
    divisor_square_residues,
    is_prime,
    quadratic_residues,
    root_states,
    route_residue,
    state_key,
)

HARD_CLASSES = (1, 121, 169, 289, 361, 529)

EXPECTED_NEGATIVE_BRANCHES = {
    (1, 11, 3, 4, (2, 6)),
    (1, 19, 5, 2, (2, 3, 8, 10, 12, 13)),
    (1, 23, 6, 10, (5, 14)),
    (121, 11, 3, 4, (2, 6)),
    (121, 23, 6, 10, (5, 14)),
    (169, 23, 6, 10, (5, 14)),
    (169, 71, 30, 26, (17, 53)),
    (289, 19, 7, 6, (2, 3, 14)),
    (289, 23, 6, 10, (5, 14)),
    (289, 71, 30, 26, (17, 53)),
    (361, 11, 3, 4, (2, 6)),
    (361, 19, 5, 2, (2, 3, 8, 10, 12, 13)),
    (361, 23, 6, 10, (5, 14)),
    (361, 31, 14, 10, (26,)),
    (529, 23, 6, 10, (5, 14)),
    (529, 71, 30, 26, (17, 53)),
}

EXPECTED_RECURSIVE_TRIPLES = {
    (121, 11, 53, 1, 42),
    (121, 11, 59, 2, 48),
    (121, 11, 71, 2, 60),
    (121, 23, 13, 0, 3),
    (121, 23, 59, 2, 36),
    (121, 23, 71, 2, 48),
    (169, 23, 13, 2, 3),
    (169, 23, 71, 1, 48),
    (169, 23, 167, 2, 144),
    (169, 71, 37, 0, 3),
    (169, 71, 167, 2, 96),
    (289, 19, 17, 0, 15),
    (289, 19, 43, 0, 24),
    (289, 23, 13, 0, 3),
    (289, 23, 71, 1, 48),
    (289, 71, 43, 0, 15),
    (289, 71, 191, 1, 120),
}

EXPECTED_NEW_TERMINALS = {
    (121, 11, 53),
    (121, 11, 59),
    (121, 11, 71),
    (169, 71, 37),
    (169, 71, 167),
    (289, 71, 43),
    (289, 71, 191),
}


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def augmented_mask(base: frozenset[int], r: int, k: int) -> frozenset[int]:
    return frozenset(a * b % k for a in base for b in (1, r, r * r % k))


def factor(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    d = 2
    while d * d <= n:
        while n % d == 0:
            out[d] += 1
            n //= d
        d += 1 if d == 2 else 2
    if n > 1:
        out[n] += 1
    return out


def transition(mask: frozenset[int], center: int, a: int, k: int) -> tuple[frozenset[int], int]:
    local = (1, a, a * a % k)
    return frozenset(x * y % k for x in mask for y in local), center * a % k


def negative_miss_centers(seed: int, k: int) -> tuple[int, int, tuple[int, ...]]:
    mask = frozenset({1})
    center = 1
    for q, e in factor(seed).items():
        for _ in range(e):
            mask, center = transition(mask, center, q % k, k)

    start = (mask, center)
    units = tuple(range(1, k))
    type_i = (-pow(4, -1, k)) % k
    seen = {start}
    queue = deque([start])
    misses = []
    while queue:
        state_mask, state_center = queue.popleft()
        if type_i not in state_mask and (-state_center) % k not in state_mask:
            misses.append(state_center)
        for a in units:
            nxt = transition(state_mask, state_center, a, k)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)

    qrs = quadratic_residues(k)
    centers = {4 * c % k for c in misses}
    negative = tuple(sorted(c for c in centers if c not in qrs))
    return len(seen), len(misses), negative


def seed_atlas(max_k: int) -> list[dict[str, object]]:
    rows = []
    for k in range(3, max_k + 1, 4):
        if not is_prime(k):
            continue
        qrs = quadratic_residues(k)
        for h in HARD_CLASSES:
            seed = class_seed(k, h)
            if math.gcd(seed, k) != 1:
                continue
            base = divisor_square_residues(seed, k)
            if not base.issubset(qrs) or base == qrs:
                continue
            repellers = tuple(sorted(r for r in qrs if augmented_mask(base, r, k) == qrs))
            if not repellers:
                continue
            states, misses, negative = negative_miss_centers(seed, k)
            rows.append({
                "hard_class": h,
                "destination_k": k,
                "base_seed": seed,
                "base_mask_size": len(base),
                "qr_size": len(qrs),
                "repelling_source_residues": list(repellers),
                "repelling_source_residue_count": len(repellers),
                "ordinary_state_count": states,
                "ordinary_miss_state_count": misses,
                "ordinary_negative_miss_centers": list(negative),
            })
    return rows


def recursive_states(max_k: int, max_sources: int) -> list[State]:
    roots = root_states()
    queue = deque(roots)
    seen = {state_key(s) for s in roots}
    states = list(roots)
    while queue:
        state = queue.popleft()
        positives = set(BASE_SOURCES[state.hard_class]) | set(state.derived_sources)
        for row in candidate_promotions(state, max_k, max_sources):
            promoted = int(row["promoted_prime"])
            if promoted in positives:
                continue
            child = State(
                hard_class=state.hard_class,
                residues=row["new_residues"],
                derived_sources=tuple(sorted(set(state.derived_sources) | {promoted})),
                required_misses=tuple(sorted(set(state.required_misses) | {int(row["destination_k"])})),
                depth=state.depth + 1,
                path=state.path + (
                    f"{row['kind']} {list(row['sources'])} -> k{row['destination_k']} extracts q{promoted}",
                ),
            )
            key = state_key(child)
            if key not in seen:
                seen.add(key)
                states.append(child)
                queue.append(child)
    return states


def analyze(max_k: int, max_sources: int) -> dict[str, object]:
    if max_sources != 2:
        raise SystemExit("pinned recursive intersection is defined for source arity <=2")

    seeds = seed_atlas(max_k)
    if len(seeds) != 21:
        raise SystemExit(f"seed repulsion atlas changed: {len(seeds)}")

    negative_rows = [row for row in seeds if row["ordinary_negative_miss_centers"]]
    pinned_negative = {
        (
            int(row["hard_class"]), int(row["destination_k"]), int(row["base_seed"]),
            int(row["repelling_source_residue_count"]),
            tuple(int(x) for x in row["ordinary_negative_miss_centers"]),
        )
        for row in negative_rows
    }
    if pinned_negative != EXPECTED_NEGATIVE_BRANCHES:
        raise SystemExit(f"negative-center atlas changed: {sorted(pinned_negative)!r}")

    states = recursive_states(max_k, max_sources)
    if len(states) != 70:
        raise SystemExit(f"recursive state dependency changed: {len(states)}")

    by_h = {h: [] for h in HARD_CLASSES}
    for row in negative_rows:
        by_h[int(row["hard_class"])].append(row)

    opportunities = []
    minimum: dict[tuple[int, int, int], tuple[int, int, State, dict[str, object]]] = {}
    for state in states:
        fixed = state.residue_map()
        for q in state.derived_sources:
            for branch in by_h[state.hard_class]:
                k = int(branch["destination_k"])
                if q == k or q % k not in set(branch["repelling_source_residues"]):
                    continue
                required = route_residue(q, state.hard_class, k, fixed)
                if required is None:
                    continue
                opportunities.append((state, q, branch, required))
                key = (state.hard_class, k, q)
                if key not in minimum or state.depth < minimum[key][0]:
                    minimum[key] = (state.depth, required, state, branch)

    triples = {
        (h, k, q, depth, required)
        for (h, k, q), (depth, required, _state, _branch) in minimum.items()
    }
    if triples != EXPECTED_RECURSIVE_TRIPLES:
        raise SystemExit(f"recursive repeller triples changed: {sorted(triples)!r}")
    if len(opportunities) != 106:
        raise SystemExit(f"recursive opportunity count changed: {len(opportunities)}")

    new_terminals = {
        (h, k, q) for h, k, q, _depth, _required in triples
        if k != 23 and not (h == 289 and k == 19)
    }
    if new_terminals != EXPECTED_NEW_TERMINALS:
        raise SystemExit(f"new terminal set changed: {sorted(new_terminals)!r}")

    return {
        "analysis": "prime-divisor-mask-repulsion-atlas-v1",
        "max_destination_k": max_k,
        "source_independent_seed_branches": len(seeds),
        "negative_center_repulsion_branches": len(negative_rows),
        "support_only_saturation_branches": len(seeds) - len(negative_rows),
        "recursive_states_checked": len(states),
        "recursive_state_source_destination_opportunities": len(opportunities),
        "recursive_repeller_triple_count": len(triples),
        "new_terminal_triple_count_beyond_k23_and_h289k19": len(new_terminals),
        "new_terminal_triples": [
            {"hard_class": h, "destination_k": k, "source_prime": q}
            for h, k, q in sorted(new_terminals)
        ],
        "negative_center_branches": negative_rows,
        "recursive_repeller_triples": [
            {
                "hard_class": h,
                "destination_k": k,
                "source_prime": q,
                "minimum_state_depth": depth,
                "required_p_mod_source": required,
                "eliminated_negative_centers": list(branch["ordinary_negative_miss_centers"]),
                "example_path": list(state.path),
            }
            for (h, k, q), (depth, required, state, branch) in sorted(minimum.items())
        ],
        "claim": (
            "source-independent prime divisor-mask repulsion law plus exact finite class-seed "
            "atlas and provenance-aware intersection with the landed recursive character states"
        ),
        "claim_boundary": (
            "conditional fixed-shift branch pruning only; an incoming source must still take "
            "the exact route residue into the destination"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-k", type=int, default=5000)
    parser.add_argument("--max-sources", type=int, default=2)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze(args.max_k, args.max_sources)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"seed branches: {report['source_independent_seed_branches']}")
        print(f"negative-center branches: {report['negative_center_repulsion_branches']}")
        print(f"recursive opportunities: {report['recursive_state_source_destination_opportunities']}")
        print(f"new terminal triples: {report['new_terminal_triple_count_beyond_k23_and_h289k19']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
