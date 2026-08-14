from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "scripts" / "caravan-join-template"
RELEASE = ROOT / "scripts" / "caravan-join-release"
VERIFY = ROOT / "scripts" / "caravan-join-verify"
RENDER = ROOT / "scripts" / "caravan-render-bazaar"
DOC = ROOT / "docs" / "CARAVAN-JOIN-RELEASE.md"
MANUAL = ROOT / "docs" / "CARAVAN-JOIN-MANUAL.md"
CENSUS = ROOT / "docs" / "CARAVAN-CENSUS.md"
BAZAAR = ROOT / "site" / "mirrors.html"


class CaravanJoinReleaseTests(unittest.TestCase):
    def test_shell_syntax(self) -> None:
        for path in (TEMPLATE, RELEASE, VERIFY):
            subprocess.run(["bash", "-n", str(path)], check=True)

    def test_mutable_repository_template_refuses_to_be_official_installer(self) -> None:
        result = subprocess.run(
            ["bash", str(TEMPLATE)], capture_output=True, text=True, check=False
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mutable development template", result.stderr)

    def test_join_release_is_rootless_and_starts_network_disabled(self) -> None:
        text = TEMPLATE.read_text(encoding="utf-8")
        self.assertIn("normal CARAVAN carrier setup is rootless", text)
        self.assertIn('"network_mode": "disabled-until-authenticated-enrollment"', text)
        self.assertIn('"inbound_listen": False', text)
        self.assertIn('"arbitrary_content": False', text)
        self.assertIn('"systemd_required": False', text)
        self.assertIn("official releases are immutable in place", text)
        self.assertIn("--no-oasis", text)
        self.assertIn("payload/centl-install", text)
        self.assertIn('"software_support"', text)
        self.assertIn('"consent"', text)
        self.assertIn("Welcome to the FCF CARAVAN", text)
        self.assertIn("https://github.com/sponsors/chasebryan", text)
        self.assertIn("https://freecomputation.org/funding.html#x-money", text)
        self.assertNotIn("╭", text)
        self.assertNotIn("╰", text)
        for network_primitive in (
            "curl ",
            "wget ",
            "ssh ",
            "socat ",
            "nc ",
            "proxy_pass",
            "0.0.0.0:",
        ):
            self.assertNotIn(network_primitive, text)

    def test_join_script_verifies_signed_exact_membership_before_install(self) -> None:
        text = TEMPLATE.read_text(encoding="utf-8")
        signature = text.index("signify -V")
        membership = text.index("release exact-membership check failed")
        install = text.index('install_root="$LIB_HOME/fcf-caravan/releases/$RELEASE_VERSION"')
        self.assertLess(signature, membership)
        self.assertLess(membership, install)
        self.assertIn("RELEASE_KEY_SHA256", text)
        self.assertIn("bundled FCF join key identity differs", text)

    def test_join_script_requires_explicit_preservation_missions(self) -> None:
        text = TEMPLATE.read_text(encoding="utf-8")
        self.assertIn("--missions", text)
        for mission in ("source", "releases", "semantic", "recovery"):
            self.assertIn(mission, text)
        self.assertIn("no preservation mission selected", text)
        self.assertIn("authenticated-fcf-public-approved-only", text)
        self.assertIn('"schema": "fcf-caravan-carrier-config-v2"', text)
        self.assertIn('"missions": missions.split(",")', text)
        self.assertIn("Mission selection is a filter, never publication authority", text)

    def test_join_script_records_private_aggregate_only_census_policy(self) -> None:
        text = TEMPLATE.read_text(encoding="utf-8")
        self.assertIn('"mode": "aggregate-only"', text)
        self.assertIn('"public_node_listing": False', text)
        self.assertIn('"public_ip_addresses": False', text)
        self.assertIn('"public_hostnames": False', text)
        self.assertIn('"heartbeat": "disabled-until-authenticated-enrollment"', text)
        self.assertIn('"$state_root/census"', text)

    def test_official_release_requires_explicit_external_fcf_secret_key(self) -> None:
        text = RELEASE.read_text(encoding="utf-8")
        self.assertIn("FCF_CARAVAN_JOIN_SECRET_KEY", text)
        self.assertIn("FCF_CARAVAN_JOIN_PUBLIC_KEY", text)
        self.assertIn("secret FCF signing key must never live inside the CENTL repository", text)
        self.assertIn("official join releases require a completely clean Git checkout", text)
        self.assertIn("release already exists and will not be overwritten", text)
        self.assertNotIn("latest", text.lower())

    def test_release_is_double_authenticated_and_deterministic(self) -> None:
        text = RELEASE.read_text(encoding="utf-8")
        self.assertGreaterEqual(text.count("signify -S"), 2)
        self.assertGreaterEqual(text.count("signify -V"), 2)
        self.assertIn("tar --sort=name", text)
        self.assertIn("--mtime='UTC 1970-01-01'", text)
        self.assertIn("--owner=0 --group=0 --numeric-owner", text)
        self.assertIn("gzip -n -9", text)
        self.assertIn("archive_sha256=", text)

    def test_release_packages_join_manual_and_census_contract(self) -> None:
        text = RELEASE.read_text(encoding="utf-8")
        self.assertIn("CARAVAN-JOIN-MANUAL.md", text)
        self.assertIn("CARAVAN-CENSUS.md", text)
        self.assertIn('"mission_selection": ["source", "releases", "semantic", "recovery"]', text)
        self.assertIn('"mission_authority": "authenticated-fcf-public-approved-only"', text)
        self.assertIn('"census_publication": "aggregate-only"', text)
        self.assertIn('"public_node_listing": False', text)
        self.assertIn('"normal_carrier_requires_systemd": False', text)
        self.assertIn('"installs_current_oasis": True', text)
        self.assertIn('"oasis_install_path": "~/.local/bin"', text)

    def test_independent_verifier_requires_separately_trusted_key(self) -> None:
        text = VERIFY.read_text(encoding="utf-8")
        self.assertIn("TRUSTED_FCF_JOIN_PUBLIC_KEY", text)
        self.assertIn("does not match the separately trusted FCF key", text)
        self.assertGreaterEqual(text.count("signify -V"), 2)
        self.assertIn("unsafe join archive member", text)
        self.assertIn("inner release checksum failed", text)

    def test_documentation_forbids_mutable_branch_installers_and_auto_update(self) -> None:
        text = DOC.read_text(encoding="utf-8")
        self.assertIn("versioned FCF-signed release artifact", text)
        self.assertIn("No mutable `latest` installer", text)
        self.assertIn("No automatic self-update", text)
        self.assertIn("curl https://.../main/join-caravan | sh", text)
        self.assertIn("Repository write access is therefore not equivalent to release authority", text)
        self.assertIn("A release version is never overwritten", text)

    def test_manual_join_guide_covers_trust_missions_linux_and_withdrawal(self) -> None:
        text = MANUAL.read_text(encoding="utf-8")
        self.assertIn("The trust rule", text)
        self.assertIn("What a normal volunteer may choose to preserve", text)
        self.assertIn("Supported Linux strategy", text)
        self.assertIn("--missions source,releases", text)
        self.assertIn("Current network status", text)
        self.assertIn("Withdraw from CARAVAN", text)
        self.assertIn("FCF public-origin operators", text)
        self.assertIn("independent trust anchor", text)

    def test_census_contract_is_aggregate_only_and_defines_lost_state(self) -> None:
        text = CENSUS.read_text(encoding="utf-8")
        self.assertIn("Active Camels 🐪", text)
        self.assertIn("Lost Camels 🐪", text)
        self.assertIn("aggregate counts only", text)
        self.assertIn("lost threshold:     72 hours", text)
        self.assertIn("Withdrawn carriers are not Lost Camels", text)
        self.assertIn("public home IP addresses as census fields", text)
        self.assertIn("k = 10", text)
        self.assertIn("not \"unique people.\"", text)

    def test_bazaar_census_template_is_server_rendered_and_privacy_preserving(self) -> None:
        html = BAZAAR.read_text(encoding="utf-8")
        self.assertIn("Active Camels", html)
        self.assertIn("Hungry Camels", html)
        self.assertIn("Lost Camels", html)
        self.assertIn("CARAVAN Cargo Loads", html)
        self.assertIn("__FCF_CARGO_LOADS__", html)
        self.assertIn("__FCF_ACTIVE_CAMELS__", html)
        self.assertIn("__FCF_HUNGRY_CAMELS__", html)
        self.assertIn("__FCF_LOST_CAMELS__", html)
        self.assertNotIn("caravan-census.js", html)
        for forbidden in (
            "volunteer IP addresses",
            "hostnames",
            "usernames",
            "email addresses",
            "locations",
        ):
            self.assertIn(forbidden, html)

    def test_bazaar_renderer_replaces_all_census_placeholders(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            census = root / "census.json"
            output = root / "mirrors.html"
            census.write_text(
                json.dumps(
                    {
                        "schema": "fcf-caravan-lead-census-v1",
                        "status": "live",
                        "generated_at": "2026-08-13T22:25:02+00:00",
                        "probe": "healthy",
                        "active_camels": 1,
                        "hungry_camels": 0,
                        "lost_camels": 0,
                        "cargo_loads": 0,
                    }
                ),
                encoding="utf-8",
            )
            subprocess.run(
                [
                    sys.executable,
                    str(RENDER),
                    "--template",
                    str(BAZAAR),
                    "--census",
                    str(census),
                    "--output",
                    str(output),
                ],
                check=True,
            )
            rendered = output.read_text(encoding="utf-8")
            self.assertNotIn("__FCF_", rendered)
            self.assertIn("<strong>1</strong>", rendered)
            self.assertGreaterEqual(rendered.count("<strong>0</strong>"), 2)
            self.assertIn("passed the latest Tor probe", rendered)

    def test_bazaar_renderer_accepts_authenticated_coordinator_census(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            census = root / "census.json"
            output = root / "mirrors.html"
            census.write_text(
                json.dumps(
                    {
                        "schema": "fcf-caravan-census-v1",
                        "status": "live",
                        "generated_at": "2026-08-13T22:25:02Z",
                        "active_camels": 7,
                        "hungry_camels": 1,
                        "lost_camels": 2,
                        "cargo_loads": 19,
                        "active_window_seconds": 1800,
                        "lost_after_seconds": 259200,
                        "individual_nodes_public": False,
                        "ip_addresses_public": False,
                    }
                ),
                encoding="utf-8",
            )
            subprocess.run(
                [
                    sys.executable,
                    str(RENDER),
                    "--template",
                    str(BAZAAR),
                    "--census",
                    str(census),
                    "--output",
                    str(output),
                ],
                check=True,
            )
            rendered = output.read_text(encoding="utf-8")
            self.assertIn("<strong>7</strong>", rendered)
            self.assertIn("<strong>1</strong>", rendered)
            self.assertIn("<strong>2</strong>", rendered)
            self.assertIn("<strong>19</strong>", rendered)
            self.assertIn("authenticated coordinator census", rendered)

    def test_bazaar_explains_the_guided_non_manual_join_path(self) -> None:
        html = BAZAAR.read_text(encoding="utf-8")
        self.assertIn("guided", html)
        self.assertIn("No repository checkout or special tooling is required", html)
        self.assertIn("Read the manual path", html)


if __name__ == "__main__":
    unittest.main()
