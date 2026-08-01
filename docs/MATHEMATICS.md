# Mathematical functions

CENTL keeps exact expressions exact and approximates only when asked.

```text
sqrt(4/9)                    = 2/3
circle_area(3)               = 9 * pi
approx(sqrt(2), 20)          ≈ [1.4142135623730950488, 1.4142135623730950489]
```

`approx(expression)` requests 20 significant decimal digits.
`approx(expression, digits)` requests between 1 and 1000. The result is an
outward-rounded interval containing the mathematical value, not a point
estimate disguised as an exact answer.

## Trigonometry and elementary functions

Angles are radians unless converted explicitly with `radians(degrees)` or
`degrees(radians)`.

```text
sin(x)   cos(x)   tan(x)
asin(x)  acos(x)  atan(x)  atan2(y, x)
sinh(x)  cosh(x)  tanh(x)
sqrt(x)  exp(x)   log(x)   abs(x)
```

The exact constants are `pi`, `e`, and `tau`. Trigonometric expressions remain
symbolic until approximation is requested. Differentiation understands the
one-argument functions above except `abs`.

## Geometry

The initial geometry vocabulary is deliberately direct:

```text
square_area(side)
rectangle_area(width, height)
rectangle_perimeter(width, height)
triangle_area(base, height)
trapezoid_area(base1, base2, height)
circle_area(radius)
circumference(radius)
sphere_area(radius)
sphere_volume(radius)
cylinder_volume(radius, height)
hypot(a, b)
distance(x1, y1, x2, y2)
slope(x1, y1, x2, y2)
```

These are exact formula expansions. Rational inputs therefore produce exact
rational results, while results involving `pi` or an irrational square root
remain exact symbolic expressions. Wrap any result in `approx` for a rigorous
real enclosure.

## Concrete mathematics

CENTL currently includes exact unbounded-integer primitives for:

```text
gcd(a, b)             lcm(a, b)
factorial(n)           fibonacci(n)
choose(n, k)           permutations(n, k)
```

Finite sums, products, recurrences, sequences, and generating functions are
the concrete-mathematics layer. The first bounded iteration slice provides:

```text
sum(expression, variable = lower, upper)
product(expression, variable = lower, upper)
```

Both bounds are inclusive exact integers. Empty sums are `0`, empty products
are `1`, and every term is combined exactly within the active machine resource
limits. See [exact finite iteration](ITERATION.md). Recurrences, sequences, and
generating functions remain the next extensions; they will use calculator
syntax and the same exact-first value model rather than a separate subsystem.

## Current limits

- Approximation supports real arithmetic, integer powers, the constants above,
  and the listed elementary functions.
- Unresolved variables cannot be approximated until they are substituted.
- Complex values, units, geometric objects, limits, series, and integration are
  planned but are not silently simulated by the current evaluator.
- A failed domain proof or exhausted precision budget is a structured error.
