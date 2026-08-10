# The CENTL Oasis Release Standard

**Status:** project release policy  
**Applies to:** any CENTL stable release  
**SemVer effect:** none

## Definition

An **Oasis release** is a CENTL release that has been deliberately reconciled, organized, hardened, validated, and established as a cohesive stable baseline.

Oasis is **not** a codename, version suffix, branch name, or permanent property of a release series. It is a declaration made only after a particular release independently satisfies the Oasis gate.

Before qualification, a release may be called an **Oasis candidate**. The declaration itself uses this form:

> **CENTL vX.Y.Z is an Oasis release.**

The Git tag remains ordinary Semantic Versioning, for example `v0.14.0`.

## Why the declaration exists

CENTL develops quickly across mathematics, physics, CENTL-SCi, MIRAGE, CARAVAN, preservation infrastructure, packaging, and repository automation. Individual feature merges can be correct while the repository as a whole accumulates stale release machinery, divergent documentation, unfinished branches, redundant paths, security debt, or unclear trust boundaries.

An Oasis declaration marks the opposite condition: a deliberately chosen point where the complete active system has been brought back into one understood and defensible state.

It is therefore a **convergence declaration**, not a marketing nickname.

## Oasis gate

A release qualifies only when every applicable requirement below is satisfied or explicitly documented as non-applicable.

### 1. Integrated release boundary

- The intended release features are present on the reviewed release commit.
- Partially integrated or superseded implementation paths are removed, retired, or clearly outside the supported boundary.
- Component documentation describes what is actually shipped rather than branch plans or future intent.
- Experimental systems are labeled honestly and cannot inherit verified/stable assurance by proximity.

### 2. Repository coherence

- The authoritative version, changelog, release notes, README, platform policy, and package metadata agree.
- Obsolete one-shot release/fix automation is removed from the active path.
- Temporary generated debris and abandoned active-state artifacts are removed or intentionally preserved outside the supported runtime boundary.
- Open pull requests and active branches that could affect the release are reconciled.
- Historical branches may remain when they preserve unique work; historical ref count alone does not defeat Oasis qualification.

### 3. Security convergence

- No known unresolved **release-blocking** security finding remains.
- Security findings are repaired at source rather than hidden by weakening a gate solely to obtain green CI.
- GitHub Actions use appropriate least-privilege permissions and immutable action identities.
- Installer, archive, update, publication, dependency, and artifact-authentication boundaries have been reviewed for the release.
- Shipped filesystem, process, parser, protocol, native-library, model, MIRAGE, and CARAVAN trust boundaries have been reviewed to the extent applicable.
- Resource ceilings exist at attacker-controlled or potentially hostile input boundaries where exhaustion is a realistic failure mode.

An Oasis declaration is not a claim that the release is free of every possible vulnerability. It means the project completed its defined release security review and is not knowingly concealing a release-blocking defect.

### 4. Validation convergence

- Required unit, integration, regression, component, and protocol tests pass on the final candidate.
- Relevant mathematical/F* verification gates pass.
- Required differential, sanitizer, fuzz, or negative tests pass where the release process defines them.
- Dependency review passes.
- GitHub Actions security analysis passes.
- Component-specific gates such as MIRAGE and CARAVAN pass when those components are included.
- A clean supported-platform build succeeds from the pinned toolchain/dependency state.

### 5. Installation and release integrity

- The supported release package can be built from the reviewed commit.
- Package identity/version metadata matches the release.
- Release archives pass checksum and structural validation.
- Archive extraction rejects unsafe paths and unsupported filesystem semantics before activation.
- Installation occurs through a staged, validated activation path.
- Installed command surfaces pass the required smoke tests.
- Any stronger release-authentication mechanism required by the active signing policy is satisfied before claiming that stronger authentication property.

### 6. Documentation and trust honesty

- Public documentation does not overstate implemented capability, platform support, network deployment, proof strength, or assurance.
- Generated, external, model-produced, laboratory, and local-extension results remain visibly separated from verified-core claims.
- Deferred work is named as deferred instead of being silently implied complete.
- The release notes state the important security and operational boundaries a user needs to understand.

### 7. Final-main identity

- The exact final candidate commit is reviewed and green.
- That candidate is integrated into `main` without changing its release semantics.
- Required final-main/release workflows pass for the integrated commit.
- The release tag points to the intended reviewed commit.

Only then is the Oasis declaration made.

## Evidence record

The release issue or equivalent release record should preserve enough evidence to explain why the declaration was justified, including the final commit identity and the applicable gate results.

Oasis is intentionally evidence-based. A green badge alone is insufficient if known release-blocking work remains unresolved; conversely, irrelevant historical branch clutter alone does not invalidate an otherwise coherent release.

## Independence between releases

Oasis status does not automatically carry forward.

If `v0.14.0` is an Oasis release, `v0.15.0` begins as an ordinary future release or Oasis candidate. It receives the declaration only after its own convergence process completes.

This allows CENTL to move quickly between convergence points without pretending every intermediate development state is equally solidified.

## After publication

An Oasis declaration records the release's qualification state at publication. A later-discovered vulnerability does not rewrite history, but it must be handled through the normal security policy, advisories, fixes, and supported-version decisions.

A later release may supersede an earlier Oasis release. The word **Oasis** does not mean permanently supported, invulnerable, or mathematically complete.

## v0.14.0

CENTL v0.14.0 is the first release being deliberately qualified under this standard.

Until every applicable gate is complete, its status is:

> **Oasis candidate**

When qualification closes, the project may replace that candidate status with:

> **CENTL v0.14.0 is an Oasis release.**
