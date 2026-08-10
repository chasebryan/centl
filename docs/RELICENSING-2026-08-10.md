# CENTL relicensing record — 2026-08-10

## Decision

The Free Computation Foundation licensing policy for CENTL changes the default license for project-owned software from `AGPL-3.0-or-later` to `Apache-2.0` and separately licenses project-owned documentation under `CC-BY-4.0`.

The purpose is to preserve free-software rights while reducing adoption friction for scientific, academic, government, nonprofit, and commercial users. Branding remains separate so unofficial forks can be distinguished from official CENTL/FCF releases.

## Repository provenance review

Before preparing the migration, repository history and current content were reviewed for obvious independent copyright interests and conflicting license declarations.

The review included:

- pull-request authorship across the repository history available through GitHub;
- searches for pull requests not authored by `chasebryan`;
- commit co-author markers;
- repository copyright notices;
- the existing root `LICENSE` and package metadata;
- release-packaging treatment of F*, OCaml, Zarith, Yojson, FLINT, GMP, and MPFR;
- the separate provenance and redistribution boundary for CENTL-SCi models and llama.cpp-derived runtime material.

### Findings

The only pull requests found outside the primary repository owner account in the reviewed history were automated Dependabot dependency-update pull requests. No independent human-authored pull request was identified by that search. Co-author searches identified automation/bot attribution but did not identify an independent human copyright holder that would obviously block relicensing of the project-owned code.

The repository already treats external numerical libraries, toolchains, inference runtimes, and model artifacts as third-party material with separate licenses/provenance. Those materials are **not** relicensed by this change.

This is a repository provenance audit, not a representation that every possible copyright fact can be proven from Git metadata alone.

## Transition rule

Project-owned material for which the relevant copyright holder has authority to grant a new license is offered under the new license indicated by `LICENSING.md` and `.reuse/dep5` beginning with the merge of this migration.

Previously distributed CENTL copies and releases under `AGPL-3.0-or-later` keep the AGPL rights granted with those copies. Those grants are not revoked.

If later review identifies material that CENTL/FCF does not have authority to relicense, that material must remain under its valid prior/upstream license until one of the following occurs:

1. the relevant copyright holder gives the necessary permission;
2. the material is replaced with independently licensed material; or
3. the material is removed.

No third-party material should be silently reclassified as Apache-2.0 merely because it is stored in the repository.

## Contribution policy after migration

New contributions use the license applicable to the contributed path and must carry Developer Certificate of Origin 1.1 sign-off as described in `CONTRIBUTING.md` and `DCO.md`. Ordinary contributors are not required to assign their copyright to FCF or sign a separate CLA.

## License map

- FCF-owned software and supporting code: `Apache-2.0`
- FCF-owned documentation identified in `.reuse/dep5`: `CC-BY-4.0`
- FCF/CENTL distinctive branding identified in `.reuse/dep5`: `LicenseRef-FCF-Branding` / `TRADEMARKS.md`
- third-party dependencies, models, imported assets, and data: their respective upstream terms

See `LICENSING.md` for the current project-wide policy.
