#!/usr/bin/env python3
"""Hermetic regression test for the GNU/Linux release installer surface."""

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

    scripts = {
        "centl": """#!/bin/sh
set -eu
case "${1:-}" in
  --version) printf 'centl 0.14.0\\n' ;;
  '0.1 + 0.2') printf '3/10\\n' ;;
  *) exit 2 ;;
esac
""",
        "centl-physics": """#!/bin/sh
set -eu
if [ "${1:-}" = convert ] && [ "${2:-}" = 100 ] && [ "${3:-}" = cm ] && [ "${4:-}" = m ]; then
  printf '1\\n'
else
  exit 2
fi
""",
        "centl-sci": """#!/bin/sh
set -eu
if [ "${1:-}" = 'What is 0.1 plus 0.2?' ]; then
  printf '3/10\\n'
elif [ "${1:-}" = --repl ]; then
  printf 'CENTL-SCi v0.0.2-Caramels\\nFree for science.\\n\\n> '
  IFS= read -r command || true
  [ "${command:-}" = :exit ] || exit 2
else
  exit 2
fi
""",
        "centl-mirage": """#!/bin/sh
set -eu
[ "${1:-}" = --version ] || exit 2
printf 'CENTL-MIRAGE development bootstrap\\n'
""",
    }
    for directory in ("bin", "libexec"):
        for command, text in scripts.items():
            write_executable(package / directory / command, text)

    archive = work / "centl-linux-x86_64.tar.gz"
    with tarfile.open(archive, "w:gz") as output:
        output.add(package, arcname="centl")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_name(archive.name + ".sha256").write_text(
        f"{digest}  {archive.name}\n", encoding="ascii"
    )
    return archive


def installer_env(home: Path) -> dict[str, str]:
    env = os.environ.copy()
    env.update(
        {
            "HOME": str(home),
            "SHELL": "/bin/bash",
            "PATH": "/usr/bin:/bin",
        }
    )
    env.pop("CENTL_RELEASE_VERSION", None)
    env.pop("CENTL_RELEASE_BASE_URL", None)
    env.pop("CENTL_PREFIX", None)
    return env


def run() -> None:
    subprocess.run(["sh", "-n", str(INSTALLER)], check=True)
    help_text = subprocess.check_output(["sh", str(INSTALLER), "--help"], text=True)
    if "default network release: 0.14.0" not in help_text:
        raise SystemExit("installer help does not bind network installs to v0.14.0")

    with tempfile.TemporaryDirectory(prefix="centl-install-check-") as temporary:
        work = Path(temporary)
        archive = build_fake_release(work)
        home = work / "home"
        home.mkdir()
        env = installer_env(home)
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
            name: prefix / "bin" / name
            for name in ("centl", "centl-physics", "centl-sci", "centl-mirage")
        }
        for name, command in commands.items():
            if not command.is_symlink():
                raise SystemExit(f"installer did not activate {name}: {command}")

        if subprocess.check_output(
            [str(commands["centl-sci"]), "What is 0.1 plus 0.2?"], text=True
        ).strip() != "3/10":
            raise SystemExit("installed CENTL-SCi failed exact arithmetic")

        repl = subprocess.run(
            [str(commands["centl-sci"]), "--repl"],
            input=":exit\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        ).stdout
        if "CENTL-SCi v0.0.2-Caramels" not in repl or "Free for science." not in repl:
            raise SystemExit("installed CENTL-SCi did not identify as Caramels")

        if subprocess.check_output(
            [str(commands["centl-mirage"]), "--version"], text=True
        ).strip() != "CENTL-MIRAGE development bootstrap":
            raise SystemExit("installed CENTL-MIRAGE failed its identity smoke test")

        for expected in (
            "Installed CENTL 0.14.0",
            "Scientific command:",
            "MIRAGE command:",
            "CENTL-SCi is ready.",
        ):
            if expected not in completed.stdout:
                raise SystemExit(f"installer output omitted {expected!r}")

        if not (home / ".bashrc").is_file():
            raise SystemExit("installer did not configure the Bash PATH")

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
            env=installer_env(static_home),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        if not (static_prefix / "bin" / "centl-mirage").is_symlink():
            raise SystemExit("static release-root install omitted CENTL-MIRAGE")

        latest = subprocess.run(
            [
                "sh",
                str(INSTALLER),
                "--version",
                "latest",
                "--release-base-url",
                static_root.as_uri(),
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
