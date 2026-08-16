#!/usr/bin/env python3
"""Independent exact checks for the recursive character-promotion milestones."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter

# One explicit shortest proof chain for each genuinely new hard-class/source pair.
# Each step is (kind, hard_class, destination, sources, required residues, base seed,
# routed seed, promoted prime). Earlier steps in a chain establish any derived source
# used later.
CHAINS = {
    (121, 79): [
        ("prime", 121, 79, (13, 19), (12, 16), 10, 2470, 79),
    ],
    (121, 53): [
        ("composite", 121, 159, (13, 23), (10, 2), 70, 20930, 53),
    ],
    (121, 11): [
        ("composite", 121, 159, (13, 23), (10, 2), 70, 20930, 53),
        ("prime", 121, 11, (53,), (42,), 3, 159, 11),
    ],
    (121, 59): [
        ("prime", 121, 79, (13, 23), (12, 13), 10, 2990, 79),
        ("prime", 121, 59, (19, 79), (17, 20), 15, 22515, 59),
    ],
    (121, 71): [
        ("prime", 121, 79, (13, 23), (12, 13), 10, 2990, 79),
        ("prime", 121, 71, (19, 79), (5, 8), 6, 9006, 71),
    ],
    (169, 71): [
        ("prime", 169, 71, (37,), (3,), 30, 1110, 71),
    ],
    (169, 83): [
        ("prime", 169, 83, (11, 37), (5, 28), 21, 8547, 83),
    ],
    (169, 19): [
        ("composite", 169, 95, (11, 37), (4, 16), 6, 2442, 19),
    ],
    (169, 13): [
        ("prime", 169, 71, (37,), (3,), 30, 1110, 71),
        ("composite", 169, 39, (11, 71), (5, 32), 2, 1562, 13),
    ],
    (169, 167): [
        ("composite", 169, 95, (11, 37), (4, 16), 6, 2442, 19),
        ("prime", 169, 167, (19, 31), (4, 19), 42, 24738, 167),
    ],
    (289, 19): [
        ("prime", 289, 19, (17,), (15,), 7, 119, 19),
    ],
    (289, 71): [
        ("prime", 289, 71, (43,), (15,), 30, 1290, 71),
    ],
    (289, 191): [
        ("prime", 289, 191, (23, 43), (16, 24), 30, 29670, 191),
    ],
}

ROOT_RESIDUES = {
    121: ({47: 8},),
    169: ({11: 4, 23: 18}, {23: 4}),
    289: ({11: 5, 47: 8}, {11: 4, 23: 18}, {11: 5, 31: 2}),
}

EXPECTED = {
    (121, 11), (121, 53), (121, 59), (121, 71), (121, 79),
    (169, 13), (169, 19), (169, 71), (169, 83), (169, 167),
    (289, 19), (289, 71), (289, 191),
}


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


def factor(n: int) -> Counter[int]:
    out: Counter[int] = Counter()
    d = 2
    while d * d <= n:
        while n % d == 0:
            n //= d
            out[d] += 1
        d += 1 if d == 2 else 2
    if n > 1:
        out[n] += 1
    return out


def divisors_from_factorization(factors: Counter[int]) -> list[int]:
    values = [1]
    for q, e in factors.items():
        values = [v * q**j for v in values for j in range(e + 1)]
    return values


def square_divisor_residues(seed: int, modulus: int) -> set[int]:
    doubled = Counter({q: 2 * e for q, e in factor(seed).items()})
    return {d % modulus for d in divisors_from_factorization(doubled)}


def qr(modulus: int) -> set[int]:
    return {x * x % modulus for x in range(1, modulus)}


def jacobi(a: int, n: int) -> int:
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


def jacobi_plus(modulus: int) -> set[int]:
    return {
        x for x in range(1, modulus)
        if math.gcd(x, modulus) == 1 and jacobi(x, modulus) == 1
    }


def saturates(kind: str, seed: int, modulus: int) -> bool:
    residues = square_divisor_residues(seed, modulus)
    if kind == "prime":
        return is_prime(modulus) and residues == qr(modulus)
    return (not is_prime(modulus)) and residues == jacobi_plus(modulus)


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def legendre_positive(a: int, q: int) -> bool:
    a %= q
    return a != 0 and pow(a, (q - 1) // 2, q) == 1


def crt_merge(a: int, m: int, b: int, n: int) -> tuple[int, int]:
    g = math.gcd(m, n)
    if (b - a) % g:
        raise AssertionError((a, m, b, n))
    m1, n1 = m // g, n // g
    t = ((b - a) // g * pow(m1, -1, n1)) % n1
    mod = m * n1
    return (a + m * t) % mod, mod


def verify_chain(target: tuple[int, int], steps: list[tuple]) -> dict[str, object]:
    h, expected_prime = target
    assert steps[-1][-1] == expected_prime

    # Start only with the hard class. Each route residue is then merged into an
    # explicit CRT branch, independently checking that no exact residue ancestry
    # becomes inconsistent.
    residue, modulus = h, 840
    promoted = set()
    checked_steps = 0

    for kind, step_h, k, sources, residues, base, seed, promoted_prime in steps:
        assert step_h == h
        assert class_seed(k, h) == base
        assert math.lcm(base, *sources) == seed
        assert not saturates(kind, base, k)
        assert saturates(kind, seed, k)

        if len(sources) > 1:
            for q in sources:
                assert not saturates(kind, math.lcm(base, q), k)

        for q, r in zip(sources, residues):
            assert r == (-k) % q
            assert legendre_positive(r, q)
            residue, modulus = crt_merge(residue, modulus, r, q)

        if kind == "prime":
            assert promoted_prime == k
        else:
            factors = factor(k)
            unknown = [q for q, e in factors.items() if e % 2 and 840 % q != 0]
            assert unknown == [promoted_prime]
            # All other odd-exponent character factors are fixed by the hard
            # residue. Their product must be +1 for the miss to extract a
            # positive character at promoted_prime.
            fixed = 1
            for q, e in factors.items():
                if e % 2 == 0 or q == promoted_prime:
                    continue
                assert 840 % q == 0
                fixed *= 1 if legendre_positive(h, q) else -1
            assert fixed == 1

        promoted.add(promoted_prime)
        checked_steps += 1

    return {
        "hard_class": h,
        "promoted_prime": expected_prime,
        "steps": checked_steps,
        "crt_modulus": modulus,
        "crt_residue": residue,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert set(CHAINS) == EXPECTED
    rows = [verify_chain(target, steps) for target, steps in sorted(CHAINS.items())]
    report = {
        "analysis": "recursive-character-promotion-independent-regression-v1",
        "new_source_classes_checked": len(rows),
        "promotion_steps_checked": sum(int(row["steps"]) for row in rows),
        "chains": rows,
        "failures": 0,
        "claim": (
            "independent divisor-enumeration and CRT regression for one shortest exact "
            "promotion chain to each newly discovered hard-class/source pair"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"new source classes checked: {len(rows)}")
        print(f"promotion steps checked: {report['promotion_steps_checked']}")
        print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
