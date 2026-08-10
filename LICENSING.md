# CENTL licensing

CENTL uses a deliberately simple licensing architecture intended to maximize scientific, public-sector, academic, and commercial adoption while keeping the project free to use, study, modify, redistribute, preserve, and fork.

## Software

Unless a file or directory says otherwise, FCF-owned software in this repository is licensed under the **Apache License 2.0** (`Apache-2.0`). This includes the CENTL mathematical kernel and language, CENTL-SCi, CENTL Physics, CENTL-MIRAGE, CENTL CARAVAN, protocols, command-line interfaces, libraries, tests, examples, build and release tooling, and project-owned supporting code.

Apache-2.0 permits commercial and noncommercial use, modification, redistribution, private use, and incorporation into larger systems. It also provides an explicit patent grant from contributors, subject to the license terms. No field-of-use restriction, account, fee, hosted service, or separate commercial license is required to exercise the software rights granted by Apache-2.0.

The canonical software license text is [`LICENSE`](LICENSE). SPDX identifier: `Apache-2.0`.

## Documentation

FCF-owned prose documentation, manuals, tutorials, diagrams, and documentation-only explanatory material identified by [`.reuse/dep5`](.reuse/dep5) are licensed under **Creative Commons Attribution 4.0 International** (`CC-BY-4.0`).

CC BY 4.0 permits copying, redistribution, adaptation, and commercial use with attribution and the other conditions of that license. The canonical text is in [`LICENSES/CC-BY-4.0.txt`](LICENSES/CC-BY-4.0.txt).

Code samples that are intended to be copied into programs may be used under Apache-2.0 unless the surrounding material explicitly says otherwise.

## Names, logos, mascots, and branding

Software and documentation licenses do not grant a general right to use FCF or CENTL branding as the identity of a different product or organization. The project names, logos, mascots, and distinctive release artwork identified in [`.reuse/dep5`](.reuse/dep5) are governed by [`TRADEMARKS.md`](TRADEMARKS.md) and [`LICENSES/LicenseRef-FCF-Branding.txt`](LICENSES/LicenseRef-FCF-Branding.txt).

This separation protects users from confusing unofficial forks with official CENTL releases without restricting the right to fork, modify, or redistribute the Apache-licensed software itself.

## Third-party material

This licensing change does **not** relicense third-party software, model weights, imported assets, dependencies, or other material that CENTL does not have authority to relicense. Those components remain under their respective upstream terms. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md), release-package license directories, and the provenance records associated with model artifacts.

Model weights remain separate artifacts and are not covered by the repository's Apache-2.0 grant merely because CENTL can load or preserve them.

## Contributions

Contributions are accepted under the license applicable to the contributed path. Contributors certify provenance through the **Developer Certificate of Origin 1.1** in [`DCO.md`](DCO.md) by adding a `Signed-off-by:` line to each contribution. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

No contributor license agreement or copyright assignment is required for ordinary contributions.

## Earlier AGPL releases

CENTL versions and source copies that were already distributed under `AGPL-3.0-or-later` remain available under the license terms granted with those copies. This migration does not revoke previously granted AGPL rights.

The repository transition to Apache-2.0 applies to the project-owned material for which the relevant copyright holders have authority to make that grant. The migration provenance review is recorded in [`docs/RELICENSING-2026-08-10.md`](docs/RELICENSING-2026-08-10.md).

If material is later discovered for which the project does not have relicensing authority, that material must retain its valid prior license until permission is obtained or the material is replaced or removed.

## Philosophy

> Good maths should be free.

For CENTL, that means scientific computation should be usable without asking permission from FCF, without a discriminatory field-of-use clause, without mandatory payment, and without dependence on a remote service. Apache-2.0 is the common software license used to make that freedom practical across individual, academic, government, nonprofit, and commercial environments.
