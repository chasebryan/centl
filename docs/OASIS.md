# The CENTL Oasis Release Standard

**Status:** project release policy  
**Applies to:** CENTL stable-product qualification on the `oasis` branch  
**SemVer effect:** none

## Definition

An **Oasis release** is a CENTL release that has been deliberately reconciled,
organized, hardened, validated, and established as a cohesive stable baseline.

The Oasis declaration is not a version suffix or marketing codename. The lowercase
`oasis` branch is the repository's authoritative standard-product branch and is
named for the qualification line defined by this document.

Oasis quality is deliberately **not** imposed on every branch or every commit.
Development can remain fluid on `mirage`, and `main` can carry the comprehensive
research and developer distribution without pretending that every integrated
experiment is release-ready.

Before qualification, a proposed stable release may be called an **Oasis
candidate**. The declaration itself uses this form:

> **CENTL vX.Y.Z is an Oasis release.**

The Git tag remains ordinary Semantic Versioning, for example `v0.14.0`.

The canonical branch roles are defined in
[`RELEASE-POLICY.md`](RELEASE-POLICY.md). This document defines the stricter
standard that must be satisfied when work is promoted into the stable-product
line.

## Why the declaration exists

CENTL develops quickly across mathematics, physics, CENTL-SCi, MIRAGE, CARAVAN,
preservation infrastructure, packaging, and repository automation. Individual
feature merges can be useful while the broader system still contains unfinished
research, incomplete integrations, security debt, or unresolved release work.

Requiring every development state to be Oasis-ready would make the experimental
line unnecessarily rigid and would blur the distinction between research and
product promises.

An Oasis declaration marks the opposite condition: a deliberately chosen point
where the intended stable product has been brought into one understood,
reproducible, and defensible state.

It is therefore a **convergence declaration and promotion state**.

## Branch relationship

The ordinary maturity path is:

```text
feature / research work
         |
         v
      mirage
         |
         | stabilize + satisfy the complete Oasis gate
         v
       oasis
         |
         v
 stable release / tag
```

`main` is not another maturity rung. It is the complete developer and research
distribution and may contain both stable Oasis material and integrated experimental
facilities.

The governing rule is:

> **Oasis is a promotion state, not a property of every commit.**

## Executable convergence engine

The comprehensive repository provides `scripts/oasis.py` as the executable
implementation of the local Oasis gate. The engine may be developed and tested in
the broader source tree before its own changes are promoted to `oasis`.

For a normal candidate convergence pass, run:

```bash
python3 scripts/oasis.py
```

The command performs the one intentionally safe automatic repair currently allowed
by the Oasis process, canonical source formatting, and then runs the complete local
qualification plan. It fails closed on missing tools, proof failures, stale
generated F* extraction, quality failures, unit or component failures, sanitizer
unavailability, hardening failures, differential-test failures, release-package
failures, unsafe archive structure, checksum mismatch, or installed-binary
smoke-test failure.

It does **not** rewrite tests, weaken security policy, disable failing gates,
silently accept skipped required checks, merge branches, close pull requests,
create tags, or declare an unresolved repository green.

The final publication identity pass is stricter:

```bash
python3 scripts/oasis.py --final --no-repair
```

`--final` requires the checked commit to be clean `oasis`, exactly match
`origin/oasis`, exactly match the current `vX.Y.Z` tag, have no unresolved pull
requests targeting `oasis`, have no non-green commit checks, have no open
high/critical code-scanning or Dependabot alerts, and have no open secret-scanning
alerts visible to the authenticated GitHub CLI.

Each run writes an atomic JSON evidence record plus SHA-256-addressed gate logs
beneath `_build/oasis/`. The evidence distinguishes candidate qualification from
final-Oasis qualification. A local candidate pass is useful convergence evidence,
but it cannot impersonate the final release declaration.

The engine is adversarially tested in `tests/test_oasis.py`, including command
failure, timeout, missing-tool, stale-extraction ordering, mandatory sanitizer,
checksum corruption, path traversal, absolute paths, symlinks, missing package
members, wrong versions, evidence atomicity, exact Oasis branch identity, Oasis PR
targeting, and release-blocking security-alert cases.

## Oasis gate

A release qualifies only when every applicable requirement below is satisfied or
explicitly documented as non-applicable.

### 1. Stable release boundary

- The intended stable features are present on the reviewed Oasis candidate commit.
- Partially integrated or superseded implementation paths are removed, retired, or
  clearly outside the supported stable boundary.
- Component documentation describes what is actually shipped rather than Mirage
  plans or future intent.
- Experimental systems are labeled honestly and cannot inherit verified or stable
  assurance merely because they also exist in `main`.

