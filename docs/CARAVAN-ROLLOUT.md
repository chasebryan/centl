# CENTL CARAVAN rollout and implementation gates

Status: **planning only — no public CARAVAN implementation or deployment is authorized by this document**.

This document defines the order in which CENTL CARAVAN may move from design to laboratory code, private testing, and eventually voluntary public hosting.

CARAVAN must not jump directly from architecture notes to an Internet-facing volunteer network.

## 1. Governing rollout rule

Each phase is gated by evidence from the previous phase.

A later phase may begin only when:

- its listed prerequisites are complete;
- unresolved security/privacy questions are explicitly documented;
- tests demonstrate the properties being claimed;
- no earlier failure has been hidden by weakening verification.

The goal is a simple user experience built on a deliberately conservative trust boundary.

## 2. Phase 0 — design and policy

No production code or public carrier deployment.

Required documents:

- `docs/CARAVAN.md` — architecture and trust model;
- `docs/CARAVAN-THREAT-MODEL.md` — hostile-peer/security analysis;
- `docs/CARAVAN-HOST-POLICY.md` — volunteer operator policy-content draft;
- this rollout document.

Required design decisions before Phase 1:

- [ ] select maintained TUF implementation/profile;
- [ ] define catalog roles and key rotation model;
- [ ] define canonical metadata serialization;
- [ ] define content-ID representation;
- [ ] define chunk-manifest serialization and fixed chunk size;
- [ ] choose carrier node identity implementation;
- [ ] choose outbound reverse transport;
- [ ] specify retrieval-ticket format, lifetime, and replay rules;
- [ ] define coordinator state model;
- [ ] define carrier storage layout and atomic promotion rules;
- [ ] define resource-limit defaults;
- [ ] define exact withdrawal behavior;
- [ ] define telemetry schema and retention goals;
- [ ] define quarantine states and recovery rules;
- [ ] define website relay boundary;
- [ ] define public-approved redistribution review path;
- [ ] review privacy claims for precision;
- [ ] review host policy for legal/privacy requirements before it can become effective terms.

Exit evidence:

- all open decisions have an explicit answer or a deliberately deferred non-production status;
- threat-model invariants are mapped to tests planned for Phase 1/2;
- no documentation claims CARAVAN is already deployed.

## 3. Phase 1 — local laboratory

Scope: one development machine may host all logical components or two local machines may be used. No public volunteer enrollment.

Minimum components:

- local signed test catalog;
- coordinator;
- two carrier processes;
- relay/download verifier;
- content-addressed store;
- user-level join/leave lifecycle.

Required functionality:

- [ ] no-root carrier installation path;
- [ ] outbound-only carrier session;
- [ ] authenticated catalog consumption;
- [ ] exact whole-file length + SHA-256 validation;
- [ ] authenticated chunk-manifest validation;
- [ ] content-addressed immutable store;
- [ ] bounded disk allocation;
- [ ] bounded upload concurrency/rate;
- [ ] carrier advertisements expire;
- [ ] coordinator chooses among multiple carriers;
- [ ] transparent retry after bad carrier;
- [ ] carrier quarantine state;
- [ ] explicit policy acceptance receipt in test mode;
- [ ] withdrawal disables serving and carrier identity.

Mandatory negative tests:

- [ ] one-byte mutation rejected;
- [ ] wrong file with same size rejected;
- [ ] truncation rejected;
- [ ] appended bytes rejected;
- [ ] reordered chunk rejected;
- [ ] missing/duplicated chunk rejected;
- [ ] unknown digest cannot become approved;
- [ ] `pending-review` artifact cannot replicate;
- [ ] traversal/symlink escape rejected;
- [ ] malformed content ID rejected;
- [ ] storage cap cannot be bypassed remotely;
- [ ] invalid/expired retrieval authorization rejected;
- [ ] expected digest is never rewritten after mismatch.

Exit evidence:

- deterministic integration suite reproduces all listed rejection behavior;
- laboratory can be torn down and recreated from documented steps;
- no root/sudo is required for normal carrier process operation.

## 4. Phase 2 — FCF private network pilot

Scope: FCF-controlled participants only. The development laptop is an acceptable first real carrier. At least one independent second host should participate.

Required functionality:

