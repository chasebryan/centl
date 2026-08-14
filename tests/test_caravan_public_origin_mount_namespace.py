from __future__ import annotations

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
UNIT = ROOT / "infra" / "caravan-public-origin" / "fcf-caravan-activate.service"
ACTIVATOR = ROOT / "scripts" / "caravan-public-origin-activate.py"


class CaravanPublicOriginMountNamespaceTests(unittest.TestCase):
    def test_atomic_claim_uses_one_writable_var_lib_mount(self) -> None:
        unit = UNIT.read_text(encoding="utf-8")
        self.assertIn(
            "ReadWritePaths=/var/lib/fcf-caravan /srv/fcf-caravan-live",
            unit,
        )
        self.assertNotIn(
            "ReadWritePaths=/var/lib/fcf-caravan/candidates ",
            unit,
        )
        self.assertNotIn(
            "/var/lib/fcf-caravan/activation-inbox /srv/fcf-caravan-live",
            unit,
        )

    def test_non_handoff_state_is_remasked_read_only(self) -> None:
        unit = UNIT.read_text(encoding="utf-8")
        read_only = next(
            line for line in unit.splitlines() if line.startswith("ReadOnlyPaths=")
        )
        for path in (
            "/var/lib/fcf-caravan/approved",
            "/var/lib/fcf-caravan/source-state",
            "/var/lib/fcf-caravan/ingest-work",
            "/run/lock/fcf-caravan-publication.lock",
        ):
            self.assertIn(path, read_only)

    def test_activator_keeps_atomic_rename_claim(self) -> None:
        activator = ACTIVATOR.read_text(encoding="utf-8")
        self.assertIn(
            '"/var/lib/fcf-caravan/candidates"',
            activator,
        )
        self.assertIn(
            '"/var/lib/fcf-caravan/activation-inbox"',
            activator,
        )
        self.assertIn("os.rename(source, claimed)", activator)
        self.assertNotIn("shutil.move(source, claimed)", activator)


if __name__ == "__main__":
    unittest.main()