### 2. Repository coherence

- The authoritative version, changelog, release notes, Oasis-facing README claims,
  platform policy, and package metadata agree.
- Obsolete one-shot release or repair automation is removed from the active stable
  path.
- Temporary generated debris and abandoned active-state artifacts are removed or
  intentionally preserved outside the supported runtime boundary.
- Pull requests targeting `oasis` that could affect the release are reconciled.
- Historical branches may remain when they preserve unique work. Historical ref
  count alone does not defeat Oasis qualification.

### 3. Security convergence

- No known unresolved **release-blocking** security finding remains.
- Security findings are repaired at source rather than hidden by weakening a gate
  solely to obtain green CI.
- GitHub Actions use appropriate least-privilege permissions and immutable action
  identities.
- Installer, archive, update, publication, dependency, and artifact-authentication
  boundaries have been reviewed for the release.
- Shipped filesystem, process, parser, protocol, native-library, model, MIRAGE, and
  CARAVAN trust boundaries have been reviewed to the extent applicable.
- Resource ceilings exist at attacker-controlled or potentially hostile input
  boundaries where exhaustion is a realistic failure mode.

An Oasis declaration is not a claim that the release is free of every possible
vulnerability. It means the project completed its defined release security review
and is not knowingly concealing a release-blocking defect.

### 4. Validation convergence

- Required unit, integration, regression, component, and protocol tests pass on the
  final Oasis candidate.
- Relevant mathematical and F* verification gates pass.
- Required differential, sanitizer, fuzz, or negative tests pass where the release
  process defines them.
- Dependency review passes.
- GitHub Actions security analysis passes.
- Component-specific gates such as MIRAGE and CARAVAN pass when those components
  are included in the stable product.
- A clean supported-platform build succeeds from the pinned toolchain and
  dependency state.

### 5. Installation and release integrity

- The supported release package can be built from the reviewed Oasis commit.
- Package identity and version metadata match the release.
- Release archives pass checksum and structural validation.
- Archive extraction rejects unsafe paths and unsupported filesystem semantics
  before activation.
- Installation occurs through a staged, validated activation path.
- Installed command surfaces pass the required smoke tests.
- Any stronger release-authentication mechanism required by the active signing
  policy is satisfied before claiming that stronger authentication property.

### 6. Documentation and trust honesty

- Public stable-product documentation does not overstate implemented capability,
  platform support, network deployment, proof strength, or assurance.
- Generated, external, model-produced, laboratory, and local-extension results
  remain visibly separated from verified-core claims.
- Mirage and other experimental capabilities are identified as experimental until
  promoted through the Oasis gate.
- Deferred work is named as deferred instead of being silently implied complete.
- Release notes state the important security and operational boundaries a user
  needs to understand.

### 7. Final-Oasis identity

- The exact final candidate commit is reviewed and green.
- That candidate is the exact head of `oasis` and matches `origin/oasis`.
- Required Oasis and release workflows pass for that commit.
- No unresolved pull request targeting `oasis` remains capable of changing the
  release candidate unexpectedly.
- The release tag points to the intended reviewed Oasis commit.

Only then is the Oasis declaration made.

`main` may subsequently integrate or expose the same stable state as part of the
complete developer/research distribution, but `main` does not become the authority
for the Oasis declaration by doing so.

## Evidence record

The release issue or equivalent release record should preserve enough evidence to
explain why the declaration was justified, including the exact Oasis commit
identity and the applicable gate results.

Oasis is intentionally evidence-based. A green badge alone is insufficient if
known release-blocking work remains unresolved. Conversely, unfinished Mirage work
or irrelevant historical branch clutter does not invalidate a qualified Oasis
release when that work lies outside the stable release boundary.

## Independence between releases

Oasis status does not automatically carry forward.

If `v0.14.0` is an Oasis release, `v0.15.0` begins as a future Oasis candidate. It
receives the declaration only after its own convergence process completes on the
`oasis` line.

This allows CENTL to move quickly in Mirage between convergence points without
pretending every intermediate development state is equally solidified.

## After publication

An Oasis declaration records the release's qualification state at publication. A
later-discovered vulnerability does not rewrite history, but it must be handled
through the normal security policy, advisories, fixes, and supported-version
decisions.

A later release may supersede an earlier Oasis release. The word **Oasis** does not
mean permanently supported, invulnerable, or mathematically complete.

## v0.14.0

CENTL v0.14.0 is the first release being deliberately qualified under this
standard.

Until every applicable gate is complete on the authoritative Oasis candidate, its
status is:

> **Oasis candidate**

When qualification closes, the project may replace that candidate status with:

> **CENTL v0.14.0 is an Oasis release.**
