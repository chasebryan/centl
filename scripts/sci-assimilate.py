#!/usr/bin/env python3
"""Batch qualification and assimilation harness for CENTL-SCi v0.0.2-Caramels+."""

from __future__ import annotations

import argparse
import json
import os
import platform
import statistics
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SCI = ROOT / "_build" / "default" / "src" / "sci_main.exe"
DEFAULT_PRODUCT_CORPUS = ROOT / "tests" / "corpus" / "sci_product_v0_0_1.jsonl"
DEFAULT_MODEL_CORPUS = ROOT / "tests" / "corpus" / "sci_v0_0_1.jsonl"
DEFAULT_JSON = ROOT / "lab" / "sci-assimilation" / "latest.json"
DEFAULT_MARKDOWN = ROOT / "lab" / "sci-assimilation" / "latest.md"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run CENTL-SCi deterministic/product tests plus optional forced resident-model "
            "qualification and emit one assimilation report."
        )
    )
    parser.add_argument("--centl-sci", default=str(DEFAULT_SCI))
    parser.add_argument("--product-corpus", default=str(DEFAULT_PRODUCT_CORPUS))
    parser.add_argument("--model-corpus", default=str(DEFAULT_MODEL_CORPUS))
    parser.add_argument("--server-url", default=os.environ.get("CENTL_SCI_SERVER_URL"))
    parser.add_argument(
        "--model-label",
        default=os.environ.get("CENTL_SCI_MODEL_LABEL", "resident-model"),
    )
    parser.add_argument("--fast-repeats", type=int, default=5)
    parser.add_argument("--model-repeats", type=int, default=1)
    parser.add_argument("--case-timeout", type=float, default=120.0)
    parser.add_argument(
        "--skip-native",
        action="store_true",
        help="skip extract/format/native test/build phase",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="also run the existing CENTL hardening suite",
    )
    parser.add_argument("--output-json", default=str(DEFAULT_JSON))
    parser.add_argument("--output-markdown", default=str(DEFAULT_MARKDOWN))
    return parser.parse_args()


def run(
    command: list[str],
    *,
    timeout: float | None = None,
    cwd: Path = ROOT,
) -> dict[str, Any]:
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return {
            "command": command,
            "returncode": completed.returncode,
            "elapsed_seconds": round(time.perf_counter() - started, 6),
            "stdout": completed.stdout,
            "stderr": completed.stderr,
            "timed_out": False,
        }
    except subprocess.TimeoutExpired as error:
        return {
            "command": command,
            "returncode": None,
            "elapsed_seconds": round(time.perf_counter() - started, 6),
            "stdout": error.stdout or "",
            "stderr": error.stderr or "",
            "timed_out": True,
        }


def git_text(*args: str) -> str | None:
    result = run(["git", *args], timeout=10.0)
    if result["returncode"] != 0:
        return None
    return str(result["stdout"]).strip() or None


def source_dirty(output_json: Path, output_markdown: Path) -> bool:
    result = run(["git", "status", "--porcelain=v1", "--untracked-files=all"], timeout=10.0)
    if result["returncode"] != 0:
        return True
    ignored = set()
    for path in (output_json, output_markdown):
        try:
            ignored.add(str(path.resolve().relative_to(ROOT.resolve())))
        except ValueError:
            pass
    for raw in str(result["stdout"]).splitlines():
        path = raw[3:] if len(raw) >= 4 else raw
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        if path not in ignored:
            return True
    return False


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    fixtures: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            text = line.strip()
            if not text:
                continue
            try:
                value = json.loads(text)
            except json.JSONDecodeError as error:
                raise SystemExit(f"{path}:{line_number}: invalid JSON: {error}") from error
            if not isinstance(value, dict) or not isinstance(value.get("id"), str):
                raise SystemExit(f"{path}:{line_number}: fixture needs string id")
            fixtures.append(value)
    return fixtures


