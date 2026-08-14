#!/usr/bin/env python3
"""Publish one already-qualified CENTL Oasis artifact without rebuilding it."""

from __future__ import annotations

import argparse
import base64
import hashlib
import io
import json
import os
from pathlib import PurePosixPath
import re
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from typing import Any

SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SEMVER_RE = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
CHECKSUM_RE = re.compile(r"^([0-9a-f]{64})  centl-linux-x86_64[.]tar[.]gz$")
REQUIRED_GATES = {
    "toolchain-runtime",
    "metadata-coherence",
    "whitespace",
    "fstar-verify",
    "extract",
    "generated-diff",
    "quality",
    "native-tests",
    "python-tests",
    "hardening",
    "differential",
    "sci-interface",
    "release-package",
    "release-archive",
    "install-smoke",
}
REQUIRED_ARCHIVE_MEMBERS = {
    "centl/BUILD_MANIFEST.json",
    "centl/VERSION",
    "centl/bin/centl",
    "centl/bin/centl-physics",
    "centl/bin/centl-sci",
    "centl/licenses/CENTL-Apache-2.0",
}
MAX_ARTIFACT_BYTES = 128 * 1024 * 1024
MAX_ARCHIVE_DECLARED_BYTES = 256 * 1024 * 1024


class LatchError(RuntimeError):
    pass


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def ensure_safe_member(name: str) -> None:
    p = PurePosixPath(name)
    if not name or p.is_absolute() or ".." in p.parts or "" in p.parts:
        raise LatchError(f"unsafe archive member path: {name!r}")


class GitHub:
    def __init__(self, repo: str, token: str, api_url: str) -> None:
        self.repo = repo
        self.token = token
        self.api_url = api_url.rstrip("/")

    def _request(
        self,
        method: str,
        path_or_url: str,
        *,
        payload: object | None = None,
        data: bytes | None = None,
        content_type: str = "application/json",
        accept: str = "application/vnd.github+json",
        allow_404: bool = False,
    ) -> tuple[int, bytes, dict[str, str]]:
        url = path_or_url if path_or_url.startswith("https://") else self.api_url + path_or_url
        headers = {
            "Accept": accept,
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "centl-oasis-publication-latch",
        }
        body = data
        if payload is not None:
            body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            headers["Content-Type"] = "application/json"
        elif data is not None:
            headers["Content-Type"] = content_type
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.status, resp.read(), dict(resp.headers.items())
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")
            if allow_404 and exc.code == 404:
                return 404, detail.encode(), dict(exc.headers.items())
            raise LatchError(f"GitHub API {method} {url} failed ({exc.code}): {detail[:1000]}") from exc
        except OSError as exc:
            raise LatchError(f"GitHub API {method} {url} failed: {exc}") from exc

    def json(self, method: str, path: str, payload: object | None = None, allow_404: bool = False) -> Any | None:
        status, raw, _ = self._request(method, path, payload=payload, allow_404=allow_404)
        if status == 404 and allow_404:
            return None
        try:
            return json.loads(raw or b"null")
        except json.JSONDecodeError as exc:
            raise LatchError(f"GitHub API returned invalid JSON for {method} {path}") from exc

    def download_artifact(self, artifact_id: int) -> bytes:
        with tempfile.NamedTemporaryFile(prefix="centl-artifact-", delete=False) as handle:
            path = handle.name
        try:
            cmd = [
                "curl", "--fail", "--silent", "--show-error", "--location",
                "--header", "Accept: application/vnd.github+json",
                "--header", f"Authorization: Bearer {self.token}",
                "--header", "X-GitHub-Api-Version: 2022-11-28",
                f"{self.api_url}/repos/{self.repo}/actions/artifacts/{artifact_id}/zip",
                "--output", path,
            ]
            completed = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
            if completed.returncode != 0:
                raise LatchError(f"artifact {artifact_id} download failed: {completed.stderr.strip()}")
            raw = open(path, "rb").read()
            if not raw or len(raw) > MAX_ARTIFACT_BYTES:
                raise LatchError(f"artifact {artifact_id} has invalid size {len(raw)}")
            return raw
        finally:
            try:
                os.unlink(path)
            except FileNotFoundError:
                pass

    def upload_asset(self, upload_url: str, name: str, data: bytes, content_type: str) -> Any:
        base = upload_url.split("{", 1)[0]
        url = base + "?" + urllib.parse.urlencode({"name": name})
        status, raw, _ = self._request(
            "POST", url, data=data, content_type=content_type,
            accept="application/vnd.github+json",
        )
        if status not in {200, 201}:
            raise LatchError(f"unexpected asset upload status {status} for {name}")
        return json.loads(raw)

    def download_release_asset(self, asset_id: int) -> bytes:
        with tempfile.NamedTemporaryFile(prefix="centl-release-asset-", delete=False) as handle:
            path = handle.name
        try:
            cmd = [
                "curl", "--fail", "--silent", "--show-error", "--location",
                "--header", "Accept: application/octet-stream",
                "--header", f"Authorization: Bearer {self.token}",
                "--header", "X-GitHub-Api-Version: 2022-11-28",
                f"{self.api_url}/repos/{self.repo}/releases/assets/{asset_id}",
                "--output", path,
            ]
            completed = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
            if completed.returncode != 0:
                raise LatchError(f"release asset {asset_id} download failed: {completed.stderr.strip()}")
            return open(path, "rb").read()
        finally:
            try:
                os.unlink(path)
            except FileNotFoundError:
                pass


