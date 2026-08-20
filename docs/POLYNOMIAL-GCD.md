# Exact Polynomial GCD over Q[x]

Status: P0 admission candidate.

This document freezes CENTL's exact greatest-common-divisor contract for
univariate polynomials over the rational field.

## Domain

The admitted inputs are canonical sparse polynomial values whose terms use at
most one explicitly named variable. The request supplies that variable
separately.

For admitted `a(x), b(x) in Q[x]`, CENTL computes a canonical polynomial
`g(x)` representing their greatest common divisor up to the usual units of
`Q[x]`.

The public normalization is fixed:

- every nonzero GCD is monic;
- `gcd(0, 0) = 0` by explicit CENTL convention;
- `gcd(a, 0)` and `gcd(0, a)` return the monic associate of nonzero `a`.

Coefficients remain exact rationals throughout. No floating-point fallback or
approximate factor test exists in this path.

This is deliberately not multivariate polynomial GCD. Any term containing a
variable other than the explicitly admitted variable is refused.

## Mathematical contract

For a nonzero returned `g(x)`:

- `g` divides `a` exactly in `Q[x]`;
- `g` divides `b` exactly in `Q[x]`;
- every common divisor of `a` and `b` divides `g` up to multiplication by a
  nonzero rational unit;
- `g` is monic, removing unit ambiguity.

`coprime(a,b)` is true exactly when the canonical GCD is the constant polynomial
`1`.

## Algorithm

CENTL uses the Euclidean algorithm over `Q[x]`, built on the admitted exact
quotient/remainder implementation.

Before and during the Euclidean chain, nonzero operands and remainders are
normalized to monic form. Monic normalization is performed incrementally and is
subject to the same cancellation, exact-bit, term, and work boundaries as the
rest of the request.

Each Euclidean iteration computes an exact remainder, then replaces
`(a,b)` with `(b,remainder)` until the second operand is zero. The resulting
first operand is already in canonical monic form.

## Shared resource semantics

GCD does not create a fresh hidden work allowance for every remainder operation.
The underlying polynomial-division module exposes a reusable internal state, and
the complete GCD request threads one shared work counter through:

- input validation;
- monomial inspection;
- leading-term scans;
- long-division progress;
- quotient and remainder construction;
- monic normalization;
- Euclidean-loop progress.

The admission also has an explicit Euclidean-step ceiling. Term-count,
exact-bit, long-division-step, shared-work, Euclidean-step, and serialized-result
ceilings all refuse explicitly with `resource_limit`.

No partial GCD is reported as success after a resource refusal.

## Cancellation

Cancellation is cooperative throughout validation, division, remainder
construction, monic normalization, and Euclidean iteration. A cancelled request
returns `cancelled` and exposes no partial mathematical result.

## Strict machine protocol

The version-1 GCD protocol exposes:

- `capabilities`;
- `gcd`;
- `coprime`.

Every mathematical request contains exactly:

- `action`;
- `variable`;
- `left`;
- `right`.

`gcd` returns a canonical sparse polynomial. `coprime` returns an exact boolean
classification payload. Successful results are classified as `exact` with
backend `centl-exact-polynomial-gcd`.

Unknown fields are refused. Approximation flags, normalization switches, and
monomial-order parameters are not part of this contract.

## Public surfaces

The canonical mathematics gateway exposes domain `polynomial_gcd` with actions
`gcd` and `coprime`.

Its polynomial, division-step, Euclidean-step, exact-bit, work, and result-byte
limits are clamped to the existing polynomial and outer-server envelopes.

JSONL `op: "math"` and the closed-schema MCP `centl_math` tool route through the
same canonical gateway implementation.

## Admission evidence

The test ladder includes:

- a known common factor for `x^3 - 1` and `x^2 - 1`;
- sign and rational-content normalization to the monic associate;
- rational-coefficient GCD;
- coprime inputs;
- all zero-input conventions;
- mixed-variable refusal;
- Euclidean-step, exact-bit, shared-work, result-byte, and cancellation limits;
- exact divisibility checks for returned GCDs;
- 25 independently constructed cases of the form `g*p` and `g*q` with distinct
  linear cofactors;
- a closed-form Bézout witness for every constructed oracle case, independent of
  the GCD implementation;
- a 4096-bit exact common-factor and Bézout case;
- strict protocol IDs, provenance, field rejection, coprimality, and
  cancellation;
- JSONL capability, GCD, coprimality, refusal, result-limit, and deep-cancel
  regressions;
- MCP schema, GCD, coprimality, nested-strictness, result-limit parity, and
  deep-cancel regressions.

The broader capability ledger remains conservative: this admission proves the
explicit univariate `Q[x]` slice only and does not claim multivariate GCD,
factorization, or square-free decomposition.
