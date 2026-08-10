# CENTL CARAVAN Phase 1 laboratory profile

Status: **implementation profile for the local laboratory; not a public network protocol**.

This document freezes the first implementation choices required to begin the
CARAVAN local laboratory described in `CARAVAN-ROLLOUT.md`. These choices are
intentionally conservative and may be revised before a public protocol version
is declared.

## 1. Governing invariant

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

The first implementation therefore separates three concerns:

1. authenticated catalog authority;
2. byte storage/transport;
3. coordinator availability/routing state.

Carrier count, reputation, or majority never rewrites an expected content hash.

## 2. Authenticated catalog profile

The Phase 1 secure-metadata implementation target is **python-tuf 7.0.0**, the
Python reference implementation of The Update Framework (TUF), using the TUF 1.0
metadata model and JSON wire format.

The carrier/downloader side needs verification only. Repository/key-generation
code is laboratory/FCF tooling and is not part of the normal volunteer runtime.
The initial trusted root must come from the authenticated CARAVAN agent/release
bootstrap rather than from a volunteer carrier.

CARAVAN-specific target metadata will carry a distribution classification. Only
`public-approved` targets are eligible for volunteer advertisement or routing.
`revoked`, `pending-review`, and `fcf-preservation-only` targets are not eligible.

The initial coordinator code already accepts only a catalog object that has
crossed an authentication boundary; direct carrier advertisements cannot create
catalog entries.

## 3. Content identity

Whole-artifact identity is:

```text
sha256:<64 lowercase hexadecimal characters>
```

The authenticated target also carries the exact byte length. Both length and
SHA-256 must match before an artifact is promoted into the content-addressed
store or released as a successful download.

SHA-256 is the existing CENTL integrity primitive; CARAVAN does not define a new
hash function.

## 4. Chunk profile

Phase 1 fixes the laboratory chunk size at **4 MiB (4,194,304 bytes)**.

Each chunk record contains:

```text
offset
length
sha256
```

The final chunk may be shorter. Chunk verification supplements rather than
replaces mandatory whole-artifact length and SHA-256 verification.

The canonical signed chunk-manifest serialization remains a later Phase 1 task;
the content-store implementation already emits deterministic ordered chunk
records for the verifier tests.

## 5. Content store

The local store is user-owned and requires no root privileges.

Initial layout:

```text
<store>/
  objects/
    sha256/
      <first-two-hex>/
        <full-sha256>
  tmp/
```

Properties implemented in the first foundation:

- source files must be regular files and symbolic-link sources are rejected;
- store directories may not be symbolic links;
- bytes are hashed while copied from an already-open source descriptor;
- promotion is same-filesystem and no-overwrite;
- stored objects are made read-only after promotion;
- an existing object is reverified instead of silently replaced;
- configurable maximum stored bytes are authoritative;
- configurable minimum free-disk reserve is authoritative;
- verification recomputes whole-file SHA-256 and length.

The store does not know whether content is legally or operationally approved.
That authority belongs to authenticated catalog metadata.

## 6. Carrier identity

The Phase 1 identity profile is **Ed25519** using a maintained cryptographic
implementation. The planned Python laboratory backend is PyCA `cryptography`
49.0.0.

The private key remains on the carrier. The coordinator receives a public key and
derived pseudonymous node identifier. A carrier identity is for authentication,
revocation, and abuse control; it is not a public user profile.

Identity generation/verification is the next implementation slice after the
content/coordinator foundation.

## 7. Coordinator state

The Phase 1 coordinator uses SQLite because it is available through the Python
standard library, transactional, and sufficient for a local/private pilot.

Coordinator state includes:

- authenticated eligible artifact IDs and lengths;
- catalog version;
- carrier pseudonymous identity;
- policy and agent versions;
- active/quarantined/withdrawn state;
- last heartbeat;
- coarse load/capacity;
- verified replica advertisements;
- short-lived retrieval tickets;
- integrity-failure records.

A catalog refresh may change routing eligibility, but carrier state cannot change
artifact identity.

## 8. Availability definition and website counters

The coordinator maintains exact internal counts. An **available caravan** is a
carrier that:

- is registered and active;
- is not quarantined or withdrawn;
- has a heartbeat inside the configured freshness window; and
- advertises at least one currently `public-approved` artifact.

The three network-health quantities are:

- **available caravans** — currently eligible carrier machines;
- **protected artifacts** — distinct `public-approved` artifact identities with
  at least one fresh eligible replica;
- **verified replicas** — total fresh eligible carrier/artifact replica pairs.

The public website will expose only privacy-safe aggregate forms of these values.
It must not expose node IDs, IP addresses, hostnames, precise locations, or raw
per-carrier uptime. During a very small pilot, public counts may be delayed or
bucketed to reduce trivial observation of a specific volunteer machine coming
online or going offline.

## 9. Presence

The laboratory default heartbeat freshness window is **45 seconds**. Presence is
leased state, not permanent membership. Stale carriers disappear from current
availability counts and route selection automatically.

Production values will be measured during the private pilot rather than inferred
from the laboratory default.

## 10. Retrieval authorization

Phase 1 uses coordinator-issued random bearer capabilities generated by the
operating system CSPRNG through Python `secrets`.

A retrieval ticket is:

- bound to one artifact ID;
- bound to one selected carrier;
- short-lived (30-second default);
- single-use;
- stored coordinator-side only as SHA-256 of the bearer token;
- rejected after expiry, replay, binding mismatch, quarantine, withdrawal, or
  heartbeat expiry.

This is authorization, not artifact authentication. The ticket cannot alter the
catalog digest.

## 11. Outbound transport

The Phase 1 network transport baseline is an outbound request/long-poll model that
works over ordinary HTTPS without a public carrier listening port. Laboratory
integration may run on loopback HTTP because it is not Internet-facing.

Before Phase 2, the transport must be TLS-protected and packet/log tests must
prove that the default carrier does not require inbound NAT/router configuration.
HTTP/2 or HTTP/3 multiplexing may replace the laboratory polling transport after
measurement without changing artifact trust semantics.

## 12. Resource policy

No coordinator instruction may override local carrier limits. The implementation
will expose at minimum:

- maximum storage bytes;
- minimum free-disk reserve;
- maximum upload concurrency;
- upload rate limit;
- optional active schedule;
- pause/leave controls.

The content foundation implements the first two limits. Network limits arrive
with the carrier transport slice.

## 13. Phase 1 implementation sequence

The authorized local-laboratory sequence is:

1. content-addressed immutable store and negative filesystem/integrity tests;
2. SQLite coordinator state, availability counters, quarantine and replay-safe
   retrieval tickets;
3. Ed25519 carrier identity and accepted-policy receipt;
4. python-tuf authenticated catalog and test repository;
5. outbound-only carrier/coordinator transport;
6. two-carrier verified retrieval with automatic fallback;
7. hostile carrier and malformed-transfer suite;
8. one-command local laboratory runner.

No public volunteer enrollment is authorized by this phase.
