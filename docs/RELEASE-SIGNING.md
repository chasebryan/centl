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

## Trust model

Hosted CI may build and test candidate artifacts, but it must not possess the FCF
production release secret key.

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
offline release-signing environment
          |
          +--> create SHA256SUMS
          +--> signify signature
          +--> verify signature with public key
          +--> recompute every SHA-256
          |
          v
publish archives + SHA256SUMS + SHA256SUMS.sig
```

A compromised CI runner therefore cannot create a release that authenticates as
FCF merely by controlling the build output.

## One-time production key creation

The production key pair must be created outside GitHub and ordinary networked
CI. See `keys/README.md`.

Example on the offline signing machine:

```sh
umask 077
signify -G \
  -c 'FCF CENTL release key 2026' \
  -p fcf-centl-release-2026.pub \
  -s fcf-centl-release-2026.sec
```

Do not use an unprotected production secret key. Only the `.pub` file belongs in
the CENTL repository.

## Signing a completed candidate release

On the isolated signing environment, with the final candidate archives in one
directory:

```sh
export FCF_SIGNIFY_SECRET_KEY=/offline/keys/fcf-centl-release-2026.sec
export FCF_SIGNIFY_PUBLIC_KEY=/offline/keys/fcf-centl-release-2026.pub

sh scripts/release-sign /offline/candidate-release
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

The signing machine should not download or rebuild the candidate. Its role is to
authenticate already-gated bytes.

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
- `SHA256SUMS` was signed by an active offline FCF release key;
- the resulting signature and all checksums were independently reverified.

A signing failure or checksum mismatch aborts promotion. The checksum, public
key, or expected identity must never be silently changed simply to make failed
verification pass.

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

If a secret key may have been exposed, stop using it immediately. Create a new
offline key, publish the new public key through multiple channels, and document
the transition. Do not re-sign old unknown artifacts merely to make them appear
continuous with the new identity.
