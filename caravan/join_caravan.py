from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import secrets
from typing import Any

from .catalog import AuthenticatedCatalog, CatalogError, parse_catalog_bytes
from .content import ArtifactIdentity, ContentStore, IntegrityError, hash_file
from .identity import CarrierIdentity, IdentityError
from .policy import create_policy_receipt, write_policy_receipt


INVITE_SCHEMA = "fcf-caravan-telepathy-invite-v1"
VOLUNTEER_STATUS_SCHEMA = "fcf-caravan-volunteer-status-v1"
POLICY_VERSION = "FCF-CARAVAN-HOST-v1"
AGENT_VERSION = "fcf-caravan-telepathy-pilot-v1"
ONION_RE = re.compile(r"^[a-z2-7]{56}[.]onion$")
MISSIONS = ("source", "releases", "semantic", "recovery")
MISSION_PREFIXES = {name: name + "/" for name in MISSIONS}
MAX_STATUS_BYTES = 64 * 1024
MAX_CATALOG_BYTES = 16 * 1024 * 1024
DEFAULT_PORT = 8791
DEFAULT_STORAGE_GIB = 10
DEFAULT_UPLOAD_MIBPS = 4


class JoinError(RuntimeError):
    """A supporter join operation failed closed."""


@dataclass(frozen=True)
class Invite:
    origin: str
    catalog_sha256: str
    policy_version: str
    policy_sha256: str

    @classmethod
    def from_dict(cls, value: object) -> "Invite":
        if not isinstance(value, dict):
            raise JoinError("invite must be a JSON object")
        expected = {"schema", "origin", "catalog_sha256", "policy_version", "policy_sha256"}
        if set(value) != expected:
            raise JoinError("invite fields do not match the private-pilot schema")
        if value["schema"] != INVITE_SCHEMA:
            raise JoinError("unsupported CARAVAN Telepathy invite schema")
        origin = value["origin"]
        if not isinstance(origin, str) or ONION_RE.fullmatch(origin) is None:
            raise JoinError("invite origin must be a Tor v3 onion hostname")
        catalog_sha = _sha256_text(value["catalog_sha256"], "catalog_sha256")
        policy_sha = _sha256_text(value["policy_sha256"], "policy_sha256")
        policy_version = value["policy_version"]
        if not isinstance(policy_version, str) or policy_version != POLICY_VERSION:
            raise JoinError("invite policy version is not the supported host policy")
        return cls(origin, catalog_sha, policy_version, policy_sha)


def _sha256_text(value: object, field: str) -> str:
    if not isinstance(value, str) or len(value) != 64:
        raise JoinError(f"{field} must be a lowercase SHA-256 digest")
    if any(ch not in "0123456789abcdef" for ch in value):
        raise JoinError(f"{field} must be a lowercase SHA-256 digest")
    return value


def _private_dir(path: Path) -> None:
    if path.exists() or path.is_symlink():
        info = os.lstat(path)
        if not stat.S_ISDIR(info.st_mode) or stat.S_ISLNK(info.st_mode):
            raise JoinError(f"unsafe CARAVAN directory: {path}")
        if info.st_mode & 0o077:
            raise JoinError(f"CARAVAN directory is not owner-only: {path}")
        path.chmod(0o700)
        return
    path.mkdir(parents=True, mode=0o700)
    path.chmod(0o700)


def _read_json(path: Path, *, max_bytes: int) -> object:
    if path.is_symlink() or not path.is_file():
        raise JoinError(f"unsafe or missing JSON file: {path}")
    data = path.read_bytes()
    if len(data) > max_bytes:
        raise JoinError(f"JSON file exceeds the CARAVAN limit: {path}")
    try:
        return json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise JoinError(f"invalid JSON: {path}") from exc


def read_invite(path: os.PathLike[str] | str) -> Invite:
    return Invite.from_dict(_read_json(Path(path), max_bytes=16 * 1024))


def _xdg(name: str, fallback: Path) -> Path:
    value = os.environ.get(name)
    return Path(value).expanduser() if value else fallback


