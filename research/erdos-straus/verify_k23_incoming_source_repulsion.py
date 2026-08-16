#!/usr/bin/env python3
"""Independent exponent-coordinate verification of k=23 source repulsion."""
from __future__ import annotations

import argparse
import json

QR23 = {1, 2, 3, 4, 6, 8, 9, 12, 13, 16, 18}
NONIDENTITY = QR23 - {1}
TYPE_II_TARGETS = {5: 16, 14: 8}
MONOMIALS = {
    2: {5: (2, 0, 2), 14: (1, 0, 2)},
    3: {5: (2, 1, 2), 14: (1, 1, 2)},
    4: {5: (0, 0, 2), 14: (1, 0, 1)},
    6: {5: (0, 1, 2), 14: (0, 2, 1)},
    8: {5: (1, 0, 1), 14: (0, 0, 1)},
    9: {5: (0, 2, 2), 14: (1, 1, 1)},
    12: {5: (0, 2, 1), 14: (0, 2, 2)},
    13: {5: (0, 1, 1), 14: (0, 0, 2)},
    16: {5: (0, 0, 1), 14: (2, 1, 1)},
    18: {5: (1, 1, 1), 14: (0, 1, 1)},
}


def qr_discrete_logs() -> dict[int, int]:
    # 2 has order 11 modulo23 and generates QR(23).
    out: dict[int, int] = {}
    x = 1
    for e in range(11):
        if x in out:
            raise RuntimeError("2 is not a generator of QR(23)")
        out[x] = e
        x = x * 2 % 23
    if set(out) != QR23:
        raise RuntimeError("discrete-log table does not equal QR(23)")
    return out


def exponent_sumset(r: int, logs: dict[int, int]) -> set[int]:
    # Divisors of (6q)^2 have exponents 0..2 in 2,3,q.
    a2 = logs[2]
    a3 = logs[3]
    ar = logs[r]
    return {
        (i * a2 + j * a3 + m * ar) % 11
        for i in range(3)
        for j in range(3)
        for m in range(3)
    }


def monomial_mod23(r: int, exponents: tuple[int, int, int]) -> int:
    a, b, c = exponents
    return pow(2, a, 23) * pow(3, b, 23) * pow(r, c, 23) % 23


def analyze() -> dict[str, object]:
    logs = qr_discrete_logs()
    failures: list[dict[str, object]] = []
    rows = []

    for r in sorted(QR23):
        exponents = exponent_sumset(r, logs)
        saturates = exponents == set(range(11))
        expected = r != 1
        if saturates != expected:
            failures.append({
                "kind": "exponent-saturation",
                "q_mod_23": r,
                "actual": saturates,
                "expected": expected,
                "exponents": sorted(exponents),
            })
        row = {
            "q_mod_23": r,
            "log_base_2": logs[r],
            "exponent_sumset": sorted(exponents),
            "saturates": saturates,
        }
        if r in NONIDENTITY:
            certs = []
            for p23, target in TYPE_II_TARGETS.items():
                abc = MONOMIALS[r][p23]
                value = monomial_mod23(r, abc)
                if value != target:
                    failures.append({
                        "kind": "monomial-target",
                        "q_mod_23": r,
                        "p_mod_23": p23,
                        "actual": value,
                        "expected": target,
                    })
                certs.append({
                    "p_mod_23": p23,
                    "target": target,
                    "exponents": list(abc),
                    "verified_residue": value,
                })
            row["explicit_certificates"] = certs
        rows.append(row)

    # Named source residues already present in the merged research tree.
    named = {13: 13, 31: 8, 47: 1, 59: 13}
    for q, expected_r in named.items():
        if q % 23 != expected_r:
            failures.append({"kind": "named-source-residue", "q": q})

    return {
        "analysis": "k23-source-repulsion-independent-exponent-v1",
        "generator": 2,
        "logs": {str(r): e for r, e in sorted(logs.items())},
        "rows": rows,
        "named_source_residues": {str(q): r for q, r in named.items()},
        "failures": len(failures),
        "failure_examples": failures[:20],
        "claim": (
            "independent QR(23) discrete-log sumset verification: divisors of (6q)^2 "
            "fill all QR exponents exactly when q mod23 is a nonidentity quadratic residue"
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
        print(f"failures: {report['failures']}")
        for row in report["rows"]:
            print(row)
    return 1 if report["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
