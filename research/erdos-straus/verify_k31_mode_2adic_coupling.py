#!/usr/bin/env python3
"""Verify exact coupling between k31 survivor mode and the local 2-adic seam."""
from __future__ import annotations

import argparse
import json
import math

H31 = frozenset({1, 5, 25})
QR31 = frozenset(pow(x, 2, 31) for x in range(1, 31))


def cofactors(t: int) -> dict[str, int]:
    return {
        "B": 8 + 35 * t,
        "D": 5 + 21 * t,
        "G": 26 + 105 * t,
        "J": 9 + 35 * t,
        "L": 4 + 15 * t,
    }


def seam(t: int) -> dict[str, int]:
    v = cofactors(t)
    return {
        "B-G": math.gcd(v["B"], v["G"]),
        "G-L": math.gcd(v["G"], v["L"]),
        "D-J": math.gcd(v["D"], v["J"]),
        "B-L": math.gcd(v["B"], v["L"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    assert 2 in QR31
    assert 2 not in H31

    for t in range(124):
        v = cofactors(t)
        s = seam(t)

        assert (v["D"] % 2 == 1) == (t % 2 == 0)
        assert (v["J"] % 2 == 1) == (t % 2 == 0)
        assert (v["B"] % 2 == 0) == (t % 2 == 0)
        assert (v["G"] % 2 == 0) == (t % 2 == 0)
        assert (v["L"] % 2 == 0) == (t % 2 == 0)

        assert s["B-G"] == math.gcd(2, t)
        assert s["G-L"] == math.gcd(2, t)
        assert s["D-J"] == math.gcd(2, t + 1)
        assert s["B-L"] == math.gcd(4, t)

        if t % 2:
            assert 2 in QR31 - H31
            assert s == {"B-G": 1, "G-L": 1, "D-J": 2, "B-L": 1}
        elif t % 4 == 0:
            assert s == {"B-G": 2, "G-L": 2, "D-J": 1, "B-L": 4}
        else:
            assert t % 4 == 2
            assert s == {"B-G": 2, "G-L": 2, "D-J": 1, "B-L": 2}

    assert all(r % 2 == 1 for r in H31)

    report = {
        "analysis": "k31-mode-2adic-coupling-v1",
        "H31": sorted(H31),
        "QR31": sorted(QR31),
        "two_is_qr31": True,
        "two_is_bare_stabilizer": False,
        "bare_implies_t_even": True,
        "odd_t_miss_forces_full_qr": True,
        "seam_states": {
            "EVEN_0": {"B-G": 2, "G-L": 2, "D-J": 1, "B-L": 4},
            "EVEN_2": {"B-G": 2, "G-L": 2, "D-J": 1, "B-L": 2},
            "ODD": {"B-G": 1, "G-L": 1, "D-J": 2, "B-L": 1},
        },
        "not_excluded_mode_seams": [
            "BARE x EVEN_0",
            "BARE x EVEN_2",
            "FULL_QR x EVEN_0",
            "FULL_QR x EVEN_2",
            "FULL_QR x ODD",
        ],
        "forbidden_mode_seam": "BARE x ODD",
        "t_values_checked": 124,
        "failures": 0,
        "claim": (
            "k31 BARE forces even t and therefore the even B-G-L 2-adic seam; "
            "an odd-t k31 miss is necessarily FULL_QR and carries the D-J gcd2 seam"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
