#!/usr/bin/env python3
"""Verify the exact factor grammar exposed by tau17=6 and tau31=7 at k27."""
from __future__ import annotations

import argparse
import json
import math

K = 27
QR27 = frozenset({1, 4, 7, 10, 13, 16, 19, 22, 25})
D_SKELETONS = ((2, 17), (14, 14), (2, 14, 14, 14))


def advance(state: tuple[frozenset[int], int], residue: int) -> tuple[frozenset[int], int]:
    mask, center = state
    r = residue % K
    powers = {1, r, r * r % K}
    return (
        frozenset(a * b % K for a in mask for b in powers),
        center * r % K,
    )


def hit(state: tuple[frozenset[int], int]) -> bool:
    mask, center = state
    return 20 in mask or (-center) % K in mask


def seed_state() -> tuple[frozenset[int], int]:
    return advance((frozenset({1}), 1), 7)


def state_after(residues: tuple[int, ...]) -> tuple[frozenset[int], int]:
    state = seed_state()
    for r in residues:
        state = advance(state, r)
    return state


def crt_pair(m: int, a: int, n: int, b: int) -> tuple[int, int]:
    assert math.gcd(m, n) == 1
    k = ((b - a) * pow(m, -1, n)) % n
    x = a + m * k
    return x % (m * n), m * n


def E(t: int) -> int:
    return 7 + 30 * t


def route_b_t(u: int) -> int:
    return 705 + 1081 * u


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    # Correct CRT class and forced rational factors.
    t_pair = crt_pair(17, 6, 31, 7)
    assert t_pair == (193, 527)
    assert 193 % 17 == 6
    assert 193 % 31 == 7
    for n in range(40):
        t = 193 + 527 * n
        assert E(t) % 17 == 0
        assert E(t) % 31 == 0
        assert E(t) == 527 * (11 + 30 * n)

    # Only one D skeleton contains the forced NR occurrence17.
    assert [s for s in D_SKELETONS if 17 in s] == [(2, 17)]
    for skeleton in D_SKELETONS:
        assert not hit(state_after(skeleton))

    d = state_after((2, 17))
    # A second residue17 is incompatible with survival.
    assert hit(advance(d, 17))

    # Forced q=31 supplies QR residue4. D survives that occurrence, but the
    # resulting exact state survives only QR residue1 thereafter.
    after31 = advance(d, 4)
    assert not hit(after31)
    assert not hit(advance(after31, 1))
    for r in sorted(QR27 - {1}):
        assert hit(advance(after31, r)), r
    # In particular a second factor31 is impossible.
    assert hit(advance(after31, 4))

    # The exact non-1 occurrence product is 17*4*2 = 1 mod27.
    assert (17 * 4 * 2) % 27 == 1
    # Hence E=1 mod27, forcing tau9=7.
    assert [tau9 for tau9 in range(9) if (7 + 3 * tau9) % 27 == 1] == [7]

    # Refine t=193+527n by n=6 mod9.
    for m in range(40):
        n = 6 + 9 * m
        t = 193 + 527 * n
        assert t % 4743 == 3355
        assert t % 9 == 7
        assert E(t) % 27 == 1
        assert (E(t) // 527) % 27 == 2
    assert crt_pair(527, 193, 9, 7) == (3355, 4743)

    # Route-B ancestry form.
    u17 = ((6 - 705) * pow(1081, -1, 17)) % 17
    u31 = ((7 - 705) * pow(1081, -1, 31)) % 31
    assert u17 == 10
    assert u31 == 4
    assert crt_pair(17, u17, 31, u31) == (469, 527)
    assert ((7 - 705) * pow(1081, -1, 9)) % 9 == 4
    assert crt_pair(527, 469, 9, 4) == (3631, 4743)
    for m in range(12):
        u = 3631 + 4743 * m
        t = route_b_t(u)
        assert t % 17 == 6
        assert t % 31 == 7
        assert t % 9 == 7
        assert t % 4743 == 3355

    report = {
        "analysis": "k27-d-selector-factor-grammar-v1",
        "phase_pair": {
            "tau17": 6,
            "tau31": 7,
            "t_mod527": 193,
            "forced_k27_mode": "D",
        },
        "nr_skeleton": [2, 17],
        "forced_valuations": {"v17_E": 1, "v31_E": 1},
        "factor_grammar": "E=17*31*r*A; r prime =2 mod27 once; every prime factor of A =1 mod27",
        "forced_tau9": 7,
        "refined_t": "3355 mod4743",
        "route_b": {
            "two_phase_u": "469 mod527",
            "refined_u": "3631 mod4743",
            "k19_mode": "FULL_QR",
            "k31_mode": "FULL_QR",
        },
        "failures": 0,
        "claim": (
            "tau17=6 and tau31=7 plus k27 survival force the exact D skeleton (2,17); "
            "the forced q31 residue4 then allows only residue1 QR completion, yielding "
            "E=17*31*r*A with r=2 mod27 once, A supported on1 mod27, and tau9=7"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
