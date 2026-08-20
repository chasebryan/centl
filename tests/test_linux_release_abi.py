from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "check-linux-release-abi.py"
SPEC = importlib.util.spec_from_file_location("centl_linux_release_abi", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
ABI = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ABI)


class LinuxReleaseAbiTests(unittest.TestCase):
    def test_parses_highest_glibc_requirement(self) -> None:
        self.assertEqual(ABI.highest_glibc("GLIBC_2.17 GLIBC_2.31 GLIBC_2.28"), (2, 31))
        self.assertIsNone(ABI.highest_glibc("no glibc symbols"))

    def test_parses_standard_interpreter_and_needed_libraries(self) -> None:
        program_headers = "[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"
        dynamic = "\n".join(
            [
                "0x1 (NEEDED) Shared library: [libc.so.6]",
                "0x2 (NEEDED) Shared library: [libgmp.so.10]",
            ]
        )
        self.assertEqual(ABI.interpreter(program_headers), "/lib64/ld-linux-x86-64.so.2")
        self.assertEqual(ABI.needed_libraries(dynamic), {"libc.so.6", "libgmp.so.10"})

    def _elf(self):
        temporary = tempfile.TemporaryDirectory()
        path = Path(temporary.name) / "centl"
        path.write_bytes(b"\x7fELF" + b"\x00" * 32)
        return temporary, path

    def test_rejects_glibc_newer_than_portable_floor(self) -> None:
        temporary, path = self._elf()
        self.addCleanup(temporary.cleanup)

        def fake_readelf(_path: Path, *arguments: str) -> str:
            if "-lW" in arguments:
                return "[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"
            if "--version-info" in arguments:
                return "Name: GLIBC_2.39"
            if "-dW" in arguments:
                return "0x1 (NEEDED) Shared library: [libc.so.6]"
            raise AssertionError(arguments)

        with mock.patch.object(ABI, "readelf", side_effect=fake_readelf):
            with self.assertRaisesRegex(ABI.PortabilityError, "requires GLIBC_2.39"):
                ABI.inspect_object(
                    path,
                    package_libraries=set(),
                    max_glibc=(2, 31),
                    executable=True,
                )

    def test_rejects_unbundled_nonbaseline_runtime_library(self) -> None:
        temporary, path = self._elf()
        self.addCleanup(temporary.cleanup)

        def fake_readelf(_path: Path, *arguments: str) -> str:
            if "-lW" in arguments:
                return "[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]"
            if "--version-info" in arguments:
                return "Name: GLIBC_2.17"
            if "-dW" in arguments:
                return "0x1 (NEEDED) Shared library: [libzstd.so.1]"
            raise AssertionError(arguments)

        with mock.patch.object(ABI, "readelf", side_effect=fake_readelf):
            with self.assertRaisesRegex(ABI.PortabilityError, "unbundled runtime library libzstd.so.1"):
                ABI.inspect_object(
                    path,
                    package_libraries=set(),
                    max_glibc=(2, 31),
                    executable=True,
                )

    def test_accepts_standard_loader_and_packaged_native_library(self) -> None:
        temporary, path = self._elf()
        self.addCleanup(temporary.cleanup)

        def fake_readelf(_path: Path, *arguments: str) -> str:
            if "-lW" in arguments:
                return "[Requesting program interpreter: /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2]"
            if "--version-info" in arguments:
                return "Name: GLIBC_2.31"
            if "-dW" in arguments:
                return "\n".join(
                    [
                        "0x1 (NEEDED) Shared library: [libc.so.6]",
                        "0x2 (NEEDED) Shared library: [libflint.so.19]",
                    ]
                )
            raise AssertionError(arguments)

        with mock.patch.object(ABI, "readelf", side_effect=fake_readelf):
            ABI.inspect_object(
                path,
                package_libraries={"libflint.so.19"},
                max_glibc=(2, 31),
                executable=True,
            )


if __name__ == "__main__":
    unittest.main()
