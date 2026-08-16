#!/usr/bin/env python3
"""Exact class-conditioned fixed-shift character atlas.

For q in {11,31,47,59}, build the complete two-target state closure after
consuming the maximal seed forced by a Mordell-hard residue class modulo 840.
The state model is deliberately implemented here without importing the older
per-q classifiers so that this file is a common cross-modulus construction.
"""
from __future__ import annotations

import argparse
import json
from collections import Counter, deque

HARD_CLASSES = (1, 121, 169, 289, 361, 529)

# The cases retained here are exactly the class-seed closures relevant to the
# new character-annihilation theorem, plus the universal controls and the
# known k=31 h=361 failure boundary.
CASES = {
    11: (3, 15),
    31: (2, 10, 14, 70),
    47: (6, 42),
    59: (3, 105),
}

CLASS_SEED = {
    11: {1: 3, 121: 3, 169: 15, 289: 15, 361: 3, 529: 15},
    31: {1: 2, 121: 2, 169: 10, 289: 10, 361: 14, 529: 70},
    47: {1: 6, 121: 42, 169: 6, 289: 42, 361: 6, 529: 6},
    59: {1: 15, 121: 15, 169: 3, 289: 3, 361: 105, 529: 21},
}

EXPECTED = {
    (11, 3): {"states": 25, "misses": 9, "legendre": {"+1": 7, "-1": 2}},
    (11, 15): {"states": 15, "misses": 5, "legendre": {"+1": 5, "-1": 0}},
    (31, 2): {"states": 760, "misses": 118, "legendre": {"+1": 88, "-1": 30}},
    (31, 10): {"states": 75, "misses": 18, "legendre": {"+1": 18, "-1": 0}},
    (31, 14): {"states": 153, "misses": 23, "legendre": {"+1": 22, "-1": 1}},
    (31, 70): {"states": 45, "misses": 15, "legendre": {"+1": 15, "-1": 0}},
    (47, 6): {"states": 1079, "misses": 196, "legendre": {"+1": 116, "-1": 80}},
    (47, 42): {"states": 97, "misses": 24, "legendre": {"+1": 24, "-1": 0}},
    (59, 3): {"states": 35740, "misses": 5869, "legendre": {"+1": 3148, "-1": 2721}},
    (59, 105): {"states": 133, "misses": 30, "legendre": {"+1": 30, "-1": 0}},
}

ANNIHILATED = {
    11: {169: 15, 289: 15, 529: 15},
    31: {169: 10, 289: 10, 529: 70},
    47: {121: 42, 289: 42},
    59: {361: 105},
}


def factor_int(n: int) -> list[int]:
    out: list[int] = []
    q = 2
    x = n
    while q * q <= x:
        while x % q == 0:
            out.append(q)
            x //= q
        q += 1
    if x > 1:
        out.append(x)
    return out


