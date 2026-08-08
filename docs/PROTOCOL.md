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
defaults to the compatibility operation `evaluate`. Stateless `--json` accepts
evaluation requests (with or without an explicit `op: "evaluate"`); the
persistent `--serve` mode separates read-only computation from mutation and
also provides the control operations below:

```json
{"version":1,"id":1,"op":"compute","expression":"1 + 1"}
{"version":1,"id":2,"op":"define","expression":"r = 3"}
{"version":1,"id":3,"op":"evaluate","expression":"legacy = 4"}
{"version":1,"id":4,"op":"reset"}
{"version":1,"id":5,"op":"describe"}
{"version":1,"id":6,"op":"session"}
{"version":1,"id":7,"op":"help","query":"factor"}
{"version":1,"id":8,"op":"ping"}
{"version":1,"id":"stop-17","op":"cancel","target":"job-17"}
```

`compute` accepts expressions, may read existing definitions, and never mutates
the session; a definition returns `definition_not_allowed`. `define` accepts
only an immutable value or function definition; an ordinary expression returns
`definition_required`. `evaluate` retains the earlier combined behavior for
existing clients. New automated callers should use `compute` and `define`.

`describe` publishes resolution statuses, supported mathematical domains with
examples, cancellation behavior, and active limits. `session` returns every
immutable definition in creation order with its canonical expression and
direct definition dependencies. `help` searches the canonical syntax catalog;
its optional `query` matches section names, forms, meanings, and examples.

Successful and failed responses report the current definition and request
counts:

```json
{"version":1,"id":"job-17","ok":true,"value":{"kind":"rational","exact":true,"numerator":"3","denominator":"10","text":"3/10"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":1}}
```

Definitions use the same calculator syntax and remain immutable:

```json
{"version":1,"id":1,"expression":"f(x) = x^2 + 1"}
```

```json
{"version":1,"id":1,"ok":true,"value":{"kind":"definition","exact":true,"definition_kind":"function","name":"f","parameters":["x"],"expression":"x^2 + 1","text":"f(x) = x^2 + 1"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_definition","method":"session_binding","backend":"centl-session"},"session":{"definitions":1,"requests":1}}
```

## Limits

The server has deterministic ceilings:

- 65,536 bytes per JSON request
- 10,000 requests per process
- 32,768 source bytes per expression
- 100,000 expression nodes during session expansion and resolution; the same
  ceiling bounds estimated symbolic-transformation work before it begins
- 1,000,000 aggregate bits per exact result, enforced by conservative
  preflight profiles and an actual-result check before output
- 100,000 request-wide integer iterations for concrete-mathematics operations;
  nested sums, products, sequences, and recurrences draw from the same
  aggregate budget
- 1,048,576 serialized mathematical-value bytes, including repeated structured
  fields such as `text`, plus retained session-value bytes
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

The same field bounds the number of elements retained by a sequence or
recurrence, including a recurrence's initial lower-index element:

```json
{"version":1,"expression":"recurrence(1, a = a*n, n = 0, 20)","limits":{"max_integer_iterations":21}}
```

Available fields are `max_source_bytes`, `max_expression_nodes`,
`max_exact_bits`, `max_integer_iterations`, `max_result_bytes`, `max_bindings`,
`max_precision_digits`, and `max_working_bits`. `describe` returns the active
process ceilings. Exhaustion is a normal structured failure with code
`resource_limit`, `precision_limit`, or `insufficient_precision`.

Finite iteration additionally derives a traversal ceiling of 64 node-work
units per allowed integer iteration. This bounds repeated substitution,
evaluation, retained sequence values, and balanced reduction even when every
individual term fits the node ceiling. Live partial reductions and the
aggregate elements of a sequence remain under their applicable expression,
exact-bit, and result-byte ceilings.

The session applies the node, exact-bit, and result-byte ceilings in aggregate
before every immutable definition commit. Filling binding slots therefore
cannot multiply the per-expression retention allowance. Result-byte estimation
includes symbol and function-name text, structured value fields, sequence
items, condition text, and definition names, parameters, and bodies, and runs
before human or JSON rendering. Transport
metadata such as provenance, session counters, JSON-RPC wrappers, and echoed
request IDs is not charged to `max_result_bytes`; it remains bounded by the
separate per-request input and process limits.

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
{"version":1,"id":"stop-17","ok":true,"cancellation":{"target":"job-17","status":"requested"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"control","method":"cancel","backend":"centl-protocol"},"session":{"definitions":0,"requests":1}}
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

