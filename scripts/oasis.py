#!/usr/bin/env python3
"""CENTL Oasis convergence engine.

This command performs safe deterministic repair, then executes the local gates
that back the project Oasis release standard. It is intentionally fail-closed:
an exit status of zero means every required gate in the selected profile ran
and passed. It never edits tests, disables checks, or treats a skipped required
gate as success.
"""

from __future__ import annotations

import argparse
import dataclasses
import datetime as dt
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
from typing import Iterable, Sequence

SCHEMA_VERSION = 1
VERSION_RE = re.compile(
    r'^\s*let\s+value\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?)"\s*$'
)
MAX_ARCHIVE_MEMBERS = 100_000
MAX_ARCHIVE_BYTES = 2 * 1024 * 1024 * 1024


@dataclasses.dataclass(frozen=True)
class Gate:
    name: str
    phase: str
    argv: tuple[str, ...]
    timeout: int
    description: str
    env: tuple[tuple[str, str], ...] = ()


@dataclasses.dataclass
class GateResult:
    name: str
    phase: str
    status: str
    returncode: int | None
    duration_seconds: float
    command: list[str]
    log: str | None = None
    detail: str | None = None
    log_sha256: str | None = None

    def as_dict(self) -> dict[str, object]:
        return dataclasses.asdict(self)


class OasisError(RuntimeError):
    pass


