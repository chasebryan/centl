# CENTL CARAVAN volunteer host policy

Status: **initial FCF policy-content draft for design review; not yet effective terms and not legal advice**.

This document defines the intended operational agreement between the Free Computation Foundation (FCF) and a person who voluntarily operates a CENTL CARAVAN carrier.

The production form must be reviewed for applicable legal, privacy, consumer, ISP, hosting-provider, export, and redistribution requirements before public enrollment is enabled.

## 1. Purpose

CARAVAN allows volunteers to contribute a bounded portion of their machine's storage, bandwidth, and availability to preserve and deliver FCF-approved public CENTL artifacts.

Participation is optional. CARAVAN is designed to be easy to join, easy to limit, and easy to leave.

## 2. What a carrier does

A participating machine may:

- download authenticated public-approved artifacts;
- retain verified local replicas within the configured CARAVAN storage limit;
- advertise possession of approved content identifiers to FCF CARAVAN infrastructure;
- respond to authenticated retrieval requests through the configured CARAVAN transport;
- upload approved artifact bytes within configured bandwidth and schedule limits;
- receive catalog, revocation, health, and software-update metadata;
- perform local integrity verification and health checks.

A carrier is not authorized to publish arbitrary files through CARAVAN.

## 3. What a carrier does not become

Participation does not make the operator:

- an FCF employee, contractor, partner, or legal representative;
- a maintainer or release authority;
- an artifact-signing authority;
- a source of truth for which bytes constitute CENTL;
- entitled to payment, reimbursement, sponsorship, or compensation unless FCF separately establishes such a program in writing.

## 4. Content authority

FCF-authenticated catalog metadata defines which artifacts are eligible for CARAVAN distribution and the exact expected byte identities.

A volunteer host cannot authorize new public content merely by placing it in local storage or advertising a digest.

Only artifacts explicitly marked `public-approved` may enter volunteer replication.

## 5. Voluntary resource contribution

The operator chooses to contribute some amount of local resources. The CARAVAN software must expose configurable limits including, as supported by the implementation:

- maximum storage;
- upload bandwidth limit;
- optional transfer allowance;
- active hours;
- minimum free-disk reserve;
- participation pause/disable control.

Local configured limits are authoritative. FCF infrastructure must not bypass them.

The operator is responsible for understanding whether use of their Internet connection, device, employer/school network, cloud account, hosting plan, ISP plan, or electricity is permitted and acceptable to them.

## 6. No root requirement in the normal design

The normal CARAVAN Linux carrier is intended to operate under the participating user's account without root or sudo, public inbound ports, or router changes.

Some operating systems or environments may require administrator configuration for optional always-on behavior. Such behavior must be clearly separated from the default enrollment and must never be silently elevated.

## 7. Network use

Participation may consume outbound and upload bandwidth. Actual use depends on artifact demand, carrier availability, configured limits, and coordinator selection.

The software must provide a visible way to inspect current participation state and configured resource limits.

FCF does not promise a particular amount of traffic, uptime, or utilization.

## 8. Storage behavior

CARAVAN stores only eligible content and protocol metadata inside its configured storage root.

The carrier software must not intentionally expose unrelated user files.

The operator may choose to retain or delete cached CARAVAN content when leaving the network, subject to the implemented withdrawal workflow.

## 9. Privacy: carrier operator

The public CARAVAN website must not intentionally publish a volunteer carrier's:

- IP address;
- hostname;
- local username;
- filesystem path;
- home address;
- precise location;
- unnecessary hardware fingerprint.

FCF infrastructure will necessarily receive some connection metadata when a carrier connects to it, such as source network address and protocol timing information. Production policy must state the final telemetry fields and retention periods precisely.

Carrier identity should be pseudonymous at the protocol level wherever practical.

## 10. Privacy: downloader

In the default website mode, volunteer carriers should receive requests through FCF relay/ingress infrastructure rather than directly from the downloader.

This is intended to keep the downloader's direct network address from the volunteer carrier.

This policy must not be represented as global anonymity. FCF infrastructure and network providers may still observe connection metadata, and traffic-analysis risks may remain.

## 11. Security and integrity

Carrier operators agree not to intentionally:

- alter CARAVAN software to misrepresent possession or integrity state to the network;
- serve knowingly modified bytes under an approved artifact identifier;
- bypass local integrity checks in order to poison the network;
- attempt to obtain or expose FCF secret signing material;
- interfere with other carriers or downloaders;
- use CARAVAN as a denial-of-service mechanism;
- attempt to make arbitrary non-approved files publicly retrievable through CARAVAN.

FCF may quarantine or revoke a carrier credential after integrity, abuse, protocol, or policy failures.

Quarantine/revocation changes routing eligibility; it does not authorize FCF to access unrelated files on the operator's machine.

## 12. Artifact revocation

FCF may mark a previously distributed artifact as revoked for security, legal, licensing, provenance, or operational reasons.

A revoked artifact must stop being advertised and served through CARAVAN when the carrier receives authenticated revocation/catalog state.

Production policy must specify whether revoked cached bytes are automatically deleted, retained locally but disabled, or require a specific operator choice for each revocation class.

Until that behavior is finalized, the conservative design is: **stop serving immediately; do not silently erase local data unless the accepted policy explicitly authorizes that behavior.**

## 13. Software updates

CARAVAN may offer authenticated software updates.