def roots() -> tuple[Path, Path, Path]:
    home = Path.home()
    return (
        _xdg("XDG_CONFIG_HOME", home / ".config") / "fcf-caravan",
        _xdg("XDG_DATA_HOME", home / ".local" / "share") / "fcf-caravan",
        _xdg("XDG_STATE_HOME", home / ".local" / "state") / "fcf-caravan",
    )


def policy_path() -> Path:
    payload_root = Path(__file__).resolve().parents[1]
    candidate = payload_root / "docs" / "CARAVAN-HOST-POLICY.md"
    if candidate.is_file():
        return candidate
    repo_root = payload_root.parent
    candidate = repo_root / "docs" / "CARAVAN-HOST-POLICY.md"
    if candidate.is_file():
        return candidate
    raise JoinError("CARAVAN host policy is not present in this join release")


def telepathyd_path() -> Path:
    payload_root = Path(__file__).resolve().parents[1]
    candidate = payload_root / "scripts" / "fcf-telepathyd"
    if candidate.is_file():
        return candidate
    repo_root = payload_root.parent
    candidate = repo_root / "scripts" / "fcf-telepathyd"
    if candidate.is_file():
        return candidate
    raise JoinError("fcf-telepathyd is not present in this join release")


def _validate_socks(value: str) -> tuple[str, str]:
    host, separator, port = value.rpartition(":")
    if not separator or not host or not port or not port.isdigit():
        raise JoinError("SOCKS endpoint must be HOST:PORT")
    if not 1 <= int(port) <= 65535:
        raise JoinError("SOCKS port is out of range")
    if any(ch.isspace() for ch in host):
        raise JoinError("SOCKS host contains whitespace")
    return host, port


def _curl_bytes(origin: str, path: str, socks: str, *, max_bytes: int, timeout: int) -> bytes:
    if not path.startswith("/") or "%" in path or "?" in path or "#" in path:
        raise JoinError("origin path is not canonical")
    if shutil.which("curl") is None:
        raise JoinError("curl is required for the Tor seed path")
    socks_host, socks_port = _validate_socks(socks)
    command = [
        "curl",
        "--fail",
        "--silent",
        "--show-error",
        "--proxy",
        "",
        "--proto",
        "=http",
        "--socks5-hostname",
        f"{socks_host}:{socks_port}",
        "--connect-timeout",
        "20",
        "--max-time",
        str(timeout),
        "--max-filesize",
        str(max_bytes),
        f"http://{origin}{path}",
    ]
    try:
        result = subprocess.run(
            command,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout + 10,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError) as exc:
        detail = ""
        if isinstance(exc, subprocess.CalledProcessError):
            detail = exc.stderr.decode("utf-8", "replace").strip()[-240:]
        raise JoinError(f"Tor seed fetch failed for {path}: {detail}") from exc
    if len(result.stdout) > max_bytes:
        raise JoinError(f"origin response exceeds the CARAVAN limit: {path}")
    return result.stdout


def _curl_file(
    origin: str,
    path: str,
    socks: str,
    destination: Path,
    *,
    max_bytes: int,
    timeout: int,
) -> None:
    if not path.startswith("/") or "%" in path or "?" in path or "#" in path:
        raise JoinError("origin path is not canonical")
    socks_host, socks_port = _validate_socks(socks)
    command = [
        "curl",
        "--fail",
        "--silent",
        "--show-error",
        "--proxy",
        "",
        "--proto",
        "=http",
        "--socks5-hostname",
        f"{socks_host}:{socks_port}",
        "--connect-timeout",
        "20",
        "--max-time",
        str(timeout),
        "--max-filesize",
        str(max_bytes),
        "--output",
        str(destination),
        f"http://{origin}{path}",
    ]
    try:
        subprocess.run(
            command,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=timeout + 10,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError) as exc:
        detail = ""
        if isinstance(exc, subprocess.CalledProcessError):
            detail = exc.stderr.decode("utf-8", "replace").strip()[-240:]
        raise JoinError(f"Tor seed fetch failed for {path}: {detail}") from exc
    if destination.stat().st_size > max_bytes:
        raise JoinError(f"download exceeds the configured artifact bound: {path}")


