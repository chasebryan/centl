#!/usr/bin/env python3
"""Exact finite-group exhaustion for all k=27 nonresidue packet sizes.

For Mordell-hard p, C=(p+27)/4 is 1 mod 3, so its total valuation E_NR of
quadratic-nonresidue prime factors modulo 27 is even.  The k=27 group has
order 18; the QR half-log state lives in C_9.

This program exhausts every reachable QR state against every unordered
multiset of E odd C_18 logs for E=0,2,4,6,8,10.  The E=10 exhaustion has no
combined misses.  Since both exact witness mechanisms are monotone under
adjoining extra factor valuation units, this gives a universal cutoff:
E_NR >= 10 always hits at k=27.

The computation is a finite group exhaustion only; there is no prime search.
"""
from __future__ import annotations

import argparse
import collections
import itertools
import json

ODD = tuple(range(1, 18, 2))
EXPECTED = {
    0: {"multisets": 1, "misses": 40, "miss_qr_states": 40},
    2: {"multisets": 45, "misses": 95, "miss_qr_states": 21},
    4: {"multisets": 495, "misses": 46, "miss_qr_states": 12},
    6: {"multisets": 3003, "misses": 16, "miss_qr_states": 6},
    8: {"multisets": 12870, "misses": 3, "miss_qr_states": 1},
    10: {"multisets": 43758, "misses": 0, "miss_qr_states": 0},
}


def add9(a: frozenset[int], b: frozenset[int]) -> frozenset[int]:
    return frozenset((x + y) % 9 for x in a for y in b)


def local_qr_states() -> set[tuple[frozenset[int], int]]:
    # e=1..12 is exhaustive; see classify_k27_e2.py and theorem note.
    out: set[tuple[frozenset[int], int]] = set()
    for a in range(9):
        for e in range(1, 13):
            out.add((
                frozenset((f * a) % 9 for f in range(0, 2 * e + 1)),
                (e * a) % 9,
            ))
    return out


def reachable_qr_states() -> set[tuple[frozenset[int], int]]:
    gens = local_qr_states()
    identity = (frozenset({0}), 0)
    reached = {identity}
    queue = [identity]
    while queue:
        divs, center = queue.pop()
        for gdivs, gcenter in gens:
            nxt = (add9(divs, gdivs), (center + gcenter) % 9)
            if nxt not in reached:
                reached.add(nxt)
                queue.append(nxt)
    return reached


def odd_contribution_mask(units: tuple[int, ...]) -> int:
    """Odd-parity divisor-log contributions of valuation units.

    Each valuation unit may contribute exponent 0, 1, or 2. Splitting an
    exponent-e prime power into e identical valuation units is exact because
    sums of e copies of {0,1,2} fill every integer 0..2e.
    """
    counts = collections.Counter(units)
    even = {0}
    odd: set[int] = set()
    for alpha, e in counts.items():
        local_even = {(f * alpha) % 18 for f in range(0, 2 * e + 1) if f % 2 == 0}
        local_odd = {(f * alpha) % 18 for f in range(0, 2 * e + 1) if f % 2 == 1}
        next_even = (
            {(x + y) % 18 for x in even for y in local_even}
            | {(x + y) % 18 for x in odd for y in local_odd}
        )
        next_odd = (
            {(x + y) % 18 for x in even for y in local_odd}
            | {(x + y) % 18 for x in odd for y in local_even}
        )
        even, odd = next_even, next_odd
    mask = 0
    for x in odd:
        mask |= 1 << x
    return mask


def mask_from_values(values: set[int]) -> int:
    mask = 0
    for x in values:
        mask |= 1 << x
    return mask


def qr_precompute() -> list[dict[str, object]]:
    rows = []
    for divs9, center9 in reachable_qr_states():
        dq = {(2 * x) % 18 for x in divs9}
        # An odd contribution o rescues Type I when 7-o is in D_Q.
        comp_i = {o for o in ODD if ((7 - o) % 18) in dq}
        comp_ii_by_sum = {}
        for nr_sum in range(0, 18, 2):
            c = (2 * center9 + nr_sum) % 18
            comp_ii_by_sum[nr_sum] = mask_from_values(
                {o for o in ODD if ((9 + c - o) % 18) in dq}
            )
        rows.append({
            "divs9": tuple(sorted(divs9)),
            "center9": center9,
            "comp_i": mask_from_values(comp_i),
            "comp_ii_by_sum": comp_ii_by_sum,
        })
    return rows


