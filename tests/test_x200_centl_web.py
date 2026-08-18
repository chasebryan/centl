from __future__ import annotations

from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
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

    def test_runtime_configuration_is_host_explicit(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("Environment=CENTL_BIND_HOST=127.0.0.1", text)
        self.assertIn("Environment=CENTL_SITE_DIR=$centl_root/site", text)
        self.assertIn("ExecStart=$centl_root/target/release/centl-web --serve $hub_port", text)

    def test_health_check_hits_stateful_hub_not_homepage(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("http://127.0.0.1:$hub_port/hub", text)
        self.assertIn("https://freecomputation.org/hub", text)
        self.assertIn("grep 22/21", text)

    def test_x200_remains_on_caravan_cloudflare_path(self) -> None:
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("tunnel_name=fcf-caravan-coordinator", text)
        self.assertIn("fcf-caravan-cloudflare-tunnel.service", text)
        self.assertIn("deploy/fcf-caravan-cloudflared-config.yml", text)
        self.assertIn("service: http://127.0.0.1:", text)


if __name__ == "__main__":
    unittest.main()
