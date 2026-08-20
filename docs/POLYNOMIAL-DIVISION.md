# Exact Polynomial Quotient and Remainder

Status: P0 admission candidate.

This document freezes CENTL's exact Euclidean-division contract for univariate
polynomials over the rational field.

## Domain

The admitted inputs are canonical sparse multivariate-polynomial values whose
terms use at most one explicitly named variable. The request supplies that
variable separately.

For admitted `a(x), b(x) in Q[x]` with `b(x) != 0`, CENTL returns unique
polynomials `q(x), r(x) in Q[x]` satisfying

`a(x) = b(x) * q(x) + r(x)`

and

`r(x) = 0` or `degree(r) < degree(b)`.

Coefficients remain exact rationals throughout. No floating-point path exists.

This is deliberately **not** multivariate polynomial division. Inputs containing
another variable are refused explicitly. No hidden monomial order is selected.

## Special cases

- division by the zero polynomial is undefined and returns `division_by_zero`;
- a zero dividend returns zero quotient and zero remainder;
- a nonzero constant divisor returns exact scalar division with zero remainder;
- an empty requested variable name is invalid;
- a term containing a variable other than the requested variable is invalid.

## Algorithm

CENTL performs exact long division over `Q`.

At each admitted step it:

1. finds the current leading term of the remainder in the explicit variable;
2. stops when the remainder is zero or its degree is below the divisor degree;
3. exactly divides leading coefficients and subtracts degrees to obtain the next
   quotient monomial;
4. retains that quotient term only after resource and cancellation checks;
5. subtracts the shifted, scaled divisor directly from the remainder one term at
   a time;
6. guards the updated remainder after every retained subtraction term.

The shifted divisor is not first materialized as a complete temporary
polynomial. This makes refusal effective while an intermediate is growing rather
than after a full oversized subtractor already exists.

## Resource semantics

Division has explicit ceilings for:

- source, intermediate, quotient, and remainder term count;
- exact-bit size;
- long-division steps;
- deterministic request-wide work;
- serialized result size at protocol and public gateway boundaries.

The work budget is shared across the whole request. Univariate validation,
monomial inspection, repeated leading-term scans, loop progress, quotient-term
retention, monomial shifts, and shifted-divisor subtraction all consume it.

Step and work counters refuse rather than overflow. Crossing any admitted
resource boundary returns `resource_limit`; no partial quotient or remainder is
presented as a successful result.

## Cancellation

Division is cooperatively cancellable during validation, leading-term scans,
quotient construction, monomial shifting, and every shifted-divisor subtraction
term. A cancelled operation returns `cancelled` and exposes no partial division
as a result.

## Strict machine protocol

The version-1 division protocol exposes:

- `capabilities`;
- `divide`;
- `quotient`;
- `remainder`.

Every mathematical request contains exactly:

- `variable`;
- `dividend`;
- `divisor`;
- the selected `action`.

`divide` returns both canonical sparse polynomial results. Successful results are
classified as `exact` with backend `centl-exact-polynomial-division`.

## Public surfaces

The canonical mathematics gateway exposes the exact domain
`polynomial_division`. Its term, exact-bit, step, work, and result limits are
clamped to the existing polynomial and outer-server ceilings.

JSONL `op: "math"` and the closed-schema MCP `centl_math` tool route through the
same gateway implementation. The MCP schema admits only the explicit univariate
contract above and does not expose approximation flags or a hidden monomial-order
parameter.

## Admission evidence

The test ladder includes:

- exact factor division `(x^3 - 1)/(x - 1)`;
- a nonzero-remainder case;
- rational coefficients;
- constant-divisor and zero-dividend cases;
- zero-divisor and mixed-variable refusal;
- exact-bit, step, work, serialized-result, and cancellation boundaries;
- reconstruction of `dividend = divisor * quotient + remainder`;
- an independently coded synthetic-division oracle over 25 deterministic cubic
  cases divided by linear factors;
- a 4096-bit exact factor case;
- strict protocol actions, IDs, provenance, error classes, and cancellation;
- JSONL capability, exact-result, zero-divisor, result-limit, and deep-cancel
  regressions;
- MCP schema, exact-result, nested-strictness, zero-divisor, result-limit parity,
  and deep-cancel regressions.

The broader strategic checklist remains conservative: this admission proves the
stated univariate `Q[x]` slice and does not claim general multivariate division.