def _load_origin_status(data: bytes) -> dict[str, Any]:
    if len(data) > MAX_STATUS_BYTES:
        raise JoinError("origin status is too large")
    try:
        value = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise JoinError("origin status is not valid JSON") from exc
    if not isinstance(value, dict):
        raise JoinError("origin status is not an object")
    required = {
        "schema": "fcf-caravan-public-origin-status-v2",
        "mode": "fcf-owned-public-origin",
        "uploads": False,
        "proxying": False,
        "arbitrary_paths": False,
    }
    for key, expected in required.items():
        if value.get(key) != expected:
            raise JoinError(f"origin status failed the X200 publication boundary: {key}")
    return value


def _selected_artifacts(catalog: AuthenticatedCatalog, missions: tuple[str, ...]) -> list[Any]:
    selected: list[Any] = []
    allowed = set(missions)
    for artifact in catalog.artifacts:
        if artifact.distribution != "public-approved":
            continue
        first = PurePosixPath(artifact.logical_path).parts[0]
        if first in allowed and first in MISSION_PREFIXES:
            selected.append(artifact)
    if not selected:
        raise JoinError("the invite/catalog has no public-approved artifacts for these missions")
    return selected


def _safe_destination(root: Path, logical_path: str) -> Path:
    path = PurePosixPath(logical_path)
    if not path.parts or any(part in {"", ".", ".."} for part in path.parts):
        raise JoinError("catalog logical path is unsafe")
    if "\\" in logical_path or logical_path.startswith("/"):
        raise JoinError("catalog logical path is unsafe")
    destination = root.joinpath(*path.parts)
    destination.relative_to(root)
    return destination


def _write_private(path: Path, data: bytes) -> None:
    _private_dir(path.parent)
    if path.is_symlink():
        raise JoinError(f"unsafe CARAVAN state path: {path}")
    temporary = path.with_name(f".{path.name}.new-{os.getpid()}-{secrets.token_hex(4)}")
    if temporary.exists() or temporary.is_symlink():
        raise JoinError(f"temporary state path already exists: {temporary}")
    temporary.write_bytes(data)
    temporary.chmod(0o600)
    os.replace(temporary, path)


