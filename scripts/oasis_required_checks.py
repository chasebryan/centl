#!/usr/bin/env python3
"""Require the mandatory hosted Oasis checks to exist and succeed.

The general final-state gate rejects visible failures, but a release cannot earn
Oasis status merely because GitHub returned an empty or incomplete check set.
This module fail-closes on the two checks produced by the authoritative Oasis
qualification workflow and requires the newest run of each check to be a
completed success for the exact candidate commit.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Sequence

REQUIRED_CHECKS = (
    "Adversarial engine self-test",
    "Full stable-product convergence",
)


class HostedCheckError(RuntimeError):
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
        raise HostedCheckError(f"cannot run {' '.join(argv)}: {exc}") from exc
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise HostedCheckError(f"{' '.join(argv)} failed: {detail}")
    return completed.stdout.strip()


def github_repo_slug(root: Path) -> str:
    url = run_capture(root, ("git", "remote", "get-url", "origin"))
    match = re.search(r"github[.]com(?::|/)([^/\s]+/[^/\s]+?)(?:[.]git)?$", url)
    if not match:
        raise HostedCheckError(f"cannot derive GitHub repository from origin URL: {url}")
    return match.group(1)


def newest_by_name(runs: list[object]) -> dict[str, dict[str, object]]:
    newest: dict[str, dict[str, object]] = {}
    for raw in runs:
        if not isinstance(raw, dict):
            continue
        name = raw.get("name")
        if not isinstance(name, str):
            continue
        current = newest.get(name)
        raw_id = raw.get("id")
        current_id = current.get("id") if current else None
        raw_order = raw_id if isinstance(raw_id, int) else -1
        current_order = current_id if isinstance(current_id, int) else -1
        if current is None or raw_order >= current_order:
            newest[name] = raw
    return newest


def required_check_failures(payload: object) -> list[str]:
    if not isinstance(payload, dict):
        return ["GitHub check-runs response is not an object"]
    runs = payload.get("check_runs")
    if not isinstance(runs, list):
        return ["GitHub check-runs response has no check_runs list"]

    newest = newest_by_name(runs)
    failures: list[str] = []
    for name in REQUIRED_CHECKS:
        item = newest.get(name)
        if item is None:
            failures.append(f"mandatory Oasis check is missing: {name}")
            continue
        status = item.get("status")
        conclusion = item.get("conclusion")
        if status != "completed" or conclusion != "success":
            failures.append(
                f"mandatory Oasis check is not successful: {name}={status}/{conclusion}"
            )
    return failures


def check(root: Path) -> tuple[str, list[str]]:
    head = run_capture(root, ("git", "rev-parse", "HEAD"))
    repo = github_repo_slug(root)
    raw = run_capture(
        root,
        ("gh", "api", f"repos/{repo}/commits/{head}/check-runs?per_page=100"),
    )
    try:
        payload = json.loads(raw or "null")
    except json.JSONDecodeError as exc:
        raise HostedCheckError("GitHub check-runs response is not valid JSON") from exc
    return head, required_check_failures(payload)


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Require successful mandatory GitHub checks for a final CENTL Oasis candidate"
    )
    p.add_argument("--root", type=Path, default=Path.cwd())
    return p


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        head, failures = check(args.root.resolve())
    except HostedCheckError as exc:
        print(f"centl oasis hosted checks: {exc}", file=sys.stderr)
        return 1
    if failures:
        for failure in failures:
            print(f"centl oasis hosted checks: {failure}", file=sys.stderr)
        return 1
    print(f"Mandatory Oasis hosted checks are successful for {head}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
