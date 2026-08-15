#!/usr/bin/env python3
"""Finite regression for MERSENNE-SHADOW-LATTICE.md.

Checks, for power-of-two depths k=2^a up to a configurable exponent:

* ord_{2^(a+2)-1}(2)=a+2;
* T_{2^a}=-<2>;
* every divisibility edge a+2 | b+2 gives exact direct shadow
  T_{2^b} mod m_a subset T_{2^a}.

This is a theorem regression test, not the proof itself.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def divisors_power_two(a: int) -> list[int]:
    return [1 << i for i in range(a + 1)]


def trap(a: int) -> set[int]:
    k = 1 << a
    m = (1 << (a + 2)) - 1
    return {r for e in divisors_power_two(a) for r in ((-e) % m, (-4 * e) % m)}


def subgroup_two(a: int) -> set[int]:
    m = (1 << (a + 2)) - 1
    out = set()
    x = 1
    while x not in out:
        out.add(x)
        x = (2 * x) % m
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-exponent", type=int, default=24)
    ap.add_argument("--out", type=Path, default=Path("mersenne-shadow-output"))
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    rows = []
    for a in range(1, args.max_exponent + 1):
        m = (1 << (a + 2)) - 1
        H = subgroup_two(a)
        T = trap(a)
        if len(H) != a + 2:
            raise AssertionError(f"order failure at a={a}")
        if T != {(-h) % m for h in H}:
            raise AssertionError(f"trap-coset equality failure at a={a}")
        rows.append({"a": a, "k": 1 << a, "m": m, "trap_size": len(T)})

    edges = []
    for b in range(2, args.max_exponent + 1):
        mb = (1 << (b + 2)) - 1
        Tb = trap(b)
        for a in range(1, b):
            if (b + 2) % (a + 2):
                continue
            ma = (1 << (a + 2)) - 1
            Ta = trap(a)
            if mb % ma:
                raise AssertionError("Mersenne modulus divisibility failed")
            if {x % ma for x in Tb} - Ta:
                raise AssertionError(f"shadow inclusion failed a={a} b={b}")
            edges.append(
                {
                    "source_a": a,
                    "source_k": 1 << a,
                    "target_b": b,
                    "target_k": 1 << b,
                    "source_shift": a + 2,
                    "target_shift": b + 2,
                }
            )

    structurally_killed = [
        b
        for b in range(3, args.max_exponent + 1)
        if any((b + 2) % (a + 2) == 0 for a in range(1, b))
    ]

    result = {
        "status": "exact finite regression of the proved Mersenne shadow lattice",
        "max_exponent": args.max_exponent,
        "power_two_layers_checked": len(rows),
        "shadow_edges_checked": len(edges),
        "structurally_killed_exponents": structurally_killed,
        "rows": rows,
        "edges": edges,
        "verdict": "VERIFIED",
    }
    (args.out / "mersenne-shadow-analysis.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n"
    )

    report = "# Mersenne shadow lattice regression\n\n"
    report += f"Power-of-two exponents checked: `1..{args.max_exponent}`.\n\n"
    report += f"Exact shadow edges checked: **`{len(edges)}`**.\n\n"
    report += "All `T_{2^a}=-<2>` and shifted-exponent divisibility checks passed.\n\n"
    report += "Structurally killed exponents in range:\n\n```text\n"
    report += " ".join(map(str, structurally_killed)) + "\n```\n"
    (args.out / "mersenne-shadow-analysis-report.md").write_text(report)
    print(report)


if __name__ == "__main__":
    main()
