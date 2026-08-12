import os
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DRIVER = ROOT / "scripts" / "caravan-preserve"
RECEIPT_HELPER = ROOT / "scripts" / "caravan-preserve-receipt.py"


class CaravanPreserveDriverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = DRIVER.read_text(encoding="utf-8")
        cls.receipt_text = RECEIPT_HELPER.read_text(encoding="utf-8")

    def test_driver_is_executable_and_shell_syntax_is_valid(self):
        self.assertTrue(os.access(DRIVER, os.X_OK), "driver must be executable")
        subprocess.run(["sh", "-n", str(DRIVER)], check=True)

    def test_default_path_updates_main_and_reexecs_fresh_policy(self):
        text = self.text
        self.assertIn('git -C "$repo_root" fetch origin main', text)
        self.assertIn('git -C "$repo_root" merge --ff-only origin/main', text)
        self.assertIn('exec "$repo_root/scripts/caravan-preserve" --no-update', text)
        self.assertNotIn("git reset --hard", text)
        self.assertNotIn("git clean -", text)

    def test_existing_capsule_uses_source_only_refresh(self):
        text = self.text
        for required in (
            "capsule/centl-build-capsule.oci.tar",
            "capsule/centl-build-capsule.oci.tar.sha256",
            "capsule/IMAGE-REF",
            "recovery/capsule-run",
            "sci-runtime/llama-cli",
        ):
            self.assertIn(required, text)
        self.assertIn(
            'note "Reusing dependency cargo and recovery capsule; refreshing CENTL source only"',
            text,
        )
        self.assertIn(
            'sh "$repo_root/scripts/supply-chain" snapshot-centl "$mirror"', text
        )

    def test_stale_receipt_adoption_is_narrow_and_authenticated(self):
        driver = self.text
        helper = self.receipt_text
        self.assertIn(
            'python3 "$repo_root/scripts/caravan-preserve-receipt.py" "$mirror"',
            driver,
        )
        for path in (
            "project/centl.bundle",
            "project/SOURCE-SHA256SUMS",
            "project/SOURCE-SHA256SUMS.sha256",
            "project/SOURCE-COMMIT",
        ):
            self.assertIn(path, helper)
        self.assertIn("integrity.verify_manifest(manifest_hash, root)", helper)
        self.assertIn("integrity.verify_manifest(symlinks_hash, root)", helper)
        self.assertIn("integrity.verify_symlink_manifest", helper)
        self.assertIn("mirror drift exists outside controlled source refresh", helper)
        self.assertIn(
            "invalid outside the controlled source-refresh surfaces", driver
        )

    def test_no_network_recovery_precedes_whole_mirror_seal(self):
        text = self.text
        run_pos = text.index('make -C "$repo_root" capsule-run MIRROR="$mirror"')
        create_pos = text.index(
            'sh "$repo_root/scripts/mirror-receipt" create "$mirror"'
        )
        verify_pos = text.index(
            'sh "$repo_root/scripts/mirror-receipt" verify "$mirror"', create_pos
        )
        self.assertLess(run_pos, create_pos)
        self.assertLess(create_pos, verify_pos)

    def test_failure_is_resumable_and_does_not_delete_preserved_cargo(self):
        text = self.text
        self.assertIn("CARAVAN PRESERVATION PAUSED", text)
        self.assertIn("run the SAME command again: scripts/caravan-preserve", text)
        self.assertNotIn('rm -rf "$mirror"', text)
        self.assertNotIn("rm -rf /srv/centl-mirror", text)

    def test_success_contract_is_explicit(self):
        text = self.text
        self.assertIn("FCF CARAVAN PRESERVATION PASS", text)
        self.assertIn("No-network recovery proved", text)
        self.assertIn("Whole-mirror receipt sealed and verified", text)


if __name__ == "__main__":
    unittest.main()
