# CENTL CARAVAN

**Content-Addressed Resilient Artifact Verification and Availability Network**

Status: **design proposal only — not yet implemented or deployed**.

CARAVAN is the proposed volunteer preservation and distribution network for CENTL and the Free Computation Foundation (FCF). It is designed so that an ordinary Linux user can voluntarily contribute storage, bandwidth, and availability with a simple one-time enrollment workflow, while downloaders continue to use an ordinary FCF web interface and do not need to understand which preservation host supplied their bytes.

The governing rule is:

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

FCF-approved authenticated metadata defines acceptable artifact identity. Volunteer machines are deliberately treated as untrusted storage and transport.

CARAVAN must not invent cryptography. Standard SHA-256, maintained digital-signature tooling, TLS, and established secure-update concepts are used as defined by their standards and maintained implementations.

## 1. Purpose

CENTL already has FCF-controlled preservation mirrors, strict whole-mirror SHA-256 receipts, release preservation, no-network recovery, and host-neutral installers. Those mechanisms reduce upstream dependency, but preservation capacity would remain concentrated in a small number of FCF-controlled machines.

CARAVAN adds a voluntary outer layer:

- ordinary Linux machines may preserve approved CENTL material;
- a development laptop may participate immediately;
- later dedicated FCF hardware may participate without changing the protocol;
- carriers may be geographically and provider diverse;
- downloaders do not select or trust individual mirrors;
- corrupt or malicious carrier bytes never become authoritative merely because a carrier advertises them;
- normal privacy mode does not expose a downloader's network address to a volunteer carrier;
- normal carrier enrollment should require no root, sudo, public listening port, or router configuration.

CARAVAN is therefore a **decentralized storage and serving plane with a centrally governed trust/catalog plane**. The coordinator chooses where to retrieve already-approved content; it does not create trust merely by choosing a carrier.

## 2. Terminology

- **artifact** — one immutable file approved for CARAVAN distribution.
- **cargo** — informal name for one or more approved artifacts.
- **carrier** — a volunteer host running the CARAVAN node software.
- **coordinator** — the FCF service that maintains availability state and selects retrieval routes.
- **catalog** — authenticated metadata defining approved artifact identities and policy.
- **relay** — a privacy-preserving transport hop between downloader-facing infrastructure and a carrier.
- **quarantine** — state in which a carrier is excluded from retrieval selection after integrity, abuse, or protocol failures.

The playful terminology must never replace precise protocol names in logs, receipts, or security decisions.

## 3. Non-goals

CARAVAN is not:

- a blockchain;
- a cryptocurrency or incentive token;
- a peer-majority voting system;
- a replacement for FCF primary and secondary preservation copies;
- a mechanism for making unreviewed third-party material publicly redistributable;
- proof that software is semantically safe merely because its hash matches;
- a reason to weaken CENTL release signing, source review, licensing review, or build validation;
- an anonymity network claiming protection against every traffic-analysis or global-observer threat.

## 4. Trust model

### 4.1 Carriers are untrusted

A carrier may claim only that it currently possesses bytes for a given content identifier. It may not define that identifier as an approved CENTL artifact.

The authoritative artifact description comes from FCF-approved authenticated metadata and includes at minimum:

- logical artifact name;
- version or immutable publication identity;
- exact byte length;
- whole-file SHA-256;
- redistribution class/status;
- metadata version;
- freshness/expiration information where applicable.

A carrier advertisement that does not correspond to an approved catalog target is ignored.

### 4.2 Integrity and authentication remain separate

CARAVAN extends CENTL's existing distinction:

- **integrity** — bytes match a trusted SHA-256 value;
- **authentication** — trusted metadata is authenticated by an FCF-controlled signing identity.

For published CENTL releases, existing release authentication remains authoritative. CARAVAN may transport release archives and their authentication material, but may not replace those checks with carrier reputation.

### 4.3 No trust-by-majority

If 10,000 carriers advertise one digest and the authenticated FCF catalog authorizes another, the 10,000 carriers are wrong for CARAVAN purposes.

Carrier count affects availability, not artifact identity. This prevents Sybil population from becoming a content-authority mechanism.

## 5. Secure catalog

CARAVAN should adopt maintained implementations and concepts from The Update Framework (TUF) rather than inventing a new secure-update signature scheme. TUF is designed around authenticated metadata for targets, hashes, lengths, versions, freshness, key roles, and low-trust mirrors.

Production planning must select a maintained implementation and explicit metadata profile before code is promoted beyond laboratory status.

Reference: <https://theupdateframework.github.io/specification/>

