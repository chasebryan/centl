"""Verified multi-carrier retrieval for the CARAVAN Phase 1 laboratory.

Carrier availability may choose where bytes come from, but only authenticated
artifact identity and chunk metadata decide whether those bytes are accepted.
"""

from __future__ import annotations

from contextlib import closing
from dataclasses import dataclass
import hashlib
import os
from pathlib import Path
import tempfile
from typing import BinaryIO, Callable, Mapping, Sequence

from .catalog import ChunkRecord
from .content import DEFAULT_CHUNK_SIZE, ArtifactIdentity, ContentStore, IntegrityError
from .coordinator import CoordinatorError, CoordinatorState, RetrievalTicket


class RetrievalError(RuntimeError):
    """Raised when no eligible carrier can produce the authenticated artifact."""


class TransferIntegrityError(IntegrityError):
    """Integrity failure carrying a digest of the bytes observed so far."""

    def __init__(self, message: str, observed_digest: str) -> None:
        super().__init__(message)
        self.observed_digest = observed_digest


@dataclass(frozen=True, slots=True)
class RetrievalResult:
    identity: ArtifactIdentity
    node_id: str
    attempts: int
    stored_path: Path


CarrierFetcher = Callable[[RetrievalTicket], BinaryIO]


def _read_exact(stream: BinaryIO, length: int) -> bytes:
    remaining = length
    blocks: list[bytes] = []
    while remaining:
        block = stream.read(remaining)
        if not block:
            break
        blocks.append(block)
        remaining -= len(block)
    return b"".join(blocks)


def _validate_manifest(expected: ArtifactIdentity, chunks: Sequence[ChunkRecord]) -> None:
    if expected.length == 0:
        if chunks:
            raise RetrievalError("zero-length artifact must not contain chunks")
        return
    if not chunks:
        raise RetrievalError("non-empty authenticated artifact requires chunks")

    expected_offset = 0
    for index, chunk in enumerate(chunks):
        if chunk.offset != expected_offset:
            raise RetrievalError("authenticated chunk manifest is not contiguous and ordered")
        if chunk.length <= 0 or chunk.length > DEFAULT_CHUNK_SIZE:
            raise RetrievalError("authenticated chunk length exceeds CARAVAN Phase 1 limit")
        if index < len(chunks) - 1 and chunk.length != DEFAULT_CHUNK_SIZE:
            raise RetrievalError("all non-final authenticated chunks must be exactly 4 MiB")
        expected_offset += chunk.length
        if expected_offset > expected.length:
            raise RetrievalError("authenticated chunk manifest exceeds artifact length")

    if expected_offset != expected.length:
        raise RetrievalError("authenticated chunk manifest length does not match artifact")


def _verify_into_file(
    stream: BinaryIO,
    destination: BinaryIO,
    *,
    expected: ArtifactIdentity,
    chunks: Sequence[ChunkRecord],
) -> None:
    whole = hashlib.sha256()
    total = 0
    expected_offset = 0

    for chunk in chunks:
        if chunk.offset != expected_offset or chunk.length <= 0:
            raise RetrievalError("authenticated chunk manifest is not contiguous and ordered")
        block = _read_exact(stream, chunk.length)
        whole.update(block)
        total += len(block)
        if len(block) != chunk.length:
            raise TransferIntegrityError("carrier truncated an authenticated chunk", whole.hexdigest())
        observed_chunk = hashlib.sha256(block).hexdigest()
        if observed_chunk != chunk.sha256:
            raise TransferIntegrityError("carrier chunk SHA-256 mismatch", whole.hexdigest())
        destination.write(block)
        expected_offset += chunk.length

    if total != expected.length:
        raise TransferIntegrityError("carrier byte length does not match authenticated length", whole.hexdigest())

    extra = stream.read(1)
    if extra:
        whole.update(extra)
        raise TransferIntegrityError("carrier appended bytes after authenticated artifact", whole.hexdigest())

    observed_whole = whole.hexdigest()
    if observed_whole != expected.sha256:
        raise TransferIntegrityError("carrier whole-artifact SHA-256 mismatch", observed_whole)


def retrieve_verified(
    coordinator: CoordinatorState,
    store: ContentStore,
    *,
    expected: ArtifactIdentity,
    chunks: Sequence[ChunkRecord],
    fetchers: Mapping[str, CarrierFetcher],
    max_attempts: int = 2,
) -> RetrievalResult:
    """Retrieve an authenticated artifact and fall back after hostile bytes.

    Each attempt consumes a coordinator ticket bound to exactly one carrier and
    artifact. Integrity failure records the observed digest, quarantines that
    carrier, discards its bytes, and asks the coordinator for another eligible
    route. No observed carrier bytes can change ``expected``.
    """

    if max_attempts <= 0:
        raise ValueError("max_attempts must be positive")
    _validate_manifest(expected, chunks)

    # Enforce the same storage and free-space ceiling before creating the
    # retrieval temporary file. Import-time checks remain authoritative too,
    # but they are intentionally not the first capacity boundary.
    try:
        store.ensure_capacity(expected.length)
    except IntegrityError as exc:
        raise RetrievalError("authenticated artifact does not fit CARAVAN store limits") from exc

    last_error: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            ticket = coordinator.issue_ticket(expected.artifact_id)
        except CoordinatorError as exc:
            last_error = exc
            break

        fetcher = fetchers.get(ticket.node_id)
        if fetcher is None:
            raise RetrievalError(f"no laboratory fetcher configured for carrier {ticket.node_id}")

        coordinator.consume_ticket(
            ticket.token,
            node_id=ticket.node_id,
            artifact_id=expected.artifact_id,
        )

        fd, tmp_name = tempfile.mkstemp(prefix="retrieval-", dir=store.root / "tmp")
        tmp_path = Path(tmp_name)
        try:
            with os.fdopen(fd, "wb", closefd=True) as destination:
                with closing(fetcher(ticket)) as stream:
                    _verify_into_file(stream, destination, expected=expected, chunks=chunks)
                destination.flush()
                os.fsync(destination.fileno())
            identity = store.import_file(tmp_path, expected=expected)
            return RetrievalResult(
                identity=identity,
                node_id=ticket.node_id,
                attempts=attempt,
                stored_path=store.path_for_verified(identity),
            )
        except TransferIntegrityError as exc:
            last_error = exc
            coordinator.record_integrity_failure(
                ticket.node_id,
                expected.artifact_id,
                expected_digest=expected.sha256,
                observed_digest=exc.observed_digest,
                quarantine=True,
            )
        finally:
            try:
                tmp_path.unlink()
            except FileNotFoundError:
                pass
            try:
                os.close(fd)
            except OSError:
                pass

    if last_error is None:
        raise RetrievalError("CARAVAN retrieval exhausted without an eligible carrier")
    raise RetrievalError(f"CARAVAN retrieval failed after {max_attempts} attempts: {last_error}") from last_error
