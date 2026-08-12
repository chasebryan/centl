from __future__ import annotations

import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CANDIDATE = ROOT / "scripts" / "caravan-public-origin-candidate.py"
INGEST = ROOT / "scripts" / "caravan-public-origin-ingest"
INSTALL = ROOT / "scripts" / "caravan-public-origin-install"
ACTIVATE = ROOT / "scripts" / "caravan-public-origin-activate.py"
SOURCE_GUARD = ROOT / "scripts" / "caravan-public-origin-source-guard.py"
ACTIVATE_GATE = ROOT / "scripts" / "caravan-public-origin-activate-gate"
AUDIT = ROOT / "scripts" / "caravan-public-origin-audit"
NGINX = ROOT / "infra" / "caravan-public-origin" / "nginx-fcf-caravan.conf.in"
INGEST_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-ingest.service"
CANDIDATE_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-candidate.service"
ACTIVATE_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-activate.service"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def add_tar_file(tf: tarfile.TarFile, name: str, data: bytes) -> None:
    info = tarfile.TarInfo(name)
    info.size = len(data)
    tf.addfile(info, io.BytesIO(data))


class CaravanPublicOriginTests(unittest.TestCase):
    def test_script_syntax(self) -> None:
        for script in (INGEST, INSTALL, AUDIT, ACTIVATE_GATE):
            subprocess.run(["bash", "-n", str(script)], check=True)
        for script in (CANDIDATE, ACTIVATE, SOURCE_GUARD):
            subprocess.run(["python3", "-m", "py_compile", str(script)], check=True)

    def test_nginx_surface_is_static_and_default_deny(self) -> None:
        text = NGINX.read_text(encoding="utf-8")
        directives = "\n".join(
            line for line in text.splitlines() if not line.lstrip().startswith("#")
        )
        self.assertIn("if ($request_method !~ ^(GET|HEAD)$)", directives)
        self.assertIn("location / {", directives)
        self.assertIn("return 404;", directives)
        self.assertIn("autoindex off", directives)
        self.assertIn("max_ranges 1", directives)
        self.assertIn("client_max_body_size 1k", directives)
        self.assertIn("limit_conn fcf_caravan_conn 4", directives)
        self.assertIn("access_log off", directives)
        for forbidden in (
            "proxy_pass",
            "fastcgi_pass",
            "uwsgi_pass",
            "scgi_pass",
            "dav_methods",
            "auth_request",
            "autoindex on",
        ):
            self.assertNotIn(forbidden, directives)
        for branch in ("main", "oasis", "mirage"):
            self.assertIn(f"location = /source/centl-{branch}.tar.gz", directives)

    def test_installer_rebuilds_dedicated_host_firewall(self) -> None:
        text = INSTALL.read_text(encoding="utf-8")
        self.assertIn("ufw --force reset", text)
        self.assertIn("ufw default deny incoming", text)
        self.assertIn("ufw default allow outgoing", text)
        self.assertIn("ufw allow 80/tcp", text)
        self.assertIn("ufw allow 443/tcp", text)
        self.assertIn("ufw limit", text)
        self.assertIn("unrelated nginx site is enabled", text)
        self.assertIn("fcf-caravan-firewall-backup-", text)
        self.assertIn("50-fcf-caravan-hardening.conf", text)
        for tunnel in ("cloudflared", "tailscale", "ngrok", "frp", "autossh"):
            self.assertNotIn(tunnel, text)

    def test_source_fetch_is_only_official_three_heads(self) -> None:
        text = CANDIDATE.read_text(encoding="utf-8")
        self.assertIn('OFFICIAL_SOURCE = "https://github.com/chasebryan/centl.git"', text)
        self.assertIn('BRANCHES = ("main", "oasis", "mirage")', text)
        self.assertIn("source repository is not the fixed CENTL public source", text)
        self.assertIn("refs/heads/{b}:refs/remotes/origin/{b}", text)
        self.assertIn('"--no-tags"', text)
        self.assertNotIn("refs/pull", text)
        self.assertNotIn("git bundle", text)
        self.assertIn('mode not in {b"100644", b"100755"}', text)
        self.assertIn("sensitive filename rejected", text)
        self.assertIn("credential-like material rejected", text)
        self.assertIn("protocol.file.allow=never", text)
        self.assertIn("protocol.ext.allow=never", text)

    def test_networked_candidate_has_no_private_or_live_write_path(self) -> None:
        text = CANDIDATE_UNIT.read_text(encoding="utf-8")
        self.assertIn("User=fcf-caravan", text)
        self.assertIn("EnvironmentFile=/etc/fcf-caravan/public-origin.env", text)
        self.assertIn("ReadOnlyPaths=/var/lib/fcf-caravan/approved", text)
        self.assertIn(
            "ReadWritePaths=/var/lib/fcf-caravan/source-state /var/lib/fcf-caravan/candidates",
            text,
        )
        self.assertNotIn("centl-mirror", text)
        self.assertNotIn("/srv/fcf-caravan-live", text)
        self.assertIn("NoNewPrivileges=yes", text)
        self.assertIn("CapabilityBoundingSet=", text)

    def test_ingest_and_activation_are_networkless_and_env_separated(self) -> None:
        ingest = INGEST_UNIT.read_text(encoding="utf-8")
        activate = ACTIVATE_UNIT.read_text(encoding="utf-8")
        self.assertIn("EnvironmentFile=/etc/fcf-caravan/ingest.env", ingest)
        self.assertIn("EnvironmentFile=/etc/fcf-caravan/public-origin.env", activate)
        for text in (ingest, activate):
            self.assertIn("PrivateNetwork=yes", text)
            self.assertIn("IPAddressDeny=any", text)
            self.assertIn("ProtectSystem=strict", text)
        self.assertIn("CAP_DAC_READ_SEARCH", ingest)
        self.assertIn("ReadOnlyPaths=/var/lib/fcf-caravan/approved", activate)
        self.assertIn("/var/lib/fcf-caravan/activation-inbox", activate)
        self.assertIn("/srv/fcf-caravan-live", activate)

        installer = INSTALL.read_text(encoding="utf-8")
        public_marker = "cat > /etc/fcf-caravan/public-origin.env <<EOF_ENV\n"
        ingest_marker = "cat > /etc/fcf-caravan/ingest.env <<EOF_ENV\n"
        public_block = installer.split(public_marker, 1)[1].split("\nEOF_ENV", 1)[0]
        ingest_block = installer.split(ingest_marker, 1)[1].split("\nEOF_ENV", 1)[0]
        self.assertNotIn("PRESERVATION_ROOT", public_block)
        self.assertIn("PRESERVATION_ROOT", ingest_block)

    def test_candidate_and_activation_share_publication_lock(self) -> None:
        candidate = CANDIDATE_UNIT.read_text(encoding="utf-8")
        activate = ACTIVATE_UNIT.read_text(encoding="utf-8")
        gate = ACTIVATE_GATE.read_text(encoding="utf-8")
        lock = "/run/lock/fcf-caravan-publication.lock"
        self.assertIn(lock, candidate)
        self.assertIn("caravan-public-origin-activate-gate", activate)
        self.assertIn(lock, gate)
        self.assertIn("flock -x", gate)
        self.assertLess(gate.index('"$GUARD"'), gate.index('"$ACTIVATE"'))

    def test_activation_seizes_and_freezes_candidate_before_copy(self) -> None:
        text = ACTIVATE.read_text(encoding="utf-8")
        claim = text.index("os.rename(source, claimed)")
        freeze = text.index("freeze_tree(claimed)")
        copy = text.index("shutil.copytree(claimed, stage")
        verify = text.index("verify_generation(stage, approved)")
        live = text.index("os.replace(pointer, live / \"current\")")
        self.assertLess(claim, freeze)
        self.assertLess(freeze, copy)
        self.assertLess(copy, verify)
        self.assertLess(verify, live)
        self.assertIn("symlinks=True", text)
        self.assertIn('compare_tree(root / "releases"', text)
        self.assertIn('compare_tree(root / "semantic"', text)

    def test_empty_ingest_is_safe_and_receipted(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            tools = root / "tools" / "scripts"
            tools.mkdir(parents=True)
            for name in ("mirror-receipt", "publication-export", "model-origin-export.py"):
                p = tools / name
                p.write_text("#!/bin/sh\nexit 99\n", encoding="utf-8")
                p.chmod(0o755)
            approved = root / "approved"
            env = os.environ.copy()
            env.update(
                {
                    "FCF_CARAVAN_PRESERVATION_ROOT": "",
                    "FCF_CARAVAN_APPROVED_ROOT": str(approved),
                    "FCF_CARAVAN_INGEST_WORK_ROOT": str(root / "work"),
                    "FCF_CARAVAN_TOOLS_ROOT": str(root / "tools"),
                }
            )
            result = subprocess.run(
                ["bash", str(INGEST)], env=env, capture_output=True, text=True
            )
            self.assertEqual(
                result.returncode,
                0,
                msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
            )
            status = json.loads((approved / "INGEST-STATUS.json").read_text(encoding="utf-8"))
            self.assertFalse(status["preservation_mirror_verified"])
            self.assertFalse(status["release_export_present"])
            self.assertFalse(status["semantic_export_present"])
            subprocess.run(
                ["sha256sum", "-c", "APPROVED-SHA256SUMS.sha256"],
                cwd=approved,
                check=True,
                capture_output=True,
            )
            subprocess.run(
                ["sha256sum", "-c", "APPROVED-SHA256SUMS"],
                cwd=approved,
                check=True,
                capture_output=True,
            )
            for path in approved.rglob("*"):
                mode = path.lstat().st_mode
                self.assertFalse(stat.S_ISLNK(mode))
                self.assertTrue(stat.S_ISREG(mode) or stat.S_ISDIR(mode))

    def test_approved_ingest_rejects_unlisted_extra_file(self) -> None:
        module = load_module(CANDIDATE, "caravan_candidate")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            cargo = root / "INGEST-STATUS.json"
            cargo.write_text("{}\n", encoding="utf-8")
            manifest = root / "APPROVED-SHA256SUMS"
            manifest.write_text(f"{module.sha256(cargo)}  INGEST-STATUS.json\n", encoding="utf-8")
            receipt = root / "APPROVED-SHA256SUMS.sha256"
            receipt.write_text(f"{module.sha256(manifest)}  APPROVED-SHA256SUMS\n", encoding="utf-8")
            (root / "surprise.bin").write_bytes(b"not approved")
            with self.assertRaises(SystemExit):
                module.verify_manifest(root, "APPROVED-SHA256SUMS", "APPROVED-SHA256SUMS.sha256")

    def test_source_validator_rejects_symlink_and_secret_name(self) -> None:
        module = load_module(CANDIDATE, "caravan_candidate_source")
        with tempfile.TemporaryDirectory() as td:
            work = Path(td) / "repo"
            subprocess.run(["git", "init", "-q", str(work)], check=True)
            subprocess.run(["git", "-C", str(work), "config", "user.name", "Test"], check=True)
            subprocess.run(["git", "-C", str(work), "config", "user.email", "test@example.invalid"], check=True)
            (work / "README.md").write_text("centl\n", encoding="utf-8")
            os.symlink("README.md", work / "escape-link")
            subprocess.run(["git", "-C", str(work), "add", "README.md", "escape-link"], check=True)
            subprocess.run(["git", "-C", str(work), "commit", "-qm", "symlink"], check=True)
            with self.assertRaises(SystemExit):
                module.validate_ref(work / ".git", "HEAD")
            subprocess.run(["git", "-C", str(work), "rm", "-q", "escape-link"], check=True)
            (work / ".env").write_text("DO_NOT_PUBLISH=1\n", encoding="utf-8")
            subprocess.run(["git", "-C", str(work), "add", ".env"], check=True)
            subprocess.run(["git", "-C", str(work), "commit", "-qm", "secret-name"], check=True)
            with self.assertRaises(SystemExit):
                module.validate_ref(work / ".git", "HEAD")

    def test_root_archive_rescan_rejects_sensitive_member(self) -> None:
        module = load_module(ACTIVATE, "caravan_activate")
        with tempfile.TemporaryDirectory() as td:
            archive_path = Path(td) / "centl-main.tar.gz"
            with tarfile.open(archive_path, "w:gz") as tf:
                add_tar_file(tf, "centl-main/README.md", b"CENTL\n")
                add_tar_file(tf, "centl-main/LICENSE", b"license\n")
                add_tar_file(tf, "centl-main/.env", b"SECRET=1\n")
            with self.assertRaises(SystemExit):
                module.verify_source_archive(archive_path, "main")

    def test_second_source_guard_rejects_sensitive_member(self) -> None:
        module = load_module(SOURCE_GUARD, "caravan_source_guard")
        with tempfile.TemporaryDirectory() as td:
            archive_path = Path(td) / "centl-main.tar.gz"
            with tarfile.open(archive_path, "w:gz") as tf:
                add_tar_file(tf, "centl-main/README.md", b"CENTL\n")
                add_tar_file(tf, "centl-main/LICENSE", b"license\n")
                add_tar_file(tf, "centl-main/id_ed25519", b"not-a-real-key\n")
            with self.assertRaises(SystemExit):
                module.guard_archive(archive_path, "main")

    def test_aggregate_catalog_includes_semantic_embedded_metadata(self) -> None:
        module = load_module(CANDIDATE, "caravan_candidate_catalog")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "caravan").mkdir()
            embedded = root / "semantic" / "caravan" / "catalog-v1.json"
            embedded.parent.mkdir(parents=True)
            embedded.write_text('{"semantic":"catalog"}\n', encoding="utf-8")
            module.make_catalog(root, 7)
            data = json.loads((root / "caravan" / "catalog-v1.json").read_text(encoding="utf-8"))
            paths = {item["logical_path"] for item in data["artifacts"]}
            self.assertIn("semantic/caravan/catalog-v1.json", paths)

    def test_hostile_http_probe_set_and_firewall_audit_are_present(self) -> None:
        text = AUDIT.read_text(encoding="utf-8")
        for method in ("POST", "PUT", "PATCH", "DELETE", "CONNECT", "TRACE", "OPTIONS"):
            self.assertIn(method, text)
        for probe in ("/.git/config", "/etc/passwd", "%2e%2e", "/source/"):
            self.assertIn(probe, text)
        self.assertIn("Default: deny (incoming)", text)
        self.assertIn("status_tmp=$(mktemp)", text)

    def test_success_banner_is_last_gate(self) -> None:
        text = INSTALL.read_text(encoding="utf-8")
        self.assertIn("SUCESS", text)
        self.assertIn("Welcome to the Free Computation Foundation caravan!", text)
        services = text.index("systemctl start fcf-caravan-ingest.service")
        cert = text.index("certbot certonly")
        audit = text.index("/usr/local/libexec/fcf-caravan/caravan-public-origin-audit")
        success = text.rindex("SUCESS")
        self.assertLess(services, cert)
        self.assertLess(cert, audit)
        self.assertLess(audit, success)


if __name__ == "__main__":
    unittest.main()
