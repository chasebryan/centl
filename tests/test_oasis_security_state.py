from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "centl_oasis_security_state", ROOT / "scripts/oasis-security-state.py"
)
assert SPEC is not None and SPEC.loader is not None
SECURITY = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = SECURITY
SPEC.loader.exec_module(SECURITY)


class SecurityStateTests(unittest.TestCase):
    def test_empty_alert_sets_pass(self) -> None:
        self.assertEqual(SECURITY.blocking_findings([], [], []), [])

    def test_high_code_scanning_blocks(self) -> None:
        failures = SECURITY.blocking_findings(
            [{"number": 7, "rule": {"security_severity_level": "high"}}], [], []
        )
        self.assertTrue(any("code-scanning" in item for item in failures))

    def test_scorecard_job_level_contents_write_does_not_block(self) -> None:
        failures = SECURITY.blocking_findings(
            [
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
            ],
            [],
            [],
        )
        self.assertEqual(failures, [])

    def test_scorecard_top_level_contents_write_blocks(self) -> None:
        failures = SECURITY.blocking_findings(
            [
                {
                    "number": 68,
                    "rule": {
                        "id": "TokenPermissionsID",
                        "security_severity_level": "high",
                    },
                    "most_recent_instance": {
                        "message": {
                            "text": "score is 0: topLevel 'contents' permission set to 'write'"
                        }
                    },
                }
            ],
            [],
            [],
        )
        self.assertTrue(any("68" in item for item in failures))

    def test_scorecard_job_level_statuses_write_blocks(self) -> None:
        failures = SECURITY.blocking_findings(
            [
                {
                    "number": 66,
                    "rule": {
                        "id": "TokenPermissionsID",
                        "security_severity_level": "high",
                    },
                    "most_recent_instance": {
                        "message": {
                            "text": "score is 0: jobLevel 'statuses' permission set to 'write'"
                        }
                    },
                }
            ],
            [],
            [],
        )
        self.assertTrue(any("66" in item for item in failures))

    def test_error_code_scanning_blocks(self) -> None:
        failures = SECURITY.blocking_findings(
            [{"number": 8, "rule": {"severity": "error"}}], [], []
        )
        self.assertTrue(failures)

    def test_medium_code_scanning_does_not_block_release_gate(self) -> None:
        failures = SECURITY.blocking_findings(
            [{"number": 9, "rule": {"security_severity_level": "medium"}}], [], []
        )
        self.assertEqual(failures, [])

    def test_high_dependabot_blocks(self) -> None:
        failures = SECURITY.blocking_findings(
            [], [{"number": 4, "security_advisory": {"severity": "high"}}], []
        )
        self.assertTrue(any("Dependabot" in item for item in failures))

    def test_medium_dependabot_does_not_block_release_gate(self) -> None:
        failures = SECURITY.blocking_findings(
            [], [{"number": 5, "security_advisory": {"severity": "medium"}}], []
        )
        self.assertEqual(failures, [])

    def test_any_open_secret_blocks(self) -> None:
        failures = SECURITY.blocking_findings([], [], [{"number": 12}])
        self.assertTrue(any("secret-scanning" in item for item in failures))

    def test_malformed_api_shape_fails_closed(self) -> None:
        failures = SECURITY.blocking_findings({}, None, "bad")
        self.assertEqual(len(failures), 3)


if __name__ == "__main__":
    unittest.main()
