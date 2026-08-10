#!/usr/bin/env python3
"""Hermetic regression test for the Unix release installer surface."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "install"
VERSION = "0.14.0"


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
  printf 'centl %s\\n' '0.14.0'
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
  printf 'CENTL-SCi v0.0.2-Caramels\\n'
  printf 'Free for science.\\n\\n'
  printf '> '
  IFS= read -r command || true
  [ "${command:-}" = ":exit" ] || exit 2
else
  printf 'fake centl-sci: unsupported test input\\n' >&2
  exit 2
fi
"""
    mirage = """#!/bin/sh
set -eu
if [ "${1:-}" = "--version" ]; then
  printf 'CENTL-MIRAGE development bootstrap\\n'
else
  printf 'fake centl-mirage: unsupported test input\\n' >&2
  exit 2
fi
"""

    commands = {
        "centl": centl,
        "centl-physics": physics,
        "centl-sci": sci,
        "centl-mirage": mirage,
    }
    for directory in ("bin", "libexec"):
        for command, text in commands.items():
            write_executable(package / directory / command, text)

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

    help_text = subprocess.check_output(["sh", str(INSTALLER), "--help"], text=True)
    if "default: 0.14.0" not in help_text:
        raise SystemExit("installer help does not bind the default release to v0.14.0")

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
        commands = {
            "centl": prefix / "bin" / "centl",
            "centl-physics": prefix / "bin" / "centl-physics",
            "centl-sci": prefix / "bin" / "centl-sci",
            "centl-mirage": prefix / "bin" / "centl-mirage",
        }
        for name, command in commands.items():
            if not command.is_symlink():
                raise SystemExit(f"installer did not activate {name}: {command}")

        sci_output = subprocess.check_output(
            [str(commands["centl-sci"]), "What is 0.1 plus 0.2?"], text=True
        ).strip()
        if sci_output != "3/10":
            raise SystemExit(f"installed CENTL-SCi returned {sci_output!r}")

        repl = subprocess.run(
            [str(commands["centl-sci"]), "--repl"],
            input=":exit\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        ).stdout
        if "CENTL-SCi v0.0.2-Caramels" not in repl or "Free for science." not in repl:
            raise SystemExit(f"installed CENTL-SCi REPL did not initialize correctly:\n{repl}")

        mirage_output = subprocess.check_output(
            [str(commands["centl-mirage"]), "--version"], text=True
        ).strip()
        if mirage_output != "CENTL-MIRAGE development bootstrap":
            raise SystemExit(f"installed CENTL-MIRAGE returned {mirage_output!r}")

        output = completed.stdout
        for expected in (
            "Installed CENTL 0.14.0",
            "CENTL-SCi is ready.",
            "Open a new terminal and run: centl-sci",
            "Scientific command:",
            "MIRAGE command:",
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
        if not (headless_prefix / "bin" / "centl-mirage").is_symlink():
            raise SystemExit("installer did not activate CENTL-MIRAGE without SHELL")
        if not headless_profile.is_file():
            raise SystemExit("installer did not use .profile when SHELL was unset")
        headless_text = headless_profile.read_text(encoding="utf-8")
        if f"# CENTL PATH: {headless_prefix / 'bin'}" not in headless_text:
            raise SystemExit("headless installer PATH setup omitted the CENTL marker")

        static_root = work / "static-releases"
        static_version = static_root / f"v{VERSION}"
        static_version.mkdir(parents=True)
        shutil.copy2(archive, static_version / archive.name)
        shutil.copy2(
            archive.with_name(archive.name + ".sha256"),
            static_version / f"{archive.name}.sha256",
        )

        static_home = work / "static-home"
        static_home.mkdir()
        static_prefix = static_home / "centl"
        static_env = env.copy()
        static_env["HOME"] = str(static_home)
        subprocess.run(
            [
                "sh",
                str(INSTALLER),
                "--version",
                VERSION,
                "--release-base-url",
                static_root.as_uri(),
                "--prefix",
                str(static_prefix),
                "--no-path",
            ],
            cwd=ROOT,
            env=static_env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        if not (static_prefix / "bin" / "centl-sci").is_symlink():
            raise SystemExit("static release-root install did not activate CENTL-SCi")
        if not (static_prefix / "bin" / "centl-mirage").is_symlink():
            raise SystemExit("static release-root install did not activate CENTL-MIRAGE")

        latest = subprocess.run(
            [
                "sh",
                str(INSTALLER),
                "--version",
                "latest",
                "--release-base-url",
                static_root.as_uri(),
                "--prefix",
                str(work / "latest-prefix"),
                "--no-path",
            ],
            cwd=ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if latest.returncode == 0 or "requires an exact --version" not in latest.stderr:
            raise SystemExit("custom release root unexpectedly accepted latest")

        insecure = subprocess.run(
            [
                "sh",
                str(INSTALLER),
                "--version",
                VERSION,
                "--release-base-url",
                "http://example.invalid/releases",
                "--prefix",
                str(work / "insecure-prefix"),
                "--no-path",
            ],
            cwd=ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if insecure.returncode == 0 or "must use https:// or file://" not in insecure.stderr:
            raise SystemExit("installer unexpectedly accepted an insecure release base URL")

    print("CENTL installer interface check: PASS")


if __name__ == "__main__":
    run()