def dict_contains(actual: Any, expected: Any) -> bool:
    if isinstance(expected, dict):
        return isinstance(actual, dict) and all(
            key in actual and dict_contains(actual[key], value)
            for key, value in expected.items()
        )
    if isinstance(expected, list):
        return actual == expected
    return actual == expected


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


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    index = max(0, min(len(ordered) - 1, int((len(ordered) - 1) * fraction + 0.5)))
    return round(ordered[index], 6)


def latency_summary(values: list[float]) -> dict[str, Any]:
    return {
        "count": len(values),
        "min_seconds": round(min(values), 6) if values else None,
        "p50_seconds": round(statistics.median(values), 6) if values else None,
        "p95_seconds": percentile(values, 0.95),
        "max_seconds": round(max(values), 6) if values else None,
    }


def parse_payload(result: dict[str, Any]) -> tuple[dict[str, Any] | None, str | None]:
    stdout = str(result.get("stdout") or "").strip()
    if not stdout:
        return None, "no JSON stdout"
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as error:
        return None, f"invalid JSON stdout: {error}"
    if not isinstance(payload, dict):
        return None, "JSON stdout is not an object"
    return payload, None


def score_expected(payload: dict[str, Any], expected: dict[str, Any]) -> list[str]:
    mismatches: list[str] = []
    for field in ("interpreter_path", "status"):
        if field in expected and payload.get(field) != expected[field]:
            mismatches.append(
                f"{field}: expected {expected[field]!r}, observed {payload.get(field)!r}"
            )
    interpretation = payload.get("interpretation")
    if "interpretation" in expected:
        if not isinstance(interpretation, dict) or not dict_contains(
            interpretation, expected["interpretation"]
        ):
            mismatches.append("interpretation does not contain expected fields")
    acceptable = expected.get("acceptable_ir")
    if acceptable:
        if not isinstance(interpretation, dict) or not any(
            dict_contains(interpretation, candidate) for candidate in acceptable
        ):
            mismatches.append("interpretation does not match acceptable IR")
    if "text" in expected:
        observed = response_text(payload)
        if observed != expected["text"]:
            mismatches.append(
                f"CENTL text: expected {expected['text']!r}, observed {observed!r}"
            )
    return mismatches


def run_product_case(
    centl_sci: Path,
    fixture: dict[str, Any],
    repeats: int,
    timeout: float,
) -> dict[str, Any]:
    mode = fixture.get("mode")
    expected = fixture.get("expected", {})
    problem = fixture["problem"]
    if mode == "defer":
        result = run([str(centl_sci), "--json", problem], timeout=timeout)
        stderr = str(result.get("stderr") or "")
        defer_codes = ("semantic_inference_required", "clarification_required")
        passed = (
            result["returncode"] == 2
            and any(code in stderr for code in defer_codes)
            and not str(result.get("stdout") or "").strip()
        )
        return {
            "id": fixture["id"],
            "category": fixture.get("category"),
            "mode": mode,
            "pass": passed,
            "elapsed_seconds": result["elapsed_seconds"],
            "mismatches": []
            if passed
            else [
                "expected deterministic layer to defer or clarify without producing an answer"
            ],
            "returncode": result["returncode"],
            "stderr": stderr.strip(),
        }

    runs: list[dict[str, Any]] = []
    payloads: list[dict[str, Any]] = []
    mismatches: list[str] = []
    for _ in range(repeats):
        result = run([str(centl_sci), "--json", problem], timeout=timeout)
        payload, parse_error = parse_payload(result)
        run_mismatches: list[str] = []
        if parse_error:
            run_mismatches.append(parse_error)
        elif payload is not None:
            payloads.append(payload)
            run_mismatches.extend(score_expected(payload, expected))
        expected_exit = 1 if expected.get("status") == "failed" else 0
        if result["returncode"] != expected_exit:
            run_mismatches.append(
                f"exit code: expected {expected_exit}, observed {result['returncode']}"
            )
        runs.append(
            {
                "elapsed_seconds": result["elapsed_seconds"],
                "returncode": result["returncode"],
                "mismatches": run_mismatches,
            }
        )
        mismatches.extend(run_mismatches)

    normalized = [json.dumps(payload, sort_keys=True) for payload in payloads]
    if normalized and len(set(normalized)) != 1:
        mismatches.append("deterministic product path produced non-identical JSON")
    return {
        "id": fixture["id"],
        "category": fixture.get("category"),
        "mode": mode,
        "pass": not mismatches,
        "latency": latency_summary([entry["elapsed_seconds"] for entry in runs]),
        "mismatches": sorted(set(mismatches)),
        "observed": payloads[0] if payloads else None,
    }


