# CENTL Security Policy

CENTL treats numerical integrity, release integrity, and ordinary software security as parts of the same trust problem. A system that safely parses input but silently overstates mathematical certainty is not trustworthy, and a mathematically correct release whose bytes can be substituted is not trustworthy either.

## Supported versions

The current supported stable series is **CENTL 0.14.x**.

| Version / line | Status |
| --- | --- |
| 0.14.x | Supported stable series |
| `oasis` | Authoritative stable-product branch |
| `main` | Active developer/research distribution; security reports accepted |
| `mirage` | Active experimental line; security reports accepted for reachable repository-controlled boundaries |
| 0.13.0 | Never published as a stable release |
| 0.12.x and earlier | No longer supported as the current stable series |

CENTL v0.14.0 is the current published **Oasis release**. Oasis qualification records a reviewed release boundary; it is not a claim that nontrivial software is free of every possible vulnerability.

## Reporting a vulnerability

Use GitHub's private [Report a vulnerability](https://github.com/chasebryan/centl/security/advisories/new) form.

**Do not open a public issue for an undisclosed vulnerability.**

Please include, where available:

- affected version, branch, tag, or commit;
- GNU/Linux distribution and architecture;
- reachable interface or trust boundary;
- expected and observed behavior;
- realistic impact;
- minimal reproduction steps or proof of concept;
- any useful mitigation or root-cause analysis.

Do not include real credentials, private user data, or exploit material unrelated to demonstrating the issue. Maintainers will use the private advisory to coordinate validation, remediation, credit, and disclosure.

## Security scope

The policy covers repository-controlled security boundaries including:

- the F* semantic core and generated extraction path;
- the OCaml parser, evaluator, CLI, history, JSON Lines, and MCP interfaces;
- native FLINT/Arb/GMP/MPFR bindings;
- CENTL-SCi and local semantic-model integration;
- MIRAGE ingestion, provenance, candidate staging, evidence, and workspace boundaries;
- CARAVAN content identity, catalog, carrier, transfer, storage, enrollment, census, coordinator, and public-origin work;
- installers, archives, checksums, release packaging, publication, and recovery paths;
- GitHub Actions and release automation;
- preservation and supply-chain tooling.

The standard CENTL core and CENTL-SCi surfaces are local-first rather than general remote network services. Applications that expose CENTL's stdio protocols to less-trusted callers must still treat expressions, scripts, JSON, MCP messages, identifiers, timing, and resource usage as attacker-controlled input.

## Core security invariants

CENTL security review is organized around invariants rather than a list of fashionable vulnerability names.

### Numerical and semantic integrity

- Decimal and integer input must not be silently narrowed through floating point or a fixed-width integer before exact interpretation and bounds checks.
- Exact, approximate, residual, unsupported, indeterminate, and assurance-bearing results must remain distinguishable across terminal and machine interfaces.
- Generated, external, or semantic-model output cannot promote its own assurance or override mathematical evidence.
- A model may interpret intent; it is not mathematical authority.
- Resource exhaustion, ambiguity, or unsupported mathematics must fail visibly rather than manufacture a result.

### Native and process safety

- Values crossing the native boundary must be validated before use.
- Attacker-controlled sizes, precision, iteration, expression depth, queue populations, transfer sizes, and retained state must remain bounded where the component exposes them.
- Cancellation and overload handling must not reorder committed state or mutate state after cancellation.
- Malformed or extreme input must not cause unchecked native allocation, memory corruption, undefined behavior, or unsafe process behavior.

### Filesystem integrity

- History, workspace, identity, policy, catalog, coordinator, preservation, and release files must obey their documented ownership, regular-file, permission, symlink, path, size, and atomic-write rules where the platform supports them.
- Archives must reject traversal, absolute paths, links, unsupported special entries, or unsafe layouts before activation.
- Installation and update paths must stage and validate material before replacing active software.

### MIRAGE authority boundaries

