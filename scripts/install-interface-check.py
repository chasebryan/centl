#!/usr/bin/env python3
"""Hermetic regression test for the Unix release installer surface."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "install"
VERSION = "0.0.0-install-test"


def write_executable(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    path.chmod(0o755)


def build_fake_release(work: Path) -> Path:
    package = work / "payload" / "centl"
    (package / "bin").mkdir(parents=True)
    (package / "libexec").mkdir(parents=True)
    (package / "VERSION").write_text(VERSION + "\n", encoding="utf-8")

    centl = """#!/bin/sh
set -eu
if [ "${1:-}" = "--version" ]; then
  printf 'centl %s\\n' '0.0.0-install-test'
elif [ "${1:-}" = "0.1 + 0.2" ]; then
  printf '3/10\\n'
else
  printf 'fake centl: unsupported test input\\n' >&2
  exit 2
fi
"""
    physics = """#!/bin/sh
set -eu
if [ "${1:-}" = "convert" ] && [ "${2:-}" = "100" ] && [ "${3:-}" = "cm" ] && [ "${4:-}" = "m" ]; then
  printf '1\\n'
else
  printf 'fake centl-physics: unsupported test input\\n' >&2
  exit 2
fi
"""
    sci = """#!/bin/sh
set -eu
if [ "${1:-}" = "What is 0.1 plus 0.2?" ]; then
  printf '3/10\\n'
elif [ "${1:-}" = "--repl" ]; then
  printf 'CENTL-SCi v0.0.1-Camelus\\n'
  printf 'Free for science.\\n\\n'
  printf '> '
  IFS= read -r command || true
  [ "${command:-}" = ":exit" ] || exit 2
else
  printf 'fake centl-sci: unsupported test input\\n' >&2
  exit 2
fi
"""

    for directory in ("bin", "libexec"):
        write_executable(package / directory / "centl", centl)
        write_executable(package / directory / "centl-physics", physics)
        write_executable(package / directory / "centl-sci", sci)

    archive = work / "centl-linux-x86_64.tar.gz"
    with tarfile.open(archive, "w:gz") as output:
        output.add(package, arcname="centl")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_name(archive.name + ".sha256").write_text(
        f"{digest}  {archive.name}\n", encoding="ascii"
    )
    return archive


def run() -> None:
    subprocess.run(["sh", "-n", str(INSTALLER)], check=True)

    with tempfile.TemporaryDirectory(prefix="centl-install-check-") as temporary:
        work = Path(temporary)
        archive = build_fake_release(work)
        home = work / "home"
        home.mkdir()
        env = os.environ.copy()
        env.update(
            {
                "HOME": str(home),
                "SHELL": "/bin/bash",
                "PATH": "/usr/bin:/bin",
            }
        )
        completed = subprocess.run(
            ["sh", str(INSTALLER), "--archive", str(archive)],
            cwd=ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )

        prefix = home / ".local"
        sci_command = prefix / "bin" / "centl-sci"
        physics_command = prefix / "bin" / "centl-physics"
        centl_command = prefix / "bin" / "centl"
        for command in (centl_command, physics_command, sci_command):
            if not command.is_symlink():
                raise SystemExit(f"installer did not activate {command}")

        sci_output = subprocess.check_output(
            [str(sci_command), "What is 0.1 plus 0.2?"], text=True
        ).strip()
        if sci_output != "3/10":
            raise SystemExit(f"installed CENTL-SCi returned {sci_output!r}")

        repl = subprocess.run(
            [str(sci_command), "--repl"],
            input=":exit\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        ).stdout
        if "CENTL-SCi v0.0.1-Camelus" not in repl or "Free for science." not in repl:
            raise SystemExit(f"installed CENTL-SCi REPL did not initialize correctly:\n{repl}")

        output = completed.stdout
        for expected in (
            "CENTL-SCi is ready.",
            "Open a new terminal and run: centl-sci",
            "Scientific command:",
        ):
            if expected not in output:
                raise SystemExit(f"installer output omitted {expected!r}\n{output}")

        bashrc = home / ".bashrc"
        if not bashrc.is_file():
            raise SystemExit("installer did not create the expected Bash PATH setup")
        profile = bashrc.read_text(encoding="utf-8")
        if f"# CENTL PATH: {prefix / 'bin'}" not in profile:
            raise SystemExit("installer did not record the CENTL PATH marker")
        if str(prefix / "bin") not in profile:
            raise SystemExit("installer PATH setup omitted the command directory")

        # Headless CI, containers, and service environments may not export SHELL.
        # The installer must still complete and fall back to the POSIX profile.
        headless_home = work / "headless-home"
        headless_home.mkdir()
        headless_env = env.copy()
        headless_env["HOME"] = str(headless_home)
        headless_env.pop("SHELL", None)
        subprocess.run(
            ["sh", str(INSTALLER), "--archive", str(archive)],
            cwd=ROOT,
            env=headless_env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        headless_prefix = headless_home / ".local"
        headless_profile = headless_home / ".profile"
        if not (headless_prefix / "bin" / "centl-sci").is_symlink():
            raise SystemExit("installer did not activate CENTL-SCi without SHELL")
        if not headless_profile.is_file():
            raise SystemExit("installer did not use .profile when SHELL was unset")
        headless_text = headless_profile.read_text(encoding="utf-8")
        if f"# CENTL PATH: {headless_prefix / 'bin'}" not in headless_text:
            raise SystemExit("headless installer PATH setup omitted the CENTL marker")

    print("CENTL installer interface check: PASS")


if __name__ == "__main__":
    run()