def _write_generation(
    *,
    data_root: Path,
    catalog_bytes: bytes,
    catalog: AuthenticatedCatalog,
    selected: list[Any],
    store: ContentStore,
    downloaded: dict[str, Path],
    missions: tuple[str, ...],
    policy_version: str,
) -> Path:
    generations = data_root / "generations"
    _private_dir(generations)
    generation = generations / f"generation-{int(time.time())}-{secrets.token_hex(6)}"
    generation.mkdir(mode=0o700)
    try:
        def write_file(relative: str, data: bytes) -> None:
            target = _safe_destination(generation, relative)
            _private_dir(target.parent)
            target.write_bytes(data)
            target.chmod(0o444)

        status = {
            "schema": VOLUNTEER_STATUS_SCHEMA,
            "role": "volunteer-camel",
            "transport": "tor-onion",
            "origin_seeded": True,
            "catalog_version": catalog.version,
            "missions": list(missions),
            "policy_version": policy_version,
            "uploads": False,
            "proxying": False,
            "arbitrary_paths": False,
            "public_node_identity": False,
            "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        }
        write_file("index.html", b"FCF CARAVAN volunteer camel\n")
        write_file("robots.txt", b"User-agent: *\nDisallow: /\n")
        write_file("status.json", (json.dumps(status, sort_keys=True, indent=2) + "\n").encode())
        write_file("caravan/catalog-v1.json", catalog_bytes)
        checksums: list[str] = []
        for artifact in selected:
            identity = store.path_for_verified(artifact.identity)
            target = _safe_destination(generation, artifact.logical_path)
            _private_dir(target.parent)
            os.link(identity, target)
            target.chmod(0o444)
            checksums.append(f"{artifact.identity.sha256}  {artifact.logical_path}")
        write_file("SHA256SUMS", ("\n".join(checksums) + "\n").encode())
        for path in generation.rglob("*"):
            if path.is_symlink():
                raise JoinError("generation contains a symbolic link")
            if path.is_dir():
                path.chmod(0o555)
            else:
                path.chmod(0o444)
        generation.chmod(0o555)
    except Exception:
        shutil.rmtree(generation, ignore_errors=True)
        raise

    current = data_root / "current"
    if current.exists() and not current.is_symlink():
        raise JoinError("CARAVAN current selector is not a symlink")
    temporary = data_root / f".current.new-{os.getpid()}-{secrets.token_hex(4)}"
    temporary.symlink_to(generation)
    os.replace(temporary, current)
    return generation


def _systemd_escape(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace(" ", "\\s")
        .replace("\t", "\\t")
    )


def _user_unit(
    *,
    config_root: Path,
    data_root: Path,
    state_root: Path,
    generation: Path,
    port: int,
    upload_mibps: int,
    uid: int,
) -> Path:
    unit_root = _xdg("XDG_CONFIG_HOME", Path.home() / ".config") / "systemd" / "user"
    _private_dir(unit_root)
    unit = unit_root / "fcf-caravan.service"
    executable = telepathyd_path()
    arguments = [
        sys.executable,
        str(executable),
        "serve",
        "--listen-host",
        "127.0.0.1",
        "--listen-port",
        str(port),
        "--live-root-uid",
        str(uid),
        "--caravan-live-root",
        str(data_root / "current"),
        "--carrier",
        "tor-onion",
        "--virtual-port",
        "80",
        "--publish",
        "--state-dir",
        str(state_root / "telepathy"),
        "--max-bytes-per-second",
        str(upload_mibps * 1024 * 1024),
    ]
    exec_start = " ".join(_systemd_escape(item) for item in arguments)
    data = f"""[Unit]
Description=FCF CARAVAN volunteer camel (Tor/Telepathy)
After=network-online.target

[Service]
Type=simple
ExecStart={exec_start}
Restart=on-failure
RestartSec=5s
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadOnlyPaths={_systemd_escape(str(data_root))}
ReadWritePaths={_systemd_escape(str(state_root))}
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

[Install]
WantedBy=default.target
"""
    _write_private(unit, data.encode("utf-8"))
    unit.chmod(0o600)
    return unit


def _start_user_service(unit: Path) -> None:
    if shutil.which("systemctl") is None:
        raise JoinError("systemctl is required to start the Tor/Telepathy camel")
    try:
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True, timeout=20)
        subprocess.run(
            ["systemctl", "--user", "enable", "--now", "fcf-caravan.service"],
            check=True,
            timeout=30,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError) as exc:
        raise JoinError(
            "user systemd could not start fcf-caravan.service; the carrier is prepared but offline"
        ) from exc


def _normalize_missions(value: str) -> tuple[str, ...]:
    if value == "all":
        return MISSIONS
    parts = tuple(part for part in value.split(",") if part)
    if not parts or any(part not in MISSIONS for part in parts):
        raise JoinError("missions must be source,releases,semantic,recovery or all")
    return tuple(item for item in MISSIONS if item in set(parts))


def _accept_policy(invite: Invite, args: argparse.Namespace) -> str:
    policy = policy_path()
    actual = hash_file(policy).sha256
    if actual != invite.policy_sha256:
        raise JoinError("local host policy does not match the invite policy digest")
    supplied = args.accept_policy
    if supplied is not None and supplied != invite.policy_version:
        raise JoinError("the supplied policy acceptance does not match the invite")
    if args.yes:
        if supplied != invite.policy_version:
            raise JoinError("--yes requires --accept-policy FCF-CARAVAN-HOST-v1")
        return "non-interactive"
    if not sys.stdin.isatty():
        raise JoinError("non-interactive join requires --accept-policy ... --yes")
    print(f"Policy: {invite.policy_version}")
    print(f"Policy SHA-256: {invite.policy_sha256}")
    print("This private-pilot carrier will use bounded storage and Tor/Telepathy.")
    print("Type ACCEPT to continue, or anything else to cancel: ", end="", flush=True)
    if sys.stdin.readline().strip() != "ACCEPT":
        raise JoinError("policy acceptance cancelled")
    return "interactive"


