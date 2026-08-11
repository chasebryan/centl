from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "centl_oasis_required_checks", ROOT / "scripts/oasis_required_checks.py"
)
assert SPEC is not None and SPEC.loader is not None
CHECKS = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKS
SPEC.loader.exec_module(CHECKS)


def run(
    name: str,
    *,
    ident: int,
    status: str = "completed",
    conclusion: str | None = "success",
    app_slug: str | None = "github-actions",
    details_url: str | None = None,
):
    if details_url is None:
        details_url = f"https://github.com/chasebryan/centl/actions/runs/{ident}/job/1"
    payload = {
        "id": ident,
        "name": name,
        "status": status,
        "conclusion": conclusion,
        "details_url": details_url,
    }
    if app_slug is not None:
        payload["app"] = {"slug": app_slug}
    return payload


class RequiredHostedCheckTests(unittest.TestCase):
    def good_payload(self):
        return {
            "check_runs": [
                run("Adversarial engine self-test", ident=10),
                run("Full stable-product convergence", ident=11),
            ]
        }

    def test_complete_success_set_passes(self) -> None:
        self.assertEqual(CHECKS.required_check_failures(self.good_payload()), [])

    def test_empty_check_set_fails_closed(self) -> None:
        failures = CHECKS.required_check_failures({"check_runs": []})
        self.assertEqual(len(failures), len(CHECKS.REQUIRED_CHECKS))
        self.assertTrue(all("missing" in item for item in failures))

    def test_missing_one_mandatory_check_fails(self) -> None:
        failures = CHECKS.required_check_failures(
            {"check_runs": [run("Adversarial engine self-test", ident=1)]}
        )
        self.assertEqual(
            failures,
            ["mandatory Oasis check is missing: Full stable-product convergence"],
        )

    def test_skipped_mandatory_check_is_not_success(self) -> None:
        payload = self.good_payload()
        payload["check_runs"][1] = run(
            "Full stable-product convergence",
            ident=12,
            conclusion="skipped",
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("skipped" in item for item in failures))

    def test_neutral_mandatory_check_is_not_success(self) -> None:
        payload = self.good_payload()
        payload["check_runs"][1] = run(
            "Full stable-product convergence",
            ident=12,
            conclusion="neutral",
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("neutral" in item for item in failures))

    def test_pending_mandatory_check_is_not_success(self) -> None:
        payload = self.good_payload()
        payload["check_runs"][0] = run(
            "Adversarial engine self-test",
            ident=12,
            status="in_progress",
            conclusion=None,
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("in_progress" in item for item in failures))

    def test_newest_attempt_controls_result(self) -> None:
        payload = self.good_payload()
        payload["check_runs"].extend(
            [
                run("Full stable-product convergence", ident=20, conclusion="failure"),
                run("Full stable-product convergence", ident=5, conclusion="success"),
            ]
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("failure" in item for item in failures))

    def test_lookalike_check_from_other_app_is_rejected(self) -> None:
        payload = self.good_payload()
        payload["check_runs"][1] = run(
            "Full stable-product convergence",
            ident=21,
            app_slug="untrusted-check-app",
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("unexpected provenance" in item for item in failures))

    def test_missing_app_identity_is_rejected(self) -> None:
        payload = self.good_payload()
        payload["check_runs"][0] = run(
            "Adversarial engine self-test",
            ident=22,
            app_slug=None,
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("app:<missing>" in item for item in failures))

    def test_non_actions_details_url_is_rejected(self) -> None:
        payload = self.good_payload()
        payload["check_runs"][0] = run(
            "Adversarial engine self-test",
            ident=23,
            details_url="https://example.invalid/result/23",
        )
        failures = CHECKS.required_check_failures(payload)
        self.assertTrue(any("invalid Actions details URL" in item for item in failures))

    def test_malformed_payload_fails_closed(self) -> None:
        self.assertTrue(CHECKS.required_check_failures(None))
        self.assertTrue(CHECKS.required_check_failures({}))


if __name__ == "__main__":
    unittest.main()
