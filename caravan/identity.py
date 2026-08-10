"""Pseudonymous Ed25519 carrier identity for the CARAVAN laboratory.

Carrier identity authenticates a volunteer node to CARAVAN infrastructure. It is
not an artifact-signing key and never changes which bytes are trusted.
"""

from __future__ import annotations

import base64
import hashlib
import os
from pathlib import Path
import stat

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)

PUBLIC_ID_PREFIX = "ed25519:"
NODE_ID_PREFIX = "caravan-node-v1:"
NODE_ID_DOMAIN = b"CENTL-CARAVAN-NODE-ID-v1\x00"
PRIVATE_KEY_NAME = "identity.pem"
PUBLIC_ID_NAME = "identity.pub"


class IdentityError(RuntimeError):
    """Raised when carrier identity state is invalid or unsafe."""


def _b64url_encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def _b64url_decode(text: str) -> bytes:
    try:
        padded = text + "=" * ((4 - len(text) % 4) % 4)
        return base64.urlsafe_b64decode(padded.encode("ascii"))
    except Exception as exc:
        raise IdentityError("invalid base64url carrier identity") from exc


def public_identity_from_key(public_key: Ed25519PublicKey) -> str:
    raw = public_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    return PUBLIC_ID_PREFIX + _b64url_encode(raw)


def public_key_from_identity(public_identity: str) -> Ed25519PublicKey:
    if not public_identity.startswith(PUBLIC_ID_PREFIX):
        raise IdentityError("carrier public identity must use ed25519:<base64url>")
    raw = _b64url_decode(public_identity[len(PUBLIC_ID_PREFIX) :])
    if len(raw) != 32:
        raise IdentityError("Ed25519 public identity must decode to exactly 32 bytes")
    try:
        return Ed25519PublicKey.from_public_bytes(raw)
    except ValueError as exc:
        raise IdentityError("invalid Ed25519 public key") from exc


def derive_node_id(public_identity: str) -> str:
    public_key = public_key_from_identity(public_identity)
    raw = public_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    digest = hashlib.sha256(NODE_ID_DOMAIN + raw).hexdigest()
    return NODE_ID_PREFIX + digest


def verify_signature(public_identity: str, payload: bytes, signature: bytes) -> None:
    try:
        public_key_from_identity(public_identity).verify(signature, payload)
    except InvalidSignature as exc:
        raise IdentityError("Ed25519 signature verification failed") from exc


def _require_private_directory(path: Path, *, create: bool) -> None:
    if path.exists() or path.is_symlink():
        info = os.lstat(path)
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISDIR(info.st_mode):
            raise IdentityError("carrier identity root must be a real directory")
        if stat.S_IMODE(info.st_mode) & 0o077:
            raise IdentityError("carrier identity root must not be accessible by group/other")
        return
    if not create:
        raise IdentityError("carrier identity root does not exist")
    path.mkdir(parents=True, mode=0o700)


def _write_exclusive(path: Path, data: bytes, mode: int) -> None:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(path, flags, mode)
    try:
        offset = 0
        while offset < len(data):
            written = os.write(fd, data[offset:])
            if written <= 0:
                raise IdentityError(f"failed writing carrier identity file: {path}")
            offset += written
        os.fsync(fd)
    finally:
        os.close(fd)


def _read_private_key(path: Path) -> Ed25519PrivateKey:
    info = os.lstat(path)
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        raise IdentityError("carrier private key must be a real regular file")
    if stat.S_IMODE(info.st_mode) & 0o077:
        raise IdentityError("carrier private key permissions must be owner-only")
    flags = os.O_RDONLY
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(path, flags)
    try:
        with os.fdopen(fd, "rb", closefd=True) as stream:
            data = stream.read()
    except Exception:
        try:
            os.close(fd)
        except OSError:
            pass
        raise
    try:
        key = serialization.load_pem_private_key(data, password=None)
    except (TypeError, ValueError) as exc:
        raise IdentityError("carrier private key could not be parsed") from exc
    if not isinstance(key, Ed25519PrivateKey):
        raise IdentityError("carrier private key is not Ed25519")
    return key


class CarrierIdentity:
    """User-owned, pseudonymous carrier identity stored without root privileges.

    The private key is intentionally unencrypted on disk because the carrier agent
    must authenticate unattended. The identity directory and private-key file are
    owner-only. Compromise of this key can impersonate a carrier until revocation,
    but cannot authorize artifacts or replace FCF catalog authority.
    """

    def __init__(self, root: Path, private_key: Ed25519PrivateKey) -> None:
        self.root = root
        self._private_key = private_key
        self.public_identity = public_identity_from_key(private_key.public_key())
        self.node_id = derive_node_id(self.public_identity)

    @classmethod
    def create(cls, root: os.PathLike[str] | str) -> "CarrierIdentity":
        root_path = Path(root)
        _require_private_directory(root_path, create=True)
        private_path = root_path / PRIVATE_KEY_NAME
        public_path = root_path / PUBLIC_ID_NAME
        if private_path.exists() or private_path.is_symlink() or public_path.exists() or public_path.is_symlink():
            raise IdentityError("carrier identity already exists")

        private_key = Ed25519PrivateKey.generate()
        private_bytes = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
        public_identity = public_identity_from_key(private_key.public_key())
        _write_exclusive(private_path, private_bytes, 0o600)
        try:
            _write_exclusive(public_path, (public_identity + "\n").encode("ascii"), 0o600)
        except Exception:
            private_path.unlink(missing_ok=True)
            raise
        return cls(root_path, private_key)

    @classmethod
    def load(cls, root: os.PathLike[str] | str) -> "CarrierIdentity":
        root_path = Path(root)
        _require_private_directory(root_path, create=False)
        private_key = _read_private_key(root_path / PRIVATE_KEY_NAME)
        identity = cls(root_path, private_key)
        public_path = root_path / PUBLIC_ID_NAME
        info = os.lstat(public_path)
        if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
            raise IdentityError("carrier public identity file must be a real regular file")
        recorded = public_path.read_text(encoding="ascii").strip()
        if recorded != identity.public_identity:
            raise IdentityError("carrier public identity file does not match private key")
        return identity

    def sign(self, payload: bytes) -> bytes:
        return self._private_key.sign(payload)
