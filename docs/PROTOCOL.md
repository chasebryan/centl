# Machine protocol

CENTL protocol version 1 is newline-delimited JSON over standard input and
output. Every request and response occupies one line and contains no terminal
color codes.

Use the smallest mode that fits:

```sh
centl --json '1/8'   # one expression
centl --json         # independent JSON requests
centl --serve        # persistent definitions and request IDs
```

`--json` remains stateless for compatibility. `--serve` owns one isolated
session until standard input closes or the process exits.

## Requests

An evaluation request is:

```json
{"version":1,"id":"job-17","expression":"0.1 + 0.2"}
```

`id` is optional, may be a string or integer, and is echoed unchanged. `op`
defaults to `evaluate`. The operations are:

```json
{"version":1,"id":1,"op":"evaluate","expression":"r = 3"}
{"version":1,"id":2,"op":"reset"}
{"version":1,"id":3,"op":"describe"}
{"version":1,"id":4,"op":"ping"}
{"version":1,"id":"stop-17","op":"cancel","target":"job-17"}
```

Successful and failed responses report the current definition and request
counts:

```json
{"version":1,"id":"job-17","ok":true,"value":{"kind":"rational","exact":true,"numerator":"3","denominator":"10","text":"3/10"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":1}}
```

Definitions use the same calculator syntax and remain immutable:

```json
{"version":1,"id":1,"expression":"f(x) = x^2 + 1"}
```

```json
{"version":1,"id":1,"ok":true,"value":{"kind":"definition","exact":true,"definition_kind":"function","name":"f","parameters":["x"],"expression":"x^2 + 1","text":"f(x) = x^2 + 1"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_definition","method":"session_binding","backend":"centl-session"},"session":{"definitions":1,"requests":1}}
```

## Limits

The server has deterministic ceilings:

- 65,536 bytes per JSON request
- 10,000 requests per process
- 32,768 source bytes per expression
- 100,000 expression nodes during session expansion and resolution; the same
  ceiling bounds estimated symbolic-transformation work before it begins
- 1,000,000 estimated bits per exact result
- 100,000 request-wide integer iterations for concrete-mathematics operations;
  nested finite sums and products draw from the same aggregate budget
- 1,048,576 rendered result bytes and retained session-text bytes
- 1,024 immutable definitions per session
- 1,000 requested significant digits
- 16,384 Arb working bits

An evaluation request may lower, but never raise, its ceilings:

```json
{"version":1,"expression":"approx(pi, 50)","limits":{"max_precision_digits":50,"max_working_bits":4096}}
```

For example, a caller can bound a finite sum independently of the process
ceiling:

```json
{"version":1,"expression":"sum(k^2, k = 1, 100)","limits":{"max_integer_iterations":100}}
```

Available fields are `max_source_bytes`, `max_expression_nodes`,
`max_exact_bits`, `max_integer_iterations`, `max_result_bytes`, `max_bindings`,
`max_precision_digits`, and `max_working_bits`. `describe` returns the active
process ceilings. Exhaustion is a normal structured failure with code
`resource_limit`, `precision_limit`, or `insufficient_precision`.

Finite iteration additionally derives a traversal ceiling of 64 node-work
units per allowed integer iteration. This bounds repeated substitution,
evaluation, and balanced reduction even when every individual term fits the
node ceiling. Live partial reductions collectively remain under
`max_expression_nodes`.

The session applies the node, exact-bit, and result-byte ceilings in aggregate
before every immutable definition commit. Filling binding slots therefore
cannot multiply the per-expression retention allowance. Result-byte estimation
includes symbol and function-name text and runs before human or JSON rendering,
so iteration cannot amplify a long identifier into an oversized response.

These limits are deterministic work bounds, not elapsed-time promises. A
caller should still impose its own process timeout.

## Cancellation

`--serve` accepts request-scoped cooperative cancellation for an evaluation
that has a string or integer `id`:

```json
{"version":1,"id":"stop-17","op":"cancel","target":"job-17"}
```

The acknowledgement is ordered with normal session traffic:

```json
{"version":1,"id":"stop-17","ok":true,"cancellation":{"target":"job-17","status":"requested"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"control","method":"cancel","backend":"centl-protocol"},"session":{"definitions":0,"requests":1}}
```

