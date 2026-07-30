# Numerical contract

## Exact values

Integer literals denote unbounded integers. A finite decimal literal denotes an
exact rational with a power-of-ten denominator. Fractions are normalized to a
positive denominator and relatively prime numerator and denominator.

For example:

```text
0.1        = 1/10
1.2300     = 123/100
0.1 + 0.2  = 3/10
```

Trailing zeros may be retained as presentation provenance without changing the
mathematical value.

An operation on exact inputs remains exact whenever its mathematical result is
represented by the exact domain. Approximation never occurs merely because an
exact computation is expensive.

## Symbolic exact values

Some values outside the rationals can remain exact through a symbolic backend,
including algebraic numbers and recognized constants. A symbolic result is
reported as exact only when the backend establishes the required property.
Failure to establish a property yields unknown, not a guessed answer.

Formal expressions and derivatives can also remain exact without being reduced
to a closed form. Exactness means the expression is preserved symbolically; it
does not claim that the expression is canonical, elementary, or numerically
approximated.

Polynomial canonicalization uses exact rational coefficient lists. A requested
transformation outside its documented domain remains symbolic and unchanged;
unsupported algebra is never interpreted as a successful factorization.

## Enclosures

An approximate real result denotes a set containing the mathematical result.
The fundamental backend contract is inclusion:

```text
mathematical value is contained in returned enclosure
```

Internally, backend balls are transferred as exact dyadic components. The core
checks sign, radius, exponent, finiteness, and size constraints before use.

Operations on enclosures preserve inclusion. If dependency growth or an
algorithmic limitation produces an enclosure too wide to satisfy the request,
CENTL increases precision or reports the unresolved enclosure.

## Precision requests

Users request a property of the result, not merely a working precision. Typical
requests include:

- at least `n` justified significant decimal digits;
- an absolute enclosure width below a threshold;
- a relative enclosure width below a threshold;
- an explicit outward-rounded decimal interval.

The evaluator selects an initial binary precision, checks the resulting
enclosure, and retries with higher precision within configured limits.

The current calculator syntax is `approx(expression)` for 20 significant digits
or `approx(expression, digits)` for an explicit request from 1 through 1000.
Working precision starts above the decimal target with a guard margin and may
double up to 16,384 bits. These are resource limits, not claims that every
request can be resolved.

Machine evaluation also bounds source bytes, expanded and resolved expression
nodes, symbolic-transformation work, estimated exact-result bits, integer
iterations, and session definitions before entering expensive operations.
`centl --serve` reports the active ceilings through `describe` and accepts lower
per-request limits.

## Rendering

Exact values are rendered exactly. Enclosures may be rendered as a midpoint and
radius, lower and upper endpoints, or a decimal prefix followed by explicit
uncertainty.

An unqualified decimal digit may be printed only when every value in the full
enclosure has that digit in the chosen rounding interpretation. Otherwise CENTL
must expose the uncertainty or request more precision.

The renderer must not infer accuracy from the number of digits present in a
backend string.

The native backend does not provide CENTL's displayed decimal. It returns exact
integer endpoints and a shared binary exponent. CENTL converts those dyadics to
rationals and rounds the lower endpoint down and the upper endpoint up at the
requested significant-decimal scale. Success requires the exact dyadic width to
be no more than half one unit at that scale; reaching the working-precision
ceiling without satisfying that test is `insufficient_precision`.

## Comparisons and domains

Comparisons over exact values are two-valued when decidable. Comparisons over
enclosures are three-valued:

```text
certainly true
certainly false
unknown at this precision
```

Domain errors distinguish certainly invalid inputs from enclosures containing
both valid and invalid points. Increasing precision may resolve the latter.

Local assumptions can justify otherwise conditional symbolic identities. For
example, cancellation in `x/x` requires a condition establishing `x != 0`.
CENTL retains that condition in the result instead of silently widening the
domain of the simplified expression.

## Failures

Numerical failure is data, not fabricated output. Structured outcomes include:

- invalid syntax;
- mathematical domain error;
- unknown comparison;
- insufficient precision;
- resource limit reached;
- unsupported exact operation;
- backend failure;
- violated backend contract.

Every failure identifies the expression and mathematical condition involved
without exposing irrelevant compiler internals.
