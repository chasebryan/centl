#!/usr/bin/env python3
"""Run the trusted Oasis publication latch with curl-backed asset uploads."""

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

_reopened_drafts: set[int] = set()


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
        raise module.LatchError("cannot read release assets while recovering upload")
    matches = [asset for asset in assets if isinstance(asset, dict) and asset.get("name") == name]
    if len(matches) > 1:
        raise module.LatchError(
            f"release contains multiple assets named {name!r}; refusing ambiguous recovery"
        )
    return matches[0] if matches else None


def _ensure_uploadable_release(self, release_id: int) -> None:
    release = self.json("GET", f"/repos/{self.repo}/releases/{release_id}")
    if not isinstance(release, dict):
        raise module.LatchError("cannot read release state before asset upload")
    if release.get("draft"):
        _reopened_drafts.add(release_id)
        return
    if not release.get("immutable"):
        return

    print(
        f"release {release_id} is immutable with missing qualified assets; "
        "requesting supported API transition back to draft"
    )
    try:
        reopened = self.json(
            "PATCH",
            f"/repos/{self.repo}/releases/{release_id}",
            {"draft": True, "make_latest": "false"},
        )
    except module.LatchError as exc:
        raise module.LatchError(
            "published immutable release cannot be returned to draft through the "
            f"GitHub Releases API: {exc}"
        ) from exc
    if not isinstance(reopened, dict) or not reopened.get("draft"):
        raise module.LatchError(
            "GitHub accepted release update request but did not return the release to draft"
        )
    _reopened_drafts.add(release_id)
    print(f"release {release_id} returned to draft for exact-byte attachment")


def _publish_recovered_draft(self, release_id: int) -> None:
    if release_id not in _reopened_drafts:
        return
    published = self.json(
        "PATCH",
        f"/repos/{self.repo}/releases/{release_id}",
        {"draft": False, "prerelease": False, "make_latest": "true"},
    )
    if not isinstance(published, dict) or published.get("draft"):
        raise module.LatchError("recovered release did not republish successfully")
    print(f"republished release {release_id} after exact-byte attachment")
    _reopened_drafts.discard(release_id)


def curl_upload_asset(self, upload_url: str, name: str, data: bytes, content_type: str):
    base = upload_url.split("{", 1)[0]
    release_id = _release_id(upload_url)
    _ensure_uploadable_release(self, release_id)
    url = base + "?" + urllib.parse.urlencode({"name": name})

    with tempfile.NamedTemporaryFile(prefix="centl-upload-", delete=False) as payload:
        payload.write(data)
        payload_path = payload.name
    try:
        for attempt in (1, 2):
            with tempfile.NamedTemporaryFile(
                prefix="centl-upload-response-", delete=False
            ) as response:
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
                        f"release asset {name} upload transport failed: "
                        f"{completed.stderr.strip()}"
                    )
                try:
                    status = int(completed.stdout.strip())
                except ValueError as exc:
                    raise module.LatchError(
                        f"release asset {name} upload returned invalid HTTP status"
                    ) from exc
                response_bytes = Path(response_path).read_bytes()

                if status in {200, 201}:
                    try:
                        asset = json.loads(response_bytes)
                    except json.JSONDecodeError as exc:
                        raise module.LatchError(
                            f"release asset {name} upload returned invalid JSON"
                        ) from exc
                    if not isinstance(asset, dict):
                        raise module.LatchError(
                            f"release asset {name} upload returned non-object JSON"
                        )
                    if name.startswith("oasis-evidence-"):
                        _publish_recovered_draft(self, release_id)
                    return asset

                if status != 422:
                    detail = response_bytes.decode("utf-8", "replace")[:1000]
                    raise module.LatchError(
                        f"release asset {name} upload failed with HTTP {status}: {detail}"
                    )

                existing = _find_named_asset(self, release_id, name)
                if existing is None:
                    detail = response_bytes.decode("utf-8", "replace")[:1000]
                    raise module.LatchError(
                        f"release asset {name} upload returned HTTP 422 but no conflicting "
                        f"asset exists: {detail}"
                    )

                state = str(existing.get("state") or "")
                try:
                    size = int(existing.get("size") or 0)
                    asset_id = int(existing["id"])
                except (KeyError, TypeError, ValueError) as exc:
                    raise module.LatchError(
                        f"release asset {name} conflict has invalid metadata"
                    ) from exc

                if state == "uploaded" and size == len(data):
                    print(
                        f"reusing existing fully uploaded release asset {name} "
                        f"({size} bytes); digest verification follows"
                    )
                    if name.startswith("oasis-evidence-"):
                        _publish_recovered_draft(self, release_id)
                    return existing

                if attempt == 2:
                    raise module.LatchError(
                        f"release asset {name} remains incomplete after recovery: "
                        f"state={state!r}, size={size}, expected={len(data)}"
                    )

                print(
                    f"removing interrupted release asset stub {name}: "
                    f"state={state!r}, size={size}, expected={len(data)}"
                )
                self.json("DELETE", f"/repos/{self.repo}/releases/assets/{asset_id}")
            finally:
                try:
                    os.unlink(response_path)
                except FileNotFoundError:
                    pass

        raise module.LatchError(f"release asset {name} upload exhausted recovery attempts")
    finally:
        try:
            os.unlink(payload_path)
        except FileNotFoundError:
            pass


module.GitHub.upload_asset = curl_upload_asset

try:
    raise SystemExit(module.main())
except module.LatchError as exc:
    print(f"centl oasis publication: {exc}", file=sys.stderr)
    raise SystemExit(1)
