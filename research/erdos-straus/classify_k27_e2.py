#!/usr/bin/env python3
"""Exact finite-group classifier for the k=27, E_NR=2 branch.

This program contains no prime search. It enumerates the complete reachable
QR-part divisor-log state space in C_9, combines it with the 45 unordered
pairs of odd C_18 logs representing two nonresidue valuation units, and
applies the proved four-companion criterion from K27-TWO-TARGET-STRUCTURE.md.

The enumeration is exhaustive because:
* QR half-log a=0 contributes nothing;
* a=3 or 6 has order 3, so e=1..3 exhausts both the saturated local set and
  all possible centers;
* every unit a in C_9 has order 9. For e=1,2,3 the local divisor set has
  3,5,7 elements; for e>=4 it is all C_9, and nine consecutive exponents
  exhaust all center values. Thus e=1..12 is sufficient for every local
  QR factor state.
"""
from __future__ import annotations

import argparse
import collections
import json

MOD_Q = 9
MOD = 18
ODD_LOGS = tuple(range(1, 18, 2))


def add_sets(a: frozenset[int], b: frozenset[int], mod: int) -> frozenset[int]:
    return frozenset((x + y) % mod for x in a for y in b)


def local_qr_states() -> set[tuple[frozenset[int], int]]:
    states: set[tuple[frozenset[int], int]] = set()
    for a in range(9):
        for e in range(1, 13):
            divs = frozenset((f * a) % 9 for f in range(0, 2 * e + 1))
            center = (e * a) % 9
            states.add((divs, center))
    return states


def reachable_qr_states() -> set[tuple[frozenset[int], int]]:
    generators = local_qr_states()
    identity = (frozenset({0}), 0)
    reached = {identity}
    queue = [identity]
    while queue:
        divs, center = queue.pop()
        for gdivs, gcenter in generators:
            nxt = (
                add_sets(divs, gdivs, 9),
                (center + gcenter) % 9,
            )
            if nxt not in reached:
                reached.add(nxt)
                queue.append(nxt)
    return reached


def odd_pair_set(alpha: int, beta: int) -> frozenset[int]:
    return frozenset({
        alpha % 18,
        beta % 18,
        (alpha + 2 * beta) % 18,
        (2 * alpha + beta) % 18,
    })


def classify_state(
    divs9: frozenset[int],
    center9: int,
    alpha: int,
    beta: int,
) -> tuple[bool, bool]:
    dq = {(2 * x) % 18 for x in divs9}
    oset = odd_pair_set(alpha, beta)
    center = (2 * center9 + alpha + beta) % 18
    type_i = any(((7 - o) % 18) in dq for o in oset)
    type_ii = any(((9 + center - o) % 18) in dq for o in oset)
    return type_i, type_ii


def report() -> dict[str, object]:
    qr_states = reachable_qr_states()
    pairs = [
        (alpha, beta)
        for i, alpha in enumerate(ODD_LOGS)
        for beta in ODD_LOGS[i:]
    ]

    miss_rows: list[dict[str, object]] = []
    miss_by_qr: collections.defaultdict[
        tuple[tuple[int, ...], int], list[tuple[int, int]]
    ] = collections.defaultdict(list)

    for divs9, center9 in qr_states:
        for alpha, beta in pairs:
            type_i, type_ii = classify_state(divs9, center9, alpha, beta)
            if not type_i and not type_ii:
                key = (tuple(sorted(divs9)), center9)
                miss_by_qr[key].append((alpha, beta))
                miss_rows.append({
                    "qr_divisor_half_logs": list(key[0]),
                    "qr_center_half_log": center9,
                    "alpha": alpha,
                    "beta": beta,
                })

    miss_capable = []
    for (divs, center), allowed in sorted(
        miss_by_qr.items(),
        key=lambda item: (len(item[0][0]), item[0][1], item[0][0]),
    ):
        miss_capable.append({
            "qr_divisor_half_logs": list(divs),
            "qr_center_half_log": center,
            "allowed_nonresidue_log_pairs": [list(pair) for pair in sorted(allowed)],
            "miss_pair_count": len(allowed),
        })

    size_hist = collections.Counter(len(divs) for divs, _ in qr_states)
    miss_size_hist = collections.Counter(
        len(row["qr_divisor_half_logs"]) for row in miss_capable
    )

    return {
        "analysis": "k27-e2-exact-finite-group-classifier-v1",
        "qr_local_states": len(local_qr_states()),
        "qr_reachable_states": len(qr_states),
        "qr_reachable_size_histogram": dict(sorted(size_hist.items())),
        "nonresidue_unordered_pairs": len(pairs),
        "total_structural_cases": len(qr_states) * len(pairs),
        "miss_capable_qr_states": len(miss_capable),
        "miss_capable_qr_size_histogram": dict(sorted(miss_size_hist.items())),
        "exact_miss_configurations": len(miss_rows),
        "miss_capable_states": miss_capable,
        "claim": "exhaustive finite-group classification of the E_NR=2 branch only",
    }


def print_text(r: dict[str, object]) -> None:
    print("k=27 E_NR=2 exact finite-group classifier")
    print(f"QR states={r['qr_reachable_states']}")
    print(f"NR pairs={r['nonresidue_unordered_pairs']}")
    print(f"structural cases={r['total_structural_cases']}")
    print(f"miss-capable QR states={r['miss_capable_qr_states']}")
    print(f"exact miss configurations={r['exact_miss_configurations']}")
    for row in r["miss_capable_states"]:
        print(
            f"  DQ/2={row['qr_divisor_half_logs']} "
            f"cQ/2={row['qr_center_half_log']} "
            f"pairs={row['allowed_nonresidue_log_pairs']}"
        )


def main() -> int:
    ap = argparse.ArgumentParser(description="classify k=27 E_NR=2 group states")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    r = report()

    # These constants are consequences of the exact enumeration and act as
    # tamper/regression guards for the state-machine definition.
    if r["qr_reachable_states"] != 40:
        raise SystemExit(f"unexpected QR state count: {r['qr_reachable_states']}")
    if r["nonresidue_unordered_pairs"] != 45:
        raise SystemExit("unexpected nonresidue pair count")
    if r["total_structural_cases"] != 1800:
        raise SystemExit("unexpected structural case count")
    if r["miss_capable_qr_states"] != 21:
        raise SystemExit(f"unexpected miss-capable state count: {r['miss_capable_qr_states']}")
    if r["exact_miss_configurations"] != 95:
        raise SystemExit(f"unexpected miss configuration count: {r['exact_miss_configurations']}")

    if args.json:
        print(json.dumps(r, indent=2, sort_keys=True))
    else:
        print_text(r)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
