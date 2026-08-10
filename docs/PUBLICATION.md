# FCF CENTL publication export

Status: public-distribution boundary for preserved CENTL releases.

The FCF preservation mirror is **not** a web root. It contains material that is
valuable for recovery but should not be published merely because it is stored by
FCF, including development caches, Git mirrors, the saved OCI build capsule,
recovery scripts, and potentially model weights with separate licensing or
provenance requirements.

Public distribution therefore uses an explicit export step.

## Principle

The publication path is allowlist-based:

```text
FCF preservation mirror
        |
        | verify complete mirror receipts
        v
verified releases/vVERSION directories
        |
        | release-local integrity/authentication checks
        v
public export root
```

`scripts/publication-export` never copies the mirror root recursively. It selects
only preserved release directories that satisfy the release contract.

## Export a public release tree

After the preservation mirror is finalized:

```sh
sh scripts/publication-export \
  /srv/centl-mirror \
  /srv/fcf-public/centl/releases
```

The output layout is intentionally the same static hierarchy understood by the
host-neutral installers:

```text
/srv/fcf-public/centl/releases/
  v0.12.0/
    VERSION
    SOURCE-COMMIT
    AUTHENTICATION
    centl-linux-x86_64.tar.gz
    centl-linux-x86_64.tar.gz.sha256
    ...
  VERSIONS
  PUBLICATION-SOURCE
  PUBLIC-SHA256SUMS
  PUBLIC-SHA256SUMS.sha256
```

A signed release also carries:

```text
SHA256SUMS
SHA256SUMS.sig
SIGNING-PUBLIC-KEY
SIGNING-PUBLIC-KEY.sha256
```

alongside its release-local receipt files.

A static HTTPS server can publish this directory directly as the release base
used by `install --release-base-url` / `install.ps1 -ReleaseBaseUrl`.

## Pre-export verification

Before copying any release, the exporter requires the entire preservation mirror
to pass its strict regular-file and symbolic-link receipts. A partial or corrupted
mirror is not accepted as a publication source.

Each release then independently must pass:

- its `RELEASE-CONTENTS-SHA256SUMS` receipt and receipt checksum;
- exact regular-file membership;
- absence of symbolic links in the public release directory;
- `VERSION` agreement with the `vVERSION` directory name; and
- the authentication rule recorded in `AUTHENTICATION`.

For historical checksum-only releases, every discovered native archive must have
an adjacent checksum that verifies the archive.

For `signify` releases, the preserved release must carry the exact public key used
when it was ingested. The exporter verifies that public-key file against its own
SHA-256 receipt, then runs the normal `release-verify` signature + archive
verification path before copying anything.

## Why preserve the signing public key inside the release

A detached signature is only useful if the corresponding public verification key
remains available.

When `release-preserve` ingests an authenticated release, it now copies the exact
selected public key into the immutable release directory as
`SIGNING-PUBLIC-KEY`, hashes that key, and repeats signature verification using the
copied key before the release is accepted.

This improves historical recoverability. It does **not** make the embedded key
self-authenticating: users still need a trusted FCF channel or previously trusted
key identity to know that a given public key represents FCF. Key availability and
key trust are separate properties.

## What is deliberately excluded

The exporter does not publish these mirror classes:

- `models/`;
- `sci-runtime/`;
- `capsule/`;
- `recovery/`;
- `opam/`;
- `julia/`;
- `git/`;
- raw dependency `artifacts/`;
- source-preservation receipts/bundles under `project/`.

Those objects may have different licensing, security, size, or operational
requirements. Any future decision to publish one should introduce an explicit
public contract for that resource class rather than widening this exporter by
accident.

In particular, a locally preserved GGUF is not automatically approved for public
redistribution merely because FCF can recover it.

## Public-tree receipt

The output receives:

```text
PUBLIC-SHA256SUMS
PUBLIC-SHA256SUMS.sha256
```

The manifest covers every regular file intended for serving except its own
receipt pair. The exporter re-verifies that exact tree before replacing the
previous output directory.

`PUBLICATION-SOURCE` records the preserved CENTL source commit and the SHA-256
identities of the mirror's regular-file and symlink manifests. This links a
published export back to the finalized preservation state without exposing the
private mirror contents.

`VERSIONS` is a sorted list of exported release versions.

## Output replacement

The export is constructed and fully verified in a sibling staging directory.
Only after all checks pass is the previous public output moved aside and the new
verified tree activated. If activation fails, cleanup attempts to restore the
previous output.

The exporter refuses an output path that is inside the preservation mirror or an
output path that would contain the preservation mirror. Publication must not
mutate or recursively copy the preservation authority.

## Serving over HTTPS

The export format is server-agnostic. FCF may serve it from Caddy, nginx, an
object store, GitHub Pages-compatible static hosting, or another HTTPS-capable
system without changing CENTL's release identity.

For a public root such as:

```text
https://downloads.example.org/centl/releases
```

a specific archive is simply:

```text
https://downloads.example.org/centl/releases/v0.12.0/centl-linux-x86_64.tar.gz
```

No `latest` redirect, API, database, or server-side application is required.

The real FCF hostname should be configured only when the corresponding hosting
exists. CENTL source deliberately does not claim a public artifact host before it
has been provisioned.

## Updating publication after mirror changes

After adding or changing intentionally accepted preservation material:

1. run the resource-specific preservation operation;
2. regenerate/verify the whole-mirror receipt;
3. update and compare independent preservation copies;
4. run `publication-export` again;
5. deploy/synchronize the verified public output.

A failed mirror, release, signature, or public-tree verification aborts export. Do
not update expected checksums merely to force a publication through.
