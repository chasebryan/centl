# Exact finite iteration

CENTL evaluates finite sums and products with the same exact-first semantics as
ordinary calculator expressions:

```text
sum(k^2, k = 1, 100)              -> 338350
product(k, k = 1, 20)             -> 2432902008176640000
sum(1/k, k = 1, 4)                -> 25/12
```

The syntax is `sum(expression, variable = lower, upper)` or
`product(expression, variable = lower, upper)`. Bounds are inclusive and must
evaluate exactly to integers. They are evaluated outside the iterator scope;
the iterator is local to the body and shadows a calculator-session definition
with the same name.

Finite iterations may be nested, and an inner body or bound may depend on an
outer iterator:

```text
sum(sum(i*j, j = 1, i), i = 1, 4) -> 65
```

Reusing the same iterator name creates a new inner scope. Substitution enters
iteration bodies and bounds, but it does not replace occurrences bound by the
iterator itself. This makes
`substitute(sum(k*x, k = 1, 4), x = 3)` equal to `30`, while substituting for
`k` leaves `sum(k, k = 1, 4)` unchanged before evaluation.

An empty range is well-defined: if `lower > upper`, `sum` returns `0` and
`product` returns `1`. Iteration never switches to floating-point arithmetic.
Wrap the completed expression in `approx(...)` only when its exact result needs
a rigorous real enclosure.

## Resource and cancellation behavior

Each term is substituted and combined through the verified exact core. The
number of inclusive range elements counts against `max_integer_iterations`.
Nested iterations share this request-wide budget: the outer range and every
inner range that is actually evaluated all consume from the same total.
Intermediate exact-result size and symbolic-expression size remain subject to
`max_exact_bits` and `max_expression_nodes`; exceeding a ceiling returns a
structured `resource_limit` error instead of a partial value. Symbol text and
rendering overhead count against `max_result_bytes`, preventing a long
identifier from being repeated into an oversized human or JSON response.
Reduction is streamed through a logarithmic set of balanced partial results,
so terms are never all materialized at once. The retained symbolic nodes across
those partials share `max_expression_nodes`. Evaluation also has a derived
request-wide traversal budget of `64 * max_integer_iterations` node-work units;
substitution, term evaluation, nested iteration, and balanced reduction consume
that budget and fail incrementally when it is exhausted.

Stateful machine requests also observe their request cancellation token between
terms. Cancellation returns the stable `cancelled` error and never installs a
partial definition or reports a partial sum/product.

Human, JSON, persistent JSON Lines, and MCP calls all use this same evaluator and
therefore return the ordinary exact integer, rational, or symbolic result shape.
`sum` and `product` are built-in names, so definitions and function parameters
cannot redefine them. Iterator names must likewise be ordinary non-built-in
identifiers.