An update must itself pass FCF authentication and integrity checks. The fact that another carrier supplied the bytes does not make the update trusted.

Production enrollment must state whether security updates are automatic, prompted, or configurable.

A material change to participation behavior or privacy policy must not be hidden inside a routine software update.

## 14. Telemetry

Production CARAVAN should collect only data needed for:

- carrier authentication;
- availability/health;
- resource/load routing;
- artifact replica state;
- integrity/security events;
- abuse/rate limiting;
- policy acceptance/versioning;
- bounded operational diagnostics.

The final data schema and retention periods must be published before public enrollment.

The public site should expose aggregate network health rather than raw carrier records.

## 15. No guarantee of service

CARAVAN is an experimental/community preservation and availability service. FCF does not promise uninterrupted operation, permanent availability of every artifact, minimum utilization of a volunteer carrier, or compatibility with every Linux environment.

FCF-controlled preservation remains the authoritative resilience layer; volunteer participation supplements it.

## 16. Operator responsibility

The operator remains responsible for their own machine, network, account, electricity, and compliance with restrictions that apply to them.

A user should not enroll a machine they do not have authority to use for this purpose.

The production terms should make any required jurisdiction-specific limitations explicit after review.

## 17. Withdrawal

The operator may leave CARAVAN at any time using the supported withdrawal command.

Withdrawal should:

1. stop new carrier service;
2. unregister or revoke the active carrier credential;
3. stop/disable the user service;
4. stop advertisements and retrieval handling;
5. offer a clear retain/delete choice for cached CARAVAN data.

FCF should cease selecting the carrier after withdrawal state reaches the coordinator.

Network propagation is not literally instantaneous; the implementation should use short-lived presence/tickets so stale authorization expires quickly.

## 18. Suspension and revocation by FCF

FCF may suspend or revoke carrier participation for reasons including:

- repeated content-integrity failures;
- protocol abuse;
- denial-of-service behavior;
- use of a compromised/revoked carrier credential;
- attempts to serve unapproved content;
- materially obsolete/insecure protocol versions;
- violation of the accepted carrier policy.

Where practical, operator-facing tooling should explain the suspension state without exposing sensitive abuse-detection details.

## 19. Policy versioning

Every effective carrier policy must have:

- a stable policy version identifier;
- publication date;
- canonical bytes;
- SHA-256 digest;
- a classification of changes from the previous version.

Minor editorial corrections that do not change participation behavior may be handled without re-acceptance if production policy explicitly defines that rule.

Material changes require re-acceptance before continued participation. Material changes include, at minimum, changes to:

- data collected or retained;
- public/private network exposure;
- resource-use authority;
- automatic deletion behavior;
- software-update authority;
- operator obligations;
- compensation terms;
- legal/redistribution scope.

## 20. Enrollment acceptance

CARAVAN should remain a one-run enrollment experience, but acceptance must be explicit.

Interactive enrollment should show a concise summary and require a clear affirmative action tied to the exact policy version.

Conceptual interaction:

```text
CENTL CARAVAN volunteer hosting
Policy: FCF-CARAVAN-HOST-v1
SHA-256: <policy digest>

You are choosing to provide bounded storage and upload bandwidth for
FCF-approved public CENTL artifacts. Participation is voluntary and can be
stopped at any time. Your configured limits remain authoritative.

Type ACCEPT to join, or anything else to exit:
```

Non-interactive automation may use an explicit flag that includes the exact policy version, for example:

```text
centl-caravan join --accept-policy FCF-CARAVAN-HOST-v1
```

The production syntax is not yet frozen.

Mere launch of the executable is not considered acceptance.

## 21. Consent receipt

After explicit acceptance, the agent should create a local receipt containing at least:

```text
policy version
policy SHA-256
acceptance timestamp
carrier public identity/fingerprint
agent version
acceptance mode (interactive/non-interactive)
```

The local receipt should be readable by the operator.

The coordinator should receive only the minimal record necessary to prove which policy version the carrier declared acceptance of. It does not need the user's legal name merely to operate a pseudonymous carrier.

## 22. No hidden acceptance

CARAVAN must not treat any of the following as policy acceptance by itself:

- package download;
- website visit;
- binary execution before the acceptance prompt;
- existence of an old carrier cache;
- receiving a network request;
- passive software update.

## 23. Incident handling

If CARAVAN detects integrity/security failure on a carrier, the network may quarantine the carrier immediately to protect downloaders.

The system must preserve evidence necessary to understand the failure without rewriting expected digests or automatically blessing changed bytes.

The incident process should distinguish:

- accidental disk corruption;
- implementation defect;
- compromised machine;
- intentional manipulation;
- false-positive health/routing signal.

## 24. FCF commitments to volunteers

The intended FCF operational commitments are:

- do not use carrier status as permission to inspect unrelated files;
- do not publish private carrier endpoint information on the public site;
- do not silently exceed configured resource limits;
- do not make unapproved preservation material volunteer-served;
- authenticate content identity independently of the carrier;
- make withdrawal straightforward;
- publish material policy changes;
- document telemetry rather than conceal it;
- keep CARAVAN optional for using CENTL.

## 25. Review gate

This draft must not be represented publicly as effective legal terms until the project has finalized:

- implementation behavior;
- telemetry schema and retention;
- revocation/deletion semantics;
- update behavior;
- coordinator/relay deployment;
- jurisdiction-appropriate legal/privacy review;
- policy version and canonical publication mechanism.
