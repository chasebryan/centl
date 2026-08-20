#!/usr/bin/env python3
"""Reject GNU/Linux release roots that are newer than CENTL's portable ABI floor."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import tempfile

DEFAULT_MAX_GLIBC = "2.31"
ALLOWED_INTERPRETERS = {
    "/lib64/ld-linux-x86-64.so.2",
    "/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2",
}
BASE_SYSTEM_LIBRARIES = {
    "libc.so.6",
    "libm.so.6",
    "libpthread.so.0",
    "libdl.so.2",
    "librt.so.1",
    "libgcc_s.so.1",
    "ld-linux-x86-64.so.2",
}
PUBLIC_EXECUTABLES = ("centl", "centl-physics", "centl-sci")
GLIBC_RE = re.compile(r"\bGLIBC_(\d+)\.(\d+)\b")
INTERP_RE = re.compile(r"Requesting program interpreter:\s*([^\]]+)")
NEEDED_RE = re.compile(r"\(NEEDED\).*Shared library: \[([^\]]+)\]")


class PortabilityError(RuntimeError):
    pass


def parse_version(value: str) -> tuple[int, int]:
    match = re.fullmatch(r"(\d+)\.(\d+)", value.strip())
    if not match:
        raise PortabilityError(f"invalid glibc baseline: {value}")
    return int(match.group(1)), int(match.group(2))


def readelf(path: Path, *arguments: str) -> str:
    try:
        completed = subprocess.run(
            ["readelf", *arguments, str(path)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except FileNotFoundError as exc:
        raise PortabilityError("readelf is required to qualify a Linux release") from exc
    except subprocess.CalledProcessError as exc:
        raise PortabilityError(f"readelf failed for {path}: {exc.stdout.strip()}") from exc
    return completed.stdout


def highest_glibc(text: str) -> tuple[int, int] | None:
    versions = {(int(major), int(minor)) for major, minor in GLIBC_RE.findall(text)}
    return max(versions) if versions else None


def interpreter(text: str) -> str | None:
    match = INTERP_RE.search(text)
    return match.group(1).strip() if match else None


def needed_libraries(text: str) -> set[str]:
    return set(NEEDED_RE.findall(text))


def require_elf(path: Path) -> None:
    try:
        with path.open("rb") as handle:
            magic = handle.read(4)
    except OSError as exc:
        raise PortabilityError(f"cannot read release object {path}: {exc}") from exc
    if magic != b"\x7fELF":
        raise PortabilityError(f"release object is not ELF: {path}")


def inspect_object(
    path: Path,
    *,
    package_libraries: set[str],
    max_glibc: tuple[int, int],
    executable: bool,
) -> None:
    require_elf(path)

    if executable:
        interp = interpreter(readelf(path, "-lW"))
        if interp not in ALLOWED_INTERPRETERS:
            shown = interp if interp is not None else "<none>"
            raise PortabilityError(
                f"{path.name} uses unsupported ELF interpreter {shown}; "
                "GNU/Linux x86_64 releases must use a standard glibc loader"
            )

    required = highest_glibc(readelf(path, "--version-info", "-W"))
    if required is not None and required > max_glibc:
        raise PortabilityError(
            f"{path.name} requires GLIBC_{required[0]}.{required[1]}, "
            f"newer than the release baseline GLIBC_{max_glibc[0]}.{max_glibc[1]}"
        )

    for library in sorted(needed_libraries(readelf(path, "-dW"))):
        if library in BASE_SYSTEM_LIBRARIES or library in package_libraries:
            continue
        raise PortabilityError(f"{path.name} depends on unbundled runtime library {library}")


def inspect_release_root(root: Path, max_glibc: tuple[int, int]) -> None:
    libexec = root / "libexec"
    library_dir = root / "lib"
    if not libexec.is_dir() or not library_dir.is_dir():
        raise PortabilityError("release root must contain libexec/ and lib/")

    package_libraries = {entry.name for entry in library_dir.iterdir() if entry.is_file()}
    for command in PUBLIC_EXECUTABLES:
        path = libexec / command
        if not path.is_file():
            raise PortabilityError(f"release root is missing libexec/{command}")
        inspect_object(
            path,
            package_libraries=package_libraries,
            max_glibc=max_glibc,
            executable=True,
        )

    for path in sorted(library_dir.iterdir()):
        if not path.is_file():
            continue
        inspect_object(
            path,
            package_libraries=package_libraries,
            max_glibc=max_glibc,
            executable=False,
        )


def safe_extract(archive: Path, destination: Path) -> Path:
    with tarfile.open(archive, "r:gz") as package:
        members = package.getmembers()
        for member in members:
            path = Path(member.name)
            if path.is_absolute() or ".." in path.parts:
                raise PortabilityError(f"unsafe archive member: {member.name}")
            if not (member.isdir() or member.isreg()):
                raise PortabilityError(f"unsupported archive member: {member.name}")
        # Python 3.8 is the ABI-floor build environment. The validation above
        # rejects links and path traversal before extraction, so the newer
        # tarfile extraction-filter API is not required here.
        package.extractall(destination, members=members)
    root = destination / "centl"
    if not root.is_dir():
        raise PortabilityError("archive does not contain the centl release root")
    return root


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("release", type=Path, help="CENTL release root or .tar.gz archive")
    parser.add_argument(
        "--max-glibc",
        default=os.environ.get("CENTL_LINUX_GLIBC_BASELINE", DEFAULT_MAX_GLIBC),
        help=f"highest allowed GLIBC symbol version (default: {DEFAULT_MAX_GLIBC})",
    )
    args = parser.parse_args(argv)
    baseline = parse_version(args.max_glibc)

    try:
        if args.release.is_dir():
            inspect_release_root(args.release, baseline)
        else:
            with tempfile.TemporaryDirectory(prefix="centl-linux-abi.") as temporary:
                root = safe_extract(args.release, Path(temporary))
                inspect_release_root(root, baseline)
    except (OSError, tarfile.TarError, PortabilityError) as exc:
        print(f"centl linux ABI: {exc}", file=sys.stderr)
        return 1

    print(f"centl linux ABI: portable through GLIBC_{baseline[0]}.{baseline[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
