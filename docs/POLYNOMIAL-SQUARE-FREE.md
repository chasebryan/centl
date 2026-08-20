# Exact Polynomial Square-Free Factorization

Status: P0 admission candidate.

This document freezes CENTL's exact square-free multiplicity-group contract for
univariate polynomials over the rational field.

## Domain

The admitted input is a canonical sparse polynomial whose terms use at most one
explicitly named variable. The request supplies that variable separately.

For every admitted nonzero `f(x) in Q[x]`, CENTL returns an exact rational unit
`u` and a finite list of pairs

`(m_i, g_i(x))`

such that

`f(x) = u * product_i g_i(x)^m_i`.

Each nonconstant `g_i` is monic and square-free. Multiplicities are positive and
reported in increasing multiplicity order.

This is deliberately not a multivariate algorithm.

## What a factor group means

The returned `g_i` values are **square-free multiplicity groups**. They are not
claimed to be irreducible factors.

For example, if two distinct irreducible factors occur with the same
multiplicity, CENTL may return their product as one square-free group at that
multiplicity. A repeated irreducible quadratic is handled directly; the
algorithm does not assume rational roots.

The machine result therefore includes

- `factor_semantics = "square_free_multiplicity_groups"`;
- `irreducible_factorization = false`.

Clients must not reinterpret this result as a complete factorization over the
rationals.

## Unit and zero conventions

CENTL separates the original leading coefficient as the exact rational unit.
The remaining nonconstant groups are monic.

A nonzero constant polynomial returns that constant as `unit` and an empty
factor list.

Square-free factorization of the zero polynomial is undefined in this admitted
contract. CENTL refuses zero explicitly instead of inventing a decomposition.

## Algorithm

CENTL uses the characteristic-zero square-free decomposition built from exact
polynomial differentiation, exact GCD, and exact quotient operations.

After separating the leading coefficient, let `F` be the monic polynomial.
CENTL computes

`C = gcd(F, F')`

and

`W = F / C`.

For multiplicity `i = 1, 2, ...`, it repeatedly computes

`Y = gcd(W, C)`

and

`G_i = W / Y`.

A nontrivial `G_i` is emitted at multiplicity `i`. The state advances by

`C <- C / Y`

and

`W <- Y`.

The process terminates when both residual values are `1`.

Every quotient used by the algorithm is required to be exact. A nonzero
remainder in a quotient that should be exact is treated as an internal
invariant failure, never as a successful partial factorization.

## One request-wide resource state

Square-free factorization does not create a fresh budget for each derivative,
GCD, or quotient.

A backward-compatible `gcd_with_state` seam lets repeated GCD calls reuse the
same admitted polynomial-division state. One request-wide work counter covers:

- input validation;
- input normalization;
- derivative construction;
- every leading-term scan;
- every Euclidean GCD step;
- every long-division step;
- every exact quotient;
- multiplicity-loop progress;
- retained polynomial terms;
- cooperative cancellation.

The operation therefore cannot reset its work meter between multiplicity
layers.

## Resource semantics

The public boundary exposes explicit ceilings for:

- polynomial term count;
- exact-bit size;
- long-division steps;
- GCD Euclidean steps;
- square-free multiplicity steps;
- request-wide work;
- serialized result bytes.

The canonical mathematics gateway clamps these limits to the already-admitted
polynomial and server envelopes. A square-free request cannot use more permissive
nested limits to escape the public boundary.

Crossing a limit returns `resource_limit`. CENTL never returns a partial
factorization as success and never falls back to floating-point arithmetic.

## Cancellation

Square-free factorization is cooperatively cancellable throughout validation,
normalization, derivative construction, GCD, long division, exact quotient, and
multiplicity extraction.

Cancellation returns `cancelled` with no partial successful factorization.

## Strict machine protocol

The version-1 protocol exposes only:

- `capabilities`;
- `factorize`.

A `factorize` request contains exactly:

- `action`;
- `variable`;
- `polynomial`.

There is no `irreducible` toggle, approximation flag, monomial-order option, or
hidden request to continue factoring the returned groups.

A successful result contains:

- the exact rational `unit`;
- `factor_semantics = "square_free_multiplicity_groups"`;
- `irreducible_factorization = false`;
- a list of exact sparse-polynomial groups with positive multiplicities;
- `factor_count`.

Successful results are classified as `exact` with backend
`centl-exact-polynomial-square-free`.

## Public surfaces

The canonical mathematics gateway exposes the exact domain
`polynomial_square_free`.

JSONL `op: "math"` and the closed-schema MCP `centl_math` tool route through the
same gateway implementation.

## Admission evidence

The test ladder includes:

- repeated multiplicities with exact reconstruction;
- mixed multiplicity-1 and repeated factors;
- an already-square-free polynomial;
- nonzero constant handling;
- explicit zero-polynomial refusal;
- mixed-variable refusal;
- repeated irreducible-quadratic coverage;
- same-multiplicity grouping coverage proving that square-free groups are not
  being misrepresented as irreducible factors;
- factor-step, shared-work, exact-bit, serialized-result, and cooperative
  cancellation boundaries;
- an independent 25-case known-multiplicity oracle;
- an independent 4096-bit exact-root case;
- strict protocol capability, result-shape, ID, provenance, zero, refusal,
  result-limit, and cancellation tests;
- JSONL capability, exact-factorization, zero-refusal, result-limit, and deep
  cancellation regressions;
- MCP closed-schema, exact-factorization, nested-strictness, zero-refusal,
  result-limit parity, and deep-cancellation regressions.

This admission proves exact square-free multiplicity-group decomposition over
`Q[x]`. It does not claim irreducible factorization, multivariate square-free
factorization, finite-field factorization, or factorization over algebraic
extensions.