def only_named_artifact(artifacts: list[dict[str, Any]], name: str) -> dict[str, Any]:
    matches = [a for a in artifacts if a.get("name") == name and not a.get("expired")]
    if len(matches) != 1:
        raise LatchError(f"expected exactly one unexpired artifact {name!r}, found {len(matches)}")
    return matches[0]


def zip_files(raw: bytes) -> dict[str, bytes]:
    try:
        with zipfile.ZipFile(io.BytesIO(raw)) as zf:
            result: dict[str, bytes] = {}
            for info in zf.infolist():
                if info.is_dir():
                    continue
                ensure_safe_member(info.filename)
                if info.file_size > MAX_ARTIFACT_BYTES:
                    raise LatchError(f"zip member too large: {info.filename}")
                if info.filename in result:
                    raise LatchError(f"duplicate zip member: {info.filename}")
                result[info.filename] = zf.read(info)
            return result
    except zipfile.BadZipFile as exc:
        raise LatchError("GitHub artifact is not a valid ZIP") from exc


def validate_release_artifact(raw: bytes, candidate: str) -> tuple[str, bytes, bytes, dict[str, Any]]:
    files = zip_files(raw)
    expected = {"centl-linux-x86_64.tar.gz", "centl-linux-x86_64.tar.gz.sha256"}
    if set(files) != expected:
        raise LatchError(f"release artifact members differ from expected: {sorted(files)}")
    archive = files["centl-linux-x86_64.tar.gz"]
    checksum_file = files["centl-linux-x86_64.tar.gz.sha256"]
    checksum_text = checksum_file.decode("utf-8", "strict").strip()
    match = CHECKSUM_RE.fullmatch(checksum_text)
    if not match:
        raise LatchError("release checksum file has unexpected format")
    digest = sha256_bytes(archive)
    if digest != match.group(1):
        raise LatchError(f"release archive checksum mismatch: expected {match.group(1)}, got {digest}")

    try:
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tf:
            members = tf.getmembers()
            if len(members) > 1000:
                raise LatchError("release archive has too many members")
            declared = 0
            names: set[str] = set()
            for member in members:
                ensure_safe_member(member.name)
                if member.name in names:
                    raise LatchError(f"duplicate tar member: {member.name}")
                names.add(member.name)
                if member.issym() or member.islnk() or member.isdev() or member.isfifo():
                    raise LatchError(f"unsupported special archive member: {member.name}")
                declared += max(member.size, 0)
                if declared > MAX_ARCHIVE_DECLARED_BYTES:
                    raise LatchError("release archive declared size exceeds policy ceiling")
            missing = REQUIRED_ARCHIVE_MEMBERS - names
            if missing:
                raise LatchError(f"release archive missing required members: {sorted(missing)}")
            version_member = tf.extractfile("centl/VERSION")
            manifest_member = tf.extractfile("centl/BUILD_MANIFEST.json")
            if version_member is None or manifest_member is None:
                raise LatchError("release identity files are not regular files")
            version = version_member.read().decode("utf-8", "strict").strip()
            if not SEMVER_RE.fullmatch(version):
                raise LatchError(f"release VERSION is not strict SemVer: {version!r}")
            manifest = json.loads(manifest_member.read().decode("utf-8", "strict"))
    except (tarfile.TarError, json.JSONDecodeError, UnicodeError) as exc:
        raise LatchError(f"invalid release archive identity data: {exc}") from exc

    if not isinstance(manifest, dict) or manifest.get("kind") != "centl_build_manifest":
        raise LatchError("release build manifest kind is invalid")
    expected_fields = {
        "semantic_version": version,
        "platform": "linux",
        "architecture": "x86_64",
        "commit": candidate,
    }
    for key, expected_value in expected_fields.items():
        if manifest.get(key) != expected_value:
            raise LatchError(f"release manifest {key}={manifest.get(key)!r}, expected {expected_value!r}")
    verification = manifest.get("verification")
    if not isinstance(verification, dict) or verification.get("command") != "make verify":
        raise LatchError("release manifest does not identify the required F* verification command")
    if verification.get("result") not in {"passed", "not_attested"}:
        raise LatchError(f"unexpected embedded verification result: {verification.get('result')!r}")
    return version, archive, checksum_file, manifest


