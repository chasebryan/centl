"""Compact GREAT/GOOD ledger and opt-in GitHub library.

One markdown file plus one JSON file per GREAT costs more inode space
than payload. Those grades live as one JSON line each. LETTERS stay
individual files. A git clone does not carry the ledger; fetch it.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tarfile
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

LEDGER_NAME = {"great": "great.jsonl", "good": "good.jsonl"}
REMOTE_NAME = "REMOTE.json"
DEFAULT_OWNER = "chasebryan"
DEFAULT_REPO = "centl"
ASSET_TAG = "es-findings"

_ID_CACHE: dict[str, dict] = {}


def _maybe_int(value):
    if isinstance(value, bool) or value is None:
        return value
    if isinstance(value, int):
        return value
    try:
        return int(value)
    except (TypeError, ValueError):
        return value


def ledger_path(root: Path, grade: str) -> Path:
    return root / LEDGER_NAME[grade]


def remote_path(root: Path) -> Path:
    return root / REMOTE_NAME


def record_from_parts(event: dict, tags: list[str], grade: str, ident: dict, stamp: str) -> dict:
    rec = {
        "id": ident["display"],
        "hex": ident["hex"],
        "number": ident["number"],
        "grade": grade,
        "tags": list(tags),
        "n": _maybe_int(event.get("n") or event.get("p") or event.get("bound")),
        "method": event.get("method"),
        "kind": event.get("kind"),
        "layer": event.get("layer"),
        "k": _maybe_int(event.get("k")),
        "x": _maybe_int(event.get("x")),
        "y": _maybe_int(event.get("y")),
        "z": _maybe_int(event.get("z")),
        "equation": event.get("equation"),
        "type": event.get("type"),
        "bound": _maybe_int(event.get("bound")),
        "kernel": event.get("kernel"),
        "written": stamp,
    }
    return {key: val for key, val in rec.items() if val is not None and val != ""}


def _cache(root: Path, grade: str) -> dict:
    path = ledger_path(root, grade)
    size = path.stat().st_size if path.is_file() else 0
    key = str(path)
    hit = _ID_CACHE.get(key)
    if hit is not None and hit["size"] == size:
        return hit
    ids: set[str] = set()
    if path.is_file():
        with path.open(encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                ident = obj.get("id")
                if ident:
                    ids.add(str(ident))
    state = {"size": size, "ids": ids}
    _ID_CACHE[key] = state
    return state


def known_ids(root: Path, grade: str) -> set[str]:
    return _cache(root, grade)["ids"]


def ledger_has(root: Path, grade: str, ident: str) -> bool:
    return ident in known_ids(root, grade)


def append_record(root: Path, rec: dict) -> Path:
    grade = rec["grade"]
    path = ledger_path(root, grade)
    line = json.dumps(rec, separators=(",", ":"), sort_keys=True) + "\n"
    with path.open("a", encoding="utf-8") as fh:
        fh.write(line)
    state = _cache(root, grade)
    state["ids"].add(rec["id"])
    state["size"] = path.stat().st_size
    return path


def tail_records(root: Path, grade: str, limit: int) -> list[dict]:
    path = ledger_path(root, grade)
    if not path.is_file():
        return []
    out: list[dict] = []
    with path.open(encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    for line in lines[-limit:]:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            out.append(obj)
    return out


def count_records(root: Path, grade: str) -> int:
    return len(known_ids(root, grade))


def find_record(root: Path, ident: str) -> dict | None:
    ident = ident.strip()
    for grade in ("great", "good"):
        path = ledger_path(root, grade)
        if not path.is_file():
            continue
        with path.open(encoding="utf-8") as fh:
            for line in fh:
                if ident not in line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if obj.get("id") == ident or obj.get("hex") == ident:
                    return obj
    folder = {"L-": "letters", "G-": "great", "O-": "good"}.get(ident[:2])
    if folder:
        side = root / folder / f"{ident}.json"
        if side.is_file():
            try:
                return json.loads(side.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                return None
    return None


def is_cleared_bound(obj: dict) -> bool:
    tags = obj.get("tags") or []
    event = obj.get("event") or obj
    return tags == ["cleared_bound"] or event.get("type") == "cleared_bound"


def record_from_loose(obj: dict) -> dict | None:
    if is_cleared_bound(obj):
        return None
    event = dict(obj.get("event") or {})
    tags = list(obj.get("tags") or [])
    grade = str(obj.get("grade") or "great")
    ident = {
        "display": obj.get("id") or "",
        "hex": obj.get("hex") or "",
        "number": obj.get("number"),
    }
    if not ident["display"]:
        return None
    stamp = str(obj.get("written") or event.get("written") or "")
    return record_from_parts(event, tags, grade, ident, stamp)


def _git_tracked(root: Path) -> set[Path]:
    try:
        proc = subprocess.run(
            ["git", "ls-files", "-z", "--", str(root)],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        return set()
    out: set[Path] = set()
    for raw in proc.stdout.split(b"\0"):
        if not raw:
            continue
        out.add(Path(raw.decode()) if not raw.startswith(b"/") else Path(raw.decode()))
    # git ls-files prints repo-relative paths
    cwd = Path.cwd()
    return {cwd / p if not p.is_absolute() else p for p in out}


def compact_loose(root: Path) -> dict:
    """Delete the old GREAT/GOOD pair-file pile. Do not parse hundreds of thousands of files.

    New hits go to great.jsonl / good.jsonl. Git-tracked sample files stay.
    """
    tracked = set()
    for path in _git_tracked(root):
        try:
            if path.exists():
                tracked.add(path.resolve())
        except OSError:
            continue
    tracked_names = {path.name for path in tracked}
    removed = 0
    for folder in ("great", "good"):
        directory = root / folder
        if not directory.is_dir():
            continue
        for entry in os.scandir(directory):
            if not entry.is_file():
                continue
            if not entry.name.endswith((".json", ".md")):
                continue
            if entry.name in tracked_names:
                continue
            try:
                os.unlink(entry.path)
                removed += 1
            except OSError:
                continue
    return {
        "added_great": 0,
        "added_good": 0,
        "skipped_cleared_bound": 0,
        "removed_files": removed,
        "max_cleared_bound": 0,
        "great": count_records(root, "great"),
        "good": count_records(root, "good"),
    }


def render_record(rec: dict) -> str:
    grade = str(rec.get("grade") or "?").upper()
    tags = rec.get("tags") or []
    tag0 = tags[0] if tags else grade.lower()
    eq = rec.get("equation") or ""
    ident = rec.get("id") or ""
    lines = [
        f"# {grade} — {tag0}",
        "",
        f"**Grade:** {grade}",
        f"**Rules that fired:** {', '.join(tags)}",
        f"**Id:** `{ident}`",
        "",
        "## What was found",
        "",
        "```text",
        eq or json.dumps(rec, sort_keys=True),
        "```",
        "",
        "| field | value |",
        "|---|---|",
        f"| n or p | {rec.get('n')} |",
        f"| method | {rec.get('method')} |",
        f"| kind | {rec.get('kind')} |",
        f"| k | {rec.get('k')} |",
        f"| x | {rec.get('x')} |",
        f"| y | {rec.get('y')} |",
        f"| z | {rec.get('z')} |",
        "",
        "Erdős–Straus remains open. A GREAT is not a proof.",
        "",
    ]
    return "\n".join(lines)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _run_zstd(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["zstd", "-T0", "-6", "-f", "-o", str(dest), str(src)],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode() or "zstd failed")


def _unzstd(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["zstd", "-d", "-f", "-o", str(dest), str(src)],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode() or "zstd -d failed")


def pack_library(root: Path, dest_dir: Path | None = None) -> dict:
    dest_dir = dest_dir or (root / ".pack")
    dest_dir.mkdir(parents=True, exist_ok=True)
    assets: dict[str, dict] = {}
    for grade, name in LEDGER_NAME.items():
        src = root / name
        if not src.is_file():
            src.write_text("")
        packed = dest_dir / f"{name}.zst"
        _run_zstd(src, packed)
        assets[grade] = {
            "asset": packed.name,
            "sha256": sha256_file(packed),
            "bytes": packed.stat().st_size,
            "records": count_records(root, grade),
        }
    letters = root / "letters"
    letters.mkdir(exist_ok=True)
    tar_path = dest_dir / "letters.tar"
    with tarfile.open(tar_path, "w") as tar:
        tar.add(letters, arcname="letters")
    packed_letters = dest_dir / "letters.tar.zst"
    _run_zstd(tar_path, packed_letters)
    tar_path.unlink(missing_ok=True)
    letter_files = sum(1 for p in letters.iterdir() if p.is_file())
    assets["letters"] = {
        "asset": packed_letters.name,
        "sha256": sha256_file(packed_letters),
        "bytes": packed_letters.stat().st_size,
        "records": letter_files,
    }
    return {"dir": str(dest_dir), "assets": assets}


def default_remote() -> dict:
    return {
        "schema": "es-findings-remote-v1",
        "owner": DEFAULT_OWNER,
        "repo": DEFAULT_REPO,
        "tag": ASSET_TAG,
        "url": f"https://github.com/{DEFAULT_OWNER}/{DEFAULT_REPO}/releases/tag/{ASSET_TAG}",
        "note": "These archives are not part of a git clone. Fetch them on purpose.",
        "grades": {},
    }


def load_remote(root: Path) -> dict:
    path = remote_path(root)
    if path.is_file():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                base = default_remote()
                base.update(data)
                return base
        except json.JSONDecodeError:
            pass
    return default_remote()


def save_remote(root: Path, remote: dict) -> None:
    remote_path(root).write_text(json.dumps(remote, indent=2, sort_keys=True) + "\n")


def asset_url(remote: dict, asset: str) -> str:
    owner = remote.get("owner") or DEFAULT_OWNER
    repo = remote.get("repo") or DEFAULT_REPO
    tag = remote.get("tag") or ASSET_TAG
    return f"https://github.com/{owner}/{repo}/releases/download/{tag}/{asset}"


def fetch_grades(root: Path, grades: list[str], *, remote: dict | None = None) -> list[str]:
    remote = remote or load_remote(root)
    wanted = list(grades)
    if not wanted or "all" in wanted:
        wanted = ["great", "good", "letters"]
    done: list[str] = []
    cache = root / ".pack"
    cache.mkdir(exist_ok=True)
    for grade in wanted:
        meta = (remote.get("grades") or {}).get(grade) or {}
        asset = meta.get("asset")
        if not asset:
            if grade in LEDGER_NAME:
                asset = f"{LEDGER_NAME[grade]}.zst"
            elif grade == "letters":
                asset = "letters.tar.zst"
            else:
                continue
        url = asset_url(remote, asset)
        dest = cache / asset
        print(f"fetch {url}")
        urllib.request.urlretrieve(url, dest)
        expect = meta.get("sha256")
        if expect:
            got = sha256_file(dest)
            if got != expect:
                raise RuntimeError(f"sha256 mismatch for {asset}: {got} != {expect}")
        if grade in LEDGER_NAME:
            _unzstd(dest, ledger_path(root, grade))
            _ID_CACHE.pop(str(ledger_path(root, grade)), None)
        elif grade == "letters":
            raw = cache / "letters.tar"
            _unzstd(dest, raw)
            with tarfile.open(raw, "r") as tar:
                tar.extractall(root)
            raw.unlink(missing_ok=True)
        done.append(grade)
    return done


def publish_release(root: Path, *, tag: str | None = None) -> dict:
    tag = tag or ASSET_TAG
    packed = pack_library(root)
    assets = packed["assets"]
    dest = Path(packed["dir"])
    files = [str(dest / spec["asset"]) for spec in assets.values()]
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    notes = f"""Erdős–Straus findings library ({stamp})

GREAT and GOOD records are compact JSONL. LETTERS are individual files.
These archives are **not** in a git clone. Download them on purpose:

    ./centl es fetch

or take a single grade:

    ./centl es fetch great
    ./centl es fetch good
    ./centl es fetch letters

A pile of findings is not a proof of the conjecture.
"""
    existing = subprocess.run(
        ["gh", "release", "view", tag, "--json", "tagName"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if existing.returncode == 0:
        subprocess.run(["gh", "release", "delete", tag, "--yes", "--cleanup-tag"], check=True)
    cmd = [
        "gh",
        "release",
        "create",
        tag,
        "--title",
        "Erdős–Straus findings library",
        "--notes",
        notes,
        "--latest=false",
        *files,
    ]
    subprocess.run(cmd, check=True)
    remote = default_remote()
    remote["tag"] = tag
    remote["url"] = f"https://github.com/{DEFAULT_OWNER}/{DEFAULT_REPO}/releases/tag/{tag}"
    remote["published"] = stamp
    remote["grades"] = assets
    save_remote(root, remote)
    return remote


def which_zstd() -> str | None:
    return shutil.which("zstd")
