#!/usr/bin/env python3
"""Independent regression for the quadratic-reciprocity routing barrier."""
from __future__ import annotations

import argparse
import json
import math


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


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    q = 3
    while q * q <= n:
        if n % q == 0:
            return False
        q += 2
    return True


def legendre(a: int, q: int) -> int:
    a %= q
    if a == 0:
        return 0
    v = pow(a, (q - 1) // 2, q)
    return -1 if v == q - 1 else 1


def analyze(max_k: int, max_q: int) -> dict[str, object]:
    failures: list[dict[str, int]] = []
    checked = 0
    positive_routes = 0
    for k in range(3, max_k + 1, 4):
        for q in range(3, max_q + 1, 2):
            if not is_prime(q) or math.gcd(k, q) != 1:
                continue
            lhs = legendre(-k, q)
            rhs = jacobi(q, k)
            checked += 1
            if lhs != rhs:
                failures.append({"k": k, "q": q, "minus_k_over_q": lhs, "q_over_k": rhs})
            if lhs == 1:
                positive_routes += 1
                if rhs != 1:
                    failures.append({"k": k, "q": q, "positive_route_rhs": rhs})

    examples = [
        (19, 15),
        (23, 15),
        (31, 15),
        (47, 15),
        (11, 35),
        (47, 35),
        (23, 19),
        (23, 7),
    ]
    example_rows = []
    for q, k in examples:
        row = {
            "q": q,
            "k": k,
            "minus_k_over_q": legendre(-k, q),
            "q_over_k": jacobi(q, k),
        }
        if row["minus_k_over_q"] != 1 or row["q_over_k"] != 1:
            failures.append({"example_q": q, "example_k": k})
        example_rows.append(row)

    return {
        "analysis": "character-routing-reciprocity-barrier-regression-v1",
        "max_k": max_k,
        "max_q": max_q,
        "coprime_pairs_checked": checked,
        "positive_route_pairs_checked": positive_routes,
        "named_route_examples": example_rows,
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "regression of the elementary identity (-k/q)=(q/k) for odd k=3 mod4; "
            "the proof is range-free and follows from quadratic/Jacobi reciprocity"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-k", type=int, default=5000)
    parser.add_argument("--max-q", type=int, default=500)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze(args.max_k, args.max_q)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"coprime pairs checked: {report['coprime_pairs_checked']}")
        print(f"positive route pairs: {report['positive_route_pairs_checked']}")
        print(f"failures: {report['failures']}")
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
