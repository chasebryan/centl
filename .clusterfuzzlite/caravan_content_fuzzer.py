#!/usr/bin/env python3
"""Coverage-guided fuzz target for CARAVAN content-addressing invariants.

The target intentionally imports ``caravan/content.py`` as a standalone module.
That file is the boundary under test and has no third-party runtime dependency;
loading the package initializer would import unrelated TUF catalog machinery and
would make this focused content fuzzer depend on code it does not exercise.
"""

from __future__ import annotations

import hashlib
import os
import sys
import tempfile

import atheris

with atheris.instrument_imports():
    from content import ArtifactIdentity, chunk_manifest, hash_file


def _check_identity(provider: atheris.FuzzedDataProvider) -> None:
    text = provider.ConsumeUnicodeNoSurrogates(160)
    length = provider.ConsumeIntInRange(0, 1 << 30)
    try:
        identity = ArtifactIdentity.parse(text, length)
    except (ValueError, TypeError):
        return

    if identity.length != length:
        raise RuntimeError("ArtifactIdentity changed the authenticated byte length")
    if identity.artifact_id != f"sha256:{identity.sha256}":
        raise RuntimeError("ArtifactIdentity produced a non-canonical artifact id")
    if len(identity.sha256) != 64 or any(
        byte not in "0123456789abcdef" for byte in identity.sha256
    ):
        raise RuntimeError("ArtifactIdentity accepted a non-canonical SHA-256 digest")


def _check_chunking(provider: atheris.FuzzedDataProvider) -> None:
    payload = provider.ConsumeBytes(16 * 1024)
    chunk_size = provider.ConsumeIntInRange(1, 4096)

    fd, name = tempfile.mkstemp(prefix="centl-caravan-fuzz-")
    try:
        with os.fdopen(fd, "wb", closefd=True) as stream:
            stream.write(payload)

        identity = hash_file(name)
        if identity.length != len(payload):
            raise RuntimeError("hash_file reported an incorrect artifact length")
        if identity.sha256 != hashlib.sha256(payload).hexdigest():
            raise RuntimeError("hash_file reported an incorrect artifact digest")

        records = chunk_manifest(name, chunk_size)
        offset = 0
        for record in records:
            record_offset = record["offset"]
            record_length = record["length"]
            digest = record["sha256"]
            if record_offset != offset:
                raise RuntimeError("chunk manifest contains a discontinuous offset")
            if not isinstance(record_length, int) or record_length <= 0:
                raise RuntimeError("chunk manifest contains an invalid chunk length")
            block = payload[offset : offset + record_length]
            if len(block) != record_length:
                raise RuntimeError("chunk manifest extends beyond the artifact")
            if digest != hashlib.sha256(block).hexdigest():
                raise RuntimeError("chunk manifest contains an incorrect chunk digest")
            offset += record_length
        if offset != len(payload):
            raise RuntimeError("chunk manifest does not cover the complete artifact")
    finally:
        try:
            os.unlink(name)
        except FileNotFoundError:
            pass


def test_one_input(data: bytes) -> None:
    provider = atheris.FuzzedDataProvider(data)
    _check_identity(provider)
    _check_chunking(provider)


def main() -> None:
    atheris.Setup(sys.argv, test_one_input)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