def primitive_root(q: int) -> int:
    phi = q - 1
    prime_divisors = sorted(set(factor_int(phi)))
    for g in range(2, q):
        if all(pow(g, phi // r, q) != 1 for r in prime_divisors):
            return g
    raise ValueError(f"no primitive root found modulo {q}")


class Model:
    def __init__(self, q: int):
        self.q = q
        self.N = q - 1
        self.ALL = (1 << self.N) - 1
        self.root = primitive_root(q)
        self.log = {pow(self.root, a, q): a for a in range(self.N)}
        self.type_i = self.log[(-pow(4, -1, q)) % q]
        self.minus_one = self.N // 2

    def rotate(self, mask: int, a: int) -> int:
        a %= self.N
        if not a:
            return mask
        return ((mask << a) | (mask >> (self.N - a))) & self.ALL

    def transition(self, state: tuple[int, int], a: int) -> tuple[int, int]:
        mask, center = state
        return (
            mask | self.rotate(mask, a) | self.rotate(mask, 2 * a),
            (center + a) % self.N,
        )

    def seed_state(self, seed: int) -> tuple[int, int]:
        state = (1, 0)
        for r in factor_int(seed):
            if r % self.q == 0:
                raise ValueError(f"seed {seed} is not a unit modulo {self.q}")
            state = self.transition(state, self.log[r % self.q])
        return state

    def closure(self, seed: int) -> set[tuple[int, int]]:
        start = self.seed_state(seed)
        seen = {start}
        todo = deque([start])
        while todo:
            state = todo.popleft()
            for a in range(self.N):
                nxt = self.transition(state, a)
                if nxt not in seen:
                    seen.add(nxt)
                    todo.append(nxt)
        return seen

    def is_miss(self, state: tuple[int, int]) -> bool:
        mask, center = state
        type_ii = (center + self.minus_one) % self.N
        return not ((mask >> self.type_i) & 1) and not ((mask >> type_ii) & 1)


def analyze_case(q: int, seed: int, include_rows: bool) -> dict[str, object]:
    model = Model(q)
    states = model.closure(seed)
    misses = {state for state in states if model.is_miss(state)}
    legendre = Counter("+1" if center % 2 == 0 else "-1" for _, center in misses)
    legendre.setdefault("+1", 0)
    legendre.setdefault("-1", 0)

    out: dict[str, object] = {
        "q": q,
        "seed": seed,
        "primitive_root": model.root,
        "seed_factors": factor_int(seed),
        "states": len(states),
        "hit_states": len(states) - len(misses),
        "misses": len(misses),
        "legendre_miss_branches": dict(sorted(legendre.items())),
        "negative_character_annihilated": legendre["-1"] == 0,
    }

    expected = EXPECTED[(q, seed)]
    actual = {
        "states": out["states"],
        "misses": out["misses"],
        "legendre": out["legendre_miss_branches"],
    }
    if actual != expected:
        raise SystemExit(
            f"atlas regression changed for q={q}, seed={seed}: {actual!r} != {expected!r}"
        )

    if include_rows:
        out["miss_rows"] = [
            {
                "mask_hex": hex(mask),
                "center_log": center,
                "center_residue": pow(model.root, center, q),
                "legendre": "+1" if center % 2 == 0 else "-1",
                "divisor_logs": [a for a in range(model.N) if (mask >> a) & 1],
            }
            for mask, center in sorted(misses, key=lambda state: (state[1], state[0]))
        ]
    return out


def analyze(include_rows: bool) -> dict[str, object]:
    reports: dict[str, object] = {}
    for q, seeds in CASES.items():
        reports[str(q)] = {
            str(seed): analyze_case(q, seed, include_rows)
            for seed in seeds
        }

    theorem_rows = []
    for q, classes in ANNIHILATED.items():
        for h, seed in classes.items():
            report = reports[str(q)][str(seed)]
            if not report["negative_character_annihilated"]:
                raise SystemExit(f"declared annihilation failed for q={q}, h={h}, seed={seed}")
            if CLASS_SEED[q][h] != seed:
                raise SystemExit(f"class seed ledger mismatch for q={q}, h={h}")
            theorem_rows.append({"q": q, "h": h, "seed": seed})

    # The excluded k=31 h=361 branch is pinned as a negative control.
    failure = reports["31"]["14"]
    if failure["legendre_miss_branches"] != {"+1": 22, "-1": 1}:
        raise SystemExit("k=31 seed-14 negative-control branch changed")

    return {
        "analysis": "class-conditioned-character-annihilation-atlas-v1",
        "hard_classes": list(HARD_CLASSES),
        "class_seed": {
            str(q): {str(h): seed for h, seed in classes.items()}
            for q, classes in CLASS_SEED.items()
        },
        "reports": reports,
        "range_free_character_annihilations": theorem_rows,
        "negative_control": {
            "q": 31,
            "h": 361,
            "seed": 14,
            "negative_miss_states": 1,
        },
        "claim": (
            "exact finite-group superset closures after maximal class seeds; "
            "zero negative-character miss states yield range-free fixed-shift implications"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--table", action="store_true", help="include exact miss-state rows")
    args = ap.parse_args()
    report = analyze(args.table)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("class-conditioned character-annihilation atlas")
        for q, cases in report["reports"].items():
            for seed, row in cases.items():
                print(
                    f"q={q:>2} seed={seed:>3} states={row['states']:>5} "
                    f"misses={row['misses']:>4} legendre={row['legendre_miss_branches']}"
                )
        print("range-free rows:")
        for row in report["range_free_character_annihilations"]:
            print(f"  h={row['h']} mod 840 and ({row['q']}/p)=-1 -> k={row['q']} hit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
