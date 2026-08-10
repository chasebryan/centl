# CENTL release preservation

Status: required distribution-preservation procedure.

FCF preservation is not complete if CENTL can be rebuilt but previously published
native release archives disappear with their original host. Published release
bytes are therefore first-class preservation material alongside source,
toolchains, models, package snapshots, and the OCI recovery capsule.

## Preserve from local release bytes

`release-preserve` never needs to download a release. Point it at a directory
that already contains the final CENTL archives and their adjacent checksum files:

```sh
CENTL_RELEASE_SOURCE_COMMIT=<full-40-character-commit> \
  sh scripts/release-preserve \
    /srv/centl-mirror \
    0.12.0 \
    /path/to/final-release
```

When a local `v0.12.0` Git tag is available, the explicit source-commit variable
may be omitted. The tag must resolve to a full commit already present in the local
CENTL repository.

The command does not treat a version string as source provenance. Every preserved
release is bound to a concrete Git commit in `SOURCE-COMMIT`.

## Required archive checks

Every `centl-*.tar.gz` or `centl-*.zip` archive must have an adjacent conventional
checksum file:

```text
centl-linux-x86_64.tar.gz
centl-linux-x86_64.tar.gz.sha256
```

The adjacent file must contain exactly one standard lowercase SHA-256 entry for
the corresponding archive. `release-preserve` verifies the source archive before
copying it and verifies the copied archive again from the staging directory.

A valid source checksum is therefore not assumed to imply a valid copy.

## Signed releases

Once FCF production release signing is active, the release directory additionally
contains:

```text
SHA256SUMS
SHA256SUMS.sig
```

Preserve an authenticated release with the active FCF public key selected:

```sh
export FCF_SIGNIFY_PUBLIC_KEY=/trusted/keys/fcf-centl-release-2026.pub

CENTL_RELEASE_SOURCE_COMMIT=<full-commit> \
  sh scripts/release-preserve \
    /srv/centl-mirror \
    0.13.0 \
    /path/to/final-release
```

If either signed-manifest file is present, both are required. The command refuses
to downgrade silently to checksum-only preservation.

For a signed release it also requires every discovered native archive to appear
exactly once in the authenticated `SHA256SUMS`, runs the normal CENTL
`release-verify` authentication/integrity path before copying, and repeats that
verification against the staged copy.

The exact selected public key is then copied into the immutable release directory
as:

```text
SIGNING-PUBLIC-KEY
SIGNING-PUBLIC-KEY.sha256
```

The copied key is SHA-256 verified and is itself used for the staged
`release-verify` pass before the release is accepted. This ensures the historical
verification material remains available even if the active project key rotates
later.

The embedded public key is not self-authenticating. A user still needs a trusted
FCF channel, prior key identity, or other trust anchor to decide that the key
belongs to FCF. Preservation of a verification key and trust in that key are
separate properties.

## Historical unsigned releases

Older CENTL releases may predate the FCF signing key. They remain worth
preserving.

Such a release is recorded with:

```text
AUTHENTICATION
```

containing:

```text
adjacent-sha256
```

A signed release records `signify` instead. This is deliberately descriptive,
not retroactive: historical unsigned artifacts are not represented as having
publisher authentication they never had.

Do not re-sign unknown historical bytes merely to make the history look uniform.
Preserve what was actually published, verify the available integrity evidence,
and record the real authentication state.

## Mirror layout

A preserved release is stored under its version:

```text
centl-mirror/
  releases/
    v0.12.0/
      VERSION
      SOURCE-COMMIT
      AUTHENTICATION
      centl-linux-x86_64.tar.gz
      centl-linux-x86_64.tar.gz.sha256
      ...
      RELEASE-CONTENTS-SHA256SUMS
      RELEASE-CONTENTS-SHA256SUMS.sha256
```

Signed releases additionally retain:

```text
SHA256SUMS
SHA256SUMS.sig
SIGNING-PUBLIC-KEY
SIGNING-PUBLIC-KEY.sha256
```

`RELEASE-CONTENTS-SHA256SUMS` covers the exact regular-file contents of the
version directory except its own receipt pair. This creates a release-local
integrity boundary in addition to the whole-mirror receipt.

## Existing version protection

A version path is immutable once preserved.

If `releases/vVERSION` already exists, a new ingest succeeds only when the newly
verified staging tree is byte-for-byte identical to the existing preserved tree.
A different archive, checksum, source commit, authentication state, verification
key, or receipt causes failure rather than replacement.

A version is not silently overwritten simply because its filename matches.

## Whole-mirror finalization

Adding a release changes the complete preservation tree. A successful
`release-preserve` therefore finishes by regenerating and verifying the top-level
whole-mirror regular-file and symbolic-link receipts through
`scripts/mirror-receipt`.

This makes release ingestion a complete preservation transaction from the
operator's point of view: success means the release directory and the updated
mirror receipt both verified.

Afterward, update every independent storage copy and prove it with:

```sh
sh scripts/mirror-receipt compare \
  /srv/centl-mirror \
  /mnt/fcf-backup/centl-mirror
```

## Public export

A preservation mirror is not itself a web root. Use
[`PUBLICATION.md`](PUBLICATION.md) and `scripts/publication-export` to create a
verified public-only tree containing intentionally publishable release material
without exposing models, build capsules, development caches, Git mirrors, or
other internal recovery state.

## What this removes from GitHub

GitHub Releases may remain a convenient public distribution surface. It is not
the preservation authority.

Once a release is ingested into FCF storage and copied to an independent second
location, loss of the GitHub Release page does not remove the native release
archives, their checksum evidence, their source-commit binding, their embedded
verification key, or their release signature when one exists.
