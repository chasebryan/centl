# FCF CARAVAN join-release contract

Status: implemented release/authentication contract; public volunteer enrollment remains gated by the CARAVAN rollout plan.

The command that turns an ordinary user's Linux account into a CARAVAN carrier is a security-critical bootstrap boundary. It must **not** be treated as a mutable shell script whose current contents on `main`, a website, a gist, a CDN, or an AI-generated answer automatically become authoritative.

## Governing rule

An official `join-caravan` installer exists only as a **versioned FCF-signed release artifact**.

The repository contains `scripts/caravan-join-template`, which is intentionally unusable as an official installer. The template refuses to run while its release markers remain unresolved.

Only `scripts/caravan-join-release` may turn that mutable development template into an official release candidate. The release command requires:

- a completely clean CENTL Git checkout;
- an explicit numeric version such as `1.0.0`;
- an FCF CARAVAN join signing secret key outside the repository;
- the corresponding trusted public key;
- an interactive confirmation unless `--yes` is deliberately supplied; and
- successful post-signing verification.

A release version is never overwritten. A code change requires another version and another explicit FCF signing action.

## Why this matters

This separates three very different things:

```text
mutable development source
        |
        | review / tests / deliberate FCF release action
        v
signed immutable join release
        |
        | user verifies FCF identity + exact bytes
        v
rootless installed carrier release
```

A malicious pull request, compromised branch, accidental edit, bot, AI agent, mirror operator, or web cache can produce different bytes. It cannot make those bytes the same authenticated FCF release without the FCF signing key.

Repository write access is therefore not equivalent to release authority.

## Release identity

A join release has all of these identities:

- semantic version;
- exact CENTL source commit used to build it;
- SHA-256 of the CARAVAN join public key;
- SHA-256 of every inner release object;
- an FCF `signify` signature over the inner checksum manifest;
- SHA-256 of the final release archive;
- an FCF `signify` signature over the outer release manifest.

The release archive is deterministic with normalized ordering, timestamps, ownership metadata, and gzip timestamp handling.

## Signing-key separation

The CARAVAN join signing key should be a **dedicated FCF signing identity**, separate from ordinary CI credentials and preferably separate from unrelated service credentials.

Recommended environment variables for the release ceremony are:

```sh
export FCF_CARAVAN_JOIN_SECRET_KEY=/protected/fcf-caravan-join-2026.sec
export FCF_CARAVAN_JOIN_PUBLIC_KEY=/protected/fcf-caravan-join-2026.pub
```

The secret key must not be committed to Git, attached to a pull request, stored in ordinary hosted CI, or copied into a CARAVAN carrier.

Create the key with OpenBSD `signify` on a trusted FCF administrator system using its normal passphrase-protected mode. Do not use `-n` for a production key.

Only the public key may be published broadly.

## Build and sign

After the implementation is ready for an official carrier release:

```sh
scripts/caravan-join-release \
  --version 1.0.0 \
  --output /srv/fcf-release-candidates/caravan \
  --yes
```

The command refuses a dirty repository and refuses to place the secret key inside the CENTL checkout.

The output is a new directory such as:

```text
fcf-caravan-join-1.0.0/
  fcf-caravan-join-1.0.0.tar.gz
  FCF-CARAVAN-JOIN.pub
  SHA256SUMS
  SHA256SUMS.sig
```

The archive itself contains another signed exact-membership manifest and the rendered `join-caravan` script.

## Independent verification

A user or FCF mirror operator who already possesses the trusted FCF CARAVAN join public key can verify the release before running anything:

```sh
scripts/caravan-join-verify \
  /path/to/fcf-caravan-join-1.0.0 \
  /trusted/fcf-caravan-join-2026.pub
```

Verification requires the bundled public key to be byte-for-byte identical to the separately trusted key, verifies the outer signature and checksums, checks archive member safety before extraction, then verifies the inner signature and checksums again.

The public key should be cross-published through multiple FCF-controlled channels. A signature is useful only when the verifier knows which public key represents FCF.

## No mutable `latest` installer

The official installation path must never be:

```text
curl https://.../main/join-caravan | sh
```

or any equivalent URL whose bytes can silently change while retaining the same identity.

FCF may provide a human-friendly page that points to the current recommended version, but the actual artifact URL and metadata must remain versioned. The recommended version pointer is discovery information, not artifact identity.

Likewise, an old release must never be replaced in place merely to fix it. Publish a new version.

## No automatic self-update

A CARAVAN carrier release does not silently replace its executable from the network.

An upgrade requires:

1. authenticated new release metadata;
2. verification of the new FCF signature and SHA-256 identities;
3. compatibility/policy checks;
4. explicit upgrade logic; and
5. atomic installation beside the old immutable release.

The old release remains available for rollback until policy says it can be removed.

When the production TUF update path is activated, the join/carrier package itself must become an authenticated TUF target as well. TUF adds rollback/freeze and role-delegation protections; it does not make mutable branch bytes authoritative.

## Rootless carrier installation

The normal volunteer-carrier path is intentionally different from the FCF-owned public-origin server.

`join-caravan` refuses `sudo`. It installs versioned release bytes read-only beneath the user's local library tree and keeps writable configuration/state in separate owner-only directories.

The prepared configuration currently records:

- storage ceiling;
- outbound upload-rate ceiling;
- no inbound listener;
- no arbitrary-content capability; and
- network enrollment disabled until the production authenticated carrier protocol is released.

Public enrollment will be enabled only after the CARAVAN rollout gates for coordinator transport, authenticated catalog/TUF state, policy acceptance, revocation, resource bounds, privacy, and withdrawal are complete.

## Abuse invariant

The official join release must never turn a volunteer machine into:

- a general upload host;
- arbitrary file storage;
- a public proxy;
- a VPN/tunnel exit;
- a shell gateway;
- a generic web mirror;
- a public Git host; or
- a way to make local files visible by path.

Carrier cargo must originate from authenticated FCF `public-approved` catalog identities. A carrier's possession of bytes does not grant those bytes publication authority.

## FCF public origin versus volunteer carrier

These are intentionally separate roles:

- **FCF public origin:** root-managed hardened server, static HTTPS, explicit preservation/publication authority, inbound 80/443.
- **Volunteer carrier:** rootless, outbound-only, bounded content-addressed cache, no public endpoint advertised to downloaders.

The first X200 public origin therefore does not establish a precedent that ordinary volunteers should open ports or expose their machine directly to the Internet.

## Publication rule

A signed join release may be copied to the FCF Semantic Origin/Bazaar infrastructure and CARAVAN only after its release verification passes.

CARAVAN replicas may distribute the exact release bytes, but they cannot edit them, rename a changed artifact into the same identity, or authorize a replacement version. SHA-256 and FCF authentication remain the authority.
