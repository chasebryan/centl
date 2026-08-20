# Exact Polynomial Content and Primitive Part

Status: P0 admission candidate.

This document freezes CENTL's exact normalization contract for polynomial
content and primitive-part decomposition over rational coefficients.

## Domain

The admitted input is a canonical sparse multivariate polynomial over `Q` as
represented by `Centl_multivariate_polynomial`.

For a nonzero polynomial with reduced rational coefficients

`a_i = n_i / d_i`, with `d_i > 0`,

CENTL defines:

1. `L = lcm(d_1, ..., d_k)`;
2. `N_i = n_i * (L / d_i)`;
3. `g = gcd(|N_1|, ..., |N_k|)`;
4. `content(p) = g / L`;
5. `primitive_part(p) = p / content(p)`.

The rational content is therefore positive for every nonzero polynomial.
The primitive part retains the signs of the original coefficients.

## Zero convention

CENTL fixes the zero case explicitly:

- `content(0) = 0`;
- `primitive_part(0) = 0`.

This is a machine convention and is reported by capability discovery.

## Canonical properties

For every admitted nonzero polynomial `p`, the result satisfies:

- `content(p) > 0`;
- every coefficient of `primitive_part(p)` is an integer;
- the gcd of the absolute primitive coefficients is `1`;
- `p = content(p) * primitive_part(p)` exactly;
- no floating-point value is introduced.

For a negative constant, for example `p = -6/35`, CENTL returns content
`6/35` and primitive part `-1`.

## Algorithm

CENTL performs three bounded traversals over canonical nonzero terms.

The first pass forms the denominator LCM. The second pass clears those
denominators conceptually and forms the gcd of the resulting integerized
numerators. The third pass constructs the primitive polynomial term by term by
exactly dividing each coefficient by the positive rational content.

The implementation guards intermediate LCMs, integerized coefficients, the
rational content, every primitive coefficient, and the aggregate primitive
polynomial exact-bit budget. A primitive term is not retained if doing so would
cross the admitted aggregate exact-bit ceiling.

## Resource semantics

The operation has explicit ceilings for:

- source and result term count;
- exact-bit size;
- deterministic request-wide work;
- serialized result size at protocol and public gateway boundaries.

Each coefficient visited by any of the three bounded traversals consumes one
unit from the request-wide work budget. Intermediate denominator LCMs,
integerized coefficients, primitive coefficients, and the accumulated primitive
result are checked before the computation proceeds.

If a boundary is exceeded, the request fails with `resource_limit`. CENTL does
not return a partial decomposition and does not fall back to approximate
arithmetic.

## Cancellation

Content decomposition is cooperatively cancellable before and during all three
coefficient traversals, including primitive-part construction. A cancelled
request returns `cancelled` and no partial normalization is presented as a
result.

## Machine protocol

The version-1 strict content protocol exposes:

- `capabilities`;
- `content`;
- `primitive_part`;
- `decompose`.

`decompose` returns both the exact rational content and the canonical primitive
polynomial. Successful results are classified as `exact` with backend
`centl-exact-polynomial-content`.

## Public surfaces

The canonical mathematics gateway exposes the exact domain
`polynomial_content`. Its limits are clamped to the existing canonical
multivariate-polynomial and outer server result ceilings rather than creating a
more permissive side channel.

JSONL `op: "math"` and the closed-schema MCP `centl_math` tool route through the
same gateway implementation. MCP advertises only the four admitted actions and
the canonical structured polynomial input; unsupported or additional nested
fields remain explicit failures rather than approximation hints.

## Admission evidence

The test ladder includes:

- a mixed-denominator multivariate example with content `3/70` and primitive
  coefficients `4, -15, 7`;
- exact reconstruction of the original polynomial;
- zero normalization;
- negative-constant sign normalization;
- already-primitive integer input;
- term, work, input exact-bit, aggregate primitive-output exact-bit, and result
  byte refusal;
- cancellation inside primitive-part construction;
- a separately coded denominator-clearing oracle over 49 deterministic rational
  coefficient cases;
- a large-exact-denominator oracle case;
- strict protocol actions, provenance, limits, IDs, and cancellation;
- JSONL public-route exact result, capability discovery, result-limit, and deep
  cancellation regressions;
- MCP schema exposure, exact decompose, nested strictness, server-limit parity,
  and deep cancellation regressions.

The strategic B2 capability is checked only after the complete repository CI
gates pass on this admission branch.
