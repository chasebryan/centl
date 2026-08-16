#!/usr/bin/env python3
"""Independent cyclic-exponent and state-set verification of prime repulsion."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

EXPECTED_REPELLERS = {
    (1, 11, 3): (3, 4, 5, 9),
    (121, 11, 3): (3, 4, 5, 9),
    (361, 11, 3): (3, 4, 5, 9),
    (1, 19, 5): (7, 11),
    (289, 19, 7): (4, 5, 6, 9, 16, 17),
    (361, 19, 5): (7, 11),
    (1, 23, 6): (2, 3, 4, 6, 8, 9, 12, 13, 16, 18),
    (121, 23, 6): (2, 3, 4, 6, 8, 9, 12, 13, 16, 18),
    (169, 23, 6): (2, 3, 4, 6, 8, 9, 12, 13, 16, 18),
    (289, 23, 6): (2, 3, 4, 6, 8, 9, 12, 13, 16, 18),
    (361, 23, 6): (2, 3, 4, 6, 8, 9, 12, 13, 16, 18),
    (529, 23, 6): (2, 3, 4, 6, 8, 9, 12, 13, 16, 18),
    (169, 31, 10): (2, 4, 7, 8, 9, 10, 14, 16, 18, 19, 20, 28),
    (289, 31, 10): (2, 4, 7, 8, 9, 10, 14, 16, 18, 19, 20, 28),
    (361, 31, 14): (2, 4, 5, 8, 10, 14, 16, 20, 25, 28),
    (121, 47, 42): (2, 3, 4, 6, 7, 8, 9, 12, 14, 16, 17, 18, 21, 24, 25, 27, 28, 32, 34, 36, 37, 42),
    (289, 47, 42): (2, 3, 4, 6, 7, 8, 9, 12, 14, 16, 17, 18, 21, 24, 25, 27, 28, 32, 34, 36, 37, 42),
    (361, 59, 105): (3, 4, 5, 7, 9, 12, 15, 16, 17, 19, 20, 21, 22, 25, 26, 27, 28, 29, 35, 36, 41, 45, 46, 48, 49, 51, 53, 57),
    (169, 71, 30): (4, 5, 8, 9, 10, 16, 18, 20, 25, 27, 29, 30, 32, 37, 38, 40, 43, 45, 48, 49, 50, 54, 57, 58, 60, 64),
    (289, 71, 30): (4, 5, 8, 9, 10, 16, 18, 20, 25, 27, 29, 30, 32, 37, 38, 40, 43, 45, 48, 49, 50, 54, 57, 58, 60, 64),
    (529, 71, 30): (4, 5, 8, 9, 10, 16, 18, 20, 25, 27, 29, 30, 32, 37, 38, 40, 43, 45, 48, 49, 50, 54, 57, 58, 60, 64),
}

EXPECTED_NEGATIVE = {
    (1, 11, 3): (2, 6),
    (121, 11, 3): (2, 6),
    (361, 11, 3): (2, 6),
    (1, 19, 5): (2, 3, 8, 10, 12, 13),
    (289, 19, 7): (2, 3, 14),
    (361, 19, 5): (2, 3, 8, 10, 12, 13),
    (1, 23, 6): (5, 14),
    (121, 23, 6): (5, 14),
    (169, 23, 6): (5, 14),
    (289, 23, 6): (5, 14),
    (361, 23, 6): (5, 14),
    (529, 23, 6): (5, 14),
    (361, 31, 14): (26,),
    (169, 71, 30): (17, 53),
    (289, 71, 30): (17, 53),
    (529, 71, 30): (17, 53),
}

NEW_TERMINALS = (
    (121, 11, 53, 42, 159, (2, 6)),
    (121, 11, 59, 48, 177, (2, 6)),
    (121, 11, 71, 60, 213, (2, 6)),
    (169, 71, 37, 3, 1110, (17, 53)),
    (169, 71, 167, 96, 5010, (17, 53)),
    (289, 71, 43, 15, 1290, (17, 53)),
    (289, 71, 191, 120, 5730, (17, 53)),
)


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


def divisors_square(seed: int) -> list[int]:
    values = [1]
    for q, e in factor(seed).items():
        values = [v * q**j for v in values for j in range(2 * e + 1)]
    return values


def qr(k: int) -> set[int]:
    return {x * x % k for x in range(1, k)}


def primitive_root(p: int) -> int:
    phi = p - 1
    factors = factor(phi)
    for g in range(2, p):
        if all(pow(g, phi // q, p) != 1 for q in factors):
            return g
    raise AssertionError(p)


def exponent_repellers(seed: int, k: int) -> tuple[int, ...]:
    g = primitive_root(k)
    z = pow(g, 2, k)
    order = (k - 1) // 2
    exp_of = {}
    value = 1
    for e in range(order):
        exp_of[value] = e
        value = value * z % k
    assert set(exp_of) == qr(k)

    base_residues = {d % k for d in divisors_square(seed)}
    assert base_residues <= set(exp_of)
    a = {exp_of[r] for r in base_residues}
    whole = set(range(order))
    repellers = []
    for r, e in exp_of.items():
        augmented = {(x + j * e) % order for x in a for j in (0, 1, 2)}
        if augmented == whole:
            repellers.append(r)
    return tuple(sorted(repellers))


def transition(mask: frozenset[int], center: int, a: int, k: int) -> tuple[frozenset[int], int]:
    local = (1, a, a * a % k)
    return frozenset(x * y % k for x in mask for y in local), center * a % k


def negative_centers(seed: int, k: int) -> tuple[int, ...]:
    mask = frozenset({1})
    center = 1
    for q, e in factor(seed).items():
        for _ in range(e):
            mask, center = transition(mask, center, q % k, k)
    start = (mask, center)
    units = tuple(u for u in range(1, k) if math.gcd(u, k) == 1)
    seen = {start}
    queue = deque([start])
    type_i = (-pow(4, -1, k)) % k
    misses = []
    while queue:
        state_mask, state_center = queue.popleft()
        type_ii = (-state_center) % k
        if type_i not in state_mask and type_ii not in state_mask:
            misses.append(4 * state_center % k)
        for a in units:
            nxt = transition(state_mask, state_center, a, k)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    qrs = qr(k)
    return tuple(sorted({r for r in misses if r not in qrs}))


def verify_terminal(row: tuple) -> dict[str, object]:
    h, k, q, required, routed_seed, negative = row
    base_seed = math.gcd(210, (h + k) // 4)
    assert required == (-k) % q
    assert pow(required, (q - 1) // 2, q) == 1
    assert routed_seed == base_seed * q
    assert q % k in EXPECTED_REPELLERS[(h, k, base_seed)]
    assert {d % k for d in divisors_square(routed_seed)} == qr(k)
    assert negative_centers(base_seed, k) == negative
    return {
        "hard_class": h,
        "destination_k": k,
        "source_prime": q,
        "required_p_mod_source": required,
        "routed_seed": routed_seed,
        "eliminated_negative_centers": list(negative),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    for key, expected in EXPECTED_REPELLERS.items():
        _h, k, seed = key
        actual = exponent_repellers(seed, k)
        assert actual == expected, (key, actual, expected)

    for key, expected in EXPECTED_NEGATIVE.items():
        _h, k, seed = key
        actual = negative_centers(seed, k)
        assert actual == expected, (key, actual, expected)

    terminal_rows = [verify_terminal(row) for row in NEW_TERMINALS]
    report = {
        "analysis": "prime-divisor-mask-repulsion-independent-regression-v1",
        "seed_repeller_branches_checked": len(EXPECTED_REPELLERS),
        "negative_center_branches_checked": len(EXPECTED_NEGATIVE),
        "new_recursive_terminal_triples_checked": len(terminal_rows),
        "new_recursive_terminals": terminal_rows,
        "failures": 0,
        "claim": (
            "independent cyclic-QR exponent verification of every source-independent repeller "
            "set, set-state verification of every negative miss-center list, and direct checks "
            "of the seven newly exposed recursive terminal triples"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"repeller branches checked: {len(EXPECTED_REPELLERS)}")
        print(f"negative-center branches checked: {len(EXPECTED_NEGATIVE)}")
        print(f"new recursive terminals checked: {len(terminal_rows)}")
        print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
