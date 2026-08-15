#!/usr/bin/env python3
"""Compact GREAT ledger and letters-only filing."""

from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from bberviges.findings import compact_library, file_event, findings_root, load_stats
from bberviges.seed import collect_label, collect_mode, default_seed
from bberviges.store import count_records, ledger_path


def check(cond, msg):
    if not cond:
        raise SystemExit(msg)


def main() -> None:
    tmp = tempfile.TemporaryDirectory()
    os.environ["ES_FINDINGS"] = tmp.name
    os.environ.pop("ES_LETTERS_ONLY", None)

    cleared = file_event({"type": "cleared_bound", "bound": 50_000, "unsolved": 0})
    check(cleared is None, "cleared_bound must not be a GREAT row")
    stats = load_stats()
    check(stats["max_cleared_bound"] == 50_000, f"bound not recorded: {stats}")
    check(count_records(findings_root(), "great") == 0, "cleared_bound leaked into ledger")

    rec = file_event(
        {
            "n": 2521,
            "solved": True,
            "layer": "window",
            "method": "fab(2,1)",
            "kind": "fab",
            "equation": "4/2521 = 1/1891 + 1/1891/3 + 1/…",
        }
    )
    check(rec is not None and rec["grade"] == "great", f"expected great, got {rec}")
    check(not list((findings_root() / "great").glob("*.md")), "great must not write a markdown pile")
    check(ledger_path(findings_root(), "great").is_file(), "great.jsonl missing")
    again = file_event(
        {
            "n": 2521,
            "solved": True,
            "layer": "window",
            "method": "fab(2,1)",
            "kind": "fab",
        }
    )
    check(again is None, "duplicate great must not be appended")
    check(count_records(findings_root(), "great") == 1, "duplicate inflated the ledger")

    os.environ["ES_LETTERS_ONLY"] = "1"
    skipped = file_event(
        {
            "n": 9601,
            "solved": True,
            "layer": "window",
            "method": "fab(1,2)",
            "kind": "fab",
        }
    )
    check(skipped is None, "letters-only must not file a GREAT")
    check(count_records(findings_root(), "great") == 1, "letters-only grew the ledger")
    os.environ.pop("ES_LETTERS_ONLY", None)

    letter = file_event({"n": 2521, "solved": False, "layer": "search"})
    check(letter is not None and letter["grade"] == "letter", f"expected letter, got {letter}")
    check((findings_root() / letter["file"]).is_file(), "letter file missing")

    # A leftover pair-file is folded by compact.
    leftover = findings_root() / "great" / "G-deadbeef.json"
    leftover.write_text(
        json.dumps(
            {
                "id": "G-deadbeefdeadbeefdeadbeefdeadbeef",
                "hex": "deadbeefdeadbeefdeadbeefdeadbeef",
                "number": 1,
                "grade": "great",
                "tags": ["escaped_small_theorems"],
                "event": {"n": 12721, "method": "fab(2,1)", "x": 1, "y": 2, "z": 3},
            }
        )
    )
    leftover.with_suffix(".md").write_text("stale")
    report = compact_library()
    check(not leftover.exists(), "compact left the pair-file")
    check(count_records(findings_root(), "great") == 1, "compact must not re-ingest the pile")
    check(report["removed_files"] >= 2, report)

    seed = default_seed()
    check(collect_mode(seed) == "all", seed)
    check("GOOD" in collect_label({"collect": "all"}), collect_label({"collect": "all"}))
    check(collect_mode({"collect": "letters"}) == "letters", "letters mode")
    os.environ.pop("ES_FINDINGS", None)
    print("OK compact store")


if __name__ == "__main__":
    main()
