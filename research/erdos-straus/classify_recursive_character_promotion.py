#!/usr/bin/env python3
"""Provenance-aware recursive QR/Jacobi character-promotion closure."""
from __future__ import annotations

import argparse
import functools
import itertools
import json
import math
from collections import Counter, deque
from dataclasses import dataclass

HARD_CLASSES = (1, 121, 169, 289, 361, 529)
BASE_SOURCES = {
    1: (7, 23),
    121: (7, 19, 23, 47),
    169: (7, 11, 23, 31),
    289: (7, 11, 23, 31, 47),
    361: (7, 23, 59),
    529: (7, 11, 23, 31),
}

# Exact positive-character extractions already proved by
# JACOBI-SATURATION-CHARACTER-EXTRACTION.md.
# (hard class, parent composite miss, routed sources, exact source residues,
#  extracted positive-character prime)
ROOT_EXTRACTIONS = (
    (121, 39, (47,), (8,), 13),
    (169, 51, (11, 23), (4, 18), 17),
    (169, 111, (23,), (4,), 37),
    (289, 39, (11, 47), (5, 8), 13),
    (289, 51, (11, 23), (4, 18), 17),
    (289, 215, (11, 31), (5, 2), 43),
    (529, 51, (11, 23), (4, 18), 17),
    (529, 171, (11, 23), (5, 13), 19),
)

EXPECTED_NEW_SOURCE_CLASSES = (
    (121, 11, 2),
    (121, 53, 1),
    (121, 59, 2),
    (121, 71, 2),
    (121, 79, 1),
    (169, 13, 2),
    (169, 19, 1),
    (169, 71, 1),
    (169, 83, 1),
    (169, 167, 2),
    (289, 19, 1),
    (289, 71, 1),
    (289, 191, 1),
)


@dataclass(frozen=True)
class State:
    hard_class: int
    residues: tuple[tuple[int, int], ...]
    derived_sources: tuple[int, ...]
    required_misses: tuple[int, ...]
    depth: int
    path: tuple[str, ...]

    def residue_map(self) -> dict[int, int]:
        return dict(self.residues)


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
def factorization_tuple(n: int) -> tuple[tuple[int, int], ...]:
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
    for q, e in factorization_tuple(seed):
        powers = [pow(q, j, k) for j in range(2 * e + 1)]
        residues = {a * b % k for a in residues for b in powers}
    return frozenset(residues)


@functools.lru_cache(maxsize=None)
def quadratic_residues(q: int) -> frozenset[int]:
    return frozenset(x * x % q for x in range(1, q))


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError(n)
    a %= n
    result = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                result = -result
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            result = -result
        a %= n
    return result if n == 1 else 0


@functools.lru_cache(maxsize=None)
def jacobi_kernel(k: int) -> frozenset[int]:
    return frozenset(
        u for u in range(1, k)
        if math.gcd(u, k) == 1 and jacobi(u, k) == 1
    )


@functools.lru_cache(maxsize=None)
def qr_saturates(seed: int, k: int) -> bool:
    return (
        is_prime(k)
        and k % 4 == 3
        and math.gcd(seed, k) == 1
        and divisor_square_residues(seed, k) == quadratic_residues(k)
    )


@functools.lru_cache(maxsize=None)
def jacobi_saturates(seed: int, k: int) -> bool:
    return (
        not is_prime(k)
        and k % 4 == 3
        and math.gcd(seed, k) == 1
        and divisor_square_residues(seed, k) == jacobi_kernel(k)
    )


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def unknown_hard_character_factor(k: int) -> int | None:
    unknown = [
        q for q, e in factorization_tuple(k)
        if e % 2 == 1 and 840 % q != 0
    ]
    return unknown[0] if len(unknown) == 1 else None


