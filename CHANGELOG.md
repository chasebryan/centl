# Changelog

## 0.12.0 — 2026-08-09

### Changed

- Promoted validated release candidate series to stable 0.12.0.
- Authoritative CLI/golden outputs updated to 0.12.0 where appropriate.
- Historical rc.2/rc.3 records preserved.


## 0.12.0-rc.3 — 2026-08-09

### Added

- CENTL-SCi is packaged and activated as a first-class native command alongside
  `centl` and `centl-physics`.
- A bare `centl-sci` starts the answer-first live scientific REPL.
- Native installers smoke-test CENTL-SCi exact arithmetic and REPL startup
  before activating the installed command.
- Unix installation can configure the user's PATH automatically, with an
  explicit opt-out and a POSIX profile fallback when the shell cannot be
  identified.
- Dedicated release notes document the first-run scientific interface and
  platform policy.

### Fixed

- The Unix installer no longer fails under `set -u` when `SHELL` is absent in a
  headless CI, container, or service environment.
- Windows installer validation no longer depends on PowerShell preserving
  native REPL line boundaries; it still requires both CENTL-SCi identity
  markers before activation.
- Regression coverage now exercises installation with `SHELL` explicitly
  removed and verifies `~/.profile` PATH fallback plus `centl-sci` activation.

### Release-candidate notes

- Linux remains the CENTL-SCi reference platform. Windows support is
  experimental and best-effort during the early development series.
- This is a candidate build for validation, not the final 0.12.0 publication.

## 0.12.0-rc.1 — 2026-08-08

### Added

- Math-contract release candidate:
  - Protocol `op: "verify"` and MCP `centl_verify` check structured claims.
  - CLI `centl verify --left/--relation/--right [--variable name:rational]
    [--json] [--receipt FILE]` and `centl check FILE [--json]
    [--receipt FILE]`.
  - Calculator grammar `assert(left rel right)` and quantified
    `assert(left rel right, for_all = x, domain = rational)`, host-checked
    outside the engine (assert exits follow verify: 0/1/2).
  - Decisive scopes: closed exact rational comparison, certified enclosure
    order/inequality, and universal equality in the F*-admitted univariate
    rational-polynomial fragment. The latter reports `verified_core` and names
    `Centl.PolynomialSoundness.surface_rational_polynomial_identity_sound`.
  - False polynomial equalities are `refuted` only with an exactly rechecked
    rational counterexample (`witness_checked`).
  - Enclosure evidence includes exact dyadic endpoints plus decimal bounds;
    polynomial evidence may include `normalized_difference` and
    `counterexample`.
  - Verdicts: `verified`, `refuted`, `unknown`, `invalid`. Operational failures
    (cancellation, resource/precision limits, backend failures) remain errors.
  - Free-form assumptions, multi-variable claims, quantified order, and
    unproved polynomial identities return `unknown`.
  - Session definitions may be read; verification never mutates session state.
  - Bounded receipts include the resolved claim, active limits, exact
    transitive session dependencies, session revision, verdict evidence, and
    the binary's semantic version, optional commit, and generated-core hash.
  - `--build-info` exposes the stamped build identity, receipt schema, and
    protocol version. Native archives carry a validated `BUILD_MANIFEST.json`.
  - A reusable local `centl-check` GitHub Action runs passing contracts and can
    retain their receipt collection as an artifact.
  - Passing and deliberately pending example contracts live under
    `examples/contracts/`.
  - `describe` advertises verification scopes, verdicts, and assurance classes.

### Release-candidate notes

- Claims outside the admitted proof fragment—including symbolic division and
  multiple free variables—remain `unknown`; this is intentional.
- This is a candidate build for validation, not the final 0.12.0 publication.

## 0.11.0 — 2026-08-08

### Added

- Every successful evaluation now carries an orthogonal transformation
  resolution: `computed`, `transformed`, `unchanged_proved`, `residual`,
  `unsupported`, or `indeterminate`. Transformation metadata identifies the
  operation, stable reason, and supported mathematical domain where relevant.
- Persistent JSON Lines adds read-only `compute` and explicit `define`
  operations. MCP adds `centl_compute` and `centl_define` with accurate
  read-only/idempotence annotations and exact discriminated output schemas.
- `describe` and `centl_capabilities` publish resolution statuses, supported
  mathematical domains, examples, limits, and cancellation behavior.
- `session` and `centl_session` return immutable definitions in creation order
  with canonical expressions and direct dependencies.
- `help` and `centl_help` provide focused structured help generated from the
  canonical syntax catalog.
- Machine errors include retryability, structured source ranges, named limit
  details, and recovery suggestions when known.
- An executable agent-tool corpus covers correct calls, supported-domain
  selection, residual recognition, read-only rejection, cancellation, limit
  failures, exact sequences, substitution, define-only validation, and
  unresolved equations.
- MCP tool text content now mirrors human residual annotations and includes
  recovery suggestions on mathematical tool errors, while structured content
  remains the canonical machine result.
- End-to-end CLI coverage exercises `compute`/`define`/`session`/`help` and
  residual classification on human, JSON Lines, and MCP surfaces.

### Changed

- Residual or unsupported differentiation, integration, simplification,
  expansion, factoring, and solving can no longer look like a completed
  transformation in human, JSON, JSON Lines, or MCP output.
- `centl_calculate` and JSON `evaluate` retain their combined compute/define
  behavior as a documented compatibility route. New automated integrations
  should use the split operations.

Machine protocol version 1 remains unchanged. Successful evaluation responses
now require top-level `resolution`; machine error objects now require
`retryable`. Strict clients should update their response schemas. MCP tool
discovery exposes seven tools instead of two.

## 0.10.0 — 2026-08-04

### Added