The production design should separate long-lived root trust from routine online catalog freshness/availability operations to a degree appropriate for the project scale.

## 6. Content addressing and byte verification

The phrase "verify every byte" has a precise meaning: every accepted artifact byte participates in cryptographic identity verification against authenticated metadata.

### 6.1 Whole-artifact verification

Every artifact has a mandatory whole-file SHA-256 and exact byte length.

Acceptance requires:

1. expected length matches;
2. computed whole-file SHA-256 matches the authenticated catalog;
3. any artifact-specific CENTL/FCF release authentication checks pass.

No artifact is promoted into an executable/installable location before these checks pass.

### 6.2 Verified streaming chunks

Large files should additionally receive a deterministic chunk manifest generated by the trusted publication pipeline. The initial design uses fixed-size chunks and standard SHA-256 for each chunk. Chunk size and canonical serialization are protocol-profile decisions and must be frozen before implementation.

The chunk manifest is itself covered by authenticated catalog metadata.

A relay or client can then:

1. buffer one chunk from a carrier;
2. verify chunk length and SHA-256;
3. release only a verified chunk downstream;
4. reject and retry another carrier on mismatch;
5. still verify the mandatory whole-artifact SHA-256 at completion.

CARAVAN does not define a new digest or a "CARAVAN hash."

## 7. What "non-malicious" means

A network cannot prove arbitrary software is harmless merely by hashing it. A SHA-256 match proves byte identity relative to the authenticated expected value.

CARAVAN therefore makes the narrower defensible claim:

> The delivered bytes are exactly the FCF-approved artifact bytes identified by authenticated metadata.

Whether those approved bytes are appropriate to publish is decided before CARAVAN distribution by CENTL's release, provenance, licensing, testing, and review processes.

A carrier cannot cause arbitrary content to become "safe" by serving it successfully.

## 8. Redistribution classes

Not everything in an FCF preservation mirror is eligible for volunteer distribution.

Every candidate artifact must have an explicit distribution class:

- **public-approved** — may be served by CARAVAN carriers and downloaded publicly;
- **fcf-preservation-only** — may exist in FCF-controlled preservation storage but not on volunteer carriers;
- **pending-review** — no CARAVAN distribution until provenance/license/policy review completes;
- **revoked** — no new CARAVAN retrievals; carriers are instructed to stop advertising and may be instructed to delete local copies according to policy.

Absence of `public-approved` means **not eligible**.

This is especially important for model weights, datasets, dependencies, and other third-party material whose redistribution rights may differ from rights to use or preserve them internally.

## 9. Carrier enrollment

The intended experience is one run, one decision, then automatic operation.

A future canonical interface may be:

```text
centl-caravan join
```

The exact installer must itself be authenticated through the normal FCF distribution trust path. An unauthenticated `curl | sh` pipeline should not be the canonical security story.

### 9.1 No-root default

Normal Linux installation should use only the user's home directory, for example:

```text
~/.local/bin/centl-caravan
~/.local/share/centl/caravan/
~/.config/centl/caravan/
~/.cache/centl/caravan/
~/.config/systemd/user/
```

The carrier should:

- bind no privileged port;
- require no firewall changes;
- require no router/NAT configuration;
- establish outbound authenticated connections to CARAVAN infrastructure;
- run under the invoking user's UID;
- access only its configured storage root;
- use a systemd user service where available.

Persistent operation after logout is not universally possible without system policy support on every Linux distribution. CARAVAN must detect that condition and degrade cleanly to session-only operation rather than silently requesting sudo.

### 9.2 Resource defaults

Enrollment starts with conservative, visible caps:

- maximum storage;
- maximum upload rate;
- optional monthly transfer cap;
- optional active hours;
- minimum free-disk reserve;
- selectable eligible artifact classes where policy permits.

The coordinator never gets authority to fill a user's disk beyond configured limits.

### 9.3 Withdrawal

One simple command must:

- stop participation;
- unregister/revoke the carrier credential;
- stop the user service;
- prevent new network requests;
- offer a clear choice to retain or delete cached CARAVAN data.

Participation is voluntary and reversible.

## 10. Carrier identity and privacy

Carrier identity exists for protocol authentication, health tracking, abuse control, and revocation. It is not a public personal profile.

The implementation should generate a local asymmetric node identity using a standard maintained cryptographic implementation. The private key remains on the carrier.

The public website must not expose:

- carrier IP addresses;
- home network information;
- hostnames;
- filesystem paths;
- usernames;
- unnecessary hardware fingerprints.

The coordinator will necessarily observe network metadata from a carrier connecting directly to it. Policy must state this plainly and define minimal retention rather than claim impossible anonymity.

