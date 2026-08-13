from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SignifyPortabilityTests(unittest.TestCase):
    def test_join_installer_accepts_debian_signify_name(self):
        text = (ROOT / "scripts" / "caravan-join-template").read_text(encoding="utf-8")
        self.assertIn("command -v signify-openbsd", text)
        self.assertIn('command signify-openbsd "$@"', text)
        self.assertIn("signify (or Debian's signify-openbsd)", text)

    def test_release_tool_accepts_debian_signify_name(self):
        text = (ROOT / "scripts" / "caravan-join-release").read_text(encoding="utf-8")
        self.assertIn("command -v signify-openbsd", text)
        self.assertIn('command signify-openbsd "$@"', text)


if __name__ == "__main__":
    unittest.main()
