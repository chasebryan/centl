#!/usr/bin/env python3
"""Validate a committed CENTL-SCi assimilation report."""

from __future__ import annotations

import argparse
import json
import string
import subprocess
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument(
        "--require-product-gates",
        action="store_true",
        help="fail if native/product/model-safety gates are not passing",
    )
    parser.add_argument(
        "--require-source-ancestor",
        action="store_true",
        help="require that the report.git.commit is an ancestor of HEAD",
    )
    return parser.parse_args()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def valid_commit_sha(value: Any) -> bool:
    return (
        isinstance(value, str)
        and len(value) == 40
        and all(character in string.hexdigits for character in value)
    )


def git_is_ancestor(commit: str) -> bool:
    completed = subprocess.run(
        ["git", "merge-base", "--is-ancestor", commit, "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    # git merge-base --is-ancestor returns:
    # 0 = yes (commit is ancestor), 1 = no (not ancestor), >1 = error
    if completed.returncode == 0:
        return True
    if completed.returncode == 1:
        return False
    # propagate git errors with stderr for diagnostics
    stderr = (completed.stderr or completed.stdout or "").strip()
    raise SystemExit(f"git error while checking ancestry: returncode={completed.returncode} {stderr}")


def main() -> int:
    args = parse_args()
    require(args.report.is_file(), f"report not found: {args.report}")
    try:
        payload: Any = json.loads(args.report.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"invalid report JSON: {error}") from error
    require(isinstance(payload, dict), "report must be a JSON object")
    require(payload.get("schema_version") == 1, "unsupported report schema_version")
    require(
        payload.get("report_kind") == "centl-sci-assimilation",
        "unexpected report_kind",
    )
    require(
        payload.get("sci_version") == "0.0.2-Caramels+",
        "unexpected sci_version",
    )

    git = payload.get("git")
    require(isinstance(git, dict), "report.git must be an object")
    source_commit = git.get("commit")
    require(valid_commit_sha(source_commit), "report.git.commit must be a full hexadecimal commit SHA")

    # Strong provenance (ancestor) is optional by default. It is required
    # only when the caller sets --require-source-ancestor or when
    # --require-product-gates is requested (product gates imply strong
    # provenance to ensure fresh/fenced evidence can't be bypassed).
    if args.require_source_ancestor or args.require_product_gates:
        is_ancestor = git_is_ancestor(source_commit)
        require(isinstance(is_ancestor, bool), "git ancestry check failed")
        require(
            is_ancestor,
            "report source commit is not an ancestor of the committed report",
        )

    product = payload.get("product")
    require(isinstance(product, dict), "report.product must be an object")
    summary = product.get("summary")
    require(isinstance(summary, dict), "report.product.summary must be an object")
    cases = product.get("cases")
    require(isinstance(cases, list), "report.product.cases must be an array")
    require(summary.get("total") == len(cases), "product summary total mismatch")
    require(
        summary.get("passed") == sum(1 for case in cases if case.get("pass") is True),
        "product summary passed mismatch",
    )

    gates = payload.get("gates")
    require(isinstance(gates, dict), "report.gates must be an object")
    for name in ("native", "product", "model_safety", "model_full_qualification"):
        require(name in gates, f"missing gate: {name}")

    model = payload.get("model")
    require(isinstance(model, dict), "report.model must be an object")
    if model.get("enabled"):
        model_cases = model.get("cases")
        model_summary = model.get("summary")
        require(isinstance(model_cases, list), "model.cases must be an array")
        require(isinstance(model_summary, dict), "model.summary must be an object")
        require(model_summary.get("total") == len(model_cases), "model total mismatch")
        require(
            model_summary.get("passed")
            == sum(1 for case in model_cases if case.get("pass") is True),
            "model passed mismatch",
        )

    if args.require_product_gates:
        require(gates.get("native") is True, "native assimilation gate failed")
        require(gates.get("product") is True, "product assimilation gate failed")
        if model.get("enabled"):
            require(gates.get("model_safety") is True, "model safety gate failed")

    print(
        "CENTL-SCi assimilation report valid: "
        f"product={summary.get('passed')}/{summary.get('total')}, "
        f"model={'enabled' if model.get('enabled') else 'not-run'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
