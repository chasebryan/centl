#!/usr/bin/env python3
"""Deterministic product-interface checks for CENTL-SCi."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SCI = ROOT / "_build" / "default" / "src" / "sci_main.exe"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check CENTL-SCi human, details, JSON, and REPL interfaces."
    )
    parser.add_argument("--centl-sci", default=str(DEFAULT_SCI))
    parser.add_argument("--timeout", type=float, default=30.0)
    return parser.parse_args()


def run(
    executable: Path,
    arguments: list[str],
    *,
    input_text: str | None,
    timeout: float,
    env: dict[str, str],
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(executable), *arguments],
        cwd=ROOT,
        input=input_text,
        capture_output=True,
        text=True,
        check=False,
        timeout=timeout,
        env=env,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_clean(result: subprocess.CompletedProcess[str], expected: str) -> None:
    require(result.returncode == 0, f"unexpected exit {result.returncode}: {result.stderr}")
    require(result.stderr == "", f"unexpected stderr: {result.stderr!r}")
    require(result.stdout == expected, f"unexpected stdout: {result.stdout!r}")


def main() -> int:
    args = parse_args()
    executable = Path(args.centl_sci)
    if not executable.is_file():
        raise SystemExit(f"CENTL-SCi executable not found: {executable}")

    passed = 0
    with tempfile.TemporaryDirectory(prefix="centl-sci-interface-") as temporary:
        root = Path(temporary)
        env = os.environ.copy()
        env.pop("CENTL_SCI_MODEL", None)
        env.pop("CENTL_SCI_SERVER_URL", None)
        env["XDG_CONFIG_HOME"] = str(root / "config")
        env["XDG_STATE_HOME"] = str(root / "state")
        env["CENTL_WORKSPACE"] = str(root / "workspace")

        cases = [
            (["What is 0.1 plus 0.2?"], "3/10\n"),
            (
                ["Solve x squared minus 5x plus 6 equals zero."],
                "x = 2 or x = 3\n",
            ),
            (["Convert 2.5 kilometers to meters."], "2500 m\n"),
            (["What is 2 × 3?"], "6\n"),
            (["--mode", "math", "roots of x squared minus 5x plus 6"], "x = 2 or x = 3\n"),
            (["--mode", "physics", "change 2.5 kilometers into meters"], "2500 m\n"),
        ]
        for arguments, expected in cases:
            require_clean(
                run(
                    executable,
                    arguments,
                    input_text=None,
                    timeout=args.timeout,
                    env=env,
                ),
                expected,
            )
            passed += 1

        details = run(
            executable,
            ["--details", "Solve x squared minus 5x plus 6 equals zero."],
            input_text=None,
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            details,
            "x = 2 or x = 3\n\nDetails:\n"
            "  Exact result within the admitted deterministic model\n"
            "  Variable: x\n"
            "  Method: CENTL polynomial equation solving\n"
            "  Established by the authoritative CENTL execution path\n",
        )
        passed += 1

        explain = run(
            executable,
            ["--explain", "What is 0.1 plus 0.2?"],
            input_text=None,
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            explain,
            "3/10\n\n"
            "Explanation\n"
            "  Understood as:\n"
            "    What is 0.1 plus 0.2?\n"
            "  Mode:\n"
            "    hybrid\n"
            "  Intent:\n"
            "    arithmetic\n"
            "  Typed problem:\n"
            "    domain=mathematics, class=exact_expression, operation=compute\n"
            "  Interpreter assumptions:\n"
            "    none introduced\n"
            "  Interpretation path:\n"
            "    fast\n"
            "  Authoritative executor:\n"
            "    centl\n"
            "  Executor request:\n"
            '    {"version":1,"op":"compute","expression":"0.1 + 0.2","limits":{"max_source_bytes":8192,"max_expression_nodes":20000,"max_exact_bits":262144,"max_integer_iterations":10000,"max_result_bytes":262144,"max_precision_digits":256,"max_working_bits":4096}}\n'
            "  Status:\n"
            "    established\n"
            "  Workspace revision:\n"
            "    0\n"
            "  Evidence events:\n"
            "    - normalized: What is 0.1 plus 0.2?\n"
            "    - intent: arithmetic: calculation phrase\n"
            "    - typed_ir: mathematics/exact_expression/compute\n"
            "    - assumptions: none introduced by the interpreter\n"
            "    - routed: authoritative executor: centl\n"
            "    - executed: established\n"
            "  Result:\n"
            "    3/10\n",
        )
        passed += 1

        machine = run(
            executable,
            ["--json", "What is 0.1 plus 0.2?"],
            input_text=None,
            timeout=args.timeout,
            env=env,
        )
        require(machine.returncode == 0, f"JSON exit {machine.returncode}: {machine.stderr}")
        payload = json.loads(machine.stdout)
        require(payload.get("status") == "established", "JSON status changed")
        require(payload.get("interpreter_path") == "fast", "JSON route changed")
        response = payload.get("centl_response")
        require(isinstance(response, dict), "JSON CENTL evidence missing")
        value = response.get("value")
        require(isinstance(value, dict) and value.get("text") == "3/10", "JSON answer changed")
        passed += 1

        repl = run(
            executable,
            ["--repl", "--no-history"],
            input_text=(
                "What is 0.1 plus 0.2?\n"
                "Convert 2.5 kilometers to meters.\n"
                ":exit\n"
            ),
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            repl,
            "CENTL-SCi v0.0.2-Caramels+\n"
            "Free for science.\n\n"
            "HYBRID> 3/10\n"
            "HYBRID> 2500 m\n"
            "HYBRID> ",
        )
        passed += 1

        modes = run(
            executable,
            ["--repl", "--no-history"],
            input_text=(
                ":mode math\n"
                "What is 0.1 plus 0.2?\n"
                ":mode physics\n"
                "Convert 2.5 kilometers to meters.\n"
                ":mode hybrid\n"
                ":exit\n"
            ),
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            modes,
            "CENTL-SCi v0.0.2-Caramels+\n"
            "Free for science.\n\n"
            "HYBRID> Mode: math\n"
            "MATH> 3/10\n"
            "MATH> Mode: physics\n"
            "PHYS> 2500 m\n"
            "PHYS> Mode: hybrid\n"
            "HYBRID> ",
        )
        passed += 1

        recovery = run(
            executable,
            ["--repl", "--no-history"],
            input_text=(
                "This is not a supported scientific problem.\n"
                "What is 0.1 plus 0.2?\n"
                ":quit\n"
            ),
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            recovery,
            "CENTL-SCi v0.0.2-Caramels+\n"
            "Free for science.\n\n"
            "HYBRID> I understand this as a request that needs semantic interpretation, but no local semantic model is configured.\n"
            "HYBRID> 3/10\n"
            "HYBRID> ",
        )
        passed += 1

        clarification = run(
            executable,
            ["--repl", "--no-history"],
            input_text="solve x squared plus 4\n:quit\n",
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            clarification,
            "CENTL-SCi v0.0.2-Caramels+\n"
            "Free for science.\n\n"
            "HYBRID> I understand this as an equation-solving request, but the equation relation or right-hand side is missing. Try, for example: solve x squared plus 4 equals 0.\n"
            "HYBRID> ",
        )
        passed += 1

        eof = run(
            executable,
            ["--repl", "--no-history"],
            input_text="What is 0.1 plus 0.2?\n",
            timeout=args.timeout,
            env=env,
        )
        require_clean(
            eof,
            "CENTL-SCi v0.0.2-Caramels+\n"
            "Free for science.\n\n"
            "HYBRID> 3/10\n"
            "HYBRID> ",
        )
        passed += 1

        config_path = root / "config" / "centl-sci" / "contribution.json"
        pending_path = root / "state" / "centl-sci" / "contributions" / "pending.jsonl"
        require(not config_path.exists(), "REPL silently changed contribution mode")
        require(not pending_path.exists(), "REPL captured contribution data while mode was off")
        passed += 1

    print(f"CENTL-SCi interface checks: {passed} passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
