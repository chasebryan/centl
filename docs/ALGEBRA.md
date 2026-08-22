# Exact Symbolic & Polynomial Algebra

CentL26.10 provides an arbitrary-precision, exact rational computer algebra engine. All polynomial arithmetic, factorization, root extraction, and equation solving are deterministic, rigorous, and 100% offline.

---

## Canonical Polynomial Operations

CentL26 represents univariate polynomials with exact rational coefficients:

```text
simplify(2*x + 3*x)
5*x

expand((x + 1)^3)
x^3 + 3*x^2 + 3*x + 1

factor(x^2 - 9)
(x - 3)*(x + 3)

factor(x^2 - 5*x + 6)
(x - 2)*(x - 3)

factor(x^3 - 6*x^2 + 11*x - 6)
(x - 1)*(x - 2)*(x - 3)
```

Polynomial operations include addition, subtraction, multiplication, division with remainder, differentiation, and integration.

---

## Smart Implicit Multiplication

CentL26.10 features natural mathematical notation parsing without requiring explicit asterisks (`*`), while distinguishing mathematical expressions from plain-English queries:

```text
2x + 5 = 15          # → x = 5
5x^2                 # → 5*x^2
3(x + 1)             # → 3*x + 3
(x - 1)(x + 1)       # → x^2 - 1
4pi                  # → 4*pi
2sin(x)              # → 2*sin(x)
```

---

## High-Precision Rational Root Theorem Solver

CentL26.10 implements a complete Rational Root Theorem solver combined with exact synthetic division (`synthetic_divide_root`) and radical isolation:

- For a polynomial $P(x) = a_n x^n + \dots + a_1 x + a_0$ with integer/rational coefficients, all candidate rational roots $p/q$ (where $p \mid a_0$ and $q \mid a_n$) are evaluated deterministically.
- Discovered roots are factored out via synthetic division to reduce polynomial degree.
- Quadratic remainders with non-square discriminants are solved with exact canonical radical enclosures (`center ± sqrt(radicand)`).

---

## Direct Algebraic Equation Auto-Solving

CentL26 automatically identifies free variables in expressions and solves equations directly without requiring explicit `solve(...)` wrappers:

```text
# Linear equations:
2x + 3 = 7
x = 2

# Quadratic equations:
x^2 - 5x + 6 = 0
x in {2, 3}

# Radical quadratics:
x^2 = 2
x in {-sqrt(2), sqrt(2)}

# Cubic equations:
x^3 - 6x^2 + 11x - 6 = 0
x in {1, 2, 3}

# Direct variable assignment:
x = 5
x = 5
```

---

## Constant Mathematical Equality Verification

When an equation contains no free variables, CentL26 validates mathematical truth value directly:

```text
2 + 3 = 5
true

2 + 3 = 6
false

2^10 = 1024
true

0.1 + 0.2 = 3/10
true
```

---

## Assumptions

`assuming` attaches an explicit condition to a symbolic expression and permits only simplifications justified by that domain condition:

```text
assuming(x / x, x != 0)
1 where x != 0

assuming(x / x, x >= 0)
x / x where x >= 0
```

Conditions are preserved in human output and emitted structurally in JSON and receipts.

---

## Rational Matrices & Linear Algebra

CentL26 includes exact rational matrix operations:
- Determinants (`det(M)`)
- Matrix inverses (`inverse(M)`)
- Gaussian elimination and rational nullspace computation for stoichiometric reaction balancing.

