from __future__ import annotations

import hashlib
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
SOURCE_EXPORT = ROOT / "scripts" / "caravan-public-origin-source-export.py"
INGEST = ROOT / "scripts" / "caravan-public-origin-ingest"
AUTHORIZE = ROOT / "scripts" / "caravan-public-origin-authorize-source"
INSTALL = ROOT / "scripts" / "caravan-public-origin-install"
PLATFORM = ROOT / "scripts" / "caravan-linux-platform"
ACTIVATE = ROOT / "scripts" / "caravan-public-origin-activate.py"
SOURCE_GUARD = ROOT / "scripts" / "caravan-public-origin-source-guard.py"
ACTIVATE_GATE = ROOT / "scripts" / "caravan-public-origin-activate-gate"
FIREWALL = ROOT / "scripts" / "caravan-public-origin-firewall"
AUDIT = ROOT / "scripts" / "caravan-public-origin-audit"
NGINX = ROOT / "infra" / "caravan-public-origin" / "nginx-fcf-caravan.conf.in"
INGEST_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-ingest.service"
CANDIDATE_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-candidate.service"
ACTIVATE_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-activate.service"
FIREWALL_UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-firewall.service"
WORKFLOW = ROOT / ".github" / "workflows" / "caravan-public-origin.yml"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(*args: str, cwd: Path) -> str:
    return subprocess.check_output(["git", *args], cwd=cwd, text=True).strip()


def build_preserved_repo(root: Path, *, secret_on_oasis: bool = False) -> tuple[Path, dict[str, str]]:
    repo = root / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q", "-b", "main"], cwd=repo, check=True)
    subprocess.run(["git", "config", "user.name", "FCF Test"], cwd=repo, check=True)
    subprocess.run(["git", "config", "user.email", "test@example.invalid"], cwd=repo, check=True)
    (repo / "README.md").write_text("CENTL\n", encoding="utf-8")
    (repo / "LICENSE").write_text("test license\n", encoding="utf-8")
    (repo / "src.txt").write_text("exact source\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-qm", "base"], cwd=repo, check=True)
    subprocess.run(["git", "branch", "oasis"], cwd=repo, check=True)
    subprocess.run(["git", "branch", "mirage"], cwd=repo, check=True)

    if secret_on_oasis:
        subprocess.run(["git", "switch", "-q", "oasis"], cwd=repo, check=True)
        (repo / ".env").write_text("DO_NOT_PUBLISH=yes\n", encoding="utf-8")
        subprocess.run(["git", "add", ".env"], cwd=repo, check=True)
        subprocess.run(["git", "commit", "-qm", "bad source"], cwd=repo, check=True)
        subprocess.run(["git", "switch", "-q", "main"], cwd=repo, check=True)

    commits = {branch: git("rev-parse", branch, cwd=repo) for branch in ("main", "oasis", "mirage")}
    mirror = root / "mirror"
    (mirror / "project").mkdir(parents=True)
    subprocess.run(
        ["git", "bundle", "create", str(mirror / "project" / "centl.bundle"), "--all"],
        cwd=repo,
        check=True,
    )
    # The source exporter is downstream of mirror-receipt verification, so this
    # fixture needs only a stable receipt identity for authorization binding.
    (mirror / "MIRROR-SHA256SUMS").write_text("fixture-preservation-receipt\n", encoding="utf-8")
    return mirror, commits


def write_authorization(path: Path, mirror: Path, commits: dict[str, str], *, receipt: str | None = None) -> None:
    receipt_hash = sha256(mirror / "MIRROR-SHA256SUMS") if receipt is None else receipt
    data = {
        "schema": "fcf-caravan-source-authorization-v1",
        "repository": "chasebryan/centl",
        "mirror_receipt_sha256": receipt_hash,
        "branches": commits,
    }
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def add_tar_file(tf: tarfile.TarFile, name: str, data: bytes) -> None:
    info = tarfile.TarInfo(name)
    info.size = len(data)
    tf.addfile(info, io.BytesIO(data))