The reader retains at most `max_requests` ordinary pending inputs and at most
16 MiB of their source bytes. The byte ceiling is derived as 256 times the
65,536-byte per-request ceiling, so small valid bursts can still reach the
advertised 10,000-request process limit. If ordinary count or bytes are already
full, one valid cancellation operation may occupy a separately accounted
emergency slot; its own input remains bounded by the 65,536-byte request limit.
There is never more than one pending emergency slot.

If a producer exceeds a queue ceiling without qualifying for that slot, or
while the slot is occupied, CENTL cancels active and queued cancellable
evaluations, appends one ordered `resource_limit` response for the overflowing
input, stops reading, drains the bounded queue, and exits with a failure status.
Thus even the terminal state retains at most the ordinary queue, one emergency
cancellation, and one zero-byte-accounted overload marker. This policy prevents
both unbounded memory growth and a saturated queue from starving cancellation.
Clients should use normal pipe backpressure instead of sending unbounded
large-request bursts.

Cancellation is best effort at explicit evaluator checkpoints: source parsing,
session expansion, symbolic traversal and transformation, approximation retry,
and immediately before a session mutation. A native backend call already in
progress completes before the next checkpoint. Process termination remains the
immediate fallback for a caller whose external deadline expires.

## Provenance

Every mathematical success, unresolved result, definition, failure, and
protocol control result has top-level structured `provenance`. `classification`
distinguishes `exact`, `exact_symbolic`, `exact_sequence`,
`exact_solution_set`, `rigorous_enclosure`, `unresolved`, `exact_definition`,
`failure`, `cancelled`, and `control`. `method` describes how CENTL produced the
result, while `backend` identifies the responsible evaluation boundary.
`producer` records the CENTL version and `schema` versions the provenance
object independently of protocol version 1.

## Transformation resolution

Every successful evaluation has a top-level `resolution` object. It is
orthogonal to `value.exact` and provenance: exactness describes the returned
value, while resolution describes whether CENTL completed the operation the
caller requested.

`status` is one of:

- `computed`: ordinary evaluation completed without a symbolic transformation
- `transformed`: the requested transformation completed
- `unchanged_proved`: CENTL proved the input already has the requested form
- `residual`: the requested operation remains explicitly present in the value
- `unsupported`: the request is outside CENTL's implemented domain
- `indeterminate`: CENTL cannot justify a definite resolution

Transformation results also identify `operation` and `supported_domain`.
Non-complete and unchanged results include a stable `reason` code. For example:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"integrate(sin(x), x)","text":"integrate(sin(x), x)"},"resolution":{"status":"unsupported","operation":"integrate","reason":"non_polynomial_integrand","supported_domain":"rational-coefficient univariate polynomials with exact rational bounds"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}
```

This is a successful exact symbolic value, but not a completed integration.
Human output appends the same classification for `unchanged_proved`,
`residual`, `unsupported`, and `indeterminate` results. Errors remain errors
and do not carry `resolution`. Existing in-process callers can use the legacy
value-only evaluation functions; JSON, JSON Lines, and MCP always expose the
detailed result.

## Values

Integers use `kind: "integer"` and a decimal-string `value`. All unbounded
integers are strings so clients cannot lose precision through their JSON number
type.

An exact symbolic result uses canonical plain text:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"3 * x^2","text":"3 * x^2"},"resolution":{"status":"transformed","operation":"diff","supported_domain":"the documented exact symbolic differentiation rules"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}
```

