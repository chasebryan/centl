# CENTL syntax

Type `./centl --syntax` at any time for this reference in the terminal.

CENTL is exact by default. Use `approx(...)` only when you want a rigorous real
enclosure.

## Implemented forms

### Values

`123` `0.125` `1/3` `x` `(expression)` `pi` `e` `tau`

### Arithmetic

`+x` `-x` `a + b` `a - b` `a * b` `a / b` `x^n`

### Symbolic math

`f(x, ...)` `name = expression` `f(x, ...) = expression`
`solve(left = right, variable)`
`diff(expression, variable)`
`integrate(expression, variable)`
`integrate(expression, variable = lower, upper)`
`substitute(expression, variable = value)` `simplify(expression)`
`expand(expression)` `factor(expression)` `assuming(expression, condition)`
`=  !=  <  <=  >  >=`

### Approximation

`approx(expression)` `approx(expression, digits)`

### Functions

`sqrt(x)` `abs(x)` `exp(x)` `log(x)` `sin(x)` `cos(x)` `tan(x)` `asin(x)`
`acos(x)` `atan(x)` `atan2(y, x)` `sinh(x)` `cosh(x)` `tanh(x)`
`radians(degrees)` `degrees(radians)`

### Geometry

`square_area(side)` `rectangle_area(width, height)`
`rectangle_perimeter(width, height)` `triangle_area(base, height)`
`trapezoid_area(base1, base2, height)` `circle_area(radius)`
`circumference(radius)` `sphere_area(radius)` `sphere_volume(radius)`
`cylinder_volume(radius, height)` `hypot(a, b)` `distance(x1, y1, x2, y2)`
`slope(x1, y1, x2, y2)`

### Concrete math

`gcd(a, b)` `lcm(a, b)` `factorial(n)` `choose(n, k)`
`permutations(n, k)` `fibonacci(n)`

### Finite iteration and sequences

`sum(expression, variable = lower, upper)`
`product(expression, variable = lower, upper)`
`sequence(expression, variable = lower, upper)`
`recurrence(initial, previous = step, index = lower, upper)`

### Scripts

`# comment`

## Example calculation forms

```text
exact          0.1 + 0.2                         -> 3/10
calculus       diff(x^3 + 2*x + 1, x)            -> 3 * x^2 + 2
integration    integrate(x^2, x = 0, 1)          -> 1/3
definition     f(x) = x^2 + 1                    -> f(x) = x^2 + 1
sequence       sequence(k^2, k = 1, 4)           -> [1, 4, 9, 16]
recurrence     recurrence(1, a = a*n, n = 0, 4)  -> [1, 1, 2, 6, 24]
geometry       circle_area(3)                    -> 9 * pi
rigorous       approx(sqrt(2), 12)               -> ≈ [1.41421356237, 1.41421356238]
```

Inside the calculator, type `:syntax` for the catalog or `:help` for usage.
Definitions are immutable and last for the current calculator session or
script. Approximate a definition when using it: `approx(f(2), 20)`.
`solve` currently handles exact linear equations and quadratics with rational
roots. Other equations return an explicit unresolved result.

The integration forms accept rational-coefficient univariate polynomials with
positive powers no larger than 64. Explicit zero powers remain residual to
preserve the possible `0^0` error. `integrate(p, x)` selects the zero-constant
antiderivative, while `integrate(p, x = a, b)` requires exact rational bounds.
Unsupported integrals stay visible as `integrate(...)` expressions.

Finite sequence bounds are inclusive exact integers. A sequence index scopes
only its element expression. In a recurrence, `initial` is the term at the
lower index; `previous` and `index` scope only `step`, which is evaluated for
each later index. A lower bound greater than the upper bound produces `[]`
without evaluating the element, initial value, or step. Sequence elements and
recurrence terms must be scalar exact values, and the resulting sequence is not
a scalar operand. See [exact finite iteration and sequences](ITERATION.md).

Statements may span lines without a continuation marker while parentheses are
open or an operator still needs a right-hand operand. The calculator shows
`....>` for continuation lines;
standard input and `--file` scripts use the same rule. Interactive terminals
offer Tab completion and process-local history through Up/Down, `:history`, and
`:clear-history`.
