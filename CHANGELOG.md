# Changelog

## 0.9.0 — UNRELEASED

This is preparation only. The runtime version, Git tag, installers, protocol
producer version, and published release remain `0.8.0`.

### Added

- `integrate(p, x)` for the canonical zero-constant antiderivative of an exact
  rational-coefficient univariate polynomial.
- `integrate(p, x = a, b)` for exact definite integration over exact rational
  bounds.
- Explicit residual `integrate(...)` expressions for unsupported integrands or
  bounds; CENTL does not guess or silently approximate them.

The accepted polynomial syntax uses positive powers no larger than 64.
Explicit zero powers remain residual so the evaluator does not erase a possible
`0^0` error.

## 0.8.0 — CURRENT

The current runtime and released tool surface. See the repository history and
release notes for the complete change record.
