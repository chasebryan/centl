# CENTL CARAVAN threat model

Status: **design document — implementation must not claim these properties until tested**.

This threat model defines the security boundary for CENTL CARAVAN, the proposed volunteer preservation and distribution network for CENTL/FCF public-approved artifacts.

## 1. Security objectives

CARAVAN should provide the following properties:

1. A malicious carrier cannot cause arbitrary bytes to be accepted as an approved artifact.
2. A corrupt carrier cannot silently alter one byte, truncate a file, append data, or substitute a different artifact without detection.
3. Carrier population or majority cannot redefine artifact identity.
4. A carrier cannot request or serve arbitrary host filesystem paths through the protocol.
5. A downloader using the default web path does not expose its direct network address to a volunteer carrier.
6. The public site does not disclose carrier home IP addresses, hostnames, usernames, or local paths.
7. A carrier can participate without root/sudo in the normal case and without opening a public inbound port.
8. A malicious downloader cannot cause unbounded disk, memory, CPU, file-descriptor, or bandwidth use on a carrier.
9. A compromised carrier does not compromise FCF signing keys or catalog authority.
10. Failure of the CARAVAN coordinator does not invalidate already-authenticated artifact identities held elsewhere.

## 2. Assets

Protected assets include:

- authenticated artifact catalog and trust metadata;
- FCF catalog/signing private keys;
- FCF release signing private keys;
- exact approved artifact digests and lengths;
- carrier node private identity keys;
- carrier filesystem outside the CARAVAN store;
- carrier bandwidth/storage limits;
- downloader network privacy relative to volunteer carriers;
- carrier network/location privacy relative to the public;
- FCF authoritative preservation copies;
- policy acceptance/version records;
- coordinator availability and routing state.

## 3. Trust boundaries

### Trusted or administratively controlled

- FCF root/catalog signing process;
- FCF publication process that decides `public-approved` eligibility;
- FCF primary/secondary preservation infrastructure;
- FCF privacy ingress/relay infrastructure, within its documented privacy scope;
- verified client/carrier code after authenticated installation.

### Explicitly untrusted

- volunteer carrier filesystem contents until verified;
- carrier operators;
- carrier network paths;
- downloader requests;
- the public Internet;
- DNS and ordinary network routing unless protected by the authenticated protocol layer;
- advertised carrier reputation, capacity, or possession claims;
- replica count as a trust signal;
- cached bytes before verification.

## 4. Adversaries

CARAVAN considers:

- a malicious volunteer carrier serving chosen bytes;
- many colluding/Sybil carriers;
- a carrier with silent disk corruption;
- a compromised carrier host;
- a malicious downloader attempting resource exhaustion or path attacks;
- a network attacker able to observe, block, replay, or modify traffic;
- a malicious or compromised relay;
- a malicious party submitting stale metadata;
- an attacker attempting downgrade to old catalog/agent/protocol state;
- an attacker attempting to discover carrier or downloader identities;
- an attacker attempting to use CARAVAN as arbitrary file hosting;
- an attacker attempting to poison availability/routing measurements;
- accidental administrator error.

## 5. Artifact substitution

### Threat

A carrier serves bytes different from the requested approved artifact.

### Controls

- exact authenticated artifact byte length;
- authenticated whole-file SHA-256;
- authenticated chunk manifest for streaming where enabled;
- release-specific signature verification where applicable;
- staging/quarantine until final verification;
- transparent retry from another carrier;
- carrier quarantine after policy-defined failures.

### Residual risk

Hash verification proves identity to the approved bytes. It does not prove those approved bytes are free of vulnerabilities or malicious logic. That is a publication/release-review concern.

## 6. Sybil and majority attacks

### Threat

An attacker creates many carriers and advertises an attacker-chosen digest.

### Control

Artifact identity comes only from authenticated FCF catalog metadata. Carrier count affects routing and availability only.

### Residual risk

A large Sybil population can still waste coordinator resources, distort apparent capacity, or reduce availability if selected. Routing health, rate limiting, identity cost controls, and FCF fallbacks address availability, not trust.

## 7. Freeze, rollback, and stale metadata

### Threat

An attacker prevents clients from seeing current catalog state or replays older valid metadata.

### Controls

The selected secure-update/TUF profile must provide version/freshness/expiration handling, trusted root rotation, and rollback/freeze protections appropriate to the implementation.

