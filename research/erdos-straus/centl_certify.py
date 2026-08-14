#!/usr/bin/env python3
"""Generate and execute CENTL exact contracts for WS-CAND-003 outputs."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


def run(cmd: list[str], stdout_path: Path | None = None) -> str:
    print("+", " ".join(cmd), flush=True)
    cp = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
    if stdout_path is not None:
        stdout_path.write_text(cp.stdout)
    print(cp.stdout, end="")
    if cp.returncode != 0:
        raise SystemExit(f"CENTL command failed with exit code {cp.returncode}: {' '.join(cmd)}")
    return cp.stdout


def decomposition(row: dict) -> tuple[int, int, int]:
    p = row["p"]
    k = row["C_AB"]
    d, n, q = row["d"], row["n"], row["q"]
    if row["type"] == "B":
        return k * q, d * q * p, k * p
    if row["type"] == "A":
        u = n * q - 1
        return d * u, k * p, k * p * u
    raise ValueError(row["type"])


def family_expressions(row: dict) -> tuple[str, str, str, str]:
    k, d, n, m = row["C_AB"], row["d"], row["n"], row["m"]
    if row["type"] == "B":
        P = f"({m}*t-{n})"
        X = f"({k}*t)"
        Y = f"({d}*t*{P})"
        Z = f"({k}*{P})"
        return P, X, Y, Z
    if row["type"] == "A":
        P = f"({m}*t-{4*d})"
        U = f"({n}*t-1)"
        X = f"({d}*{U})"
        Y = f"({k}*{P})"
        Z = f"({k}*{P}*{U})"
        return P, X, Y, Z
    raise ValueError(row["type"])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--centl", required=True)
    ap.add_argument("--out", type=Path, default=Path("research-output"))
    args = ap.parse_args()
    out = args.out
    centl = args.centl

    frontier = json.loads((out / "frontier.json").read_text())
    edges = json.loads((out / "ancestry-edges.json").read_text())
    quotients = sorted({e["quotient"] for e in edges if e["modulus_divides"] and e["quotient"] is not None})

    contract = out / "generated-centl-research-contracts.centl"
    lines = [
        "# Generated exact contracts for WS-CAND-003.",
        "# These certify algebraic identities only. They do not establish literature novelty, primality theorems, or global Erdos-Straus coverage.",
        "",
        "# Frontier closed exact decompositions and fixed-(d,n) polynomial families",
    ]

    closed_rows = []
    for row in frontier:
        p = row["p"]
        x, y, z = decomposition(row)
        lines.append(f"equal | 4/{p} | 1/{x} + 1/{y} + 1/{z}")
        P, X, Y, Z = family_expressions(row)
        lines.append(f"equal | 4*{X}*{Y}*{Z} | {P}*{Y}*{Z} + {P}*{X}*{Z} + {P}*{X}*{Y} | t:rational")
        closed_rows.append({"p": p, "C_AB": row["C_AB"], "type": row["type"], "x": x, "y": y, "z": z})

    lines += ["", "# Modulus-ancestry algebra for every observed divisibility quotient"]
    for q in quotients:
        if q % 4 != 1:
            raise RuntimeError(f"invalid ancestry quotient {q}")
        s = (q - 1) // 4
        # If k=q*j-s then 4k-1=q(4j-1).  This contract certifies the fixed-q polynomial identity.
        lines.append(f"equal | 4*({q}*j-{s})-1 | {q}*(4*j-1) | j:rational")

    contract.write_text("\n".join(lines) + "\n")
    (out / "frontier-decompositions.json").write_text(json.dumps(closed_rows, indent=2, sort_keys=True) + "\n")

    run([centl, "--version"], out / "centl-version.txt")
    run([centl, "--build-info"], out / "centl-build-info.txt")
    check_out = run([centl, "check", str(contract), "--receipt", str(out / "centl-research-contracts-receipt.json")], out / "centl-check-output.txt")
    if "verified" not in check_out.lower():
        raise SystemExit("CENTL check completed without a visible verified verdict")

    # Preserve a dedicated proof-carrying receipt for the record fixed family.
    record = max(frontier, key=lambda r: r["C_AB"])
    P, X, Y, Z = family_expressions(record)
    verify_out = run([
        centl,
        "verify",
        "--left", f"4*{X}*{Y}*{Z}",
        "--relation", "equal",
        "--right", f"{P}*{Y}*{Z} + {P}*{X}*{Z} + {P}*{X}*{Y}",
        "--variable", "t:rational",
        "--receipt", str(out / f"centl-record-p{record['p']}-C{record['C_AB']}.json"),
    ], out / "centl-record-verify-output.txt")
    if "verified" not in verify_out.lower():
        raise SystemExit("record-family CENTL verification did not report verified")

    summary = {
        "frontier_closed_identities": len(frontier),
        "frontier_fixed_parameter_polynomial_families": len(frontier),
        "observed_modulus_ancestry_quotient_identities": len(quotients),
        "record_prime": record["p"],
        "record_C_AB": record["C_AB"],
        "verdict": "CENTL exact contracts verified",
        "scope_note": "CENTL certifies the exact and polynomial algebra supplied to it; external number-theoretic and novelty claims remain separately justified.",
    }
    (out / "centl-certification-summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
