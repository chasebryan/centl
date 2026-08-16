#!/usr/bin/env python3
"""Source-independent divisor-mask repulsion atlas at prime destinations."""
from __future__ import annotations

import argparse
import functools
import json
import math
from collections import Counter, deque

from classify_recursive_character_promotion import (
    BASE_SOURCES,
    State,
    candidate_promotions,
    root_states,
    route_residue,
    state_key,
)

HARD_CLASSES = (1, 121, 169, 289, 361, 529)

EXPECTED_NEGATIVE_BRANCHES = (
    (1, 11, 3, 4, (2, 6)),
    (121, 11, 3, 4, (2, 6)),
    (361, 11, 3, 4, (2, 6)),
    (1, 19, 5, 2, (2, 3, 8, 10, 12, 13)),
    (289, 19, 7, 6, (2, 3, 14)),
    (361, 19, 5, 2, (2, 3, 8, 10, 12, 13)),
    (1, 23, 6, 10, (5, 14)),
    (121, 23, 6, 10, (5, 14)),
    (169, 23, 6, 10, (5, 14)),
    (289, 23, 6, 10, (5, 14)),
    (361, 23, 6, 10, (5, 14)),
    (529, 23, 6, 10, (5, 14)),
    (361, 31, 14, 10, (26,)),
    (169, 71, 30, 26, (17, 53)),
    (289, 71, 30, 26, (17, 53)),
    (529, 71, 30, 26, (17, 53)),
)

EXPECTED_RECURSIVE_TRIPLES = (
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
)

EXPECTED_NEW_TERMINAL_TRIPLES = (
    (121, 11, 53),
    (121, 11, 59),
    (121, 11, 71),
    (169, 71, 37),
    (169, 71, 167),
    (289, 71, 43),
    (289, 71, 191),
)


@functools.lru_cache(maxsize=None)
def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    d = 3
    while d * d <= n:
        if n % d == 0:
            return False
        d += 2
    return True


@functools.lru_cache(maxsize=None)
def factor_tuple(n: int) -> tuple[tuple[int, int], ...]:
    out: Counter[int] = Counter()
    d = 2
    while d * d <= n:
        while n % d == 0:
            out[d] += 1
            n //= d
        d += 1 if d == 2 else 2
    if n > 1:
        out[n] += 1
    return tuple(sorted(out.items()))


@functools.lru_cache(maxsize=None)
def divisor_square_residues(seed: int, k: int) -> frozenset[int]:
    residues = {1}
    for q, e in factor_tuple(seed):
        local = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in local}
    return frozenset(residues)


@functools.lru_cache(maxsize=None)
def quadratic_residues(k: int) -> frozenset[int]:
    return frozenset(x * x % k for x in range(1, k))


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def symbolic_augmented_mask(base_mask: frozenset[int], r: int, k: int) -> frozenset[int]:
    local = (1, r, r * r % k)
    return frozenset(a * b % k for a in base_mask for b in local)


class UnitStateModel:
    """Independent fixed-shift state closure used only to locate ordinary miss centers."""

    def __init__(self, k: int):
        self.k = k
        self.units = [u for u in range(1, k) if math.gcd(u, k) == 1]
        self.index = {u: i for i, u in enumerate(self.units)}
        self.type_i = (-pow(4, -1, k)) % k

    def transition(self, state: tuple[int, int], a: int) -> tuple[int, int]:
        mask, center = state
        out = 0
        local = (1, a, a * a % self.k)
        for i, u in enumerate(self.units):
            if (mask >> i) & 1:
                for v in local:
                    out |= 1 << self.index[u * v % self.k]
        return out, center * a % self.k

    def seed_state(self, seed: int) -> tuple[int, int]:
        state = (1 << self.index[1], 1)
        for q, e in factor_tuple(seed):
            for _ in range(e):
                state = self.transition(state, q % self.k)
        return state

    def closure(self, seed: int) -> set[tuple[int, int]]:
        start = self.seed_state(seed)
        seen = {start}
        queue = deque([start])
        while queue:
            state = queue.popleft()
            for a in self.units:
                nxt = self.transition(state, a)
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        return seen

    def is_miss(self, state: tuple[int, int]) -> bool:
        mask, center = state
        type_ii = (-center) % self.k
        return (
            ((mask >> self.index[self.type_i]) & 1) == 0
            and ((mask >> self.index[type_ii]) & 1) == 0
        )

    def p_center(self, state: tuple[int, int]) -> int:
        return 4 * state[1] % self.k


def ordinary_negative_centers(k: int, seed: int) -> tuple[int, int, tuple[int, ...]]:
    model = UnitStateModel(k)
    closure = model.closure(seed)
    misses = [state for state in closure if model.is_miss(state)]
    centers = {model.p_center(state) for state in misses}
    qr = quadratic_residues(k)
    negative = tuple(sorted(center for center in centers if center not in qr))
    return len(closure), len(misses), negative


