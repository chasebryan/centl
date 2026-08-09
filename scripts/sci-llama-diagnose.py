#!/usr/bin/env python3
"""Isolate llama.cpp sampler/grammar failures for CENTL-SCi.

This script intentionally exercises the same local model with progressively
stronger constraints. It does not execute CENTL and does not judge model
quality. Its only purpose is to identify the first inference-runtime boundary
that fails before CENTL-SCi qualification is attempted.
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
    reasoning_off: bool


def load_sci_grammar(repo_root: pathlib.Path) -> str:
    source_path = repo_root / "src" / "ocaml" / "centl_sci_schema.ml"
    source = source_path.read_text(encoding="utf-8")
    match = re.search(r"let llama_grammar\s*=\s*\{\|(.*?)\|\}", source, re.DOTALL)
    if match is None:
        raise RuntimeError(f"could not locate llama_grammar in {source_path}")
    return match.group(1)


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
        "--no-display-prompt",
        "--no-show-timings",
        "--single-turn",
        "--color",
        "off",
        "--ctx-size",
        "4096",
        "--predict",
        "64",
        "--seed",
        "0",
        "--temp",
        "0",
    ]
    if probe.reasoning_off:
        argv.extend(["--reasoning", "off"])
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
        return {
            "name": probe.name,
            "ok": completed.returncode == 0,
            "exit_code": completed.returncode,
            "elapsed_seconds": round(elapsed, 3),
            "stdout": completed.stdout.strip(),
            "stderr": completed.stderr.strip(),
            "grammar": probe.grammar is not None,
            "reasoning_off": probe.reasoning_off,
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
            "grammar": probe.grammar is not None,
            "reasoning_off": probe.reasoning_off,
            "timeout": True,
        }


def tail(text: str, lines: int = 8) -> str:
    values = text.splitlines()
    return "\n".join(values[-lines:])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--llama-cli", default="llama-cli")
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--output", default="sci-llama-diagnostic.json")
    args = parser.parse_args()

    repo_root = pathlib.Path(__file__).resolve().parents[1]
    sci_grammar = load_sci_grammar(repo_root)

    json_string_grammar = r'''root ::= "{\"value\":\"" char* "\"}"
char ::= [^"\\\x7F\x00-\x1F] | [\\] (["\\bfnrt] | "u" [0-9a-fA-F]{4})'''

    probes = [
        Probe("baseline_default", "Return only the digit 4.", None, False),
        Probe("baseline_reasoning_off", "Return only the digit 4.", None, True),
        Probe("literal_grammar", "Return only the digit 4.", 'root ::= "4"', True),
        Probe(
            "literal_json_grammar",
            "Return exactly a JSON object whose ok field is true.",
            'root ::= "{\\\"ok\\\":true}"',
            True,
        ),
        Probe(
            "json_string_grammar",
            "Return a JSON object with a value string containing the digit 4.",
            json_string_grammar,
            True,
        ),
        Probe(
            "centl_sci_grammar",
            "Translate this problem to the supported CENTL-SCi IR: What is 0.1 plus 0.2?",
            sci_grammar,
            True,
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
            print(f"PASS {result['elapsed_seconds']}s | stdout={result['stdout']!r}", flush=True)
        else:
            if first_failure is None:
                first_failure = probe.name
            print(f"FAIL {result['elapsed_seconds']}s | exit={result['exit_code']}", flush=True)
            diagnostic = tail(str(result["stderr"]))
            if diagnostic:
                print(diagnostic, flush=True)

    report = {
        "purpose": "CENTL-SCi llama.cpp sampler/grammar isolation; not model-quality evaluation",
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
        print("All runtime grammar probes passed.")
        return 0
    print(f"First failing runtime boundary: {first_failure}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