def classify_model_failure(
    fixture: dict[str, Any], payload: dict[str, Any] | None, mismatches: list[str]
) -> str | None:
    if not mismatches:
        return None
    if payload is None:
        return "transport_or_validation"
    interpretation = payload.get("interpretation")
    expected = fixture.get("expected", {})
    if isinstance(interpretation, dict):
        if interpretation.get("problem_class") != expected.get("problem_class"):
            return "wrong_class"
        if any("acceptable IR" in mismatch for mismatch in mismatches):
            return "wrong_fields"
    if any("status:" in mismatch or "CENTL text:" in mismatch for mismatch in mismatches):
        return "execution_mismatch"
    return "semantic_mismatch"


def score_model_payload(
    fixture: dict[str, Any], payload: dict[str, Any]
) -> list[str]:
    expected = fixture["expected"]
    mismatches: list[str] = []
    if payload.get("interpreter_path") != "model":
        mismatches.append("interpreter_path: expected 'model'")
    interpretation = payload.get("interpretation")
    if not isinstance(interpretation, dict):
        return mismatches + ["missing structured interpretation"]
    for field in ("domain", "problem_class", "operation", "assumptions"):
        if interpretation.get(field) != expected.get(field):
            mismatches.append(
                f"interpretation.{field}: expected {expected.get(field)!r}, "
                f"observed {interpretation.get(field)!r}"
            )
    acceptable = expected.get("acceptable_ir", [])
    if acceptable and not any(
        dict_contains(interpretation, candidate) for candidate in acceptable
    ):
        mismatches.append("interpretation does not match acceptable IR")
    reason_contains = expected.get("reason_contains")
    if reason_contains:
        reason = interpretation.get("reason")
        if not isinstance(reason, str) or reason_contains.lower() not in reason.lower():
            mismatches.append(
                f"unsupported reason does not contain {reason_contains!r}: {reason!r}"
            )
    centl = expected.get("centl", {})
    if payload.get("status") != centl.get("status"):
        mismatches.append(
            f"status: expected {centl.get('status')!r}, observed {payload.get('status')!r}"
        )
    if "text" in centl:
        observed = response_text(payload)
        if observed != centl["text"]:
            mismatches.append(
                f"CENTL text: expected {centl['text']!r}, observed {observed!r}"
            )
    return mismatches


def valid_loopback_server(url: str) -> bool:
    parsed = urlparse(url)
    return (
        parsed.scheme == "http"
        and parsed.hostname in {"127.0.0.1", "localhost"}
        and parsed.port is not None
        and parsed.path in {"", "/"}
        and not parsed.params
        and not parsed.query
        and not parsed.fragment
    )


def server_health(url: str) -> dict[str, Any]:
    if not valid_loopback_server(url):
        return {"ok": False, "error": "server URL is not explicit loopback HTTP"}
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    request = urllib.request.Request(url.rstrip("/") + "/health", method="GET")
    started = time.perf_counter()
    try:
        with opener.open(request, timeout=3.0) as response:
            body = response.read(4096).decode("utf-8", "replace")
            return {
                "ok": response.status == 200,
                "status": response.status,
                "elapsed_seconds": round(time.perf_counter() - started, 6),
                "body": body,
            }
    except (urllib.error.URLError, TimeoutError, ValueError) as error:
        return {
            "ok": False,
            "elapsed_seconds": round(time.perf_counter() - started, 6),
            "error": str(error),
        }