- `sequence(expression, variable = lower, upper)` produces an exact finite
  sequence over inclusive integer bounds, with lexical index scope and a
  defined empty result.
- `recurrence(initial, previous = step, index = lower, upper)` produces an
  exact first-order bounded recurrence. The initial value occupies the lower
  index and every later term receives the previous exact value and its current
  index.
- Exact sequences have a structured protocol value, provenance, and identical
  behavior through one-shot JSON, persistent JSON Lines, and MCP.
- Real quadratic equations with positive nonsquare discriminants now return
  verified exact conjugate roots as canonical `center ± sqrt(radicand)` pairs,
  including structured branch, center, and radicand fields.
- Human input supports syntax-aware multiline statements in the calculator,
  standard-input scripts, and `--file` scripts. Syntax and runtime mathematical
  diagnostics now retain source locations; human output includes a caret
  excerpt and machine errors expose a stable zero-based byte position.
- Interactive terminals provide built-in and session-name completion plus
  private, versioned, bounded history shared safely across calculator
  processes. `:history`, `:clear-history`, `--no-history`, and environment
  opt-outs make persistence explicit and controllable.
- Deterministic parser/protocol/native mutation corpora, exact-rational
  metamorphic checks, ASan/UBSan coverage of the production Arb shim, and
  conservative startup/evaluation performance budgets provide reproducible
  hardening gates.
- A pinned opam manifest, contributor bootstrap, honest formatting and lint
  gates, and a focused pull-request verification workflow make the development
  path reproducible.

### Changed

- Exact rendering now uses an explicit traversal stack and bounded buffer
  construction, including cancellation-aware size preflight, so deeply nested
  symbolic results do not depend on the OCaml call stack.
- Sequences and recurrences share the existing request-wide iteration, exact
  bit, symbolic node, serialized-value byte, work, and cancellation limits.
  Aggregate retained sequence elements are checked before a result is returned
  or a definition is committed.
- Empty finite ranges defer session-function expansion as well as evaluation.
  Exact-bit budgets use rational numerator/denominator profiles and validate
  the actual exact payload before output; sequence and enclosure results cannot
  cross scalar-only iteration or symbolic-transformation boundaries.
- Pull requests run the pinned Linux verification, native, quality, and seeded
  Julia/Nemo differential path. Full native packaging remains on `main`, tags,
  and manual runs, and superseded branch runs are cancelled.
- Quadratic completion validates host-supplied integer square-root floor
  witnesses in F*, preserves the existing rational-root representation, and
  applies exact-bit, result-byte, and cooperative-cancellation boundaries.
- MCP calculation and reset responses now advertise separate closed output
  schemas; calculation schemas discriminate every value, definition, error,
  rational solution, and exact real-quadratic solution shape and are allocated
  only during tool discovery.
- Persistent JSON Lines and MCP input use an extracted, directly tested FIFO
  queue with exact count/byte accounting and one separately bounded emergency
  cancellation slot, so ordinary saturation cannot prevent a valid
  cancellation from reaching its target.
- Native release verification installs Git and its runtime prerequisites before
  checkout and asserts that verification runs inside the expected worktree.

Machine protocol version 1 remains unchanged. Consumers that exhaustively
match value kinds must accept the new exact `sequence` kind. Consumers that
inspect `solution_set.solutions` must also accept tagged `real_quadratic`
members alongside the unchanged rational member shape. `sequence` and
`recurrence` are reserved built-in names.

## 0.9.1 — 2026-08-02

### Fixed

- Linux and macOS x86_64 release libraries now target baseline x86-64 and use
  GMP runtime CPU dispatch instead of inheriting the hosted runner's ISA.
- Native release CI executes the packaged Linux binary under an emulated Core 2
  CPU for both exact GMP arithmetic and rigorous MPFR approximation.

The x86_64 native libraries attached to `0.9.0` were tuned for their CI runner
CPU and can exit with an illegal-instruction fault on older x86_64 processors.
Source builds, Windows, and macOS arm64 artifacts are unaffected; use `0.9.1`
for portable Linux and macOS x86_64 packages.

## 0.9.0 — 2026-08-02

### Added

- Exact inclusive `sum(expression, variable = lower, upper)` and
  `product(expression, variable = lower, upper)`, including nested iteration,
  exact rational or symbolic results, and defined empty ranges.
- `integrate(p, x)` for the canonical zero-constant antiderivative of an exact
  rational-coefficient univariate polynomial.
- `integrate(p, x = a, b)` for exact definite integration over exact rational
  bounds.
- Explicit residual `integrate(...)` expressions for unsupported integrands or
  bounds; CENTL does not guess or silently approximate them.
- Structured provenance for every machine result and request-scoped cooperative
  cancellation across JSON Lines and MCP.
- Pinned Julia/Nemo differential tests, formatting and lint gates, and expanded
  adversarial coverage.

### Changed

- Substitution is simultaneous and capture-avoiding across iteration,
  integration, differentiation, solving, and substitution binders.
- Bounded FIFO input queues, aggregate session and result limits, atomic
  definition commits, and symbolic-work preflight harden persistent operation.
- The verified core now covers semantic differentiation, polynomial
  antiderivative coefficient round trips, outward decimal rounding, and
  logarithmic exact-power properties.

The accepted polynomial syntax uses positive powers no larger than 64.
Explicit zero powers remain residual so the evaluator does not erase a possible
`0^0` error.

Machine protocol version 1 and existing value kinds remain unchanged. Machine
responses now include top-level provenance; strict response-schema consumers
may need to accept that required field. `sum`, `product`, and `integrate` are
reserved built-in names.

## 0.8.0

Added persistent JSON Lines and MCP operation. See the repository history and
release notes for the complete change record.
