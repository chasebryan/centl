#!/usr/bin/env python3
"""Direction-resolved finite theorem mining for negative-Legendre k=47 misses.

Consumes a CBX standalone hit-relation TSV and refines the finite set of hard
primes that miss k=47 with (47/p)=-1 by their exact forced-6 one-packet state
class. Compatibility is deliberately represented as a set, even though the
abstract regression currently proves that the 80 negative-character miss
states split disjointly across the eleven one-packet directions.

No finite cover is promoted to a universal theorem.
"""
from __future__ import annotations

import argparse
import itertools
import json
from collections import Counter, defaultdict, deque
from pathlib import Path

import classify_k47_forced6_states as hard
import classify_k47_states as core

# Earlier companion shifts P+1,...,P+10. k=43 is intentionally excluded:
# the observed negative-character k=47 hole is already empty by k=39.
PRIOR = (3, 7, 11, 15, 19, 23, 27, 31, 35, 39)
ONE_PACKET_DIRECTIONS = (1, 7, 9, 11, 17, 19, 27, 29, 35, 37, 45)
QR_DIRECTIONS = tuple(range(0, core.N, 2))
EXPECTED_ABSTRACT_DIRECTION_COUNTS = {
    1: 7,
    7: 2,
    9: 13,
    11: 3,
    17: 6,
    19: 10,
    27: 11,
    29: 3,
    35: 3,
    37: 13,
    45: 9,
}


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
    return p % 47 != 0 and pow(p % 47, 23, 47) == 46


def closure_from(start: tuple[int, int], directions) -> set[tuple[int, int]]:
    seen = {start}
    q = deque([start])
    while q:
        state = q.popleft()
        for a in directions:
            nxt = core.transition(state, a)
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return seen


def one_packet_closures() -> dict[int, set[tuple[int, int]]]:
    seed = hard.forced_start()
    return {
        r: closure_from(core.transition(seed, r), QR_DIRECTIONS)
        for r in ONE_PACKET_DIRECTIONS
    }


def abstract_direction_regression(
    closures: dict[int, set[tuple[int, int]]] | None = None,
) -> dict:
    if closures is None:
        closures = one_packet_closures()
    negative_misses = {
        state
        for state in hard.closure()
        if core.is_miss(state) and state[1] % 2 == 1
    }
    if len(negative_misses) != 80:
        raise SystemExit(
            f"expected 80 negative-character hard miss states, got {len(negative_misses)}"
        )

    compatible: dict[tuple[int, int], tuple[int, ...]] = {
        state: tuple(r for r in ONE_PACKET_DIRECTIONS if state in closures[r])
        for state in negative_misses
    }
    uncovered = [state for state, dirs in compatible.items() if not dirs]
    if uncovered:
        raise SystemExit(f"one-packet closures left {len(uncovered)} abstract misses uncovered")

    multiplicity = Counter(len(dirs) for dirs in compatible.values())
    if multiplicity != Counter({1: 80}):
        raise SystemExit(
            "one-packet direction classes are no longer disjoint on the 80 abstract misses: "
            f"{dict(sorted(multiplicity.items()))}"
        )

    counts = {
        r: sum(1 for dirs in compatible.values() if r in dirs)
        for r in ONE_PACKET_DIRECTIONS
    }
    if counts != EXPECTED_ABSTRACT_DIRECTION_COUNTS:
        raise SystemExit(
            "abstract one-packet direction counts changed: "
            f"{counts!r} != {EXPECTED_ABSTRACT_DIRECTION_COUNTS!r}"
        )

    return {
        "negative_character_hard_miss_states": len(negative_misses),
        "compatibility_multiplicity_histogram": dict(sorted(multiplicity.items())),
        "direction_state_counts": {str(r): counts[r] for r in ONE_PACKET_DIRECTIONS},
        "direction_classes_disjoint": True,
        "direction_union_complete": True,
    }


def factor_integer(n: int) -> list[tuple[int, int]]:
    if n < 1:
        raise ValueError("factor_integer expects n >= 1")
    out: list[tuple[int, int]] = []
    e = 0
    while n % 2 == 0:
        n //= 2
        e += 1
    if e:
        out.append((2, e))
    d = 3
    while d * d <= n:
        e = 0
        while n % d == 0:
            n //= d
            e += 1
        if e:
            out.append((d, e))
        d += 2
    if n > 1:
        out.append((n, 1))
    return out


