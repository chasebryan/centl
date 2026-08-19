# Exact real algebraic root certificates

Status: implementation in progress.

Capability family: P0 algebraic-number substrate.

This slice does **not** yet claim the full general algebraic-number scalar domain.
It establishes the exact representation and verification primitive needed for it:
a square-free primitive integer polynomial together with a rational interval that
is mechanically proven to contain exactly one real root.

## Mathematical object

A certificate consists of:

1. a nonconstant primitive polynomial `p in Z[x]` with positive leading
   coefficient;
2. rational endpoints `a < b`;
3. proof-by-recomputation that `p(a) != 0` and `p(b) != 0`;
4. proof-by-recomputation, using a rational Sturm sequence, that `p` has exactly
   one distinct real root in `(a,b)`.

The represented value is that unique root.

The first slice requires `p` to be square-free. Repeated-root input is rejected
rather than silently square-free-normalized because the submitted polynomial is
part of the certificate provenance.

## Polynomial normalization

Input coefficients are ordered from constant term upward. Leading zeros are
removed. The gcd of the absolute nonzero coefficients is divided out and the
sign is normalized so the leading coefficient is positive.

Thus scalar multiples such as `2*x^2 - 4` normalize to `x^2 - 2`.

Normalization does not claim irreducibility or minimality. A later algebraic
scalar layer may reduce a defining polynomial to a minimal polynomial when that
identity is independently established.

## Root-count certificate

CENTL constructs the exact Sturm chain

`p0 = p`

`p1 = p'`

`p(k+1) = -rem(p(k-1), p(k))`

using exact rational polynomial division. At a rational point that is not a root
of `p`, zero values in the chain are ignored and sign variations are counted in
the ordinary Sturm sense.

The number of distinct roots in `(a,b)` is

`V(a) - V(b)`.

Admission requires this value to equal exactly one.

## Exact refinement

A certificate may be bisected at the rational midpoint.

- If the midpoint is exactly a root, refinement returns that exact rational root.
- Otherwise exact Sturm counts select the unique half-interval containing the
  represented root and return a new certificate.

No floating-point root finder participates.

## Result classification

An admitted certificate is **algebraic exact**. The interval is identifying
metadata, not an approximation pretending to equal the root. Decimal rendering,
if later requested, must be produced from a certified enclosure/refinement path.

## Invalid and refused inputs

This slice rejects:

- the zero polynomial;
- constant polynomials;
- an interval with `a >= b`;
- an endpoint that is itself a root;
- non-square-free defining polynomials;
- intervals containing zero or more than one distinct root.

This slice does not yet provide:

- arithmetic between algebraic roots;
- equality between certificates with different defining polynomials;
- minimal-polynomial computation;
- exact complex algebraic roots;
- complex isolating boxes;
- automatic radical conversion;
- ordering between two unrelated algebraic certificates;
- a public decimal approximation command.

Those are separate capability gates.

## Resource model

The pure core is exact and deterministic. The eventual public adapter must bound
at least polynomial degree, coefficient bits, interval endpoint bits, Sturm-chain
work, remainder growth, refinement steps, and result bytes. Resource exhaustion
must be explicit.

## Verification gates before promotion

Before this substrate is promoted into a first-class CENTL value, require:

1. normalization examples and invariants;
2. exact Sturm counts against independently known polynomials;
3. positive and negative `sqrt(2)` isolation;
4. multi-root interval rejection;
5. endpoint-root rejection;
6. repeated-root rejection;
7. rational-root midpoint detection;
8. repeated exact refinement preserving one-root isolation;
9. independent differential root-count tests;
10. adversarial degree/coefficient/interval resource tests at the public boundary;
11. strict machine schema and provenance;
12. integration with the canonical value/evaluator architecture.

Only after the wider algebraic-number requirements land should the general
algebraic scalar checklist item be checked.
