#!/usr/bin/env python3
"""Verify the exact factor-residue shape of the k=47 state r7-s02.

The state transition enlarges the signed-box mask monotonically. Therefore any
valuation-unit sequence ending at a target state must stay inside the target
mask at every intermediate step. We enumerate that finite constrained graph
from the universally forced 2*3 seed.

Result: r7-s02 is reached nontrivially only by adding exactly one log-7 unit;
log-0 units may be inserted arbitrarily because they are state-neutral. In
ordinary residues this means

    C47 = 6 * q * S,
    q prime, q == 11 (mod 47), v_q(C47)=1,
    every prime divisor of S == 1 (mod 47),
    v_2(C47)=v_3(C47)=1.

The script also locks in an explicit S>1 prime example so the stronger but
false finite guess C47=6q cannot silently reappear.
"""
from __future__ import annotations

import json
from collections import defaultdict, deque

import analyze_k47_negative_corridor as corridor
import analyze_k47_negative_states as states
import classify_k47_forced6_states as hard
import classify_k47_states as core

STATE_ID = "r7-s02"
DIRECTION = 7
EXAMPLE = {
    "p": 537_647_881,
    "q": 79_159,
    "S": 283,
}


def constrained_graph(target: tuple[int, int]):
    start = hard.forced_start()
    target_mask = target[0]
    seen = {start}
    q = deque([start])
    edges: dict[tuple[int, int], list[tuple[int, tuple[int, int]]]] = defaultdict(list)
    reverse: dict[tuple[int, int], list[tuple[tuple[int, int], int]]] = defaultdict(list)

    while q:
        state = q.popleft()
        for a in range(core.N):
            nxt = core.transition(state, a)
            if nxt[0] & ~target_mask:
                continue
            edges[state].append((a, nxt))
            reverse[nxt].append((state, a))
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen, edges, reverse


def reverse_reachable(target, reverse):
    seen = {target}
    q = deque([target])
    while q:
        state = q.popleft()
        for prev, _a in reverse.get(state, []):
            if prev not in seen:
                seen.add(prev)
                q.append(prev)
    return seen


def analyze() -> dict:
    state_direction, state_id, _by_direction = states.abstract_state_partition()
    target = next(state for state, sid in state_id.items() if sid == STATE_ID)
    expected = core.transition(hard.forced_start(), DIRECTION)
    if target != expected:
        raise SystemExit(f"{STATE_ID} is no longer forced-start + direction {DIRECTION}")
    if state_direction[target] != DIRECTION:
        raise SystemExit(f"{STATE_ID} direction changed")
    if not core.is_miss(target) or target[1] % 2 != 1:
        raise SystemExit(f"{STATE_ID} is no longer a negative-character combined miss")

    seen, edges, reverse = constrained_graph(target)
    can_reach = reverse_reachable(target, reverse)
    start = hard.forced_start()
    productive = seen & can_reach

    productive_nonzero_edges = []
    for state in productive:
        for a, nxt in edges[state]:
            if nxt in productive and a != 0:
                productive_nonzero_edges.append((state, a, nxt))

    # The only productive nonzero transition is forced_start --7--> target.
    if productive != {start, target}:
        raise SystemExit(f"unexpected productive constrained states: {productive}")
    if productive_nonzero_edges != [(start, DIRECTION, target)]:
        raise SystemExit(f"unexpected productive nonzero edges: {productive_nonzero_edges}")
    if core.transition(target, 0) != target or core.transition(start, 0) != start:
        raise SystemExit("log-0 valuation unit is no longer state-neutral")

    # No extra 2 or 3 valuation can occur in this exact state.
    if core.LOG[2] == 0 or core.LOG[3] == 0:
        raise SystemExit("unexpected zero log for forced factor")
    if core.transition(start, core.LOG[2]) == target:
        raise SystemExit("extra factor 2 unexpectedly realizes target state")
    if core.transition(start, core.LOG[3]) == target:
        raise SystemExit("extra factor 3 unexpectedly realizes target state")

    # State center fixes C47 mod 47 and therefore p mod 47.
    c47_residue = pow(core.PRIMITIVE_ROOT, target[1], core.MOD)
    p_residue47 = (4 * c47_residue) % core.MOD
    if c47_residue != 19 or p_residue47 != 29:
        raise SystemExit(
            f"r7-s02 residue regression changed: C47={c47_residue}, p={p_residue47} mod47"
        )

    # Combine p == 1 mod840 with p == 29 mod47.
    p_residue39480 = next(
        r for r in range(1, 840 * 47 + 1, 840) if r % 47 == p_residue47
    )
    if p_residue39480 != 9241:
        raise SystemExit(f"CRT residue changed: {p_residue39480}")

    # Explicit S>1 regression against the false stronger guess C47=6q.
    p = EXAMPLE["p"]
    qprime = EXAMPLE["q"]
    S = EXAMPLE["S"]
    if not corridor.is_prime64(p) or not corridor.is_prime64(qprime) or not corridor.is_prime64(S):
        raise SystemExit("S>1 regression example primality changed")
    if qprime % 47 != 11 or S % 47 != 1:
        raise SystemExit("S>1 regression factor residues changed")
    if p % 840 != 1 or p % 47 != 29:
        raise SystemExit("S>1 regression prime residue changed")
    if (p + 47) // 4 != 6 * qprime * S:
        raise SystemExit("S>1 regression factor identity changed")
    example_state, factors = corridor.k47_state_from_prime(p)
    if example_state != target or not core.is_miss(example_state):
        raise SystemExit("S>1 example no longer realizes r7-s02 miss state")

    return {
        "analysis": "k47-r7-s02-factor-shape-v1",
        "state_id": STATE_ID,
        "direction_log": DIRECTION,
        "direction_residue_mod47": pow(core.PRIMITIVE_ROOT, DIRECTION, core.MOD),
        "target_center_log": target[1],
        "target_center_residue_mod47": c47_residue,
        "target_divisor_set_size": target[0].bit_count(),
        "constrained_states_inside_target_mask": len(seen),
        "productive_states_to_target": len(productive),
        "productive_nonzero_transition_logs": [DIRECTION],
        "neutral_transition_logs": [0],
        "factor_shape": {
            "forced_v2": 1,
            "forced_v3": 1,
            "exactly_one_prime_factor_residue_mod47": 11,
            "that_factor_total_valuation": 1,
            "all_other_prime_factor_residues_mod47": 1,
        },
        "p_residue_mod47": p_residue47,
        "hard_cell_p_residue_mod840": 1,
        "hard_cell_p_residue_mod39480": p_residue39480,
        "hard_cell_C47_over6_residue_mod1645": 387,
        "s_gt_1_regression_example": {
            **EXAMPLE,
            "C47": (p + 47) // 4,
            "factorization": factors,
        },
        "claim": (
            "exact finite-state factor-residue shape at fixed k=47; hard-cell CRT is universal "
            "conditional on p mod840=1; S>1 example is finite existence evidence"
        ),
    }


def main() -> int:
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("k=47 r7-s02 exact factor-residue shape")
        print(f"productive nonzero logs: {report['productive_nonzero_transition_logs']}")
        print(f"p mod47: {report['p_residue_mod47']}")
        print(f"hard-cell p mod39480: {report['hard_cell_p_residue_mod39480']}")
        print(f"S>1 example: {report['s_gt_1_regression_example']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
