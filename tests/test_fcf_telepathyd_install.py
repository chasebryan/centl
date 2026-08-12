from __future__ import annotations

from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "scripts" / "fcf-telepathyd-install"
UNIT = ROOT / "infra" / "fcf-telepathyd" / "fcf-telepathyd.service"
RUNBOOK = ROOT / "docs" / "FCF-TELEPATHYD-DEPLOY.md"


class InstallerTests(unittest.TestCase):
    def test_shell_syntax_and_help(self) -> None:
        syntax = subprocess.run(
            ["bash", "-n", str(INSTALLER)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(syntax.returncode, 0, msg=syntax.stderr)

        help_result = subprocess.run(
            ["bash", str(INSTALLER), "--help"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(help_result.returncode, 0, msg=help_result.stderr)
        self.assertIn("--enable-now", help_result.stdout)
        self.assertIn("never publishes", help_result.stdout)

    def test_install_does_not_activate_without_explicit_flag(self) -> None:
        text = INSTALLER.read_text(encoding="utf-8")
        self.assertIn("ENABLE_NOW=0", text)
        self.assertIn('if [ "$ENABLE_NOW" -eq 0 ]; then', text)
        self.assertIn("Installed but NOT activated", text)
        self.assertIn("systemctl restart fcf-telepathyd.service", text)
        self.assertNotIn("systemctl enable --now", text)

    def test_custom_live_root_rewrites_all_unit_occurrences(self) -> None:
        text = INSTALLER.read_text(encoding="utf-8")
        self.assertIn(
            'sed "s#/srv/fcf-caravan-live/current#$LIVE_ROOT#g"',
            text,
        )
        self.assertIn(
            '*[!A-Za-z0-9._/+:-]*) fail "CARAVAN live root contains unsupported characters"',
            text,
        )

    def test_installer_only_disables_tor_it_installed(self) -> None:
        text = INSTALLER.read_text(encoding="utf-8")
        self.assertIn("TOR_INSTALLED_BY_US=0", text)
        self.assertIn("TOR_INSTALLED_BY_US=1", text)
        self.assertIn('if [ "$TOR_INSTALLED_BY_US" -eq 1 ]; then', text)
        self.assertIn("tor@default.service", text)


class SystemdUnitTests(unittest.TestCase):
    def setUp(self) -> None:
        self.text = UNIT.read_text(encoding="utf-8")

    def test_service_is_unprivileged_and_capability_empty(self) -> None:
        self.assertIn("User=fcf-telepathyd", self.text)
        self.assertIn("Group=fcf-telepathyd", self.text)
        self.assertNotIn("User=root", self.text)
        self.assertIn("NoNewPrivileges=true", self.text)
        self.assertRegex(self.text, r"(?m)^CapabilityBoundingSet=$")
        self.assertRegex(self.text, r"(?m)^AmbientCapabilities=$")
        self.assertIn("UMask=0077", self.text)

    def test_service_reads_caravan_and_writes_only_private_state(self) -> None:
        self.assertIn("ProtectSystem=strict", self.text)
        self.assertIn("ProtectHome=true", self.text)
        self.assertIn("ReadOnlyPaths=/srv/fcf-caravan-live", self.text)
        self.assertIn("StateDirectory=fcf-telepathyd", self.text)
        self.assertIn("StateDirectoryMode=0700", self.text)
        self.assertIn("--caravan-live-root /srv/fcf-caravan-live/current", self.text)

    def test_service_keeps_publication_listener_loopback(self) -> None:
        self.assertIn("--listen-host 127.0.0.1", self.text)
        self.assertIn("--listen-port 8790", self.text)
        self.assertIn("--carrier tor-onion", self.text)
        self.assertIn("--publish", self.text)
        self.assertNotIn("PrivateNetwork=true", self.text)
        self.assertIn("RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX", self.text)

    def test_service_has_process_and_kernel_hardening(self) -> None:
        for directive in (
            "PrivateTmp=true",
            "PrivateDevices=true",
            "ProtectKernelTunables=true",
            "ProtectKernelModules=true",
            "ProtectKernelLogs=true",
            "ProtectControlGroups=true",
            "ProtectClock=true",
            "ProtectHostname=true",
            "ProtectProc=invisible",
            "ProcSubset=pid",
            "LockPersonality=true",
            "RestrictSUIDSGID=true",
            "RestrictRealtime=true",
            "RestrictNamespaces=true",
            "SystemCallArchitectures=native",
        ):
            self.assertIn(directive, self.text)

    def test_shutdown_gives_daemon_first_chance_to_withdraw_tor(self) -> None:
        self.assertIn("KillMode=mixed", self.text)
        self.assertIn("TimeoutStopSec=15s", self.text)


class RunbookTests(unittest.TestCase):
    def test_runbook_distinguishes_local_bootstrap_from_remote_qualification(self) -> None:
        text = RUNBOOK.read_text(encoding="utf-8")
        self.assertIn("--enable-now", text)
        self.assertIn("second Tor client", text)
        self.assertIn("--socks5-hostname", text)
        self.assertIn("Do not use a public web gateway", text)


if __name__ == "__main__":
    unittest.main()
