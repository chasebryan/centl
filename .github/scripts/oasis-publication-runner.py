#!/usr/bin/env python3
"""Run the trusted Oasis publication latch with immutable-release recovery."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import urllib.parse

SCRIPT = Path(__file__).with_name("oasis-publication.py")
spec = importlib.util.spec_from_file_location("centl_oasis_publication", SCRIPT)
if spec is None or spec.loader is None:
    raise SystemExit("cannot load Oasis publication latch")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def _arg(name: str) -> str:
    try:
        index = sys.argv.index(name)
        return sys.argv[index + 1]
    except (ValueError, IndexError) as exc:
        raise SystemExit(f"missing required runner argument {name}") from exc


CANDIDATE = _arg("--candidate")
REPOSITORY = _arg("--repository")
_payload_release: dict[str, object] | None = None
_payload_digests: dict[str, str] = {}


def _release_id(upload_url: str) -> int:
    base = upload_url.split("{", 1)[0]
    match = re.search(r"/releases/([0-9]+)/assets/?$", base)
    if not match:
        raise module.LatchError(f"cannot derive release id from upload URL: {base}")
    return int(match.group(1))


def _find_named_asset(self, release_id: int, name: str):
    assets = self.json(
        "GET", f"/repos/{self.repo}/releases/{release_id}/assets?per_page=100"
    )
    if not isinstance(assets, list):
        raise module.LatchError("cannot read release assets")
    matches = [asset for asset in assets if isinstance(asset, dict) and asset.get("name") == name]
    if len(matches) > 1:
        raise module.LatchError(
            f"release contains multiple assets named {name!r}; refusing ambiguous recovery"
        )
    return matches[0] if matches else None


def _payload_body(canonical_tag: str, payload_tag: str) -> str:
    lines = [
        f"# CENTL {canonical_tag} qualified Oasis payload",
        "",
        "This is the immutable qualified-byte payload companion for the canonical",
        f"CENTL release `{canonical_tag}`. It does not define a new CENTL version.",
        "",
        f"Canonical source tag: `{canonical_tag}`",
        f"Payload tag: `{payload_tag}`",
        f"Exact qualified commit: `{CANDIDATE}`",
        "",
        "The canonical immutable release was published before GitHub release assets",
        "could be attached. Because GitHub does not permit an immutable release to",
        "return to draft, the already-qualified bytes are preserved here on an",
        "ancillary tag pointing to the exact same commit.",
        "",
        "## Qualified asset SHA-256",
        "",
    ]
    for name in sorted(_payload_digests):
        lines.append(f"- `{name}`: `{_payload_digests[name]}`")
    lines.extend(
        [
            "",
            "The publication latch re-downloads every attached asset and requires",
            "byte-for-byte SHA-256 equality with the preserved qualification artifacts",
            "before reporting publication success.",
        ]
    )
    return "\n".join(lines) + "\n"


def _ensure_payload_release(self, canonical_release: dict[str, object]) -> dict[str, object]:
    global _payload_release
    if _payload_release is not None:
        return _payload_release

    canonical_tag = str(canonical_release.get("tag_name") or "")
    if not canonical_tag.startswith("v"):
        raise module.LatchError("canonical immutable release has invalid tag")
    payload_tag = canonical_tag + "-oasis-payload"

    tag_path = f"/repos/{self.repo}/git/ref/tags/{urllib.parse.quote(payload_tag, safe='')}"
    tag_ref = self.json("GET", tag_path, allow_404=True)
    if tag_ref is None:
        self.json(
            "POST",
            f"/repos/{self.repo}/git/refs",
            {"ref": f"refs/tags/{payload_tag}", "sha": CANDIDATE},
        )
        print(f"created ancillary payload tag {payload_tag} -> {CANDIDATE}")
    else:
        tag_object = tag_ref.get("object") if isinstance(tag_ref, dict) else None
        if (
            not isinstance(tag_object, dict)
            or tag_object.get("type") != "commit"
            or tag_object.get("sha") != CANDIDATE
        ):
            raise module.LatchError(
                f"existing payload tag {payload_tag} is not bound directly to exact Oasis SHA"
            )

    release_path = f"/repos/{self.repo}/releases/tags/{urllib.parse.quote(payload_tag, safe='')}"
    payload = self.json("GET", release_path, allow_404=True)
    if payload is None:
        payload = self.json(
            "POST",
            f"/repos/{self.repo}/releases",
            {
                "tag_name": payload_tag,
                "target_commitish": CANDIDATE,
                "name": f"CENTL {canonical_tag} qualified Oasis payload",
                "body": _payload_body(canonical_tag, payload_tag),
                "draft": True,
                "prerelease": False,
                "make_latest": "false",
            },
        )
        print(f"created draft ancillary payload release {payload_tag}")
    if not isinstance(payload, dict):
        raise module.LatchError("cannot resolve ancillary payload release")
    if payload.get("tag_name") != payload_tag:
        raise module.LatchError("ancillary payload release tag identity is inconsistent")

    payload_commit = self.json("GET", tag_path)
    payload_object = payload_commit.get("object") if isinstance(payload_commit, dict) else None
    if not isinstance(payload_object, dict) or payload_object.get("sha") != CANDIDATE:
        raise module.LatchError("ancillary payload release tag moved away from exact Oasis SHA")

    _payload_release = payload
    return payload


def _publish_payload_release(self, payload: dict[str, object]) -> None:
    if not payload.get("draft"):
        if not payload.get("immutable"):
            raise module.LatchError("published payload release is unexpectedly mutable")
        return
    release_id = int(payload["id"])
    canonical_tag = str(payload.get("name") or "").split(" qualified Oasis payload", 1)[0]
    canonical_tag = canonical_tag.removeprefix("CENTL ")
    payload_tag = str(payload["tag_name"])
    published = self.json(
        "PATCH",
        f"/repos/{self.repo}/releases/{release_id}",
        {
            "body": _payload_body(canonical_tag, payload_tag),
            "draft": False,
            "prerelease": False,
            "make_latest": "false",
        },
    )
    if not isinstance(published, dict) or published.get("draft"):
        raise module.LatchError("ancillary payload release did not publish successfully")
    if not published.get("immutable"):
        raise module.LatchError("ancillary payload release did not become immutable on publication")
    print(f"published immutable ancillary payload release {payload_tag}")
    _payload_release.clear()
    _payload_release.update(published)


def _target_release(self, canonical_upload_url: str) -> dict[str, object]:
    canonical_id = _release_id(canonical_upload_url)
    canonical = self.json("GET", f"/repos/{self.repo}/releases/{canonical_id}")
    if not isinstance(canonical, dict):
        raise module.LatchError("cannot read canonical release state before asset publication")
    if canonical.get("immutable"):
        return _ensure_payload_release(self, canonical)
    return canonical


def curl_upload_asset(self, upload_url: str, name: str, data: bytes, content_type: str):
    target = _target_release(self, upload_url)
    release_id = int(target["id"])
    target_upload_url = str(target.get("upload_url") or "")
    if not target_upload_url:
        raise module.LatchError("target release lacks upload URL")

    _payload_digests[name] = module.sha256_bytes(data)
    existing = _find_named_asset(self, release_id, name)
    if existing is not None:
        state = str(existing.get("state") or "")
        try:
            size = int(existing.get("size") or 0)
            asset_id = int(existing["id"])
        except (KeyError, TypeError, ValueError) as exc:
            raise module.LatchError(f"release asset {name} has invalid metadata") from exc
        if state == "uploaded" and size == len(data):
            print(
                f"reusing existing fully uploaded release asset {name} "
                f"({size} bytes); digest verification follows"
            )
            if name.startswith("oasis-evidence-") and target.get("draft"):
                _publish_payload_release(self, target)
            return existing
        if not target.get("draft"):
            raise module.LatchError(
                f"immutable payload release contains incomplete asset {name}: "
                f"state={state!r}, size={size}, expected={len(data)}"
            )
        print(
            f"removing interrupted draft asset stub {name}: "
            f"state={state!r}, size={size}, expected={len(data)}"
        )
        self.json("DELETE", f"/repos/{self.repo}/releases/assets/{asset_id}")

    if not target.get("draft") and target.get("immutable"):
        raise module.LatchError(
            f"immutable payload release is missing required asset {name}; refusing mutation"
        )

    base = target_upload_url.split("{", 1)[0]
    url = base + "?" + urllib.parse.urlencode({"name": name})
    with tempfile.NamedTemporaryFile(prefix="centl-upload-", delete=False) as payload_file:
        payload_file.write(data)
        payload_path = payload_file.name
    with tempfile.NamedTemporaryFile(prefix="centl-upload-response-", delete=False) as response:
        response_path = response.name
    try:
        cmd = [
            "curl",
            "--silent",
            "--show-error",
            "--location",
            "--request",
            "POST",
            "--header",
            "Accept: application/vnd.github+json",
            "--header",
            f"Authorization: Bearer {self.token}",
            "--header",
            "X-GitHub-Api-Version: 2022-11-28",
            "--header",
            f"Content-Type: {content_type}",
            "--data-binary",
            f"@{payload_path}",
            "--output",
            response_path,
            "--write-out",
            "%{http_code}",
            "--max-time",
            "300",
            url,
        ]
        completed = subprocess.run(
            cmd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=330,
            check=False,
        )
        if completed.returncode != 0:
            raise module.LatchError(
                f"release asset {name} upload transport failed: {completed.stderr.strip()}"
            )
        try:
            status = int(completed.stdout.strip())
        except ValueError as exc:
            raise module.LatchError(
                f"release asset {name} upload returned invalid HTTP status"
            ) from exc
        response_bytes = Path(response_path).read_bytes()
        if status not in {200, 201}:
            detail = response_bytes.decode("utf-8", "replace")[:1000]
            raise module.LatchError(
                f"release asset {name} upload failed with HTTP {status}: {detail}"
            )
        try:
            asset = json.loads(response_bytes)
        except json.JSONDecodeError as exc:
            raise module.LatchError(f"release asset {name} upload returned invalid JSON") from exc
        if not isinstance(asset, dict):
            raise module.LatchError(f"release asset {name} upload returned non-object JSON")
        if name.startswith("oasis-evidence-") and target.get("draft"):
            _publish_payload_release(self, target)
        return asset
    finally:
        for path in (payload_path, response_path):
            try:
                os.unlink(path)
            except FileNotFoundError:
                pass


module.GitHub.upload_asset = curl_upload_asset

try:
    result = module.main()
    if result == 0 and _payload_release is not None:
        print(
            json.dumps(
                {
                    "kind": "centl_oasis_payload_companion",
                    "candidate": CANDIDATE,
                    "tag": _payload_release.get("tag_name"),
                    "release_id": _payload_release.get("id"),
                    "immutable": _payload_release.get("immutable"),
                    "assets": _payload_digests,
                },
                indent=2,
                sort_keys=True,
            )
        )
    raise SystemExit(result)
except module.LatchError as exc:
    print(f"centl oasis publication: {exc}", file=sys.stderr)
    raise SystemExit(1)