## 11. Outbound-only carrier transport

A core design goal is NAT-friendly hosting without root.

A carrier opens an outbound long-lived authenticated connection to one or more CARAVAN ingress services. The connection may be multiplexed so the coordinator/relay can request approved content without requiring the carrier to listen publicly on its router.

The implementation may use maintained TLS-protected HTTP/2, HTTP/3/QUIC, or WebSocket-style reverse transport. The exact protocol is a later design gate and must be benchmarked and documented before production.

The carrier never accepts arbitrary filesystem paths from the network. Requests are content-ID based and resolve only inside the agent-managed content store.

## 12. Downloader privacy

### 12.1 Default website path

The default website download path must not directly connect a downloader to a home carrier.

```text
Downloader
    |
    v
FCF privacy ingress / relay
    |
    v
CARAVAN selected route
    |
    v
Volunteer carrier
```

The carrier sees the relay/ingress connection, not the downloader's direct network address. The website does not expose carrier endpoints to the browser.

### 12.2 Provider privacy

The public site shows aggregate availability, not a directory of home IP addresses. A carrier is represented internally by a pseudonymous node identity and health state.

FCF infrastructure still sees connection metadata from participating carriers. The privacy policy must define what is collected, why, and for how long.

### 12.3 Stronger split-knowledge privacy

A later privacy tier may separate the party that sees the downloader's source network address from the party that sees plaintext request content. Oblivious HTTP (RFC 9458) provides an established relay/gateway model worth evaluating rather than inventing custom privacy cryptography.

Reference: <https://www.rfc-editor.org/rfc/rfc9458.html>

Large artifact delivery has different performance characteristics from many OHTTP use cases, so production use must be measured rather than assumed.

CARAVAN must not claim protection against global traffic correlation unless a future implementation establishes that property.

### 12.4 Optional direct mode

A future advanced user may explicitly opt into direct carrier retrieval for maximum throughput. Such a mode must warn that the selected carrier may observe the downloader's source network address.

Direct mode is never the website default.

## 13. Coordinator responsibilities

The coordinator is a decision service, not a byte-trust oracle.

It maintains:

- current authenticated catalog version;
- carrier availability advertisements;
- recent health probes;
- current load/capacity data;
- artifact replica count;
- recent integrity failures;
- route/privacy eligibility;
- quarantine state.

For a requested artifact, the coordinator selects a carrier or fallback set using factors such as:

- claimed possession of the exact authenticated artifact digest;
- recent successful health verification;
- current load;
- available bandwidth;
- route latency;
- geographic/provider diversity where useful;
- privacy-path availability;
- previous integrity/protocol failures.

No routing score may alter the expected artifact SHA-256.

## 14. Retrieval flow

The intended website experience is:

1. user opens the FCF/CENTL downloads page;
2. user selects the desired version/material;
3. website requests resolution from the coordinator;
4. coordinator selects an eligible route automatically;
5. relay requests only the authenticated content ID from the carrier;
6. bytes are verified chunk-by-chunk before release through the relay path;
7. the complete artifact is verified against whole-file length and SHA-256;
8. release-specific signature/authentication verification runs where applicable;
9. user receives the requested ordinary file;
10. failures transparently retry another eligible carrier when possible.

The user does not need to understand carrier selection.

An optional technical-details panel may show artifact SHA-256, catalog version, verification result, and that CARAVAN supplied the file. It must not expose volunteer private network details.

## 15. Carrier failures and malicious behavior

A carrier mismatch is treated as hostile-storage behavior until explained. Metadata is never rewritten to make the peer pass.

On chunk or whole-file mismatch:

1. discard untrusted bytes;
2. record expected and computed digests internally;
3. never expose the corrupt artifact as successful;
4. reduce or suspend the carrier's eligibility;
5. retry another carrier;
6. quarantine according to policy for severe/repeated failures;
7. investigate separately whether cause was corruption, operator modification, implementation error, or malicious behavior.

A carrier may also claim content and then refuse/fail to serve it. That is an availability failure, not an integrity ambiguity.

Mitigations include bounded deadlines, health probes, fallback carrier sets, replica diversity, health decay, and FCF-owned fallback origins for critical releases.

## 16. Agent updates

The CARAVAN agent is security-sensitive. Agent updates are authenticated FCF artifacts and must not trust an update merely because CARAVAN served it.

A carrier may receive an update through CARAVAN, but installation occurs only after authenticated metadata and SHA-256 verification.

Automatic updates, if enabled later, require a documented rollback and recovery path.

## 17. Consent and policy acceptance

