# CENTL CARAVAN

**Content-Addressed Resilient Artifact Verification and Availability Network**

CARAVAN is the Free Computation Foundation's preservation and availability architecture for approved CENTL and FCF artifacts.

Its governing rule is:

> **A carrier may provide bytes, but a carrier may never define which bytes are trusted.**

CARAVAN separates **availability** from **authority**. Volunteer or FCF-operated carriers can help preserve and deliver exact artifact bytes, but authenticated FCF metadata defines which content identity is approved. Carrier count, popularity, or possession never turns unapproved bytes into trusted software.

## Current status

CARAVAN is no longer merely a design proposal.

**CENTL v0.14.0 includes the completed CARAVAN Phase 1 local laboratory in the source baseline.** That boundary establishes content-addressed storage, authenticated catalog consumption, carrier identity, proof of possession, policy receipts, bounded transfer behavior, verified retrieval, quarantine/fallback behavior, and reproducible local testing.

Main-line development contains later work for signed carrier joining, census, public-origin infrastructure, preservation missions, and rollout preparation.

**Public volunteer network enrollment is still gated.** The current signed join path may prepare and validate a carrier without silently activating public network service. Production enrollment, relay deployment, abuse operations, privacy/telemetry policy, and other rollout requirements must be satisfied deliberately rather than inferred from source-code presence.

Repository presence does not automatically expand the current Oasis release promise.

## Why CARAVAN exists

CENTL depends on more than its own source code. Releases, toolchains, numerical libraries, semantic artifacts, recovery material, and other critical resources can disappear upstream or become difficult to obtain.

FCF-controlled preservation copies reduce that risk, but concentrated storage still leaves a project dependent on a small number of machines and providers.

CARAVAN adds a distributed outer preservation layer in which ordinary GNU/Linux systems can contribute bounded resources without becoming content authorities.

The intended properties are:

- approved artifacts can exist on many independent machines;
- no carrier can redefine an artifact merely by serving different bytes;
- users do not have to trust a volunteer host personally;
- ordinary carriers remain rootless and outbound-only by default;
- storage and bandwidth are capped by the volunteer;
- participation is voluntary and reversible;
- arbitrary local files cannot be published through CARAVAN;
- FCF release and artifact authentication remains authoritative;
- preservation can survive the disappearance of an individual host or provider.

## FCF preservation doctrine

CARAVAN is one layer of the broader [Free Computation Foundation Preservation Plan](FCF-PRESERVATION-PLAN.md).

FCF preservation is intentionally broader than CENTL and broader than CARAVAN's current implementation. The Foundation's long-term preservation scope includes important free operating systems and kernels, development toolchains, historical source, documentation, books, manuals, specifications, boot and firmware projects, package ecosystems, and the reconstruction evidence required to make those materials useful in the future.

The initial strategic targets include **Linux, Linux-libre, Trisquel GNU/Linux, OpenBSD, FreeBSD, the GNU developer toolchain and foundational utilities, and FSF/GNU books and documentation under their applicable rights**, together with CENTL and the software required to build and recover it.

CARAVAN does not decide what deserves preservation. The authority path is:

```text
upstream artifact or corpus
          |
          v
FCF preservation admission
 provenance / rights / identity
          |
          v
FCF preservation catalog
     |               |
     |               +--> preservation-only holdings
     |
     +--> public-approved objects
                  |
                  v
               CARAVAN
        distributed availability
```

This separation keeps preservation curation, legal/redistribution decisions, and artifact authority out of the hands of individual carriers.

A preserved object may be retained by FCF without being eligible for public CARAVAN distribution. Public CARAVAN eligibility requires an explicit redistribution class and authenticated catalog membership. Possession alone never implies publication permission.

The preservation plan also distinguishes policy domains from implemented CARAVAN mission values. Future mission classes for systems, toolchains, knowledge, historical releases, or other preservation corpora must be introduced through a versioned protocol and rollout change rather than being implied by documentation before the software supports them.

## Joining CARAVAN is support

**Operating a CARAVAN carrier is itself a contribution to CENTL and the Free Computation Foundation.**

