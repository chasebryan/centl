#!/usr/bin/env python3
"""Branch-aware recursive Jacobi/QR saturation closure.

Scope:
- roots are the eight merged composite character-extraction branches;
- each root also carries the already-proved positive source characters for its
  hard class under the simultaneous-survivor hypothesis;
- every residue used to route a source is retained in the branch state;
- destinations are odd k=3 mod4 through a finite bound;
- exact mandatory divisor seeds are tested for Type-I hits and Jacobi-kernel
  saturation;
- routed subsets of size <=3 are enumerated exactly, and an all-compatible-
  sources maximal-seed check proves that no hidden larger subset qualifies.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
from collections import Counter
from dataclasses import dataclass
from functools import lru_cache

ROOTS = (
    ("h121-q13", 121, {47: 8}, 13),
    ("h169-q17", 169, {11: 4, 23: 18}, 17),
    ("h169-q37", 169, {23: 4}, 37),
    ("h289-q13", 289, {11: 5, 47: 8}, 13),
    ("h289-q17", 289, {11: 4, 23: 18}, 17),
    ("h289-q43", 289, {11: 5, 31: 2}, 43),
    ("h529-q17", 529, {11: 4, 23: 18}, 17),
    ("h529-q19", 529, {11: 5, 23: 13}, 19),
)

# Positive-character theorems already proved independently on these hard
# classes. q=7 is not listed because the hard residue class fixes p mod7
# exactly and the class-seed law already incorporates its routed factor.
GLOBAL_POSITIVE = {
    121: {19, 47},
    169: {11, 31},
    289: {11, 31, 47},
    529: {11, 31},
}

EXPECTED = {
    "roots": 8,
    "states": 259,
    "transitions": 2820,
    "known_plus": 2535,
    "extract_positive": 284,
    "product_constraints": 1,
    "type_i_hits": 0,
    "sign_hits": 0,
    "negative_extractions": 0,
    "max_depth": 7,
    "max_qualifying_destination": 971,
    "hidden_large_subset_qualifiers": 0,
}

EXPECTED_SOURCE_ALPHABET = {
    11, 13, 17, 19, 23, 29, 31, 37, 43, 47, 53, 71, 79,
    83, 107, 109, 127, 131, 151, 167, 191, 271, 383, 971,
}

EXPECTED_DESTINATIONS = {
    3, 7, 11, 15, 19, 23, 31, 35, 39, 47, 51, 55, 71, 79, 83,
    107, 109, 111, 127, 131, 151, 167, 171, 191, 215, 271, 383,
    551, 971,
}


@dataclass(frozen=True)
class State:
    hard_class: int
    fixed: tuple[tuple[int, int], ...]
    characters: tuple[tuple[int, int], ...]
    depth: int

    @property
    def key(self) -> tuple[object, ...]:
        return self.hard_class, self.fixed, self.characters


@lru_cache(maxsize=None)
def factorization(n: int) -> tuple[tuple[int, int], ...]:
    out: Counter[int] = Counter()
    q = 2
    x = n
    while q * q <= x:
        while x % q == 0:
            out[q] += 1
            x //= q
        q += 1 if q == 2 else 2
    if x > 1:
        out[x] += 1
    return tuple(sorted(out.items()))


def legendre_from_residue(residue: int, q: int) -> int:
    residue %= q
    if residue == 0:
        return 0
    value = pow(residue, (q - 1) // 2, q)
    return -1 if value == q - 1 else 1


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


@lru_cache(maxsize=None)
def jacobi_kernel(k: int) -> frozenset[int]:
    return frozenset(
        u for u in range(1, k)
        if math.gcd(u, k) == 1 and jacobi(u, k) == 1
    )


@lru_cache(maxsize=None)
def divisor_square_residues(seed: int, k: int) -> frozenset[int]:
    residues = {1}
    for q, exponent in factorization(seed):
        local = {pow(q, j, k) for j in range(2 * exponent + 1)}
        residues = {a * b % k for a in residues for b in local}
    return frozenset(residues)


def class_seed(k: int, hard_class: int) -> int:
    return math.gcd(210, (hard_class + k) // 4)


def route_possible(q: int, sign: int, k: int) -> bool:
    residue = (-k) % q
    return residue != 0 and legendre_from_residue(residue, q) == sign


def mandatory_seed(k: int, hard_class: int, fixed: dict[int, int]) -> int:
    seed = class_seed(k, hard_class)
    for q, residue in fixed.items():
        if (residue + k) % q == 0:
            seed = math.lcm(seed, q)
    return seed


def known_character(
    prime: int,
    hard_class: int,
    fixed: dict[int, int],
    characters: dict[int, int],
) -> int | None:
    if 840 % prime == 0:
        return legendre_from_residue(hard_class % prime, prime)
    if prime in fixed:
        return legendre_from_residue(fixed[prime], prime)
    return characters.get(prime)


def analyze_seed(
    k: int,
    seed: int,
    hard_class: int,
    fixed: dict[int, int],
    characters: dict[int, int],
) -> tuple[str | None, int | tuple[int, ...] | None, int | None]:
    """Return (outcome, extracted-or-product, sign).

    Outcomes:
    - type_i_hit
    - sign_hit
    - known_plus
    - extract
    - product
    - None
    """
    residues = divisor_square_residues(seed, k)
    type_i = (-pow(4, -1, k)) % k
    if type_i in residues:
        return "type_i_hit", None, None

    if residues != jacobi_kernel(k):
        return None, None, None

    known_product = 1
    unknown: list[int] = []
    for q, exponent in factorization(k):
        if exponent % 2 == 0:
            continue
        sign = known_character(q, hard_class, fixed, characters)
        if sign is None:
            unknown.append(q)
        else:
            known_product *= sign

    if not unknown:
        if known_product == -1:
            return "sign_hit", None, None
        return "known_plus", None, None
    if len(unknown) == 1:
        # A saturated miss forces Jacobi(k/p)=+1. Since signs are +/-1,
        # the unknown sign must equal the product of the known signs.
        return "extract", unknown[0], known_product
    return "product", tuple(unknown), known_product


def root_states() -> list[State]:
    states: list[State] = []
    for _, hard_class, fixed_map, extracted_q in ROOTS:
        chars = {q: 1 for q in GLOBAL_POSITIVE[hard_class]}
        for q, residue in fixed_map.items():
            sign = legendre_from_residue(residue, q)
            if sign != 1:
                raise RuntimeError((hard_class, q, residue, sign))
            chars[q] = 1
        chars[extracted_q] = 1
        states.append(
            State(
                hard_class=hard_class,
                fixed=tuple(sorted(fixed_map.items())),
                characters=tuple(sorted(chars.items())),
                depth=0,
            )
        )
    return states


def qualifying_transitions(
    state: State,
    max_k: int,
    max_explicit_subset: int = 3,
) -> tuple[list[dict[str, object]], int]:
    fixed0 = dict(state.fixed)
    chars = dict(state.characters)
    transitions: list[dict[str, object]] = []
    hidden_large_subset_qualifiers = 0

    for k in range(3, max_k + 1, 4):
        base_seed = mandatory_seed(k, state.hard_class, fixed0)
        compatible = [
            q for q, sign in chars.items()
            if q not in fixed0 and route_possible(q, sign, k)
        ]

        found: list[dict[str, object]] = []
        upper = min(max_explicit_subset, len(compatible))
        for size in range(upper + 1):
            level: list[dict[str, object]] = []
            for subset in itertools.combinations(compatible, size):
                fixed = dict(fixed0)
                for q in subset:
                    fixed[q] = (-k) % q
                seed = math.lcm(base_seed, *subset)
                outcome, value, sign = analyze_seed(
                    k, seed, state.hard_class, fixed, chars
                )
                if outcome is None:
                    continue
                level.append(
                    {
                        "k": k,
                        "subset": tuple(subset),
                        "seed": seed,
                        "fixed": tuple(sorted(fixed.items())),
                        "outcome": outcome,
                        "value": value,
                        "sign": sign,
                    }
                )
            if level:
                found.extend(level)
                break

        transitions.extend(found)

        # Completeness guard for 4+-source subsets. All current source
        # characters are positive. A routed positive source is Jacobi-plus at
        # the destination by the reciprocity barrier. Therefore if any subset
        # Jacobi-saturates, every compatible superset stays saturated; and if
        # any subset hits the fixed Type-I target, every superset still hits.
        # Hence when no <=3 subset qualifies, it is sufficient to test the
        # maximal seed containing every compatible source at once.
        if not found and len(compatible) > max_explicit_subset:
            maximal_fixed = dict(fixed0)
            for q in compatible:
                maximal_fixed[q] = (-k) % q
            maximal_seed = math.lcm(base_seed, *compatible)
            outcome, _, _ = analyze_seed(
                k, maximal_seed, state.hard_class, maximal_fixed, chars
            )
            if outcome is not None:
                hidden_large_subset_qualifiers += 1

    return transitions, hidden_large_subset_qualifiers


def closure(max_k: int) -> dict[str, object]:
    roots = root_states()
    seen = {state.key: state for state in roots}
    frontier = roots
    depth_rows: list[dict[str, int]] = []
    outcome_counts: Counter[str] = Counter()
    transition_count = 0
    hidden_large = 0
    destinations: set[int] = set()
    source_alphabet = {
        q for state in roots for q, _ in state.characters
    }
    product_rows: list[dict[str, object]] = []

    depth = 0
    while frontier:
        new_frontier: list[State] = []
        for state in frontier:
            transitions, hidden = qualifying_transitions(state, max_k)
            hidden_large += hidden
            for row in transitions:
                transition_count += 1
                outcome = str(row["outcome"])
                outcome_counts[outcome] += 1
                destinations.add(int(row["k"]))

                if outcome == "product":
                    product_rows.append(
                        {
                            "hard_class": state.hard_class,
                            "k": row["k"],
                            "subset": list(row["subset"]),
                            "seed": row["seed"],
                            "unknown_factors": list(row["value"]),
                            "known_product": row["sign"],
                        }
                    )
                    continue

                if outcome != "extract":
                    continue

                extracted_q = int(row["value"])
                extracted_sign = int(row["sign"])
                chars = dict(state.characters)
                prior = chars.get(extracted_q)
                if prior is not None and prior != extracted_sign:
                    raise RuntimeError(
                        f"character contradiction q={extracted_q}: {prior} vs {extracted_sign}"
                    )
                chars[extracted_q] = extracted_sign
                source_alphabet.add(extracted_q)
                child = State(
                    hard_class=state.hard_class,
                    fixed=tuple(row["fixed"]),
                    characters=tuple(sorted(chars.items())),
                    depth=state.depth + 1,
                )
                if child.key not in seen:
                    seen[child.key] = child
                    new_frontier.append(child)

        depth_rows.append(
            {
                "depth": depth,
                "states_processed": len(frontier),
                "new_states": len(new_frontier),
            }
        )
        frontier = new_frontier
        depth += 1
        if depth > 20:
            raise RuntimeError("unexpected non-closure beyond depth 20")

    negative_extractions = sum(
        1 for state in seen.values() for _, sign in state.characters if sign < 0
    )

    report = {
        "analysis": "branch-aware-character-saturation-closure-v1",
        "max_destination_k": max_k,
        "roots": len(roots),
        "states": len(seen),
        "transitions": transition_count,
        "outcomes": dict(sorted(outcome_counts.items())),
        "product_constraints": product_rows,
        "negative_character_entries_in_states": negative_extractions,
        "max_depth": max(state.depth for state in seen.values()),
        "depth_rows": depth_rows,
        "source_alphabet": sorted(source_alphabet),
        "qualifying_destinations": sorted(destinations),
        "max_qualifying_destination": max(destinations),
        "hidden_large_subset_qualifiers": hidden_large,
        "scope": (
            "eight merged composite-extraction roots; proved class-global positive sources; "
            "exact retained route residues; odd destinations k=3 mod4 through bound; "
            "minimal routed subsets <=3 plus maximal-all-source completeness guard"
        ),
        "claim_boundary": (
            "finite closure of the quadratic/Jacobi saturation-promotion mechanism only; "
            "does not include finer exact miss masks, valuations, or full companion-factor allocation"
        ),
    }
    return report


def assert_expected(report: dict[str, object]) -> None:
    outcomes = report["outcomes"]
    actual = {
        "roots": report["roots"],
        "states": report["states"],
        "transitions": report["transitions"],
        "known_plus": outcomes.get("known_plus", 0),
        "extract_positive": outcomes.get("extract", 0),
        "product_constraints": outcomes.get("product", 0),
        "type_i_hits": outcomes.get("type_i_hit", 0),
        "sign_hits": outcomes.get("sign_hit", 0),
        "negative_extractions": report["negative_character_entries_in_states"],
        "max_depth": report["max_depth"],
        "max_qualifying_destination": report["max_qualifying_destination"],
        "hidden_large_subset_qualifiers": report["hidden_large_subset_qualifiers"],
    }
    if actual != EXPECTED:
        raise SystemExit(f"closure constants changed: {actual!r} != {EXPECTED!r}")
    if set(report["source_alphabet"]) != EXPECTED_SOURCE_ALPHABET:
        raise SystemExit(f"source alphabet changed: {report['source_alphabet']!r}")
    if set(report["qualifying_destinations"]) != EXPECTED_DESTINATIONS:
        raise SystemExit(
            f"qualifying destinations changed: {report['qualifying_destinations']!r}"
        )

    products = report["product_constraints"]
    if len(products) != 1:
        raise SystemExit(f"unexpected product rows: {products!r}")
    row = products[0]
    if not (
        row["hard_class"] == 289
        and row["k"] == 551
        and row["unknown_factors"] == [19, 29]
        and row["known_product"] == 1
    ):
        raise SystemExit(f"product row changed: {row!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-k", type=int, default=5000)
    parser.add_argument("--json", action="store_true")
    parser.add_argument(
        "--assert-frontier",
        action="store_true",
        help="require the pinned k<=5000 closure constants",
    )
    args = parser.parse_args()

    report = closure(args.max_k)
    if args.assert_frontier:
        if args.max_k != 5000:
            raise SystemExit("--assert-frontier requires --max-k 5000")
        assert_expected(report)

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"states: {report['states']}")
        print(f"transitions: {report['transitions']}")
        print(f"max depth: {report['max_depth']}")
        print(f"max qualifying destination: {report['max_qualifying_destination']}")
        print(f"outcomes: {report['outcomes']}")
        print(f"hidden large-subset qualifiers: {report['hidden_large_subset_qualifiers']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
