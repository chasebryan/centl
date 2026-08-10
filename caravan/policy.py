"""Versioned CARAVAN host-policy acceptance receipts.

Receipts prove only that a pseudonymous carrier identity declared acceptance of
specific policy bytes. They do not identify the operator and do not authorize
artifacts.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass, replace
from datetime import datetime, timezone
import hashlib
import hmac
import json
import os
from pathlib import Path
import stat
import tempfile
from typing import Any

from .content import hash_file
from .identity import CarrierIdentity, IdentityError, derive_node_id, verify_signature

POLICY_RECEIPT_SCHEMA = "centl-caravan-policy-acceptance-v1"


class PolicyError(RuntimeError):
    """Raised when a policy receipt is malformed, mismatched, or unauthenticated."""


def _b64url_encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def _b64url_decode(text: str) -> bytes:
    try:
        padded = text + "=" * ((4 - len(text) % 4) % 4)
        return base64.urlsafe_b64decode(padded.encode("ascii"))
    except Exception as exc:
        raise PolicyError("invalid policy receipt signature encoding") from exc


def _canonical_json(value: dict[str, Any]) -> bytes:
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
        allow_nan=False,
    ).encode("utf-8")


def _timestamp(value: float | None) -> str:
    moment = datetime.now(timezone.utc) if value is None else datetime.fromtimestamp(value, timezone.utc)
    return moment.isoformat(timespec="seconds").replace("+00:00", "Z")


def _validate_timestamp(value: str) -> None:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise PolicyError("invalid policy acceptance timestamp") from exc
    if parsed.tzinfo is None:
        raise PolicyError("policy acceptance timestamp must include UTC offset")


def _validate_sha256(value: str) -> None:
    if len(value) != 64 or any(ch not in "0123456789abcdef" for ch in value):
        raise PolicyError("policy SHA-256 must be 64 lowercase hexadecimal characters")


@dataclass(frozen=True, slots=True)
class PolicyAcceptanceReceipt:
    schema: str
    node_id: str
    public_identity: str
    policy_version: str
    policy_sha256: str
    agent_version: str
    acceptance_mode: str
    accepted_at: str
    signature: str

    def payload(self) -> dict[str, str]:
        return {
            "schema": self.schema,
            "node_id": self.node_id,
            "public_identity": self.public_identity,
            "policy_version": self.policy_version,
            "policy_sha256": self.policy_sha256,
            "agent_version": self.agent_version,
            "acceptance_mode": self.acceptance_mode,
            "accepted_at": self.accepted_at,
        }

    def canonical_payload(self) -> bytes:
        return _canonical_json(self.payload())

    def to_dict(self) -> dict[str, str]:
        value = self.payload()
        value["signature"] = self.signature
        return value

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "PolicyAcceptanceReceipt":
        expected = {
            "schema",
            "node_id",
            "public_identity",
            "policy_version",
            "policy_sha256",
            "agent_version",
            "acceptance_mode",
            "accepted_at",
            "signature",
        }
        if set(value) != expected or any(not isinstance(value[key], str) for key in expected):
            raise PolicyError("policy receipt fields do not match schema")
        return cls(**{key: value[key] for key in expected})


def create_policy_receipt(
    identity: CarrierIdentity,
    policy_path: os.PathLike[str] | str,
    *,
    policy_version: str,
    agent_version: str,
    acceptance_mode: str,
    accepted_at: float | None = None,
) -> PolicyAcceptanceReceipt:
    if not policy_version or not agent_version:
        raise ValueError("policy_version and agent_version must be non-empty")
    if acceptance_mode not in {"interactive", "non-interactive"}:
        raise ValueError("unsupported policy acceptance mode")

    policy_identity = hash_file(policy_path)
    unsigned = PolicyAcceptanceReceipt(
        schema=POLICY_RECEIPT_SCHEMA,
        node_id=identity.node_id,
        public_identity=identity.public_identity,
        policy_version=policy_version,
        policy_sha256=policy_identity.sha256,
        agent_version=agent_version,
        acceptance_mode=acceptance_mode,
        accepted_at=_timestamp(accepted_at),
        signature="",
    )
    signature = _b64url_encode(identity.sign(unsigned.canonical_payload()))
    return replace(unsigned, signature=signature)


def verify_policy_receipt(
    receipt: PolicyAcceptanceReceipt,
    *,
    expected_policy_path: os.PathLike[str] | str | None = None,
    expected_policy_version: str | None = None,
) -> PolicyAcceptanceReceipt:
    if receipt.schema != POLICY_RECEIPT_SCHEMA:
        raise PolicyError("unsupported policy receipt schema")
    if not receipt.policy_version or not receipt.agent_version:
        raise PolicyError("policy receipt version fields must be non-empty")
    if receipt.acceptance_mode not in {"interactive", "non-interactive"}:
        raise PolicyError("unsupported policy acceptance mode")
    _validate_sha256(receipt.policy_sha256)
    _validate_timestamp(receipt.accepted_at)

    try:
        derived_node = derive_node_id(receipt.public_identity)
        if not hmac.compare_digest(derived_node, receipt.node_id):
            raise PolicyError("policy receipt node ID does not match public identity")
        verify_signature(
            receipt.public_identity,
            receipt.canonical_payload(),
            _b64url_decode(receipt.signature),
        )
    except IdentityError as exc:
        raise PolicyError(str(exc)) from exc

    if expected_policy_version is not None and not hmac.compare_digest(
        receipt.policy_version, expected_policy_version
    ):
        raise PolicyError("policy receipt version is not the required version")

    if expected_policy_path is not None:
        expected = hash_file(expected_policy_path).sha256
        if not hmac.compare_digest(receipt.policy_sha256, expected):
            raise PolicyError("policy receipt digest does not match required policy bytes")
    return receipt


def write_policy_receipt(
    path: os.PathLike[str] | str,
    receipt: PolicyAcceptanceReceipt,
) -> None:
    verify_policy_receipt(receipt)
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    parent_info = os.lstat(destination.parent)
    if stat.S_ISLNK(parent_info.st_mode) or not stat.S_ISDIR(parent_info.st_mode):
        raise PolicyError("policy receipt directory must be a real directory")
    if stat.S_IMODE(parent_info.st_mode) & 0o077:
        raise PolicyError("policy receipt directory must be owner-only")

    data = json.dumps(receipt.to_dict(), indent=2, sort_keys=True) + "\n"
    fd, tmp_name = tempfile.mkstemp(prefix="policy-receipt-", dir=destination.parent)
    tmp_path = Path(tmp_name)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8", closefd=True) as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(tmp_path, destination)
    finally:
        try:
            os.close(fd)
        except OSError:
            pass
        tmp_path.unlink(missing_ok=True)


def read_policy_receipt(path: os.PathLike[str] | str) -> PolicyAcceptanceReceipt:
    source = Path(path)
    info = os.lstat(source)
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        raise PolicyError("policy receipt must be a real regular file")
    try:
        value = json.loads(source.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PolicyError("policy receipt could not be read") from exc
    if not isinstance(value, dict):
        raise PolicyError("policy receipt must be a JSON object")
    receipt = PolicyAcceptanceReceipt.from_dict(value)
    return verify_policy_receipt(receipt)
