from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
INSTALL = (ROOT / "install").read_text(encoding="utf-8")


class MarsaInstallTests(unittest.TestCase):
    def test_linux_still_gets_the_prebuilt_path(self) -> None:
        self.assertIn("Linux) platform=linux ;;", INSTALL)
        self.assertIn('asset="centl-${platform}-${architecture}.tar.gz"', INSTALL)

    def test_macos_and_windows_are_sent_to_marsa_not_a_dead_end(self) -> None:
        self.assertIn("Darwin) platform=macos ;;", INSTALL)
        self.assertIn("platform=windows ;;", INSTALL)
        self.assertIn("git checkout CENTL-Marsa", INSTALL)
        self.assertIn("CENTL Marsa is not Oasis", INSTALL)
        self.assertNotIn("macOS is currently unsupported", INSTALL)


if __name__ == "__main__":
    unittest.main()
