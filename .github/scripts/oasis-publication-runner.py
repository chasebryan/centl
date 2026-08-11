#!/usr/bin/env python3
"""Run the trusted Oasis publication latch with curl-backed asset uploads."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
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


def curl_upload_asset(self, upload_url: str, name: str, data: bytes, content_type: str):
    base = upload_url.split("{", 1)[0]
    url = base + "?" + urllib.parse.urlencode({"name": name})
    with tempfile.NamedTemporaryFile(prefix="centl-upload-", delete=False) as payload:
        payload.write(data)
        payload_path = payload.name
    with tempfile.NamedTemporaryFile(prefix="centl-upload-response-", delete=False) as response:
        response_path = response.name
    try:
        cmd = [
            "curl",
            "--fail",
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
                f"release asset {name} upload failed: {completed.stderr.strip()}"
            )
        try:
            return json.loads(Path(response_path).read_bytes())
        except json.JSONDecodeError as exc:
            raise module.LatchError(
                f"release asset {name} upload returned invalid JSON"
            ) from exc
    finally:
        for path in (payload_path, response_path):
            try:
                os.unlink(path)
            except FileNotFoundError:
                pass


module.GitHub.upload_asset = curl_upload_asset

try:
    raise SystemExit(module.main())
except module.LatchError as exc:
    print(f"centl oasis publication: {exc}", file=sys.stderr)
    raise SystemExit(1)