def seed_repulsion_atlas(max_k: int) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for k in range(3, max_k + 1, 4):
        if not is_prime(k):
            continue
        qr = quadratic_residues(k)
        for h in HARD_CLASSES:
            seed = class_seed(k, h)
            if math.gcd(seed, k) != 1:
                continue
            base_mask = divisor_square_residues(seed, k)
            if not base_mask.issubset(qr) or base_mask == qr:
                continue
            repellers = tuple(sorted(
                r for r in qr
                if symbolic_augmented_mask(base_mask, r, k) == qr
            ))
            if not repellers:
                continue
            closure_count, miss_count, negative = ordinary_negative_centers(k, seed)
            rows.append({
                "hard_class": h,
                "destination_k": k,
                "base_seed": seed,
                "base_mask_size": len(base_mask),
                "qr_size": len(qr),
                "repelling_source_residues": list(repellers),
                "repelling_source_residue_count": len(repellers),
                "ordinary_state_count": closure_count,
                "ordinary_miss_state_count": miss_count,
                "ordinary_negative_miss_centers": list(negative),
            })
    return rows


def recursive_states(max_k: int, max_sources: int) -> list[State]:
    roots = root_states()
    queue: deque[State] = deque(roots)
    seen = {state_key(state) for state in roots}
    states = list(roots)
    while queue:
        state = queue.popleft()
        current_positive = set(BASE_SOURCES[state.hard_class]) | set(state.derived_sources)
        for row in candidate_promotions(state, max_k, max_sources):
            promoted = int(row["promoted_prime"])
            if promoted in current_positive:
                continue
            child = State(
                hard_class=state.hard_class,
                residues=row["new_residues"],
                derived_sources=tuple(sorted(set(state.derived_sources) | {promoted})),
                required_misses=tuple(
                    sorted(set(state.required_misses) | {int(row["destination_k"])})
                ),
                depth=state.depth + 1,
                path=state.path + (
                    f"{row['kind']} {list(row['sources'])} -> "
                    f"k{row['destination_k']} extracts q{promoted}",
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

    seed_rows = seed_repulsion_atlas(max_k)
    if len(seed_rows) != 21:
        raise SystemExit(f"source-independent seed repulsion atlas changed: {len(seed_rows)}")

    negative_rows = [row for row in seed_rows if row["ordinary_negative_miss_centers"]]
    pinned_negative = tuple(sorted(
        (
            int(row["hard_class"]),
            int(row["destination_k"]),
            int(row["base_seed"]),
            int(row["repelling_source_residue_count"]),
            tuple(int(x) for x in row["ordinary_negative_miss_centers"]),
        )
        for row in negative_rows
    ))
    if pinned_negative != EXPECTED_NEGATIVE_BRANCHES:
        raise SystemExit(f"negative-center repulsion atlas changed: {pinned_negative!r}")

    states = recursive_states(max_k, max_sources)
    if len(states) != 70:
        raise SystemExit(f"recursive state dependency changed: {len(states)}")

    by_h: dict[int, list[dict[str, object]]] = {h: [] for h in HARD_CLASSES}
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
                row = {
                    "hard_class": state.hard_class,
                    "destination_k": k,
                    "source_prime": q,
                    "source_mod_destination": q % k,
                    "required_p_mod_source": required,
                    "state_depth": state.depth,
                    "eliminated_negative_centers": list(branch["ordinary_negative_miss_centers"]),
                    "path": list(state.path),
                }
                opportunities.append(row)
                key = (state.hard_class, k, q)
                prior = minimum.get(key)
                if prior is None or state.depth < prior[0]:
                    minimum[key] = (state.depth, required, state, branch)

    pinned_triples = tuple(sorted(
        (h, k, q, depth, required)
        for (h, k, q), (depth, required, _state, _branch) in minimum.items()
    ))
    if pinned_triples != EXPECTED_RECURSIVE_TRIPLES:
        raise SystemExit(f"recursive repulsion triples changed: {pinned_triples!r}")
    if len(opportunities) != 106:
        raise SystemExit(f"recursive repulsion opportunity count changed: {len(opportunities)}")

    new_terminal = tuple(sorted(
        (h, k, q)
        for h, k, q, _depth, _required in pinned_triples
        if k != 23 and not (h == 289 and k == 19)
    ))
    if new_terminal != EXPECTED_NEW_TERMINAL_TRIPLES:
        raise SystemExit(f"new terminal repulsion triples changed: {new_terminal!r}")

    return {
        "analysis": "prime-divisor-mask-repulsion-atlas-v1",
        "max_destination_k": max_k,
        "source_independent_seed_branches": len(seed_rows),
        "negative_center_repulsion_branches": len(negative_rows),
        "support_only_saturation_branches": len(seed_rows) - len(negative_rows),
        "recursive_states_checked": len(states),
        "recursive_state_source_destination_opportunities": len(opportunities),
        "recursive_repeller_triple_count": len(pinned_triples),
        "new_terminal_triple_count_beyond_k23_and_h289k19": len(new_terminal),
        "new_terminal_triples": [
            {"hard_class": h, "destination_k": k, "source_prime": q}
            for h, k, q in new_terminal
        ],
        "negative_center_branches": negative_rows,
        "recursive_repeller_triples": [
            {
                "hard_class": h,
                "destination_k": k,
                "source_prime": q,
                "minimum_state_depth": depth,
                "required_p_mod_source": required,
                "eliminated_negative_centers": list(
                    minimum[(h, k, q)][3]["ordinary_negative_miss_centers"]
                ),
                "example_path": list(minimum[(h, k, q)][2].path),
            }
            for h, k, q, depth, required in pinned_triples
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