def fixed_hard_character_product(h: int, k: int, unknown: int) -> int:
    product = 1
    for q, e in factorization_tuple(k):
        if e % 2 == 0 or q == unknown:
            continue
        if 840 % q != 0:
            raise RuntimeError((h, k, unknown, q))
        v = pow(h % q, (q - 1) // 2, q)
        product *= -1 if v == q - 1 else 1
    return product


def route_residue(q: int, h: int, k: int, fixed: dict[int, int]) -> int | None:
    r = (-k) % q
    if r == 0:
        return None
    if q in fixed:
        return r if fixed[q] == r else None
    if q == 7:
        return r if r == h % 7 else None
    return r if r in quadratic_residues(q) else None


def state_key(state: State) -> tuple[object, ...]:
    # Canonicalize by arithmetic information. Breadth-first traversal keeps the
    # first path, hence one shortest proof ancestry, when equivalent arithmetic
    # states are reached in more than one way.
    return (state.hard_class, state.residues, state.derived_sources)


def root_states() -> list[State]:
    out = []
    for h, parent, sources, residues, extracted in ROOT_EXTRACTIONS:
        out.append(State(
            hard_class=h,
            residues=tuple(sorted(zip(sources, residues))),
            derived_sources=(extracted,),
            required_misses=(parent,),
            depth=0,
            path=(f"k{parent} miss extracts q{extracted}",),
        ))
    return out


def candidate_promotions(
    state: State,
    max_k: int,
    max_sources: int,
) -> list[dict[str, object]]:
    h = state.hard_class
    fixed = state.residue_map()
    derived = set(state.derived_sources)
    positives = tuple(sorted(set(BASE_SOURCES[h]) | derived))
    rows: list[dict[str, object]] = []

    for arity in range(1, max_sources + 1):
        for sources in itertools.combinations(positives, arity):
            # Base-only route combinations belong to the already-landed atlas.
            if not derived.intersection(sources):
                continue

            for k in range(3, max_k + 1, 4):
                if k in sources:
                    continue

                residues = []
                for q in sources:
                    r = route_residue(q, h, k, fixed)
                    if r is None:
                        break
                    residues.append(r)
                else:
                    base = class_seed(k, h)
                    seed = math.lcm(base, *sources)

                    if is_prime(k):
                        if qr_saturates(base, k) or not qr_saturates(seed, k):
                            continue
                        if arity > 1 and any(
                            qr_saturates(math.lcm(base, *subset), k)
                            for size in range(1, arity)
                            for subset in itertools.combinations(sources, size)
                        ):
                            continue
                        promoted = k
                        kind = "prime-qr"
                    else:
                        if (
                            math.gcd(base, k) != 1
                            or jacobi_saturates(base, k)
                            or not jacobi_saturates(seed, k)
                        ):
                            continue
                        if arity > 1 and any(
                            jacobi_saturates(math.lcm(base, *subset), k)
                            for size in range(1, arity)
                            for subset in itertools.combinations(sources, size)
                        ):
                            continue
                        promoted = unknown_hard_character_factor(k)
                        if promoted is None:
                            continue
                        if fixed_hard_character_product(h, k, promoted) != 1:
                            continue
                        kind = "composite-jacobi"

                    new_fixed = dict(fixed)
                    for q, r in zip(sources, residues):
                        new_fixed[q] = r
                    rows.append({
                        "kind": kind,
                        "sources": sources,
                        "destination_k": k,
                        "required_source_residues": tuple(residues),
                        "base_seed": base,
                        "routed_seed": seed,
                        "promoted_prime": promoted,
                        "new_residues": tuple(sorted(new_fixed.items())),
                    })
    return rows


def analyze(max_k: int, max_sources: int) -> dict[str, object]:
    if max_sources != 2:
        raise SystemExit("this pinned v1 atlas is defined for source arity <=2")

    roots = root_states()
    queue: deque[State] = deque(roots)
    seen = {state_key(state) for state in roots}
    states = list(roots)
    edges: list[dict[str, object]] = []

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
                required_misses=tuple(sorted(set(state.required_misses) | {int(row["destination_k"])})),
                depth=state.depth + 1,
                path=state.path + (
                    f"{row['kind']} {list(row['sources'])} -> k{row['destination_k']} extracts q{promoted}",
                ),
            )
            edge = {
                "parent_depth": state.depth,
                "hard_class": state.hard_class,
                "kind": row["kind"],
                "sources": list(row["sources"]),
                "destination_k": row["destination_k"],
                "required_source_residues": list(row["required_source_residues"]),
                "base_seed": row["base_seed"],
                "routed_seed": row["routed_seed"],
                "promoted_prime": promoted,
                "child_depth": child.depth,
            }
            edges.append(edge)

            key = state_key(child)
            if key not in seen:
                seen.add(key)
                states.append(child)
                queue.append(child)

    root_source_classes = {
        (h, q) for h, _parent, _sources, _residues, q in ROOT_EXTRACTIONS
    }
    root_source_classes |= {
        (h, q) for h, sources in BASE_SOURCES.items() for q in sources
    }

    min_depth: dict[tuple[int, int], int] = {}
    example_path: dict[tuple[int, int], tuple[str, ...]] = {}
    for state in states:
        for q in state.derived_sources:
            pair = (state.hard_class, q)
            if pair in root_source_classes:
                continue
            if pair not in min_depth or state.depth < min_depth[pair]:
                min_depth[pair] = state.depth
                example_path[pair] = state.path

    pinned = tuple(sorted((h, q, min_depth[(h, q)]) for h, q in min_depth))
    if pinned != EXPECTED_NEW_SOURCE_CLASSES:
        raise SystemExit(f"recursive source closure changed: {pinned!r}")
    if len(roots) != 8 or len(states) != 70 or len(edges) != 66:
        raise SystemExit(
            f"recursive state graph changed: roots={len(roots)} states={len(states)} edges={len(edges)}"
        )
    max_depth = max(state.depth for state in states)
    if max_depth != 5:
        raise SystemExit(f"recursive maximum path depth changed: {max_depth}")

    depth_hist = Counter(state.depth for state in states)
    expected_hist = {0: 8, 1: 15, 2: 20, 3: 14, 4: 10, 5: 3}
    if dict(sorted(depth_hist.items())) != expected_hist:
        raise SystemExit(f"recursive depth histogram changed: {dict(depth_hist)!r}")

    return {
        "analysis": "recursive-character-promotion-v1",
        "max_destination_k": max_k,
        "max_routed_source_arity": max_sources,
        "root_extraction_states": len(roots),
        "reachable_canonical_states": len(states),
        "promotion_edges": len(edges),
        "maximum_state_depth": max_depth,
        "state_depth_histogram": dict(sorted(depth_hist.items())),
        "new_source_class_count": len(pinned),
        "new_source_classes": [
            {
                "hard_class": h,
                "prime": q,
                "minimum_generation": depth,
                "example_path": list(example_path[(h, q)]),
            }
            for h, q, depth in pinned
        ],
        "promotion_edges_by_kind": dict(sorted(Counter(edge["kind"] for edge in edges).items())),
        "claim": (
            "finite provenance-preserving closure of the merged positive-character extraction roots "
            "under minimal one/two-source QR saturation at prime destinations and Jacobi saturation "
            "at composite destinations with one hard-class-extractable prime factor"
        ),
        "claim_boundary": (
            "finite mechanism closure through the configured destination bound; not a survivor cover, "
            "not a universal shift ceiling, and not an Erdős-Straus proof"
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
        print(f"canonical states: {report['reachable_canonical_states']}")
        print(f"promotion edges: {report['promotion_edges']}")
        print(f"new source classes: {report['new_source_class_count']}")
        for row in report["new_source_classes"]:
            print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
