from __future__ import annotations

import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("centl_oasis", ROOT / "scripts/oasis.py")
assert SPEC is not None and SPEC.loader is not None
OASIS = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = OASIS
SPEC.loader.exec_module(OASIS)


class OasisTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="centl-oasis-test-")
        self.root = Path(self.temp.name)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_version(self, value: str = "0.13.0") -> None:
        path = self.root / "src/ocaml/centl_version.ml"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f'let value = "{value}"\n', encoding="utf-8")

    def make_archive(
        self,
        *,
        version: str = "0.13.0",
        extra_member: tarfile.TarInfo | None = None,
        extra_data: bytes = b"",
    ) -> Path:
        dist = self.root / "dist"
        dist.mkdir(parents=True, exist_ok=True)
        archive = dist / "centl-linux-x86_64.tar.gz"
        members = {
            "centl/VERSION": (version + "\n").encode(),
            "centl/bin/centl": b"launcher",
            "centl/bin/centl-physics": b"launcher",
            "centl/bin/centl-sci": b"launcher",
            "centl/libexec/centl": b"binary",
            "centl/libexec/centl-physics": b"binary",
            "centl/libexec/centl-sci": b"binary",
        }
        with tarfile.open(archive, "w:gz") as tar:
            for name, data in members.items():
                info = tarfile.TarInfo(name)
                info.size = len(data)
                info.mode = 0o755 if "/bin/" in name or "/libexec/" in name else 0o644
                tar.addfile(info, io.BytesIO(data))
            if extra_member is not None:
                tar.addfile(extra_member, io.BytesIO(extra_data) if extra_data else None)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        (dist / "centl-linux-x86_64.tar.gz.sha256").write_text(
            f"{digest}  centl-linux-x86_64.tar.gz\n", encoding="utf-8"
        )
        return archive


class VersionTests(OasisTestCase):
    def test_reads_authoritative_version(self) -> None:
        self.write_version("1.2.3-rc.4")
        self.assertEqual(OASIS.read_version(self.root), "1.2.3-rc.4")

    def test_rejects_noncanonical_version_source(self) -> None:
        self.write_version()
        path = self.root / "src/ocaml/centl_version.ml"
        path.write_text('let value = Sys.getenv "CENTL_VERSION"\n', encoding="utf-8")
        with self.assertRaises(OASIS.OasisError):
            OASIS.read_version(self.root)


class PlanTests(OasisTestCase):
    def test_runtime_pin_gate_runs_before_any_repair(self) -> None:
        plan = OASIS.build_plan("0.13.0")
        self.assertEqual(plan[0].name, "toolchain-runtime")
        self.assertEqual(plan[0].phase, "preflight")

    def test_verified_extraction_precedes_native_tests(self) -> None:
        names = [gate.name for gate in OASIS.build_plan("0.13.0")]
        self.assertLess(names.index("fstar-verify"), names.index("extract"))
        self.assertLess(names.index("extract"), names.index("generated-diff"))
        self.assertLess(names.index("generated-diff"), names.index("native-tests"))

    def test_sanitizer_is_mandatory_in_oasis_hardening(self) -> None:
        hardening = next(gate for gate in OASIS.build_plan("0.13.0") if gate.name == "hardening")
        self.assertIn(("CENTL_SANITIZER_REQUIRED", "1"), hardening.env)

    def test_only_formatting_is_automatic_repair(self) -> None:
        repair = [gate.name for gate in OASIS.build_plan("0.13.0") if gate.phase == "repair"]
        self.assertEqual(repair, ["format-fix"])

    def test_release_plan_uses_authoritative_version(self) -> None:
        release = next(gate for gate in OASIS.build_plan("7.8.9") if gate.name == "release-package")
        self.assertIn("VERSION=7.8.9", release.argv)