- [ ] carriers work behind NAT with changing addresses;
- [ ] sleep/offline/resume behavior is safe;
- [ ] outbound-only connection reconnects cleanly;
- [ ] default downloader path uses privacy relay rather than direct carrier endpoint;
- [ ] carrier does not receive downloader's direct IP in default mode;
- [ ] browser/site does not expose carrier endpoint;
- [ ] FCF-owned fallback origin works;
- [ ] coordinator restarts without losing authoritative catalog trust;
- [ ] carrier credential revocation works;
- [ ] agent update path verifies authenticated update metadata;
- [ ] operational telemetry matches documented schema;
- [ ] retention behavior is tested;
- [ ] private model/preservation-only material cannot enter CARAVAN catalog/export;
- [ ] FCF primary preservation remains independent of CARAVAN.

Adversarial drills:

- [ ] intentionally corrupt one carrier cache;
- [ ] intentionally serve wrong bytes;
- [ ] intentionally advertise then refuse service;
- [ ] make one carrier disappear mid-transfer;
- [ ] replay stale presence/ticket data;
- [ ] attempt route-selection poisoning;
- [ ] exceed rate/concurrency limits;
- [ ] revoke one carrier during active participation;
- [ ] rotate a test catalog key according to selected secure-update profile.

Exit evidence:

- private pilot can operate for a sustained period without manual babysitting;
- integrity failures are automatically contained;
- privacy claims have packet/log-level evidence;
- no private preservation artifact is publicly eligible.

## 5. Phase 3 — website integration before public enrollment

Scope: downloaders may use CARAVAN-backed delivery from FCF-controlled/private-pilot carriers, but arbitrary public volunteers are not yet accepted.

Website requirements:

- [ ] ordinary artifact/version selection;
- [ ] one normal download action;
- [ ] automatic route selection;
- [ ] automatic verified fallback;
- [ ] optional technical verification panel;
- [ ] no public carrier IP/host directory;
- [ ] clear CARAVAN experimental-status disclosure;
- [ ] ordinary FCF fallback if CARAVAN is unavailable.

Verification requirements:

- [ ] browser/client receives only bytes that passed the defined verification chain;
- [ ] whole-file SHA-256 is verified at completion;
- [ ] release-specific authentication remains intact;
- [ ] failed carrier bytes never become a successful HTTP download;
- [ ] response caching cannot mix artifact identities;
- [ ] range/resume behavior cannot bypass final verification.

Exit evidence:

- end-to-end downloads are indistinguishable in ease of use from ordinary mirror downloads;
- technical logs prove which authenticated artifact identity was delivered without exposing private carrier data publicly.

## 6. Phase 4 — public volunteer pilot

This phase requires the highest pre-launch review because it accepts third-party machines into the serving network.

Prerequisites:

- [ ] host policy finalized and effective version published;
- [ ] privacy notice finalized;
- [ ] telemetry schema/retention published;
- [ ] exact policy SHA-256/version acceptance implemented;
- [ ] material-change re-acceptance rules implemented;
- [ ] rate limiting/abuse controls deployed;
- [ ] carrier credential revocation deployed;
- [ ] protocol minimum-version enforcement deployed;
- [ ] incident-response procedure documented;
- [ ] public-approved artifact publication workflow audited;
- [ ] signing/catalog key recovery and rotation tested;
- [ ] coordinator and relay have backups/recovery documentation;
- [ ] public status page exposes only aggregate information.

Enrollment UX target:

1. user downloads/verifies the authenticated CARAVAN agent;
2. user runs one join command;
3. concise policy/resource summary appears;
4. user explicitly accepts exact policy version;
5. safe resource defaults are shown and may be adjusted;
6. node identity/store/user service are configured automatically;
7. initial approved cargo is optionally synchronized;
8. user is told how to inspect status and leave.

The user should not need root for the normal path.

Initial public pilot should be deliberately bounded by one or more of:

- invite code;
- limited participant count;
- limited public-approved artifact set;
- limited storage contribution ceiling;
- protocol marked experimental;
- rapid revocation ability.

Exit evidence:

- public pilot demonstrates real independent carrier diversity;
- no integrity breach results in bad artifact acceptance;
- privacy/telemetry behavior matches published policy;
- support burden remains low enough that one-run enrollment is credible.

## 7. Phase 5 — general availability

General availability is justified only after public-pilot evidence.

Maturity goals:

- [ ] robust load balancing;
- [ ] provider/geographic replica diversity;
- [ ] multiple FCF-controlled fallback origins;
- [ ] coordinator high availability/recovery;
- [ ] protocol-version migration process;
- [ ] regular hostile-carrier simulation;
- [ ] reproducible carrier/coordinator/relay deployment;
- [ ] documented capacity planning;
- [ ] public aggregate health reporting;
- [ ] agent rollback/recovery path;
- [ ] scheduled catalog/root/key-rotation drills;
- [ ] periodic privacy review;
- [ ] possible stronger split-knowledge request privacy evaluated with measured performance.

## 8. Implementation decomposition

Once Phase 0 is explicitly approved, implementation should be divided into independently reviewable components rather than one giant service.

Proposed components:

### `caravan-catalog`

Produces/validates approved artifact metadata and chunk manifests from the verified FCF publication boundary. It cannot ingest arbitrary preservation-tree paths.

### `caravan-carrier`

Unprivileged Linux user agent implementing content store, catalog sync, outbound session, resource limits, integrity verification, advertisements, policy receipt, and withdrawal.

### `caravan-coordinator`

Tracks carrier health/availability and selects routes for authenticated artifact IDs. Routing decisions do not define trust.

### `caravan-relay`

Downloader-facing privacy transport and verified streaming boundary.

### `caravanctl`

Operator CLI for join/status/limits/pause/resume/leave/verify.

### website integration

FCF/CENTL download UI that requests a verified CARAVAN route without exposing carrier endpoints.

Names are provisional implementation labels; the network/protocol name remains CENTL CARAVAN.

## 9. Data formats that must be frozen before interoperable release

Before two independently developed CARAVAN implementations could claim interoperability, the project must version and freeze:

- protocol version negotiation;
- artifact ID grammar;
- catalog profile;
- canonical metadata serialization;
- chunk-manifest format;
- carrier advertisement format;
- retrieval-ticket format;
- error codes;
- policy receipt format;
- node identity representation;
- quarantine/revocation semantics.

No hidden implementation-specific serialization should silently become the protocol standard.

## 10. Compatibility policy

During laboratory/private pilot, protocol breaks are allowed when clearly versioned.

Before public volunteer enrollment, the agent must support:

- explicit protocol version;
- minimum accepted version;
- safe refusal of incompatible coordinator messages;
- authenticated update path;
- clear migration/re-enrollment behavior for incompatible identity/policy changes.

## 11. Availability targets

CARAVAN should not publish hard service-level claims before measurement.

The coordinator may maintain desired replica counts per artifact class, but replica count is an operational target, not a security threshold.

Critical CENTL releases should always retain at least one FCF-controlled fallback route independent of volunteer carriers.

## 12. Conservation targets

CARAVAN's conservation role is meaningful only if volunteer replicas remain independently useful.

The network should preserve enough authenticated metadata alongside cargo that an FCF recovery process can prove exactly what the bytes are even if individual carriers are later disconnected from the coordinator.

However, volunteer replicas do not replace the richer FCF private preservation mirror containing source/toolchain/recovery material that is not public-approved.

## 13. Metrics

Useful aggregate metrics include:

- healthy carriers;
- eligible replicas per artifact;
- aggregate contributed bytes;
- aggregate available upload capacity;
- verification failure count/rate;
- timeout/failover rate;
- catalog-version adoption;
- agent protocol-version adoption;
- average time to retrieve approved artifact;
- FCF-fallback usage rate.

Metrics should not create permanent individualized downloader histories.

## 14. Stop conditions

A pilot should pause or roll back if any of the following occurs:

- unapproved content becomes publicly retrievable;
- integrity failure produces a successful bad download;
- default website path exposes volunteer carrier endpoints unexpectedly;
- resource limits can be bypassed remotely;
- policy acceptance state is ambiguous or silently changed;
- signing/catalog authority compromise is suspected;
- carrier software accesses unrelated host files;
- telemetry materially exceeds published policy;
- revocation cannot remove a compromised carrier from routing.

The response to such a failure is investigation and repair, not weakening the invariant.

## 15. Current authorization boundary

At the time this document is introduced, CARAVAN is **authorized for documentation and design review only**.

No production coordinator, relay, public carrier enrollment, or website CARAVAN download path should be represented as operational until the corresponding rollout phase is explicitly completed.