class CaravanPublicOriginTests(unittest.TestCase):
    def test_script_syntax(self) -> None:
        for script in (PLATFORM, INGEST, AUTHORIZE, INSTALL, FIREWALL, AUDIT, ACTIVATE_GATE):
            subprocess.run(["bash", "-n", str(script)], check=True)
        for script in (CANDIDATE, SOURCE_EXPORT, ACTIVATE, SOURCE_GUARD):
            subprocess.run(["python3", "-m", "py_compile", str(script)], check=True)

    def test_candidate_has_no_mutable_source_network_authority(self) -> None:
        text = CANDIDATE.read_text(encoding="utf-8")
        for forbidden in (
            "github.com/chasebryan/centl.git",
            "refs/remotes/origin/",
            "git fetch",
            "refs/pull",
            "OFFICIAL_SOURCE",
        ):
            self.assertNotIn(forbidden, text)
        self.assertIn("root-approved publication store is missing", text)
        self.assertIn('shutil.copytree(approved / "source"', text)

        unit = CANDIDATE_UNIT.read_text(encoding="utf-8")
        self.assertIn("PrivateNetwork=yes", unit)
        self.assertIn("IPAddressDeny=any", unit)
        self.assertIn("RestrictAddressFamilies=AF_UNIX", unit)
        self.assertIn("ReadOnlyPaths=/var/lib/fcf-caravan/approved", unit)

    def test_ingest_is_preservation_only_and_networkless(self) -> None:
        text = INGEST.read_text(encoding="utf-8")
        self.assertIn("FCF_CARAVAN_PRESERVATION_ROOT is required", text)
        self.assertIn("explicit root-owned source authorization is required", text)
        self.assertIn("caravan-public-origin-source-export.py", text)
        self.assertNotIn("github.com", text)
        unit = INGEST_UNIT.read_text(encoding="utf-8")
        self.assertIn("PrivateNetwork=yes", unit)
        self.assertIn("IPAddressDeny=any", unit)
        self.assertIn("CAP_DAC_READ_SEARCH", unit)

    def test_source_authorization_is_bound_to_exact_mirror_receipt(self) -> None:
        module = load_module(SOURCE_EXPORT, "caravan_source_export_stale")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            mirror, commits = build_preserved_repo(root)
            auth = root / "authorization.json"
            write_authorization(auth, mirror, commits, receipt="0" * 64)
            with self.assertRaises(SystemExit):
                module.load_authorization(auth, mirror)

    def test_source_export_uses_only_exact_preserved_commits(self) -> None:
        module = load_module(SOURCE_EXPORT, "caravan_source_export_ok")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            mirror, commits = build_preserved_repo(root)
            auth = root / "authorization.json"
            write_authorization(auth, mirror, commits)
            out1 = root / "source-one"
            out2 = root / "source-two"
            module.export(mirror, auth, out1)
            module.export(mirror, auth, out2)
            index = json.loads((out1 / "INDEX.json").read_text(encoding="utf-8"))
            self.assertEqual(index["schema"], "centl-fcf-source-index-v2")
            self.assertEqual(index["repository"], "chasebryan/centl")
            self.assertEqual(index["mirror_receipt_sha256"], sha256(mirror / "MIRROR-SHA256SUMS"))
            self.assertEqual(index["authorization_sha256"], sha256(auth))
            for branch in ("main", "oasis", "mirage"):
                item = index["branches"][branch]
                self.assertEqual(item["commit"], commits[branch])
                archive = out1 / item["archive"]
                self.assertEqual(item["sha256"], sha256(archive))
                self.assertEqual(archive.read_bytes(), (out2 / item["archive"]).read_bytes())

    def test_source_export_rejects_secret_bearing_authorized_commit(self) -> None:
        module = load_module(SOURCE_EXPORT, "caravan_source_export_secret")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            mirror, commits = build_preserved_repo(root, secret_on_oasis=True)
            auth = root / "authorization.json"
            write_authorization(auth, mirror, commits)
            with self.assertRaises(SystemExit):
                module.export(mirror, auth, root / "public-source")

    def test_approved_store_rejects_unlisted_extra_file(self) -> None:
        module = load_module(CANDIDATE, "caravan_candidate_manifest")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            cargo = root / "INGEST-STATUS.json"
            cargo.write_text("{}\n", encoding="utf-8")
            manifest = root / "APPROVED-SHA256SUMS"
            manifest.write_text(f"{sha256(cargo)}  INGEST-STATUS.json\n", encoding="utf-8")
            receipt = root / "APPROVED-SHA256SUMS.sha256"
            receipt.write_text(f"{sha256(manifest)}  APPROVED-SHA256SUMS\n", encoding="utf-8")
            (root / "surprise.bin").write_bytes(b"not approved")
            with self.assertRaises(SystemExit):
                module.verify_manifest(root)

    def test_activation_independently_rescans_and_compares_source(self) -> None:
        text = ACTIVATE.read_text(encoding="utf-8")
        self.assertIn('"centl-fcf-source-index-v2"', text)
        self.assertIn('compare_tree(root / "source", approved / "source", "source export")', text)
        self.assertIn("verify_source_archive", text)
        claim = text.index("os.rename(source, claimed)")
        freeze = text.index("freeze_tree(claimed)")
        copy = text.index("shutil.copytree(claimed, stage")
        verify = text.index("verify_generation(stage, approved)")
        live = text.index('os.replace(pointer, live / "current")')
        self.assertLess(claim, freeze)
        self.assertLess(freeze, copy)
        self.assertLess(copy, verify)
        self.assertLess(verify, live)

    def test_root_archive_rescan_rejects_sensitive_member(self) -> None:
        module = load_module(ACTIVATE, "caravan_activate_archive")
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

    def test_networkless_ingest_candidate_and_activation_are_separate(self) -> None:
        ingest = INGEST_UNIT.read_text(encoding="utf-8")
        candidate = CANDIDATE_UNIT.read_text(encoding="utf-8")
        activate = ACTIVATE_UNIT.read_text(encoding="utf-8")
        for text in (ingest, candidate, activate):
            self.assertIn("ProtectSystem=strict", text)
        for text in (ingest, candidate, activate):
            self.assertIn("PrivateNetwork=yes", text)
        self.assertIn("User=fcf-caravan", candidate)
        self.assertNotIn("PRESERVATION_ROOT", candidate)
        self.assertIn("ReadOnlyPaths=/var/lib/fcf-caravan/approved", candidate)
        self.assertIn("ReadOnlyPaths=/var/lib/fcf-caravan/approved", activate)

        installer = INSTALL.read_text(encoding="utf-8")
        public_block = installer.split("cat > /etc/fcf-caravan/public-origin.env", 1)[1].split("EOF_ENV", 1)[0]
        ingest_block = installer.split("cat > /etc/fcf-caravan/ingest.env", 1)[1].split("EOF_ENV", 1)[0]
        self.assertNotIn("PRESERVATION_ROOT", public_block)
        self.assertIn("PRESERVATION_ROOT", ingest_block)
        self.assertIn("SOURCE_AUTHORIZATION", ingest_block)

    def test_publication_lock_serializes_all_three_phases(self) -> None:
        candidate = CANDIDATE_UNIT.read_text(encoding="utf-8")
        ingest = INGEST_UNIT.read_text(encoding="utf-8")
        activate_gate = ACTIVATE_GATE.read_text(encoding="utf-8")
        lock = "/run/lock/fcf-caravan-publication.lock"
        self.assertIn(lock, candidate)
        self.assertIn(lock, ingest)
        self.assertIn(lock, activate_gate)
        self.assertIn("flock", candidate)
        self.assertIn("flock", ingest)
        self.assertIn("flock -x", activate_gate)

    def test_nginx_surface_is_static_get_head_and_default_deny(self) -> None:
        text = NGINX.read_text(encoding="utf-8")
        active = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("#"))
        self.assertIn("if ($request_method !~ ^(GET|HEAD)$)", active)
        self.assertIn("location / {", active)
        self.assertIn("return 404;", active)
        self.assertIn("autoindex off", active)
        self.assertIn("max_ranges 1", active)
        self.assertIn("client_max_body_size 1k", active)
        self.assertIn("limit_conn fcf_caravan_conn 4", active)
        self.assertIn("access_log off", active)
        for forbidden in (
            "proxy_pass", "fastcgi_pass", "uwsgi_pass", "scgi_pass",
            "dav_methods", "auth_request", "autoindex on",
        ):
            self.assertNotIn(forbidden, active)
        for branch in ("main", "oasis", "mirage"):
            self.assertIn(f"location = /source/centl-{branch}.tar.gz", active)

    def test_firewall_is_atomic_dedicated_host_default_deny(self) -> None:
        loader = FIREWALL.read_text(encoding="utf-8")
        installer = INSTALL.read_text(encoding="utf-8")
        unit = FIREWALL_UNIT.read_text(encoding="utf-8")
        self.assertIn("nft -c -f", loader)
        self.assertIn("nft -f", loader)
        self.assertNotIn("nft delete table", loader)
        self.assertIn("flush ruleset", installer)
        self.assertIn("policy drop", installer)
        self.assertIn("tcp dport 80 accept", installer)
        self.assertIn("tcp dport 443 accept", installer)
        self.assertIn("firewalld ufw nftables", installer)
        self.assertIn("CapabilityBoundingSet=CAP_NET_ADMIN", unit)
        self.assertNotIn("ufw --force reset", installer)

    def test_public_origin_installer_is_distro_adaptive(self) -> None:
        platform = PLATFORM.read_text(encoding="utf-8")
        installer = INSTALL.read_text(encoding="utf-8")
        for manager in ("apt-get", "dnf", "yum", "zypper", "pacman"):
            self.assertIn(manager, platform)
        self.assertIn("unrecognized distribution", platform)
        self.assertIn("fcf_linux_install_origin_dependencies", installer)
        self.assertNotIn("/etc/os-release", installer)
        self.assertNotIn("trisquel|debian|ubuntu", installer)
        self.assertIn("systemd is required for the FCF public-origin role", platform)

    def test_installer_requires_preservation_and_explicit_source_authorization(self) -> None:
        text = INSTALL.read_text(encoding="utf-8")
        self.assertIn("CARAVAN has no direct-GitHub publication fallback", text)
        self.assertIn("caravan-public-origin-authorize-source", text)
        self.assertIn("Authorize exactly these preserved commits", text)
        self.assertNotIn("OFFICIAL_SOURCE", text)
        self.assertNotIn("FCF_CARAVAN_SOURCE_REPO_URL", text)
        authorizer = AUTHORIZE.read_text(encoding="utf-8")
        self.assertIn("mirror_receipt_sha256", authorizer)
        self.assertIn("chmod 0600", authorizer)
        self.assertIn("--main, --oasis, and --mirage are all required", authorizer)

    def test_hostile_http_probe_set_is_present(self) -> None:
        text = AUDIT.read_text(encoding="utf-8")
        for method in ("POST", "PUT", "PATCH", "DELETE", "CONNECT", "TRACE", "OPTIONS"):
            self.assertIn(method, text)
        for probe in (
            "/.git/config", "/etc/passwd", "%2e%2e", "/source/",
            "/proc/self/environ", "/var/lib/fcf-caravan/approved/APPROVED-SHA256SUMS",
        ):
            self.assertIn(probe, text)
        self.assertIn("nft list table inet fcf_caravan", text)
        self.assertIn("fcf-caravan-public-origin-status-v2", text)

    def test_success_banner_is_after_every_real_qualification_gate(self) -> None:
        text = INSTALL.read_text(encoding="utf-8")
        self.assertIn("SUCESS", text)
        self.assertIn("Welcome to the Free Computation Foundation caravan!", text)
        authorization = text.index("caravan-public-origin-authorize-source")
        ingest = text.index("systemctl start fcf-caravan-ingest.service")
        cert = text.index("certbot certonly")
        audit = text.rindex("/usr/local/libexec/fcf-caravan/caravan-public-origin-audit")
        success = text.rindex("SUCESS")
        self.assertLess(authorization, ingest)
        self.assertLess(ingest, cert)
        self.assertLess(cert, audit)
        self.assertLess(audit, success)

    def test_workflow_does_not_fetch_live_production_branches(self) -> None:
        text = WORKFLOW.read_text(encoding="utf-8")
        self.assertNotIn("refs/remotes/origin/main", text)
        self.assertNotIn("refs/remotes/origin/oasis", text)
        self.assertNotIn("refs/remotes/origin/mirage", text)
        self.assertNotIn("git -c protocol.file.allow=never", text)
        self.assertIn("closed-world-source-policy", text)


if __name__ == "__main__":
    unittest.main()