class CommandRunnerTests(OasisTestCase):
    def test_failed_command_is_not_green(self) -> None:
        runner = OASIS.CommandRunner(self.root, self.root / "logs", echo=False)
        gate = OASIS.Gate(
            "false-command",
            "test",
            (sys.executable, "-c", "import sys; print('nope'); sys.exit(17)"),
            10,
            "intentional failure",
        )
        result = runner.run(gate, dict(os.environ))
        self.assertEqual(result.status, "failed")
        self.assertEqual(result.returncode, 17)
        self.assertTrue(Path(result.log).is_file())
        self.assertIsNotNone(result.log_sha256)

    def test_timeout_is_failure_and_process_is_stopped(self) -> None:
        runner = OASIS.CommandRunner(self.root, self.root / "logs", echo=False)
        gate = OASIS.Gate(
            "timeout-command",
            "test",
            (sys.executable, "-c", "import time; print('start', flush=True); time.sleep(30)"),
            1,
            "intentional timeout",
        )
        result = runner.run(gate, dict(os.environ))
        self.assertEqual(result.status, "timeout")
        self.assertEqual(result.returncode, 124)
        self.assertIn("timeout", result.detail or "")

    def test_missing_command_is_failure(self) -> None:
        runner = OASIS.CommandRunner(self.root, self.root / "logs", echo=False)
        gate = OASIS.Gate(
            "missing-command",
            "test",
            ("centl-oasis-definitely-does-not-exist",),
            1,
            "intentional missing tool",
        )
        result = runner.run(gate, dict(os.environ))
        self.assertEqual(result.status, "failed")
        self.assertEqual(result.returncode, 127)


class ArchiveTests(OasisTestCase):
    def test_accepts_structurally_safe_release_archive(self) -> None:
        self.make_archive()
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "passed", result.detail)

    def test_rejects_checksum_corruption(self) -> None:
        archive = self.make_archive()
        with archive.open("ab") as handle:
            handle.write(b"corrupt")
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("checksum mismatch", result.detail or "")

    def test_rejects_parent_path_traversal(self) -> None:
        info = tarfile.TarInfo("centl/../../escape")
        data = b"bad"
        info.size = len(data)
        info.mode = 0o644
        self.make_archive(extra_member=info, extra_data=data)
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("unsafe release archive path", result.detail or "")

    def test_rejects_absolute_path(self) -> None:
        info = tarfile.TarInfo("/tmp/escape")
        data = b"bad"
        info.size = len(data)
        info.mode = 0o644
        self.make_archive(extra_member=info, extra_data=data)
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("unsafe release archive path", result.detail or "")

    def test_rejects_noncanonical_path(self) -> None:
        info = tarfile.TarInfo("centl//extra")
        data = b"bad"
        info.size = len(data)
        info.mode = 0o644
        self.make_archive(extra_member=info, extra_data=data)
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("non-canonical", result.detail or "")

    def test_rejects_symlink(self) -> None:
        info = tarfile.TarInfo("centl/bin/evil-link")
        info.type = tarfile.SYMTYPE
        info.linkname = "/etc/passwd"
        info.mode = 0o755
        self.make_archive(extra_member=info)
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("contains a link", result.detail or "")

    def test_rejects_duplicate_member(self) -> None:
        info = tarfile.TarInfo("centl/VERSION")
        data = b"evil\n"
        info.size = len(data)
        info.mode = 0o644
        self.make_archive(extra_member=info, extra_data=data)
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("duplicate member", result.detail or "")

    def test_rejects_group_world_writable_entry(self) -> None:
        info = tarfile.TarInfo("centl/extra")
        data = b"bad"
        info.size = len(data)
        info.mode = 0o666
        self.make_archive(extra_member=info, extra_data=data)
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("group/world-writable", result.detail or "")

    def test_rejects_wrong_embedded_version(self) -> None:
        self.make_archive(version="0.12.0")
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("does not match", result.detail or "")

    def test_rejects_missing_required_binary(self) -> None:
        self.make_archive()
        archive = self.root / "dist/centl-linux-x86_64.tar.gz"
        replacement = self.root / "dist/replacement.tar.gz"
        with tarfile.open(archive, "r:gz") as src, tarfile.open(replacement, "w:gz") as dst:
            for member in src:
                if member.name == "centl/libexec/centl-sci":
                    continue
                payload = src.extractfile(member) if member.isfile() else None
                dst.addfile(member, payload)
        replacement.replace(archive)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        (self.root / "dist/centl-linux-x86_64.tar.gz.sha256").write_text(
            f"{digest}  centl-linux-x86_64.tar.gz\n", encoding="utf-8"
        )
        result = OASIS.validate_release_archive(self.root, "0.13.0")
        self.assertEqual(result.status, "failed")
        self.assertIn("missing required members", result.detail or "")


