# Exact Polynomial Extended GCD Certificates

Status: P0 admission candidate.

This document freezes CENTL's exact Bézout-certificate contract for univariate
polynomials over the rational field.

## Separation from ordinary GCD

CENTL exposes ordinary polynomial GCD and extended GCD as separate capabilities.

The lean `polynomial_gcd` domain returns the canonical monic gcd or a coprimality
answer. It does not construct Bézout witnesses. This matters because witness
polynomials can grow substantially even when the gcd itself is small.

The `polynomial_extended_gcd` domain is the explicit certificate-producing path.
A request therefore pays for witness construction only when the caller asks for
it.

## Domain

The admitted inputs are canonical sparse polynomial values whose terms use at
most one explicitly named variable. The request supplies that variable
separately.

For admitted `a(x), b(x) in Q[x]`, CENTL returns exact polynomials

- `g(x)`;
- `s(x)`;
- `t(x)`;

such that

`g(x) = s(x) * a(x) + t(x) * b(x)`

and `g` is the canonical monic gcd whenever it is nonzero.

This is deliberately not a multivariate extended-GCD algorithm. Inputs carrying
a variable other than the explicitly admitted variable are refused.

## Zero convention

CENTL fixes the all-zero case explicitly:

`extended_gcd(0,0) = { gcd = 0, s = 0, t = 0 }`.

For exactly one nonzero operand, the result is the monic normalization of that
operand and the corresponding exact scalar witness.

## Algorithm

CENTL runs the standard extended Euclidean recurrence on the original inputs.
It tracks

`(old_r, r, old_s, s, old_t, t)`

with initial state

`(a, b, 1, 0, 0, 1)`.

At each Euclidean step, exact polynomial division produces

`old_r = q * r + next_r`.

The witness recurrence is

`next_s = old_s - q*s`

and

`next_t = old_t - q*t`.

The witness updates are accumulated directly into the destination difference,
term by term. CENTL does not first materialize complete temporary `q*s` or `q*t`
polynomials. Cancellation, work, term-count, and exact-bit guards run before each
new product term is retained in the evolving witness.

The algorithm does not monic-normalize intermediate remainders. Doing so would
require synchronizing every unit scaling with both witness sequences. Instead,
when the Euclidean chain terminates, CENTL multiplies the final gcd and both
witness polynomials by the same exact scalar that makes the gcd monic. The
Bézout identity is therefore preserved exactly.

## One request-wide resource state

Extended GCD reuses the admitted polynomial-division state rather than creating a
fresh budget for each Euclidean remainder.

The same work counter covers:

- input validation;
- leading-term scans;
- every long-division step;
- quotient/remainder construction;
- direct witness product-subtraction updates;
- final gcd/witness normalization;
- Euclidean-loop progress.

Witness updates are bounded term by term. The evolving difference is guarded
before another product contribution is retained, so witness construction cannot
allocate a complete oversized product before refusal. The operation also cannot
reset the meter between remainder work and certificate work.

## Resource semantics

The public boundary exposes explicit ceilings for:

- polynomial term count;
- exact-bit size;
- long-division steps;
- Euclidean steps;
- request-wide work;
- serialized result bytes.

The nested limits are clamped to the already-admitted polynomial and server
ceilings. A more permissive extended-GCD request cannot escape the canonical
mathematics gateway boundary.

Crossing a limit returns `resource_limit`; CENTL never returns a partial
certificate as a successful result and never falls back to floating-point
arithmetic.

## Cancellation

Extended GCD is cooperatively cancellable throughout validation, long division,
direct witness updates, Euclidean iteration, and final normalization.
Cancellation returns `cancelled` with no partial certificate.

## Strict machine protocol

The version-1 protocol exposes only:

- `capabilities`;
- `extended_gcd`.

An `extended_gcd` request contains exactly:

- `variable`;
- `left`;
- `right`;
- the `action`.

The successful result contains canonical sparse-polynomial objects for:

- `gcd`;
- `left_coefficient`;
- `right_coefficient`.

Successful results are classified as `exact` with backend
`centl-exact-polynomial-extended-gcd`.

## Public surfaces

The canonical mathematics gateway exposes the exact domain
`polynomial_extended_gcd`.

JSONL `op: "math"` and the closed-schema MCP `centl_math` tool route through the
same gateway implementation. The MCP schema exposes no approximation option,
monic toggle, witness-size override, or hidden monomial order.

## Admission evidence

The test ladder includes:

- a common-factor certificate for `x^3 - 1` and `x^2 - 1`;
- rationally scaled inputs;
- a coprime certificate whose gcd is exactly `1`;
- both-zero and one-zero conventions;
- mixed-variable refusal;
- Euclidean-step, shared-work, exact-bit, serialized-result, and cancellation
  boundaries;
- exact verification of `s*a + t*b = gcd` against the original inputs;
- an independently constructed 25-case known-factor oracle using closed-form
  Bézout witnesses for distinct linear cofactors;
- an independent 4096-bit exact certificate case;
- strict protocol capability, result-shape, ID, provenance, zero, refusal,
  result-limit, and cancellation tests;
- JSONL capability, exact-certificate, mixed-variable, result-limit, and deep
  cancellation regressions;
- MCP schema, exact-certificate, nested-strictness, result-limit parity, and deep
  cancellation regressions.

This admission proves exact univariate Bézout certificates over `Q[x]`. It does
not claim multivariate extended GCD, polynomial factorization, or ideal
membership.