Clients must not accept metadata solely because a signature is valid if its version/freshness state is invalid.

## 8. Signing-key compromise

### Threat

An FCF catalog signing key is stolen.

### Controls

- separate long-lived root authority from routine online metadata signing where practical;
- documented rotation/revocation process;
- limited online key scope;
- preserve historical metadata and transition records;
- avoid storing catalog/release secret keys on volunteer carriers.

### Residual risk

Compromise of an authorized online catalog role may allow malicious metadata within that role's authority until detected/revoked. This is why carrier hashing alone cannot replace authenticated metadata governance.

## 9. Carrier filesystem escape

### Threat

A request causes a carrier to read outside its CARAVAN-managed store.

### Controls

- requests use content IDs, never arbitrary user paths;
- fixed internal content-addressed layout;
- reject traversal components and malformed IDs;
- no network-controlled symlink following;
- open/verify files using race-resistant filesystem operations;
- reject unsupported special files;
- run under unprivileged user UID;
- optional sandboxing/hardening after implementation selection.

## 10. TOCTOU artifact replacement

### Threat

A local attacker replaces a file after verification but before or during serving.

### Controls

Implementation should verify and serve from a stable file descriptor/object, use immutable content-store semantics, compare stat identity where appropriate, and avoid a verify-path-then-reopen-path sequence.

Whole-stream/chunk verification on relay/client side remains authoritative even if carrier local verification was bypassed.

## 11. Resource exhaustion

### Threats

A downloader or coordinator causes excessive carrier use through many requests, expensive ranges, connection floods, or storage replication demands.

### Controls

- per-node configured disk cap;
- minimum free-space reserve;
- upload bandwidth cap;
- optional monthly transfer cap;
- bounded concurrent streams;
- bounded queue lengths;
- request deadlines;
- authenticated retrieval tickets where used;
- no decompression of untrusted network payloads unless strictly bounded;
- coordinator/relay rate limiting;
- carrier may refuse replication.

Refusal due to limits is normal behavior, not misconduct.

## 12. Disk exhaustion

### Threat

Coordinator requests or malicious metadata cause carrier storage to fill.

### Controls

- carrier-local maximum storage is authoritative;
- reserve threshold prevents crossing minimum free disk;
- only authenticated `public-approved` catalog targets are eligible;
- bounded temporary staging space;
- atomic promotion only after verification;
- safe eviction policy for non-required replicas.

## 13. Network interception and modification

### Threat

An on-path attacker modifies carrier, relay, or catalog traffic.

### Controls

TLS protects transport authentication/confidentiality where applicable, but artifact acceptance still depends on authenticated metadata and content hashes. A TLS endpoint alone is not content authority.

## 14. Downloader privacy leakage

### Threat

A volunteer carrier learns the downloader's public IP address.

### Default control

The default website path goes through FCF privacy ingress/relay infrastructure. The browser/client does not receive a volunteer carrier endpoint and does not connect directly to it.

### Residual risk

FCF ingress sees downloader connection metadata. A global network observer may correlate traffic. CARAVAN must not advertise stronger anonymity than it actually implements.

## 15. Carrier privacy leakage

### Threat

The public learns home carrier IP addresses or host identity.

### Controls

- carriers make outbound connections;
- website does not expose carrier endpoints;
- aggregate health reporting only;
- pseudonymous node identifiers;
- minimal coordinator data retention;
- no public location/IP map.

### Residual risk

FCF infrastructure and network providers necessarily observe some carrier connection metadata.

## 16. Malicious relay

### Threat

A relay tampers with, drops, records, or selectively routes traffic.

### Controls

Artifact integrity does not trust the relay. Client/final verifier checks authenticated metadata, chunk hashes where used, whole-file SHA-256, and release authentication.

### Residual risk

A malicious relay can deny service and may observe metadata within its protocol role. Split-knowledge designs such as OHTTP may reduce metadata exposure for some request paths but do not solve global traffic analysis.

## 17. Coordinator compromise

### Threat

An attacker controls routing decisions.

### Controls

Coordinator selection cannot redefine artifact hash or authenticated catalog state. Clients/relays independently reject bytes that fail authenticated identity checks.

### Residual risk

A compromised coordinator can cause denial of service, route users to malicious-but-detectable carriers, reveal operational metadata available to it, or suppress healthy carriers. Recovery/replication of coordinator state and independent FCF fallback origins are required maturity goals.

