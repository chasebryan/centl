#!/usr/bin/env python3
"""Verify exact counterexamples to the proposed k<=39 -> k47 cross-containment.

These are NOT Erdős-Straus counterexamples. They are Mordell-hard primes in the
exact fixed-k47 r7-s02 miss state which miss every earlier signed-box shift
k=3,7,...,39 and also miss k=43 and k=47. Each is later captured by another
fixed shift.

The purpose of this verifier is adversarial: any future attempt to restore the
falsified statement

  miss all k<=39 and (47/p)=-1 => hit at k=47

must fail this regression immediately.
"""
from __future__ import annotations

import argparse
import json
from math import gcd

import analyze_k47_negative_corridor as corridor
import analyze_k47_negative_states as states
import classify_k47_states as core

EARLIER = (3, 7, 11, 15, 19, 23, 27, 31, 35, 39)
CASES = (
    {
        "p": 2_444_452_921,
        "C47_factors": ((2, 1), (3, 1), (4993, 1), (20399, 1)),
        "first_later_hit": 51,
    },
    {
        "p": 7_269_066_841,
        "C47_factors": ((2, 1), (3, 1), (302877787, 1)),
        "first_later_hit": 59,
    },
    {
        "p": 9_053_010_121,
        "C47_factors": ((2, 1), (3, 1), (377208757, 1)),
        "first_later_hit": 59,
    },
)


def signed_box(factors: list[tuple[int, int]], k: int) -> set[int]:
    vals = {1 % k}
    for q, e in factors:
        if gcd(q, k) != 1:
            return set()
        qmod = q % k
        qinv = pow(qmod, -1, k)
        local = []
        cur = pow(qinv, e, k)
        for _ in range(2 * e + 1):
            local.append(cur)
            cur = (cur * qmod) % k
        vals = {(a * b) % k for a in vals for b in local}
    return vals


def delta_zero(p: int, k: int) -> bool:
    if k < 3 or k % 4 != 3 or gcd(p, k) != 1:
        return False
    C = (p + k) // 4
    if gcd(C, k) != 1:
        return False
    factors = corridor.factor_integer(C)
    box = signed_box(factors, k)
    if (k - 1) in box:
        return True
    tau_i = (-pow(4, -1, k) * pow(C, -1, k)) % k
    return tau_i in box


def first_hit_from(p: int, start: int, stop: int = 1000) -> int | None:
    k = start
    while k <= stop:
        if k % 4 == 3 and delta_zero(p, k):
            return k
        k += 1
    return None


def analyze() -> dict:
    _direction, state_ids, _by_direction = states.abstract_state_partition()
    r7s02 = next(state for state, sid in state_ids.items() if sid == "r7-s02")
    rows = []

    for case in CASES:
        p = case["p"]
        if not corridor.is_prime64(p):
            raise SystemExit(f"p={p} is no longer prime")
        if p % 840 != 1 or p % 47 != 29 or p % 39480 != 9241:
            raise SystemExit(f"p={p}: hard-cell CRT regression changed")
        if pow(p % 47, 23, 47) != 46:
            raise SystemExit(f"p={p}: expected (47/p)=-1 parity branch")

        C47 = (p + 47) // 4
        factors = corridor.factor_integer(C47)
        expected = list(case["C47_factors"])
        if factors != expected:
            raise SystemExit(f"p={p}: C47 factorization changed: {factors} != {expected}")
        for q, _e in factors:
            if not corridor.is_prime64(q):
                raise SystemExit(f"p={p}: listed C47 factor {q} is not prime")

        state, rebuilt_factors = corridor.k47_state_from_prime(p)
        if state != r7s02 or state_ids.get(state) != "r7-s02":
            raise SystemExit(f"p={p}: fixed-k47 state is not r7-s02")
        if rebuilt_factors != factors or not core.is_miss(state) or delta_zero(p, 47):
            raise SystemExit(f"p={p}: expected exact fixed-k47 combined miss")

        earlier = {str(k): delta_zero(p, k) for k in EARLIER}
        if any(earlier.values()):
            raise SystemExit(f"p={p}: no longer misses the full earlier corridor: {earlier}")
        if delta_zero(p, 43):
            raise SystemExit(f"p={p}: unexpectedly hits k=43")

        first = first_hit_from(p, 51, 1000)
        if first != case["first_later_hit"]:
            raise SystemExit(
                f"p={p}: first later hit changed: {first} != {case['first_later_hit']}"
            )

        q11 = [q for q, e in factors if q % 47 == 11 for _ in range(e)]
        s1 = [q for q, e in factors if q not in (2, 3) and q % 47 == 1 for _ in range(e)]
        if len(q11) != 1:
            raise SystemExit(f"p={p}: expected exactly one log-7 factor")

        rows.append({
            "p": p,
            "p_mod840": p % 840,
            "p_mod47": p % 47,
            "p_mod39480": p % 39480,
            "C47": C47,
            "C47_factors": factors,
            "q_mod47_eq_11": q11[0],
            "S_prime_factors_mod47_eq_1": s1,
            "misses_earlier_through39": True,
            "misses_k43": True,
            "misses_k47": True,
            "first_later_hit": first,
        })

    return {
        "analysis": "k47-earlier-corridor-counterexamples-v1",
        "falsified_candidate": (
            "for every Mordell-hard prime, miss of k=3,7,...,39 together with "
            "(47/p)=-1 forces a hit at k=47"
        ),
        "counterexample_count_locked": len(rows),
        "rows": rows,
        "claim_boundary": (
            "counterexamples only to the proposed cross-shift containment; "
            "all listed primes have later fixed-shift hits and are not Erdős-Straus counterexamples"
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print("k=47 earlier-corridor containment is false")
        for row in report["rows"]:
            print(
                f"p={row['p']} misses k<=47 corridor; "
                f"first later signed-box hit k={row['first_later_hit']}"
            )
        print("warning: these are not Erdős-Straus counterexamples")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
