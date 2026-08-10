#!/usr/bin/env python3
"""Preserve public GitHub forge metadata into an FCF-controlled CENTL mirror.

Git itself remains authoritative for source history. This snapshot preserves the
public collaboration/distribution metadata that a Git bundle does not contain:
issues, pull requests, comments, issue events, releases, labels, milestones,
branches/tags, contributors, and workflow definitions metadata.

An optional GITHUB_TOKEN is used only as an HTTP Authorization header and is never
written to the snapshot.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, NoReturn

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
HEX40 = re.compile(r"^[0-9a-f]{40}$")


def die(message: str) -> NoReturn:
    raise SystemExit(f"centl forge snapshot: {message}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while block := handle.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def write_json(path: Path, value: Any) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def sort_records(records: list[Any]) -> list[Any]:
    def key(item: Any) -> tuple[int, str, str]:
        if not isinstance(item, dict):
            return (2, "", json.dumps(item, sort_keys=True))
        identifier = item.get("id")
        if isinstance(identifier, int):
            return (0, f"{identifier:020d}", "")
        number = item.get("number")
        if isinstance(number, int):
            return (0, f"{number:020d}", "")
        return (1, str(item.get("name", "")), str(item.get("url", "")))

    return sorted(records, key=key)


class GitHubClient:
    def __init__(self, api_base: str, token: str | None) -> None:
        parsed = urllib.parse.urlparse(api_base)
        if parsed.scheme != "https" or not parsed.netloc:
            die("GitHub API base must use HTTPS")
        self.api_base = api_base.rstrip("/")
        self.origin = (parsed.scheme, parsed.netloc)
        self.token = token
        self.requests = 0
        self.rate_remaining: str | None = None

    def _request(self, url: str) -> tuple[Any, urllib.response.addinfourl]:
        parsed = urllib.parse.urlparse(url)
        if (parsed.scheme, parsed.netloc) != self.origin:
            die(f"refusing pagination outside API origin: {url}")
        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "centl-fcf-forge-preservation/1",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        request = urllib.request.Request(url, headers=headers)
        try:
            response = urllib.request.urlopen(request, timeout=60)
            raw = response.read()
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")[:1000]
            die(f"GitHub API {error.code} for {url}: {detail}")
        except urllib.error.URLError as error:
            die(f"GitHub API request failed for {url}: {error.reason}")
        self.requests += 1
        self.rate_remaining = response.headers.get("X-RateLimit-Remaining")
        try:
            value = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            die(f"GitHub API returned invalid JSON for {url}: {error}")
        return value, response

    def get(self, path: str) -> Any:
        url = f"{self.api_base}{path}"
        value, _ = self._request(url)
        return value

    def paginate(self, path: str) -> list[Any]:
        separator = "&" if "?" in path else "?"
        url = f"{self.api_base}{path}{separator}per_page=100"
        collected: list[Any] = []
        seen: set[str] = set()
        while url:
            if url in seen:
                die(f"pagination loop detected: {url}")
            seen.add(url)
            value, response = self._request(url)
            if not isinstance(value, list):
                die(f"expected list response while paginating {url}")
            collected.extend(value)
            next_url = ""
            link = response.headers.get("Link", "")
            for part in link.split(","):
                section = part.strip()
                if 'rel="next"' not in section:
                    continue
                match = re.match(r"^<([^>]+)>;", section)
                if not match:
                    die(f"malformed GitHub pagination Link header: {section}")
                next_url = match.group(1)
                break
            url = next_url
        return sort_records(collected)


def source_commit(mirror: Path) -> str:
    path = mirror / "project" / "SOURCE-COMMIT"
    if not path.exists():
        return "unrecorded"
    if not path.is_file() or path.is_symlink():
        die("project/SOURCE-COMMIT is unsafe")
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) != 1 or not HEX40.fullmatch(lines[0]):
        die("project/SOURCE-COMMIT is malformed")
    return lines[0]


def verify_existing_mirror_if_finalized(mirror: Path) -> None:
    receipt = mirror / "MIRROR-SHA256SUMS"
    if not receipt.exists():
        return
    subprocess.run(
        ["sh", str(ROOT / "scripts" / "mirror-receipt"), "verify", str(mirror)],
        check=True,
    )


def build_snapshot(stage: Path, client: GitHubClient, repository: str, commit: str) -> dict[str, int]:
    encoded = urllib.parse.quote(repository, safe="/")
    base = f"/repos/{encoded}"

    datasets: dict[str, Any] = {
        "repository.json": client.get(base),
        "issues.json": client.paginate(f"{base}/issues?state=all"),
        "issue-comments.json": client.paginate(f"{base}/issues/comments"),
        "issue-events.json": client.paginate(f"{base}/issues/events"),
        "pulls.json": client.paginate(f"{base}/pulls?state=all"),
        "pull-review-comments.json": client.paginate(f"{base}/pulls/comments"),
        "releases.json": client.paginate(f"{base}/releases"),
        "tags.json": client.paginate(f"{base}/tags"),
        "branches.json": client.paginate(f"{base}/branches"),
        "labels.json": client.paginate(f"{base}/labels"),
        "milestones.json": client.paginate(f"{base}/milestones?state=all"),
        "contributors.json": client.paginate(f"{base}/contributors"),
    }
    workflows = client.get(f"{base}/actions/workflows?per_page=100")
    if not isinstance(workflows, dict) or not isinstance(workflows.get("workflows"), list):
        die("unexpected actions/workflows response")
    workflows = dict(workflows)
    workflows["workflows"] = sort_records(workflows["workflows"])
    datasets["workflows.json"] = workflows

    counts: dict[str, int] = {}
    for filename, value in datasets.items():
        write_json(stage / filename, value)
        if isinstance(value, list):
            counts[filename] = len(value)
        elif filename == "workflows.json":
            counts[filename] = len(value["workflows"])
        else:
            counts[filename] = 1

    metadata = {
        "schema": 1,
        "repository": repository,
        "captured_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "preservation_source_commit": commit,
        "api_base": client.api_base,
        "http_requests": client.requests,
        "rate_limit_remaining_after_snapshot": client.rate_remaining,
        "token_used": bool(client.token),
        "datasets": counts,
        "note": "Public forge metadata snapshot. Git source history is preserved separately by the CENTL Git bundle.",
    }
    write_json(stage / "SNAPSHOT.json", metadata)
    return counts


def finalize_stage(stage: Path) -> None:
    manifest = stage / "FORGE-SHA256SUMS"
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "integrity.py"),
            "tree-manifest",
            "--root",
            str(stage),
            "--output",
            str(manifest),
        ],
        check=True,
    )
    with (stage / "FORGE-SHA256SUMS.sha256").open("w", encoding="ascii", newline="\n") as handle:
        handle.write(f"{sha256_file(manifest)}  FORGE-SHA256SUMS\n")
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "integrity.py"),
            "verify",
            str(stage / "FORGE-SHA256SUMS.sha256"),
            "--root",
            str(stage),
        ],
        check=True,
    )
    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "integrity.py"),
            "tree-verify",
            str(manifest),
            "--root",
            str(stage),
            "--ignore",
            "FORGE-SHA256SUMS",
            "--ignore",
            "FORGE-SHA256SUMS.sha256",
        ],
        check=True,
    )


def activate(stage: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and (not target.is_dir() or target.is_symlink()):
        die(f"forge snapshot target is not a normal directory: {target}")
    backup: Path | None = None
    if target.exists():
        backup = target.parent / f".{target.name}.old.{os.getpid()}"
        if backup.exists():
            shutil.rmtree(backup)
        target.rename(backup)
    try:
        stage.rename(target)
    except Exception:
        if backup is not None and backup.exists() and not target.exists():
            backup.rename(target)
        raise
    if backup is not None and backup.exists():
        shutil.rmtree(backup)


def main() -> int:
    parser = argparse.ArgumentParser(description="preserve public GitHub forge metadata")
    parser.add_argument("mirror", type=Path)
    parser.add_argument("--repository", default="chasebryan/centl")
    parser.add_argument("--api-base", default="https://api.github.com")
    parser.add_argument("--token-env", default="GITHUB_TOKEN")
    args = parser.parse_args()

    if not REPOSITORY_RE.fullmatch(args.repository):
        die("repository must be in owner/name form")
    mirror = args.mirror.expanduser().resolve()
    if not mirror.is_dir():
        die(f"preservation mirror not found: {mirror}")
    verify_existing_mirror_if_finalized(mirror)

    token = os.environ.get(args.token_env) or None
    client = GitHubClient(args.api_base, token)
    commit = source_commit(mirror)
    target = mirror / "forge" / "github"
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{target.name}.new.", dir=target.parent) as temporary:
        stage = Path(temporary)
        counts = build_snapshot(stage, client, args.repository, commit)
        finalize_stage(stage)
        # TemporaryDirectory wants to remove its path on exit. Move its contents
        # into a sibling staging directory that can be atomically activated.
        activation = target.parent / f".{target.name}.activate.{os.getpid()}"
        if activation.exists():
            shutil.rmtree(activation)
        stage.rename(activation)
        activate(activation, target)

    subprocess.run(
        ["sh", str(ROOT / "scripts" / "mirror-receipt"), "create", str(mirror)],
        check=True,
    )

    print("FCF CENTL forge metadata snapshot: PASS")
    print(f"repository={args.repository}")
    print(f"output={target}")
    print(f"requests={client.requests}")
    print(f"datasets={len(counts)}")
    print(f"token_used={'yes' if token else 'no'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
