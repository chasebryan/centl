# CENTL Oasis convergence engine

The authoritative stable-product convergence command is:

```sh
./scripts/oasis
```

A successful candidate run means every required local Oasis gate in the current
engine plan actually ran and passed. The command is deliberately fail-closed: it
does not convert unknown defects into green state, weaken tests, suppress security
findings, choose a release version, or silently skip a required gate.

## What the command does

The engine verifies the executing pinned toolchain, checks release-metadata
coherence, applies canonical formatting as the only automatic source repair, and
then runs verification, fresh generated-core extraction identity, repository
quality/integrity/supply-chain gates, native and Python tests, mandatory
sanitizer-backed hardening, fuzz/metamorphic/performance checks, differential
validation, CENTL-SCi interface checks, release packaging, hostile archive
validation, and isolated installation smoke probes.

Every executed gate receives a hard timeout. Complete command output is spooled to
per-gate logs and SHA-256 recorded. The run writes an atomic JSON evidence record
under `_build/oasis/`.

## Candidate versus final release proof

Normal convergence:

```sh
./scripts/oasis
```

Verification-only convergence without the formatting repair step:

```sh
./scripts/oasis --no-repair
```

Official snapshot of current main and mirage (never declares Oasis):

```sh
./scripts/oasis --snapshot
```

That report checks whether `main` and `mirage` trees match and whether
HEAD contains the oasis tip. It does not run gates.

Final release identity:

```sh
./scripts/oasis --final --no-repair
```

Final mode is stricter. It requires successful mandatory hosted Oasis checks for
the exact candidate commit, a clean checkout on the authoritative `oasis` branch,
exact `origin/oasis` identity, exact release-tag identity, and the final GitHub
release/security state required by the engine.

An empty hosted check set is a failure. A pending, skipped, neutral, failed, or
look-alike mandatory check is a failure. Mandatory hosted checks must be produced
by GitHub Actions and link to an Actions run. For v0.14.0, the hosted proof also
includes the dedicated release-security state check.

## Automatic repair boundary

The engine may run canonical source formatting. It does not automatically modify
semantic code, tests, security policy, release identity, branch history, or known
release blockers. Those states require a real corrective change followed by a new
Oasis run.

This boundary is intentional. The useful invariant is not "the script can hide
anything until green". It is:

> If the Oasis command completes successfully, every defined gate was actually
> discharged for that candidate.

## Release metadata coherence

The source version, changelog, release notes, README current-release status, and
version-specific Oasis status must agree. The engine refuses to infer which one is
"probably" correct. This prevents a partial promotion from acquiring a release
identity that the stable tree has not earned.

## Evidence and publication

Candidate evidence is written beneath:

```text
_build/oasis/<run-id>/
```

The hosted qualification also preserves the exact release archive produced by a
successful `oasis` push. Tag publication is allowed to consume those already
qualified bytes only after exact branch, tag, hosted-check, and release-state
identity is proven. The release workflow does not perform a new publication build.

A final Oasis declaration should retain the exact commit identity together with the
applicable hosted and local evidence.
