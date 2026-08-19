#!/usr/bin/env python3
"""Classify the exact k19/k23 survivor coupling on the two realized h169 pair routes."""
from __future__ import annotations

import argparse
import json
import math

from classify_exact_state_incoming_repulsion import model
from classify_k19_realized_pair_survivor_normal_form import ROUTES, analyze_route

K23 = 23
QR23 = frozenset(x * x % K23 for x in range(1, K23))


def k23_rigid_center4() -> dict[str, object]:
    m = model(K23)
    start = m.seed_state(6)
    states = m.closure(start)
    misses = tuple(state for state in states if m.is_miss(state))
    center4 = tuple(state for state in misses if m.p_center(state) == 4)

    assert len(states) == 49
    assert len(misses) == 15
    assert len(center4) == 1
    mask = m.mask_residues(center4[0])
    assert mask == QR23

    return {
        "seed": 6,
        "state_count": len(states),
        "miss_count": len(misses),
        "center": 4,
        "center4_miss_count": len(center4),
        "center4_mask": sorted(mask),
        "center4_mask_is_qr23": True,
    }


def analyze() -> dict[str, object]:
    k23 = k23_rigid_center4()
    rows = []

    for route in ROUTES:
        k19 = analyze_route(route)
        seed = int(route["combined_source_seed"])

        # On h169, C23 has class seed6. Since C23-C19=(23-19)/4=1,
        # writing C19=seed*R and C23=6*B gives 6B-seed*R=1.
        assert (23 - 19) // 4 == 1
        assert math.gcd(6, seed) == 1

        rows.append({
            "name": route["name"],
            "hard_class": 169,
            "source_primes": list(route["source_primes"]),
            "required_p_mod_sources": list(route["required_p_mod_sources"]),
            "k19_seed": seed,
            "k19_bare_center": k19["bare_center"],
            "k19_bare_mask": k19["bare_mask"],
            "k19_full_qr_centers": k19["full_qr_miss_centers"],
            "k23_seed": 6,
            "k23_center": 4,
            "k23_mask": k23["center4_mask"],
            "affine_identity": f"6*B - {seed}*R = 1",
            "gcd_BR": 1,
            "simultaneous_miss_support": {
                "B": "every prime factor is a quadratic residue modulo23",
                "R": (
                    "every prime factor is a quadratic residue modulo19; in bare k19 mode "
                    "every prime factor is 1 modulo19"
                ),
                "overlap": "gcd(B,R)=1",
            },
        })

    return {
        "analysis": "k19-k23-realized-survivor-coupling-v1",
        "hard_class": 169,
        "k23_rigid_state": k23,
        "routes": rows,
        "claim": (
            "on either recursively realized h169 pair route, simultaneous k19 and k23 misses "
            "force coprime residual populations B and R with QR23-only support for B and "
            "QR19-only support for R, sharpened to 1 mod19 support in the bare k19 mode"
        ),
        "claim_boundary": (
            "conditional simultaneous-miss theorem on the two named routes; it is not a "
            "contradiction and does not prove Erdős-Straus"
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = analyze()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        for row in report["routes"]:
            print(row["name"], row["affine_identity"], row["simultaneous_miss_support"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
