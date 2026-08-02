# Symbolic calculus

CENTL's exact symbolic foundation makes names, integer powers, and mathematical
functions ordinary calculator expressions:

```text
x^2 + 2*x + 1
sin(x)
```

Differentiate with respect to a name:

```text
diff(x^3 + 2*x + 1, x)
3 * x^2 + 2
```

## Exact polynomial integration

CENTL 0.9.0 adds two exact integration forms.

`integrate(p, x)` returns the canonical antiderivative whose integration
constant is zero:

```text
integrate(3*x^2 + 2*x + 1, x)
x^3 + x^2 + x
```

This is one distinguished antiderivative, not a claim that every
antiderivative has zero constant. Differentiating the result with respect to
`x` recovers the accepted polynomial.

`integrate(p, x = a, b)` evaluates that antiderivative at the exact rational
bounds and subtracts:

```text
integrate(x^2, x = 0, 1)
1/3
```

Both forms accept rational-coefficient univariate polynomials in the named
variable, using the same positive-power expansion domain as the algebra engine
(powers from 1 through 64). An explicit zero power
such as `x^0` stays residual: reducing it to `1` would erase CENTL's definedness
distinction at `x = 0`, where `0^0` is an error. Write a constant directly when
that constant is the intended integrand. Divisors must also be visibly constant
to the bounded host preflight; a variable expression that only becomes constant
after cancellation stays residual unless it is simplified first.

The integration variable is local to the integrand; definite-integral bounds
are evaluated in the surrounding scope. An expression outside the accepted
domain remains visible rather than being guessed or approximated:

```text
integrate(sin(x), x)
integrate(sin(x), x)
```

Substitute an exact expression or value:

```text
substitute(x^2 + 1, x = 3)
10
```

The verified core currently knows exact derivative rules for integer powers,
arithmetic, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `sinh`, `cosh`,
`tanh`, `exp`, `log`, and `sqrt`. An unknown rule stays visible instead of being
guessed:

```text
diff(f(x), x)
```

Attach a domain condition without hiding it:

```text
assuming(diff(log(x), x), x > 0)
1 / x where x > 0
```

Colored terminal output distinguishes numbers (cyan), names (magenta),
functions (blue), operators (yellow), and grouping (muted). Pipes and JSON stay
plain; `--color=always`, `--no-color`, and `NO_COLOR` control terminal output.

Limits, series, rigorous integration outside the exact polynomial domain, and
broader symbolic integration are planned but not yet implemented.