A participant contributes infrastructure rather than source code: bounded storage, bandwidth, availability, and geographic/provider diversity. That can help keep approved FCF material reachable even if an upstream project, mirror, account, or hosting provider disappears.

Money is therefore not the only way to support CENTL. A reliable machine with a modest amount of storage and network capacity can become useful project infrastructure once the relevant enrollment channel is opened.

Until public enrollment is enabled, users can still help by:

- testing the signed join and verification process;
- reviewing operator documentation and host policy;
- validating supported GNU/Linux environments;
- testing withdrawal, resource ceilings, and failure behavior;
- reviewing privacy, identity, and abuse boundaries;
- participating in local laboratory and reproducibility testing.

CARAVAN support never purchases or confers authority over FCF artifact identity.

## Trust model

CARAVAN uses a centrally governed trust/catalog plane with a distributed storage and serving plane.

### Artifact authority

An approved artifact is identified by authenticated metadata that binds properties such as:

- logical artifact identity;
- exact byte length;
- whole-file cryptographic digest;
- chunk layout and chunk identities where applicable;
- metadata version and freshness;
- redistribution status;
- release- or artifact-specific authentication material.

A carrier advertisement that does not correspond to an approved catalog target does not become trusted merely because the carrier possesses it.

### No trust by majority

If one authenticated FCF catalog authorizes digest A and ten thousand carriers advertise digest B, digest B is still wrong for CARAVAN purposes.

Carrier population affects availability only.

### Carriers are untrusted storage

A carrier can fail, lie, corrupt data, disappear, return stale material, or provide malformed transfers. CARAVAN must detect those conditions rather than reinterpret them as trust decisions.

Incorrect carrier bytes are rejected, the carrier may be quarantined, and retrieval can fall back to another eligible source.

## Content identity and verification

CARAVAN uses standard cryptographic primitives and maintained implementations rather than inventing a custom digest or signature scheme.

The Phase 1 architecture includes:

- exact whole-file SHA-256 identity;
- deterministic fixed-size chunk records;
- immutable content-addressed storage;
- integrity-checked object promotion;
- authenticated artifact catalogs;
- verified multi-carrier retrieval;
- automatic bad-carrier quarantine and fallback;
- explicit rejection of corruption, reordering, truncation, appended data, and malformed authenticated layouts.

A matching digest proves byte identity relative to the authenticated expected value. It does not prove that arbitrary software is semantically safe. Publication approval happens before distribution.

## Carrier identity

Ordinary carriers use pseudonymous cryptographic node identity for protocol authentication, proof of possession, revocation, health, and abuse control.

Carrier identity is not intended to become a public personal profile.

Ordinary public surfaces should not expose unnecessary host information such as:

- home IP addresses;
- hostnames;
- usernames;
- local filesystem paths;
- router details;
- unnecessary hardware fingerprints.

The coordinator may necessarily observe network metadata while accepting a connection. Policy must describe that reality plainly and minimize retention rather than claim impossible anonymity.

## Ordinary carrier boundary

The intended volunteer carrier is deliberately narrow.

It should:

- run as the user's ordinary account rather than root;
- open no inbound port by default;
- establish outbound authenticated connections;
- store content only beneath its dedicated CARAVAN storage root;
- enforce user-selected storage and bandwidth ceilings;
- maintain a minimum free-disk reserve;
- accept only authenticated content identities admitted by policy;
- support explicit credential rotation and withdrawal;
- avoid silent self-update;
- expose no arbitrary directory or home-directory content.

An ordinary carrier is **not** a proxy, VPN, shell gateway, general web host, generic object store, public Git host, or arbitrary file-sharing service.

## Preservation missions

The signed join architecture allows a volunteer to select preservation missions over authenticated `public-approved` catalog entries.

Current mission classes include:

| Mission | Purpose |
| --- | --- |
| `source` | Preserve approved CENTL source snapshots and source metadata |
| `releases` | Preserve signed FCF/CENTL release artifacts |
| `semantic` | Preserve redistribution-approved semantic artifacts |
| `recovery` | Preserve approved recovery/toolchain material |
| `all` | Participate in all eligible mission classes |

Mission selection is a filter over FCF-approved catalog content. It never grants a carrier authority to add an arbitrary URL, local file, digest, or unpublished artifact to the network.

