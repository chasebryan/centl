#!/usr/bin/env python3
"""Public CENTL Oasis entry point.

The large execution core lives in oasis_engine.py. This front door owns policy
composition so mandatory repository-coherence gates cannot be skipped by the
normal command surface.
"""

from __future__ import annotations

from pathlib import Path
import sys

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import oasis_engine as _engine

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


def main(argv=None) -> int:
    return _engine.main(argv)


if __name__ == "__main__":
    raise SystemExit(main())
