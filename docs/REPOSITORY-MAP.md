# CENTL Repository Map

This document describes the supported organization of the CENTL source tree used to qualify v0.14.0 for an Oasis release declaration. It is an architectural map, not a promise that every historical file or preservation artifact belongs to the runtime.

## Root

The repository root is reserved for project-wide build, package, policy, licensing, contributor, and entry-point material.

Key surfaces include:

- `README.md` — public project entry point and supported-system overview;
- `CHANGELOG.md` — chronological version history;
- `LICENSE`, `LICENSING.md`, `THIRD_PARTY_NOTICES.md`, `TRADEMARKS.md` — licensing and identity policy;
- `SECURITY.md` — supported security boundary, threat model, and reporting policy;
- `CONTRIBUTING.md` — contributor policy;
- `dune-project`, `centl.opam`, `Makefile`, `toolchain.lock` — authoritative build/dependency entry points;
- `install` — supported GNU/Linux installation entry point;
- `centl`, `executeme` — command/compatibility launch surfaces retained by the current distribution.

Version-specific one-shot release automation does not belong at the root or in permanent CI after its release line is abandoned.

## `src/`

`src/` contains shipped implementation code.

The current tree includes the OCaml/F*/native numerical core, physics implementation, command servers and protocol surfaces, CENTL-SCi, and the MIRAGE executable/modules. Code in this directory is part of the security-review surface whenever it is reachable from a shipped command, library, protocol, installer, or release artifact.

New implementation code should be grouped by subsystem and should not be placed in `scripts/` merely because it is convenient to execute during development.

## `caravan/`

`caravan/` contains the Python implementation of the CARAVAN local laboratory.

CARAVAN has its own explicit trust boundary: carriers affect availability but never define artifact authority. The directory contains content-addressed storage, catalog/TUF handling, identity/policy enrollment, coordinator state, transport, verified retrieval, lifecycle, and laboratory orchestration.

Production/public-network CARAVAN code must not be mixed into the Phase 1 laboratory without satisfying the rollout and policy gates documented under `docs/`.

## `tests/`

`tests/` contains deterministic product and protocol tests. Subsystem-specific suites should remain grouped, such as `tests/mirage/`.

Tests are evidence, not production authority. Fixtures should be bounded and should not silently become runtime dependencies.

## `scripts/`

`scripts/` contains developer, validation, packaging, preservation, demonstration, and operational helpers that are not themselves the primary shipped implementation.

A script that becomes a required runtime component should be promoted into an appropriate implementation/package surface rather than remaining an accidental helper.

Release-specific repair scripts should be removed or archived once they no longer serve a supported release path.

## `docs/`

`docs/` is the durable design, user, architecture, policy, and release-documentation surface.

Important subsystem families include:

- CENTL core design, mathematics, numerics, verification, protocol, MCP, and installation;
- CENTL-SCi and Caramels BUILD/self-extension;
- CENTL-MIRAGE architecture;
- CARAVAN architecture, threat model, host policy, rollout, transport, identity, catalog, and laboratory documentation;
- platform support and preservation/recovery documentation;
- `docs/releases/` for durable release-specific notes.

Transient CI failure records do not belong in durable documentation.

## `assets/`

`assets/` contains project visual material. Branding should live under `assets/branding/`; demonstrative screenshots and output images should be grouped separately from canonical branding.

README assets should have stable descriptive names. Temporary upload names and branch-specific image names should not become permanent interfaces.

## `.github/`

`.github/` contains repository automation and policy integration.

Permanent workflows should be capability-oriented rather than tied to a single obsolete release number. Workflows must use least-privilege permissions, immutable action pins, and safe trust boundaries for pull-request content and publication credentials.

One-shot release automation is removed after it ceases to describe a supported release path.

## `lab/` and experimental surfaces

Laboratory or research material that is intentionally outside the stable runtime should remain visibly separated from shipped core behavior. Experimental results must not inherit verified-core assurance through directory placement or naming.

## Branches

`main` is the canonical integrated source line.

Short-lived feature/fix branches are implementation vehicles, not long-term product surfaces. `archive/*` or explicitly documented preservation refs may retain historically important pre-merge states. Before deleting an old branch, compare it to current `main` or otherwise establish that unique work is intentionally discarded or preserved elsewhere.

Oasis qualification does not treat the existence of old remote refs as a runtime defect; the release hygiene goal is to eliminate ambiguous *active* development state while preserving history safely.

## Releases

Stable release tags use plain Semantic Versioning, for example `v0.14.0`. **Oasis is not a codename or SemVer component.** It is a repeatable quality declaration attached to a release only after that release satisfies the repository's reconciliation, hardening, security, and validation gate.

Release artifacts must be reproducible from the tagged commit through the supported release workflow and must retain checksum/build-manifest identity before activation or publication.