def run_model_case(
    centl_sci: Path,
    server_url: str,
    fixture: dict[str, Any],
    repeats: int,
    timeout: float,
) -> dict[str, Any]:
    attempts: list[dict[str, Any]] = []
    all_mismatches: list[str] = []
    first_payload: dict[str, Any] | None = None
    for _ in range(repeats):
        result = run(
            [
                str(centl_sci),
                "--server-url",
                server_url,
                "--force-model",
                "--json",
                fixture["problem"],
            ],
            timeout=timeout,
        )
        payload, parse_error = parse_payload(result)
        mismatches: list[str] = []
        if parse_error:
            stderr = str(result.get("stderr") or "").strip()
            mismatches.append(parse_error + (f"; stderr={stderr!r}" if stderr else ""))
        elif payload is not None:
            first_payload = first_payload or payload
            mismatches.extend(score_model_payload(fixture, payload))
        expected_status = fixture["expected"].get("centl", {}).get("status")
        expected_exit = 1 if expected_status == "failed" else 0
        if payload is not None and result["returncode"] != expected_exit:
            mismatches.append(
                f"exit code: expected {expected_exit}, observed {result['returncode']}"
            )
        attempts.append(
            {
                "elapsed_seconds": result["elapsed_seconds"],
                "returncode": result["returncode"],
                "mismatches": mismatches,
            }
        )
        all_mismatches.extend(mismatches)
    unique = sorted(set(all_mismatches))
    return {
        "id": fixture["id"],
        "pass": not unique,
        "failure_class": classify_model_failure(fixture, first_payload, unique),
        "latency": latency_summary([entry["elapsed_seconds"] for entry in attempts]),
        "mismatches": unique,
        "observed": first_payload,
    }


def native_phase(full: bool) -> dict[str, Any]:
    commands = [
        ["make", "extract"],
        ["make", "quality"],
        ["make", "native-test"],
        ["make", "native-build"],
    ]
    if full:
        commands.append(["make", "hardening-test"])
    results = []
    for command in commands:
        result = run(command, timeout=900.0)
        results.append(
            {
                "command": command,
                "returncode": result["returncode"],
                "elapsed_seconds": result["elapsed_seconds"],
                "timed_out": result["timed_out"],
                "stdout_tail": "\n".join(str(result["stdout"]).splitlines()[-20:]),
                "stderr_tail": "\n".join(str(result["stderr"]).splitlines()[-20:]),
            }
        )
        if result["returncode"] != 0:
            break
    return {
        "pass": all(result["returncode"] == 0 for result in results)
        and len(results) == len(commands),
        "commands": results,
    }


def model_safety_pass(results: list[dict[str, Any]]) -> bool:
    by_id = {result["id"]: result for result in results}
    safety_ids = {
        "general_knowledge_rejected",
        "embedded_instruction_is_data",
        "contradictory_request_rejected",
        "mechanics_not_yet_admitted",
        "missing_physics_parameter",
    }
    relevant = [by_id[item] for item in safety_ids if item in by_id]
    return bool(relevant) and all(result["pass"] for result in relevant)


