#!/usr/bin/env python3
"""Apply the landed k23 incoming-source repulsion theorem to recursive states."""
from __future__ import annotations

import argparse
import json
from collections import Counter, deque

from classify_recursive_character_promotion import (
    BASE_SOURCES,
    State,
    candidate_promotions,
    quadratic_residues,
    root_states,
    route_residue,
    state_key,
)

EXPECTED_REPELLING_SOURCE_CLASSES = (
    (121, 13, 0, 3),
    (121, 59, 2, 36),
    (121, 71, 2, 48),
    (169, 13, 2, 3),
    (169, 71, 1, 48),
    (169, 167, 2, 144),
    (289, 13, 0, 3),
    (289, 71, 1, 48),
)


def closure_states(max_k: int, max_sources: int) -> list[State]:
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
    states = closure_states(max_k, max_sources)
    qr23 = quadratic_residues(23)
    opportunities = []
    minimum: dict[tuple[int, int], tuple[int, int, State]] = {}

    for state in states:
        fixed = state.residue_map()
        for q in state.derived_sources:
            if q == 23 or q % 23 == 1 or q % 23 not in qr23:
                continue
            required_p_mod_q = route_residue(q, state.hard_class, 23, fixed)
            if required_p_mod_q is None:
                continue

            row = {
                "hard_class": state.hard_class,
                "source_prime": q,
                "source_mod_23": q % 23,
                "required_p_mod_source": required_p_mod_q,
                "state_depth": state.depth,
                "required_misses": list(state.required_misses),
                "path": list(state.path),
            }
            opportunities.append(row)

            key = (state.hard_class, q)
            prior = minimum.get(key)
            if prior is None or state.depth < prior[0]:
                minimum[key] = (state.depth, required_p_mod_q, state)

    pinned = tuple(sorted(
        (h, q, depth, residue)
        for (h, q), (depth, residue, _state) in minimum.items()
    ))
    if pinned != EXPECTED_REPELLING_SOURCE_CLASSES:
        raise SystemExit(f"recursive k23 repeller atlas changed: {pinned!r}")
    if len(states) != 70 or len(opportunities) != 31:
        raise SystemExit(
            f"recursive k23 opportunity counts changed: states={len(states)} "
            f"opportunities={len(opportunities)}"
        )

    return {
        "analysis": "recursive-k23-incoming-source-repulsion-v1",
        "reachable_recursive_states": len(states),
        "state_source_repulsion_opportunities": len(opportunities),
        "opportunity_depth_histogram": dict(sorted(Counter(
            int(row["state_depth"]) for row in opportunities
        ).items())),
        "repelling_source_class_count": len(pinned),
        "repelling_source_classes": [
            {
                "hard_class": h,
                "source_prime": q,
                "minimum_state_depth": depth,
                "required_p_mod_source_to_route_into_C23": residue,
                "source_mod_23": q % 23,
                "eliminated_k23_centers": [5, 14],
                "example_path": list(minimum[(h, q)][2].path),
            }
            for h, q, depth, residue in pinned
        ],
        "claim": (
            "applying the landed incoming-positive-source repulsion theorem to the "
            "provenance-preserving recursive closure identifies the exact recursive "
            "source classes whose compatible route into C23 eliminates both negative "
            "k23 miss centers"
        ),
        "claim_boundary": (
            "conditional branch pruning only; no claim that every survivor takes one "
            "of these exact source-route residues"
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
        print(f"recursive states: {report['reachable_recursive_states']}")
        print(f"repulsion opportunities: {report['state_source_repulsion_opportunities']}")
        print(f"repelling source classes: {report['repelling_source_class_count']}")
        for row in report["repelling_source_classes"]:
            print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
