# Exact multivariate rational polynomials

Status: implementation in progress.

Capability family: P0 algebraic substrate.  
Strategic backlog: `B2. Canonical multivariate polynomials`.

## Mathematical object

The first multivariate domain is the polynomial ring

`Q[x1, x2, ..., xn]`

for a finite set of symbolic variable names. A polynomial is represented as a
finite sparse map from monomials to exact rational coefficients.

A monomial is a finite map from variable name to nonnegative integer exponent.
Zero exponents are omitted. Variable names are stored in deterministic
lexicographic order. Duplicate variable occurrences in an input monomial are
combined by exact exponent addition.

A polynomial is canonical when:

- every monomial is canonical;
- every coefficient is a normalized rational;
- no zero coefficient is stored;
- equal monomials occur exactly once.

## First admitted operations

- zero, one, rational constants, and single variables;
- exact term construction;
- equality;
- addition and subtraction;
- additive negation and rational scalar multiplication;
- polynomial multiplication;
- nonnegative integer powers;
- exact coefficient lookup;
- variable discovery;
- total degree;
- exact partial differentiation;
- exact rational substitution for any selected subset of variables.

Rational substitution is partial: substituted variables disappear from the
corresponding monomial factors while unassigned variables remain symbolic.

## Power convention

For a nonzero polynomial, exponent zero returns one. `0^0` is undefined and is
reported explicitly. Negative powers are outside the polynomial ring and are
not silently converted into rational functions.

## Differentiation

For a term

`c * x^k * m`

where `m` contains no `x`, the partial derivative with respect to `x` is

`c*k * x^(k-1) * m`.

Terms with no occurrence of the requested variable differentiate to zero.

## Exact substitution

A rational substitution map such as

`{x -> 2, z -> -3/5}`

is applied term-by-term. Each assigned power is evaluated exactly in `Q`; the
remaining unassigned monomial is retained canonically. Terms that collapse onto
the same monomial are combined and zero sums are removed.

## Result classification

Every successful value in this slice is **exact**. No floating-point path exists
inside the canonical polynomial implementation.

## Invalid inputs and refusal boundary

The core rejects:

- empty variable names;
- negative monomial exponents;
- `0^0`;
- negative polynomial powers.

This slice does not yet claim:

- general rational functions;
- polynomial quotient/remainder;
- GCD or extended GCD;
- factorization;
- resultants or discriminants;
- Groebner bases or ideals;
- algebraic-extension coefficients;
- complex coefficients;
- finite-field coefficients;
- a privileged monomial ordering for Groebner algorithms.

The canonical storage order is an implementation determinism rule, not a claim
that lexicographic order has been selected as the future Groebner monomial order.

## Resource model

The pure core does not own public request ceilings. The public adapter must bound
at least:

- input term count;
- variable count;
- exponent magnitude;
- exact coefficient bits;
- intermediate/generated term count;
- multiplication/power work;
- result bytes.

Expansion blowup must return `resource_limit` at the public boundary rather than
silently dropping terms or approximating coefficients.

## Machine representation

The eventual machine value is sparse and structural. A polynomial such as

`3/2*x^2*y - 5`

is represented by exact terms rather than by parsing display text:

```json
{
  "kind": "multivariate_rational_polynomial",
  "exact": true,
  "terms": [
    {
      "coefficient": {"numerator":"3","denominator":"2"},
      "powers": [{"variable":"x","exponent":2},{"variable":"y","exponent":1}]
    },
    {
      "coefficient": {"numerator":"-5","denominator":"1"},
      "powers": []
    }
  ]
}
```

Human text is presentation only.

## Verification gates before promotion

The backlog item remains unchecked until applicable admission gates include:

1. canonicalization tests for duplicate powers, zero exponents, and zero
   coefficients;
2. ring identity tests over generated exact samples;
3. multiplication/expansion examples such as `(x+y)^n` for bounded `n`;
4. exact partial-derivative reconstruction examples;
5. rational-substitution equivalence tests;
6. coefficient/degree/variable-query tests;
7. an independent differential oracle;
8. adversarial term-growth/exponent/bit/output limits at the public boundary;
9. strict machine schemas;
10. integration with the canonical CENTL evaluator rather than a second hidden
    algebra engine;
11. CI, documentation, and security review required by
    `MATHEMATICS-IMPLEMENTATION-STANDARD.md`.
