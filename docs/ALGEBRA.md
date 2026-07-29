# Exact symbolic algebra

CENTL 0.3 adds calculator-native polynomial operations:

```text
simplify(2*x + 3*x)
5 * x

expand((x + 1)^3)
x^3 + 3 * x^2 + 3 * x + 1

factor(x^2 - 1)
(x - 1) * (x + 1)
```

Canonical univariate polynomials use exact rational coefficients. Addition,
subtraction, multiplication, constant division, and positive integer powers are
performed in the verified F* core. Expansion is currently bounded to powers no
larger than 64; a larger or unsupported expression remains visible rather than
consuming unbounded resources or returning a guessed form.

The initial factorizer recognizes differences of squares, unit perfect-square
quadratics, and common monomial factors. Unsupported factors return the
canonical expression unchanged.

## Assumptions

`assuming` attaches an explicit condition to a result and permits only
simplifications justified by that condition:

```text
assuming(x / x, x != 0)
1 where x != 0

assuming(x / x, x >= 0)
x / x where x >= 0
```

Conditions are preserved in human output and emitted structurally in JSON.
They are local to the expression; persistent session assumptions are not yet
implemented.

## Equations

Use ordinary equality inside `solve`:

```text
solve(2*x + 3 = 11, x)
x = 4

solve(x^2 - 5*x + 6 = 0, x)
x in {2, 3}
```

CENTL classifies exact univariate polynomials in its verified core. This first
slice solves linear equations and quadratics whose real roots are rational. It
also distinguishes no solutions from all values. A quadratic with irrational
roots, a higher-degree equation, or a non-polynomial equation is reported as
`unresolved` instead of guessed or silently approximated.
