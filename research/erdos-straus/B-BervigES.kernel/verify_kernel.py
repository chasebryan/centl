#!/usr/bin/env python3
"""Independent checks of B-BervigES.kernel. Does not prove Erdős–Straus."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from bberviges.solve import Solver
from bberviges.witness import verify_witness


CASES = (2, 3, 4, 5, 6, 7, 8, 13, 17, 73, 121, 169, 1009, 10369, 9658489)


def main() -> None:
    solver = Solver(sieve_limit=100_000, k_max=300)
    for n in CASES:
        if n > 2_000_000:
            continue
        r = solver.solve(n)
        if r.witness is None or not verify_witness(r.witness):
            raise SystemExit(f"failed n={n}")
        print(f"OK {r.witness.equation()}  [{r.witness.method}/{r.witness.kind}]")

    # 9658489 is the recorded Type A/B record; allow a larger corridor.
    big = Solver(sieve_limit=100_000, k_max=2800)
    r = big.solve(9_658_489)
    if r.witness is None or not verify_witness(r.witness):
        raise SystemExit("failed record prime 9658489")
    print(f"OK {r.witness.equation()}  [{r.witness.method}/{r.witness.kind}]")

    report = Solver(sieve_limit=20_000, k_max=200).solve_range(300)
    if report["unsolved"]:
        raise SystemExit(f"unsolved in 2..300: {report['unsolved']}")
    print(f"OK range 2..300 solved={report['solved']}")
    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    main()
