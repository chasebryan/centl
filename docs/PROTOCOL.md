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
```

Successful and failed responses report the current definition and request
counts:

```json
{"version":1,"id":"job-17","ok":true,"value":{"kind":"rational","exact":true,"numerator":"3","denominator":"10","text":"3/10"},"session":{"definitions":0,"requests":1}}
```

Definitions use the same calculator syntax and remain immutable:

```json
{"version":1,"id":1,"expression":"f(x) = x^2 + 1"}
```

```json
{"version":1,"id":1,"ok":true,"value":{"kind":"definition","exact":true,"definition_kind":"function","name":"f","parameters":["x"],"expression":"x^2 + 1","text":"f(x) = x^2 + 1"},"session":{"definitions":1,"requests":1}}
```

## Limits

The server has deterministic ceilings:

- 65,536 bytes per JSON request
- 10,000 requests per process
- 32,768 source bytes per expression
- 100,000 expression nodes during and after session expansion
- 1,000,000 estimated bits per exact result
- 100,000 integer iterations for concrete-mathematics operations
- 1,024 immutable definitions per session
- 1,000 requested significant digits
- 16,384 Arb working bits

An evaluation request may lower, but never raise, its ceilings:

```json
{"version":1,"expression":"approx(pi, 50)","limits":{"max_precision_digits":50,"max_working_bits":4096}}
```

Available fields are `max_source_bytes`, `max_expression_nodes`,
`max_exact_bits`, `max_integer_iterations`, `max_bindings`,
`max_precision_digits`, and `max_working_bits`. `describe` returns the active
process ceilings. Exhaustion is a normal structured failure with code
`resource_limit`, `precision_limit`, or `insufficient_precision`.

These limits are deterministic work bounds, not elapsed-time promises. A
caller should still impose its own process timeout and close standard input to
cancel outstanding work.

## Values

Integers use `kind: "integer"` and a decimal-string `value`. All unbounded
integers are strings so clients cannot lose precision through their JSON number
type.

An exact symbolic result uses canonical plain text:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"3 * x^2","text":"3 * x^2"}}
```

Conditional symbolic results retain machine-readable conditions:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]}}
```

Relation codes are `equal`, `not_equal`, `less_than`, `less_or_equal`,
`greater_than`, and `greater_or_equal`.

Equation solving returns a structured solution set. Rational parts remain
decimal strings:

```json
{"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"numerator":"-1","denominator":"1","text":"-1"},{"numerator":"1","denominator":"1","text":"1"}],"equation":{"left":"x^2 - 1","right":"0"},"text":"x in {-1, 1}"}}
```

`status` is `finite`, `none`, `all`, or `unresolved`. An unresolved result is a
successful explicit classification with `resolved: false`.

A rigorous approximation uses `kind: "real_enclosure"` and `exact: false`.
`dyadic` contains exact endpoints, `decimal` is an outward-rounded view, and
`precision` records actual backend work:

```json
{"version":1,"ok":true,"value":{"kind":"real_enclosure","exact":false,"text":"≈ [3.141592653, 3.141592654]","dyadic":{"lower_mantissa":"497805226624462170461043889243","upper_mantissa":"497805226624462170461043889245","binary_exponent":-97},"decimal":{"lower":"3.141592653","upper":"3.141592654","requested_significant_digits":10,"certified_significant_digits":10},"precision":{"working_bits":98,"backend":"flint-arb","rigorous":true}}}
```

## Errors

Failures have stable codes and mathematical messages:

```json
{"version":1,"ok":false,"error":{"code":"division_by_zero","message":"division by zero"}}
```

Syntax errors also contain a zero-based byte `position`. Version 1 error codes
include `syntax_error`, `division_by_zero`, `zero_denominator`,
`invalid_request`, `invalid_arguments`, `undefined_power`, `domain_error`,
`precision_limit`, `insufficient_precision`, `resource_limit`,
`unsupported_approximation`, `invalid_solution_variable`,
`solution_set_not_expression`, `backend_failure`, and
`core_contract_violation`.
