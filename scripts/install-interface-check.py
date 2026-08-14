#!/usr/bin/env python3
"""Hermetic regression test for the Unix channel-aware installer surface."""

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


def run_installer(args: list[str], env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["sh", str(INSTALLER), *args],
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )


def require_symlink(path: Path) -> None:
    if not path.is_symlink():
        raise SystemExit(f"installer did not activate {path}")


def run() -> None:
    subprocess.run(["sh", "-n", str(INSTALLER)], check=True)

    with tempfile.TemporaryDirectory(prefix="centl-install-check-") as temporary:
        work = Path(temporary)
        archive = build_fake_release(work)
        home = work / "home"
        home.mkdir()
        env = os.environ.copy()
        env.update({"HOME": str(home), "SHELL": "/bin/bash", "PATH": "/usr/bin:/bin"})

        oasis = run_installer(["--archive", str(archive)], env)
        prefix = home / ".local"
        for name in (
            "centl",
            "centl-physics",
            "centl-sci",
            "oasis-centl",
            "oasis-centl-physics",
            "oasis-centl-sci",
        ):
            require_symlink(prefix / "bin" / name)

        if "Oasis is ready. Start with: centl-sci" not in oasis.stdout:
            raise SystemExit(f"Oasis installer output is incomplete:\n{oasis.stdout}")

        reinstall = run_installer(["--reinstall", "--archive", str(archive)], env)
        if "Installed CENTL oasis channel" not in reinstall.stdout:
            raise SystemExit(f"Oasis reinstall output is incomplete:\n{reinstall.stdout}")

        sci_output = subprocess.check_output(
            [str(prefix / "bin" / "centl-sci"), "What is 0.1 plus 0.2?"], text=True
        ).strip()
        if sci_output != "3/10":
            raise SystemExit(f"installed CENTL-SCi returned {sci_output!r}")

        stable_target_before = (prefix / "bin" / "centl").resolve()
        mirage = run_installer(["--channel", "mirage", "--archive", str(archive)], env)
        for name in ("mirage-centl", "mirage-centl-physics", "mirage-centl-sci"):
            require_symlink(prefix / "bin" / name)
        if "Mirage is ready. Start with: mirage-centl-sci" not in mirage.stdout:
            raise SystemExit(f"Mirage installer output is incomplete:\n{mirage.stdout}")
        if (prefix / "bin" / "centl").resolve() != stable_target_before:
            raise SystemExit("installing Mirage replaced the stable Oasis command")
        if "/channels/oasis/" not in str(stable_target_before):
            raise SystemExit("stable command does not resolve into the Oasis channel")
        if "/channels/mirage/" not in str((prefix / "bin" / "mirage-centl").resolve()):
            raise SystemExit("Mirage command does not resolve into the Mirage channel")

        bashrc = home / ".bashrc"
        if not bashrc.is_file():
            raise SystemExit("installer did not create the expected Bash PATH setup")
        profile = bashrc.read_text(encoding="utf-8")
        if f"# CENTL PATH: {prefix / 'bin'}" not in profile:
            raise SystemExit("installer did not record the CENTL PATH marker")

        headless_home = work / "headless-home"
        headless_home.mkdir()
        headless_env = env.copy()
        headless_env["HOME"] = str(headless_home)
        headless_env["SHELL"] = ""
        run_installer(["--archive", str(archive)], headless_env)
        headless_prefix = headless_home / ".local"
        require_symlink(headless_prefix / "bin" / "centl-sci")
        headless_profile = headless_home / ".profile"
        if not headless_profile.is_file():
            raise SystemExit("installer did not use .profile when SHELL was unset")

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
        run_installer(
            [
                "--channel",
                "oasis",
                "--version",
                VERSION,
                "--release-base-url",
                static_root.as_uri(),
                "--prefix",
                str(static_prefix),
                "--no-path",
            ],
            static_env,
        )
        require_symlink(static_prefix / "bin" / "centl-sci")

        latest = subprocess.run(
            [
                "sh",
                str(INSTALLER),
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
        if latest.returncode == 0 or "requires an explicit --version" not in latest.stderr:
            raise SystemExit("custom release root unexpectedly accepted implicit latest")

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

        invalid = subprocess.run(
            ["sh", str(INSTALLER), "--channel", "sandstorm", "--archive", str(archive)],
            cwd=ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if invalid.returncode == 0 or "must be oasis or mirage" not in invalid.stderr:
            raise SystemExit("installer unexpectedly accepted an unknown channel")

    print("CENTL installer interface check: PASS")


if __name__ == "__main__":
    run()
