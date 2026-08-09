#!/usr/bin/env python3
"""Qualify a local CENTL-SCi model against the deterministic v0.0.1 corpus."""

from __future__ import annotations

import argparse
import json
import os
import platform
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CORPUS = ROOT / "tests" / "corpus" / "sci_v0_0_1.jsonl"
DEFAULT_SCI = ROOT / "_build" / "default" / "src" / "sci_main.exe"
SCI_RUNTIME_SOURCES = [
    ROOT / "src" / "sci_main.ml",
    ROOT / "src" / "ocaml" / "centl_sci_ir.ml",
    ROOT / "src" / "ocaml" / "centl_sci_fastpath.ml",
    ROOT / "src" / "ocaml" / "centl_sci_llama.ml",
    ROOT / "src" / "ocaml" / "centl_sci_runtime.ml",
    ROOT / "src" / "ocaml" / "centl_sci_schema.ml",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run a local GGUF model through the real centl-sci process boundary and "
            "score its structured interpretation plus CENTL result."
        )
    )
    parser.add_argument("--model", required=True, help="path to the local GGUF model")
    parser.add_argument(
        "--model-label",
        default=None,
        help="human-readable model/quantization label recorded in the report",
    )
    parser.add_argument(
        "--llama-cli",
        default=os.environ.get("CENTL_SCI_LLAMA_CLI", "llama-cli"),
        help="llama.cpp llama-cli executable",
    )
    parser.add_argument(
        "--centl-sci",
        default=str(DEFAULT_SCI),
        help="built centl-sci executable",
    )
    parser.add_argument(
        "--corpus",
        default=str(DEFAULT_CORPUS),
        help="SCi JSONL evaluation corpus",
    )
    parser.add_argument(
        "--case",
        action="append",
        dest="cases",
        default=[],
        help="run only this fixture id; may be repeated",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=300.0,
        help="maximum seconds for one problem, including model load",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="write the full JSON report to this path instead of stdout",
    )
    return parser.parse_args()


def load_corpus(path: Path) -> list[dict[str, Any]]:
    fixtures: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            stripped = line.strip()
            if not stripped:
                continue
            try:
                fixture = json.loads(stripped)
            except json.JSONDecodeError as error:
                raise SystemExit(f"{path}:{line_number}: invalid JSON: {error}") from error
            if not isinstance(fixture, dict) or not isinstance(fixture.get("id"), str):
                raise SystemExit(f"{path}:{line_number}: fixture must be an object with string id")
            fixtures.append(fixture)
    return fixtures


