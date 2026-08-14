# Security Policy

## Supported Versions

Security fixes are made for the latest published stable minor series and the
current `main` branch.

| Version | Supported |
| --- | --- |
| 0.15.x | Yes |
| 0.14.x | Yes |
| `main` | Yes |
| 0.12.x and earlier | No |

The 0.13.0 development line was never published as a separate stable release.
CENTL v0.15.0 is **Al-Nur**, the Oasis candidate built from main and
mirage on the oasis tip. The canonical tag remains `v0.15.0`. Until that
identity finishes the Oasis gate, v0.14.0 remains the last completed
Oasis.

## Reporting a Vulnerability

Use GitHub's private
[Report a vulnerability](https://github.com/chasebryan/centl/security/advisories/new)
form. Do not open a public issue for a vulnerability that has not been fixed.

Include the affected version or commit, platform, reachable interface, impact,
minimal reproduction steps, and any suggested mitigation. Do not include real
credentials, private user data, or unnecessary exploit details. Maintainers
will coordinate validation, remediation, credit, and disclosure through the
private advisory.

## System and Scope

CENTL is a local exact-first calculator, numerical language, physics engine, and
scientific interaction system. This policy covers its F* semantics and
extraction, OCaml parser and application, C binding to FLINT/Arb, CLI and file
input, JSON Lines and MCP-over-stdio interfaces, local history storage,
CENTL-SCi, MIRAGE, CARAVAN Phase 1, installers, packaging scripts, release
artifacts, and GitHub Actions workflows.

The CENTL core and CENTL-SCi do not provide a general remote network service.
Applications may expose their stdio machine interfaces to less-trusted callers,
so expressions, scripts, JSON, MCP messages, request identifiers, and request
timing must be treated as attacker controlled.

CARAVAN Phase 1 adds an explicitly bounded local laboratory transport. Plain
HTTP is allowed only for explicit loopback laboratory operation; non-loopback
catalog/transport endpoints require the documented authenticated/HTTPS
boundaries. Oasis qualification does not authorize arbitrary public volunteer
enrollment or a production public carrier listener.

MIRAGE ingests user-provided local documents and creates provenance, graph,
evidence-obligation, and candidate-transaction artifacts. User document text
is untrusted data and receives no shell, source-mutation, publication, or
verified-core authority merely because MIRAGE parsed it.

Release archives, checksums, dependency registries, authenticated CARAVAN
metadata, downloaded toolchains, and local preservation copies cross separate
supply-chain trust boundaries.

Important assets are mathematical-result integrity, exactness and enclosure
claims, process and host availability, native memory safety, protocol integrity,
private local history/workspaces, CARAVAN artifact authenticity and carrier
credentials, MIRAGE provenance and rollback state, and the authenticity of
published releases.

## Threat Model and Trust Boundaries

- The handwritten OCaml parser and host convert untrusted input into the
  extracted F* core and serialize every public result view.
- Exact values and validated dyadic bounds cross the OCaml/C boundary into
  FLINT, Arb, GMP, and MPFR. F* proofs do not prove those external libraries.
- Persistent JSON Lines and MCP modes retain definitions and process a bounded
  queue for the lifetime of one local process; they do not authenticate callers.
- History and CENTL-SCi/MIRAGE workspaces cross filesystem boundaries and may
  contain sensitive expressions, specifications, generated plans, or evidence.
- MIRAGE preserves user-source provenance and may stage candidate metadata, but
  generated or model-proposed material remains untrusted until the applicable
  parser, type/dimension, regression, trust, rollback, and verification gates
  have been discharged.
- CARAVAN carriers may provide malicious or malformed bytes. Carrier population
  affects availability only; authenticated FCF/TUF metadata defines which bytes
  are trusted. Retrieval must validate authenticated chunks and the complete
  artifact before promotion.
- CARAVAN carrier keys, policy receipts, retrieval tickets, coordinator state,
  quarantine state, and catalog trust roots cross distinct identity and
  filesystem/network boundaries.
- Installers and release workflows cross GitHub, runner, archive, checksum,
  compiler, package-registry, preservation-host, and end-user filesystem
  boundaries.
- The F* toolchain, selected Z3 version, OCaml compiler/runtime, native
  compiler/linker, operating system, pinned Python dependencies used by shipped
  components, and pinned third-party numerical/security libraries are in the
  trusted computing base, subject to the validation and pinning in this
  repository.

### CENTL-SCi publish path

The in-process GitHub contribution path is a narrow, explicit grant. It is not
a remote-control surface and it is not a claim of perfect security.

- Credentials and tokens are never written by CENTL.
- User English is never passed to a shell.
- Automated pull requests are draft and must target `mirage`. `oasis` is not
  an automatic base. Force-push is not implemented.
- A promotion candidate must contain the current oasis tip. Oasis does not
  regress.
- Workflow default tokens are read-only. Jobs that publish releases or the
  `distribution` branch take job-scoped `contents: write` and do not persist
  checkout credentials.
- Qualification and publication workflows do not hold `statuses: write` or
  `checks: write`. Attestation is the GitHub Actions job conclusion itself.
  Scorecard still reports leftover job-level `contents: write` on publication
  jobs; that permission is required to create releases or update
  `distribution` and is accepted residual risk, not a top-level write token.

This sweep does not claim the absence of every future defect. Residual risk
includes native library memory safety, a compromised GitHub release account,
and any write token that a publication job must still hold.

## Security Invariants

- Decimal and integer input must not be narrowed through floating point or a
  fixed-width integer before exact parsing and bounds checks.
- Exact, approximate, residual, unsupported, and indeterminate results must not
  be confused across terminal, JSON, JSON Lines, verification, or MCP output.
- Untrusted input must remain within request, expression, exact-bit, iteration,
  precision, result-size, retained-session, queue, transfer, document, catalog,
  and process-lifetime limits appropriate to its component.
- Cancellation and overload handling must not reorder committed definitions,
  mutate state after cancellation, or permit unbounded retained work.
- Values crossing the native boundary must be validated before use; malformed
  or extreme input must not cause memory corruption, undefined behavior, or an
  unchecked native allocation.
- History, workspace, identity, policy, and coordinator files must enforce their
  documented regular-file, ownership/permission, symlink, size, and atomic-write
  boundaries where the platform supports them.
- MIRAGE user documents remain data. A document cannot gain executable authority
  through imperative wording, and staged candidates cannot promote their own
  assurance or mutate the workspace before the required admission path.
- CARAVAN carriers cannot redefine trusted artifact identity. Malformed,
  reordered, truncated, appended, or digest-mismatched transfers must be
  rejected before object promotion, and a failing carrier cannot rewrite the
  authenticated expected identity.
- CARAVAN retrieval capabilities must remain scoped, expiring, and replay-safe;
  carrier identity proof and policy acceptance must be verified before
  enrollment/use at the relevant boundary.
- Archives must be checksum verified, reject unsafe paths/layouts, reject link
  and unsupported special-entry semantics before extraction, and be staged and
  validated before activation. A checksum hosted beside an archive detects
  corruption but is not an independent signature against repository or
  release-account compromise.
- Repository workflows must use least-privilege tokens, immutable action pins
  with accurate version annotations, reviewed dependency changes, and protected
  publication paths. Untrusted pull request content must not execute with
  release credentials.

## Reportable Findings and Severity Context

A finding is reportable when attacker-controlled input or a compromised
dependency can realistically violate an invariant in a supported interface.
Examples include memory corruption or code execution, unsafe archive
extraction, unintended file access or overwrite, release substitution, secret
exposure, a practical resource-limit bypass, cross-request state corruption,
CARAVAN artifact/trust substitution, MIRAGE authority/provenance bypass, or a
result-integrity failure that can mislead an automated caller about exactness,
proof, enclosure, or assurance guarantees.

Severity depends on reachability and impact. Compromise of release consumers,
arbitrary code execution, artifact-authentication bypass, or silent corruption
of security-relevant machine results is high impact. A bounded local denial of
service requiring the user to invoke malicious input is generally lower
severity unless a common embedding makes the input remotely reachable. Tests
and proof declarations are evidence of intended controls, not proof that a
reported path is unreachable.

## Out of Scope, Exclusions, and Accepted Risk

- Julia/Nemo laboratory code is not shipped in the runtime, though a weakness
  that corrupts a release gate or trusted oracle remains in scope.
- CARAVAN Phase 1 is a local laboratory. Vulnerabilities in a hypothetical
  public deployment that is not implemented or authorized are not assigned
  public-network reachability without a repository-controlled path, although
  flaws in the laboratory trust model remain in scope.
- A proof gap, style concern, or ordinary correctness bug without a realistic
  security-boundary impact is not by itself a security vulnerability; report
  ordinary bugs through GitHub Issues.
- Vulnerabilities that require prior administrator/root compromise, or purely
  theoretical third-party issues with no reachable CENTL path, are not
  reportable without an additional repository-controlled weakness.
- Unsupported versions are out of scope unless the same issue affects a
  supported version.

No blanket vulnerability classes or known exploitable risks are accepted by
this policy.

## Known Limitations and Compensating Controls

- GitHub CodeQL analyzes supported portions of the native/security-relevant
  repository but does not prove CENTL's OCaml or F* source correct. F*
  verification, OCaml warnings, deterministic tests, fuzzing, sanitizers,
  metamorphic tests, Julia/Nemo differential tests, CARAVAN negative tests, and
  MIRAGE admission tests provide complementary coverage but do not replace
  security review.
- Dependabot coverage is ecosystem-dependent. Dependencies not supported by
  GitHub's automated update tooling remain pinned and require manual advisory
  review plus tested updates.
- Native numerical libraries, Python security libraries used by CARAVAN, and
  the language/toolchain stack remain part of the trusted computing base.
  Narrow bindings, representation checks, exact pins, source/archive hashes,
  authenticated metadata, and differential/negative testing reduce but do not
  eliminate that risk.
- GitHub secret scanning, push protection, private vulnerability reporting,
  rulesets, required reviews, and code-scanning merge protection are repository
  settings and must remain enabled in GitHub in addition to the files in this
  repository.

## Oasis security gate

An Oasis release is not justified merely because normal unit tests pass. The
exact release SHA must also satisfy the repository's dependency/security
analysis, relevant component-specific validation, installer/release integrity
checks, and the dedicated hosted `Release security state` gate. No known
release-blocking security finding may be intentionally hidden by weakening a
checker solely to obtain a green release.
