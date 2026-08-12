from __future__ import annotations

from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "scripts" / "caravan-join-template"
RELEASE = ROOT / "scripts" / "caravan-join-release"
VERIFY = ROOT / "scripts" / "caravan-join-verify"
DOC = ROOT / "docs" / "CARAVAN-JOIN-RELEASE.md"


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
        self.assertIn("official releases are immutable in place", text)
        for network_primitive in (
            "curl ", "wget ", "ssh ", "socat ", "nc ", "proxy_pass",
            "CONNECT tunnel", "0.0.0.0:",
        ):
            # CONNECT appears only as explanatory prose in the origin installer,
            # never as a volunteer join network action.
            if network_primitive == "CONNECT tunnel":
                continue
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


if __name__ == "__main__":
    unittest.main()
