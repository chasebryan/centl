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
`diff(expression, variable)`
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

### Scripts

`# comment`

## Example calculation forms

```text
exact          0.1 + 0.2                         -> 3/10
calculus       diff(x^3 + 2*x + 1, x)            -> 3 * x^2 + 2
definition     f(x) = x^2 + 1                    -> f(x) = x^2 + 1
geometry       circle_area(3)                    -> 9 * pi
rigorous       approx(sqrt(2), 12)               -> ≈ [1.41421356237, 1.41421356238]
```

Inside the calculator, type `:syntax` for the catalog or `:help` for usage.
Definitions are immutable and last for the current calculator session or
script. Approximate a definition when using it: `approx(f(2), 20)`.
