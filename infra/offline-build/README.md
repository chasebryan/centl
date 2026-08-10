# FCF offline CENTL rebuild capsule

Status: infrastructure contract.

The preservation mirror keeps CENTL's project/toolchain/model inputs under FCF
control. The remaining operating-system bootstrap is represented by an **FCF
build capsule**: a maintained Linux machine/image that already contains the small
set of host executables required to consume the mirror.

The capsule is deliberately boring. It is not a new distribution and it does not
attempt to vendor an entire Linux ecosystem into the CENTL Git repository.

## Required host tools

The Linux reference capsule must provide:

- Git;
- GNU Make and a C toolchain;
- Python 3;
- opam plus the pinned `centl` switch;
- Julia 1.12.6 executable;
- `tar` and normal POSIX shell utilities;
- native development/runtime support required by the CENTL build;
- Linux user/network namespaces (`unshare`) for the no-network gate.

The CENTL-specific source inputs, verifier archive, Git sources, Julia/Nemo depot,
model, and integrity receipts come from the FCF preservation mirror rather than
from the public network.

## No-network rebuild gate

Run:

```sh
make offline-rebuild MIRROR=/srv/centl-mirror
```

or directly:

```sh
scripts/offline-rebuild /srv/centl-mirror
```

The gate creates a new Linux network namespace before rebuilding. Inside it:

1. the preservation mirror is audited;
2. CENTL is cloned from the preserved Git bundle;
3. the exact recorded source commit is checked out;
4. the source `SHA256SUMS` receipt is verified;
5. F* is recovered from the SHA-256-pinned mirror artifact;
6. the already-present pinned opam switch is used with no possibility of an
   upstream network fallback;
7. the preserved Julia/Nemo depot is used in package-offline mode;
8. `make quality`, the verified build/tests, and the deterministic Nemo
   differential suite run;
9. the rebuilt binary must report the exact preserved source commit.

A missing package/tool is a capsule failure. The gate must not fix itself by
contacting an upstream repository.

## What is and is not reproduced

This gate proves that the preserved application/toolchain material is sufficient
to rebuild CENTL on the maintained FCF Linux capsule without network access.

It does **not yet** prove bit-for-bit reproducibility of every emitted binary
across arbitrary Linux installations. CENTL's release workflow already controls
many build inputs, but binary reproducibility is a separate property and should
be claimed only when measured.

It also does not preserve the entire OS package repository. The capsule itself
must therefore be backed up/versioned by FCF infrastructure. A practical first
implementation is a disk/image snapshot plus a plain-text inventory of installed
packages. Later, if warranted, FCF can add an apt/deb mirror for rebuilding the
capsule itself.

## Self-hosted CI direction

A future FCF self-hosted runner should execute this gate against a read-only or
staged mirror. GitHub Actions may remain a convenient public CI surface, but it
must not be the only environment capable of validating CENTL.

The independence test is simple:

> If GitHub and all named upstream dependency hosts disappeared today, can the
> FCF capsule plus preservation mirror still verify, build, test, and run the
> current Linux CENTL source state?

The purpose of this infrastructure is to make that answer yes.
