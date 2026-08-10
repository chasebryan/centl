# FCF offline CENTL rebuild capsule

Status: required recovery infrastructure for the Linux reference platform.

The preservation mirror keeps CENTL's project/toolchain/model inputs under FCF
control. The remaining host bootstrap is represented by an **FCF build capsule**:
a versioned Linux OCI image containing the compiler/runtime tools required to
consume that mirror.

The capsule is deliberately boring. It is not a new distribution and it does not
vendor a Linux ecosystem into CENTL Git history. The built OCI archive lives in
the FCF preservation mirror beside the source artifacts and is protected by a
standard SHA-256 receipt.

## Capsule contents

`infra/offline-build/Containerfile` starts from the same pinned Ubuntu 22.04 image
digest used by CENTL's native release workflow and contains:

- Git, GNU Make, GCC and ordinary build utilities;
- Python 3;
- opam and the exact `centl` OCaml 4.14.1 switch dependencies;
- Julia 1.12.6;
- GMP 6.3.0, MPFR 4.2.2, and FLINT 3.0.1 built from the same SHA-256-pinned
  source archives preserved by CENTL;
- `signify-openbsd` for release authentication/verification;
- the native runtime support required by the pinned F* archive.

F*, the CENTL Git bundle, the Julia/Nemo depot, CENTL-SCi model bytes, and source
integrity receipts remain in the preservation mirror and are mounted into the
capsule at validation time.

## Build and preserve the capsule

The reference implementation uses Podman so the resulting image can be saved as
a portable OCI archive.

First preserve the CENTL dependency mirror, then run:

```sh
make capsule-build MIRROR=/srv/centl-mirror
```

The build helper refuses to retrieve GMP, MPFR, FLINT, or Julia from upstream;
those inputs must already exist in the FCF mirror and pass their locked SHA-256
values.

The first capsule construction still uses Ubuntu's package service and opam to
install the generic host/compiler packages and exact OCaml packages. That is an
intentional bootstrap boundary. Once construction succeeds, the resulting image
itself is preserved so a recovery does not need to repeat those downloads.

The mirror receives:

```text
capsule/
  centl-build-capsule.oci.tar
  centl-build-capsule.oci.tar.sha256
  IMAGE-REF
  IMAGE-ID
  IDENTITY
```

The OCI archive is therefore another preservation artifact, not something that
must be reconstructed during an outage.

## Run the preserved capsule with no network

```sh
make capsule-run MIRROR=/srv/centl-mirror
```

The helper:

1. verifies the saved OCI archive against its SHA-256 receipt;
2. loads the image from local FCF storage;
3. mounts the preservation mirror read-only;
4. mounts the CENTL driver scripts read-only;
5. starts the capsule with Podman `--network none`;
6. executes `scripts/offline-rebuild` inside that isolated environment.

The inner rebuild then:

1. audits the preserved external artifacts/Git mirrors;
2. verifies `SOURCE-SHA256SUMS` and its receipt;
3. verifies the preserved opam source and Julia-depot manifests;
4. clones CENTL from the preserved Git bundle;
5. checks out the exact `SOURCE-COMMIT`;
6. verifies every recorded source-file SHA-256;
7. recovers F* only from the mirror;
8. runs `make quality` and the verified test/build path;
9. runs the deterministic Julia/Nemo differential suite from the preserved
   depot;
10. requires the rebuilt binary to report the exact preserved source commit.

There is no network fallback in this run. A missing component is a failed
preservation/capsule gate, not a reason to contact upstream.

## Host-only no-network mode

For a trusted Linux machine that already has the required pinned host tools, the
lower-level gate remains available without Podman:

```sh
make offline-rebuild MIRROR=/srv/centl-mirror
```

It uses a Linux network namespace to remove the upstream route before rebuilding.
The OCI capsule is preferred for disaster recovery because it also preserves the
host build environment.

## Reproducibility claim boundary

The capsule demonstrates **recoverability and environment preservation**. It does
not by itself claim that arbitrary independent machines produce bit-for-bit
identical final CENTL archives. Binary reproducibility is a stronger property and
must be measured before CENTL advertises it.

The OCI archive *is* content-addressed by its SHA-256 receipt, so copies of the
preserved capsule can be checked exactly.

## Self-hosted CI direction

An FCF-controlled runner can invoke `make capsule-run MIRROR=...` on a schedule
or before release promotion. GitHub Actions may remain a useful public CI surface,
but the project no longer needs GitHub-hosted compute to define the authoritative
Linux recovery test.

The independence test is:

> If GitHub and the named upstream dependency hosts disappeared today, can an
> FCF-held OCI capsule plus FCF-held preservation mirror still verify, build,
> test, and run the preserved CENTL source state?

That is the recovery property this layer is designed to provide.
