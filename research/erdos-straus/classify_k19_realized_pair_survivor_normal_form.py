#!/usr/bin/env python3
"""Classify the exact k=19 survivor normal form on the two pair routes realized by the 380-state closure."""
from __future__ import annotations

import argparse
import json

from classify_exact_state_incoming_repulsion import model

K = 19
QR19 = frozenset(x * x % K for x in range(1, K))

ROUTES = (
    {
        "name": "h169-q17-q23-to-k19",
        "hard_class": 169,
        "source_primes": (17, 23),
        "required_p_mod_sources": (15, 4),
        "source_residues_mod_19": (17, 4),
        "combined_source_seed": 17 * 23,
        "expected_bare_mask": (1, 4, 6, 7, 11, 16, 17),
        "expected_bare_center": 6,
    },
    {
        "name": "h169-q23-q47-to-k19",
        "hard_class": 169,
        "source_primes": (23, 47),
        "required_p_mod_sources": (4, 28),
        "source_residues_mod_19": (4, 9),
        "combined_source_seed": 23 * 47,
        "expected_bare_mask": (1, 4, 5, 9, 11, 16, 17),
        "expected_bare_center": 11,
    },
)


def analyze_route(route: dict[str, object]) -> dict[str, object]:
    m = model(K)
    start = m.seed_state(1)
    for residue in route["source_residues_mod_19"]:
        start = m.transition(start, int(residue))

    start_mask = m.mask_residues(start)
    start_center = m.p_center(start)
    assert tuple(sorted(start_mask)) == route["expected_bare_mask"]
    assert start_center == route["expected_bare_center"]
    assert start_mask != QR19
    assert m.is_miss(start)

    closure = m.closure(start)
    misses = tuple(state for state in closure if m.is_miss(state))
    miss_rows = []
    for state in misses:
        mask = m.mask_residues(state)
        center = m.p_center(state)
        miss_rows.append((center, tuple(sorted(mask))))
    miss_rows.sort()

    full_qr_rows = tuple(row for row in miss_rows if frozenset(row[1]) == QR19)
    partial_rows = tuple(row for row in miss_rows if frozenset(row[1]) != QR19)

    assert len(closure) == 41
    assert len(misses) == 10
    assert len(full_qr_rows) == 9
    assert tuple(center for center, _mask in full_qr_rows) == tuple(sorted(QR19))
    assert partial_rows == ((start_center, tuple(sorted(start_mask))),)

    # The bare routed state has trivial one-step stabilizer. Because exact
    # divisor masks grow monotonically under each residual prime-factor
    # transition, once any non-1 residue is encountered the bare state can
    # never be recovered later.
    stabilizer = tuple(
        residue
        for residue in range(1, K)
        if m.transition(start, residue) == start
    )
    same_mask = tuple(
        residue
        for residue in range(1, K)
        if m.mask_residues(m.transition(start, residue)) == start_mask
    )
    assert stabilizer == (1,)
    assert same_mask == (1,)

    return {
        **route,
        "exact_state_count": len(closure),
        "miss_state_count": len(misses),
        "bare_mask": sorted(start_mask),
        "bare_mask_size": len(start_mask),
        "bare_center": start_center,
        "qr_mask_size": len(QR19),
        "full_qr_miss_centers": sorted(QR19),
        "full_qr_miss_state_count": len(full_qr_rows),
        "partial_miss_states": [
            {"center": center, "mask": list(mask)}
            for center, mask in partial_rows
        ],
        "bare_state_stabilizer_residues": list(stabilizer),
        "bare_mask_preserving_residues": list(same_mask),
        "normal_form": (
            "every k19 miss is either the bare routed seed state or a full-QR mask; "
            "the bare state persists under additional companion factors iff every added "
            "prime-factor residue is 1 mod19"
        ),
    }


def analyze() -> dict[str, object]:
    rows = [analyze_route(route) for route in ROUTES]
    return {
        "analysis": "k19-realized-pair-survivor-normal-form-v1",
        "destination_k": K,
        "hard_class": 169,
        "route_count": len(rows),
        "routes": rows,
        "claim": (
            "on the two pair routes actually realized by the 380-state recursive closure, "
            "the exact k19 miss set has a two-mode normal form: one bare routed state plus "
            "nine full-QR states, and the bare state has trivial residue stabilizer"
        ),
        "claim_boundary": (
            "fixed k19 exact-state theorem on the two named h169 routed branches; it does "
            "not prove that every survivor enters either branch and does not prove ES"
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
            print(row["name"], row["normal_form"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