def validate_evidence(raw: bytes, candidate: str, version: str, archive_digest: str) -> dict[str, Any]:
    files = zip_files(raw)
    report_names = [name for name in files if name.endswith("/report.json") or name == "report.json"]
    if len(report_names) != 1:
        raise LatchError(f"expected exactly one Oasis report.json, found {len(report_names)}")
    try:
        report = json.loads(files[report_names[0]].decode("utf-8", "strict"))
    except (json.JSONDecodeError, UnicodeError) as exc:
        raise LatchError(f"invalid Oasis report: {exc}") from exc
    if not isinstance(report, dict):
        raise LatchError("Oasis report is not an object")
    if report.get("result") != "PASS" or report.get("mode") != "candidate":
        raise LatchError("Oasis evidence is not a successful candidate report")
    if report.get("version") != version:
        raise LatchError("Oasis evidence version does not match release archive")
    for section in ("initial_git", "final_git"):
        identity = report.get(section)
        if not isinstance(identity, dict) or identity.get("head") != candidate:
            raise LatchError(f"Oasis evidence {section} does not bind exact candidate SHA")
    if report.get("final_identity_failures") not in ([], None):
        raise LatchError("Oasis evidence records final identity failures")
    gates = report.get("gates")
    if not isinstance(gates, list):
        raise LatchError("Oasis evidence gates are missing")
    by_name = {g.get("name"): g for g in gates if isinstance(g, dict) and isinstance(g.get("name"), str)}
    missing = REQUIRED_GATES - set(by_name)
    if missing:
        raise LatchError(f"Oasis evidence missing required gates: {sorted(missing)}")
    failed = [name for name in REQUIRED_GATES if by_name[name].get("status") != "passed" or by_name[name].get("returncode") not in {0, None}]
    if failed:
        raise LatchError(f"Oasis evidence contains non-passing required gates: {sorted(failed)}")
    fstar = by_name["fstar-verify"]
    if fstar.get("command")[-2:] != ["make", "verify"]:
        raise LatchError("F* evidence did not run make verify")
    release_detail = str(by_name["release-archive"].get("detail") or "")
    if f"sha256={archive_digest}" not in release_detail:
        raise LatchError("Oasis evidence release-archive digest does not match preserved release bytes")
    return report


def derive_run_id(status: dict[str, Any]) -> int:
    target = str(status.get("target_url") or "")
    match = re.search(r"/actions/runs/([0-9]+)(?:$|[/?#])", target)
    if not match:
        raise LatchError("authoritative qualification status does not point to a workflow run")
    return int(match.group(1))


