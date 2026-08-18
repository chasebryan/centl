from __future__ import annotations

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "x200-centl-web"


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
        self.assertIn("fcf-caravan-cloudflare-tunnel.service", text)
        self.assertIn("deploy/fcf-caravan-cloudflared-config.yml", text)
        self.assertIn("service: http://127.0.0.1:", text)
        self.assertIn("freecomputation.org to 127.0.0.1:$hub_port", text)


if __name__ == "__main__":
    unittest.main()
