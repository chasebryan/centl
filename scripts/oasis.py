#!/usr/bin/env python3
"""Public CENTL Oasis entry point.

The large execution core lives in oasis_engine.py. This front door owns policy
composition so mandatory repository-coherence and hosted-proof gates cannot be
skipped by the normal command surface.
"""

from __future__ import annotations

from pathlib import Path
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import oasis_engine as _engine
import oasis_required_checks as _required_checks

# Re-export the engine API so adversarial unit tests can exercise the public
# entry point rather than a private implementation file.
for _name in dir(_engine):
    if not _name.startswith("_"):
        globals()[_name] = getattr(_engine, _name)

_core_build_plan = _engine.build_plan


def build_plan(version: str, switch: str = "centl") -> list[Gate]:
    plan = _core_build_plan(version, switch)
    metadata = Gate(
        "metadata-coherence",
        "preflight",
        (
            sys.executable,
            "scripts/oasis-metadata-check.py",
            "--root",
            ".",
        ),
        60,
        "require source version, changelog, release notes, README, and Oasis status to agree",
    )
    # Runtime toolchain identity remains the first gate. Metadata is second and
    # still precedes every repair or source mutation.
    return [plan[0], metadata, *plan[1:]]


# main() resolves build_plan in the implementation module, so replace that
# reference with the policy-composed public plan before delegating.
_engine.build_plan = build_plan


def _root_from_argv(argv: list[str]) -> Path:
    root = Path.cwd()
    for index, item in enumerate(argv):
        if item == "--root" and index + 1 < len(argv):
            root = Path(argv[index + 1])
        elif item.startswith("--root="):
            root = Path(item.split("=", 1)[1])
    return root.resolve()


def main(argv=None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)

    # A final Oasis declaration requires positive evidence that the mandatory
    # hosted qualification checks exist and succeeded. Do this before the local
    # final engine so an empty, skipped, neutral, or still-running hosted check
    # set can never be mistaken for release proof. --plan remains side-effect
    # free and does not query GitHub.
    if "--final" in args and "--plan" not in args:
        try:
            head, failures = _required_checks.check(_root_from_argv(args))
        except _required_checks.HostedCheckError as exc:
            print(f"[oasis] PRECHECK FAILED: mandatory hosted checks: {exc}", file=sys.stderr)
            return 2
        if failures:
            for failure in failures:
                print(f"[oasis] PRECHECK FAILED: {failure}", file=sys.stderr)
            return 1
        print(f"[oasis] mandatory hosted checks successful for {head}")

    return _engine.main(args)


if __name__ == "__main__":
    raise SystemExit(main())