def _write_config(
    config_root: Path,
    *,
    invite: Invite,
    identity: CarrierIdentity,
    generation: Path,
    missions: tuple[str, ...],
    storage_gib: int,
    upload_mibps: int,
    port: int,
) -> Path:
    config = {
        "schema": "fcf-caravan-carrier-config-v3",
        "agent_version": AGENT_VERSION,
        "role": "volunteer-camel",
        "release_version": AGENT_VERSION,
        "network_mode": "telepathy-onion-private-pilot",
        "origin_onion": invite.origin,
        "inbound_listen": False,
        "loopback_listen": True,
        "arbitrary_content": False,
        "missions": list(missions),
        "storage_limit_gib": storage_gib,
        "upload_limit_mibps": upload_mibps,
        "mission_authority": "catalog-public-approved-only",
        "catalog_sha256": invite.catalog_sha256,
        "live_generation": str(generation),
        "telepathy_port": port,
        "census": {
            "mode": "aggregate-only",
            "public_node_listing": False,
            "public_ip_addresses": False,
            "public_hostnames": False,
            "heartbeat": "private-pilot-not-configured",
        },
        "identity": {
            "node_id_local_only": identity.node_id,
            "public_identity_published": False,
        },
    }
    destination = config_root / "config.json"
    _write_private(destination, (json.dumps(config, indent=2, sort_keys=True) + "\n").encode())
    destination.chmod(0o600)
    return destination


