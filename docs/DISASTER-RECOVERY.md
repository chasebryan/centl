# CENTL disaster recovery

Status: Linux x86_64 reference recovery procedure.

The FCF preservation design is intended to survive loss of GitHub, upstream
release hosts, package/model hosts, hosted CI, and the primary CENTL development
checkout. The authoritative recovery unit is the **FCF preservation mirror plus
the saved OCI build capsule**.

After the mirror and capsule have been provisioned successfully, a recovery host
does not need a current CENTL checkout and does not need to download CENTL source
or its preserved project dependencies from the public network.

## Minimum recovery material

A complete FCF mirror contains, among other preservation objects:

```text
centl-mirror/
  project/
    centl.bundle
    SOURCE-COMMIT
    SOURCE-SHA256SUMS
    SOURCE-SHA256SUMS.sha256
  artifacts/
  git/
  opam/
  julia/
  models/
  sci-runtime/
  capsule/
    centl-build-capsule.oci.tar
    centl-build-capsule.oci.tar.sha256
    IMAGE-REF
    IDENTITY
  recovery/
    capsule-run
    capsule-run.sha256
    DRIVER-COMMIT
  MIRROR-SHA256SUMS
  MIRROR-SHA256SUMS.sha256
  MIRROR-SYMLINKS
  MIRROR-SYMLINKS.sha256
```

The actual tree may also contain preserved native releases and other accepted
material. The whole-mirror receipts define the finalized tree.

## Minimal recovery-host substrate

The standalone recovery launcher intentionally has a small host dependency
surface:

- Linux x86_64 for the current reference capsule;
- a POSIX shell;
- Podman capable of loading the saved OCI archive; and
- `sha256sum` or `shasum -a 256`.

Git is **not** required on the host by `recovery/capsule-run`; Git exists inside
the saved capsule and is used there to recover the exact source commit from the
FCF-held Git bundle.

Python, opam, OCaml, F*, Julia, Nemo, CMake, llama.cpp, and the qualified
`llama-cli` environment are provided by the preservation mirror/capsule path
rather than by the recovery host's normal development environment.

Podman and the basic host OS remain a bootstrap boundary. Preserving an apt/deb
repository for reconstructing that host substrate is a useful later resilience
layer, but it is not required to execute an already-saved OCI capsule on a host
that has Podman available.

## Verify the standalone recovery launcher

The launcher is copied into the mirror only during capsule construction from a
clean CENTL checkout whose `HEAD` exactly matches the mirror's `SOURCE-COMMIT`.
It receives its own SHA-256 receipt.

From the mirror:

```sh
cd /srv/centl-mirror/recovery
sha256sum -c capsule-run.sha256
```

On a system that provides `shasum` instead:

```sh
expected=$(awk 'NR == 1 { print $1 }' capsule-run.sha256)
actual=$(shasum -a 256 capsule-run | awk '{ print $1 }')
test "$actual" = "$expected"
```

Do not execute a recovery launcher whose receipt fails.

## Run recovery without a CENTL checkout

The normal disaster-recovery command is:

```sh
sh /srv/centl-mirror/recovery/capsule-run /srv/centl-mirror
```

The host-side launcher performs only the minimum work needed to cross into the
saved environment:

1. validate the saved OCI archive checksum;
2. load that OCI archive into Podman;
3. read the preserved image reference; and
4. start the capsule with `--network none`, mounting only the FCF mirror
   read-only.

The host CENTL repository is not mounted into the container.

Inside the no-network capsule, the launcher then:

1. clones `/mirror/project/centl.bundle` into a temporary recovery-driver
   checkout;
2. reads and validates `/mirror/project/SOURCE-COMMIT`;
3. checks out exactly that commit;
4. requires the recovered driver checkout to report the same commit; and
5. executes that preserved commit's own `scripts/offline-rebuild` against the
   read-only mirror.

This is important: the recovery logic that understands a preservation snapshot
comes from the same preserved CENTL source state as the snapshot itself. A newer
or older host checkout cannot silently reinterpret it.

## What the inner recovery proves

The preserved `offline-rebuild` performs the project recovery gates defined by
that exact CENTL commit. For the current design this includes:

- supply-chain mirror audit;
- source-receipt verification;
- exact source checkout from the CENTL bundle;
- F* recovery from SHA-256-pinned preserved bytes;
- use of the preserved opam switch/environment;
- use of the preserved Julia/Nemo depot;
- CENTL quality, verified build, native tests, and Nemo differential checks;
- rebuilt-binary source-commit verification; and
- when an active CENTL-SCi model is preserved, verification of the qualified
  llama.cpp runtime identity followed by a real forced-model
  `exact_decimal_addition` qualification case against the preserved GGUF.

The capsule runs with public networking disabled. A missing preserved input is a
recovery failure, not a reason to fall back to upstream.

## Capsule/source consistency rule

The capsule must be constructed from the same source state it is intended to
recover.

`scripts/capsule-build` therefore requires:

```text
current clean CENTL checkout HEAD == mirror/project/SOURCE-COMMIT
```

If `main` advances after a preservation snapshot, do not build a new capsule
against the old snapshot while claiming they form one recovery unit. Instead:

1. update to the intentionally selected CENTL commit;
2. run the preservation snapshot for that commit;
3. build the capsule from that same clean commit;
4. run the saved-capsule recovery gate;
5. finalize the whole-mirror receipt; and
6. update and strictly compare every independent copy.

## Independent copy recovery

FCF should normally have at least two verified copies of the finalized mirror.
Before an incident, use:

```sh
sh scripts/mirror-receipt compare \
  /srv/centl-mirror \
  /mnt/fcf-backup/centl-mirror
```

During a true loss of the primary development environment, either independently
verified copy can become the recovery source. The saved `recovery/capsule-run`
inside that copy is sufficient to start the project recovery process.

The existence of a second directory is not considered proof of a valid backup;
the prior strict receipt comparison is the evidence that the copy represented
the finalized preservation tree.

## Recovery without GitHub

Nothing in the saved-capsule execution path requires:

- GitHub repository availability;
- GitHub Releases;
- GitHub Actions;
- F*, Julia, GNU, FLINT, llama.cpp, opam, or model-host availability;
- DNS for those upstreams; or
- a current CENTL checkout on the recovery host.

GitHub and upstream services may remain useful for normal development and public
distribution. They are not the authoritative recovery store.

## Known remaining boundary

The strongest remaining bootstrap dependency is the generic host layer needed to
load the already-preserved OCI image: Linux + Podman + basic shell/SHA tooling.

A future FCF apt/deb mirror, bootable recovery image, or otherwise preserved host
substrate could reduce this boundary further. That is a separate operating-system
preservation problem and should not be confused with the already-preserved CENTL
application/toolchain/model stack.

For the current project scale, multiple verified copies of the mirror and saved
OCI capsule provide substantially more practical resilience than attempting to
mirror an entire Linux distribution before the first preservation store is even
provisioned.
