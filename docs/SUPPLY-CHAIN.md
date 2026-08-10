# CENTL supply-chain preservation

Status: required project infrastructure.

CENTL must remain buildable and scientifically usable if an upstream project,
package host, release page, model host, public forge, or hosted CI provider
disappears. Version pinning is necessary but not sufficient: a hash cannot
recover bytes that no longer exist.

The project therefore treats its external build/runtime inputs and its Linux
recovery environment as preservation material.

## Preservation objective

For the Linux reference platform, an FCF-controlled mirror plus a preserved FCF
build capsule should contain enough material to recover the recorded CENTL source
state without depending on the continued availability of the original upstream
download locations or GitHub-hosted compute.

The mirror covers:

- the pinned F* binary release and its bundled Z3;
- the pinned GMP, MPFR, and FLINT source archives;
- the pinned Julia binary used by the differential laboratory;
- bare Git mirrors of F*, llama.cpp, and the opam repository;
- a complete Git bundle of CENTL itself;
- a source SHA-256 receipt bound to the exact preserved commit;
- the active opam switch export, download cache, and installed package sources;
- an instantiated Julia/Nemo depot for the committed laboratory manifest;
- the exact local CENTL-SCi GGUF model bytes when a model is supplied;
- a versioned Linux OCI build capsule and its SHA-256 receipt after capsule
  provisioning.

`supply-chain/sources.lock` records immutable artifact hashes and required Git
commits. Mirrored bytes are never accepted merely because they came from an
FCF-controlled host; they still have to match the lock.

## Immediate preservation run

On the Linux development machine:

```sh
make supply-chain-preserve \
  MIRROR=/srv/centl-mirror \
  MODEL=/var/home/chasebryan/Models/CENTL-SCi/Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf
```

This performs the source-integrity gate, external source synchronization, opam
snapshot, Julia/Nemo snapshot, exact Git bundle capture, model preservation, and
mirror audit.

If `CENTL_SCI_MODEL` already names the active model, the model argument may be
omitted from the lower-level `scripts/supply-chain sync` command.

The resulting mirror must then be copied to at least one second independent
FCF-controlled storage location. Multiple copies matter more than elaborate
storage ceremony: a mirror that exists only on the primary development disk is
not a preservation system.

## Layout

```text
centl-mirror/
  sources.lock
  artifacts/
    fstar-v2026.07.05-Linux-x86_64.tar.gz
    gmp-6.3.0.tar.xz
    mpfr-4.2.2.tar.xz
    flint-3.0.1.tar.gz
    julia-1.12.6-linux-x86_64.tar.gz
  git/
    fstar.git
    llama.cpp.git
    opam-repository.git
  project/
    centl.bundle
    CENTL_HEAD
    SOURCE-COMMIT
    SOURCE-SHA256SUMS
    SOURCE-SHA256SUMS.sha256
  models/
    ACTIVE.sha256
    <sha256>/
      MANIFEST
      <model>.gguf
  opam/
    centl-switch.export
    installed-packages.txt
    download-cache/
    sources/
    SOURCES.sha256
  julia/
    JULIA_VERSION
    Project.toml
    Manifest.toml
    depot/
    DEPOT.sha256
  capsule/
    centl-build-capsule.oci.tar
    centl-build-capsule.oci.tar.sha256
    BASE-REF
    IMAGE-REF
    IMAGE-ID
    IDENTITY
```

Large mirrored artifacts, models, and OCI images do **not** belong in normal
CENTL Git history. The repository stores the lock, tooling, and policy; FCF
storage stores the preserved bytes.

## Mirror-first fetch

A local mirror can become the preferred source without changing the lock:

```sh
export CENTL_SOURCE_MIRROR_DIR=/srv/centl-mirror
sh scripts/supply-chain fetch fstar-linux-x86_64 \
  "$CENTL_SOURCE_MIRROR_DIR" /tmp/fstar.tar.gz
```

A static HTTPS mirror is also supported through `CENTL_SOURCE_MIRROR_URL`. The
URL is configuration rather than cryptographic identity, so storage may move
without changing the integrity lock.

Strict no-upstream mode is:

```sh
export CENTL_SUPPLY_CHAIN_OFFLINE=1
export CENTL_SOURCE_MIRROR_DIR=/srv/centl-mirror
sh scripts/supply-chain audit "$CENTL_SOURCE_MIRROR_DIR"
```

## CENTL release preservation

CENTL release archives can be installed without GitHub through the installer's
local archive path. Preserve each release archive beside its `.sha256` file and,
for authenticated FCF releases, the release-level `SHA256SUMS` and
`SHA256SUMS.sig` files.

```sh
sh install --archive /srv/centl-mirror/releases/centl-linux-x86_64.tar.gz
```

The local archive path performs the same checksum, extraction, staging, runtime,
and CENTL-SCi smoke checks as a network-installed release.

