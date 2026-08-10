# CENTL CARAVAN carrier identity and policy receipt

Status: **Phase 1 laboratory profile; not a public enrollment protocol**.

This document defines the current CARAVAN carrier identity and host-policy
acceptance mechanism used by the local laboratory.

## Trust boundary

A carrier identity authenticates one participating node to CARAVAN infrastructure.
It is **not** an FCF artifact-signing key and does not authorize content.

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

Compromise of a carrier identity can impersonate that carrier until the credential
is quarantined or revoked. It cannot change an authenticated artifact digest,
create a `public-approved` target, or sign an FCF release/catalog role.

## Identity primitive

Phase 1 uses Ed25519 through PyCA `cryptography` 50.0.0. The earlier laboratory
selection of 49.0.0 was replaced before merge after dependency review identified
CVE-2026-69247 in that release; 50.0.0 contains PyCA's fix.

The carrier stores:

```text
<identity-root>/
  identity.pem
  identity.pub
```

The identity root is owner-only and the private key file must not be accessible to
group or other users. Symbolic-link identity roots/private-key files are rejected.
Normal operation requires no root or sudo.

The private key is intentionally not passphrase-encrypted in Phase 1 because the
carrier must authenticate unattended. This is a node credential, not an FCF
publisher key. The operational response to suspected compromise is credential
quarantine/revocation and identity replacement.

## Public identity

The public identity is the raw 32-byte Ed25519 public key encoded as unpadded
base64url:

```text
ed25519:<base64url-public-key>
```

The pseudonymous node identifier is derived only from that public key:

```text
caravan-node-v1:<sha256>
```

The SHA-256 input is a fixed CARAVAN v1 domain separator followed by the raw
Ed25519 public key. The node identifier therefore does not include username,
hostname, IP address, filesystem path, or hardware serial information.

## Explicit host-policy acceptance

Execution alone is not consent. The laboratory acceptance object is created only
after an enrollment flow has obtained explicit acceptance for exact policy bytes.

A signed receipt binds:

- receipt schema;
- pseudonymous node identifier;
- Ed25519 public identity;
- exact policy version;
- SHA-256 of the accepted policy bytes;
- agent version;
- acceptance mode (`interactive` or `non-interactive`);
- UTC acceptance timestamp.

The canonical signing payload is deterministic JSON with sorted keys and compact
separators. The Ed25519 signature is stored as unpadded base64url.

The receipt deliberately contains no operator legal name, username, hostname, IP
address, home address, or hardware fingerprint.

## Material policy changes

A receipt is valid only for the exact policy SHA-256 and version to which it was
signed. Changing the policy bytes invalidates that receipt for enrollment against
the new policy. Material policy changes therefore require a new explicit
acceptance receipt rather than silently inheriting old consent.

## Coordinator enrollment boundary

`register_accepted_carrier()` verifies the receipt signature, public-key-derived
node ID, required policy version, and exact policy digest before inserting the
carrier into coordinator state.

The coordinator stores only the pseudonymous identity and version data needed for
operation. This does not yet replace the Phase 1 transport proof-of-possession
work: the outbound session layer still needs to authenticate that the connecting
process currently controls the private key.

## Tests

The Phase 1 identity suite covers:

- stable identity across reload;
- owner-only private-key permissions;
- symlink identity-root rejection;
- Ed25519 signature success and tamper failure;
- exact policy-byte binding;
- policy-version binding;
- receipt-field tamper rejection;
- wrong-identity rejection;
- absence of username/hostname fields;
- policy-gated coordinator registration;
- changed-policy re-acceptance requirement.

Public enrollment remains prohibited until the later CARAVAN rollout gates are
satisfied.
