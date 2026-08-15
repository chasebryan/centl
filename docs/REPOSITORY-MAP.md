# CENTL Repository Map

This document describes the supported organization of the CENTL source tree and
its long-lived branch roles. It is an architectural map, not a promise that every
historical file or preservation artifact belongs to the stable runtime.

The authoritative branch and release rules are defined in
[`docs/RELEASE-POLICY.md`](RELEASE-POLICY.md).

## Root

The repository root is reserved for project-wide build, package, policy, licensing,
contributor, and entry-point material.

Key surfaces include:

- `README.md` — public project entry point: install and the three Oasis commands;
- `docs/README.md` — start-here index for the rest of the manuals;
- `site/` — public HTML/CSS site, including the hosted research library;
- `CHANGELOG.md` — chronological version history;
- `LICENSE`, `LICENSING.md`, `THIRD_PARTY_NOTICES.md`, `TRADEMARKS.md` — licensing and identity policy;
- `SECURITY.md` — supported security boundary, threat model, and reporting policy;
- `CONTRIBUTING.md` — contributor policy;
- `dune-project`, `centl.opam`, `Makefile`, `toolchain.lock` — authoritative build/dependency entry points;
- `install` — supported GNU/Linux installation entry point;
- `centl`, `executeme` — command/compatibility launch surfaces retained by the current distribution.

Version-specific one-shot release automation does not belong at the root or in
permanent CI after its release line is abandoned.

## `src/`

`src/` contains shipped implementation code.

The current tree includes the OCaml/F*/native numerical core, physics implementation,
command servers and protocol surfaces, CENTL-SCi, and the MIRAGE executable/modules.
Code in this directory is part of the security-review surface whenever it is
reachable from a shipped command, library, protocol, installer, or release artifact.

New implementation code should be grouped by subsystem and should not be placed in
`scripts/` merely because it is convenient to execute during development.

## `caravan/`

`caravan/` contains the Python implementation of the CARAVAN local laboratory.

CARAVAN has its own explicit trust boundary: carriers affect availability but never
define artifact authority. The directory contains content-addressed storage,
catalog/TUF handling, identity/policy enrollment, coordinator state, transport,
verified retrieval, lifecycle, and laboratory orchestration.

Production/public-network CARAVAN code must not be mixed into the Phase 1 laboratory
without satisfying the rollout and policy gates documented under `docs/`.

## `tests/`

`tests/` contains deterministic product and protocol tests. Subsystem-specific suites
should remain grouped, such as `tests/mirage/`.

Tests are evidence, not production authority. Fixtures should be bounded and should
not silently become runtime dependencies.

## `scripts/`

`scripts/` contains developer, validation, packaging, preservation, demonstration,
and operational helpers that are not themselves the primary shipped implementation.

A script that becomes a required runtime component should be promoted into an
appropriate implementation/package surface rather than remaining an accidental
helper.

`scripts/publish-site-library.py` turns public research notes and front-facing
manuals into the static HTML tree under `site/library/` and `site/manuals/`.

Release-specific repair scripts should be removed or archived once they no longer
serve a supported release path.

## `docs/`

`docs/` is the durable design, user, architecture, policy, and release-documentation
surface.

Important subsystem families include:

- CENTL core design, mathematics, numerics, verification, protocol, MCP, and installation;
- CENTL-SCi and Caramels BUILD/self-extension;
- CENTL-MIRAGE architecture;
- FCF Wellspring records under `docs/wellsprings/`;
- FCF Camp records under `docs/camps/`;
- the company and AI-software proposal in [`FCF-PROPOSAL.md`](FCF-PROPOSAL.md);
- CARAVAN architecture, threat model, host policy, rollout, transport, identity, catalog, and laboratory documentation;
- platform support and preservation/recovery documentation;
- branch and release policy;
- `docs/releases/` for durable release-specific notes.

Transient CI failure records do not belong in durable documentation.

## `assets/`

`assets/` contains project visual material. Branding should live under
`assets/branding/`; demonstrative screenshots and output images should be grouped
separately from canonical branding.

README assets should have stable descriptive names. Temporary upload names and
branch-specific image names should not become permanent interfaces.

## `.github/`

`.github/` contains repository automation and policy integration.

Permanent workflows should be capability-oriented rather than tied to a single
obsolete release number. Workflows must use least-privilege permissions, immutable
action pins, and safe trust boundaries for pull-request content and publication
credentials.

CI is intentionally branch-aware. `oasis` receives the complete Oasis qualification
gate, `mirage` receives a lighter development gate, and `main` receives integration
checks appropriate to the comprehensive tree. Oasis-only release qualification must
not be imposed indiscriminately on every branch.

One-shot release automation is removed after it ceases to describe a supported
release path.

## `lab/` and experimental surfaces

Laboratory or research material that is intentionally outside the stable runtime
should remain visibly separated from shipped core behavior. Experimental results
must not inherit verified-core or Oasis assurance through directory placement,
branch presence, or naming.

## Branches

CENTL has three long-lived branches with distinct responsibilities:

- **`oasis` — standard product.** This is the steadily advanced stable
  snapshot of current `main` and `mirage`. It is the only long-lived
  branch required to satisfy the full Oasis qualification standard.
  Stable releases are promoted and tagged from qualified Oasis commits.
  After a snapshot is promoted, development continues on `mirage` and
  `main`.
- **`mirage` — development and research laboratory.** New features, prototypes,
  experimental mathematics, architecture changes, and speculative work normally
  mature here. Mirage deliberately uses lighter development checks and is not
  required to satisfy every Oasis-only release gate.
- **`main` — complete developer and research distribution.** Main exposes the
  comprehensive codebase, including stable Oasis material and integrated
  Mirage-originated experimental facilities. Main is not itself an Oasis
  declaration.

The main README and other flagship public-product surfaces must use `oasis` as the
authoritative source for stable release/version identity, recommended capabilities,
installation claims, and other standard-product statements. Experimental material
present in `main` must remain visibly experimental rather than silently inheriting
Oasis status.

The ordinary maturity path is `mirage` -> `main` -> linear snapshot on
the oasis tip -> Oasis qualification -> `oasis`, then development
continues on `mirage` and `main`. `main` is an integrated distribution
view rather than another maturity stage.

Short-lived feature/fix branches are implementation vehicles, not long-term product
surfaces. `archive/*` or explicitly documented preservation refs may retain
historically important pre-merge states. Before deleting an old branch, compare it
to the appropriate long-lived line or otherwise establish that unique work is
intentionally discarded or preserved elsewhere.

The governing repository rule is:

> **Oasis is a promotion state of one exact snapshot, not a property of every commit.**

## Releases

Stable release tags use plain Semantic Versioning, for example `v0.14.0`, and are
cut from qualified `oasis` commits. **Oasis is not a codename or SemVer component.**
It is a repeatable quality declaration attached to a release only after that source
satisfies the repository's reconciliation, hardening, security, validation,
documentation, packaging, and reproducibility gates.

Release artifacts must be reproducible from the tagged Oasis commit through the
supported release workflow and must retain checksum/build-manifest identity before
activation or publication.
