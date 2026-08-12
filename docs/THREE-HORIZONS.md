# CENTL: Three Horizons

**Compass directive for the holiday 2026 / New Year 2027 horizon**

> **Different systems. Same mathematics.**

Three Horizons is CENTL's current strategic direction for returning to first-class
cross-platform support after the Linux-first development period. The aim is a
future Oasis-qualified release set for **GNU/Linux, macOS, and Windows** derived
from one reviewed CENTL source lineage and governed by the same numerical
contract.

This document is a **compass directive, not a release promise**. Its schedule,
platform matrix, packaging design, release number, and implementation details may
change as the project learns. The direction is intentional; the exact route remains
open to evidence and improvement.

## Why this direction exists

CENTL narrowed active platform support to GNU/Linux so that mathematical,
scientific, verification, security, MIRAGE, SCi, and CARAVAN work could progress
without continuously multiplying platform-specific engineering costs.

That decision remains useful during rapid development. Three Horizons does not
reverse the Linux-first principle prematurely. Instead, it gives the project a
clear destination: once the core is mature enough, CENTL should deliberately
reunify its supported user base around a common, qualified scientific product.

The desired outcome is not merely that the source happens to compile on three
operating systems. The desired outcome is that users on the supported GNU/Linux,
macOS, and Windows targets receive the **same mathematical meaning, trust model,
verification behavior, and release identity**.

## Preferred release horizon

The preferred public horizon is **New Year 2027**, with the late-December 2026
holiday period serving as the qualification window.

The date is aspirational. CENTL must not weaken an Oasis gate, omit a required
platform, or publish an unqualified artifact merely to meet the calendar. If the
three supported targets have not earned the declaration, the release moves.

No Semantic Versioning number is committed by this directive. If CENTL has earned
`v1.0.0` maturity by that point, the milestone may be considered for it, but the
version must follow actual product maturity rather than symbolism.

## The Three Horizons objective

A Three Horizons Oasis should establish all of the following:

1. **One source lineage.** Supported platform artifacts are produced from the same
   qualified source identity, not independent platform forks.
2. **One numerical contract.** Exactness, enclosure, unresolved-result,
   verification, and rendering rules preserve the same mathematical meaning on
   every supported target.
3. **Native, deliberate distribution.** Each supported operating system has a
   documented installation and upgrade path appropriate to that platform. The
   exact architecture matrix will be fixed by the qualification plan rather than
   guessed in advance.
4. **Cross-platform conformance.** Shared deterministic corpora, protocol fixtures,
   mathematical tests, and representative scientific workflows are exercised
   across the supported targets and checked for semantic equivalence.
5. **Platform-specific hardening.** Filesystem behavior, process execution,
   terminal interaction, local-model integration, native libraries, packaging,
   permissions, paths, and update behavior are tested where they differ by OS.
6. **Reproducible release identity.** Published artifacts carry provenance,
   integrity metadata, checksums, dependency notices, and an auditable connection
   to the qualified Oasis source.
7. **Honest support claims.** A platform is called supported only when its build,
   install, runtime, and qualification path is actually maintained.

A platform compiling successfully is necessary but not sufficient. Three Horizons
is about **behavioral and mathematical parity**, not checkbox portability.

## Development model

Three Horizons must preserve the branch philosophy that gives CENTL room to move
quickly.

- **`mirage` remains the experimental laboratory.** Mirage work does not need to
  satisfy the final cross-platform Oasis matrix on every development commit.
- **`main` remains the complete developer and research distribution.** It may
  integrate portability work as the campaign develops.
- **`oasis` remains the stable product authority.** A Three Horizons release must
  cross the applicable Oasis qualification boundary for every platform it claims
  to support.

The governing idea is:

> **Mirage may move quickly. Oasis must arrive intact.**

Cross-platform restoration should therefore be staged late enough that it does not
turn every experimental feature into three simultaneous engineering projects, but
early enough that portability problems are discovered before the final release
freeze.

## Working campaign

The following sequence is directional and may be revised as evidence accumulates.

### August-September 2026: deepen the system

Continue the Linux-first development push. Prioritize mathematical breadth,
verification, SCi usability, MIRAGE architecture, CARAVAN maturity, tests,
security, documentation, and simplification of platform-sensitive assumptions.

Portable shared code should remain portable when that is natural, but speculative
work should not be blocked merely because Windows or macOS packaging has not yet
caught up.

### October 2026: portability audit

Begin an explicit audit of platform assumptions, including:

- paths, separators, symlinks, permissions, and filesystem semantics;
- subprocess creation and shell assumptions;
- terminal and interactive behavior;
- local model discovery and execution;
- dynamic/native library loading;
- toolchain bootstrap and dependency installation;
- packaging, installer, upgrade, and rollback behavior;
- architecture-sensitive numerical and FFI behavior.

The objective is to identify and isolate portability boundaries rather than spread
conditional logic throughout the scientific core.

### November 2026: restore qualification environments

Bring serious Windows and macOS build/test environments back into the release
engineering path. Establish platform-native packaging prototypes and begin running
the shared mathematical and protocol conformance suites across the emerging target
matrix.

Failures should be classified as semantic, numerical, toolchain, packaging,
platform, or infrastructure failures so that platform work does not hide genuine
scientific regressions.

### December 2026: freeze and qualify

Enter a bounded feature freeze for the candidate line. Run installation tests on
clean systems, deterministic cross-platform comparison, security review,
reproducibility checks, artifact provenance validation, upgrade/rollback tests,
and the complete applicable Oasis gate.

The project should prefer delaying the release over silently weakening the standard.

### New Year 2027: publish only if earned

If the supported GNU/Linux, macOS, and Windows targets all satisfy the declared
qualification matrix, publish the Three Horizons Oasis release set and document the
exact supported versions and architectures.

If one horizon is not ready, the declaration waits.

## Success criteria beyond release day

The milestone is successful only if cross-platform support remains maintainable
after publication. The project should monitor:

- installation success and failure by platform;
- platform-specific regression rates;
- CI and release-maintenance cost;
- mathematical conformance divergence;
- time required to qualify subsequent Oasis releases;
- real user demand on each supported target.

If a support promise becomes unsustainable, CENTL should narrow it honestly rather
than let an untested platform appear supported indefinitely.

## Relationship to the current Linux-first policy

Until a later Oasis release explicitly changes the support declaration, the current
stable support policy remains **GNU/Linux only**. macOS and Windows remain
unsupported during the preparatory period.

Three Horizons therefore describes where CENTL is aiming, not what the current
stable release already provides.

## Compass statement

CENTL is not pursuing portability for its own sake. It is pursuing a stronger
scientific promise:

> A researcher should be able to cross operating-system boundaries without
> crossing into different mathematics.

That is the Three Horizons direction.