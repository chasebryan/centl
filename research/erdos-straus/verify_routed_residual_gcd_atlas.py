#!/usr/bin/env python3
"""Independent arithmetic regression for routed residual gcd constraints."""
from __future__ import annotations

import argparse
import json
import math

PAIR_SYNERGIES = (
    (121, 31, 2, (19, 47), 1786, (7, 16)),
    (121, 79, 10, (19, 23), 4370, (16, 13)),
    (169, 19, 1, (11, 23), 253, (3, 4)),
    (169, 83, 21, (11, 23), 5313, (5, 9)),
    (169, 83, 21, (11, 31), 7161, (5, 10)),
    (169, 83, 21, (23, 31), 14973, (9, 10)),
    (169, 167, 42, (11, 31), 14322, (9, 19)),
    (529, 19, 1, (11, 23), 253, (3, 4)),
)

TRIPLE_SYNERGIES = (
    (169, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (289, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
    (289, 167, 6, (11, 31, 47), 96162, (9, 19, 21)),
    (529, 79, 2, (11, 23, 31), 15686, (9, 13, 14)),
    (529, 83, 3, (11, 23, 31), 23529, (5, 9, 10)),
)

FULL_COPRIME_PAIR_BRANCHES = {
    (121, 79, (19, 23)),
    (169, 19, (11, 23)),
    (529, 19, (11, 23)),
}
ALLOWED_NONTRIVIAL_GCDS = {2, 3, 13, 17}


def class_seed(k: int, h: int) -> int:
    return math.gcd(210, (h + k) // 4)


def route_r0(h: int, sources: tuple[int, ...], residues: tuple[int, ...]) -> tuple[int, int]:
    modulus = math.prod(sources)
    matches = [
        r for r in range(modulus)
        if all((840 * r + h) % q == a for q, a in zip(sources, residues))
    ]
    if len(matches) != 1:
        raise AssertionError((h, sources, residues, matches))
    return matches[0], modulus


def companions(p: int, shifts: tuple[int, ...]) -> dict[int, int]:
    out = {}
    for k in shifts:
        if (p + k) % 4:
            raise AssertionError((p, k))
        out[k] = (p + k) // 4
    return out


def verify_flagship_identities() -> None:
    # h=169/529, q11+q23 -> k19.
    for h in (169, 529):
        r0, modulus = route_r0(h, (11, 23), (3, 4))
        for t in range(1000):
            r = r0 + modulus * t
            p = 840 * r + h
            c = companions(p, (11, 19, 23))
            assert c[11] % 15 == 0
            assert c[19] % 253 == 0
            assert c[23] % 6 == 0
            a = c[11] // 15
            b = c[23] // 6
            rr = c[19] // 253
            assert 15 * a - 253 * rr == -2
            assert 6 * b - 253 * rr == 1
            assert 5 * a - 2 * b == -1
            assert a % 2 == 1 and rr % 2 == 1
            assert math.gcd(a, b) == math.gcd(a, rr) == math.gcd(b, rr) == 1

    # h=121, q19+q23 -> k79.
    h = 121
    r0, modulus = route_r0(h, (19, 23), (16, 13))
    for t in range(1000):
        r = r0 + modulus * t
        p = 840 * r + h
        c = companions(p, (19, 23, 79))
        assert c[19] % 35 == 0
        assert c[23] % 6 == 0
        assert c[79] % 4370 == 0
        a = c[19] // 35
        b = c[23] // 6
        rr = c[79] // 4370
        assert 7 * a - 874 * rr == -3
        assert 3 * b - 2185 * rr == -7
        assert 35 * a - 6 * b == -1
        assert a % 3 == 1
        assert b % 7 == 6
        assert math.gcd(a, b) == math.gcd(a, rr) == math.gcd(b, rr) == 1

    # h=121, q19+q47 -> k31. Only a factor 2 may be shared by A47 and R.
    r0, modulus = route_r0(121, (19, 47), (7, 16))
    seen_two = False
    for t in range(1000):
        r = r0 + modulus * t
        p = 840 * r + 121
        c = companions(p, (19, 31, 47))
        a = c[19] // 35
        b = c[47] // 42
        rr = c[31] // 1786
        assert 35 * a - 1786 * rr == -3
        assert 21 * b - 893 * rr == 2
        assert 5 * a - 6 * b == -1
        assert a % 3 == 1
        assert math.gcd(a, b) == 1
        assert math.gcd(a, rr) == 1
        assert math.gcd(b, rr) in (1, 2)
        seen_two |= math.gcd(b, rr) == 2
    assert seen_two


def verify_all_branches(iterations: int) -> dict[str, int]:
    checked = 0
    nontrivial_seen: set[int] = set()
    full_coprime_seen: set[tuple[int, int, tuple[int, ...]]] = set()

    for kind, rows in (("pair", PAIR_SYNERGIES), ("triple", TRIPLE_SYNERGIES)):
        for h, destination, _base, sources, destination_seed, residues in rows:
            r0, modulus = route_r0(h, sources, residues)
            source_seeds = [class_seed(q, h) for q in sources]
            branch_key = (h, destination, sources)

            for t in range(iterations):
                r = r0 + modulus * t
                p = 840 * r + h
                shifts = tuple(sources) + (destination,)
                c = companions(p, shifts)

                values = []
                for q, seed in zip(sources, source_seeds):
                    assert c[q] % seed == 0
                    values.append(c[q] // seed)
                assert c[destination] % destination_seed == 0
                values.append(c[destination] // destination_seed)

                gcds = []
                for i, left in enumerate(values):
                    for right in values[i + 1 :]:
                        g = math.gcd(left, right)
                        gcds.append(g)
                        if g > 1:
                            nontrivial_seen.add(g)
                            assert g in ALLOWED_NONTRIVIAL_GCDS

                if kind == "pair":
                    assert math.gcd(values[0], values[1]) == 1
                    if branch_key in FULL_COPRIME_PAIR_BRANCHES:
                        assert all(g == 1 for g in gcds)
                        full_coprime_seen.add(branch_key)
                checked += 1

    assert full_coprime_seen == FULL_COPRIME_PAIR_BRANCHES
    return {
        "branch_parameter_values_checked": checked,
        "nontrivial_gcd_values_seen": len(nontrivial_seen),
    }


def verify_record_anchor() -> dict[str, int]:
    p = 8_803_369
    assert p % 840 == 169
    assert p % 11 == 3
    assert p % 23 == 4
    c = companions(p, (11, 19, 23))
    a = c[11] // 15
    b = c[23] // 6
    rr = c[19] // 253
    assert (a, b, rr) == (146_723, 366_808, 8_699)
    assert 15 * a - 253 * rr == -2
    assert 6 * b - 253 * rr == 1
    assert 5 * a - 2 * b == -1
    assert math.gcd(a, b) == math.gcd(a, rr) == math.gcd(b, rr) == 1
    return {"A11": a, "A23": b, "R19": rr}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--iterations", type=int, default=2000)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    verify_flagship_identities()
    counts = verify_all_branches(args.iterations)
    anchor = verify_record_anchor()
    report = {
        "analysis": "routed-residual-gcd-independent-regression-v1",
        "iterations_per_branch": args.iterations,
        **counts,
        "record_anchor": anchor,
        "failures": 0,
        "claim": (
            "independent arithmetic regression of the exact residual identities and "
            "gcd restrictions on the current multi-source saturation branches"
        ),
    }
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"branch parameter values checked: {counts['branch_parameter_values_checked']}")
        print(f"record residuals: {anchor}")
        print("failures: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
