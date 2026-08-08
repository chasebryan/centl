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

`assert(left relation right)` `# comment`

`assert(...)` checks a claim without adding a session definition. It exits
successfully only for a `verified` verdict; `refuted`, `unknown`, and `invalid`
claims are unsuccessful. A quantified rational form is also accepted:
`assert(left relation right, for_all = x, domain = rational)`.

## Example calculation forms

```text
exact          0.1 + 0.2                         -> 3/10
calculus       diff(x^3 + 2*x + 1, x)            -> 3 * x^2 + 2
integration    integrate(x^2, x = 0, 1)          -> 1/3
equation       solve(x^2 = 2, x)                  -> x in {-sqrt(2), sqrt(2)}
definition     f(x) = x^2 + 1                    -> f(x) = x^2 + 1
sequence       sequence(k^2, k = 1, 4)           -> [1, 4, 9, 16]
recurrence     recurrence(1, a = a*n, n = 0, 4)  -> [1, 1, 2, 6, 24]
geometry       circle_area(3)                    -> 9 * pi
rigorous       approx(sqrt(2), 12)               -> ≈ [1.41421356237, 1.41421356238]
```

Inside the calculator, type `:syntax` for the catalog or `:help` for usage.
Definitions are immutable and last for the current calculator session or
script. Approximate a definition when using it: `approx(f(2), 20)`.
`solve` handles exact linear equations and real quadratics with rational
coefficients. Positive nonsquare discriminants return a canonical exact pair
`center - sqrt(radicand)` and `center + sqrt(radicand)`; CENTL does not turn
these roots into decimal approximations. Higher-degree and otherwise
unsupported equations return an explicit unresolved value plus an
`unsupported` resolution label and reason.

The integration forms accept rational-coefficient univariate polynomials with
positive powers no larger than 64. Explicit zero powers remain residual to
preserve the possible `0^0` error. `integrate(p, x)` selects the zero-constant
antiderivative, while `integrate(p, x = a, b)` requires exact rational bounds.
Unsupported integrals stay visible as `integrate(...)` expressions and carry
an `unsupported` resolution label. `simplify`, `expand`, and `factor` similarly
report when an input is outside their documented polynomial domains. If
`simplify` or `expand` proves that an expression is already in its requested
form, the result is labeled `unchanged_proved`; an unchanged value is never
presented as if a transformation silently succeeded.

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
offer Tab completion and bounded durable history through Up/Down, `:history`,
and `:clear-history`.

### Interactive history

Interactive history is loaded when the calculator starts and each accepted
entry is saved immediately. It contains calculator input only; definitions and
evaluation state still last only for the current session. `:clear-history`
clears both the current editor history and the saved file.

The version-1 JSON history file is stored at:

- Unix: `$XDG_STATE_HOME/centl/history.json` when `XDG_STATE_HOME` is a
  nonempty absolute path, otherwise `$HOME/.local/state/centl/history.json`.
- Windows: `%LOCALAPPDATA%\centl\history.json`, falling back to
  `%APPDATA%\centl\history.json` and then
  `%USERPROFILE%\AppData\Local\centl\history.json` when needed.

CENTL keeps at most 1,000 entries, 1,048,576 serialized bytes, and 32,768 bytes
per entry. Oldest entries are discarded first. Blank, adjacent duplicate,
oversized, and terminal-control entries are not retained.

On Unix, CENTL creates its state directory with mode `0700` and its history and
lock files with mode `0600`. Windows relies on the current account's operating
system access controls because OCaml's Unix-compatible file modes cannot
express Windows ACLs. Writes re-read and merge the current disk state under a
cross-process lock, fsync a private temporary file, and atomically replace the
history file; CENTL's Windows reads permit that replacement while they are
open. This prevents concurrent writers from replacing one another's additions.
A running editor keeps its startup snapshot; entries from another process
become available after the next launch. A clear and concurrent adds are ordered
by the same lock, and stale in-memory snapshots are never written back
wholesale.

Use `--no-history` for one invocation, set `CENTL_NO_HISTORY` to any value, or
set `CENTL_HISTORY` to `0`, `false`, `no`, or `off` to disable disk reads and
writes. Up/Down and `:history` continue to work in memory for that process.

Version 1 is CENTL's first on-disk history format, so there is no legacy file
to migrate or plaintext format to import. Malformed files and files with an
unknown version are ignored safely. The next saved entry replaces such a file
with a valid version-1 file; CENTL never guesses at or executes unknown history
content.
