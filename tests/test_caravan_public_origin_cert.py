from __future__ import annotations

from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
INSTALL = ROOT / "scripts" / "caravan-public-origin-install"
DEPLOY = ROOT / "scripts" / "caravan-public-origin-cert-deploy"
AUDIT = ROOT / "scripts" / "caravan-public-origin-audit"
SERVICE = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-cert-renew.service"
TIMER = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-cert-renew.timer"


class CaravanPublicOriginCertificateTests(unittest.TestCase):
    def test_deploy_hook_syntax_and_safe_reload_order(self) -> None:
        subprocess.run(["bash", "-n", str(DEPLOY)], check=True)
        text = DEPLOY.read_text(encoding="utf-8")
        validate = text.index("nginx -t")
        reload_nginx = text.index("systemctl reload nginx")
        active = text.index("systemctl is-active --quiet nginx")
        self.assertLess(validate, reload_nginx)
        self.assertLess(reload_nginx, active)
        self.assertNotIn("restart nginx", text)

    def test_renewal_service_uses_explicit_deploy_hook_and_narrow_write_paths(self) -> None:
        text = SERVICE.read_text(encoding="utf-8")
        self.assertIn("certbot renew --quiet", text)
        self.assertIn("--deploy-hook /usr/local/libexec/fcf-caravan/caravan-public-origin-cert-deploy", text)
        self.assertIn("ProtectSystem=strict", text)
        self.assertIn("ReadWritePaths=/etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt", text)
        self.assertIn("RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6", text)
        self.assertNotIn("PrivateNetwork=yes", text)

    def test_renewal_timer_is_persistent_and_jittered(self) -> None:
        text = TIMER.read_text(encoding="utf-8")
        self.assertIn("OnCalendar=", text)
        self.assertIn("RandomizedDelaySec=2h", text)
        self.assertIn("Persistent=true", text)
        self.assertIn("Unit=fcf-caravan-cert-renew.service", text)

    def test_installer_qualifies_certificate_before_enabling_renewal(self) -> None:
        text = INSTALL.read_text(encoding="utf-8")
        self.assertIn("caravan-public-origin-cert-deploy", text)
        issue = text.index("certbot certonly")
        deploy_flag = text.index("--deploy-hook /usr/local/libexec/fcf-caravan/caravan-public-origin-cert-deploy")
        renew_timer = text.index("systemctl enable --now fcf-caravan-cert-renew.timer")
        audit = text.rindex("/usr/local/libexec/fcf-caravan/caravan-public-origin-audit")
        success = text.rindex("SUCESS")
        self.assertLess(issue, deploy_flag)
        self.assertLess(deploy_flag, renew_timer)
        self.assertLess(renew_timer, audit)
        self.assertLess(audit, success)

    def test_final_audit_requires_renewal_timer_and_hook(self) -> None:
        text = AUDIT.read_text(encoding="utf-8")
        self.assertIn("fcf-caravan-cert-renew.timer", text)
        self.assertIn("caravan-public-origin-cert-deploy", text)
        self.assertIn("certificate deploy hook is missing or unsafe", text)


if __name__ == "__main__":
    unittest.main()