def classify_packet_size(E: int, qr_rows: list[dict[str, object]]) -> dict[str, object]:
    if E == 0:
        # Pure QR support: both exact targets are odd while D_Q is even.
        return {
            "E_NR": 0,
            "nonresidue_multisets": 1,
            "structural_cases": len(qr_rows),
            "miss_configurations": len(qr_rows),
            "miss_capable_qr_states": len(qr_rows),
            "odd_contribution_size_histogram": {"0": 1},
            "miss_examples": [],
        }

    multiset_count = 0
    miss_count = 0
    miss_qr: set[tuple[tuple[int, ...], int]] = set()
    osize_hist: collections.Counter[int] = collections.Counter()
    examples: list[dict[str, object]] = []

    for units in itertools.combinations_with_replacement(ODD, E):
        multiset_count += 1
        omask = odd_contribution_mask(units)
        osize_hist[omask.bit_count()] += 1
        nr_sum = sum(units) % 18

        for qr in qr_rows:
            hit_i = bool(omask & int(qr["comp_i"]))
            hit_ii = bool(omask & int(qr["comp_ii_by_sum"][nr_sum]))
            if hit_i or hit_ii:
                continue
            miss_count += 1
            key = (qr["divs9"], int(qr["center9"]))
            miss_qr.add(key)
            if len(examples) < 20:
                examples.append({
                    "qr_divisor_half_logs": list(qr["divs9"]),
                    "qr_center_half_log": qr["center9"],
                    "nonresidue_logs": list(units),
                    "odd_contribution_logs": [i for i in range(18) if (omask >> i) & 1],
                })

    return {
        "E_NR": E,
        "nonresidue_multisets": multiset_count,
        "structural_cases": multiset_count * len(qr_rows),
        "miss_configurations": miss_count,
        "miss_capable_qr_states": len(miss_qr),
        "odd_contribution_size_histogram": dict(sorted(osize_hist.items())),
        "miss_examples": examples,
    }


def report() -> dict[str, object]:
    qr_rows = qr_precompute()
    packets = [classify_packet_size(E, qr_rows) for E in (0, 2, 4, 6, 8, 10)]

    return {
        "analysis": "k27-even-packet-exhaustion-v1",
        "qr_local_states": len(local_qr_states()),
        "qr_reachable_states": len(qr_rows),
        "packet_results": packets,
        "universal_cutoff": {
            "E_NR_at_least": 10,
            "combined_miss_possible": False,
            "reason": (
                "the exhaustive E_NR=10 group table has no miss; any larger even packet "
                "contains a ten-unit subpacket, and either a fixed Type-I divisor witness "
                "or a Type-II signed-box witness extends unchanged when extra factor "
                "valuation units are adjoined"
            ),
        },
        "claim": "exact finite-group exhaustion plus monotone-witness cutoff; no prime search",
    }


def validate(r: dict[str, object]) -> None:
    if r["qr_reachable_states"] != 40:
        raise SystemExit(f"unexpected QR-state count: {r['qr_reachable_states']}")
    by_e = {row["E_NR"]: row for row in r["packet_results"]}
    for E, expected in EXPECTED.items():
        row = by_e[E]
        for key, value in (
            ("nonresidue_multisets", expected["multisets"]),
            ("miss_configurations", expected["misses"]),
            ("miss_capable_qr_states", expected["miss_qr_states"]),
        ):
            if row[key] != value:
                raise SystemExit(f"E={E}: {key}={row[key]} expected {value}")
    if by_e[10]["miss_configurations"] != 0:
        raise SystemExit("E_NR=10 cutoff failed")


def print_text(r: dict[str, object]) -> None:
    print("k=27 exact even-packet exhaustion")
    print(f"QR reachable states={r['qr_reachable_states']}")
    for row in r["packet_results"]:
        print(
            f"  E={row['E_NR']}: multisets={row['nonresidue_multisets']} "
            f"cases={row['structural_cases']} misses={row['miss_configurations']} "
            f"miss-QR-states={row['miss_capable_qr_states']}"
        )
    print("  E>=10: universal hit by exhaustive cutoff + witness monotonicity")


def main() -> int:
    ap = argparse.ArgumentParser(description="exhaust exact k=27 even nonresidue packets")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    r = report()
    validate(r)
    if args.json:
        print(json.dumps(r, indent=2, sort_keys=True))
    else:
        print_text(r)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
