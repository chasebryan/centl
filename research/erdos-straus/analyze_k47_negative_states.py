#!/usr/bin/env python3
"""Refine the finite negative-character k=47 corridor by exact abstract miss state.

This is a second-stage theorem-mining view over analyze_k47_negative_corridor.py.
It does not reimplement the fixed-k state model or the finite universe. Instead,
it imports the validated v2 analyzer, reconstructs each target's exact k=47
state, assigns a stable state ID inside its one-packet direction class, and
computes exact finite minimum earlier-shift covers for every realized state.

Finite cover statements are evidence only, not universal containment theorems.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path

import analyze_k47_negative_corridor as corridor
import classify_k47_forced6_states as hard
import classify_k47_states as core


def abstract_state_partition() -> tuple[
    dict[tuple[int, int], int],
    dict[tuple[int, int], str],
    dict[int, list[tuple[int, int]]],
]:
    closures = corridor.one_packet_closures()
    negative_misses = {
        state
        for state in hard.closure()
        if core.is_miss(state) and state[1] % 2 == 1
    }
    if len(negative_misses) != 80:
        raise SystemExit(f"expected 80 negative-character miss states, got {len(negative_misses)}")

    state_direction: dict[tuple[int, int], int] = {}
    by_direction: dict[int, list[tuple[int, int]]] = {}
    state_id: dict[tuple[int, int], str] = {}

    for r in corridor.ONE_PACKET_DIRECTIONS:
        states = sorted(
            (state for state in negative_misses if state in closures[r]),
            key=lambda state: (state[1], state[0]),
        )
        by_direction[r] = states
        expected = corridor.EXPECTED_ABSTRACT_DIRECTION_COUNTS[r]
        if len(states) != expected:
            raise SystemExit(f"direction r={r}: {len(states)} states != expected {expected}")
        for index, state in enumerate(states, 1):
            if state in state_direction:
                raise SystemExit(f"abstract state appears in multiple direction classes: {state}")
            state_direction[state] = r
            state_id[state] = f"r{r}-s{index:02d}"

    if set(state_direction) != negative_misses:
        raise SystemExit("eleven direction classes do not partition the 80 negative miss states")
    return state_direction, state_id, by_direction


def analyze(relations: Path, hi: int) -> dict:
    base = corridor.analyze(relations, hi)
    hits, _relation_union = corridor.load(relations, hi)
    state_direction, state_id, by_direction = abstract_state_partition()

    target_primes = set(base["finite_target_primes"])
    targets_by_state: dict[tuple[int, int], set[int]] = defaultdict(set)
    for p in target_primes:
        state, _factors = corridor.k47_state_from_prime(p)
        if state not in state_direction:
            raise SystemExit(f"p={p}: exact state is not one of the 80 negative hard miss states")
        targets_by_state[state].add(p)

    rows = []
    for r in corridor.ONE_PACKET_DIRECTIONS:
        for state in by_direction[r]:
            targets = targets_by_state.get(state, set())
            covers = corridor.exact_minimum_covers(targets, hits)
            capture = [
                {
                    "k": k,
                    "caught": len(targets & hits[k]),
                    "left": len(targets - hits[k]),
                }
                for k in corridor.PRIOR
            ]
            row = {
                "state_id": state_id[state],
                "log_direction": r,
                "residue_mod47": pow(core.PRIMITIVE_ROOT, r, core.MOD),
                "center_log": state[1],
                "center_residue": pow(core.PRIMITIVE_ROOT, state[1], core.MOD),
                "divisor_set_size": state[0].bit_count(),
                "divisor_logs": [a for a in range(core.N) if (state[0] >> a) & 1],
                "type_i_log": core.TYPE_I,
                "type_ii_log": core.type_ii(state[1]),
                "finite_targets": len(targets),
                "finite_target_primes": sorted(targets),
                "capture_by_shift": capture,
                "singleton_eliminators": [
                    k for k in corridor.PRIOR if targets and targets <= hits[k]
                ],
                "minimum_finite_cover_size": len(covers[0]) if targets and covers else None,
                "all_minimum_finite_covers": covers if targets else [],
            }
            rows.append(row)

    realized = [row for row in rows if row["finite_targets"]]
    hard_core = [row for row in realized if row["minimum_finite_cover_size"] == 4]
    min_hist = Counter(row["minimum_finite_cover_size"] for row in realized)
    target_hist = Counter()
    for row in realized:
        target_hist[row["minimum_finite_cover_size"]] += row["finite_targets"]

    if len(realized) != 62:
        raise SystemExit(f"10M regression expected 62 realized states, got {len(realized)}")
    if dict(sorted(min_hist.items())) != {1: 35, 2: 9, 3: 11, 4: 7}:
        raise SystemExit(f"state minimum-cover histogram changed: {dict(sorted(min_hist.items()))}")
    if sum(row["finite_targets"] for row in realized) != base["negative_legendre_k47_misses"]:
        raise SystemExit("state target counts do not sum to the finite k47 negative-miss target set")
    if len(hard_core) != 7 or sum(row["finite_targets"] for row in hard_core) != 231:
        raise SystemExit("seven-state finite hard-core regression changed")

    return {
        "analysis": "k47-negative-legendre-exact-state-refinement-v1",
        "hi": hi,
        "hard_universe": base["hard_universe"],
        "negative_legendre_k47_misses": base["negative_legendre_k47_misses"],
        "abstract_negative_miss_states": 80,
        "realized_abstract_states": len(realized),
        "unrealized_abstract_states": 80 - len(realized),
        "realized_state_minimum_cover_histogram": {
            str(k): v for k, v in sorted(min_hist.items())
        },
        "targets_by_state_minimum_cover_size": {
            str(k): v for k, v in sorted(target_hist.items())
        },
        "states_with_cover_size_at_most_3": sum(
            1 for row in realized if row["minimum_finite_cover_size"] <= 3
        ),
        "targets_in_states_with_cover_size_at_most_3": sum(
            row["finite_targets"]
            for row in realized
            if row["minimum_finite_cover_size"] <= 3
        ),
        "four_shift_hard_core_state_count": len(hard_core),
        "four_shift_hard_core_target_count": sum(row["finite_targets"] for row in hard_core),
        "four_shift_hard_core_state_ids": [row["state_id"] for row in hard_core],
        "rows": rows,
        "claim": (
            "exact abstract fixed-k47 state partition plus complete finite 10M relation census; "
            "minimum earlier-shift covers remain finite evidence, not universal theorems"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("relations", type=Path)
    ap.add_argument("--hi", type=int, required=True)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze(args.relations, args.hi)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"negative-character k47 misses: {report['negative_legendre_k47_misses']}")
        print(
            f"realized abstract states: {report['realized_abstract_states']}/"
            f"{report['abstract_negative_miss_states']}"
        )
        print(f"state min-cover histogram: {report['realized_state_minimum_cover_histogram']}")
        print(
            f"four-shift hard core: {report['four_shift_hard_core_state_count']} states / "
            f"{report['four_shift_hard_core_target_count']} targets"
        )
        print("warning: finite theorem-mining evidence only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
