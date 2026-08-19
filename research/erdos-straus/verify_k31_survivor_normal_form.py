#!/usr/bin/env python3
"""Independent exact-state verification of the h169 k31 survivor normal form."""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, deque

K = 31
TYPE_I_TARGET = (-pow(4, -1, K)) % K
UNITS = tuple(range(1, K))
QR = frozenset(pow(x, 2, K) for x in UNITS)
H31 = frozenset({1, 5, 25})


def seed_state() -> tuple[frozenset[int], int]:
    mask = {1}
    center = 1
    for q in (2, 5):
        center = center * q % K
        mask = {a * b % K for a in mask for b in (1, q % K, q * q % K)}
    return frozenset(mask), center


def transition(
    state: tuple[frozenset[int], int], r: int
) -> tuple[frozenset[int], int]:
    mask, center = state
    powers = {1, r % K, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def hit(state: tuple[frozenset[int], int]) -> tuple[bool, bool]:
    mask, center = state
    type_i = TYPE_I_TARGET in mask
    type_ii = (-center) % K in mask
    return type_i, type_ii


def closure() -> frozenset[tuple[frozenset[int], int]]:
    start = seed_state()
    seen = {start}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        for r in UNITS:
            nxt = transition(state, r)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return frozenset(seen)


def verify_affine_chain() -> dict[str, object]:
    for t in range(31 * 35):
        p = 169 + 840 * t
        C23 = (p + 23) // 4
        C27 = (p + 27) // 4
        C31 = (p + 31) // 4
        B = 8 + 35 * t
        E = 7 + 30 * t
        D = 5 + 21 * t
        assert C23 == 6 * B
        assert C27 == 7 * E
        assert C31 == 10 * D
        assert 7 * E - 6 * B == 1
        assert 10 * D - 7 * E == 1
        assert 5 * D - 3 * B == 1
        assert math.gcd(B, E) == 1
        assert math.gcd(E, D) == 1
        assert math.gcd(B, D) == 1
    return {
        "t_values_checked": 31 * 35,
        "relations": [
            "7E-6B=1",
            "10D-7E=1",
            "5D-3B=1",
        ],
        "pairwise_coprime": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    M0, c0 = seed_state()
    expected_m0 = frozenset({1, 2, 4, 5, 7, 10, 19, 20, 25})
    expected_qr = frozenset({1, 2, 4, 5, 7, 8, 9, 10, 14, 16, 18, 19, 20, 25, 28})
    assert M0 == expected_m0
    assert c0 == 10
    assert QR == expected_qr
    assert TYPE_I_TARGET == 23
    assert TYPE_I_TARGET not in QR
    assert pow(K - 1, (K - 1) // 2, K) == K - 1

    states = closure()
    misses = [state for state in states if not any(hit(state))]
    hits = [state for state in states if any(hit(state))]
    assert len(states) == 75
    assert len(misses) == 18
    assert len(hits) == 57

    miss_by_mask: Counter[frozenset[int]] = Counter(mask for mask, _center in misses)
    assert set(miss_by_mask) == {M0, QR}
    assert miss_by_mask[M0] == 3
    assert miss_by_mask[QR] == 15

    bare_centers = frozenset(center for mask, center in misses if mask == M0)
    full_centers = frozenset(center for mask, center in misses if mask == QR)
    assert bare_centers == frozenset({2, 10, 19})
    assert full_centers == QR

    stabilizer = frozenset(
        r for r in UNITS
        if transition((M0, c0), r)[0] == M0
    )
    assert stabilizer == H31

    for r in QR:
        mask, _center = transition((M0, c0), r)
        if r in H31:
            assert mask == M0
        else:
            assert mask == QR

    nonresidues = frozenset(set(UNITS) - set(QR))
    assert len(nonresidues) == 15

    # This is the exact converse engine: every reachable state whose divisor
    # mask contains a nonresidue is a hit. Hence a miss cannot contain any
    # nonresidue prime-factor residue.
    for state in states:
        mask, _center = state
        if not set(mask).issubset(QR):
            assert any(hit(state))

    # A factor31 is an immediate Type-II hit because the target and an
    # available divisor are both0 modulo31.
    assert 31 % K == 0

    report = {
        "analysis": "h169-k31-survivor-normal-form-v1",
        "states": len(states),
        "hits": len(hits),
        "misses": len(misses),
        "type_i_target": TYPE_I_TARGET,
        "seed_mask": sorted(M0),
        "qr31": sorted(QR),
        "bare": {
            "mask": sorted(M0),
            "centers": sorted(bare_centers),
            "stabilizer": sorted(stabilizer),
        },
        "full_qr": {
            "mask": sorted(QR),
            "centers": sorted(full_centers),
        },
        "miss_masks": {
            "seed_mask_count": miss_by_mask[M0],
            "full_qr_count": miss_by_mask[QR],
            "intermediate_count": 0,
        },
        "affine_chain": verify_affine_chain(),
        "failures": 0,
        "claim": (
            "exact 75-state k31 closure: h169 k31 misses iff all prime factors of "
            "D=C31/10 are nonzero quadratic residues mod31; misses compress to BARE "
            "with residues {1,5,25} or FULL_QR"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