class CommandRunner:
    def __init__(self, root: Path, log_dir: Path, echo: bool = True):
        self.root = root
        self.log_dir = log_dir
        self.echo = echo

    def run(self, gate: Gate, base_env: dict[str, str]) -> GateResult:
        self.log_dir.mkdir(parents=True, exist_ok=True)
        log_path = self.log_dir / f"{gate.name}.log"
        env = dict(base_env)
        env.update(dict(gate.env))
        started = time.monotonic()
        rc: int | None = None
        status = "failed"
        detail: str | None = None
        output = b""

        if self.echo:
            print(f"\n[oasis] {gate.phase}/{gate.name}: {gate.description}")
            print(f"[oasis] $ {shlex.join(gate.argv)}")

        try:
            proc = subprocess.Popen(
                gate.argv,
                cwd=self.root,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            try:
                output, _ = proc.communicate(timeout=gate.timeout)
                rc = proc.returncode
                status = "passed" if rc == 0 else "failed"
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(proc.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    tail, _ = proc.communicate(timeout=5)
                except subprocess.TimeoutExpired:
                    try:
                        os.killpg(proc.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    tail, _ = proc.communicate()
                output += tail or b""
                rc = 124
                status = "timeout"
                detail = f"exceeded {gate.timeout}s timeout"
        except FileNotFoundError as exc:
            detail = f"command not found: {exc.filename}"
            rc = 127
            status = "failed"
            output = (detail + "\n").encode()

        log_path.write_bytes(output)
        digest = hashlib.sha256(output).hexdigest()
        if self.echo and output:
            sys.stdout.buffer.write(output)
            if not output.endswith(b"\n"):
                sys.stdout.buffer.write(b"\n")
            sys.stdout.buffer.flush()

        return GateResult(
            name=gate.name,
            phase=gate.phase,
            status=status,
            returncode=rc,
            duration_seconds=round(time.monotonic() - started, 3),
            command=list(gate.argv),
            log=str(log_path),
            detail=detail,
            log_sha256=digest,
        )


def opam_make(target: str, *args: str, switch: str = "centl") -> tuple[str, ...]:
    return ("opam", "exec", f"--switch={switch}", "--", "make", target, *args)


def build_plan(version: str, switch: str = "centl") -> list[Gate]:
    """Return the canonical full local Oasis gate plan in execution order."""
    return [
        Gate(
            "format-fix",
            "repair",
            opam_make("format-fix", switch=switch),
            300,
            "apply the one permitted automatic source repair: canonical formatting",
        ),
        Gate(
            "whitespace",
            "coherence",
            ("git", "diff", "--check"),
            120,
            "reject whitespace errors after repair",
        ),
        Gate(
            "fstar-verify",
            "verification",
            opam_make("verify", switch=switch),
            1200,
            "verify the F* core with the pinned proof toolchain",
        ),
        Gate(
            "extract",
            "verification",
            opam_make("extract", switch=switch),
            1200,
            "extract verified F* modules into the committed OCaml generated core",
        ),
        Gate(
            "generated-diff",
            "verification",
            ("git", "diff", "--exit-code", "--", "src/generated"),
            120,
            "require committed generated OCaml to match fresh verified extraction exactly",
        ),
        Gate(
            "quality",
            "coherence",
            opam_make("quality", switch=switch),
            1200,
            "run formatting, lint, licensing, installer, integrity, and supply-chain gates",
        ),
        Gate(
            "native-tests",
            "validation",
            opam_make("native-test", switch=switch),
            1800,
            "run the integrated native test suite",
        ),
        Gate(
            "python-tests",
            "validation",
            (sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", "test_*.py"),
            1800,
            "run repository Python regression, CARAVAN, and automation tests",
        ),
        Gate(
            "hardening",
            "security",
            opam_make("hardening-test", switch=switch),
            2400,
            "run adversarial, fuzz, metamorphic, mandatory sanitizer, and performance gates",
            env=(("CENTL_SANITIZER_REQUIRED", "1"),),
        ),
        Gate(
            "differential",
            "validation",
            opam_make("differential-test", switch=switch),
            1800,
            "compare CENTL numerics against the pinned independent Julia/Nemo oracle",
        ),
        Gate(
            "sci-interface",
            "component",
            opam_make("sci-interface-check", switch=switch),
            900,
            "exercise the shipped CENTL-SCi local interface boundary",
        ),
        Gate(
            "release-package",
            "release",
            opam_make("release", f"VERSION={version}", switch=switch),
            1800,
            "build the exact current version and create the GNU/Linux release archive",
        ),
    ]


def read_version(root: Path) -> str:
    path = root / "src/ocaml/centl_version.ml"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise OasisError(f"cannot read authoritative version file: {exc}") from exc
    match = VERSION_RE.match(text)
    if not match:
        raise OasisError(f"invalid authoritative version declaration in {path}")
    return match.group(1)


def run_capture(root: Path, argv: Sequence[str], timeout: int = 30) -> str:
    try:
        completed = subprocess.run(
            argv,
            cwd=root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise OasisError(f"cannot run {shlex.join(argv)}: {exc}") from exc
    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip()
        raise OasisError(f"{shlex.join(argv)} failed: {message}")
    return completed.stdout.strip()


def git_state(root: Path) -> dict[str, object]:
    head = run_capture(root, ("git", "rev-parse", "HEAD"))
    branch = run_capture(root, ("git", "branch", "--show-current")) or "DETACHED"
    tracked_dirty = run_capture(root, ("git", "status", "--porcelain", "--untracked-files=no"))
    return {
        "head": head,
        "branch": branch,
        "tracked_dirty": bool(tracked_dirty),
        "tracked_changes": [line for line in tracked_dirty.splitlines() if line],
    }


def require_layout(root: Path, version: str) -> None:
    required = [
        "Makefile",
        "centl.opam",
        "SECURITY.md",
        "docs/OASIS.md",
        "docs/REPOSITORY-MAP.md",
        f"docs/releases/{version}.md",
        "install",
        "scripts/package-release",
        "scripts/integrity.py",
    ]
    missing = [path for path in required if not (root / path).exists()]
    if missing:
        raise OasisError("repository layout is incomplete: " + ", ".join(missing))


def require_tools(names: Iterable[str]) -> None:
    missing = [name for name in names if shutil.which(name) is None]
    if missing:
        raise OasisError(
            "required Oasis tools are missing from PATH: " + ", ".join(sorted(missing))
        )


def normalized_environment(root: Path) -> dict[str, str]:
    env = dict(os.environ)
    env.update({"LC_ALL": "C", "LANG": "C", "TZ": "UTC", "PYTHONHASHSEED": "0"})
    if "SOURCE_DATE_EPOCH" not in env:
        try:
            env["SOURCE_DATE_EPOCH"] = run_capture(
                root, ("git", "show", "-s", "--format=%ct", "HEAD")
            )
        except OasisError:
            env["SOURCE_DATE_EPOCH"] = "315532800"
    return env


def validate_archive_member(member: tarfile.TarInfo) -> None:
    name = member.name
    path = PurePosixPath(name)
    if not name or path.is_absolute() or ".." in path.parts:
        raise OasisError(f"unsafe release archive path: {name!r}")
    if member.issym() or member.islnk():
        raise OasisError(f"release archive contains a link: {name!r}")
    if not (member.isdir() or member.isfile()):
        raise OasisError(f"release archive contains unsupported filesystem object: {name!r}")
    if member.size < 0:
        raise OasisError(f"release archive contains invalid negative size: {name!r}")


def validate_release_archive(root: Path, version: str) -> GateResult:
    started = time.monotonic()
    archive = root / "dist/centl-linux-x86_64.tar.gz"
    checksum = root / "dist/centl-linux-x86_64.tar.gz.sha256"
    try:
        if not archive.is_file() or archive.stat().st_size <= 0:
            raise OasisError(f"missing release archive: {archive}")
        if not checksum.is_file():
            raise OasisError(f"missing release checksum: {checksum}")
        line = checksum.read_text(encoding="utf-8").strip()
        fields = line.split()
        if not fields or not re.fullmatch(r"[0-9a-fA-F]{64}", fields[0]):
            raise OasisError("release checksum file does not contain one SHA-256 digest")
        expected = fields[0].lower()
        digest = hashlib.sha256()
        with archive.open("rb") as handle:
            for block in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(block)
        actual = digest.hexdigest()
        if actual != expected:
            raise OasisError(f"release checksum mismatch: expected {expected}, got {actual}")

        member_count = 0
        total_bytes = 0
        names: set[str] = set()
        with tarfile.open(archive, "r:gz") as tar:
            for member in tar:
                member_count += 1
                if member_count > MAX_ARCHIVE_MEMBERS:
                    raise OasisError("release archive member ceiling exceeded")
                validate_archive_member(member)
                total_bytes += member.size
                if total_bytes > MAX_ARCHIVE_BYTES:
                    raise OasisError("release archive expanded-size ceiling exceeded")
                names.add(member.name.rstrip("/"))

        expected_members = {
            "centl/VERSION",
            "centl/bin/centl",
            "centl/bin/centl-physics",
            "centl/bin/centl-sci",
            "centl/libexec/centl",
            "centl/libexec/centl-physics",
            "centl/libexec/centl-sci",
        }
        missing = sorted(expected_members - names)
        if missing:
            raise OasisError("release archive missing required members: " + ", ".join(missing))

        with tarfile.open(archive, "r:gz") as tar:
            version_member = tar.extractfile("centl/VERSION")
            if version_member is None:
                raise OasisError("release archive VERSION is unreadable")
            packaged_version = version_member.read(256).decode("utf-8", "strict").strip()
            if packaged_version != version:
                raise OasisError(
                    f"release archive version {packaged_version!r} does not match {version!r}"
                )
        status = "passed"
        detail = f"{member_count} members, {total_bytes} declared bytes, sha256={actual}"
        rc = 0
    except (OasisError, OSError, tarfile.TarError, UnicodeError) as exc:
        status = "failed"
        detail = str(exc)
        rc = 1

    return GateResult(
        name="release-archive",
        phase="release",
        status=status,
        returncode=rc,
        duration_seconds=round(time.monotonic() - started, 3),
        command=["internal:validate-release-archive"],
        detail=detail,
    )


def install_smoke(root: Path, base_env: dict[str, str]) -> GateResult:
    started = time.monotonic()
    archive = root / "dist/centl-linux-x86_64.tar.gz"
    detail: str | None = None
    rc = 0
    try:
        with tempfile.TemporaryDirectory(prefix="centl-oasis-install-") as prefix:
            install = subprocess.run(
                ("sh", "install", "--archive", str(archive), "--prefix", prefix),
                cwd=root,
                env=base_env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                timeout=300,
                check=False,
            )
            if install.returncode != 0:
                raise OasisError("installer failed: " + install.stdout[-4000:])
            binary = Path(prefix) / "bin/centl"
            probes = [
                ((str(binary), "0.1 + 0.2"), "3/10"),
                ((str(binary), "2^128"), "340282366920938463463374607431768211456"),
                ((str(binary), "approx(sqrt(2), 12)"), "≈ [1.41421356237, 1.41421356238]"),
            ]
            for probe_argv, expected in probes:
                result = subprocess.run(
                    probe_argv,
                    cwd=root,
                    env=base_env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=60,
                    check=False,
                )
                if result.returncode != 0 or result.stdout.strip() != expected:
                    raise OasisError(
                        f"installed smoke probe failed for {shlex.join(probe_argv[1:])}: "
                        f"rc={result.returncode}, output={result.stdout.strip()!r}"
                    )
            detail = "isolated install and three exact/rigorous numeric probes passed"
    except (OasisError, OSError, subprocess.TimeoutExpired) as exc:
        rc = 1
        detail = str(exc)

    return GateResult(
        name="install-smoke",
        phase="release",
        status="passed" if rc == 0 else "failed",
        returncode=rc,
        duration_seconds=round(time.monotonic() - started, 3),
        command=["internal:install-smoke"],
        detail=detail,
    )


def atomic_json(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, indent=2, sort_keys=True) + "\n"
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        try:
            os.unlink(tmp)
        except FileNotFoundError:
            pass


def final_identity_checks(root: Path, version: str, state: dict[str, object]) -> list[str]:
    failures: list[str] = []
    if state["tracked_dirty"]:
        failures.append("tracked worktree is not clean")
    if state["branch"] != "main":
        failures.append(f"final qualification requires main, found {state['branch']}")
    head = str(state["head"])
    try:
        remote_main = run_capture(root, ("git", "ls-remote", "origin", "refs/heads/main"), 60)
        remote_sha = remote_main.split()[0] if remote_main else ""
        if remote_sha != head:
            failures.append(f"HEAD {head} is not exact origin/main {remote_sha or '<missing>'}")
    except OasisError as exc:
        failures.append(str(exc))

    tag = f"v{version}"
    try:
        raw = run_capture(
            root,
            ("git", "ls-remote", "origin", f"refs/tags/{tag}", f"refs/tags/{tag}^{{}}"),
            60,
        )
        refs = {
            line.split()[1]: line.split()[0]
            for line in raw.splitlines()
            if len(line.split()) == 2
        }
        tag_sha = refs.get(f"refs/tags/{tag}^{{}}") or refs.get(f"refs/tags/{tag}")
        if tag_sha != head:
            failures.append(f"{tag} does not resolve to exact HEAD {head}")
    except OasisError as exc:
        failures.append(str(exc))
    return failures


def github_repo_slug(root: Path) -> str:
    url = run_capture(root, ("git", "remote", "get-url", "origin"))
    match = re.search(r"github[.]com(?::|/)([^/\s]+/[^/\s]+?)(?:[.]git)?$", url)
    if not match:
        raise OasisError(f"cannot derive GitHub repository from origin URL: {url}")
    return match.group(1)


def gh_json(root: Path, endpoint: str) -> object:
    raw = run_capture(root, ("gh", "api", endpoint), 120)
    try:
        return json.loads(raw or "null")
    except json.JSONDecodeError as exc:
        raise OasisError(f"GitHub API returned invalid JSON for {endpoint}") from exc


def github_release_checks(root: Path, head: str) -> list[str]:
    """Return release-blocking GitHub state visible through authenticated gh."""
    failures: list[str] = []
    repo = github_repo_slug(root)

    try:
        prs = json.loads(
            run_capture(
                root,
                (
                    "gh",
                    "pr",
                    "list",
                    "--repo",
                    repo,
                    "--state",
                    "open",
                    "--base",
                    "main",
                    "--limit",
                    "100",
                    "--json",
                    "number,title,headRefName",
                ),
                120,
            )
            or "[]"
        )
        if prs:
            numbers = ", ".join(f"#{item.get('number')}" for item in prs)
            failures.append(f"open pull requests still target main: {numbers}")
    except (OasisError, json.JSONDecodeError) as exc:
        failures.append(f"cannot verify open pull requests: {exc}")

    try:
        checks = gh_json(root, f"repos/{repo}/commits/{head}/check-runs?per_page=100")
        runs = checks.get("check_runs", []) if isinstance(checks, dict) else []
        bad = []
        for item in runs:
            status = item.get("status")
            conclusion = item.get("conclusion")
            if status != "completed" or conclusion not in {"success", "neutral", "skipped"}:
                bad.append(f"{item.get('name', '<unnamed>')}={status}/{conclusion}")
        if bad:
            failures.append("non-green commit checks: " + ", ".join(bad[:20]))
    except OasisError as exc:
        failures.append(f"cannot verify commit checks: {exc}")

    try:
        alerts = gh_json(root, f"repos/{repo}/code-scanning/alerts?state=open&per_page=100")
        blocking = []
        if isinstance(alerts, list):
            for alert in alerts:
                rule = alert.get("rule") or {}
                severity = str(
                    rule.get("security_severity_level") or rule.get("severity") or ""
                ).lower()
                if severity in {"critical", "high", "error"}:
                    blocking.append(str(alert.get("number", "?")))
        if blocking:
            failures.append("open release-blocking code-scanning alerts: " + ", ".join(blocking))
    except OasisError as exc:
        failures.append(f"cannot verify code-scanning alerts: {exc}")

    try:
        alerts = gh_json(root, f"repos/{repo}/dependabot/alerts?state=open&per_page=100")
        blocking = []
        if isinstance(alerts, list):
            for alert in alerts:
                advisory = alert.get("security_advisory") or {}
                severity = str(advisory.get("severity") or "").lower()
                if severity in {"critical", "high"}:
                    blocking.append(str(alert.get("number", "?")))
        if blocking:
            failures.append("open high/critical Dependabot alerts: " + ", ".join(blocking))
    except OasisError as exc:
        failures.append(f"cannot verify Dependabot alerts: {exc}")

    try:
        alerts = gh_json(root, f"repos/{repo}/secret-scanning/alerts?state=open&per_page=100")
        if isinstance(alerts, list) and alerts:
            identifiers = ", ".join(str(item.get("number", "?")) for item in alerts[:20])
            failures.append("open secret-scanning alerts: " + identifiers)
    except OasisError as exc:
        failures.append(f"cannot verify secret-scanning alerts: {exc}")

    return failures


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Converge and qualify the CENTL tree against Oasis gates"
    )
    p.add_argument("--root", type=Path, default=Path.cwd(), help="repository root (default: cwd)")
    p.add_argument("--opam-switch", default=os.environ.get("OPAM_SWITCH", "centl"))
    p.add_argument("--no-repair", action="store_true", help="verify only; do not run format-fix")
    p.add_argument("--allow-dirty", action="store_true", help="permit pre-existing tracked edits before repair")
    p.add_argument("--keep-going", action="store_true", help="run later gates after a failure to collect evidence")
    p.add_argument(
        "--final",
        action="store_true",
        help="also require exact main/tag identity and release-blocking GitHub state to be green",
    )
    p.add_argument("--plan", action="store_true", help="print the gate plan without executing it")
    p.add_argument("--report", type=Path, help="explicit JSON evidence report path")
    p.add_argument("--quiet", action="store_true")
    return p


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    started_at = dt.datetime.now(dt.timezone.utc)

    try:
        version = read_version(root)
        require_layout(root, version)
    except OasisError as exc:
        print(f"[oasis] PRECHECK FAILED: {exc}", file=sys.stderr)
        return 2

    plan = build_plan(version, args.opam_switch)
    if args.no_repair:
        plan = [gate for gate in plan if gate.phase != "repair"]
    if args.plan:
        print(f"CENTL {version} Oasis gate plan")
        for gate in plan:
            print(f"- {gate.phase:12} {gate.name:18} {shlex.join(gate.argv)}")
        print("- release      release-archive    internal structural/checksum validation")
        print("- release      install-smoke      isolated installed-binary smoke probes")
        if args.final:
            print("- identity     final-main/github exact main/tag plus GitHub release blockers")
        return 0

    try:
        tools = ["git", "make", "opam", "python3", "fstar.exe", "julia", "sh"]
        if args.final:
            tools.append("gh")
        require_tools(tools)
        initial = git_state(root)
        if initial["tracked_dirty"] and not args.allow_dirty and not args.no_repair:
            raise OasisError(
                "tracked edits already exist; refusing to auto-format them. "
                "Commit/stash them, use --no-repair, or explicitly use --allow-dirty."
            )
    except OasisError as exc:
        print(f"[oasis] PRECHECK FAILED: {exc}", file=sys.stderr)
        return 2

    run_id = started_at.strftime("%Y%m%dT%H%M%SZ") + "-" + str(initial["head"])[:12]
    evidence_root = root / "_build/oasis" / run_id
    report_path = args.report.resolve() if args.report else evidence_root / "report.json"
    runner = CommandRunner(root, evidence_root / "logs", echo=not args.quiet)
    base_env = normalized_environment(root)
    results: list[GateResult] = []
    failed = False

    for gate in plan:
        if failed and not args.keep_going:
            break
        result = runner.run(gate, base_env)
        results.append(result)
        if result.status != "passed":
            failed = True

    if not failed or args.keep_going:
        archive_result = validate_release_archive(root, version)
        results.append(archive_result)
        failed = failed or archive_result.status != "passed"
    if (
        (not failed or args.keep_going)
        and results[-1].name == "release-archive"
        and results[-1].status == "passed"
    ):
        smoke_result = install_smoke(root, base_env)
        results.append(smoke_result)
        failed = failed or smoke_result.status != "passed"

    try:
        final_state = git_state(root)
    except OasisError as exc:
        final_state = {
            "head": None,
            "branch": None,
            "tracked_dirty": True,
            "tracked_changes": [str(exc)],
        }
        failed = True

    final_failures: list[str] = []
    if args.final:
        final_failures = final_identity_checks(root, version, final_state)
        if not final_failures:
            final_failures.extend(github_release_checks(root, str(final_state["head"])))
        failed = failed or bool(final_failures)

    finished_at = dt.datetime.now(dt.timezone.utc)
    payload: dict[str, object] = {
        "schema": SCHEMA_VERSION,
        "run_id": run_id,
        "version": version,
        "mode": "final" if args.final else "candidate",
        "started_at": started_at.isoformat(),
        "finished_at": finished_at.isoformat(),
        "duration_seconds": round((finished_at - started_at).total_seconds(), 3),
        "initial_git": initial,
        "final_git": final_state,
        "repair_enabled": not args.no_repair,
        "result": "PASS" if not failed else "FAIL",
        "gates": [result.as_dict() for result in results],
        "final_identity_failures": final_failures,
    }
    atomic_json(report_path, payload)

    print(f"\n[oasis] evidence: {report_path}")
    if failed:
        failures = [result for result in results if result.status != "passed"]
        for result in failures:
            print(
                f"[oasis] FAIL {result.name}: {result.detail or f'rc={result.returncode}'}",
                file=sys.stderr,
            )
        for item in final_failures:
            print(f"[oasis] FAIL final-main: {item}", file=sys.stderr)
        print("[oasis] OASIS QUALIFICATION: FAIL", file=sys.stderr)
        return 1

    if args.final:
        print(f"[oasis] CENTL v{version} OASIS RELEASE GATE: PASS")
    else:
        changed = bool(final_state.get("tracked_dirty"))
        suffix = " (safe repairs are present and must be reviewed/committed)" if changed else ""
        print(f"[oasis] CENTL v{version} OASIS CANDIDATE GATE: PASS{suffix}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
