# Machine protocol

CENTL's machine interface is newline-delimited JSON over standard input and
output. Each line is one independent request:

```json
{"version":1,"expression":"0.1 + 0.2"}
```

A successful exact rational response is:

```json
{"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"3","denominator":"10","text":"3/10"}}
```

Integers use `kind: "integer"` and a decimal-string `value`. All integers are
strings so clients cannot lose precision through their JSON number type.

An exact symbolic result uses canonical plain text and never contains terminal
color codes:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"3 * x^2","text":"3 * x^2"}}
```

Conditional symbolic results retain machine-readable conditions:

```json
{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]}}
```

Relation codes are `equal`, `not_equal`, `less_than`, `less_or_equal`,
`greater_than`, and `greater_or_equal`.

A rigorous approximation uses `kind: "real_enclosure"` and `exact: false`.
`dyadic` is the canonical enclosure: each endpoint is its signed mantissa times
two to `binary_exponent`. `decimal` is an outward-rounded view, and `precision`
records the actual backend and working precision.

```json
{"version":1,"ok":true,"value":{"kind":"real_enclosure","exact":false,"text":"≈ [3.141592653, 3.141592654]","dyadic":{"lower_mantissa":"497805226624462170461043889243","upper_mantissa":"497805226624462170461043889245","binary_exponent":-97},"decimal":{"lower":"3.141592653","upper":"3.141592654","requested_significant_digits":10,"certified_significant_digits":10},"precision":{"working_bits":98,"backend":"flint-arb","rigorous":true}}}
```

Failures have stable codes and mathematical messages:

```json
{"version":1,"ok":false,"error":{"code":"division_by_zero","message":"division by zero"}}
```

Syntax errors also contain a zero-based byte `position`. Version 1 error codes
include `syntax_error`, `division_by_zero`, `zero_denominator`,
`invalid_request`, `invalid_arguments`, `undefined_power`, `domain_error`,
`precision_limit`, `insufficient_precision`, `unsupported_approximation`,
`backend_failure`, and `core_contract_violation`.

Run persistent machine mode with:

```sh
./centl --json
```

For a single expression, `./centl --json '1/8'` emits the same response schema
without requiring a JSON request wrapper.
