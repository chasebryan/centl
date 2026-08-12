# FCF CARAVAN privacy-preserving camel census

Status: protocol contract for the production volunteer rollout. The public coordinator and live census endpoint are not yet enabled.

CARAVAN needs to know whether the preservation network is alive without turning its volunteers into a public tracking directory. The census therefore counts carriers centrally while publishing only aggregate numbers.

The public-facing names are intentionally simple:

- **Active Camels 🐪** — enrolled carriers with a recent authenticated heartbeat.
- **Lost Camels 🐪** — enrolled carriers that have stopped heartbeating beyond the loss window without explicitly withdrawing or being revoked.

The public website must never publish a per-carrier roster.

## Privacy goals

The census is designed to answer questions such as "how many CARAVAN carriers are alive?" without answering "where is Alice's laptop?"

The coordinator must not intentionally collect or persist:

- hostnames;
- usernames;
- email addresses;
- hardware serial numbers;
- MAC addresses;
- GPS/geolocation;
- public home IP addresses as census fields;
- local filesystem paths;
- lists of non-CARAVAN files;
- browser/device fingerprints;
- exact per-carrier public directory entries.

A server necessarily observes the source network address of an HTTPS connection while processing it. Census endpoint policy requires access logging to be disabled or scrubbed so that source addresses are not retained as census history.

## Local carrier identity

On first production enrollment, a carrier creates an owner-only, high-entropy random enrollment token. The token is not a human identity and contains no machine metadata.

Recommended local representation:

```text
~/.local/state/fcf-caravan/identity/
  enrollment-token        # 32 random bytes, mode 0600
  enrollment.json         # non-secret coordinator state, mode 0600
```

The token must be generated with the operating system CSPRNG. It must never be derived from a hostname, username, IP address, MAC address, disk serial, machine-id, or other stable host identifier.

The coordinator stores only a one-way, server-peppered verifier/handle for the token plus minimal state required for counting and revocation. A database copy should not contain the bearer token itself.

The token is transmitted only over authenticated TLS to the designated FCF coordinator endpoint. It is never included in the public census document.

## Why a persistent private handle exists

A Lost Camel count requires the coordinator to distinguish "the same enrolled carrier has stopped checking in" from "a completely new carrier appeared." Therefore some private persistent enrollment state is unavoidable.

CARAVAN minimizes that state instead of pretending it can perform longitudinal counting with zero continuity information.

The persistent handle is private coordinator state. It is not a website identity, not a Bazaar listing, and not a public pseudonym.

## Heartbeat

Production carriers send a small authenticated heartbeat on an interval with random jitter.

Initial protocol target:

```text
nominal heartbeat: 10 minutes
jitter:             ±2 minutes
active window:      30 minutes
lost threshold:     72 hours
```

The heartbeat should contain only what is required for network operation and aggregate health:

```json
{
  "schema": "fcf-caravan-heartbeat-v1",
  "release_version": "X.Y.Z",
  "missions": ["source", "releases"],
  "protocol_version": 1
}
```

Authentication is carried separately using the enrollment credential. The payload does not contain the enrollment token, IP address, hostname, username, or geolocation as ordinary metadata fields.

Selected missions are useful for scheduling and aggregate capacity planning, but exact per-carrier combinations must not be published.

## Carrier states

The coordinator maintains these internal states:

### Active

Last valid heartbeat is no older than 30 minutes.

### Quiet

Last valid heartbeat is older than the Active window but not yet past the Lost threshold.

This absorbs normal laptop sleep, temporary network loss, travel, maintenance, and brief outages without immediately declaring a carrier lost.

Quiet is an internal operational state. The initial public widget does not need to display it.

### Lost

Last valid heartbeat is older than 72 hours and the carrier has not explicitly withdrawn or been revoked.

A Lost Camel that later authenticates successfully returns to Active. Recovery must not create a second public count merely because the machine was temporarily absent.

### Withdrawn

The owner explicitly leaves CARAVAN using the authenticated withdrawal operation. Withdrawn carriers are not Lost Camels.

### Revoked

FCF or the owner invalidates a compromised enrollment credential. Revoked carriers are not counted as Active and are not represented as ordinary Lost Camels.

## Data retention