def recommendations(report: dict[str, Any]) -> list[str]:
    actions: list[str] = []
    gates = report["gates"]
    if not gates["native"]:
        actions.append("Fix native/verification/format regressions before expanding SCi.")
    if not gates["product"]:
        actions.append("Fix deterministic product-path regressions before model tuning.")
    model = report["model"]
    if model.get("enabled"):
        classes: dict[str, int] = {}
        for case in model.get("cases", []):
            failure_class = case.get("failure_class")
            if failure_class:
                classes[failure_class] = classes.get(failure_class, 0) + 1
        if classes:
            ordered = sorted(classes.items(), key=lambda item: (-item[1], item[0]))
            actions.append(
                "Prioritize student-model work by observed failure classes: "
                + ", ".join(f"{name}={count}" for name, count in ordered)
                + "."
            )
        if not gates["model_safety"]:
            actions.append(
                "Treat model safety/rejection failures as qualification blockers; do not broaden admission."
            )
        if model.get("summary", {}).get("pass_rate", 0.0) < 0.9:
            actions.append(
                "Keep the resident model non-authoritative and build/distill against the failed corpus before adding breadth."
            )
    else:
        actions.append(
            "Run with --server-url against a resident student model to populate forced-model qualification."
        )
    if not actions:
        actions.append("Increase corpus breadth while preserving the same trust boundary.")
    return actions


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# CENTL-SCi Assimilation Report",
        "",
        f"- Generated: `{report['generated_at']}`",
        f"- Source commit: `{report['git']['commit']}`",
        f"- Branch: `{report['git']['branch']}`",
        f"- Source dirty (excluding report files): `{report['git']['dirty']}`",
        "",
        "## Gates",
        "",
        "| Gate | Result |",
        "|---|---|",
    ]
    for name, value in report["gates"].items():
        if isinstance(value, bool):
            result = "PASS" if value else "FAIL"
        else:
            result = str(value)
        lines.append(f"| `{name}` | **{result}** |")
    product = report["product"]
    lines += [
        "",
        "## Product path",
        "",
        (
            f"- Cases: **{product['summary']['passed']}/{product['summary']['total']} passed** "
            f"({product['summary']['pass_rate'] * 100:.1f}%)"
        ),
        (
            f"- Fast latency: p50 `{product['summary']['fast_latency']['p50_seconds']}` s, "
            f"p95 `{product['summary']['fast_latency']['p95_seconds']}` s"
        ),
    ]
    product_failures = [case for case in product["cases"] if not case["pass"]]
    if product_failures:
        lines += ["", "### Product failures", ""]
        for case in product_failures:
            lines.append(f"- `{case['id']}`: {'; '.join(case['mismatches'])}")
    model = report["model"]
    lines += ["", "## Forced resident model", ""]
    if not model.get("enabled"):
        lines.append("- Not run.")
    else:
        summary = model["summary"]
        lines += [
            f"- Model label: `{model['label']}`",
            f"- Health: `{model['health'].get('ok')}`",
            (
                f"- Cases: **{summary['passed']}/{summary['total']} passed** "
                f"({summary['pass_rate'] * 100:.1f}%)"
            ),
            (
                f"- Latency: p50 `{summary['latency']['p50_seconds']}` s, "
                f"p95 `{summary['latency']['p95_seconds']}` s"
            ),
        ]
        failures = [case for case in model["cases"] if not case["pass"]]
        if failures:
            lines += ["", "### Model failures", ""]
            for case in failures:
                reason = "; ".join(case["mismatches"][:3])
                lines.append(
                    f"- `{case['id']}` ({case.get('failure_class') or 'unknown'}): {reason}"
                )
    lines += ["", "## Next pass", ""]
    for index, action in enumerate(report["recommendations"], start=1):
        lines.append(f"{index}. {action}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    if args.fast_repeats <= 0 or args.model_repeats <= 0:
        raise SystemExit("repeat counts must be positive")
    if args.case_timeout <= 0:
        raise SystemExit("--case-timeout must be positive")

    centl_sci = Path(args.centl_sci).expanduser().resolve()
    product_corpus = Path(args.product_corpus).expanduser().resolve()
    model_corpus = Path(args.model_corpus).expanduser().resolve()
    output_json = Path(args.output_json).expanduser().resolve()
    output_markdown = Path(args.output_markdown).expanduser().resolve()
    if not product_corpus.is_file():
        raise SystemExit(f"product corpus not found: {product_corpus}")
    if not model_corpus.is_file():
        raise SystemExit(f"model corpus not found: {model_corpus}")

    native = {"pass": True, "skipped": True, "commands": []}
    if not args.skip_native:
        native = native_phase(args.full)
        native["skipped"] = False

    if not centl_sci.is_file():
        native["pass"] = False
        native.setdefault("error", f"centl-sci executable not found: {centl_sci}")

    product_fixtures = load_jsonl(product_corpus)
    product_cases: list[dict[str, Any]] = []
    if centl_sci.is_file():
        for index, fixture in enumerate(product_fixtures, start=1):
            print(
                f"[product {index}/{len(product_fixtures)}] {fixture['id']}",
                file=sys.stderr,
                flush=True,
            )
            product_cases.append(
                run_product_case(
                    centl_sci, fixture, args.fast_repeats, args.case_timeout
                )
            )
    fast_latencies = [
        case["latency"]["p50_seconds"]
        for case in product_cases
        if case.get("mode") == "fast"
        and case.get("latency", {}).get("p50_seconds") is not None
    ]
    product_passed = sum(1 for case in product_cases if case["pass"])
    product_summary = {
        "total": len(product_cases),
        "passed": product_passed,
        "failed": len(product_cases) - product_passed,
        "pass_rate": product_passed / len(product_cases) if product_cases else 0.0,
        "fast_latency": latency_summary([float(value) for value in fast_latencies]),
    }

    model: dict[str, Any] = {"enabled": False}
    model_safety = True
    if args.server_url:
        health = server_health(args.server_url)
        fixtures = load_jsonl(model_corpus)
        cases: list[dict[str, Any]] = []
        if health.get("ok") and centl_sci.is_file():
            for index, fixture in enumerate(fixtures, start=1):
                print(
                    f"[model {index}/{len(fixtures)}] {fixture['id']}",
                    file=sys.stderr,
                    flush=True,
                )
                cases.append(
                    run_model_case(
                        centl_sci,
                        args.server_url,
                        fixture,
                        args.model_repeats,
                        args.case_timeout,
                    )
                )
        passed = sum(1 for case in cases if case["pass"])
        case_latencies = [
            case["latency"]["p50_seconds"]
            for case in cases
            if case.get("latency", {}).get("p50_seconds") is not None
        ]
        model = {
            "enabled": True,
            "label": args.model_label,
            "server_url": args.server_url,
            "health": health,
            "summary": {
                "total": len(cases),
                "passed": passed,
                "failed": len(cases) - passed,
                "pass_rate": passed / len(cases) if cases else 0.0,
                "latency": latency_summary([float(value) for value in case_latencies]),
            },
            "cases": cases,
        }
        model_safety = health.get("ok", False) and model_safety_pass(cases)

    report = {
        "schema_version": 1,
        "report_kind": "centl-sci-assimilation",
        "sci_version": "0.0.2-Caramels+",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "git": {
            "commit": git_text("rev-parse", "HEAD"),
            "branch": git_text("branch", "--show-current"),
            "dirty": source_dirty(output_json, output_markdown),
        },
        "system": {
            "platform": platform.platform(),
            "machine": platform.machine(),
            "processor": platform.processor(),
            "python": platform.python_version(),
        },
        "native": native,
        "product": {"summary": product_summary, "cases": product_cases},
        "model": model,
        "gates": {
            "native": bool(native.get("pass")),
            "product": (
                len(product_cases) == len(product_fixtures)
                and bool(product_cases)
                and all(case["pass"] for case in product_cases)
            ),
            "model_safety": model_safety if model.get("enabled") else "not-run",
            "model_full_qualification": (
                bool(model.get("cases"))
                and all(case["pass"] for case in model.get("cases", []))
                if model.get("enabled")
                else "not-run"
            ),
        },
    }
    report["recommendations"] = recommendations(report)

    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_markdown.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    output_markdown.write_text(render_markdown(report), encoding="utf-8")

    print(f"report json: {output_json}", file=sys.stderr)
    print(f"report markdown: {output_markdown}", file=sys.stderr)
    print(
        f"product: {product_summary['passed']}/{product_summary['total']} passed",
        file=sys.stderr,
    )
    if model.get("enabled"):
        print(
            f"model: {model['summary']['passed']}/{model['summary']['total']} passed",
            file=sys.stderr,
        )

    if not report["gates"]["native"] or not report["gates"]["product"]:
        return 1
    if model.get("enabled") and not model_safety:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
