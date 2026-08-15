#!/usr/bin/env python3
"""Exact grade-rule checks. A wrong stamp is a kernel bug."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import json
import os
import tempfile
from pathlib import Path

from bberviges.findings import grade_of, load_catalog, save_catalog, tags_for_event


def check(event, expect_grade, cat=None):
    cat = cat or {"records": {"max_shift_k": 0}, "methods": []}
    tags = tags_for_event(event, cat)
    grade = grade_of(tags)
    if grade != expect_grade:
        raise SystemExit(f"expected {expect_grade} got {grade} tags={tags} event={event}")


def main() -> None:
    check(
        {"n": 1009, "solved": True, "layer": "theorem", "method": "4p+1", "kind": "linear"},
        None,
    )
    check(
        {
            "n": 2521,
            "solved": True,
            "layer": "window",
            "method": "fab(2,1)",
            "kind": "fab",
            "x": 1,
            "y": 2,
            "z": 3,
        },
        "great",
    )
    check(
        {"n": 2521, "solved": True, "layer": "search", "method": "corridor[23]", "kind": "II", "k": 23},
        "letter",
    )
    check({"n": 2521, "solved": False, "layer": "search"}, "letter")
    check(
        {"n": 1009, "solved": True, "layer": "theorem", "method": "corridor[11]", "kind": "both", "k": 11},
        "good",
    )
    check({"type": "cleared_bound", "bound": 20000, "unsolved": 0}, "great")

    from bberviges.letter_id import letter_id

    u = letter_id({"n": 2521, "solved": False}, ["unsolved_after_search"])
    v = letter_id({"p": 2521, "solved": False}, ["unsolved_after_search"])
    if u is None or v is None or u["number"] != v["number"]:
        raise SystemExit("letter numbers must be machine-independent")

    with tempfile.TemporaryDirectory() as tmp:
        os.environ["ES_FINDINGS"] = tmp
        empty = Path(tmp) / "catalog.json"
        empty.write_text("")
        cat = load_catalog(required=False)
        if cat.get("items") != []:
            raise SystemExit("empty catalog must not crash display load")
        save_catalog({"records": {"max_shift_k": 1, "max_cleared_bound": 0}, "methods": [], "items": []})
        cat = load_catalog(required=True)
        if cat["records"]["max_shift_k"] != 1:
            raise SystemExit("round-trip catalog failed")
        os.environ.pop("ES_FINDINGS", None)
    print("OK findings grades")


if __name__ == "__main__":
    main()
