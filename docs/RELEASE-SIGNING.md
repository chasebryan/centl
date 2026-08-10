# CENTL release authentication

Status: required release infrastructure once the first FCF production release
public key is committed.

CENTL separates two guarantees:

- **integrity:** standard SHA-256 says whether the release bytes match the
  expected checksum manifest;
- **authentication:** OpenBSD `signify` says whether that checksum manifest was
  signed by the selected FCF release key.

Neither guarantee is substituted for the other.

## Why signify

`signify` is an established OpenBSD signing utility designed to sign/verify
files and signed checksum lists. CENTL uses it as defined; no custom signature
scheme or home-grown cryptography is introduced.

The OpenBSD `signify` interface also protects generated secret keys with a
passphrase by default; `-n` explicitly disables that protection. FCF production
keys must remain passphrase-protected.

The release contract is:

```text
centl-linux-x86_64.tar.gz
centl-macos-x86_64.tar.gz
centl-macos-arm64.tar.gz
centl-windows-x86_64.zip
SHA256SUMS
SHA256SUMS.sig
```

The exact archive set varies by release/platform availability. `SHA256SUMS`
contains the standard lowercase SHA-256 digest plus two spaces plus filename for
each release archive. `SHA256SUMS.sig` is a detached signify signature over the
exact checksum-manifest bytes.

## Trust and availability model

Hosted CI may build and test candidate artifacts, but it does not need access to
the FCF production release secret key.

FCF does **not** require one irreplaceable air-gapped key. The production signing
identity is an organizational asset and must be recoverable. The working secret
key is passphrase-protected, and multiple encrypted backup copies are maintained
independently. When additional trusted maintainers exist, at least one other
custodian should have a documented recovery path.

The intended flow is:

```text
source + preserved dependencies
          |
          v
build/test/reproducibility gates
          |
          v
unsigned candidate archives
          |
          v
explicit FCF signing action
          |
          +--> create SHA256SUMS
          +--> signify signature
          +--> verify signature with public key
          +--> recompute every SHA-256
          |
          v
publish archives + SHA256SUMS + SHA256SUMS.sig
```

A compromised ordinary CI runner therefore cannot create an authenticated FCF
release merely by controlling build output. At the same time, loss of one
workstation or storage device does not strand the project.

## Production key creation and recovery

The production key pair must be created outside ordinary hosted CI. It may be
created on a trusted FCF administrator workstation or on a more isolated machine.
See `keys/README.md` for the custody policy.

```sh
umask 077
signify -G \
  -c 'FCF CENTL release key 2026' \
  -p fcf-centl-release-2026.pub \
  -s fcf-centl-release-2026.sec
```

Do not use `-n` for an FCF production key. Only the `.pub` file belongs in the
public CENTL repository.

Operationally, FCF should retain:

- one protected working copy;
- at least two additional encrypted backups on independent storage/services;
- a separately recoverable record of the passphrase in a reputable password
  manager or equivalent protected recovery system;
- a tested restoration procedure.

This is intentionally simpler than threshold cryptography. The goal is good
security with reliable continuity, not ceremony for its own sake.

## Signing a completed candidate release

With the final candidate archives in one directory:

```sh
export FCF_SIGNIFY_SECRET_KEY=/protected/keys/fcf-centl-release-2026.sec
export FCF_SIGNIFY_PUBLIC_KEY=/protected/keys/fcf-centl-release-2026.pub

sh scripts/release-sign /path/to/candidate-release
```

The command refuses to use a secret key stored inside the CENTL repository. It
then:

1. runs the standard SHA-256 known-answer check;
2. creates `SHA256SUMS` from the release archives in deterministic filename
   order;
3. verifies the generated SHA-256 manifest against the archive bytes;
4. signs the exact manifest with `signify`;
5. verifies the new signature with the explicitly selected public key;
6. recomputes every archive checksum again before reporting success.

A fully offline signing environment may be used for a higher-assurance release,
but it is not mandatory for every normal CENTL release.

## Independent verification

Anyone with the release files and trusted FCF public key can run:

```sh
export FCF_SIGNIFY_PUBLIC_KEY=keys/fcf-centl-release-2026.pub
sh scripts/release-verify /path/to/release
```

Verification order is intentional:

1. verify `SHA256SUMS.sig` authenticates the exact `SHA256SUMS` bytes;
2. parse the checksum manifest conservatively;
3. recompute standard SHA-256 for every listed release archive;
4. reject missing, modified, symlinked, duplicate, malformed, or path-escaping
   entries.

## Release promotion rule

A release is not an authenticated FCF release until all of the following are
true:

- source integrity gate passed;
- dependency preservation pins passed;
- required test/verification gates passed;
- required reproducibility/offline gate passed for the release class;
- final archive SHA-256 values were generated from the final candidate bytes;
- `SHA256SUMS` was signed by an active FCF release key;
- the resulting signature and all checksums were independently reverified.

A signing failure or checksum mismatch aborts promotion. The checksum, public
key, or expected identity must never be silently changed simply to make failed
verification pass.

## Lost key

If every copy of the secret key is lost, historical releases remain verifiable
with the corresponding public key. FCF loses only the ability to make *new*
signatures under that old signing identity.

Future releases can continue after generating a replacement key, publishing its
public key, and recording the transition. This is why old public keys must remain
available permanently and why key rotation is a normal supported operation.

A lost key is therefore an operational incident, not a project-ending event.

## Key rotation and compromise

Public keys are additive historical records. A new production key gets a new
filename and explicit activation date. Historical public keys stay available so
old releases remain independently verifiable.

The FCF operational record should maintain:

- key identifier/name;
- public key bytes and fingerprint/identity;
- creation and activation date;
- retirement date, if any;
- compromise/revocation status;
- which release series used the key.

If a secret key may have been exposed, stop using it. Create a replacement key,
publish the new public key through normal FCF channels, and document the
transition. Do not re-sign unknown historical artifacts merely to make them
appear continuous with the new identity.