def k47_state_from_prime(p: int) -> tuple[tuple[int, int], list[tuple[int, int]]]:
    if p % 4 != 1:
        raise SystemExit(f"target p={p} is not 1 mod 4")
    c47 = (p + 47) // 4
    factors = factor_integer(c47)
    state = (1, 0)
    for q, e in factors:
        residue = q % core.MOD
        if residue == 0:
            raise SystemExit(f"C47 for p={p} contains factor 47, outside unit-state model")
        try:
            a = core.LOG[residue]
        except KeyError as exc:
            raise SystemExit(f"no base-5 log for factor residue {residue} mod47") from exc
        for _ in range(e):
            state = core.transition(state, a)
    return state, factors


def exact_minimum_covers(
    targets: set[int], hits: dict[int, set[int]], shifts=PRIOR
) -> list[list[int]]:
    if not targets:
        return [[]]
    for size in range(1, len(shifts) + 1):
        covers = [
            list(comb)
            for comb in itertools.combinations(shifts, size)
            if targets <= set().union(*(hits[k] for k in comb))
        ]
        if covers:
            return covers
    return []


def pair_eliminators(targets: set[int], hits: dict[int, set[int]]) -> list[list[int]]:
    if not targets:
        return []
    return [
        list(comb)
        for comb in itertools.combinations(PRIOR, 2)
        if targets <= (hits[comb[0]] | hits[comb[1]])
    ]


def ordered_residual(targets: set[int], hits: dict[int, set[int]]) -> list[dict]:
    remaining = set(targets)
    rows = []
    for k in PRIOR:
        before = len(remaining)
        caught = remaining & hits[k]
        remaining -= caught
        rows.append({
            "k": k,
            "before": before,
            "newly_caught": len(caught),
            "after": len(remaining),
        })
    return rows


def finite_direction_matrix(
    target: set[int],
    hits: dict[int, set[int]],
    closures: dict[int, set[tuple[int, int]]],
) -> dict:
    hard_states = hard.closure()
    compatibility: dict[int, tuple[int, ...]] = {}

    for p in sorted(target):
        if p % 24 != 1:
            raise SystemExit(f"target p={p} violates hard-prime p == 1 (mod 24)")
        state, _factors = k47_state_from_prime(p)
        if state not in hard_states:
            raise SystemExit(f"p={p}: reconstructed k47 state is outside forced-6 closure")
        if not core.is_miss(state):
            raise SystemExit(f"p={p}: relation says k47 miss but reconstructed state is a hit")
        if state[1] % 2 != 1:
            raise SystemExit(f"p={p}: expected negative-character odd center, got {state[1]}")
        dirs = tuple(r for r in ONE_PACKET_DIRECTIONS if state in closures[r])
        if not dirs:
            raise SystemExit(f"p={p}: exact state has no compatible one-packet direction")
        compatibility[p] = dirs

    multiplicity = Counter(len(dirs) for dirs in compatibility.values())
    per_direction = []
    for r in ONE_PACKET_DIRECTIONS:
        members = {p for p, dirs in compatibility.items() if r in dirs}
        min_covers = exact_minimum_covers(members, hits)
        singleton = [k for k in PRIOR if members and members <= hits[k]]
        pairs = pair_eliminators(members, hits)
        capture = [
            {
                "k": k,
                "caught": len(members & hits[k]),
                "left": len(members - hits[k]),
            }
            for k in PRIOR
        ]
        per_direction.append({
            "log_direction": r,
            "residue_mod47": pow(core.PRIMITIVE_ROOT, r, core.MOD),
            "abstract_miss_state_count": EXPECTED_ABSTRACT_DIRECTION_COUNTS[r],
            "finite_compatible_targets": len(members),
            "finite_target_primes": sorted(members),
            "capture_by_shift": capture,
            "ordered_residual": ordered_residual(members, hits),
            "singleton_eliminators": singleton,
            "pair_eliminators": pairs,
            "minimum_finite_cover_size": len(min_covers[0]) if min_covers else None,
            "all_minimum_finite_covers": min_covers,
        })

    return {
        "compatibility_multiplicity_histogram": dict(sorted(multiplicity.items())),
        "compatible_directions_by_prime": {
            str(p): list(dirs) for p, dirs in sorted(compatibility.items())
        },
        "finite_direction_counts": {
            str(r): sum(1 for dirs in compatibility.values() if r in dirs)
            for r in ONE_PACKET_DIRECTIONS
        },
        "directions": per_direction,
    }


