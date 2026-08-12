# The CENTL Oasis Release Standard

**Status:** active project release standard  
**Applies to:** stable-product qualification on the `oasis` branch  
**SemVer effect:** none

## Definition

An **Oasis release** is a CENTL release that has been deliberately reconciled, organized, hardened, validated, and established as a cohesive stable baseline.

Oasis is not a version suffix and not a codename. It is a **quality declaration attached to an exact release identity**.

The canonical declaration is:

> **CENTL vX.Y.Z is an Oasis release.**

The Git tag remains ordinary Semantic Versioning, such as `v0.14.0`.

**CENTL v0.14.0 is the first published Oasis release.**

## Why Oasis exists

CENTL develops across mathematics, physics, CENTL-SCi, MIRAGE, CARAVAN, preservation infrastructure, packaging, verification, and release automation. Useful development can move quickly without every experimental commit satisfying the complete stable-release standard.

Oasis marks the opposite condition: a deliberately chosen convergence point where the supported product, its source identity, its documentation, its security posture, its tests, and its published bytes have been brought into one defensible state.

The governing rule is:

> **Oasis is a promotion state, not a property of every commit.**

## Branch relationship

CENTL has three long-lived branches:

- **`oasis`** is the authoritative stable-product branch and the only long-lived branch required to satisfy the complete Oasis qualification standard;
- **`mirage`** is the development and research laboratory where features, prototypes, experiments, and incomplete work normally mature;
- **`main`** is the complete developer/research distribution and integration view and may contain work newer than the stable product.

The normal maturity path is:

```text
feature / research work
         |
         v
      mirage
         |
         | stabilize + satisfy Oasis qualification
         v
       oasis
         |
         v
 stable release / tag
```

`main` is an integration view, not another maturity rung.

See [`RELEASE-POLICY.md`](RELEASE-POLICY.md) for the canonical branch rules.

## What earns the declaration

An Oasis release must satisfy the applicable requirements below on the exact source identity that will be published.

### 1. Stable product boundary

- Supported command surfaces and capabilities are explicit.
- Experimental source does not silently inherit stable assurance.
- Partially integrated or superseded paths are removed, retired, or clearly outside the supported product.
- Platform support claims match the actual release boundary.

### 2. Repository coherence

- Version metadata, changelog, release notes, README, installer, package metadata, and platform policy agree.
- Obsolete one-shot release machinery is removed from the active path.
- Temporary debris and abandoned active-state artifacts are removed or deliberately preserved outside the runtime boundary.
- Pull requests capable of changing the candidate are reconciled before final publication.

### 3. Mathematical and verification integrity

- Required deterministic, unit, integration, regression, and protocol tests pass.
- Applicable F* verification and fresh extraction checks pass.
- Mathematical changes receive the required independent differential validation.
- Exactness, approximation, enclosure, proof, and assurance claims remain distinguishable and defensible.
- Generated or model-produced semantics cannot promote their own authority.

### 4. Security convergence

- No known unresolved release-blocking security finding is hidden or ignored.
- Relevant native, parser, filesystem, protocol, resource, installer, release, MIRAGE, CARAVAN, and supply-chain boundaries are reviewed.
- Mandatory hardening checks such as sanitizers, fuzzing, adversarial tests, metamorphic tests, or performance/resource checks run where the release plan requires them.
- GitHub Actions and publication paths use appropriate least privilege and immutable identities where required.
- Security findings are repaired at source rather than suppressed merely to obtain a green result.

An Oasis declaration is not a claim of invulnerability. It is evidence that the defined release security review was completed for the declared boundary.

### 5. Installation and release integrity

- The release package is built from the reviewed source identity.
- Archive structure and exact membership are validated.
- Checksums and embedded build identity agree with the qualified artifact.
- Unsafe archive paths, links, or special entries are rejected before activation.
- Installation stages and smoke-tests the package before replacing active software.
- Publication does not substitute a new build for already-qualified bytes.

### 6. Documentation honesty

- Public documentation describes what is actually stable and shipped.
- Experimental or later main-line work is labeled as such.
- Deferred work is named as deferred.
- Platform, network, model, proof, and assurance claims are not broader than the evidence.
- Stable installation instructions come from the `oasis` authority rather than a mutable experimental branch.

### 7. Exact final identity

The declaration belongs only to the exact release identity that passed qualification.

The final publication path must bind together:

- the qualified source commit;
- the `oasis` branch identity;
- the intended `vX.Y.Z` tag;
- the mandatory hosted checks and their provenance;
- the qualified release artifact and checksum;
- the published release bytes.

A tag never authorizes a substitute build.

## The executable Oasis gate

The repository provides `scripts/oasis.py` as the local convergence engine.

A normal candidate pass is:

```sh
python3 scripts/oasis.py
```

The engine performs the safe repair actions explicitly allowed by policy and runs the local qualification plan. It fails closed on missing required tools, proof failure, stale extraction, quality failure, required hardening failure, differential failure, package failure, unsafe archive structure, integrity failure, or installed-binary smoke-test failure.

It does **not** rewrite tests, weaken security policy, merge branches, close pull requests, create a release tag, or declare unresolved work green.

A final identity pass uses:

```sh
python3 scripts/oasis.py --final --no-repair
```

Final qualification additionally requires the exact Oasis branch/tag/repository identity and applicable hosted security/release state defined by the current release machinery.

Each run writes machine-readable evidence beneath `_build/oasis/`.

## Stable release authority

Public stable claims are derived from `oasis`.

That includes:

- recommended stable version;
- supported platforms;
- installed command surfaces;
- stable capability claims;
- release qualification status;
- ordinary installation instructions.

`main` can expose newer MIRAGE, CARAVAN, semantic-origin, research, or integration work, but repository presence alone does not expand the Oasis promise.

## v0.14.0

**CENTL v0.14.0 is an Oasis release.**

It is the first release published under this standard and the stable successor to v0.12.0. The v0.13.0 development line was not published as a stable release.

The standard v0.14.0 native release boundary is GNU/Linux x86_64 and installs:

- `centl`;
- `centl-sci`;
- `centl-physics`.

The source baseline contains bounded MIRAGE and CARAVAN work, but those systems do not become public installed commands merely by being present in source.

## Independence between releases

Oasis status does not automatically carry forward.

If v0.14.0 is an Oasis release, a later v0.15.0 begins as a future candidate and earns its own declaration only after its own exact source and publication identity satisfy the then-current Oasis gate.

This allows development to remain fluid without diluting the meaning of a convergence declaration.

## After publication

An Oasis declaration records the evidence-backed state at publication. A later-discovered vulnerability does not erase history, but it must be handled through the normal security, advisory, remediation, and supported-version process.

Oasis means **qualified at the declared boundary**. It does not mean permanently supported, mathematically complete, or immune to future discoveries.
