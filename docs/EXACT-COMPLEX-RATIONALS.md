# Exact complex rational scalars

Status: admission candidate, not yet promoted.

Capability: exact complex rational scalar domain  
Domain: P0 scalar and algebraic substrate  
Backlog item: `A1. General exact complex rational scalar domain`

## Mathematical definition

CENTL represents a complex rational scalar as an ordered pair

`z = (a, b)` with `a, b in Q`, interpreted as `a + b*i`.

The representation is canonical when both rational components are individually
normalized to positive denominators and relatively-prime numerator/denominator
pairs.

The admitted operation set is deliberately exact:

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

The exact complex evaluator accepts closed complex-rational expressions built
from:

- exact integer, finite-decimal, and rational literals;
- `complex(real, imaginary)` where both arguments evaluate to exact rationals;
- the admitted arithmetic operators over complex-rational operands;
- the exact complex functions `re`, `im`, `conj`, and `norm2`.

This slice does **not** reserve a global identifier such as `i`. That avoids
silently changing existing symbolic-variable semantics. Human rendering may use
`i`, but construction remains explicit through `complex(a,b)` until a separate
language-design decision is made.

## Returned value model

A successful result contains two normalized exact rational components:

- `real`;
- `imaginary`.

Human output renders the pair canonically. Machine output exposes both components
structurally and labels the result `exact`.

## Result classification

All successful values in this slice are **exact**. No floating-point fallback is
permitted. Operations that leave the exact complex-rational domain fail
explicitly rather than being silently approximated.

## Assumptions and conventions

- The field is `Q(i)` restricted here to pairs of rational components.
- Equality is componentwise exact equality after normalization.
- Division uses `(a+bi)/(c+di) = ((a+bi)(c-di))/(c^2+d^2)`.
- `norm2(z)` means the exact squared modulus `re(z)^2 + im(z)^2`, not the
  generally irrational modulus `sqrt(norm2(z))`.
- Integer exponent zero returns one for every nonzero base; `0^0` is undefined.
- Negative integer exponents require a nonzero base.

## Boundary and refusal cases

- Division by `complex(0,0)` is a mathematical domain error.
- `complex(0,0)^0` is undefined.
- Negative powers of zero are a division-by-zero/domain error.
- A `complex(real, imaginary)` component that is not provably an exact rational
  is outside this slice and remains unsupported rather than approximated.
- Transcendental or algebraic-nonrational real/imaginary components are refused.
- Complex logarithms, roots, trigonometric functions, and branch-cut semantics
  are not claimed by this substrate.
- Unresolved symbols are not automatically converted into complex values.
- Matrices or polynomials over complex rationals remain separate future domains.

## Algorithm and backend

The implementation is native OCaml over Zarith exact rationals. Arithmetic is
implemented directly from field identities and normalized by Zarith rational
construction. Integer powers use exponentiation by squaring.

The exact adapter does not call a floating-point backend.

## Resource model

The complex core now enforces three independent deterministic boundaries during
evaluation:

1. an exact-bit ceiling over the two rational components of every admitted
   intermediate value;
2. a maximum absolute integer exponent for power operations;
3. a work budget consumed by recursive expression traversal and
   repeated-squaring checkpoints.

The exact-bit guard runs inside exponentiation after each multiply and square.
An oversized intermediate therefore stops immediately instead of continuing
until a final result is formed.

The public exact-complex protocol additionally enforces source-byte and
result-byte ceilings. Its public limit record remains backward-compatible while
the hardened core uses fixed work and power ceilings at CENTL's normal default
integer-iteration scale. The canonical mathematics gateway still clamps the
public source, exact-bit, and result-byte ceilings inherited from its enclosing
server.

## Cancellation

Complex evaluation is cooperatively cancellable. Cancellation is checked during
recursive expression evaluation and inside exponentiation-by-squaring. This is
stronger than a one-time dispatch check: a request may be interrupted after
exact work has begun, and the result is the explicit `cancelled` failure rather
than a partial or approximate value.

## Public machine surfaces

The exact complex-rational substrate is available through the canonical
mathematics gateway as `complex_rational`, including:

- the JSONL `op: "math"` route;
- the closed-schema MCP `centl_math` tool.

The gateway propagates cooperative cancellation into this domain and preserves
its exact result and failure provenance.

The standalone domain protocol returns values in this shape:

```json
{
  "kind": "complex_rational",
  "exact": true,
  "real": {"numerator": "1", "denominator": "2", "text": "1/2"},
  "imaginary": {"numerator": "-3", "denominator": "4", "text": "-3/4"},
  "text": "1/2 - 3/4*i"
}
```

## Provenance and errors

Successful protocol results carry:

- classification: `exact`;
- method: `exact_complex_rational_evaluation`;
- backend: `centl-exact-complex`.

Machine-readable failures distinguish zero denominators, complex division by
zero, undefined powers, unsupported exact components/expressions,
`resource_limit`, syntax errors, and `cancelled`.

The value itself is an arithmetic certificate: both components are normalized
rationals. Tests additionally verify field identities, division reconstruction,
conjugation involution, and `z*conj(z) = norm2(z)`.

## Adversarial evidence

The test suite includes:

- exact examples for every admitted operation;
- zero-divisor, zero-power, and negative-power boundaries;
- field-law checks over a grid of nontrivial rational complex values;
- strict refusal of nonrational exact components;
- exact-bit and source/result resource refusals;
- oversized power-exponent refusal;
- cancellation before evaluation and during repeated squaring;
- a power whose admitted input grows beyond the exact-bit ceiling during
  repeated squaring;
- a 4096-bit exact `z/z = 1` field identity;
- canonical rendering and strict machine-schema checks.

## Promotion condition

The strategic backlog item remains unchecked until all applicable requirements
in `MATHEMATICS-IMPLEMENTATION-STANDARD.md` are satisfied. In particular, this
hardening checkpoint does not claim first-class integration into the ordinary
`Centl_engine.exact_value` path. Canonical evaluator-value integration, its
rendering/JSON/provenance representation, and the corresponding MCP output
schema must land before promotion.
