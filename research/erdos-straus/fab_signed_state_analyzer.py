#!/usr/bin/env python3
"""Finite-state analyzer for bounded signed divisor sets modulo m.

A prime factor occurrence with residue r updates the signed-reach set S by
S -> S * {r^-1,1,r}. Repeating an occurrence e times is exactly equivalent to
allowing a signed valuation z in [-e,e]. Therefore the reachable automaton is
an exact abstraction of residue-factor multisets, not a heuristic.

The default report classifies reciprocal-lane failure states:
  total product = 4^-1 mod m
  forbidden signed target = -1 mod m

Use only modest m. State spaces can grow rapidly.
"""

from __future__ import annotations

import argparse
import json
import math
from collections import deque
from pathlib import Path


def units(m: int) -> list[int]:
    return [r for r in range(1, m) if math.gcd(r, m) == 1]


def transition(m: int, state: tuple[int, frozenset[int]], r: int) -> tuple[int, frozenset[int]]:
    product, signed = state
    rinv = pow(r, -1, m)
    reached = frozenset(
        (s * x) % m
        for s in signed
        for x in (rinv, 1, r)
    )
    return (product * r) % m, reached


def recover_sequence(
    state: tuple[int, frozenset[int]],
    parent: dict[tuple[int, frozenset[int]], tuple[tuple[int, frozenset[int]], int]],
) -> list[int]:
    out: list[int] = []
    while state in parent:
        prev, r = parent[state]
        out.append(r)
        state = prev
    out.reverse()
    return out


def analyze(m: int, state_cap: int) -> dict:
    if m <= 1 or m % 2 == 0:
        raise SystemExit("m must be odd and >1")

    us = units(m)
    start = (1 % m, frozenset({1 % m}))
    seen = {start}
    parent: dict[tuple[int, frozenset[int]], tuple[tuple[int, frozenset[int]], int]] = {}
    queue = deque([start])

    while queue:
        state = queue.popleft()
        for r in us:
            nxt = transition(m, state, r)
            if nxt in seen:
                continue
            seen.add(nxt)
            parent[nxt] = (state, r)
            queue.append(nxt)
            if len(seen) > state_cap:
                raise SystemExit(
                    f"state cap exceeded ({state_cap}); choose a smaller m or larger --state-cap"
                )

    total_target = pow(4, -1, m)
    signed_target = (-1) % m

    failures = [
        state
        for state in seen
        if state[0] == total_target and signed_target not in state[1]
    ]
    failures.sort(key=lambda st: (len(st[1]), tuple(sorted(st[1]))))

    rows = []
    for state in failures:
        product, signed = state
        keep_bad = []
        for r in us:
            nxt = transition(m, state, r)
            if signed_target not in nxt[1]:
                keep_bad.append(r)

        rows.append(
            {
                "product": product,
                "signed_reach": sorted(signed),
                "minimal_factor_residue_sequence": recover_sequence(state, parent),
                "residues_that_preserve_target_avoidance_for_one_more_occurrence": keep_bad,
            }
        )

    return {
        "schema": 1,
        "m": m,
        "unit_count": len(us),
        "reachable_state_count": len(seen),
        "reciprocal_total_product": total_target,
        "reciprocal_signed_target": signed_target,
        "reciprocal_failure_state_count": len(rows),
        "reciprocal_failure_states": rows,
        "meaning": (
            "Exact automaton over residue-factor occurrences. A failure state has the "
            "forced reciprocal total residue 4^-1 but its bounded signed divisor set "
            "does not contain -1."
        ),
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--m", type=int, required=True)
    ap.add_argument("--state-cap", type=int, default=1_000_000)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    report = analyze(args.m, args.state_cap)
    text = json.dumps(report, indent=2, sort_keys=True)
    print(text)

    if args.out is not None:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n")


if __name__ == "__main__":
    main()