class EvidenceTests(OasisTestCase):
    def test_atomic_json_replaces_complete_document(self) -> None:
        path = self.root / "evidence/report.json"
        OASIS.atomic_json(path, {"result": "FAIL", "round": 1})
        OASIS.atomic_json(path, {"result": "PASS", "round": 2})
        self.assertEqual(
            json.loads(path.read_text(encoding="utf-8")),
            {"result": "PASS", "round": 2},
        )
        leftovers = list(path.parent.glob("report.json.*"))
        self.assertEqual(leftovers, [])


class IdentityTests(OasisTestCase):
    def test_wrong_branch_blocks_final_identity(self) -> None:
        state = {
            "head": "a" * 40,
            "branch": "main",
            "tracked_dirty": False,
            "tracked_changes": [],
        }
        with mock.patch.object(OASIS._engine, "run_capture", return_value=""):
            failures = OASIS.final_identity_checks(
                self.root, "0.13.0", state, "oasis"
            )
        self.assertTrue(any("requires oasis" in item for item in failures))

    def test_exact_oasis_branch_and_tag_can_pass_identity(self) -> None:
        head = "b" * 40
        state = {
            "head": head,
            "branch": "oasis",
            "tracked_dirty": False,
            "tracked_changes": [],
        }

        def fake_capture(root: Path, argv, timeout=30):
            if argv[:3] == ("git", "ls-remote", "origin") and argv[3] == "refs/heads/oasis":
                return f"{head}\trefs/heads/oasis"
            if argv[:3] == ("git", "ls-remote", "origin"):
                return f"{head}\trefs/tags/v0.13.0"
            raise AssertionError(argv)

        with mock.patch.object(OASIS._engine, "run_capture", side_effect=fake_capture):
            failures = OASIS.final_identity_checks(
                self.root, "0.13.0", state, "oasis"
            )
        self.assertEqual(failures, [])


