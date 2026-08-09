#!/usr/bin/env python3
"""
CENTL Physics — exact sphere-contact screenshot demo.

Runs the real `centl-physics --serve` JSONL interface and verifies:
  1. exact sphere contact classification,
  2. exact isolated elastic contact resolution with conservation checks,
  3. explicit deferral for an ambiguous simultaneous-contact world.

Run from the CENTL repository:
    python3 centl_contact_demo.py

Optional:
    CENTL_PHYSICS_BIN=/path/to/centl-physics python3 centl_contact_demo.py
"""

from __future__ import annotations

import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


class Style:
    enabled = sys.stdout.isatty() and "NO_COLOR" not in os.environ
    RESET = "\033[0m" if enabled else ""
    BOLD = "\033[1m" if enabled else ""
    DIM = "\033[2m" if enabled else ""
    GREEN = "\033[32m" if enabled else ""
    CYAN = "\033[36m" if enabled else ""
    YELLOW = "\033[33m" if enabled else ""
    MAGENTA = "\033[35m" if enabled else ""
    RED = "\033[31m" if enabled else ""


def find_server_command() -> list[str]:
    override = os.environ.get("CENTL_PHYSICS_BIN")
    if override:
        return shlex.split(override, posix=os.name != "nt") + ["--serve"]

    project_root = Path(__file__).resolve().parents[1]
    for relative in (
        Path("_build/default/src/physics_main.exe"),
        Path("_build/default/src/physics_main"),
    ):
        candidate = project_root / relative
        if candidate.is_file():
            return [str(candidate), "--serve"]

    dune = shutil.which("dune")
    if dune:
        return [dune, "exec", "centl-physics", "--", "--serve"]

    opam = shutil.which("opam")
    if opam:
        switch = os.environ.get("CENTL_OPAM_SWITCH", os.environ.get("OPAM_SWITCH", "centl"))
        return [
            opam,
            "exec",
            f"--switch={switch}",
            "--",
            "dune",
            "exec",
            "centl-physics",
            "--",
            "--serve",
        ]

    installed = shutil.which("centl-physics")
    if installed:
        return [installed, "--serve"]

    raise SystemExit(
        "Could not find a CENTL physics executable.\n"
        "Build with: opam exec --switch=centl -- make build\n"
        "Or set CENTL_PHYSICS_BIN to a built centl-physics executable."
    )


class CentlPhysics:
    def __init__(self) -> None:
        self.command = find_server_command()
        self.proc = subprocess.Popen(
            self.command,
            cwd=Path(__file__).resolve().parents[1],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )

    def request(self, action: str, **fields: Any) -> dict[str, Any]:
        assert self.proc.stdin is not None
        assert self.proc.stdout is not None

        request = {"version": 1, "action": action, **fields}
        self.proc.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
        self.proc.stdin.flush()

        line = self.proc.stdout.readline()
        if not line:
            err = ""
            if self.proc.stderr is not None:
                err = self.proc.stderr.read()
            raise RuntimeError(
                "CENTL physics service exited without a response.\n"
                f"Command: {' '.join(self.command)}\n{err}"
            )

        response = json.loads(line)
        if response.get("ok") is not True:
            raise RuntimeError(
                "CENTL rejected the demo request:\n"
                + json.dumps(response, indent=2, sort_keys=True)
            )
        if "physics" not in response:
            raise RuntimeError("CENTL response did not contain a physics result.")
        return response["physics"]

    def close(self) -> None:
        if self.proc.stdin is not None:
            self.proc.stdin.close()
        try:
            self.proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            self.proc.terminate()
            self.proc.wait(timeout=2)

    def __enter__(self) -> "CentlPhysics":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()


def q(value: str, unit: str) -> dict[str, str]:
    return {"value": value, "unit": unit}


def v3(x: str, y: str, z: str, unit: str) -> dict[str, str]:
    return {"x": x, "y": y, "z": z, "unit": unit}


def sphere(pid: str, x: str, vx: str, radius: str = "1") -> dict[str, Any]:
    return {
        "particle": {
            "id": pid,
            "mass": q("1", "kg"),
            "position": v3(x, "0", "0", "m"),
            "velocity": v3(vx, "0", "0", "m/s"),
        },
        "radius": q(radius, "m"),
    }


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError("Demo invariant failed: " + message)


def particle_velocity_x(world: dict[str, Any], pid: str) -> str:
    for body in world["spheres"]:
        particle = body["particle"]
        if particle["id"] == pid:
            return particle["velocity"]["x"]
    raise AssertionError(f"particle {pid!r} missing from returned world")


def section(number: int, title: str) -> None:
    print()
    print(f"{Style.BOLD}{Style.CYAN}{number}. {title}{Style.RESET}")
    print(f"{Style.DIM}{'─' * 70}{Style.RESET}")


def yes(value: bool) -> str:
    return f"{Style.GREEN}YES{Style.RESET}" if value else f"{Style.RED}NO{Style.RESET}"


