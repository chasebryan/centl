#!/usr/bin/env python3
"""Finite exact constraint propagator for the realized h169 pair-route grammar.

This tool composes only theorem rules already landed in the research tree.  It
operates on the symbolic survivor laboratory, not on arbitrary Erdős–Straus
inputs, and it never treats BEC/BREC annotations as proof data.
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from itertools import product
from typing import Callable, Iterable

S19 = (0, 2, 7, 8, 11, 14, 15, 16, 17)
S31 = (0, 2, 6, 7, 8, 9, 11, 12, 14, 15, 19, 22, 27, 28, 29)
BARE31_PHASES = frozenset({0, 19, 29})
M19 = ("BARE", "FULL_QR")
K27 = ("Q", "A", "B", "C", "D", "E", "F")
M31 = ("BARE", "FULL_QR")
K35 = ("J_ONLY", "S7_ONLY", "BOTH")
M47 = ("THIN", "FULL_QR")

FIELDS = (
    "tau19",
    "tau31",
    "tau4",
    "tau9",
    "k19_mode",
    "k27_mode",
    "k31_mode",
    "k35_status",
    "k47_mode",
)


@dataclass(frozen=True)
class State:
    tau19: int
    tau31: int
    tau4: int
    tau9: int
    k19_mode: str
    k27_mode: str
    k31_mode: str
    k35_status: str
    k47_mode: str

    def as_dict(self) -> dict[str, object]:
        return {field: getattr(self, field) for field in FIELDS}


@dataclass(frozen=True)
class Rule:
    name: str
    statement: str
    predicate: Callable[[str, State], bool]
    bec_candidate: str = "↓(⊖/⊕)"


def rule_k19_bare_phase(route: str, s: State) -> bool:
    if s.k19_mode != "BARE":
        return True
    return s.tau19 == (2 if route == "A" else 8)


def rule_k27_phase8_selector(_route: str, s: State) -> bool:
    return s.tau19 != 8 or s.k27_mode == "Q"


def rule_k31_bare_phase(_route: str, s: State) -> bool:
    if s.k31_mode != "BARE":
        return True
    return s.tau31 in BARE31_PHASES and s.tau4 % 2 == 0


def rule_route_b_k47_thin_even(route: str, s: State) -> bool:
    if route != "B" or s.k47_mode != "THIN":
        return True
    return s.tau4 % 2 == 0


def rule_route_b_odd_full(route: str, s: State) -> bool:
    if route != "B" or s.tau4 % 2 == 0:
        return True
    return s.k31_mode == "FULL_QR" and s.k47_mode == "FULL_QR"


def rule_k35_phase4(_route: str, s: State) -> bool:
    return s.tau9 != 4 or s.k35_status == "J_ONLY"


RULES = (
    Rule(
        "k19-bare-phase",
        "Route-A BARE requires tau19=2; Route-B BARE requires tau19=8.",
        rule_k19_bare_phase,
    ),
    Rule(
        "k27-phase8-q-selector",
        "tau19=8 forces 19|E, so a k27 miss has NR mode Q and QR27 support.",
        rule_k27_phase8_selector,
    ),
    Rule(
        "k31-bare-phase-seam",
        "k31 BARE requires tau31 in {0,19,29} and even tau4.",
        rule_k31_bare_phase,
    ),
    Rule(
        "route-b-k47-thin-even",
        "On Route B, k47 THIN excludes factor 2 and therefore requires even tau4.",
        rule_route_b_k47_thin_even,
    ),
    Rule(
        "route-b-odd-full-full",
        "On Route B, odd tau4 gives the D-J gcd2 seam and forces FULL_QR at k31 and k47.",
        rule_route_b_odd_full,
    ),
    Rule(
        "k35-v3-ge2-j-only",
        "tau9=4 gives 9|F, excludes S7, and forces J_ONLY on a k35 miss.",
        rule_k35_phase4,
    ),
)


def naive_states(route: str) -> Iterable[State]:
    k47_values = ("NA",) if route == "A" else M47
    for row in product(S19, S31, range(4), range(9), M19, K27, M31, K35, k47_values):
        yield State(*row)


def normalize_constraint(field: str, value: object) -> frozenset[object]:
    if isinstance(value, list):
        return frozenset(value)
    return frozenset({value})


def parse_constraints(raw: dict[str, object]) -> dict[str, frozenset[object]]:
    unknown = set(raw) - set(FIELDS)
    if unknown:
        raise ValueError(f"unknown state fields: {sorted(unknown)}")
    return {field: normalize_constraint(field, value) for field, value in raw.items()}


def matches_constraints(s: State, constraints: dict[str, frozenset[object]]) -> bool:
    return all(getattr(s, field) in allowed for field, allowed in constraints.items())


def seam_from_tau4(tau4: int) -> str:
    if tau4 == 0:
        return "EVEN_0"
    if tau4 == 2:
        return "EVEN_2"
    return "ODD"


def v3_bucket(tau9: int) -> str:
    if tau9 == 4:
        return "GE2"
    if tau9 in {1, 7}:
        return "EQ1"
    return "ZERO"


def project(states: list[State]) -> dict[str, list[object]]:
    return {
        field: sorted({getattr(s, field) for s in states}, key=lambda x: (str(type(x)), str(x)))
        for field in FIELDS
    }


def derived_projection(states: list[State]) -> dict[str, object]:
    tau4 = {s.tau4 for s in states}
    tau9 = {s.tau9 for s in states}
    return {
        "parity": sorted({"EVEN" if x % 2 == 0 else "ODD" for x in tau4}),
        "support_seam": sorted({seam_from_tau4(x) for x in tau4}),
        "k35_v3_bucket": sorted({v3_bucket(x) for x in tau9}),
        "gcd_D_J": sorted({1 if x % 2 == 0 else 2 for x in tau4}),
    }


def support_consequences(route: str, states: list[State]) -> list[str]:
    if not states:
        return []
    out = [
        "scope: realized h169 pair-route simultaneous survivor grammar",
        "k23 miss coordinate: every prime factor of B is QR mod23",
        "k31 miss coordinate: every prime factor of D is QR mod31",
    ]
    k19_modes = {s.k19_mode for s in states}
    k27_modes = {s.k27_mode for s in states}
    k31_modes = {s.k31_mode for s in states}
    k35_status = {s.k35_status for s in states}
    tau9 = {s.tau9 for s in states}

    if k19_modes == {"BARE"}:
        out.append("k19 BARE: residual R has only 1-mod19 prime support")
    if k27_modes == {"Q"}:
        out.append("k27 Q: every prime factor of E is QR mod27")
    if k31_modes == {"BARE"}:
        out.append("k31 BARE: every prime factor of D lies in H31={1,5,25} mod31")
    if route == "B":
        out.append("Route-B k47 miss coordinate: every prime factor of J is QR mod47")
        k47_modes = {s.k47_mode for s in states}
        if k47_modes == {"THIN"}:
            out.append("Route-B k47 THIN: after deleting 1-mod47 occurrences, J has {9} or {3,3}")
    if k35_status <= {"J_ONLY", "BOTH"}:
        out.append("k35 J35 present: every prime factor of F lies in H35")
    if k35_status <= {"S7_ONLY", "BOTH"} and tau9 <= {1, 7}:
        out.append("k35 S7 with v3(F)=1: rational 3 is distinguished and F/3 has only 1-mod7 support")
    return out


def propagate(
    route: str,
    constraints: dict[str, frozenset[object]],
    annotate_bec: bool = False,
) -> dict[str, object]:
    route = route.upper()
    if route not in {"A", "B"}:
        raise ValueError("route must be A or B")
    if route == "A" and "k47_mode" in constraints and constraints["k47_mode"] != {"NA"}:
        raise ValueError("k47_mode is not a Route-A grammar coordinate; omit it or use NA")

    states = [s for s in naive_states(route) if matches_constraints(s, constraints)]
    input_count = len(states)
    trace: list[dict[str, object]] = []

    for rule in RULES:
        before = len(states)
        states = [s for s in states if rule.predicate(route, s)]
        after = len(states)
        if after != before:
            event: dict[str, object] = {
                "rule": rule.name,
                "statement": rule.statement,
                "before": before,
                "after": after,
                "removed_in_ordered_trace": before - after,
            }
            if annotate_bec:
                event["bec_candidate"] = rule.bec_candidate
                event["bec_status"] = "observational scheduling metadata only; not proof data"
            trace.append(event)

    contradiction = not states
    result: dict[str, object] = {
        "analysis": "h169-dependency-propagator-v1",
        "route": route,
        "input_constraints": {k: sorted(v, key=str) for k, v in constraints.items()},
        "input_formal_tuples": input_count,
        "surviving_formal_tuples": len(states),
        "contradiction": contradiction,
        "theorem_trace": trace,
        "claim_boundary": (
            "finite symbolic propagation inside the realized h169 pair-route survivor grammar; "
            "formal tuples are not asserted arithmetic realizations"
        ),
    }

    if contradiction:
        result["domains"] = {}
        result["derived"] = {}
        result["support_consequences"] = []
        if input_count == 0:
            result["contradiction_source"] = "input constraints lie outside the grammar base domains"
        elif trace:
            result["contradiction_source"] = f"emptied by exact rule: {trace[-1]['rule']}"
        return result

    result["domains"] = project(states)
    result["derived"] = derived_projection(states)
    result["support_consequences"] = support_consequences(route, states)
    result["forced"] = {
        field: values[0]
        for field, values in result["domains"].items()  # type: ignore[union-attr]
        if len(values) == 1
    }
    return result


def self_test() -> None:
    a = propagate("A", {})
    b = propagate("B", {})
    assert a["surviving_formal_tuples"] == 105_600
    assert b["surviving_formal_tuples"] == 147_900

    rb = propagate("B", {"k19_mode": frozenset({"BARE"})})
    assert rb["contradiction"] is False
    assert rb["domains"]["tau19"] == [8]  # type: ignore[index]
    assert rb["domains"]["k27_mode"] == ["Q"]  # type: ignore[index]
    assert "k27 Q: every prime factor of E is QR mod27" in rb["support_consequences"]

    rb_bad = propagate(
        "B",
        {"k19_mode": frozenset({"BARE"}), "k27_mode": frozenset({"A"})},
    )
    assert rb_bad["contradiction"] is True

    odd = propagate("B", {"tau4": frozenset({1})})
    assert odd["domains"]["k31_mode"] == ["FULL_QR"]  # type: ignore[index]
    assert odd["domains"]["k47_mode"] == ["FULL_QR"]  # type: ignore[index]
    assert odd["derived"]["gcd_D_J"] == [2]  # type: ignore[index]

    thin = propagate("B", {"k47_mode": frozenset({"THIN"})})
    assert thin["domains"]["tau4"] == [0, 2]  # type: ignore[index]

    bare31 = propagate("A", {"k31_mode": frozenset({"BARE"})})
    assert bare31["domains"]["tau31"] == [0, 19, 29]  # type: ignore[index]
    assert bare31["domains"]["tau4"] == [0, 2]  # type: ignore[index]

    v3 = propagate("A", {"tau9": frozenset({4})})
    assert v3["domains"]["k35_status"] == ["J_ONLY"]  # type: ignore[index]

    ra = propagate("A", {"k19_mode": frozenset({"BARE"})})
    assert ra["domains"]["tau19"] == [2]  # type: ignore[index]
    assert set(ra["domains"]["k27_mode"]) == set(K27)  # type: ignore[index]


def build_constraints(args: argparse.Namespace) -> dict[str, frozenset[object]]:
    raw: dict[str, object] = {}
    if args.state_json:
        parsed = json.loads(args.state_json)
        if not isinstance(parsed, dict):
            raise ValueError("--state-json must decode to a JSON object")
        raw.update(parsed)
    mapping = {
        "tau19": args.tau19,
        "tau31": args.tau31,
        "tau4": args.tau4,
        "tau9": args.tau9,
        "k19_mode": args.k19_mode,
        "k27_mode": args.k27_mode,
        "k31_mode": args.k31_mode,
        "k35_status": args.k35_status,
        "k47_mode": args.k47_mode,
    }
    raw.update({k: v for k, v in mapping.items() if v is not None})
    return parse_constraints(raw)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Propagate exact constraints in the realized h169 pair-route survivor grammar."
    )
    parser.add_argument("--route", choices=("A", "B"))
    parser.add_argument("--state-json", help="partial state as a JSON object; values may be scalars or lists")
    parser.add_argument("--tau19", type=int)
    parser.add_argument("--tau31", type=int)
    parser.add_argument("--tau4", type=int)
    parser.add_argument("--tau9", type=int)
    parser.add_argument("--k19-mode", choices=M19)
    parser.add_argument("--k27-mode", choices=K27)
    parser.add_argument("--k31-mode", choices=M31)
    parser.add_argument("--k35-status", choices=K35)
    parser.add_argument("--k47-mode", choices=M47)
    parser.add_argument("--annotate-bec", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        report = {"analysis": "h169-dependency-propagator-self-test", "failures": 0}
        print(json.dumps(report, indent=2, sort_keys=True) if args.json else report)
        return 0

    if not args.route:
        parser.error("--route is required unless --self-test is used")

    constraints = build_constraints(args)
    report = propagate(args.route, constraints, annotate_bec=args.annotate_bec)
    print(json.dumps(report, indent=2, sort_keys=True) if args.json else report)
    return 1 if report["contradiction"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