def join(args: argparse.Namespace) -> int:
    if os.geteuid() == 0:
        raise JoinError("join-caravan must run as the ordinary user, not root")
    invite = read_invite(args.invite)
    missions = _normalize_missions(args.missions)
    if args.storage_gib < 1 or args.storage_gib > 4096:
        raise JoinError("storage-gib must be between 1 and 4096")
    if args.upload_mibps < 1 or args.upload_mibps > 1024:
        raise JoinError("upload-mibps must be between 1 and 1024")
    if args.port < 1 or args.port > 65535:
        raise JoinError("telepathy port is out of range")
    acceptance_mode = _accept_policy(invite, args)

    config_root, data_root, state_root = roots()
    for root in (config_root, data_root, state_root):
        _private_dir(root)
    config_path = config_root / "config.json"
    if config_path.exists() or config_path.is_symlink():
        raise JoinError("this user already has a CARAVAN configuration; use status or leave")

    identity_root = state_root / "identity"
    identity = CarrierIdentity.load(identity_root) if identity_root.exists() else CarrierIdentity.create(identity_root)
    receipt = create_policy_receipt(
        identity,
        policy_path(),
        policy_version=invite.policy_version,
        agent_version=AGENT_VERSION,
        acceptance_mode=acceptance_mode,
    )
    write_policy_receipt(state_root / "policy-acceptance.json", receipt)

    status_bytes = _curl_bytes(invite.origin, "/status.json", args.socks, max_bytes=MAX_STATUS_BYTES, timeout=60)
    _load_origin_status(status_bytes)
    catalog_bytes = _curl_bytes(invite.origin, "/caravan/catalog-v1.json", args.socks, max_bytes=MAX_CATALOG_BYTES, timeout=120)
    if hashlib.sha256(catalog_bytes).hexdigest() != invite.catalog_sha256:
        raise JoinError("origin catalog digest does not match the private-pilot invite")
    try:
        catalog = parse_catalog_bytes(catalog_bytes)
    except CatalogError as exc:
        raise JoinError(f"origin catalog failed CARAVAN validation: {exc}") from exc
    selected = _selected_artifacts(catalog, missions)

    store = ContentStore(
        data_root / "store",
        max_bytes=args.storage_gib * 1024 * 1024 * 1024,
        min_free_bytes=max(256 * 1024 * 1024, args.storage_gib * 1024 * 1024 * 1024 // 20),
    )
    downloads_root = state_root / "downloads"
    _private_dir(downloads_root)
    downloaded: dict[str, Path] = {}
    try:
        for artifact in selected:
            temporary = downloads_root / f"{artifact.identity.sha256}.incoming"
            if temporary.exists() or temporary.is_symlink():
                temporary.unlink()
            _curl_file(
                invite.origin,
                "/" + artifact.logical_path,
                args.socks,
                temporary,
                max_bytes=artifact.identity.length,
                timeout=max(120, min(1800, 60 + artifact.identity.length // (1024 * 1024))),
            )
            try:
                store.import_file(temporary, expected=artifact.identity)
            except IntegrityError as exc:
                raise JoinError(f"artifact verification failed: {artifact.logical_path}") from exc
            downloaded[artifact.logical_path] = temporary
    finally:
        for path in downloads_root.iterdir():
            if path.is_file() or path.is_symlink():
                path.unlink()
    generation = _write_generation(
        data_root=data_root,
        catalog_bytes=catalog_bytes,
        catalog=catalog,
        selected=selected,
        store=store,
        downloaded=downloaded,
        missions=missions,
        policy_version=invite.policy_version,
    )
    config = _write_config(
        config_root,
        invite=invite,
        identity=identity,
        generation=generation,
        missions=missions,
        storage_gib=args.storage_gib,
        upload_mibps=args.upload_mibps,
        port=args.port,
    )
    unit = _user_unit(
        config_root=config_root,
        data_root=data_root,
        state_root=state_root,
        generation=generation,
        port=args.port,
        upload_mibps=args.upload_mibps,
        uid=os.geteuid(),
    )
    if not args.no_start:
        _start_user_service(unit)
    print("FCF CARAVAN volunteer camel: PREPARED")
    print(f"missions={','.join(missions)}")
    print(f"catalog_sha256={invite.catalog_sha256}")
    print(f"config={config}")
    print(f"service={unit}")
    if args.no_start:
        print("network=prepared-only")
    else:
        print("network=telepathy-onion-private-pilot")
    return 0


def status(_args: argparse.Namespace) -> int:
    config_root, data_root, state_root = roots()
    config_path = config_root / "config.json"
    if not config_path.is_file():
        raise JoinError("this user has no CARAVAN configuration")
    config = _read_json(config_path, max_bytes=64 * 1024)
    if not isinstance(config, dict):
        raise JoinError("CARAVAN config is not an object")
    identity = CarrierIdentity.load(state_root / "identity")
    print(f"role={config.get('role')}")
    print(f"node_id={identity.node_id}")
    print(f"network_mode={config.get('network_mode')}")
    print(f"catalog_sha256={config.get('catalog_sha256')}")
    service = subprocess.run(
        ["systemctl", "--user", "is-active", "fcf-caravan.service"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    print(f"service={service.stdout.strip() or 'inactive'}")
    hostname = state_root / "telepathy" / "tor" / "hidden-service" / "hostname"
    if hostname.is_file():
        print(f"onion={hostname.read_text(encoding='ascii').strip()}")
    return 0


def leave(_args: argparse.Namespace) -> int:
    config_root, _data_root, _state_root = roots()
    if not (config_root / "config.json").exists():
        raise JoinError("this user has no CARAVAN configuration")
    if shutil.which("systemctl") is not None:
        subprocess.run(
            ["systemctl", "--user", "disable", "--now", "fcf-caravan.service"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    print("FCF CARAVAN volunteer camel: offline")
    print("Local identity, verified cargo, and Tor identity were retained.")
    return 0


def parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="joincaravan")
    commands = parser.add_subparsers(dest="command", required=True)
    join_parser = commands.add_parser("join", help="seed and start a volunteer camel")
    join_parser.add_argument("--invite", type=Path, required=True)
    join_parser.add_argument("--missions", default="source,releases")
    join_parser.add_argument("--storage-gib", type=int, default=DEFAULT_STORAGE_GIB)
    join_parser.add_argument("--upload-mibps", type=int, default=DEFAULT_UPLOAD_MIBPS)
    join_parser.add_argument("--socks", default="127.0.0.1:9050")
    join_parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    join_parser.add_argument("--accept-policy")
    join_parser.add_argument("--yes", action="store_true")
    join_parser.add_argument("--no-start", action="store_true")
    commands.add_parser("status", help="show local private-pilot status")
    commands.add_parser("leave", help="stop the volunteer camel without deleting state")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "join":
            return join(args)
        if args.command == "status":
            return status(args)
        if args.command == "leave":
            return leave(args)
        raise JoinError("unsupported joincaravan command")
    except (JoinError, IdentityError, IntegrityError, OSError) as exc:
        print(f"joincaravan: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