See `docs/RELEASE-SIGNING.md` for FCF release authentication.

## Git recovery

The CENTL bundle preserves repository refs visible to the source checkout at
snapshot time:

```sh
git clone /srv/centl-mirror/project/centl.bundle centl-recovered
```

Pinned external source repositories are bare mirrors and can be cloned directly:

```sh
git clone /srv/centl-mirror/git/llama.cpp.git
git clone /srv/centl-mirror/git/fstar.git
```

## Model preservation

CENTL-SCi model files are preserved by content hash rather than by model-host
URL:

```text
models/<sha256>/<filename>
```

`models/ACTIVE.sha256` identifies the selected preserved model. Mirror audit
recomputes the model digest before accepting it. A filename or model-host URL is
not a substitute for content integrity.

Model licensing and upstream attribution remain separate required metadata when
an FCF model distribution is published.

## opam recovery material

`snapshot-opam` preserves redundant recovery evidence/material:

1. a full `opam switch export` for the active CENTL switch;
2. the opam download cache already used by the machine;
3. expanded source trees for installed packages where `opam source` can obtain
   them;
4. a SHA-256 manifest for the preserved source trees.

The exact package constraints in `centl.opam` remain the project contract. The
bare `opam-repository.git` mirror is retained so package metadata does not depend
on GitHub remaining available.

## Julia/Nemo recovery material

The committed Julia `Manifest.toml` pins package identities and tree hashes but
does not contain package/artifact bytes. `snapshot-julia` instantiates the
laboratory into an isolated depot and preserves that depot plus a SHA-256
manifest.

The no-network rebuild points `JULIA_DEPOT_PATH` at that preserved depot and sets
Julia package-offline mode instead of re-instantiating from upstream.

## Preserved Linux build capsule

The FCF build capsule removes dependence on the primary developer workstation's
installed compiler/toolchain state.

After the preservation mirror has been populated, construct and save the capsule:

```sh
make capsule-build MIRROR=/srv/centl-mirror
```

`infra/offline-build/Containerfile` starts from the same immutable Ubuntu image
digest used by CENTL's native release workflow. GMP, MPFR, FLINT, and Julia are
fed into the capsule only from already-preserved SHA-256-verified mirror
artifacts. The resulting image is saved as a portable OCI archive and itself
SHA-256 protected.

The first construction still uses Ubuntu package repositories and opam to obtain
generic host/compiler packages. That is a bootstrap event, not a recovery-time
dependency: once the OCI archive exists and is copied with the mirror, a disaster
recovery loads that saved image instead of reconstructing it.

Run the saved capsule with no network:

```sh
make capsule-run MIRROR=/srv/centl-mirror
```

This verifies and loads the OCI archive locally, mounts the mirror read-only, and
starts the capsule with `--network none`. The inner recovery gate verifies the
source and snapshot manifests, rebuilds/tests CENTL, runs the Nemo differential
suite, and requires the rebuilt binary to report the exact preserved commit.

See `infra/offline-build/README.md`.

## What remains operational rather than architectural

The repository now contains the application-level mirror tooling, source and
model integrity process, authenticated release-manifest tooling, no-network
rebuild gate, and preserved OCI build-capsule implementation.

The important remaining work is provisioning and continuity:

- actually populate `/srv/centl-mirror` (or another FCF storage root) from the
  current development state;
- actually build the first OCI capsule and preserve it in that mirror;
- copy the mirror/capsule to at least one independent second location;
- create the first passphrase-protected FCF `signify` release key and commit only
  its public key;
- maintain multiple encrypted recovery copies of that secret key rather than
  making one maintainer/device a single point of failure;
- schedule or manually perform periodic `capsule-run` recovery tests;
- establish FCF-controlled public artifact hosting when practical;
- maintain DNS/TLS/website continuity separately from build recovery.

GitHub Actions may remain useful public CI. It is no longer the design authority
for disaster recovery: the preserved OCI capsule plus mirror define the
independent Linux recovery path.

A future apt/deb mirror would improve the ability to *reconstruct a new capsule
from scratch* if every saved capsule copy were lost. It is not required to run an
already-preserved capsule, so it is a later resilience improvement rather than a
blocker for the first preservation deployment.

## Updating pins

A source pin is changed only deliberately:

1. verify the new upstream version/commit;
2. obtain and independently verify its checksum/provenance;
3. update `toolchain.lock` and/or the relevant project manifest;
4. update `supply-chain/sources.lock`;
5. run `sync` into a staging mirror;
6. run `audit`;
7. build/test CENTL from the new mirrored material;
8. build or refresh the capsule when its contained toolchain changes;
9. perform the no-network recovery gate;
10. promote the staged bytes/capsule to the FCF preservation stores.

Never replace a file in place while keeping its previous checksum entry.