def analyze(path: Path, hi: int | None):
    hits, universe = load(path, hi)
    if 47 not in hits:
        raise SystemExit("relation file has no k=47 rows")
    for k in PRIOR:
        if k not in hits:
            raise SystemExit(f"relation file has no k={k} rows")

    closures = one_packet_closures()
    abstract = abstract_direction_regression(closures)

    target = {p for p in universe if p not in hits[47] and legendre47_negative(p)}
    first = Counter()
    for p in target:
        earlier = [k for k in PRIOR if p in hits[k]]
        first[str(min(earlier)) if earlier else "none"] += 1

    residual_rows = ordered_residual(target, hits)
    remaining = target - set().union(*(hits[k] for k in PRIOR))
    global_covers = exact_minimum_covers(target, hits)
    matrix = finite_direction_matrix(target, hits, closures)

    # The interface stays set-valued. The assertion below is a theorem-level
    # regression inherited from the exact abstract 80-state partition.
    if matrix["compatibility_multiplicity_histogram"] != {1: len(target)}:
        raise SystemExit(
            "finite compatibility multiplicity disagrees with abstract disjoint partition: "
            f"{matrix['compatibility_multiplicity_histogram']}"
        )

    return {
        "analysis": "k47-negative-legendre-direction-matrix-v2",
        "hi": hi,
        "hard_universe_from_relation_union": len(universe),
        "negative_legendre_k47_misses": len(target),
        "finite_target_primes": sorted(target),
        "one_packet_log_directions": list(ONE_PACKET_DIRECTIONS),
        "abstract_direction_regression": abstract,
        "first_prior_hit_histogram": dict(
            sorted(
                first.items(),
                key=lambda kv: (
                    kv[0] == "none",
                    int(kv[0]) if kv[0] != "none" else 10**9,
                ),
            )
        ),
        "ordered_residual": residual_rows,
        "residual_after_prior_corridor": len(remaining),
        "minimum_finite_cover_size": len(global_covers[0]) if global_covers else None,
        "all_minimum_finite_covers": global_covers,
        "direction_matrix": matrix,
        "claim": (
            "exact finite relation-set and exact fixed-k47 state analysis only; "
            "no universal cross-shift containment theorem"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("relations", nargs="?", type=Path)
    ap.add_argument("--hi", type=int)
    ap.add_argument("--json", action="store_true")
    ap.add_argument(
        "--self-test",
        action="store_true",
        help="run the exact 80-state one-packet partition regression without a relation TSV",
    )
    args = ap.parse_args()

    if args.self_test:
        report = {
            "analysis": "k47-one-packet-abstract-regression-v1",
            **abstract_direction_regression(),
        }
    else:
        if args.relations is None:
            ap.error("relations is required unless --self-test is used")
        report = analyze(args.relations, args.hi)

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    elif args.self_test:
        print("k=47 one-packet abstract regression")
        print(f"negative miss states: {report['negative_character_hard_miss_states']}")
        print(f"multiplicity: {report['compatibility_multiplicity_histogram']}")
        print(f"direction counts: {report['direction_state_counts']}")
    else:
        print(f"negative-Legendre k47 misses: {report['negative_legendre_k47_misses']}")
        print(f"direction counts: {report['direction_matrix']['finite_direction_counts']}")
        for row in report["ordered_residual"]:
            print(f"k={row['k']}: {row['before']} -> {row['after']} (caught {row['newly_caught']})")
        print(f"minimum finite covers: {report['all_minimum_finite_covers']}")
        print("warning: finite theorem-mining evidence only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
