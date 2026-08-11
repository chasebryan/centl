# The CENTL Oasis Release Standard

**Status:** authoritative stable-product policy  
**Applies to:** the `oasis` branch and stable releases cut from it  
**SemVer effect:** none

## Definition

An **Oasis release** is a CENTL release that has been deliberately reconciled,
organized, hardened, validated, and established as a cohesive stable baseline.

The lowercase `oasis` branch is CENTL's authoritative standard-product branch.
The branch name does not replace Semantic Versioning. Stable tags remain ordinary
versions such as `v0.14.0`.

Before every gate has passed, a proposed release is an **Oasis candidate**. Only
after qualification may the project state:

> **CENTL vX.Y.Z is an Oasis release.**

The canonical branch relationship is defined in
[`RELEASE-POLICY.md`](RELEASE-POLICY.md).

## Scope

Oasis quality is a promotion requirement, not a universal requirement for every
CENTL branch or development commit.

- `oasis` is the strict standard product and must satisfy the complete Oasis gate.
- `mirage` is the development and research laboratory and intentionally uses a
  lighter gate while work is experimental.
- `main` is the comprehensive developer and research distribution and may contain
  experimental material that has not inherited Oasis assurance.

The governing rule is:

> **Oasis is a promotion state, not a property of every commit.**

## Promotion

The ordinary maturity path is:

```text
feature / research work
         |
         v
      mirage
         |
         | stabilize + complete Oasis qualification
         v
       oasis
         |
         v
 stable release / tag
```

A change is not made stable merely by being useful, merged somewhere in the
repository, or present in `main`. Promotion into `oasis` is the point where the
strict product promise becomes applicable.

## Oasis gate

A release qualifies only when every applicable requirement below passes or is
explicitly documented as non-applicable.

### 1. Stable release boundary

- Intended stable features are present on the reviewed Oasis candidate.
- Partially integrated or superseded paths are removed, retired, or explicitly
  outside the stable boundary.
- Stable documentation describes shipped behavior rather than Mirage plans.
- Experimental systems cannot inherit stable or verified assurance by proximity.

### 2. Repository coherence

- Version, changelog, release notes, package metadata, installation claims, and
  public stable-product statements agree.
- Obsolete one-shot release or repair automation is removed from the active stable
  path.
- Generated debris and abandoned active-state artifacts are removed or deliberately
  preserved outside the supported runtime boundary.
- Pull requests targeting `oasis` that can affect the release are reconciled.

### 3. Security convergence

- No known unresolved release-blocking security finding remains.
- Security findings are repaired at source instead of hidden by weakening a gate
  solely to obtain a green result.
- GitHub Actions use appropriate least-privilege permissions and immutable action
  identities.
- Installer, archive, update, publication, dependency, and artifact-authentication
  boundaries are reviewed for the release.
- Applicable parser, protocol, native-library, model, MIRAGE, CARAVAN, filesystem,
  and process trust boundaries are reviewed.
- Realistic hostile-input boundaries have appropriate resource ceilings.

Oasis does not mean vulnerability-free. It means the defined release security
review has completed without knowingly concealing a release-blocking defect.

### 4. Validation convergence

- Required unit, integration, regression, component, and protocol tests pass.
- Applicable mathematical and F* verification gates pass.
- Required differential, sanitizer, fuzz, negative, and hardening tests pass.
- Dependency and GitHub security analysis pass.
- Component-specific gates pass for every component included in the stable product.
- A clean GNU/Linux build succeeds from the pinned toolchain and dependency state.

### 5. Installation and release integrity

- The supported package builds from the reviewed Oasis commit.
- Package identity and version metadata match the release.
- Release archives pass checksum and structural validation.
- Unsafe archive paths and unsupported filesystem semantics are rejected before
  activation.
- Installation uses the supported staged and validated activation path.
- Installed command surfaces pass required smoke tests.
- Any stronger authentication required by active signing policy is completed before
  claiming that property.

### 6. Documentation and trust honesty

- Stable-product documentation does not overstate capability, platform support,
  network deployment, proof strength, or assurance.
- Generated, external, model-produced, laboratory, and local-extension results stay
  visibly separated from verified-core claims.
- Mirage-originated capabilities remain identified as experimental until promoted.
- Deferred work is named as deferred.
- Release notes describe important security and operational boundaries.

### 7. Final Oasis identity

- The exact final candidate commit is reviewed and green.
- The candidate is the exact head of `oasis` and matches `origin/oasis`.
- Required Oasis and release workflows pass on that commit.
- No unresolved pull request targeting `oasis` remains capable of unexpectedly
  changing the candidate.
- The final `vX.Y.Z` tag points to that exact reviewed Oasis commit.

Only then is the Oasis declaration made.

## Evidence

Qualification evidence must preserve the final commit identity and the applicable
gate results. A green badge alone is insufficient if known release-blocking work
remains unresolved.

Conversely, unfinished Mirage experiments, research material in `main`, or
irrelevant historical refs do not invalidate a qualified Oasis release when they
lie outside the stable-product boundary.

## Independent qualification

Oasis status does not automatically carry forward from one release to another.
Each release must satisfy the standard independently.

This permits aggressive research and development on Mirage while preserving a
clear, evidence-backed boundary for the product CENTL publicly recommends.

## v0.14.0

CENTL v0.14.0 is the first release being deliberately qualified under this
standard.

Until every applicable gate is complete, its status is:

> **Oasis candidate**

After qualification closes, the declaration may become:

> **CENTL v0.14.0 is an Oasis release.**
