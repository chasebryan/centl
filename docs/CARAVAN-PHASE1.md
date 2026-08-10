# CENTL CARAVAN Phase 1 laboratory profile

Status: **implemented local laboratory; not a public volunteer network protocol**.

CENTL CARAVAN is the **Content-Addressed Resilient Artifact Verification and Availability Network**. Phase 1 establishes the local, reproducible laboratory boundary required before any private pilot or public volunteer enrollment.

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

Carrier population affects availability only. Authenticated FCF/TUF metadata defines artifact identity and redistribution eligibility.

## Implemented trust boundary

Phase 1 uses `python-tuf` 7.0.0 with TUF 1.0 JSON metadata. The laboratory verifies the root -> timestamp -> snapshot -> targets chain around `caravan/catalog-v1.json`. The trusted bootstrap root is supplied independently of carriers. There is no trust-on-first-carrier mode.

Only `public-approved` artifacts may enter volunteer routing. `revoked` targets disable known identities; `pending-review` and `fcf-preservation-only` material cannot be advertised by volunteer carriers.

Whole-artifact identity is `sha256:<64 lowercase hexadecimal characters>` plus exact byte length. The authenticated chunk profile uses ordered, contiguous 4 MiB SHA-256 records, with a shorter final chunk permitted. Chunk verification supplements rather than replaces mandatory whole-file verification.

## Implemented carrier boundary

The laboratory provides:

- user-owned immutable content-addressed storage;
- source/store symlink rejection and regular-file enforcement;
- hash-while-copy verification and atomic no-overwrite promotion;
- storage ceiling and minimum free-disk reserve;
- Ed25519 pseudonymous carrier identities stored under owner-only permissions;
- signed policy-acceptance receipts binding exact policy SHA-256/version, agent version, acceptance mode, and UTC timestamp;
- SQLite coordinator state with fresh-heartbeat availability semantics;
- quarantine and withdrawal states;
- privacy-safe aggregate counts for available caravans, protected artifacts, and verified replicas;
- one-use, short-lived retrieval tickets bound to one carrier and artifact;
- live Ed25519 proof-of-possession carrier sessions;
- outbound-only carrier/coordinator HTTP transport for the loopback laboratory, with HTTPS required outside explicit loopback mode;
- exact request/response bounds and bounded laboratory long polling.

The normal carrier never needs a public listening port, router configuration, root, or sudo.

## Verified retrieval and fallback

Phase 1 now implements verified multi-carrier retrieval. A selected carrier receives only a ticket for the authenticated artifact identity. Received bytes are checked against ordered authenticated chunk records and the mandatory whole-artifact length and SHA-256 before promotion into the immutable store.

Malformed or hostile bytes are discarded. Truncation, appended bytes, chunk mismatch/reordering, and whole-file mismatch cannot be promoted. Integrity failure records the expected and observed digests without rewriting expected identity, quarantines the bad carrier, consumes the failed ticket, and automatically asks the coordinator for another eligible route. The dedicated test suite includes a bad-carrier -> good-carrier fallback proving this behavior.

## Join / status / leave lifecycle

The local lifecycle API provides explicit `join`, `status`, and `leave` operations. Join creates or loads a user-owned Ed25519 identity, records exact policy acceptance, and enrolls only after receipt verification. Leave withdraws the carrier, removes it from routing eligibility, and preserves local identity/state for explicit operator control.

Participation remains voluntary and reversible.

## One-command laboratory

From a source checkout with the pinned Phase 1 Python dependencies installed:

```text
PYTHONPATH=. python3 -m caravan.lab
```

The command constructs an owner-only temporary laboratory, creates two policy-accepted carriers, applies already-authenticated catalog data at the coordinator trust boundary, deliberately serves corrupted bytes from the preferred carrier, verifies that the bad carrier is quarantined, falls back to the second carrier, verifies and stores the exact artifact, reports aggregate network state, and cleans up temporary state.

The complete Phase 1 validation gate is:

```text
sh scripts/caravan-phase1-check
```

It compiles the laboratory modules, verifies exact dependency pins, runs storage/coordinator/identity/policy/TUF/session/transport/retrieval/lifecycle tests, hostile-transfer cases, and the one-command laboratory.

## Dependency security

Phase 1 pins PyCA `cryptography` 50.0.0. The earlier 49.0.0 selection was rejected after dependency review identified CVE-2026-69247. The vulnerability gate was fixed rather than suppressed.

## Public-network boundary

Phase 1 **does not authorize public volunteer enrollment**. It does not expose home carrier endpoints and it does not claim global anonymity.

A later private/pilot phase must still establish production TLS deployment, bounded concurrency and rate policy derived from measurement, reconnect/backoff behavior at deployment scale, credential revocation operations, finalized telemetry retention, abuse controls, legal/privacy review of host policy, default downloader privacy relay, website integration, and production operational monitoring.

Those are production-network gates, not reasons to keep the completed local laboratory out of the CENTL source tree.