def owner_from_repo(repo: str) -> str:
    parts = repo.split("/", 1)
    if len(parts) != 2 or not all(parts):
        raise LatchError(f"invalid repository slug: {repo!r}")
    return parts[0]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--candidate", required=True)
    args = parser.parse_args(argv)

    token = os.environ.get("GH_TOKEN", "")
    api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com")
    if not token:
        raise LatchError("GH_TOKEN is required")
    candidate = args.candidate.strip()
    if not SHA_RE.fullmatch(candidate):
        raise LatchError("candidate must be a full lowercase 40-hex SHA")

    repo = args.repository
    owner = owner_from_repo(repo)
    gh = GitHub(repo, token, api_url)

    oasis_ref = gh.json("GET", f"/repos/{repo}/git/ref/heads/oasis")
    if not isinstance(oasis_ref, dict) or (oasis_ref.get("object") or {}).get("sha") != candidate:
        raise LatchError("candidate is not the exact current oasis branch head")

    open_prs = gh.json("GET", f"/repos/{repo}/pulls?state=open&base=oasis&per_page=100")
    if not isinstance(open_prs, list) or open_prs:
        raise LatchError(f"expected zero open pull requests targeting oasis, found {len(open_prs) if isinstance(open_prs, list) else 'invalid response'}")

    associated = gh.json("GET", f"/repos/{repo}/commits/{candidate}/pulls?per_page=100")
    if not isinstance(associated, list):
        raise LatchError("cannot read pull requests associated with candidate")
    qualified_prs = [
        pr for pr in associated
        if isinstance(pr, dict)
        and (pr.get("base") or {}).get("ref") == "oasis"
        and (pr.get("head") or {}).get("sha") == candidate
        and (pr.get("user") or {}).get("login") == owner
        and pr.get("state") == "closed"
        and pr.get("merged_at")
    ]
    if len(qualified_prs) != 1:
        raise LatchError(f"expected exactly one closed owner qualification PR for candidate, found {len(qualified_prs)}")

    status_doc = gh.json("GET", f"/repos/{repo}/commits/{candidate}/status")
    statuses = status_doc.get("statuses") if isinstance(status_doc, dict) else None
    if not isinstance(statuses, list):
        raise LatchError("cannot read combined commit status")
    authoritative = [s for s in statuses if isinstance(s, dict) and s.get("context") == "centl/oasis-qualification" and s.get("state") == "success"]
    if not authoritative:
        raise LatchError("exact candidate lacks successful centl/oasis-qualification status")
    run_id = derive_run_id(authoritative[0])

    run = gh.json("GET", f"/repos/{repo}/actions/runs/{run_id}")
    if not isinstance(run, dict) or run.get("conclusion") != "success":
        raise LatchError(f"qualification workflow run {run_id} is not successful")
    if run.get("event") not in {"push", "workflow_dispatch"}:
        raise LatchError(f"qualification workflow run {run_id} has unexpected event {run.get('event')!r}")

    artifact_doc = gh.json("GET", f"/repos/{repo}/actions/runs/{run_id}/artifacts?per_page=100")
    artifacts = artifact_doc.get("artifacts") if isinstance(artifact_doc, dict) else None
    if not isinstance(artifacts, list):
        raise LatchError("cannot read qualification artifacts")
    release_artifact = only_named_artifact(artifacts, f"oasis-release-{candidate}")
    evidence_artifact = only_named_artifact(artifacts, f"oasis-evidence-{candidate}")

    release_zip = gh.download_artifact(int(release_artifact["id"]))
    version, archive, checksum_file, manifest = validate_release_artifact(release_zip, candidate)
    archive_digest = sha256_bytes(archive)

    evidence_zip = gh.download_artifact(int(evidence_artifact["id"]))
    report = validate_evidence(evidence_zip, candidate, version, archive_digest)

    verification = manifest["verification"]
    if verification.get("result") == "not_attested":
        print("embedded manifest verification is external-attestation mode; preserved F* evidence is PASS")

    tag = f"v{version}"
    tag_ref = gh.json("GET", f"/repos/{repo}/git/ref/tags/{urllib.parse.quote(tag, safe='')}", allow_404=True)
    if tag_ref is None:
        gh.json("POST", f"/repos/{repo}/git/refs", {"ref": f"refs/tags/{tag}", "sha": candidate})
        print(f"created lightweight tag {tag} -> {candidate}")
    else:
        tag_object = tag_ref.get("object") if isinstance(tag_ref, dict) else None
        if not isinstance(tag_object, dict) or tag_object.get("type") != "commit" or tag_object.get("sha") != candidate:
            raise LatchError(f"existing tag {tag} does not point directly to exact Oasis candidate")
        print(f"verified existing tag {tag} -> {candidate}")

    notes_doc = gh.json("GET", f"/repos/{repo}/contents/docs/releases/{version}.md?ref={candidate}")
    if not isinstance(notes_doc, dict) or notes_doc.get("encoding") != "base64":
        raise LatchError("cannot retrieve release notes from exact candidate")
    try:
        body = base64.b64decode(str(notes_doc.get("content") or ""), validate=False).decode("utf-8", "strict")
    except (ValueError, UnicodeError) as exc:
        raise LatchError(f"invalid release notes encoding: {exc}") from exc

    release = gh.json("GET", f"/repos/{repo}/releases/tags/{urllib.parse.quote(tag, safe='')}", allow_404=True)
    if release is None:
        release = gh.json(
            "POST", f"/repos/{repo}/releases",
            {
                "tag_name": tag,
                "target_commitish": candidate,
                "name": f"CENTL {tag}",
                "body": body,
                "draft": False,
                "prerelease": False,
                "make_latest": "true",
            },
        )
        print(f"created GitHub release CENTL {tag}")
    if not isinstance(release, dict) or release.get("tag_name") != tag or release.get("draft") or release.get("prerelease"):
        raise LatchError("GitHub release state is inconsistent with Oasis publication")

    release_id = int(release["id"])
    upload_url = str(release.get("upload_url") or "")
    if not upload_url:
        raise LatchError("GitHub release lacks upload URL")
    assets_doc = gh.json("GET", f"/repos/{repo}/releases/{release_id}/assets?per_page=100")
    if not isinstance(assets_doc, list):
        raise LatchError("cannot read GitHub release assets")
    existing = {a.get("name"): a for a in assets_doc if isinstance(a, dict)}

    publication_assets = {
        "centl-linux-x86_64.tar.gz": (archive, "application/gzip"),
        "centl-linux-x86_64.tar.gz.sha256": (checksum_file, "text/plain"),
        f"oasis-evidence-{candidate}.zip": (evidence_zip, "application/zip"),
    }
    verified_assets: dict[str, str] = {}
    for name, (data, content_type) in publication_assets.items():
        asset = existing.get(name)
        if asset is None:
            asset = gh.upload_asset(upload_url, name, data, content_type)
            print(f"uploaded release asset {name}")
        asset_id = int(asset["id"])
        published = gh.download_release_asset(asset_id)
        local_digest = sha256_bytes(data)
        published_digest = sha256_bytes(published)
        if published_digest != local_digest:
            raise LatchError(f"published asset {name} digest mismatch")
        verified_assets[name] = published_digest

    final_tag = gh.json("GET", f"/repos/{repo}/git/ref/tags/{urllib.parse.quote(tag, safe='')}")
    if not isinstance(final_tag, dict) or (final_tag.get("object") or {}).get("sha") != candidate:
        raise LatchError("tag identity changed during publication")
    final_release = gh.json("GET", f"/repos/{repo}/releases/tags/{urllib.parse.quote(tag, safe='')}")
    if not isinstance(final_release, dict) or final_release.get("draft") or final_release.get("prerelease"):
        raise LatchError("release did not remain publicly published")

    summary = {
        "schema": 1,
        "kind": "centl_oasis_publication",
        "repository": repo,
        "candidate": candidate,
        "version": version,
        "tag": tag,
        "qualification_run_id": run_id,
        "qualification_pr": qualified_prs[0].get("number"),
        "release_id": release_id,
        "release_url": final_release.get("html_url"),
        "qualified_archive_sha256": archive_digest,
        "evidence_artifact_id": evidence_artifact.get("id"),
        "fstar_log_sha256": next(g for g in report["gates"] if g.get("name") == "fstar-verify").get("log_sha256"),
        "published_assets": verified_assets,
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except LatchError as exc:
        print(f"centl oasis publication: {exc}", file=sys.stderr)
        raise SystemExit(1)
