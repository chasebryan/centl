# CENTL supply-chain preservation

Status: required project infrastructure.

CENTL must remain buildable and scientifically usable if an upstream project,
package host, release page, model host, or public forge disappears. Version
pinning is necessary but not sufficient: a hash cannot recover bytes that no
longer exist.

The project therefore treats its external build/runtime inputs as preservation
material.

## Preservation objective

For the Linux reference platform, a CENTL source checkout plus an FCF-controlled
mirror should contain enough material to recover the current development stack
without depending on the continued availability of the original upstream
download locations.

The mirror covers:

- the pinned F* binary release and its bundled Z3;
- the pinned GMP, MPFR, and FLINT source archives;
- the pinned Julia binary used by the differential laboratory;
- bare Git mirrors of F*, llama.cpp, and the opam repository;
- a complete Git bundle of CENTL itself;
- the active opam switch export, download cache, and installed package sources;
- an instantiated Julia/Nemo depot for the committed laboratory manifest;
- the exact local CENTL-SCi GGUF model bytes when a model is supplied.

`supply-chain/sources.lock` records immutable artifact hashes and required Git
commits. Mirrored bytes are never accepted merely because they came from an
FCF-controlled host; they still have to match the lock.

## Immediate preservation run

On the current Linux development machine:

```sh
export MIRROR=/srv/centl-mirror

sh scripts/supply-chain sync "$MIRROR" \
  /var/home/chasebryan/Models/CENTL-SCi/Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf

sh scripts/supply-chain snapshot-opam "$MIRROR"
sh scripts/supply-chain snapshot-julia "$MIRROR"
sh scripts/supply-chain audit "$MIRROR"
```

The same operation is available through the Makefile:

```sh
make supply-chain-preserve \
  MIRROR=/srv/centl-mirror \
  MODEL=/var/home/chasebryan/Models/CENTL-SCi/Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf
```

If `CENTL_SCI_MODEL` already names the active model, the model argument may be
omitted from `sync`.

The resulting directory should immediately be copied to at least one second
machine or storage device under FCF control. An offline copy is strongly
recommended. A mirror that exists only on the primary development disk is not a
preservation system.

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
```

Large mirrored artifacts and models do **not** belong in the normal CENTL Git
history. The repository stores the lock, tooling, and policy; FCF storage stores
the preserved bytes.

## Mirror-first fetch

A local mirror can become the preferred source without changing the lock:

```sh
export CENTL_SOURCE_MIRROR_DIR=/srv/centl-mirror
sh scripts/supply-chain fetch fstar-linux-x86_64 "$CENTL_SOURCE_MIRROR_DIR" /tmp/fstar.tar.gz
```

A static HTTPS mirror is also supported:

```sh
export CENTL_SOURCE_MIRROR_URL=https://artifacts.example.invalid/centl-sources
```

The URL is intentionally configuration, not an FCF hostname hard-coded into the
source tree. This allows storage to move without changing the integrity lock.

For a no-network recovery test:

```sh
export CENTL_SUPPLY_CHAIN_OFFLINE=1
export CENTL_SOURCE_MIRROR_DIR=/srv/centl-mirror
sh scripts/supply-chain audit "$CENTL_SOURCE_MIRROR_DIR"
sh scripts/supply-chain fetch fstar-linux-x86_64 \
  "$CENTL_SOURCE_MIRROR_DIR" /tmp/fstar.tar.gz
```

## CENTL release preservation

CENTL release archives can already be installed without GitHub through the
installer's local archive path. Preserve each release archive beside its
`.sha256` file in FCF storage, then install directly from that copy:

```sh
sh install --archive /srv/centl-mirror/releases/centl-linux-x86_64.tar.gz
```

The local archive path performs the same checksum, extraction, staging, runtime,
and CENTL-SCi smoke checks as a network-installed release. A future FCF release
endpoint may mirror GitHub's release layout, but recovery does not need to wait
for that hosting layer because `--archive` is already an offline contract.

## Git recovery

The CENTL bundle preserves all refs visible to the source checkout at snapshot
time:

```sh
git clone /srv/centl-mirror/project/centl.bundle centl-recovered
```

Pinned external source repositories are bare mirrors and can be cloned directly:

```sh
git clone /srv/centl-mirror/git/llama.cpp.git
git clone /srv/centl-mirror/git/fstar.git
```

## Model preservation

CENTL-SCi model files are preserved by content hash rather than by a model-host
URL. This is intentional. The current qualification filename is not sufficient
provenance by itself, and model hosting can move or disappear.

`scripts/supply-chain sync MIRROR MODEL.gguf` copies the exact bytes under:

```text
models/<sha256>/<filename>
```

and writes `models/ACTIVE.sha256`.

The stored hash becomes the local preservation identity. Model licensing and
upstream attribution remain separate required metadata when an FCF model
distribution is published.

## opam recovery material

`snapshot-opam` preserves three levels of evidence/material:

1. a full `opam switch export` for the active CENTL switch;
2. the opam download cache already used by the machine;
3. expanded source trees for installed packages where `opam source` can obtain
   them.

This is deliberately redundant. The exact package constraints in `centl.opam`
remain the project contract, while the snapshot keeps the corresponding bytes
under FCF control.

The bare `opam-repository.git` mirror is also retained so package metadata does
not depend on GitHub remaining available.

## Julia/Nemo recovery material

The committed Julia `Manifest.toml` pins package identities and tree hashes, but
does not contain the package/artifact bytes. `snapshot-julia` instantiates the
laboratory into an isolated depot and preserves that depot beside the manifest.

A recovery machine can point `JULIA_DEPOT_PATH` at the preserved depot before
running the differential suite.

## What this first layer does not pretend to solve

The application-level mirror removes CENTL's direct dependence on the most
important project/package/model upstreams. It does not make the entire operating
system supply chain disappear.

The following must be handled as the next infrastructure layer:

- Ubuntu/deb bootstrap packages used by development and release jobs;
- GitHub-hosted Actions and GitHub-hosted runners;
- pinned container image availability;
- external CI artifact retention;
- DNS/TLS and hosting continuity for the eventual FCF mirror.

The durable solution is an FCF-owned Linux build image plus a self-hosted CI
runner that consumes only the preserved mirror during the reproducibility gate.
That gate should periodically build CENTL with outbound network access disabled.

Until that layer lands, `scripts/supply-chain audit` is the required integrity
check for the application-level preservation store.

## Updating pins

A source pin is changed only deliberately:

1. verify the new upstream version/commit;
2. obtain and independently verify its checksum/provenance;
3. update `toolchain.lock` and/or the relevant project manifest;
4. update `supply-chain/sources.lock`;
5. run `sync` into a staging mirror;
6. run `audit`;
7. build/test CENTL from the new mirrored material;
8. promote the staged bytes to the FCF preservation store.

Never replace a file in place while keeping its previous checksum entry.
