# Changelog

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
