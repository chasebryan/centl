from __future__ import annotations

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "fcf-leadcaravan"
COMPAT_SCRIPT = ROOT / "scripts" / "x200-camel-online"


class X200CamelOnlineTests(unittest.TestCase):
    def test_shell_syntax_and_help(self) -> None:
        syntax = subprocess.run(
            ["bash", "-n", str(SCRIPT)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, msg=syntax.stderr)

        help_result = subprocess.run(
            ["bash", str(SCRIPT), "--help"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(help_result.returncode, 0, msg=help_result.stderr)
        for command in ("online", "status", "verify", "offline"):
            self.assertIn(command, help_result.stdout)

    def test_legacy_alias_executes(self) -> None:
        result = subprocess.run(
            [str(COMPAT_SCRIPT), "--help"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("fcf-leadcaravan", result.stdout)

    def test_online_path_uses_landed_telepathyd_service(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("scripts/fcf-telepathyd-install", text)
        self.assertIn("--enable-now", text)
        self.assertIn("fcf-telepathyd.service", text)
        self.assertIn("http://127.0.0.1:8790", text)
        self.assertIn("git -C \"$repo_root\" switch mirage", text)
        self.assertNotIn("caravan-public-origin-install", text)

    def test_resume_path_does_not_reintroduce_borrowed_or_router_carriers(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        for forbidden in (
            "tailscale funnel",
            "cloudflared",
            "ngrok",
            "upnpc -a",
            "iptables -t nat",
        ):
            self.assertNotIn(forbidden, text)
        self.assertIn("does not require public TCP 80/443", text)
        self.assertIn("No router port forwarding", text)

    def test_final_qualification_requires_real_tor_socks_path(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("--socks5-hostname", text)
        self.assertIn("second machine / Tor client context", text)
        self.assertIn("Do not use a public onion web gateway", text)
        self.assertIn("expect_remote_code GET /status.json 200", text)
        self.assertIn("expect_remote_code HEAD /source/INDEX.json 200", text)
        self.assertIn("Range: bytes=0-63", text)
        self.assertIn("expect_remote_code POST /status.json 405", text)
        self.assertIn("expect_remote_code GET /etc/passwd 403", text)

    def test_offline_preserves_caravan_and_onion_identity(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("systemctl disable --now fcf-telepathyd.service", text)
        self.assertIn("CARAVAN preservation/live cargo was not deleted", text)
        self.assertIn("Tor hidden-service keys were retained", text)
        self.assertNotIn("rm -rf /srv/fcf-caravan-live", text)
        self.assertNotIn("rm -rf /var/lib/fcf-telepathyd", text)


if __name__ == "__main__":
    unittest.main()
