# Exact finite iteration and sequences

CENTL evaluates bounded sums, products, sequences, and first-order recurrences
with the same exact-first semantics as ordinary calculator expressions:

```text
sum(k^2, k = 1, 100)              -> 338350
product(k, k = 1, 20)             -> 2432902008176640000
sum(1/k, k = 1, 4)                -> 25/12
sequence(k^2, k = 1, 5)           -> [1, 4, 9, 16, 25]
recurrence(1, a = a*n, n = 0, 5)  -> [1, 1, 2, 6, 24, 120]
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

Substitution is simultaneous and capture-avoiding. In particular, a free name
in a replacement remains free if it matches an iterator name. For example,
`substitute(sum(x, k = 1, 3), x = k)` produces three free occurrences of `k`;
it does not turn them into the iteration values `1`, `2`, and `3`. CENTL
alpha-renames the iterator when necessary, choosing a parser-valid internal
name that is absent from the body and every replacement. The bounded fresh-name
search also skips an already occupied internal-looking name, so stored symbolic
definitions remain unambiguous and can be parsed again. Both bounds stay
outside the renamed iterator's scope.

## Exact sequences

`sequence(expression, variable = lower, upper)` returns the exact value of the
element expression at every inclusive integer index:

```text
sequence(k/3, k = 1, 3)       -> [1/3, 2/3, 1]
sequence(x + k, k = 0, 2)     -> [x, x + 1, x + 2]
```

The index scopes only the element expression. Bounds are evaluated in the
surrounding calculator scope, so a stored definition with the same name can be
used by either bound while the element expression still sees the index. The
same simultaneous, capture-avoiding substitution rule used by sums and
products applies to sequence bodies.

An empty range does not expand or evaluate its body, including calls to stored
session functions. Recurrences apply the same rule to both the unused initial
value and step expression.

Every element must be an exact scalar integer, rational, or symbolic value.
Approximate values, solution sets, and nested sequences are rejected with
`exact_sequence_required`. A sequence can be returned directly, stored in an
immutable value definition, or returned by a user function, but it cannot be
used as an arithmetic operand or passed to a scalar operation; that use returns
`sequence_not_expression`.

## Exact first-order recurrences

The syntax is
`recurrence(initial, previous = step, index = lower, upper)`. The initial value
is the term at `lower`. For each current index from `lower + 1` through `upper`,
CENTL evaluates `step` with `previous` bound to the preceding exact term and
`index` bound to the current integer:

```text
recurrence(3, a = 2*a, n = 4, 7)    -> [3, 6, 12, 24]
recurrence(10, a = a+n, n = 1, 4)   -> [10, 12, 15, 19]
```

The previous-value and index names must be distinct ordinary identifiers. They
scope only `step`; the initial expression and both bounds are evaluated in the
surrounding scope. Substitution removes both bound names while entering the
step and alpha-renames either binder when necessary to keep free replacement
names free. Recurrence terms obey the same exact-scalar rule as sequence
elements and the result is the same exact sequence value.

Empty ranges are well-defined. If `lower > upper`, `sum` returns `0`, `product`
returns `1`, and `sequence` or `recurrence` returns `[]`. Empty sequences do not
evaluate their element expression; empty recurrences do not evaluate either
the initial value or the step. None of these operations switches to
floating-point arithmetic. Wrap a completed scalar sum or product in
`approx(...)` only when that scalar exact result needs a rigorous real
enclosure; exact sequences are not scalar approximation operands.

## Resource and cancellation behavior

Each term is substituted and evaluated through the verified exact core. The
number of inclusive range elements counts against `max_integer_iterations`;
the initial recurrence value counts as the lower-index element. Nested bounded
operations share this request-wide budget: the outer range and every inner
range actually evaluated all consume from the same total.

Exact-value size and symbolic-expression size remain subject to
`max_exact_bits` and `max_expression_nodes`; exceeding a ceiling returns a
structured `resource_limit` error instead of a partial value. Symbol text,
sequence punctuation, and repeated structured value fields count against
`max_result_bytes`, preventing a long identifier from being amplified across a
serialized mathematical value. Sum and product reduction streams through a
logarithmic set of balanced partial results. A sequence must retain its ordered
elements, so their aggregate exact bits, symbolic nodes, and serialized value
bytes are checked as the sequence grows. Evaluation also has a derived
request-wide traversal budget of `64 * max_integer_iterations` node-work units. Substitution, term
evaluation, retained sequence values, nested operations, and balanced reduction
consume that budget and fail incrementally when it is exhausted.

Stateful machine requests also observe their request cancellation token between
terms. Cancellation returns the stable `cancelled` error and never installs a
partial definition or reports a partial scalar or sequence.

Human, JSON, persistent JSON Lines, and MCP calls all use this same evaluator.
Sums and products return the ordinary exact integer, rational, or symbolic
result shape. Sequences and recurrences return a human form such as `[1, 4, 9]`
and the structured `sequence` machine value described in
[the machine protocol](PROTOCOL.md#exact-sequences).

`sum`, `product`, `sequence`, and `recurrence` are built-in names, so
definitions and function parameters cannot redefine them. Iterator,
previous-value, and recurrence-index names must likewise be ordinary
non-built-in identifiers.
