# Exact complex rational scalars

Status: implementation in progress.

Capability: exact complex rational scalar domain  
Domain: P0 scalar and algebraic substrate  
Backlog item: `A1. General exact complex rational scalar domain`

## Mathematical definition

CENTL represents a complex rational scalar as an ordered pair

`z = (a, b)` with `a, b in Q`, interpreted as `a + b*i`.

The representation is canonical when both rational components are individually
normalized to positive denominators and relatively-prime numerator/denominator
pairs.

The first admitted operation set is deliberately small:

- construction from exact rational real and imaginary components;
- addition and subtraction;
- multiplication;
- division by a nonzero complex rational;
- additive negation;
- integer powers, including negative powers for nonzero bases;
- conjugation;
- real and imaginary component projection;
- exact squared modulus `a^2 + b^2`;
- exact equality.

## Accepted inputs

The canonical evaluator accepts closed complex-rational expressions built from:

- exact integer, finite-decimal, and rational literals;
- `complex(real, imaginary)` where both arguments evaluate to exact rationals;
- the admitted arithmetic operators over complex-rational operands;
- the exact complex functions `re`, `im`, `conj`, and `norm2`.

This first slice does **not** reserve a global identifier such as `i`. That avoids
silently changing existing symbolic-variable semantics. Human rendering may use
`i`, but construction remains explicit through `complex(a,b)` until a separate
language-design decision is made.

## Returned value model

A successful result is an exact value containing two normalized rational
components:

- `real`;
- `imaginary`.

Human output renders the pair canonically. Machine output must expose both
components structurally and label the result `exact`.

## Result classification

All successful values in this slice are **exact**. No floating-point fallback is
permitted. Operations that leave the exact complex-rational domain are not
silently approximated.

## Assumptions and conventions

- The field is `Q(i)` restricted here to pairs of rational components.
- Equality is componentwise exact equality after normalization.
- Division uses `(a+bi)/(c+di) = ((a+bi)(c-di))/(c^2+d^2)`.
- `norm2(z)` means the exact squared modulus `re(z)^2 + im(z)^2`, not the
  generally irrational modulus `sqrt(norm2(z))`.
- Integer exponent zero returns one for every nonzero base; `0^0` is undefined.
- Negative integer exponents require a nonzero base.

## Boundary cases

- Division by `complex(0,0)` is a mathematical domain error.
- `complex(0,0)^0` is undefined.
- Negative powers of zero are a division-by-zero/domain error.
- A `complex(real, imaginary)` component that is not provably an exact rational
  is outside this slice and remains unsupported rather than approximated.

## Refusal cases

This slice refuses:

- transcendental or algebraic-nonrational real/imaginary components;
- complex logarithms, roots, trigonometric functions, or branch-cut semantics;
- automatic conversion of unresolved symbols into complex values;
- approximate complex arithmetic;
- matrices or polynomials over complex rationals until their own capability
  contracts land.

## Non-goals

This is not yet the general exact algebraic-number domain, complex enclosure
backend, or a complete complex-analysis system. It is the exact field substrate
needed by later P0/P1 work.

## Algorithm and backend

The canonical implementation is native OCaml over Zarith exact rationals. It
does not call a floating-point backend. Arithmetic is implemented directly from
field identities and normalized by Zarith rational construction.

Independent oracle: Julia/Nemo or an independently coded rational-pair oracle in
CI. The implementation must not use the same code path as its verifier.

## Resource limits

The existing CENTL expression-node, source-byte, exact-bit, and result-byte
limits remain authoritative at the public evaluator boundary. Complex results
must count both rational components toward exact-bit and output limits.

No loop in the base field operations is unbounded except integer exponentiation,
which must use exponentiation by squaring and remain bounded by the existing
integer/expression limits.

## Cancellation points

Base arithmetic operations are short exact operations and need no internal
cancellation point after admission. Any future bulk complex operation must add
its own deterministic checkpoints.

## Machine schema

The promoted machine value is additive to the existing protocol and has the
shape:

```json
{
  "kind": "complex_rational",
  "exact": true,
  "real": {"numerator": "1", "denominator": "2"},
  "imaginary": {"numerator": "-3", "denominator": "4"},
  "text": "1/2 - 3/4*i"
}
```

Adapters must delegate to the same canonical evaluator.

## Evidence and provenance

The exact value itself is its arithmetic certificate: both components are
normalized rationals. Property tests additionally check field identities and
reconstruct division by multiplying the quotient by the divisor.

## Tests required before promotion

- exact examples for every admitted operation;
- zero divisor, zero power, and negative-power boundaries;
- normalization/canonical rendering checks;
- commutativity and associativity for addition/multiplication on generated small
  rationals;
- distributivity;
- conjugation involution and `norm2(z) = z*conj(z)` component identity;
- division reconstruction for nonzero divisors;
- independent differential cases;
- adversarial large numerator/denominator bit sizes and result-size limits;
- strict machine-schema tests.

## Promotion condition

The backlog item stays unchecked until the canonical evaluator, public machine
schema, human adapter, resource accounting, unit/property/differential/adversarial
tests, documentation, and branch CI all satisfy
`MATHEMATICS-IMPLEMENTATION-STANDARD.md`.