- User documents are data, not executable authority.
- Imperative wording in a specification cannot grant shell access, source-mutation authority, publication authority, or verified-core status.
- Candidate material remains staged until the applicable parsing, type/dimension, regression, provenance, rollback, review, and verification gates are satisfied.
- Generated artifacts cannot certify themselves.

### CARAVAN authority boundaries

CARAVAN's governing security invariant is:

> **A carrier may provide bytes, but a carrier may never define which bytes are trusted.**

Accordingly:

- authenticated FCF metadata defines approved artifact identity;
- carrier count affects availability, not authority;
- malformed, reordered, truncated, appended, or digest-mismatched transfers must be rejected before promotion;
- carrier credentials, policy receipts, catalog trust roots, retrieval capabilities, census state, and quarantine state remain separate trust objects;
- ordinary carriers must not become arbitrary file servers, proxies, shell gateways, or trust roots;
- participation and withdrawal must respect explicit resource and privacy boundaries.

The v0.14.0 stable boundary contains the bounded CARAVAN Phase 1 laboratory. Main-line work contains later enrollment and public-origin development, but **public volunteer network enrollment remains gated** until its release and operational requirements are deliberately satisfied.

### Release and supply-chain integrity

- Toolchains and dependencies used by the release path must be pinned and validated according to repository policy.
- GitHub Actions must use appropriate least-privilege permissions and immutable action identities where required.
- Untrusted pull-request content must not execute with publication credentials.
- The release tag, qualified source commit, packaged bytes, checksums, and embedded build identity must agree through the publication path.
- A checksum published beside an archive detects corruption but is not by itself an independent signature against compromise of the publication authority.
- A release must never be rebuilt from a different source identity merely because the version number matches.

## Reportable findings

A finding is security-relevant when attacker-controlled input, a compromised dependency, or a repository-controlled trust failure can realistically violate a supported boundary.

Examples include:

- arbitrary code execution or memory corruption;
- unsafe archive extraction or unintended filesystem access;
- secret exposure;
- release or artifact substitution;
- a practical resource-limit bypass;
- cross-request state corruption;
- CARAVAN trust or content-identity substitution;
- MIRAGE provenance or authority bypass;
- silent corruption of an exactness, proof, enclosure, or assurance claim presented to a human or machine caller.

Severity depends on both reachability and impact. A local bounded denial of service that requires a user to intentionally run hostile input is generally less severe than a path exposed through a common embedding, publication system, or network-facing component.

## Out of scope and accepted boundaries

- Ordinary correctness bugs without a realistic security, integrity, or assurance impact should be reported through GitHub Issues.
- Julia/Nemo laboratory code is not shipped as the runtime, although a weakness that corrupts a trusted release gate or oracle remains in scope.
- A hypothetical public CARAVAN deployment does not receive public-network reachability simply because a design document describes it. Security analysis should use the actually implemented and enabled path.
- Vulnerabilities requiring prior administrator/root compromise are generally out of scope unless CENTL introduces an additional repository-controlled weakness that materially changes the impact.
- Unsupported historical releases are out of scope unless the same issue affects a supported line.

There is no blanket accepted class of known exploitable vulnerability.

## Oasis security posture

An Oasis release is not qualified merely because unit tests pass. The applicable gate also examines verification, hardening, dependency and hosted security state, component-specific trust boundaries, installer/release integrity, source identity, and publication integrity.

A release-blocking security finding must be repaired, explicitly scoped out because it is genuinely unreachable or non-applicable, or otherwise resolved with defensible evidence. A checker must not be weakened solely to obtain a green release.

See [`docs/OASIS.md`](docs/OASIS.md), [`docs/RELEASE-POLICY.md`](docs/RELEASE-POLICY.md), [`docs/CARAVAN-THREAT-MODEL.md`](docs/CARAVAN-THREAT-MODEL.md), and [`docs/VERIFICATION.md`](docs/VERIFICATION.md).
