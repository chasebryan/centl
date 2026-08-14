# Contributing to CENTL

CENTL welcomes contributions that make the system more correct, more reproducible, easier to understand, easier to preserve, or more useful for scientific work.

You do not have to be an OCaml or F* expert to contribute. Documentation, tests, mathematical counterexamples, reproducible bug reports, packaging work, preservation work, and CARAVAN participation are all meaningful contributions.

> **Free for science.**

## Ways to contribute

Useful contributions include:

- exact mathematics, algebra, calculus, verification, or physics improvements;
- parser, protocol, CLI, installer, packaging, or GNU/Linux integration work;
- CENTL-SCi interaction and evidence improvements;
- MIRAGE research, tests, provenance, candidate-admission, and self-development work;
- CARAVAN preservation, transport, security, policy, operator, and rollout work;
- adversarial tests, fuzz cases, regression cases, and independent differential checks;
- clear documentation and examples;
- reproducible bug reports with the smallest useful failing case;
- review that catches an unjustified numerical, security, or assurance claim.

A valuable contribution can also be a proof that an idea is wrong. CENTL would rather reject a beautiful mistake than print an unjustified digit.

## Supporting CENTL through CARAVAN

**Becoming part of CARAVAN is itself a form of project support.**

A CARAVAN carrier contributes bounded storage, bandwidth, and availability so approved Free Computation Foundation artifacts can be preserved across more than one machine, host, or provider. A carrier contributes availability, not authority: authenticated FCF metadata still defines which exact bytes are trusted.

Public volunteer network enrollment is currently gated. The existing join path can prepare and validate a carrier without silently activating public network service. As enrollment opens for qualified release channels, operating a carrier becomes a direct infrastructure contribution to CENTL and FCF.

CARAVAN participation is designed to remain voluntary, resource-capped, reversible, rootless for ordinary carriers, and unable to expose arbitrary local files or redefine trusted artifacts.

Start with:

- [`docs/CARAVAN.md`](docs/CARAVAN.md)
- [`docs/CARAVAN-JOIN-MANUAL.md`](docs/CARAVAN-JOIN-MANUAL.md)
- [`docs/CARAVAN-HOST-POLICY.md`](docs/CARAVAN-HOST-POLICY.md)
- [`docs/CARAVAN-THREAT-MODEL.md`](docs/CARAVAN-THREAT-MODEL.md)

