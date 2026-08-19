from __future__ import annotations

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "x200-centl-web"
DEPLOY_FILES = (
    ROOT / "deploy" / "fcf-centl-web.service",
    ROOT / "deploy" / "fcf-caravan-coordinator.service",
    ROOT / "deploy" / "fcf-caravan-cloudflare-tunnel.service",
    ROOT / "deploy" / "fcf-caravan-cloudflared-config.yml",
)


class X200CentlWebTests(unittest.TestCase):
    def test_shell_syntax(self) -> None:
        result = subprocess.run(
            ["sh", "-n", str(SCRIPT)],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

    def test_deploy_restarts_the_rebuilt_web_process(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("systemctl --user daemon-reload", text)
        self.assertIn("systemctl --user enable fcf-centl-web.service", text)
        self.assertIn("systemctl --user restart fcf-centl-web.service", text)
        self.assertNotIn("enable --now fcf-centl-web.service", text)

    def test_runtime_configuration_is_host_and_commit_explicit(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn('home=${HOME:?HOME must be set for the X200 deployment}', text)
        self.assertIn("current_commit=$(git -C \"$centl_root\" rev-parse HEAD)", text)
        self.assertIn("Environment=CENTL_BIND_HOST=127.0.0.1", text)
        self.assertIn("Environment=CENTL_SITE_DIR=$centl_root/site", text)
        self.assertIn("Environment=CENTL_BUILD_COMMIT=$current_commit", text)
        self.assertIn("ExecStart=$centl_root/target/release/centl-web --serve $hub_port", text)

    def test_health_check_proves_refresh_clears_history(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("--location", text)
        self.assertIn("--cookie-jar", text)
        self.assertIn("http://127.0.0.1:$hub_port/hub", text)
        self.assertIn("grep -q '22/21'", text)
        self.assertIn("clean GET /hub retained calculation history", text)
        self.assertIn("CENTL exact mathematical interpreter ready.", text)

    def test_public_probe_fingerprints_the_x200_origin(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("http://127.0.0.1:$hub_port/__centl_origin", text)
        self.assertIn("https://freecomputation.org/__centl_origin", text)
        self.assertIn('"centl-web $current_commit"', text)
        self.assertIn("freecomputation.org is not reaching this X200 build", text)

    def test_x200_remains_on_caravan_cloudflare_path(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("tunnel_name=fcf-caravan-coordinator", text)
        self.assertIn("tunnel_id=d59e3e73-544d-40f8-8ad4-9bb6aa6cd689", text)
        self.assertIn("fcf-caravan-cloudflare-tunnel.service", text)
        self.assertIn("service: http://127.0.0.1:$hub_port", text)
        self.assertIn("hostname: caravan.freecomputation.org", text)
        self.assertIn("hostname: www.freecomputation.org", text)

    def test_cloudflare_credentials_and_service_follow_runtime_home(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("cloudflared_dir=$home/.cloudflared", text)
        self.assertIn("cloudflared_credentials=$cloudflared_dir/$tunnel_id.json", text)
        self.assertIn("credentials-file: $cloudflared_credentials", text)
        self.assertIn("cloudflared tunnel --config \"$cloudflared_config\" ingress validate", text)
        self.assertIn("ExecStart=$cloudflared_bin tunnel --config $cloudflared_config run", text)
        self.assertIn("systemctl --user is-active --quiet fcf-caravan-cloudflare-tunnel.service", text)

    def test_deployment_assets_do_not_pin_a_maintainer_home(self) -> None:
        assets = [SCRIPT, *DEPLOY_FILES]
        for path in assets:
            with self.subTest(path=path.relative_to(ROOT)):
                text = path.read_text(encoding="utf-8")
                self.assertNotIn("/var/home/chasebryan", text)

    def test_static_service_templates_use_systemd_home_specifier(self) -> None:
        for path in DEPLOY_FILES[:3]:
            with self.subTest(path=path.relative_to(ROOT)):
                text = path.read_text(encoding="utf-8")
                self.assertIn("%h", text)

        tunnel_template = DEPLOY_FILES[3].read_text(encoding="utf-8")
        self.assertIn("__FCF_HOME__", tunnel_template)


if __name__ == "__main__":
    unittest.main()
