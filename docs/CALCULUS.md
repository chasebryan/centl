# Symbolic Calculus & Discrete Series

CentL26.10 provides an exact symbolic calculus engine supporting multi-order differentiation, exact integration, symbolic limits, Taylor series expansions, and discrete finite summations and products.

---

## Symbolic Differentiation

Differentiate symbolic expressions with respect to a named variable:

```text
diff(x^3 + 2*x + 1, x)
3*x^2 + 2

diff(sin(x) * exp(x), x)
exp(x)*sin(x) + exp(x)*cos(x)
```

### Higher-Order Differentiation

Pass a third argument `n` to compute the $n$-th derivative:

```text
diff(x^4, x, 3)
24*x

diff(sin(x), x, 4)
sin(x)

diff(exp(2*x), x, 3)
8*exp(2*x)
```

The differentiation engine knows exact derivative rules for polynomials, integer/rational powers, trigonometric functions (`sin`, `cos`, `tan`, `asin`, `acos`, `atan`), hyperbolic functions (`sinh`, `cosh`, `tanh`), `exp`, `log`, `sqrt`, and product/quotient/chain rules.

---

## Exact Integration

### Indefinite Integration (Antiderivatives)

`integrate(f, x)` computes the exact canonical antiderivative:

```text
integrate(3*x^2 + 2*x + 1, x)
x^3 + x^2 + x

integrate(sin(x), x)
-cos(x)

integrate(exp(x), x)
exp(x)
```

### Definite Integration

`integrate(f, x, a, b)` evaluates the integral over the interval $[a, b]$ with exact bounds:

```text
integrate(3*x^2 + 2*x, x, 0, 3)
36

integrate(x^2, x, 0, 1)
1/3
```

---

## Symbolic Limits & L'Hôpital's Rule

Compute analytical limits with automatic resolution of indeterminate forms ($0/0$, $\infty/\infty$) via L'Hôpital's Rule:

```text
limit((x^2 - 1)/(x - 1), x, 1)
2

limit(sin(x)/x, x, 0)
1

limit((exp(x) - 1)/x, x, 0)
1
```

---

## Taylor & Maclaurin Series

Generate exact Taylor polynomial approximations around a point $x = a$ up to order $n$:

```text
# Maclaurin expansion of exp(x) up to degree 3:
taylor(exp(x), x, 0, 3)
1 + x + 1/2*x^2 + 1/6*x^3

# Taylor expansion of sin(x) around 0 up to degree 5:
taylor(sin(x), x, 0, 5)
x - 1/6*x^3 + 1/120*x^5

# Taylor expansion of cos(x) around 0 up to degree 4:
taylor(cos(x), x, 0, 4)
1 - 1/2*x^2 + 1/24*x^4
```

---

## Discrete Summations & Products

Evaluate finite discrete sums and products over closed integer intervals:

```text
# Sum of k^2 from k = 1 to 5:
sum(k^2, k, 1, 5)
55

# Product of k from k = 1 to 5 (Factorial):
product(k, k, 1, 5)
120

# Sum of 2^k from k = 0 to 10:
sum(2^k, k, 0, 10)
2047
```

