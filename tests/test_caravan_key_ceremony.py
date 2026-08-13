from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "caravan-join-key-ceremony"


class JoinKeyCeremonyTests(unittest.TestCase):
    def test_shell_syntax(self):
        subprocess.run(["bash", "-n", str(SCRIPT)], check=True)

    def test_expected_guardrails_are_present(self):
        text = SCRIPT.read_text(encoding="utf-8")
        self.assertIn('signify -G -p "$public" -s "$secret"', text)
        self.assertNotIn("signify -G -n", text)
        self.assertIn("outside the CENTL repository", text)
        self.assertIn("public enrollment is NOT enabled", text)


if __name__ == "__main__":
    unittest.main()
