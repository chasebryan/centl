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

Limits, series, rigorous definite integration, and partial symbolic integration
are planned but not yet implemented.
