#!/usr/bin/env python3
"""B-BervigES.kernel command line — exact reference solver."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from bberviges.cc_bridge import run_cc  # noqa: E402
from bberviges.solve import Solver  # noqa: E402
from bberviges.witness import verify_witness  # noqa: E402


def main() -> None:
    ap = argparse.ArgumentParser(
        prog="bb.kernel",
        description="bb.kernel — Python Erdős–Straus reference stack",
    )
    ap.add_argument("--sieve", type=int, default=200_000)
    ap.add_argument("--k-max", type=int, default=400)
    ap.add_argument(
        "--through",
        choices=("classical", "theorem", "window", "search"),
        default="search",
    )
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_solve = sub.add_parser("solve", help="solve one n")
    p_solve.add_argument("n", type=int)

    p_range = sub.add_parser("range", help="solve every n in 2..limit")
    p_range.add_argument("limit", type=int)

    p_res = sub.add_parser("residual", help="hard-prime residual after theorem layers")
    p_res.add_argument("limit", type=int)

    sub.add_parser("status", help="CC.kernel proof-ledger status")
    p_hunt = sub.add_parser("hunt", help="run CC.kernel until bound or --until-proof")
    p_hunt.add_argument("--until-proof", action="store_true")
    p_hunt.add_argument("--start", type=int, default=20000)
    p_hunt.add_argument("--max-bound", type=int, default=200000)
    p_hunt.add_argument("--rounds", type=int, default=3)

    args = ap.parse_args()
    solver = Solver(
        sieve_limit=max(args.sieve, 16),
        k_max=args.k_max,
        through_layer=args.through,
    )

    if args.cmd == "solve":
        r = solver.solve(args.n)
        if r.witness is None:
            print(json.dumps({"n": args.n, "solved": False, "kernel": "B-BervigES.kernel"}))
            raise SystemExit(2)
        assert verify_witness(r.witness)
        print(
            json.dumps(
                {
                    "kernel": "B-BervigES.kernel",
                    "solved": True,
                    "equation": r.witness.equation(),
                    **r.witness.as_dict(),
                },
                indent=2,
                sort_keys=True,
            )
        )
        return

    if args.cmd == "range":
        print(json.dumps(solver.solve_range(args.limit), indent=2, sort_keys=True))
        return

    if args.cmd == "residual":
        print(json.dumps(solver.residual(args.limit), indent=2, sort_keys=True))
        return

    if args.cmd == "status":
        proc = run_cc("status")
        if proc is None:
            raise SystemExit("CC.kernel is not built; run make -C CC.kernel")
        sys.stdout.write(proc.stdout)
        raise SystemExit(proc.returncode)

    if args.cmd == "hunt":
        extra = [
            "hunt",
            "--start",
            str(args.start),
            "--max-bound",
            str(args.max_bound),
            "--rounds",
            str(args.rounds),
            "--k-max",
            str(args.k_max),
        ]
        if args.until_proof:
            extra.append("--until-proof")
        proc = run_cc(*extra, timeout=3600)
        if proc is None:
            raise SystemExit("CC.kernel is not built; run make -C CC.kernel")
        sys.stdout.write(proc.stdout)
        if proc.stderr:
            sys.stderr.write(proc.stderr)
        raise SystemExit(proc.returncode)


if __name__ == "__main__":
    main()
