# CENTL CARAVAN outbound carrier transport

Status: **Phase 1 local laboratory; not an Internet-facing service**.

CARAVAN volunteer carriers are designed to initiate connections outward. Normal
participation must not require a volunteer to configure a router, expose a public
listening port, publish a home IP address, or run the carrier as root.

## Phase 1 topology

```text
carrier process
    |
    | outbound request / poll
    v
CARAVAN coordinator / relay boundary
```

The laboratory coordinator has a loopback-only HTTP service so the protocol can
be tested without pretending plaintext HTTP is suitable for deployment. Carrier
client code contains no listening-server path.

Outside the explicit loopback laboratory mode, coordinator URLs are HTTPS-only.

## Live carrier authentication

A policy acceptance receipt proves that a pseudonymous carrier identity accepted
specific policy bytes. It does not prove that the process connecting now still
controls the corresponding private key.

Each outbound session therefore performs a separate Ed25519 proof of possession:

1. the registered active carrier asks for a challenge by pseudonymous node ID;
2. the coordinator generates a CSPRNG challenge ID and challenge value;
3. the carrier signs canonical, domain-separated session-proof bytes containing
   the node ID, challenge ID, and challenge;
4. the coordinator verifies the signature against the public identity already
   bound to the registered carrier;
5. a short-lived random bearer session is issued only after verification.

Challenges are single-use. A failed signature burns the challenge. Challenge and
session state are intentionally process-ephemeral; a coordinator restart
invalidates all of them.

## Session revocation behavior

Every authenticated request rechecks current durable carrier state. A carrier
that becomes quarantined or withdrawn cannot continue using an otherwise
unexpired session token.

The bearer token is not an artifact credential. It cannot add an artifact to the
authenticated catalog or alter an expected digest.

## Laboratory endpoints

The local service currently provides:

```text
POST /v1/session/challenge
POST /v1/session/complete
POST /v1/carrier/heartbeat
POST /v1/carrier/advertise
POST /v1/carrier/poll
```

Heartbeat updates leased presence and local capacity/load information. Advertise
is accepted only for a `public-approved` artifact already present in coordinator
catalog state. Poll is a bounded empty long-poll placeholder for the next
assignment/retrieval slice.

## Privacy properties at this phase

The transport intentionally does not expose a public carrier endpoint or carrier
roster. The laboratory HTTP handler also suppresses the standard request log that
would otherwise include client addresses.

This does **not** establish anonymous networking. The future relay/coordinator can
observe carrier connections, and infrastructure/network observers may infer
traffic relationships. CARAVAN's intended default privacy property is narrower:
normal downloaders should not connect directly to volunteer home carriers, and
volunteer carrier endpoints should not be published to downloaders.

That property will be tested only after the relay/download path exists.

## Resource and abuse limits

Current transport request/response bodies are capped and long-poll duration is
bounded. Storage limits already exist in the content store. The next transport
work adds explicit upload concurrency/rate ceilings, reconnect/backoff state, and
assignment limits before any private multi-machine pilot.

## Negative evidence

The Phase 1 transport tests require:

- a carrier can authenticate, heartbeat, advertise an approved artifact, and
  poll using outbound requests only;
- carrier client operation fails the test if it attempts an explicit socket
  `bind()` after the coordinator is already listening;
- a different Ed25519 identity cannot answer another carrier's challenge;
- a consumed challenge cannot be replayed;
- expired sessions are rejected;
- quarantine invalidates an existing session on its next request;
- an authenticated carrier cannot advertise an artifact absent from the approved
  catalog;
- non-loopback plaintext HTTP coordinator URLs are rejected;
- pathological long-poll durations are rejected.

No public volunteer enrollment is authorized by this transport implementation.