## 18. Arbitrary-content abuse

### Threat

A user attempts to use CARAVAN as general public file hosting.

### Controls

Only authenticated catalog targets marked `public-approved` may be stored/advertised/served through the public CARAVAN protocol. Carrier-local files cannot become network-visible by path or by self-advertising an unapproved digest.

## 19. Licensing/provenance violation

### Threat

Internally preserved third-party material is accidentally distributed publicly.

### Controls

- explicit distribution class required;
- default deny when class absent;
- public catalog/export pipeline allowlists `public-approved` only;
- model/dependency provenance remains separate from byte identity;
- volunteer replication consumes only public catalog targets, not raw preservation mirror contents.

## 20. Malicious agent update

### Threat

A carrier is told to install a replacement CARAVAN binary.

### Controls

The agent is itself an authenticated FCF target. Network source is irrelevant to trust. Update verification must validate authenticated metadata and expected bytes before installation.

## 21. Policy spoofing

### Threat

A fake enrollment package displays altered terms or records acceptance of a policy the user never saw.

### Controls

- enrollment software itself is authenticated;
- policy document is versioned and hashed;
- local consent receipt records exact policy SHA-256/version;
- material policy changes require explicit re-acceptance according to policy rules;
- coordinator cannot silently rewrite local acceptance receipts.

## 22. Telemetry/privacy overcollection

### Threat

Operational logging becomes a long-lived database of downloader behavior or volunteer home-network details.

### Controls

- data-minimization schema defined before production;
- bounded retention periods;
- aggregate public reporting;
- debugging detail disabled by default or time-limited;
- no public raw connection logs;
- policy documents exactly what carrier/downloader metadata the FCF service sees.

## 23. Denial of service

CARAVAN cannot guarantee availability against all attacks. Required mitigations include multiple carriers, FCF fallback origins, bounded timeouts, failover, replica diversity, coordinator rate limits, and graceful handling of offline/sleeping laptop carriers.

Integrity failures must never cause fallback to weaker verification.

## 24. Compromised carrier host

If a carrier operating system is compromised, CARAVAN assumes its local node key and local cached data can be controlled by the attacker.

This must not expose FCF catalog/release secret keys because they are never provisioned to the carrier. Other participants still verify all bytes independently.

Carrier credentials therefore authorize participation, not artifact authorship.

## 25. Security invariants

The implementation and tests must preserve these invariants:

1. **No catalog entry, no public serving.**
2. **No `public-approved` class, no volunteer replication.**
3. **No authenticated expected digest, no acceptance.**
4. **Carrier identity never grants content-authority rights.**
5. **Routing state never modifies content identity.**
6. **Checksum/signature failure never rewrites expected metadata.**
7. **Network requests never become arbitrary filesystem paths.**
8. **Default browser download never reveals carrier endpoint.**
9. **Root/sudo is not required for the normal carrier path.**
10. **FCF primary preservation remains independent of volunteer availability.**

## 26. Mandatory hostile tests before public pilot

Before a public volunteer pilot, tests must demonstrate rejection of:

- one-byte mutation;
- wrong-but-same-size file;
- truncation;
- appended bytes;
- reordered chunks;
- duplicated/missing chunk;
- stale metadata;
- catalog rollback where the selected secure-update profile forbids it;
- unapproved digest advertisement;
- unapproved redistribution class;
- traversal path attempts;
- symlink escape;
- special-file injection;
- file replacement during verification/serving;
- invalid/expired retrieval ticket;
- replay where protocol state requires freshness;
- excessive concurrent streams;
- disk-cap violation;
- malformed length/range requests;
- malicious carrier failover;
- public disclosure of carrier endpoint through the normal website path.

## 27. Open design decisions

These items must be resolved before implementation is considered production-bound:

- exact TUF implementation/profile and role structure;
- exact catalog canonicalization/serialization;
- chunk size and manifest representation;
- carrier node identity/signature implementation;
- outbound reverse-transport choice;
- coordinator ticket format and replay controls;
- relay deployment model;
- telemetry schema and retention periods;
- quarantine thresholds/appeal/recovery policy;
- update rollback mechanics;
- browser/client final-verification location;
- whether stronger split-knowledge privacy is practical for large artifacts.