def main() -> int:
    print(f"{Style.BOLD}{Style.MAGENTA}CENTL PHYSICS — EXACT CONTACT CONTRACT DEMO{Style.RESET}")
    print(f"{Style.DIM}Real JSONL machine interface • exact rational mechanics • no guessed physics{Style.RESET}")

    with CentlPhysics() as centl:
        capabilities = centl.request("capabilities")
        max_pairs = capabilities["limits"]["max_contact_pairs"]
        check(max_pairs == 4096, "expected the 4,096-pair contact ceiling")
        print(f"Protocol: v1   Contact budget: {max_pairs:,} unordered sphere pairs")

        # 1. Exact contact classification.
        analysis_world = [
            sphere("A", "0", "1"),
            sphere("B", "2", "-1"),
            sphere("C", "5", "0"),
        ]
        analysis = centl.request(
            "analyze_sphere_contacts",
            spheres=analysis_world,
        )

        summary = analysis["summary"]
        active = analysis["active_contacts"]
        check(analysis["exact"] is True, "contact analysis must be exact")
        check(summary == {
            "pair_count": 3,
            "separated": 2,
            "touching": 1,
            "overlapping": 0,
        }, "unexpected pair classification summary")
        check(len(active) == 1, "expected one active contact")

        contact = active[0]
        check(contact["particle1_id"] == "A" and contact["particle2_id"] == "B",
              "expected A/B contact evidence")
        check(contact["relation"] == "touching", "A/B must be touching")
        check(contact["distance_squared"]["value"] == "4", "distance² must equal 4")
        check(contact["radius_sum_squared"]["value"] == "4",
              "(rA+rB)² must equal 4")

        section(1, "EXACT CONTACT CLASSIFICATION")
        print("World:   A @ 0 m   B @ 2 m   C @ 5 m   (all radii = 1 m)")
        print("Pairs:   3 total   1 touching   0 overlapping   2 separated")
        print(
            f"A ↔ B:   distance² = {Style.BOLD}4 m²{Style.RESET}   "
            f"(rA+rB)² = {Style.BOLD}4 m²{Style.RESET}"
        )
        print(
            f"Verdict: {Style.GREEN}{Style.BOLD}TOUCHING — EXACT{Style.RESET} "
            f"{Style.DIM}(squared-distance equality; no √ required){Style.RESET}"
        )

        # 2. Exact isolated elastic resolution.
        collision_world = [
            sphere("A", "0", "1"),
            sphere("B", "2", "-1"),
            sphere("C", "6", "3"),
        ]
        resolved = centl.request(
            "resolve_isolated_elastic_sphere_contacts",
            spheres=collision_world,
        )

        check(resolved["exact"] is True, "resolution must be exact")
        check(resolved["decision"] == "completed", "resolution must complete")
        check(resolved["world_changed"] is True, "collision should change the world")
        check(resolved["invariants"]["momentum"] is True, "momentum must be conserved")
        check(resolved["invariants"]["kinetic_energy"] is True,
              "kinetic energy must be conserved")
        check(particle_velocity_x(resolved["world"], "A") == "-1",
              "A final vx must be -1")
        check(particle_velocity_x(resolved["world"], "B") == "1",
              "B final vx must be +1")
        check(particle_velocity_x(resolved["world"], "C") == "3",
              "C final vx must remain +3")

        section(2, "EXACT ELASTIC CONTACT RESOLUTION")
        print("Before:  vA = +1 m/s    vB = -1 m/s    vC = +3 m/s")
        print("After:   vA = -1 m/s    vB = +1 m/s    vC = +3 m/s")
        print(
            f"Decision: {Style.GREEN}{Style.BOLD}COMPLETED{Style.RESET}   "
            f"world changed: {yes(resolved['world_changed'])}"
        )
        print(
            f"Checks:   momentum conserved: {yes(resolved['invariants']['momentum'])}   "
            f"kinetic energy conserved: {yes(resolved['invariants']['kinetic_energy'])}"
        )

        # 3. Ambiguous simultaneous contact: CENTL must refuse to invent an order.
        ambiguous_world = [
            sphere("A", "0", "1"),
            sphere("B", "2", "0"),
            sphere("C", "4", "-1"),
        ]
        deferred = centl.request(
            "resolve_isolated_elastic_sphere_contacts",
            spheres=ambiguous_world,
        )

        check(deferred["exact"] is True, "deferred verdict must still be exact")
        check(deferred["decision"] == "deferred", "ambiguous world must defer")
        check(deferred["reason"] == "ambiguous_simultaneous_contacts",
              "expected simultaneous-contact reason")
        check(deferred["world_changed"] is False,
              "deferred resolution must be failure-atomic")
        check(deferred["ambiguous_particle_ids"] == ["B"],
              "B must be identified as the shared-contact particle")

        section(3, "HONEST REFUSAL OUTSIDE THE JUSTIFIED SOLVER DOMAIN")
        print("Geometry: A ↔ B touching simultaneously with B ↔ C")
        print(
            f"Decision: {Style.YELLOW}{Style.BOLD}DEFERRED{Style.RESET}   "
            f"reason: ambiguous_simultaneous_contacts"
        )
        print(f"World changed: {yes(deferred['world_changed'])}")
        print(
            f"{Style.YELLOW}CENTL refused to invent an impulse order or partially mutate the world.{Style.RESET}"
        )

        trust = deferred["trust_boundary"]
        check(trust["continuous_collision_detection"] is False, "CCD boundary changed")
        check(trust["penetration_correction"] is False, "penetration boundary changed")
        check(trust["friction"] is False, "friction boundary changed")
        check(trust["spin"] is False, "spin boundary changed")

        print()
        print(f"{Style.DIM}Trust boundary:{Style.RESET} CCD=false • penetration=false • friction=false • spin=false")
        print()
        print(
            f"{Style.GREEN}{Style.BOLD}ALL DEMO CHECKS PASSED{Style.RESET} "
            f"— every value above came from CENTL's live physics service."
        )

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"\n{Style.RED}{Style.BOLD}DEMO FAILED{Style.RESET}: {exc}", file=sys.stderr)
        raise SystemExit(1)
