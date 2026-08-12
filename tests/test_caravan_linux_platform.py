from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PLATFORM = ROOT / "scripts" / "caravan-linux-platform"


class CaravanLinuxPlatformTests(unittest.TestCase):
    def test_shell_syntax(self) -> None:
        subprocess.run(["bash", "-n", str(PLATFORM)], check=True)

    def test_debian_signify_openbsd_is_normalized_for_installer_shell(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            bindir = Path(td)
            required = (
                "certbot",
                "curl",
                "find",
                "git",
                "gzip",
                "nft",
                "nginx",
                "python3",
                "ss",
                "systemctl",
                "useradd",
            )
            for name in required:
                path = bindir / name
                path.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                path.chmod(0o755)

            marker = bindir / "signify-args"
            signify_openbsd = bindir / "signify-openbsd"
            signify_openbsd.write_text(
                "#!/bin/sh\nprintf '%s\\n' \"$*\" > \"$FCF_TEST_SIGNIFY_MARKER\"\n",
                encoding="utf-8",
            )
            signify_openbsd.chmod(0o755)

            env = os.environ.copy()
            env["PATH"] = str(bindir)
            env["FCF_TEST_SIGNIFY_MARKER"] = str(marker)
            script = f"""
set -eu
. {PLATFORM!s}
fcf_linux_origin_commands_present
command -v signify >/dev/null
signify -V -p public.key -m manifest -x signature
"""
            subprocess.run(["/bin/bash", "-c", script], env=env, check=True)
            self.assertEqual(
                marker.read_text(encoding="utf-8").strip(),
                "-V -p public.key -m manifest -x signature",
            )

    def test_native_signify_remains_preferred_when_present(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            bindir = Path(td)
            native = bindir / "signify"
            native.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            native.chmod(0o755)
            fallback = bindir / "signify-openbsd"
            fallback.write_text("#!/bin/sh\nexit 99\n", encoding="utf-8")
            fallback.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = str(bindir)
            script = f"""
set -eu
. {PLATFORM!s}
fcf_linux_normalize_signify_command
signify
"""
            subprocess.run(["/bin/bash", "-c", script], env=env, check=True)


if __name__ == "__main__":
    unittest.main()
