# Changelog

## 0.10.0 — UNRELEASED

This is preparation only. The runtime version, Git tag, installers, protocol
producer version, and published release remain `0.9.1`.

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
- Human input supports syntax-aware multiline statements in the calculator,
  standard-input scripts, and `--file` scripts. Human syntax diagnostics now
  include source locations and a caret excerpt.
- Interactive terminals provide built-in and session-name completion plus a
  bounded in-memory history with `:history` and `:clear-history` commands.
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

Machine protocol version 1 remains unchanged. Consumers that exhaustively
match value kinds must accept the new exact `sequence` kind. `sequence` and
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