The coordinator should retain only the minimum per-carrier state needed for active/lost transitions, revocation, abuse prevention, and recovery.

Recommended fields are:

```text
private token verifier/handle
created_at
last_valid_heartbeat_at
state
release major/minor compatibility information
selected mission bitset
credential rotation/revocation state
```

No historical heartbeat timeline is required for the public counter. Updating `last_valid_heartbeat_at` in place is preferable to retaining a detailed activity log.

When a withdrawn/revoked record no longer needs to be retained for security or abuse-prevention purposes, it should be deleted or reduced to non-identifying aggregate statistics.

## Public census document

The coordinator publishes a small aggregate document such as:

```json
{
  "schema": "fcf-caravan-census-v1",
  "status": "live",
  "generated_at": "2026-08-12T00:00:00Z",
  "active_camels": 42,
  "lost_camels": 3,
  "active_window_seconds": 1800,
  "lost_after_seconds": 259200,
  "individual_nodes_public": false,
  "ip_addresses_public": false
}
```

The document contains no carrier identifiers.

A machine-consumable production census should be accompanied by an FCF authentication signature and checksum so mirrors can reproduce the aggregate document without gaining authority to alter the count.

The website may trust its same-origin HTTPS response for presentation, while independent clients can verify the adjacent FCF signature.

## Website widget

The Bazaar hosts a compact widget with at least:

```text
CARAVAN
Active Camels 🐪    42
Lost Camels 🐪       3
```

The widget should refresh periodically, but "live" means recent authenticated census state rather than a continuously streaming location tracker.

The UI must state the freshness time/age and the definitions of Active and Lost. If the census endpoint is unavailable or not yet provisioned, it must display an unavailable/provisioning state rather than fabricate zeroes.

## Role aggregates and k-anonymity

FCF may later want aggregate counts such as how many carriers support semantic or recovery cargo. Small cohorts can become identifying, especially early in the network.

Therefore mission-specific public counts must not be emitted unless the cohort meets a configured minimum population threshold. The initial target is:

```text
k = 10
```

Counts below that threshold should be omitted or grouped into a broader category. The global Active/Lost totals remain the primary public metric.

## Coordinator abuse resistance

The census endpoint is not a general telemetry collector. The coordinator must reject unknown fields rather than silently accumulating new metadata.

It must enforce:

- authenticated enrollment and heartbeat credentials;
- strict schema/size limits;
- replay protection where relevant;
- per-credential and per-source rate limits;
- bounded request bodies;
- no arbitrary URL fetch capability;
- no uploaded files;
- no shell commands;
- no proxy/tunnel behavior;
- no coordinator instruction that can promote local files into public cargo.

A malicious or compromised coordinator must not be able to convert the census channel into a generic remote execution or file collection channel.

## Double-count and Sybil limits

The counter measures authenticated enrolled carrier identities, not guaranteed unique human beings. One person may legitimately operate multiple machines, and a determined attacker may try to create many identities.

The system should reduce casual inflation through enrollment rate limits, credential issuance policy, replay prevention, and anomaly detection without collecting invasive personal identity data.

The public site must describe the number as "active carriers/camels," not "unique people."

## Withdrawal and privacy

Withdrawal is first-class. A carrier that intentionally leaves sends one authenticated withdrawal request before deleting its local credential when possible.

The coordinator then:

1. marks the credential withdrawn;
2. removes it from Active/Lost eligibility;
3. prevents later heartbeat use unless explicitly re-enrolled;
4. schedules private state minimization/deletion according to retention policy.

If a machine is destroyed, lost, or disconnected without withdrawal, it naturally transitions to Lost after the threshold.

## Public-origin exclusion

FCF-owned public origins are infrastructure, not ordinary volunteer carriers. They may be monitored separately and should not automatically inflate the volunteer Active Camel count unless FCF explicitly defines a separate census class.

The first website widget should count volunteer carrier enrollments only. Public origins can have their own health status in The Bazaar.

## Cryptographic and release relationship

Census protocol code is part of the security-sensitive carrier release. Any change to heartbeat authentication, enrollment credentials, state transitions, privacy fields, or coordinator trust requires a new immutable signed `join-caravan` release and the corresponding protocol compatibility review.

There is no silent server command that rewrites an installed carrier into a different census protocol.
