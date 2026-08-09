#!/usr/bin/env python3
"""Isolate llama.cpp invocation failures for CENTL-SCi.

This script does not execute CENTL and does not judge model quality.  It probes
llama-cli with controlled differences so local developers can identify the
first runtime boundary that diverges from the production adapter.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
import time
from dataclasses import dataclass


@dataclass(frozen=True)
class Probe:
    name: str
    prompt: str
    grammar: str | None
    reasoning_off: bool = True
    log_disable: bool = False
    simple_io: bool = False
    predict: int = 64


def load_sci_grammar(repo_root: pathlib.Path) -> str:
    source_path = repo_root / "src" / "ocaml" / "centl_sci_schema.ml"
    source = source_path.read_text(encoding="utf-8")
    match = re.search(r"let llama_grammar\s*=\s*\{\|(.*?)\|\}", source, re.DOTALL)
    if match is None:
        raise RuntimeError(f"could not locate llama_grammar in {source_path}")
    return match.group(1)


def load_production_prompt(repo_root: pathlib.Path, problem: str) -> str:
    source_path = repo_root / "src" / "ocaml" / "centl_sci_llama.ml"
    source = source_path.read_text(encoding="utf-8")
    match = re.search(
        r"let prompt problem\s*=\s*\{\|(.*?)\|\}\s*\^\s*Yojson\.Safe\.to_string",
        source,
        re.DOTALL,
    )
    if match is None:
        raise RuntimeError(f"could not locate production prompt in {source_path}")
    return match.group(1) + json.dumps(problem, ensure_ascii=False)


def json_candidate(text: str) -> str | None:
    for line in reversed(text.splitlines()):
        candidate = line.strip()
        if not (candidate.startswith("{") and candidate.endswith("}")):
            continue
        try:
            value = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return candidate
    return None


def run_probe(
    probe: Probe,
    *,
    llama_cli: str,
    model: str,
    timeout: int,
) -> dict[str, object]:
    argv = [
        llama_cli,
        "-m",
        model,
        "--offline",
    ]
    if probe.log_disable:
        argv.append("--log-disable")
    argv.extend(
        [
            "--no-display-prompt",
            "--no-show-timings",
            "--single-turn",
        ]
    )
    if probe.simple_io:
        argv.append("--simple-io")
    if probe.reasoning_off:
        argv.extend(["--reasoning", "off"])
    argv.extend(
        [
            "--color",
            "off",
            "--ctx-size",
            "4096",
            "--predict",
            str(probe.predict),
            "--seed",
            "0",
            "--temp",
            "0",
        ]
    )
    if probe.grammar is not None:
        argv.extend(["--grammar", probe.grammar])
    argv.extend(["--prompt", probe.prompt])

    started = time.monotonic()
    try:
        completed = subprocess.run(
            argv,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        elapsed = time.monotonic() - started
        stdout = completed.stdout.strip()
        stderr = completed.stderr.strip()
        stdout_json = json_candidate(stdout)
        stderr_json = json_candidate(stderr)
        if stdout_json is not None:
            generated_stream = "stdout"
            generated_json = stdout_json
        elif stderr_json is not None:
            generated_stream = "stderr"
            generated_json = stderr_json
        else:
            generated_stream = "none"
            generated_json = None
        return {
            "name": probe.name,
            "ok": completed.returncode == 0,
            "exit_code": completed.returncode,
            "elapsed_seconds": round(elapsed, 3),
            "stdout": stdout,
            "stderr": stderr,
            "generated_stream": generated_stream,
            "generated_json": generated_json,
            "grammar": probe.grammar is not None,
            "reasoning_off": probe.reasoning_off,
            "log_disable": probe.log_disable,
            "simple_io": probe.simple_io,
            "predict": probe.predict,
        }
    except subprocess.TimeoutExpired as error:
        elapsed = time.monotonic() - started
        stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or "")
        stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or "")
        return {
            "name": probe.name,
            "ok": False,
            "exit_code": None,
            "elapsed_seconds": round(elapsed, 3),
            "stdout": stdout.strip(),
            "stderr": stderr.strip(),
            "generated_stream": "none",
            "generated_json": None,
            "grammar": probe.grammar is not None,
            "reasoning_off": probe.reasoning_off,
            "log_disable": probe.log_disable,
            "simple_io": probe.simple_io,
            "predict": probe.predict,
            "timeout": True,
        }


def tail(text: str, lines: int = 8) -> str:
    values = text.splitlines()
    return "\n".join(values[-lines:])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--llama-cli", default="llama-cli")
    parser.add_argument("--timeout", type=int, default=90)
    parser.add_argument("--output", default="sci-llama-diagnostic.json")
    args = parser.parse_args()

    repo_root = pathlib.Path(__file__).resolve().parents[1]
    sci_grammar = load_sci_grammar(repo_root)
    problem = "What is 0.1 plus 0.2?"
    production_prompt = load_production_prompt(repo_root, problem)
    short_prompt = (
        "Translate this problem to the supported CENTL-SCi IR: "
        "What is 0.1 plus 0.2?"
    )

    # Stage two intentionally varies only production-invocation details.  The
    # earlier grammar ladder established on real hardware that the model,
    # reasoning-off mode, JSON strings, and the complete SCi grammar all load.
    probes = [
        Probe(
            "grammar_plus_log_disable",
            short_prompt,
            sci_grammar,
            log_disable=True,
        ),
        Probe(
            "grammar_predict_512",
            short_prompt,
            sci_grammar,
            predict=512,
        ),
        Probe(
            "production_prompt",
            production_prompt,
            sci_grammar,
            predict=512,
        ),
        Probe(
            "production_prompt_simple_io",
            production_prompt,
            sci_grammar,
            simple_io=True,
            predict=512,
        ),
        Probe(
            "production_exact_flags",
            production_prompt,
            sci_grammar,
            log_disable=True,
            predict=512,
        ),
        Probe(
            "production_log_disable_simple_io",
            production_prompt,
            sci_grammar,
            log_disable=True,
            simple_io=True,
            predict=512,
        ),
    ]

    results: list[dict[str, object]] = []
    first_failure: str | None = None
    for index, probe in enumerate(probes, start=1):
        print(f"[{index}/{len(probes)}] {probe.name}", flush=True)
        result = run_probe(
            probe,
            llama_cli=args.llama_cli,
            model=args.model,
            timeout=args.timeout,
        )
        results.append(result)
        if bool(result["ok"]):
            print(
                f"PASS {result['elapsed_seconds']}s | "
                f"generated_stream={result['generated_stream']} | "
                f"json={result['generated_json']!r}",
                flush=True,
            )
        else:
            if first_failure is None:
                first_failure = probe.name
            print(
                f"FAIL {result['elapsed_seconds']}s | exit={result['exit_code']} | "
                f"generated_stream={result['generated_stream']}",
                flush=True,
            )
            diagnostic = tail(str(result["stderr"]))
            if diagnostic:
                print(diagnostic, flush=True)

    report = {
        "purpose": "CENTL-SCi llama.cpp production-invocation isolation; not model-quality evaluation",
        "model": str(pathlib.Path(args.model).expanduser().resolve()),
        "llama_cli": args.llama_cli,
        "first_failure": first_failure,
        "results": results,
    }
    pathlib.Path(args.output).write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"report: {args.output}")
    if first_failure is None:
        print("All production-invocation probes passed.")
        return 0
    print(f"First failing production boundary: {first_failure}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
