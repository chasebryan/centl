from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "scripts" / "fcf-telepathy").read_text(encoding="utf-8")
NGINX = (ROOT / "infra" / "caravan-public-origin" / "nginx-fcf-telepathy.conf").read_text(encoding="utf-8")


class TelepathyBoundaryTests(unittest.TestCase):
    def test_nginx_is_loopback_only(self):
        self.assertIn("listen 127.0.0.1:8787;", NGINX)
        self.assertNotIn("listen 0.0.0.0", NGINX)
        self.assertNotIn("listen [::]", NGINX)
        self.assertNotIn("proxy_pass", NGINX)
        self.assertNotIn("autoindex on", NGINX)

    def test_nginx_serves_only_live_generation(self):
        self.assertIn("root /srv/fcf-caravan-live/current;", NGINX)
        self.assertNotIn("/srv/centl-mirror", NGINX)
        self.assertNotIn("/var/lib/fcf-caravan/approved", NGINX)
        self.assertNotIn("/var/lib/fcf-caravan/candidates", NGINX)
        self.assertIn("if ($request_method !~ ^(GET|HEAD)$)", NGINX)
        self.assertIn("return 405;", NGINX)
        self.assertIn("location / {\n        return 404;", NGINX)

    def test_transport_targets_loopback_only(self):
        self.assertIn('BACKEND_HOST=127.0.0.1', SCRIPT)
        self.assertIn('BACKEND_PORT=8787', SCRIPT)
        self.assertIn('tailscale funnel --bg --https=443 "http://${BACKEND_HOST}:${BACKEND_PORT}"', SCRIPT)
        self.assertNotIn("cloudflared", SCRIPT)
        self.assertNotIn("ngrok", SCRIPT)

    def test_transport_does_not_mutate_caravan_cargo(self):
        self.assertIn("FCF-Telepathy is transport only", SCRIPT)
        forbidden_write_patterns = [
            "rm -rf /srv/fcf-caravan-live",
            "cp -a /srv/centl-mirror",
            "mv /srv/centl-mirror",
            "chmod -R /srv/fcf-caravan-live",
            "chown -R /srv/fcf-caravan-live",
        ]
        for pattern in forbidden_write_patterns:
            self.assertNotIn(pattern, SCRIPT)

    def test_audit_is_hostile_not_ceremonial(self):
        for method in ("POST", "PUT", "DELETE"):
            self.assertIn(f'expect_code {method}', SCRIPT)
        for path in ("/.git/config", "/etc/passwd", "/proc/self/environ", "/does-not-exist"):
            self.assertIn(path, SCRIPT)
        self.assertIn("FCF-TELEPATHY PUBLIC TRANSPORT PASS", SCRIPT)


if __name__ == "__main__":
    unittest.main()