class GitHubGateTests(OasisTestCase):
    def test_high_security_alerts_block_final_gate(self) -> None:
        def fake_capture(root: Path, argv, timeout=30):
            if tuple(argv[:3]) == ("gh", "pr", "list"):
                self.assertIn("oasis", argv)
                return "[]"
            raise AssertionError(f"unexpected command: {argv}")

        def fake_json(root: Path, endpoint: str):
            if "check-runs" in endpoint:
                return {
                    "check_runs": [
                        {"name": "CI", "status": "completed", "conclusion": "success"}
                    ]
                }
            if "code-scanning" in endpoint:
                return [{"number": 41, "rule": {"security_severity_level": "high"}}]
            if "dependabot" in endpoint or "secret-scanning" in endpoint:
                return []
            raise AssertionError(endpoint)

        with mock.patch.object(
            OASIS._engine, "github_repo_slug", return_value="chasebryan/centl"
        ), mock.patch.object(OASIS._engine, "run_capture", side_effect=fake_capture), mock.patch.object(
            OASIS._engine, "gh_json", side_effect=fake_json
        ):
            failures = OASIS.github_release_checks(self.root, "a" * 40, "oasis")
        self.assertTrue(any("code-scanning" in item for item in failures))

    def test_scorecard_job_level_contents_write_does_not_block_final_gate(self) -> None:
        def fake_capture(root: Path, argv, timeout=30):
            if tuple(argv[:3]) == ("gh", "pr", "list"):
                return "[]"
            raise AssertionError(f"unexpected command: {argv}")

        def fake_json(root: Path, endpoint: str):
            if "check-runs" in endpoint:
                return {
                    "check_runs": [
                        {"name": "CI", "status": "completed", "conclusion": "success"}
                    ]
                }
            if "code-scanning" in endpoint:
                return [
                    {
                        "number": 67,
                        "rule": {
                            "id": "TokenPermissionsID",
                            "security_severity_level": "high",
                            "severity": "error",
                        },
                        "most_recent_instance": {
                            "message": {
                                "text": "score is 0: jobLevel 'contents' permission set to 'write'"
                            }
                        },
                    }
                ]
            if "dependabot" in endpoint or "secret-scanning" in endpoint:
                return []
            raise AssertionError(endpoint)

        with mock.patch.object(
            OASIS._engine, "github_repo_slug", return_value="chasebryan/centl"
        ), mock.patch.object(OASIS._engine, "run_capture", side_effect=fake_capture), mock.patch.object(
            OASIS._engine, "gh_json", side_effect=fake_json
        ):
            failures = OASIS.github_release_checks(self.root, "a" * 40, "oasis")
        self.assertFalse(any("code-scanning" in item for item in failures))

    def test_open_pr_targeting_oasis_blocks_final_gate(self) -> None:
        def fake_capture(root: Path, argv, timeout=30):
            if tuple(argv[:3]) == ("gh", "pr", "list"):
                self.assertEqual(argv[argv.index("--base") + 1], "oasis")
                return '[{"number":123,"title":"unfinished","headRefName":"feature"}]'
            raise AssertionError(f"unexpected command: {argv}")

        def fake_json(root: Path, endpoint: str):
            if "check-runs" in endpoint:
                return {"check_runs": []}
            return []

        with mock.patch.object(
            OASIS._engine, "github_repo_slug", return_value="chasebryan/centl"
        ), mock.patch.object(OASIS._engine, "run_capture", side_effect=fake_capture), mock.patch.object(
            OASIS._engine, "gh_json", side_effect=fake_json
        ):
            failures = OASIS.github_release_checks(self.root, "b" * 40, "oasis")
        self.assertTrue(any("#123" in item for item in failures))
        self.assertTrue(any("target oasis" in item for item in failures))




class InspectTests(unittest.TestCase):
    def test_inspect_does_not_declare_oasis(self) -> None:
        with tempfile.TemporaryDirectory(prefix="centl-oasis-inspect-") as tmp:
            report = Path(tmp) / "inspect.json"
            rc = OASIS.main(
                ["--root", str(ROOT), "--inspect", "--quiet", "--report", str(report)]
            )
            self.assertEqual(rc, 0)
            payload = json.loads(report.read_text(encoding="utf-8"))
            self.assertFalse(payload["declaration"])
            self.assertFalse(payload["eligible_for_final_qualification"])
            self.assertEqual(payload["published_oasis"], "0.15.0")
            self.assertIn("blockers", payload)
            self.assertIn("cannot declare Oasis", payload["summary"])
            self.assertFalse(payload["fcf_camp"]["oasis_closed"])
            self.assertFalse(payload["fcf_camp"]["new_oasis_declared"])

    def test_inspect_records_oasis_non_regression_when_tip_missing(self) -> None:
        payload = OASIS.inspect_identity(ROOT, "0.14.0")
        self.assertFalse(payload["declaration"])
        contains, _tip = OASIS.contains_oasis_tip(ROOT)
        if contains:
            self.assertFalse(
                any("would regress Oasis-only work" in str(item) for item in payload["blockers"])
            )
        else:
            self.assertTrue(
                any("would regress Oasis-only work" in str(item) for item in payload["blockers"])
            )

if __name__ == "__main__":
    unittest.main()