def command_version(executable: str) -> str | None:
    try:
        completed = subprocess.run(
            [executable, "--version"],
            check=False,
            capture_output=True,
            text=True,
            timeout=10.0,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    text = completed.stdout.strip() or completed.stderr.strip()
    if not text:
        return None
    return text.splitlines()[0][:1024]


def ensure_default_binary_is_fresh(centl_sci: Path) -> None:
    if centl_sci != DEFAULT_SCI.resolve():
        return
    executable_mtime = centl_sci.stat().st_mtime
    newer_sources = [
        source
        for source in SCI_RUNTIME_SOURCES
        if source.is_file() and source.stat().st_mtime > executable_mtime
    ]
    if newer_sources:
        relative = ", ".join(str(source.relative_to(ROOT)) for source in newer_sources)
        raise SystemExit(
            "default centl-sci executable is older than SCi source files "
            f"({relative}); run `make build` before model evaluation"
        )


def dict_contains(actual: Any, expected_subset: Any) -> bool:
    if isinstance(expected_subset, dict):
        if not isinstance(actual, dict):
            return False
        return all(
            key in actual and dict_contains(actual[key], value)
            for key, value in expected_subset.items()
        )
    if isinstance(expected_subset, list):
        return actual == expected_subset
    return actual == expected_subset


def response_text(payload: dict[str, Any]) -> str | None:
    response = payload.get("centl_response")
    if not isinstance(response, dict):
        return None
    value = response.get("value")
    if isinstance(value, dict) and isinstance(value.get("text"), str):
        return value["text"]
    physics = response.get("physics")
    if isinstance(physics, dict) and isinstance(physics.get("text"), str):
        return physics["text"]
    error = response.get("error")
    if isinstance(error, dict) and isinstance(error.get("message"), str):
        return error["message"]
    return None


def score_payload(fixture: dict[str, Any], payload: dict[str, Any]) -> list[str]:
    expected = fixture["expected"]
    interpretation = payload.get("interpretation")
    mismatches: list[str] = []

    if payload.get("interpreter_path") != "model":
        mismatches.append(
            "model qualification did not traverse the model interpreter path"
        )

    if not isinstance(interpretation, dict):
        return mismatches + ["centl-sci output has no structured interpretation"]

    for field in ("domain", "problem_class", "operation", "assumptions"):
        if interpretation.get(field) != expected.get(field):
            mismatches.append(
                f"interpretation.{field}: expected {expected.get(field)!r}, "
                f"observed {interpretation.get(field)!r}"
            )

    acceptable = expected.get("acceptable_ir", [])
    if acceptable:
        if not any(dict_contains(interpretation, candidate) for candidate in acceptable):
            mismatches.append("interpretation does not match any acceptable IR formalization")

    reason_contains = expected.get("reason_contains")
    if reason_contains:
        reason = interpretation.get("reason")
        if not isinstance(reason, str) or reason_contains.lower() not in reason.lower():
            mismatches.append(
                f"unsupported reason does not contain {reason_contains!r}: {reason!r}"
            )

    expected_centl = expected.get("centl", {})
    expected_status = expected_centl.get("status")
    if payload.get("status") != expected_status:
        mismatches.append(
            f"status: expected {expected_status!r}, observed {payload.get('status')!r}"
        )

    expected_text = expected_centl.get("text")
    if expected_text is not None:
        observed_text = response_text(payload)
        if observed_text != expected_text:
            mismatches.append(
                f"CENTL text: expected {expected_text!r}, observed {observed_text!r}"
            )

    return mismatches


def run_fixture(
    fixture: dict[str, Any],
    *,
    model: Path,
    llama_cli: str,
    centl_sci: Path,
    timeout: float,
) -> dict[str, Any]:
    command = [
        str(centl_sci),
        "--model",
        str(model),
        "--llama-cli",
        llama_cli,
        "--force-model",
        "--json",
        fixture["problem"],
    ]
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        elapsed = time.perf_counter() - started
    except subprocess.TimeoutExpired as error:
        elapsed = time.perf_counter() - started
        return {
            "id": fixture["id"],
            "pass": False,
            "elapsed_seconds": round(elapsed, 6),
            "exit_code": None,
            "mismatches": [f"timed out after {timeout:g} seconds"],
            "stdout": error.stdout or "",
            "stderr": error.stderr or "",
            "observed": None,
        }

    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip()
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as error:
        mismatch = f"centl-sci did not emit JSON: {error}"
        if completed.returncode != 0:
            mismatch += f"; exit code {completed.returncode}"
        return {
            "id": fixture["id"],
            "pass": False,
            "elapsed_seconds": round(elapsed, 6),
            "exit_code": completed.returncode,
            "mismatches": [mismatch],
            "stdout": stdout,
            "stderr": stderr,
            "observed": None,
        }

    if not isinstance(payload, dict):
        mismatches = ["centl-sci JSON output is not an object"]
    else:
        mismatches = score_payload(fixture, payload)

    expected_status = fixture["expected"].get("centl", {}).get("status")
    expected_exit = 1 if expected_status == "failed" else 0
    if completed.returncode != expected_exit:
        mismatches.append(
            f"exit code: expected {expected_exit}, observed {completed.returncode}"
        )

    return {
        "id": fixture["id"],
        "pass": not mismatches,
        "elapsed_seconds": round(elapsed, 6),
        "exit_code": completed.returncode,
        "mismatches": mismatches,
        "stderr": stderr,
        "observed": payload,
    }


def main() -> int:
    args = parse_args()
    model = Path(args.model).expanduser().resolve()
    centl_sci = Path(args.centl_sci).expanduser().resolve()
    corpus = Path(args.corpus).expanduser().resolve()

    if not model.is_file():
        raise SystemExit(f"model file not found: {model}")
    if not centl_sci.is_file():
        raise SystemExit(
            f"centl-sci executable not found: {centl_sci}; run `make build` first"
        )
    ensure_default_binary_is_fresh(centl_sci)
    if not corpus.is_file():
        raise SystemExit(f"corpus file not found: {corpus}")
    if args.timeout <= 0:
        raise SystemExit("--timeout must be positive")

    fixtures = load_corpus(corpus)
    if args.cases:
        requested = set(args.cases)
        fixtures = [fixture for fixture in fixtures if fixture["id"] in requested]
        missing = requested - {fixture["id"] for fixture in fixtures}
        if missing:
            raise SystemExit("unknown fixture id(s): " + ", ".join(sorted(missing)))

    results: list[dict[str, Any]] = []
    for index, fixture in enumerate(fixtures, start=1):
        print(
            f"[{index}/{len(fixtures)}] {fixture['id']}",
            file=sys.stderr,
            flush=True,
        )
        result = run_fixture(
            fixture,
            model=model,
            llama_cli=args.llama_cli,
            centl_sci=centl_sci,
            timeout=args.timeout,
        )
        results.append(result)
        verdict = "PASS" if result["pass"] else "FAIL"
        print(
            f"  {verdict} {result['elapsed_seconds']:.3f}s",
            file=sys.stderr,
            flush=True,
        )
        for mismatch in result["mismatches"]:
            print(f"    - {mismatch}", file=sys.stderr, flush=True)
        if not result["pass"]:
            stderr = str(result.get("stderr") or "").strip()
            if stderr:
                print("    centl-sci stderr:", file=sys.stderr, flush=True)
                for line in stderr.splitlines()[-12:]:
                    print(f"      {line}", file=sys.stderr, flush=True)

    passed = sum(1 for result in results if result["pass"])
    total = len(results)
    report = {
        "schema_version": 1,
        "sci_version": "0.0.1",
        "model": {
            "path": str(model),
            "label": args.model_label or model.name,
            "size_bytes": model.stat().st_size,
        },
        "runtime": {
            "centl_sci": str(centl_sci),
            "centl_sci_version": command_version(str(centl_sci)),
            "llama_cli": args.llama_cli,
            "llama_cli_version": command_version(args.llama_cli),
            "qualification_path": "forced model inference; deterministic fast path disabled",
            "note": (
                "elapsed_seconds includes process startup and model loading for each case; "
                "it is not an interpretation-only latency measurement"
            ),
        },
        "system": {
            "platform": platform.platform(),
            "machine": platform.machine(),
            "processor": platform.processor(),
            "python": platform.python_version(),
        },
        "corpus": str(corpus),
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "pass_rate": (passed / total) if total else 0.0,
            "total_elapsed_seconds": round(
                sum(result["elapsed_seconds"] for result in results), 6
            ),
        },
        "cases": results,
    }

    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        output = Path(args.output).expanduser()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
        print(f"report: {output}", file=sys.stderr)
    else:
        sys.stdout.write(rendered)

    print(
        f"CENTL-SCi corpus: {passed}/{total} passed "
        f"({report['summary']['pass_rate'] * 100:.1f}%)",
        file=sys.stderr,
    )
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