Laboratory coverage and `centl caravan inspect` use the same first-path-segment
prefixes. They report which authenticated identities are held or
under-replicated. They do not join, enroll, or change the signed join
installer.

The broader FCF preservation domains do not automatically become protocol mission strings. That mapping must remain explicit and versioned as CARAVAN evolves.

## Redistribution classes

Not every preserved FCF artifact is eligible for volunteer distribution.

CARAVAN distinguishes at least:

- **public-approved**: eligible for public CARAVAN distribution;
- **fcf-preservation-only**: retained only under FCF-controlled preservation policy;
- **pending-review**: not distributable until provenance, licensing, or policy review is complete;
- **revoked**: no longer eligible for new retrievals and subject to the applicable withdrawal policy.

Absence of explicit public approval means **not eligible for volunteer distribution**.

This is especially important for third-party model weights, datasets, dependencies, books, manuals, standards, historical archives, and other artifacts whose right to possess or preserve may differ from the right to redistribute.

## Downloader privacy

The intended default public retrieval path should avoid exposing a downloader directly to a home carrier.

Conceptually:

```text
Downloader
    |
    v
FCF ingress / relay
    |
    v
CARAVAN route selection
    |
    v
Carrier
```

The public website should expose aggregate availability and verification state, not a directory of volunteer home-network endpoints.

Stronger privacy modes may evolve later, but CARAVAN must not claim anonymity properties that have not been implemented and demonstrated.

## Participation and withdrawal

Participation is voluntary.

A carrier must be able to stop participating, revoke or retire its credential as defined by the active protocol, stop new network work, and choose whether eligible cached data is retained or removed according to policy.

The coordinator never gains authority to exceed the resource ceilings chosen by the volunteer.

## What v0.14.0 does not claim

The v0.14.0 Oasis release does **not** claim:

- arbitrary public volunteer enrollment;
- a production global relay network;
- universal anonymity;
- public installation of CARAVAN as a standard `centl-*` command;
- that a content hash proves semantic safety;
- that volunteer carrier consensus defines trusted artifacts;
- that every FCF-preserved third-party artifact is redistributable.

Those distinctions are part of CARAVAN's security model, not disclaimers to be removed later for convenience.

## Documentation map

Start here, then use the document matching the task:

- [`FCF-PRESERVATION-PLAN.md`](FCF-PRESERVATION-PLAN.md): Foundation-wide preservation doctrine, scope, admission, verification, and recovery policy;
- [`FCF-DEPENDENCY-CHEST.md`](FCF-DEPENDENCY-CHEST.md): immutable dependency/recovery crates used by CENTL and related FCF systems;
- [`CARAVAN-PHASE1.md`](CARAVAN-PHASE1.md): admitted Phase 1 laboratory boundary;
- [`CARAVAN-JOIN-MANUAL.md`](CARAVAN-JOIN-MANUAL.md): manual carrier preparation and join procedure;
- [`CARAVAN-JOIN-RELEASE.md`](CARAVAN-JOIN-RELEASE.md): signed join-release contract;
- [`CARAVAN-HOST-POLICY.md`](CARAVAN-HOST-POLICY.md): volunteer host rules and consent boundary;
- [`CARAVAN-THREAT-MODEL.md`](CARAVAN-THREAT-MODEL.md): adversaries, assets, and trust boundaries;
- [`CARAVAN-IDENTITY.md`](CARAVAN-IDENTITY.md): carrier identity model;
- [`CARAVAN-CATALOG.md`](CARAVAN-CATALOG.md): authenticated artifact catalog model;
- [`CARAVAN-CENSUS.md`](CARAVAN-CENSUS.md): privacy-conscious carrier census design;
- [`CARAVAN-PUBLIC-ORIGIN.md`](CARAVAN-PUBLIC-ORIGIN.md): FCF-operated public-origin role;
- [`CARAVAN-ROLLOUT.md`](CARAVAN-ROLLOUT.md): gates between laboratory work and public deployment.

## Final invariant

CARAVAN exists to make FCF software and preservation-approved free-computing heritage harder to lose without making it easier to counterfeit or unlawfully redistribute.

> **Availability may be distributed. Authority remains explicit.**
