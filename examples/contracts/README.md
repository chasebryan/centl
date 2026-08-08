# Math contract examples

These files are checked with:

```sh
centl check examples/contracts/math-contracts.centl
centl check examples/contracts/pending-polynomials.centl
```

## Format

Blank lines and `#` comments are ignored. Each remaining line is either:

```text
RELATION | LEFT | RIGHT
RELATION | LEFT | RIGHT | variable:rational
define | NAME = EXPRESSION
define | NAME(args) = EXPRESSION
```

`RELATION` is one of `equal`, `not_equal`, `less_than`, `less_or_equal`,
`greater_than`, or `greater_or_equal`.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | every assertion verified |
| 1 | at least one assertion was refuted, unknown, or invalid |
| 2 | malformed file, operational error, or resource limit |

Strict CI should treat only exit 0 as success.

`math-contracts.centl` contains only claims expected to verify and exits 0.
`pending-polynomials.centl` contains identities that return `unknown` while
the F* zero-difference soundness theorem remains unfinished, so it exits 1.
