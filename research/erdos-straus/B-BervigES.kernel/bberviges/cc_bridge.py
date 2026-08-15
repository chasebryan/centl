"""Call CC.kernel when it can provide the witness or hunt."""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

from .witness import Witness, make_witness, verify_witness


def repo_es_root() -> Path:
    here = Path(__file__).resolve()
    return here.parents[2]


def cc_binary() -> Path | None:
    env = os.environ.get("CC_KERNEL")
    if env:
        p = Path(env)
        if p.is_file() and os.access(p, os.X_OK):
            return p
    cand = repo_es_root() / "CC.kernel" / "cc-kernel"
    if cand.is_file() and os.access(cand, os.X_OK):
        return cand
    return None


def run_cc(*args: str, timeout: int = 120) -> subprocess.CompletedProcess[str] | None:
    binary = cc_binary()
    if binary is None:
        return None
    return subprocess.run(
        [str(binary), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        cwd=str(binary.parent),
        check=False,
    )


def witness_from_cc_json(obj: dict) -> Witness | None:
    if not obj.get("solved"):
        return None
    n = int(obj.get("p") or obj.get("n") or 0)
    if n < 2:
        return None
    w = make_witness(
        n,
        int(obj["x"]),
        int(obj["y"]),
        int(obj["z"]),
        layer=str(obj.get("layer", "cc")),
        method=str(obj.get("method", "cc")),
        kind=str(obj.get("kind", "cc")),
        detail={"provider": "CC.kernel", "k": obj.get("k")},
    )
    if not verify_witness(w):
        return None
    return w


def solve_via_cc(n: int, *, k_max: int = 400, through: str = "search") -> Witness | None:
    proc = run_cc("solve", str(n), "--k-max", str(k_max), "--through", through)
    if proc is None or proc.returncode not in (0, 1) or not proc.stdout.strip():
        return None
    try:
        obj = json.loads(proc.stdout.splitlines()[-1])
    except json.JSONDecodeError:
        return None
    return witness_from_cc_json(obj)
