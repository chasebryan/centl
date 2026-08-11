#!/usr/bin/env python3
"""Verify that the toolchain actually executing an Oasis run matches toolchain.lock."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import platform
import re
import subprocess
import sys
import tomllib
from typing import Sequence


class PinError(RuntimeError):
    pass


def run(root: Path, argv: Sequence[str], *, env: dict[str, str] | None = None) -> str:
    try:
        completed = subprocess.run(
            argv,
            cwd=root,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=60,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PinError(f"cannot execute {' '.join(argv)}: {exc}") from exc
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise PinError(f"{' '.join(argv)} failed: {detail}")
    return completed.stdout.strip()


def expect(label: str, actual: str, expected: str) -> None:
    if actual != expected:
        raise PinError(f"{label} is {actual!r}; toolchain.lock requires {expected!r}")


def opam_exec(root: Path, switch: str, *argv: str) -> str:
    return run(root, ("opam", "exec", f"--switch={switch}", "--", *argv))


def ocamlfind_version(root: Path, switch: str, package: str) -> str:
    return opam_exec(root, switch, "ocamlfind", "query", "-format", "%v", package)


def pkg_version(root: Path, package: str, env: dict[str, str]) -> str:
    return run(root, ("pkg-config", "--modversion", package), env=env).splitlines()[0].strip()


def load_lock(root: Path) -> dict[str, object]:
    path = root / "toolchain.lock"
    try:
        with path.open("rb") as handle:
            lock = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        raise PinError(f"cannot read toolchain.lock: {exc}") from exc
    if lock.get("schema") != 1:
        raise PinError(f"unsupported toolchain.lock schema: {lock.get('schema')!r}")
    return lock


def check(root: Path, switch: str) -> None:
    if platform.system() != "Linux":
        raise PinError(f"Oasis release qualification requires Linux, found {platform.system()}")
    if platform.machine().lower() not in {"x86_64", "amd64"}:
        raise PinError(
            f"Oasis release packaging requires x86_64, found {platform.machine()}"
        )

    lock = load_lock(root)
    verification = lock["verification"]
    runtime = lock["runtime"]
    test = lock["test"]
    development = lock["development"]
    laboratory = lock["laboratory"]

    expect("OCaml", opam_exec(root, switch, "ocamlc", "-version"), runtime["ocaml"])
    expect("Dune", opam_exec(root, switch, "dune", "--version"), runtime["dune"])
    expect(
        "OCamlFormat",
        opam_exec(root, switch, "ocamlformat", "--version"),
        development["ocamlformat"],
    )
    expect("Zarith", ocamlfind_version(root, switch, "zarith"), runtime["zarith"])
    expect("Yojson", ocamlfind_version(root, switch, "yojson"), runtime["yojson"])
    expect("Alcotest", ocamlfind_version(root, switch, "alcotest"), test["alcotest"])
    expect("QCheck", ocamlfind_version(root, switch, "qcheck"), test["qcheck"])

    fstar_output = run(root, ("fstar.exe", "--version"))
    commit = re.search(r"(?:^|\s)commit=([0-9a-f]{40})(?:\s|$)", fstar_output)
    if not commit:
        raise PinError(f"F* did not report an immutable commit identity: {fstar_output!r}")
    expect("F* commit", commit.group(1), verification["fstar_commit"])

    z3_path = run(root, ("fstar.exe", "--locate_z3", verification["z3"]))
    z3_output = run(root, (z3_path, "--version"))
    match = re.search(r"Z3 version ([0-9]+(?:\.[0-9]+)+)", z3_output)
    if not match:
        raise PinError(f"Z3 did not report a parseable version: {z3_output!r}")
    expect("Z3", match.group(1), verification["z3"])

    julia = run(root, ("julia", "--startup-file=no", "-e", "print(VERSION)"))
    expect("Julia", julia, laboratory["julia"])

    native_env = dict(os.environ)
    expect("GMP", pkg_version(root, "gmp", native_env), runtime["gmp"])
    expect("MPFR", pkg_version(root, "mpfr", native_env), runtime["mpfr"])
    expect("FLINT", pkg_version(root, "flint", native_env), runtime["flint"])

    print("Oasis executing toolchain matches toolchain.lock.")


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Verify the executing CENTL Oasis toolchain")
    p.add_argument("--root", type=Path, default=Path.cwd())
    p.add_argument("--opam-switch", default=os.environ.get("OPAM_SWITCH", "centl"))
    return p


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        check(args.root.resolve(), args.opam_switch)
    except PinError as exc:
        print(f"centl oasis toolchain: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
