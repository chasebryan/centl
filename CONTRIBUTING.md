# Contributing to CENTL

CENTL's build has three layers: a verified F* core, an OCaml application, and
native FLINT/GMP/MPFR bindings. The independent Julia/Nemo laboratory is
optional for ordinary development but required before merging mathematical
changes.

If any part of that stack is unfamiliar, start with the
[manual contributor onboarding](docs/ONBOARDING.md). It provides a staged OCaml,
F*, rigorous-numerics, protocol, testing, and source-code curriculum with
readiness exercises.

The canonical versions are recorded in [`toolchain.lock`](toolchain.lock). The
checked-in [`centl.opam`](centl.opam) manifest gives opam exact constraints for
the OCaml compiler, build tools, test libraries, and formatter.

## Prerequisites

Install these system tools first:

- opam 2.1 or newer
- a C compiler, GNU Make, `pkg-config`, and development headers for FLINT 3,
  GMP, and MPFR
- `curl`, `tar`, and the `libzstd` runtime for the pinned F* distribution
- Julia 1.12.6 when running the independent differential suite

On Ubuntu 24.04, the system layer can be installed with:

```sh
sudo apt-get update
sudo apt-get install --yes \
  build-essential ca-certificates curl libflint-dev libgmp-dev libmpfr-dev \
  libzstd1 make opam pkg-config tar
```

Release packaging builds the exact GMP, MPFR, and FLINT versions in
`toolchain.lock`; the distro packages above are the faster development setup.

## Install the pinned F* verifier

The workflow uses the F* release and checksum below. Install it into a local
tools directory, then add its `bin` directory to your shell's `PATH`:

```sh
FSTAR_VERSION=2026.07.05
FSTAR_SHA256=23829d496c909c67f7261c1471be34047ad0d508ee0b933607618b313cbae1a4
mkdir -p .tools/fstar
curl --fail --location \
  "https://github.com/FStarLang/FStar/releases/download/v${FSTAR_VERSION}/fstar-v${FSTAR_VERSION}-Linux-x86_64.tar.gz" \
  --output .tools/fstar.tar.gz
printf '%s  %s\n' "$FSTAR_SHA256" .tools/fstar.tar.gz | sha256sum --check
tar -xzf .tools/fstar.tar.gz -C .tools/fstar
fstar=$(find .tools/fstar -type f -path '*/bin/fstar.exe' -print -quit)
test -n "$fstar"
export PATH="$(dirname "$fstar"):$PATH"
```

F* ships the supported Z3 binary. Confirm both pins before building:

```sh
fstar.exe --version
"$(fstar.exe --locate_z3 4.13.3)" --version
```

## Bootstrap the OCaml switch

From the repository root, run:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
```

The bootstrap creates the `centl` switch with OCaml 4.14.1 when needed and
installs the exact dependencies from `centl.opam`. Set `CENTL_OPAM_SWITCH` to
use a different switch name.

## Build and test

Use the complete verified path at least once after changing F* or from a clean
checkout:

```sh
make test
```

Extraction refreshes the checked-in OCaml snapshot under `src/generated/`.
Commit that snapshot with every F* change; CI regenerates it with the pinned
verifier and rejects stale output. Keeping the snapshot in source releases lets
ordinary `opam install .` and Dune package builds run without an undeclared F*
dependency. After a successful extraction, the shorter native loop is:

```sh
make native-build
make native-test
```

Quality targets are checks and do not rewrite files:

```sh
make quality
```

`make quality` also runs CENTL's standard SHA-256 integrity process. It validates
the SHA-256 implementation against published known-answer vectors, generates a
deterministic `SHA256SUMS` manifest for every Git-tracked regular source file,
verifies the manifest against the checkout, hashes the manifest itself, and
checks the external supply-chain preservation pins. See
[`docs/INTEGRITY.md`](docs/INTEGRITY.md) and
[`docs/SUPPLY-CHAIN.md`](docs/SUPPLY-CHAIN.md).

The integrity receipt can be generated directly with:

```sh
make integrity-source
```

The receipt is written below `_build/integrity/`. A checksum mismatch is a
failure. Do not update an expected digest merely to make a mismatch pass.

`make format` checks OCaml and Dune formatting, while `make lint` compiles all
modules with development warnings, validates `centl.opam`, and checks that
toolchain pins agree. Apply formatter changes explicitly with
`make format-fix`.

## Supply-chain preservation

Maintainers should periodically preserve the complete current Linux development
inputs to FCF-controlled storage. Preservation requires a clean tracked worktree
so the source receipt can be bound to an exact Git commit:

```sh
make supply-chain-preserve \
  MIRROR=/srv/centl-mirror \
  MODEL=/path/to/active-centl-sci-model.gguf
```

This records the source SHA-256 receipt and commit alongside mirrored external
artifacts, source repositories, opam material, the instantiated Julia/Nemo depot,
and the exact CENTL-SCi model bytes. Copy the resulting mirror to a second
FCF-controlled location and preferably one offline copy.

## Differential testing

Instantiate the checked-in Julia manifest once, then run the seeded suite:

```sh
julia --startup-file=no --project=lab/julia \
  -e 'using Pkg; Pkg.instantiate()'
make differential-test
```

The suite compares CENTL's structured exact results with Nemo. Its random cases
use fixed seeds, so failures are reproducible.

## Pull requests

Open pull requests against `main`. Include the behavior being changed and the
commands used to validate it. Pull requests run one fast Linux verification,
quality, native-test, and Julia/Nemo job. Because `make quality` includes the
integrity gate, source SHA-256 verification and preservation-pin consistency are
part of the normal pull-request path rather than an optional release-only step.
Full native packaging remains on `main`, version tags, and manual
release-workflow runs.

## Developer Certificate of Origin

CENTL uses the **Developer Certificate of Origin 1.1** rather than a contributor
license agreement or copyright assignment. Every contribution must be signed off
by the contributor to certify that they have the right to submit it under the
license applicable to the contributed path.

Sign commits with:

```sh
git commit -s
```

This adds a line of the form:

```text
Signed-off-by: Your Name <you@example.com>
```

Use your real contribution identity and an email address you are authorized to
use. The complete certificate is in [`DCO.md`](DCO.md). By contributing, you are
not assigning your copyright to FCF; you are certifying the provenance and
licensing authority described by the DCO.

Software contributions are normally accepted under `Apache-2.0`. Documentation
and other paths may use the license identified in [`LICENSING.md`](LICENSING.md)
and [`.reuse/dep5`](.reuse/dep5). Do not remove or overwrite valid third-party
license notices.

## Math contracts (0.12 foundation)

Local claim checking without a full release:

```sh
./centl verify --left '0.1 + 0.2' --relation equal --right '3/10'
./centl verify --left 'sqrt(2)' --relation less_than --right '2'
./centl check tests/fixtures/contracts.centl
./centl check tests/fixtures/contracts.centl --json
```

Protocol: `op: "verify"`. MCP: `centl_verify`. See `docs/PROTOCOL.md` and
`docs/DESIGN_PATH.md`.