Enrollment should remain simple, but merely executing a binary is not sufficient evidence of deliberate policy acceptance.

First run should:

1. display a concise human-readable summary;
2. identify the exact policy version;
3. provide the full policy locally and by FCF publication reference;
4. require explicit affirmative action or an explicit non-interactive acceptance flag;
5. record a local consent receipt containing policy version, policy SHA-256, acceptance time, and local carrier identity;
6. send only the minimal acceptance record required by the coordinator;
7. continue immediately into safe-default configuration.

The production policy/terms must receive appropriate legal/policy review for the jurisdictions in which FCF operates. This technical design does not claim that any particular acceptance mechanism is legally sufficient everywhere.

See `docs/CARAVAN-HOST-POLICY.md`.

## 18. Data minimization

Coordinator records should be limited to what is needed for:

- node authentication;
- policy-version acceptance;
- artifact availability;
- coarse capacity/load;
- integrity failures;
- abuse/rate limiting;
- bounded protocol debugging.

CARAVAN should avoid permanent downloader request histories tied to individuals. Detailed diagnostic logging should be disabled by default or tightly retention-bounded.

## 19. Suggested protocol objects

This section is descriptive, not a frozen wire format.

### 19.1 Artifact identity

```text
artifact_id = sha256:<64 lowercase hexadecimal characters>
```

The identifier refers to whole-file digest and is paired with authenticated byte length and catalog metadata.

### 19.2 Carrier advertisement

Conceptually:

```text
node identity
catalog version
approved artifact IDs held
capacity/load
agent protocol version
expiry/heartbeat time
node authentication proof
```

Advertisements expire. Stale presence is not availability.

### 19.3 Retrieval ticket

The coordinator may issue a short-lived ticket binding:

```text
requested artifact_id
expected byte length
catalog version
selected route/carrier
privacy mode
expiry
nonce/request identity
```

A ticket authorizes retrieval; it does not redefine artifact identity.

### 19.4 Chunk manifest

Conceptually:

```text
artifact whole SHA-256
artifact length
chunk size
ordered [offset, length, sha256] entries
```

Canonical serialization is a pre-implementation design decision.

## 20. Carrier storage

Carrier storage is content-addressed and immutable from the network's point of view.

Recommended logical layout:

```text
store/
  sha256/
    ab/
      <full-sha256>/artifact
      <full-sha256>/metadata
```

The implementation must defend against:

- path traversal;
- symlink escape;
- special-file injection;
- replacement of an open file during verification;
- unbounded sparse-file allocation;
- disk exhaustion;
- archive/decompression bombs if archive inspection is ever performed.

Network requests select an authenticated artifact ID, never an arbitrary filesystem path.

## 21. Replication

The coordinator may request additional replicas when approved artifacts fall below desired availability.

A carrier may refuse because of local limits. Refusal is not misconduct.

Replication decisions should prefer diversity rather than repeatedly filling one provider/network region.

FCF-owned primary preservation remains outside volunteer replica counts.

## 22. Website behavior

The public downloads page remains ordinary:

- human-meaningful artifact name/version;
- one normal download action;
- CARAVAN resolution behind the page;
- FCF-owned fallback when no eligible carrier is available;
- clear error only after automated fallback paths are exhausted;
- optional verification details for technical users.

A public CARAVAN health page may show aggregate healthy carrier count, public-approved replica count, aggregate contributed capacity, artifact availability, and protocol-version distribution. It must not become a directory of private home-host addresses.

## 23. Development laptop and future dedicated host

A development laptop is a valid initial carrier. The design must tolerate:

- intermittent connectivity;
- changing IP addresses;
- NAT;
- sleep/resume;
- limited disk budgets;
- user-session service management.

A future dedicated preservation desktop can run the same agent with larger resource limits and longer uptime. No dedicated-hardware assumption belongs in the protocol.

## 24. Relationship to FCF-owned preservation

CARAVAN supplements but does not replace FCF-owned preservation.

FCF should still maintain:

- an authoritative primary preservation mirror;
- at least one independent FCF-controlled second copy;
- strict whole-mirror receipts;
- tested no-network recovery;
- authenticated release metadata and key continuity.

Volunteer replicas are additional availability and conservation capacity. They are never the only source of truth.

## 25. Implementation gate

No CARAVAN production implementation should begin until the following documents are reviewed together:

- this architecture document;
- `CARAVAN-THREAT-MODEL.md`;
- `CARAVAN-HOST-POLICY.md`;
- `CARAVAN-ROLLOUT.md`.

The first implementation milestone is deliberately a local laboratory, not a public volunteer network.