Conditional symbolic results retain machine-readable conditions:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]},"resolution":{"status":"transformed","operation":"assuming","supported_domain":"exact expressions with retained conditions"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}
```

Relation codes are `equal`, `not_equal`, `less_than`, `less_or_equal`,
`greater_than`, and `greater_or_equal`.

### Exact sequences

`sequence(...)` and `recurrence(...)` return `kind: "sequence"`. `items` keeps
the ordered scalar values using the existing integer, rational, and symbolic
schemas, and `length` is a JSON integer bounded by the active iteration limit:

```json
{"version":1,"ok":true,"value":{"kind":"sequence","exact":true,"length":3,"items":[{"kind":"rational","exact":true,"numerator":"1","denominator":"2","text":"1/2"},{"kind":"integer","exact":true,"value":"1","text":"1"},{"kind":"rational","exact":true,"numerator":"3","denominator":"2","text":"3/2"}],"text":"[1/2, 1, 3/2]"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_sequence","method":"finite_iteration","backend":"centl-iteration"}}
```

Empty ranges have `length: 0`, `items: []`, and `text: "[]"`. Nested sequence
items and approximate or solution-set items are not accepted. Immutable value
definitions may retain a sequence, and user functions may return one, but a
sequence cannot be consumed where a scalar expression is required.

Equation solving returns a structured solution set. Rational parts remain
decimal strings:

```json
{"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"numerator":"-1","denominator":"1","text":"-1"},{"numerator":"1","denominator":"1","text":"1"}],"equation":{"left":"x^2 - 1","right":"0"},"text":"x in {-1, 1}"},"resolution":{"status":"transformed","operation":"solve","supported_domain":"linear and real quadratic equations with rational coefficients"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_solution_set","method":"equation_solving","backend":"centl-exact"}}
```

`status` is `finite`, `none`, `all`, or `unresolved`. An unresolved result is a
successful explicit classification with `resolved: false`.

Finite rational solutions retain the protocol's original untagged
`numerator`/`denominator`/`text` object. A real quadratic with a positive
nonsquare discriminant uses a tagged exact solution object instead:

```json
{"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"kind":"real_quadratic","exact":true,"branch":"lower","center":{"numerator":"0","denominator":"1"},"radicand":{"numerator":"2","denominator":"1"},"text":"-sqrt(2)"},{"kind":"real_quadratic","exact":true,"branch":"upper","center":{"numerator":"0","denominator":"1"},"radicand":{"numerator":"2","denominator":"1"},"text":"sqrt(2)"}],"equation":{"left":"x^2","right":"2"},"text":"x in {-sqrt(2), sqrt(2)}"},"resolution":{"status":"transformed","operation":"solve","supported_domain":"linear and real quadratic equations with rational coefficients"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"exact_solution_set","method":"verified_quadratic_solving","backend":"centl-core"}}
```

`branch` is `lower` for `center - sqrt(radicand)` and `upper` for
`center + sqrt(radicand)`. Both rational components are reduced with positive
denominators. The representation comes from `-b/(2a)` and
`discriminant/(4a^2)`, so multiplying an equation by a nonzero rational leaves
the structured roots unchanged. These objects are exact equation solutions,
not general scalar values; use `approx(...)` separately when a decimal
enclosure is required.

A rigorous approximation uses `kind: "real_enclosure"` and `exact: false`.
`dyadic` contains exact endpoints, `decimal` is an outward-rounded view, and
`precision` records actual backend work:

```json
{"version":1,"ok":true,"value":{"kind":"real_enclosure","exact":false,"text":"≈ [3.141592653, 3.141592654]","dyadic":{"lower_mantissa":"497805226624462170461043889243","upper_mantissa":"497805226624462170461043889245","binary_exponent":-97},"decimal":{"lower":"3.141592653","upper":"3.141592654","requested_significant_digits":10,"certified_significant_digits":10},"precision":{"working_bits":98,"backend":"flint-arb","rigorous":true}},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"rigorous_enclosure","method":"interval_evaluation","backend":"flint-arb"}}
```

## Errors

Failures have stable codes and mathematical messages:

```json
{"version":1,"ok":false,"error":{"suggestion":"Change the input or retain an explicit nonzero domain condition.","code":"division_by_zero","message":"division by zero","retryable":false},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"failure","method":"evaluation","backend":"centl-runtime"}}
```

Syntax errors and runtime mathematical failures that can be localized to source
also contain a legacy zero-based byte `position` and a structured zero-width
`range` with `start` and `end` byte offsets. Request/session-wide failures omit
both when no single source expression is responsible. Every error states
whether it is `retryable`; a `suggestion` is included when CENTL knows a useful
recovery. Limit failures additionally carry `details.category: "limit"` and the
specific configurable `details.limit` name when it can be identified. Version
1 error codes include
`syntax_error`, `division_by_zero`, `zero_denominator`,
`invalid_request`, `invalid_arguments`, `undefined_power`, `domain_error`,
`precision_limit`, `insufficient_precision`, `resource_limit`,
`unsupported_approximation`, `invalid_solution_variable`,
`solution_set_not_expression`, `approximation_not_expression`,
`definition_not_allowed`, `definition_required`,
`backend_failure`, and
`core_contract_violation`. Cooperative cancellation uses `cancelled`.
Finite-iteration bounds that are not exact integers use `invalid_arguments`;
malformed iteration syntax uses `syntax_error`; and exhausted range,
aggregate-iteration, expression-node, exact-bit, work, or result-byte budgets
use `resource_limit`. A non-scalar or inexact sequence term uses
`exact_sequence_required`, while trying to consume a completed sequence as a
scalar uses `sequence_not_expression`.

## Claim verification

Read-only structured claim checking ships in the 0.12.0 release candidate.
Protocol version remains 1; the `verify` operation is additive.

A protocol request names both sides and one of six relations:

```json
{"version":1,"id":9,"op":"verify","left":"0.1 + 0.2","relation":"equal","right":"3/10"}
```

A decisive exact result is explicit about its scope, method, assurance, values,
and the transformation resolution of each side:

```json
{"version":1,"id":9,"ok":true,"verification":{"schema":1,"verdict":"verified","scope":"closed_exact_rational","method":"closed_rational_comparison","claim":{"left":"0.1 + 0.2","relation":"equal","right":"3/10","variables":[],"assumptions":[]},"evidence":{"left":{"kind":"rational","text":"3/10","numerator":"3","denominator":"10"},"right":{"kind":"rational","text":"3/10","numerator":"3","denominator":"10"},"comparison":"equal","left_resolution":{"status":"computed"},"right_resolution":{"status":"computed"}},"assurance":{"class":"exact_algorithm"},"producer":{"name":"centl","version":"0.12.0-rc.1"}},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.12.0-rc.1"},"classification":"verification","method":"claim_verification","backend":"centl-verify"},"session":{"definitions":0,"requests":1}}
```

`relation` is `equal`, `not_equal`, `less_than`, `less_or_equal`,
`greater_than`, or `greater_or_equal`. Unknown request fields are rejected.
`variables` is an optional array of closed `{name, domain}` objects; the only
accepted domain is `rational`. `assumptions` is an optional string array.

The decisive scopes in this initial slice are:

| Scope | Decisive outcomes |
| --- | --- |
| `closed_exact_rational` | Both sides reduce to exact integers or rationals; all six relations are decided. |
| `closed_real_enclosure` | Disjoint rigorous enclosures decide order, inequalities, and non-equality. |
| `univariate_rational_polynomial` | One quantified rational variable. False equalities are `refuted` only with an exact rational counterexample (`witness_checked`). Zero-difference identities in the F*-admitted fragment are `verified` with `verified_core` assurance and the named soundness theorem. |

Real equality is not inferred from enclosures. Overlapping enclosures,
free-form assumptions, multi-variable claims, quantified order, polynomial
forms outside the F* admission function, and unquantified free symbols return `unknown` with a
stable reason. Invalid mathematical inputs return the `invalid` verdict.
Cancellation, resource or precision exhaustion, insufficient precision, and
backend failures remain protocol errors with `ok: false`; they are never
converted to `unknown`. A polynomial identity reports `verified_core` only
when `Centl.PolynomialSoundness.classify_polynomial_identity` admits it and
returns `VerifiedPolynomialIdentity`; host normalization alone is never decisive.
Counterexample refutations report `witness_checked`; closed exact rational
comparisons report `exact_algorithm`; enclosure order reports
`certified_enclosure`.

Enclosure evidence contains exact dyadic `lower_mantissa`,
`upper_mantissa`, and `binary_exponent` fields alongside outward-rounded
decimal bounds. Claims that read immutable session definitions report those
dependencies in their evidence. Verification does not add, replace, or remove
session bindings.

`centl verify ... --receipt FILE` writes one bounded replayable receipt.
`centl check FILE --receipt FILE` writes a collection containing one receipt
per assertion. Each receipt records the resolved claim, verdict evidence,
active limits, exact transitive session definitions, session revision,
protocol/receipt schema, and stamped build identity. Serialization is capped
at 1,048,576 bytes and the destination is replaced atomically.

Unlike ordinary evaluation's mathematical-value limit, verification applies
`max_result_bytes` to the complete protocol response, including the echoed
claim, evidence, provenance, and session counters.

The same operation is exposed as MCP tool `centl_verify` and through:

```sh
centl verify --left '0.1 + 0.2' --relation equal --right '3/10' --receipt claim.json
centl check path/to/contracts.centl --receipt contracts.json
```

`centl verify` exits 0 for `verified`, 1 for `refuted`, `unknown`, or
`invalid`, and 2 for malformed input or an operational error. `centl check`
uses the same classification across the whole file: any malformed or
operational line makes the process exit 2; otherwise any non-verified
assertion makes it exit 1.

Contract files are line-oriented. Blank lines and lines beginning with `#`
are ignored:

```text
equal | 0.1 + 0.2 | 3/10
define | r = 3
equal | r^2 | 9
less_than | sqrt(2) | 2
```

Definitions mutate only the private session created for that one `centl check`
process. A fourth assertion field such as `x:rational` selects the univariate
rational polynomial method for equality claims.

Calculator scripts may also write:

```text
assert(0.1 + 0.2 = 3/10)
assert((x + 1)^2 = x^2 + 2*x + 1, for_all = x, domain = rational)
```
