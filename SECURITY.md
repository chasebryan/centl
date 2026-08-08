# Security Policy

## Supported Versions

Security fixes are made for the latest released minor series and the current
`main` branch.

| Version | Supported |
| --- | --- |
| 0.11.x | Yes |
| `main` | Best effort until the next release |
| 0.10.x and earlier | No |

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

CENTL is a local exact-first calculator and numerical language. This policy
covers its F* semantics and extraction, OCaml parser and application, C binding
to FLINT/Arb, CLI and file input, JSON Lines and MCP-over-stdio interfaces,
local history storage, installers, packaging scripts, release artifacts, and
GitHub Actions workflows.

CENTL does not provide a network listener or hosted multi-tenant service.
Applications may expose its stdio machine interfaces to less-trusted callers,
so expressions, scripts, JSON, MCP messages, request identifiers, and request
timing must be treated as attacker controlled. Release archives, checksums,
dependency registries, and downloaded toolchains cross separate supply-chain
trust boundaries.

Important assets are mathematical-result integrity, exactness and enclosure
claims, process and host availability, native memory safety, protocol
integrity, private local history, and the authenticity of published releases.

## Threat Model and Trust Boundaries

- The handwritten OCaml parser and host convert untrusted input into the
  extracted F* core and serialize every public result view.
- Exact values and validated dyadic bounds cross the OCaml/C boundary into
  FLINT, Arb, GMP, and MPFR. F* proofs do not prove those external libraries.
- Persistent JSON Lines and MCP modes retain definitions and process a bounded
  queue for the lifetime of one local process; they do not authenticate callers.
- History crosses a filesystem boundary and may contain sensitive expressions.
- Installers and release workflows cross GitHub, runner, archive, checksum,
  compiler, package-registry, and end-user filesystem boundaries.
- The F* toolchain, selected Z3 version, OCaml compiler/runtime, native
  compiler/linker, operating system, and pinned third-party libraries are in
  the trusted computing base, subject to the validation and pinning in this
  repository.

## Security Invariants

- Decimal and integer input must not be narrowed through floating point or a
  fixed-width integer before exact parsing and bounds checks.
- Exact, approximate, residual, unsupported, and indeterminate results must not
  be confused across terminal, JSON, JSON Lines, verification, or MCP output.
- Untrusted input must remain within request, expression, exact-bit, iteration,
  precision, result-size, retained-session, queue, and process-lifetime limits.
- Cancellation and overload handling must not reorder committed definitions,
  mutate state after cancellation, or permit unbounded retained work.
- Values crossing the native boundary must be validated before use; malformed
  or extreme input must not cause memory corruption, undefined behavior, or an
  unchecked native allocation.
- History files and lock files must remain bounded, regular files with private
  permissions where the platform supports them, and updates must be atomic.
- Archives must be checksum verified, reject unsafe paths and layouts, and be
  staged and validated before activation. A checksum hosted beside an archive
  detects corruption but is not an independent signature against repository or
  release-account compromise.
- Repository workflows must use least-privilege tokens, immutable action pins,
  reviewed dependency changes, and protected publication paths. Untrusted pull
  request content must not execute with release credentials.

## Reportable Findings and Severity Context

A finding is reportable when attacker-controlled input or a compromised
dependency can realistically violate an invariant in a supported interface.
Examples include memory corruption or code execution, unsafe archive
extraction, unintended file access or overwrite, release substitution, secret
exposure, a practical resource-limit bypass, cross-request state corruption,
or a result-integrity failure that can mislead an automated caller about
exactness, proof, or enclosure guarantees.

Severity depends on reachability and impact. Compromise of release consumers,
arbitrary code execution, or silent corruption of security-relevant machine
results is high impact. A bounded local denial of service requiring the user to
invoke malicious input is generally lower severity unless a common embedding
makes the input remotely reachable. Tests and proof declarations are evidence
of intended controls, not proof that a reported path is unreachable.

## Out of Scope, Exclusions, and Accepted Risk

- Julia/Nemo laboratory code is not shipped in the runtime, though a weakness
  that corrupts a release gate or trusted oracle remains in scope.
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

- GitHub CodeQL analyzes the native C boundary; it does not support CENTL's
  OCaml or F* source. F* verification, OCaml warnings, tests, deterministic
  fuzzing, sanitizers, metamorphic tests, and Julia/Nemo differential tests
  provide complementary coverage but do not replace security review.
- Dependabot updates GitHub Actions and Julia dependencies. GitHub does not
  currently support opam, so OCaml dependencies remain exact-pinned and require
  manual advisory review and tested updates.
- Native numerical libraries and the language toolchain remain part of the
  trusted computing base. Narrow bindings, representation checks, exact
  version pins, source/archive hashes, and differential testing reduce but do
  not eliminate that risk.
- GitHub secret scanning, push protection, private vulnerability reporting,
  rulesets, required reviews, and code-scanning merge protection are repository
  settings and must remain enabled in GitHub in addition to the files in this
  repository.