Financial sponsorship is also available through [GitHub Sponsors](https://github.com/sponsors/chasebryan), but money is not the only useful form of support. Compute, storage, bandwidth, testing, review, documentation, and independent mathematical scrutiny all matter.

## Know the branch model before opening a pull request

CENTL has three long-lived branches with different responsibilities. The canonical policy is [`docs/RELEASE-POLICY.md`](docs/RELEASE-POLICY.md).

- **`mirage`** is the normal target for experimental features, prototypes, research, speculative mathematics, architecture exploration, and incomplete work.
- **`oasis`** is the authoritative stable-product branch. It is for release hardening, qualification repairs, and deliberately prepared promotions that are ready to satisfy the complete Oasis gate.
- **`main`** is the comprehensive developer/research distribution and integration view. Repository-wide documentation, tooling, integration, or source-tree work may target it when appropriate.

Do not target `oasis` merely because a feature is important. A feature normally matures elsewhere, then earns promotion by satisfying the stable-product qualification standard.

The current stable release is **CENTL v0.14.0**, the first published Oasis release. Stable product claims come from `oasis`; `main` may contain newer experimental work that has not inherited Oasis assurance.

## Development platform

Current CENTL engineering is **GNU/Linux-first**. GNU/Linux is the active platform for development, CI, packaging, validation, installation, and release work. macOS and Windows are not active support targets.

Historical portability material may remain in source history, but new contributions should not assume that macOS or Windows behavior is release-supported unless the platform policy changes explicitly.

See [`docs/SCI_PLATFORM_SUPPORT.md`](docs/SCI_PLATFORM_SUPPORT.md).

## Build architecture

The core build has three principal layers:

1. a verified F* semantic core;
2. a handwritten OCaml application and protocol layer;
3. native FLINT/GMP/MPFR bindings for rigorous numerical work.

The Julia/Nemo laboratory provides an independent mathematical oracle for differential validation. It is not required for every documentation or host-only change, but mathematical changes should run the applicable independent differential suite before promotion toward Oasis.

CENTL-SCi, MIRAGE, CARAVAN, installers, preservation tooling, and release automation add further component-specific tests and trust boundaries.

If the stack is unfamiliar, begin with [`docs/ONBOARDING.md`](docs/ONBOARDING.md).

## Canonical toolchain

Do not guess dependency versions from tutorials or system packages. The canonical versions are recorded in [`toolchain.lock`](toolchain.lock), while [`centl.opam`](centl.opam) defines the OCaml package constraints.

Current principal pins include:

- F* 2026.07.05;
- Z3 4.13.3;
- OCaml 4.14.1;
- Dune 3.24.1;
- FLINT 3.0.1;
- GMP 6.3.0;
- MPFR 4.2.2;
- OCamlFormat 0.29.0;
- Julia 1.12.6 and Nemo 0.56.1 for the independent laboratory.

When this document and `toolchain.lock` disagree, **`toolchain.lock` wins**.

## Prerequisites

Install at least:

- opam 2.1 or newer;
- a C compiler, GNU Make, and `pkg-config`;
- FLINT, GMP, and MPFR development headers;
- `curl`, `tar`, and the `libzstd` runtime for the pinned F* distribution;
- Julia only when running the independent differential laboratory.

On Ubuntu 24.04:

```sh
sudo apt-get update
sudo apt-get install --yes \
  build-essential ca-certificates curl libflint-dev libgmp-dev libmpfr-dev \
  libzstd1 make opam pkg-config tar
```

Release packaging uses the exact pinned native-library versions recorded in the repository. Distribution packages are the faster ordinary development setup.

## Install the pinned F* verifier

The repository pins the F* release and SHA-256 in `toolchain.lock`. The current values are:

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

Confirm the verifier and its supported Z3 before building:

```sh
fstar.exe --version
"$(fstar.exe --locate_z3 4.13.3)" --version
```

Never replace a failed expected checksum merely to make an installation pass.

## Bootstrap the OCaml switch

From the repository root:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
```

The bootstrap creates the `centl` switch with the pinned OCaml toolchain when needed and installs the exact project dependencies. Set `CENTL_OPAM_SWITCH` if you intentionally need another switch name.

## Baseline validation

For an ordinary source change, begin with:

```sh
make test
make quality
```

`make test` runs the verified extraction/build/test path. `make quality` performs non-mutating quality and integrity checks.

After a verified extraction has succeeded, the shorter native loop is:

```sh
make native-build
make native-test
```

Formatting checks do not rewrite source:

```sh
make format
```

Apply canonical formatting explicitly with:

```sh
make format-fix
```

Inspect the diff after formatter changes.

## F* changes

Never hand-edit `src/generated/`. Generated OCaml is a checked-in extraction artifact from the verified F* source.

The safe edit loop is:

```sh
make verify
make extract
git diff -- src/generated
make native-test
make quality
```

Commit the regenerated snapshot with the F* change. Hosted validation re-extracts with the pinned verifier and rejects stale generated output.

## Mathematical and rigorous-numerics changes

For changes that affect mathematical semantics, exactness, approximation, solving, calculus, native numerics, or result claims, run the independent differential laboratory where applicable:

```sh
julia --startup-file=no --project=lab/julia \
  -e 'using Pkg; Pkg.instantiate()'
make differential-test
```

High-risk parser, native, resource-boundary, protocol, or numerical changes should also run the relevant hardening, adversarial, sanitizer, fuzz, metamorphic, and performance checks defined by the repository.

A mathematical result should not be promoted merely because one implementation agrees with itself.

## Component-specific work

Do not treat the core test suite as proof that every subsystem is safe.

- **CENTL-SCi** changes should preserve the boundary between semantic interpretation and mathematical authority.
- **MIRAGE** changes must preserve provenance, non-mutation/admission boundaries, rollback, and the rule that generated material cannot promote its own assurance.
- **CARAVAN** changes must preserve the separation between availability and authority, resource ceilings, content identity, authenticated metadata, carrier isolation, and withdrawal.
- **Installer/release** changes must preserve archive, checksum, source identity, staging, activation, and publication integrity.

Use the component documentation and tests before changing those boundaries.

## Integrity and preservation

`make quality` includes CENTL's standard source-integrity process. A direct source-integrity receipt can be generated with:

```sh
make integrity-source
```

Receipts are written beneath `_build/integrity/`.

Maintainers may preserve the complete Linux development inputs to FCF-controlled storage with:

```sh
make supply-chain-preserve \
  MIRROR=/srv/centl-mirror \
  MODEL=/path/to/active-centl-sci-model.gguf
```

Preservation should be bound to an exact clean Git commit and copied to more than one FCF-controlled location where practical.

See [`docs/INTEGRITY.md`](docs/INTEGRITY.md) and [`docs/SUPPLY-CHAIN.md`](docs/SUPPLY-CHAIN.md).

## Pull-request expectations

A pull request should explain:

- what behavior or documentation is changing;
- why the change belongs on the selected target branch;
- the trust, mathematical, security, or compatibility boundary it affects, if any;
- the commands or evidence used to validate it;
- known limitations or deferred work.

Prefer small, reviewable semantic changes over large unrelated bundles.

Do not weaken a release, security, proof, or integrity check merely to make a branch green. If a check is wrong, fix the check and explain why it was wrong.

CENTL-SCi can prepare a local pack with `pack contribution` and, after an
explicit publish grant, open a **draft** pull request against `mirage`.
That path does not store tokens, does not target `oasis`, and does not
replace this human review. See [SCI.md](docs/SCI.md).

## Developer Certificate of Origin

CENTL uses the **Developer Certificate of Origin 1.1** rather than a contributor license agreement or copyright assignment.

Every contribution must be signed off:

```sh
git commit -s
```

This adds:

```text
Signed-off-by: Your Name <you@example.com>
```

Use an identity and email address you are authorized to use. The complete certificate is in [`DCO.md`](DCO.md).

By contributing, you do not assign your copyright to FCF. You certify the provenance and licensing authority described by the DCO.

Software contributions are normally accepted under `Apache-2.0`. Documentation and other paths may use the license identified in [`LICENSING.md`](LICENSING.md) and [`.reuse/dep5`](.reuse/dep5). Preserve valid third-party notices.

## Where to start

For a first contribution, choose one small thing you can completely understand and validate. A documentation correction, reproducible test case, clearer error, missing boundary test, or narrowly scoped mathematical improvement is better than a sprawling patch whose correctness nobody can explain.

CENTL is ambitious software. Contributions should make its claims easier to defend, not merely larger.
