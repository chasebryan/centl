#!/usr/bin/env python3
"""Fail closed on repository security alerts that block an Oasis release."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Sequence


class SecurityStateError(RuntimeError):
    pass


def run_capture(root: Path, argv: Sequence[str], timeout: int = 120) -> str:
    try:
        completed = subprocess.run(
            argv,
            cwd=root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise SecurityStateError(f"cannot run {' '.join(argv)}: {exc}") from exc
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise SecurityStateError(f"{' '.join(argv)} failed: {detail}")
    return completed.stdout.strip()


def repository_slug(root: Path) -> str:
    url = run_capture(root, ("git", "remote", "get-url", "origin"))
    match = re.search(r"github[.]com(?::|/)([^/\s]+/[^/\s]+?)(?:[.]git)?$", url)
    if not match:
        raise SecurityStateError(f"cannot derive GitHub repository from origin URL: {url}")
    return match.group(1)


def gh_json(root: Path, endpoint: str) -> object:
    raw = run_capture(root, ("gh", "api", endpoint))
    try:
        return json.loads(raw or "null")
    except json.JSONDecodeError as exc:
        raise SecurityStateError(f"GitHub API returned invalid JSON for {endpoint}") from exc


def _alert_message(alert: dict) -> str:
    instance = alert.get("most_recent_instance") or {}
    if not isinstance(instance, dict):
        return ""
    message = instance.get("message")
    if isinstance(message, dict):
        return str(message.get("text") or "")
    if isinstance(message, str):
        return message
    return ""


def is_blocking_code_scanning_alert(alert: object) -> bool:
    """High/critical/error alerts block, except Scorecard job-level contents write.

    Scorecard reports publication-job ``contents: write`` as high even though
    that finding does not reduce the Token-Permissions score. Those jobs still
    need job-scoped write to create releases or update ``distribution``.
    Top-level write, statuses/checks write, and every other high finding stay
    blocking.
    """
    if not isinstance(alert, dict):
        return False
    rule = alert.get("rule") or {}
    if not isinstance(rule, dict):
        rule = {}
    rule_id = str(rule.get("id") or "")
    text = _alert_message(alert).lower()
    if (
        rule_id == "TokenPermissionsID"
        and "joblevel" in text
        and "'contents'" in text
    ):
        return False
    severity = str(
        rule.get("security_severity_level") or rule.get("severity") or ""
    ).lower()
    return severity in {"critical", "high", "error"}


def blocking_findings(
    code_scanning: object,
    dependabot: object,
    secret_scanning: object,
) -> list[str]:
    failures: list[str] = []

    if not isinstance(code_scanning, list):
        failures.append("code-scanning alert response is not a list")
    else:
        blocking = []
        for alert in code_scanning:
            if is_blocking_code_scanning_alert(alert):
                blocking.append(str(alert.get("number", "?")))
        if blocking:
            failures.append("open release-blocking code-scanning alerts: " + ", ".join(blocking))

    if not isinstance(dependabot, list):
        failures.append("Dependabot alert response is not a list")
    else:
        blocking = []
        for alert in dependabot:
            if not isinstance(alert, dict):
                continue
            advisory = alert.get("security_advisory") or {}
            if not isinstance(advisory, dict):
                advisory = {}
            severity = str(advisory.get("severity") or "").lower()
            if severity in {"critical", "high"}:
                blocking.append(str(alert.get("number", "?")))
        if blocking:
            failures.append("open high/critical Dependabot alerts: " + ", ".join(blocking))

    if not isinstance(secret_scanning, list):
        failures.append("secret-scanning alert response is not a list")
    elif secret_scanning:
        identifiers = ", ".join(
            str(item.get("number", "?"))
            for item in secret_scanning[:20]
            if isinstance(item, dict)
        )
        failures.append("open secret-scanning alerts: " + (identifiers or "unknown"))

    return failures


def check(root: Path) -> list[str]:
    repo = repository_slug(root)
    code = gh_json(root, f"repos/{repo}/code-scanning/alerts?state=open&per_page=100")
    deps = gh_json(root, f"repos/{repo}/dependabot/alerts?state=open&per_page=100")
    secrets = gh_json(root, f"repos/{repo}/secret-scanning/alerts?state=open&per_page=100")
    return blocking_findings(code, deps, secrets)


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Check GitHub security state for CENTL Oasis")
    p.add_argument("--root", type=Path, default=Path.cwd())
    return p


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        failures = check(args.root.resolve())
    except SecurityStateError as exc:
        print(f"centl oasis security: {exc}", file=sys.stderr)
        return 1
    if failures:
        for failure in failures:
            print(f"centl oasis security: {failure}", file=sys.stderr)
        return 1
    print("Oasis release-blocking GitHub security state is clear.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
