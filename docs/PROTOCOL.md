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

Failures have stable codes and mathematical messages:

```json
{"version":1,"ok":false,"error":{"code":"division_by_zero","message":"division by zero"}}
```

Syntax errors also contain a zero-based byte `position`. Version 1 error codes
are `syntax_error`, `division_by_zero`, `zero_denominator`, `invalid_request`,
and `core_contract_violation`.

Run persistent machine mode with:

```sh
./centl --json
```

For a single expression, `./centl --json '1/8'` emits the same response schema
without requiring a JSON request wrapper.
