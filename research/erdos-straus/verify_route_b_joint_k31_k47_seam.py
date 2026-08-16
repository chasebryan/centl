#!/usr/bin/env python3
"""Verify Route-B joint k31/k47 mode coupling through the exact 2-adic seam."""
from __future__ import annotations

import argparse
import json
import math

H31 = frozenset({1, 5, 25})
QR31 = frozenset(pow(x, 2, 31) for x in range(1, 31))
QR47 = frozenset(pow(x, 2, 47) for x in range(1, 47))
THIN_ALLOWED_NON1 = frozenset({3, 9})


def route_b_t(u: int) -> int:
    return 705 + 1081 * u


def values(t: int) -> dict[str, int]:
    return {
        "B": 8 + 35 * t,
        "D": 5 + 21 * t,
        "G": 26 + 105 * t,
        "J": 9 + 35 * t,
        "L": 4 + 15 * t,
    }


def seam(t: int) -> dict[str, int]:
    v = values(t)
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
    assert 2 in QR47
    assert 2 not in THIN_ALLOWED_NON1
    assert 2 != 1

    # Route-B ancestry and parity/seam relations.
    for u in range(248):
        t = route_b_t(u)
        v = values(t)
        s = seam(t)

        assert t % 23 == 15
        assert t % 47 == 0
        assert (t % 2 == 0) == (u % 2 == 1)
        assert (v["D"] % 2 == 0) == (t % 2 == 1)
        assert (v["J"] % 2 == 0) == (t % 2 == 1)
        assert s["D-J"] == math.gcd(2, t + 1)
        assert s["B-G"] == math.gcd(2, t)
        assert s["G-L"] == math.gcd(2, t)
        assert s["B-L"] == math.gcd(4, t)

        if t % 2:
            # The same rational prime2 occurs in D and J.
            assert v["D"] % 2 == 0
            assert v["J"] % 2 == 0
            assert s["D-J"] == 2
            # At k31, residue2 is QR but outside BARE H31.
            assert 2 in QR31 - H31
            # At k47, residue2 is QR but is forbidden by the exact THIN grammar.
            assert 2 in QR47
            assert 2 not in {1, 3, 9}
            assert s == {"B-G": 1, "G-L": 1, "D-J": 2, "B-L": 1}
        elif t % 4 == 0:
            assert s == {"B-G": 2, "G-L": 2, "D-J": 1, "B-L": 4}
        else:
            assert t % 4 == 2
            assert s == {"B-G": 2, "G-L": 2, "D-J": 1, "B-L": 2}

    # Formal product-state filtering. We distinguish two even seams and one odd seam.
    modes31 = ("BARE", "FULL_QR")
    modes47 = ("THIN", "FULL_QR")
    seams = ("EVEN_0", "EVEN_2", "ODD")
    not_excluded = []
    forbidden = []
    for m31 in modes31:
        for m47 in modes47:
            for s in seams:
                bad = s == "ODD" and (m31 == "BARE" or m47 == "THIN")
                row = f"{m31} x {m47} x {s}"
                (forbidden if bad else not_excluded).append(row)

    assert len(not_excluded) == 9
    assert len(forbidden) == 3
    assert forbidden == [
        "BARE x THIN x ODD",
        "BARE x FULL_QR x ODD",
        "FULL_QR x THIN x ODD",
    ]
    assert "FULL_QR x FULL_QR x ODD" in not_excluded

    # BARE phase shadow: D mod31 must lie in H31.
    inv21 = pow(21, -1, 31)
    assert inv21 == 3
    bare_t31 = frozenset(((h - 5) * inv21) % 31 for h in H31)
    assert bare_t31 == frozenset({0, 19, 29})

    # Route B: t = 23 + 27u mod31; solve for u and then impose u odd.
    inv27 = pow(27, -1, 31)
    assert inv27 == 23
    bare_u31 = frozenset(((t - 23) * inv27) % 31 for t in bare_t31)
    assert bare_u31 == frozenset({1, 14, 29})
    bare_u62 = frozenset(
        next(x for x in (r, r + 31) if x % 2 == 1)
        for r in bare_u31
    )
    assert bare_u62 == frozenset({1, 29, 45})

    report = {
        "analysis": "route-b-joint-k31-k47-seam-v1",
        "route_b": "t=705+1081u",
        "k31_modes": list(modes31),
        "k47_modes": list(modes47),
        "two_in_qr31_not_h31": True,
        "two_in_qr47_not_thin_grammar": True,
        "odd_sector_forced_modes": ["FULL_QR", "FULL_QR"],
        "odd_sector_gcd_D_J": 2,
        "even_sector_gcd_D_J": 1,
        "not_excluded_mode_seams": not_excluded,
        "forbidden_mode_seams": forbidden,
        "k31_bare_t_mod31": sorted(bare_t31),
        "route_b_k31_bare_u_mod31": sorted(bare_u31),
        "route_b_k31_bare_u_mod62": sorted(bare_u62),
        "u_values_checked": 248,
        "failures": 0,
        "claim": (
            "on realized Route B, an odd-t simultaneous k31/k47 survivor is forced to "
            "FULL_QR at both shifts and has gcd(D,J)=2; any BARE31 or THIN47 survivor "
            "forces the even seam with gcd(D,J)=1"
        ),
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