Input is read independently from evaluation, so the cancellation signal can
mark an active request or a request waiting in the FIFO evaluation queue. If a
checkpoint observes the signal before completion, the target returns error code
`cancelled`; a definition that returns `cancelled` is not committed. A signal
that races with an already completed request may have no effect. Other
evaluations, definitions, reset operations, and their responses remain in input
order. Clients must not reuse an ID while a request with that ID may still be
outstanding.

Valid cancellation operations are an out-of-band control path: they remain
available after `max_requests` is reached and do not increment the request
counter. Malformed cancellation objects have no side effect and follow ordinary
admission and validation.

The reader retains at most `max_requests` pending inputs and at most 16 MiB of
their source bytes. The byte ceiling is derived as 256 times the 65,536-byte
per-request ceiling, so small valid bursts can still reach the advertised
10,000-request process limit. If a producer exceeds either queue ceiling before
the evaluator can drain it, CENTL cancels active and queued cancellable
evaluations, appends one ordered `resource_limit` response for the overflowing
input, stops reading, drains the bounded queue, and exits with a failure status.
This terminal overload policy prevents both unbounded memory growth and a
saturated queue from starving cancellation. Clients should use normal pipe
backpressure instead of sending unbounded large-request bursts.

Cancellation is best effort at explicit evaluator checkpoints: source parsing,
session expansion, symbolic traversal and transformation, approximation retry,
and immediately before a session mutation. A native backend call already in
progress completes before the next checkpoint. Process termination remains the
immediate fallback for a caller whose external deadline expires.

## Provenance

Every mathematical success, unresolved result, definition, failure, and
protocol control result has top-level structured `provenance`. `classification`
distinguishes `exact`, `exact_symbolic`, `exact_solution_set`,
`rigorous_enclosure`, `unresolved`, `exact_definition`, `failure`, `cancelled`,
and `control`. `method` describes how CENTL produced the result, while `backend`
identifies the responsible evaluation boundary. `producer` records the CENTL
version and `schema` versions the provenance object independently of protocol
version 1.

## Values

Integers use `kind: "integer"` and a decimal-string `value`. All unbounded
integers are strings so clients cannot lose precision through their JSON number
type.

An exact symbolic result uses canonical plain text:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"3 * x^2","text":"3 * x^2"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}
```

Conditional symbolic results retain machine-readable conditions:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}
```

Relation codes are `equal`, `not_equal`, `less_than`, `less_or_equal`,
`greater_than`, and `greater_or_equal`.

Equation solving returns a structured solution set. Rational parts remain
decimal strings:

```json
{"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"numerator":"-1","denominator":"1","text":"-1"},{"numerator":"1","denominator":"1","text":"1"}],"equation":{"left":"x^2 - 1","right":"0"},"text":"x in {-1, 1}"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_solution_set","method":"equation_solving","backend":"centl-exact"}}
```

`status` is `finite`, `none`, `all`, or `unresolved`. An unresolved result is a
successful explicit classification with `resolved: false`.

A rigorous approximation uses `kind: "real_enclosure"` and `exact: false`.
`dyadic` contains exact endpoints, `decimal` is an outward-rounded view, and
`precision` records actual backend work:

```json
{"version":1,"ok":true,"value":{"kind":"real_enclosure","exact":false,"text":"≈ [3.141592653, 3.141592654]","dyadic":{"lower_mantissa":"497805226624462170461043889243","upper_mantissa":"497805226624462170461043889245","binary_exponent":-97},"decimal":{"lower":"3.141592653","upper":"3.141592654","requested_significant_digits":10,"certified_significant_digits":10},"precision":{"working_bits":98,"backend":"flint-arb","rigorous":true}},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"rigorous_enclosure","method":"interval_evaluation","backend":"flint-arb"}}
```

## Errors

Failures have stable codes and mathematical messages:

```json
{"version":1,"ok":false,"error":{"code":"division_by_zero","message":"division by zero"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"}}
```

Syntax errors also contain a zero-based byte `position`. Version 1 error codes
include `syntax_error`, `division_by_zero`, `zero_denominator`,
`invalid_request`, `invalid_arguments`, `undefined_power`, `domain_error`,
`precision_limit`, `insufficient_precision`, `resource_limit`,
`unsupported_approximation`, `invalid_solution_variable`,
`solution_set_not_expression`, `backend_failure`, and
`core_contract_violation`. Cooperative cancellation uses `cancelled`.
Finite-iteration bounds that are not exact integers use `invalid_arguments`;
malformed iteration syntax uses `syntax_error`; and exhausted range,
aggregate-iteration, expression-node, or exact-bit budgets use `resource_limit`.
