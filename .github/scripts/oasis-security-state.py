#!/usr/bin/env python3
"""Fail closed on GitHub security alerts that block a CENTL Oasis release.

This script belongs to the trusted default-branch qualification control plane.
It deliberately does not execute from the candidate checkout when credentials
with security-alert visibility are present.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Mapping


class SecurityStateError(RuntimeError):
    pass


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SecurityStateError(f"required environment variable {name} is not set")
    return value


def gh_json(endpoint: str, token: str) -> object:
    env: Mapping[str, str] = {**os.environ, "GH_TOKEN": token}
    try:
        completed = subprocess.run(
            ("gh", "api", endpoint),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=120,
            check=False,
            env=env,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise SecurityStateError(f"cannot query {endpoint}: {exc}") from exc
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise SecurityStateError(f"gh api {endpoint} failed: {detail}")
    try:
        return json.loads(completed.stdout or "null")
    except json.JSONDecodeError as exc:
        raise SecurityStateError(f"GitHub API returned invalid JSON for {endpoint}") from exc


def blocking_findings(
    code_scanning: object,
    dependabot: object,
    secret_scanning: object,
) -> list[str]:
    failures: list[str] = []

    if not isinstance(code_scanning, list):
        failures.append("code-scanning alert response is not a list")
    else:
        blocking: list[str] = []
        for alert in code_scanning:
            if not isinstance(alert, dict):
                continue
            rule = alert.get("rule") or {}
            if not isinstance(rule, dict):
                rule = {}
            severity = str(
                rule.get("security_severity_level") or rule.get("severity") or ""
            ).lower()
            if severity in {"critical", "high", "error"}:
                blocking.append(str(alert.get("number", "?")))
        if blocking:
            failures.append(
                "open release-blocking code-scanning alerts: " + ", ".join(blocking)
            )

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
            failures.append(
                "open high/critical Dependabot alerts: " + ", ".join(blocking)
            )

    if not isinstance(secret_scanning, list):
        failures.append("secret-scanning alert response is not a list")
    elif secret_scanning:
        identifiers = ", ".join(
            str(item.get("number", "?"))
            for item in secret_scanning[:20]
            if isinstance(item, dict)
        )
        failures.append(
            "open secret-scanning alerts: " + (identifiers or "unknown")
        )

    return failures


def main() -> int:
    try:
        repo = require_env("GITHUB_REPOSITORY")
        github_token = require_env("GH_TOKEN")
        secret_token = require_env("OASIS_SECRET_SCANNING_TOKEN")

        code = gh_json(
            f"repos/{repo}/code-scanning/alerts?state=open&per_page=100",
            github_token,
        )
        dependabot = gh_json(
            f"repos/{repo}/dependabot/alerts?state=open&per_page=100",
            github_token,
        )
        secrets = gh_json(
            f"repos/{repo}/secret-scanning/alerts?state=open&per_page=100",
            secret_token,
        )
        failures = blocking_findings(code, dependabot, secrets)
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
