# GitHub Copilot instructions for CENTL

## Project identity

CENTL is an exact-first, calculator-first numerical language implemented as a
verified F* core, an OCaml application, and narrow C bindings to FLINT/Arb.
Preserve its central promise: exact input stays exact whenever the result is in
the exact domain, approximation is explicit, and output never contains an
unjustified digit.

Before making a nontrivial change, read the relevant user contract and design
document under `docs/`. In particular, use:

- `docs/DESIGN.md` for architecture and layer ownership.
- `docs/VERIFICATION.md` for the proved/trusted boundary.
- `docs/NUMERICS.md` for exactness, enclosure, and rendering rules.
- `docs/SYNTAX.md` plus the topic-specific syntax document for language changes.
- `docs/PROTOCOL.md` and `docs/MCP.md` for machine-interface changes.
- `docs/PERFORMANCE.md` for resource and performance work.
- `CONTRIBUTING.md` and `toolchain.lock` for the build and pinned toolchain.

Treat the current working tree as user-owned. Inspect `git status` before
editing, preserve unrelated changes, and do not rewrite or delete files merely
to obtain a clean tree.

## Architecture and source ownership

Put behavior in the layer that owns it:

- `src/fstar/`: authoritative AST, exact semantics, symbolic transformations,
  boundary validation, proof-backed algorithms, and stated properties.
- `src/generated/`: checked-in OCaml extracted from F*. Never hand-edit these
  files. Change `src/fstar/`, run `make extract`, and commit the regenerated
  snapshot with the F* change.
- `src/runtime/`: the small F* extraction runtime.
- `src/ocaml/`: parsing and source locations, sessions, finite iteration,
  budgets, approximation retries, the shared host result union, rendering,
  cancellation, protocols, terminal behavior, history, and process
  orchestration. OCaml must not independently redefine arithmetic or repair an
  invalid core result; all public views must derive from the same typed result.
- `src/native/`: the narrow OCaml/C interface to FLINT/Arb. Exchange exact
  integers, rationals, and dyadic enclosure data, never host floats or formatted
  decimal answers.
- `lab/julia/`: independent Julia/Nemo experiments and differential oracles.
  This is not production runtime code and must not become a runtime dependency.
- `tests/`: Alcotest/QCheck tests, cram CLI tests, deterministic hardening tests,
  fixtures, and parser/protocol corpora.

When a change crosses layers, keep one semantic authority. For example, an
OCaml parser may construct the verified AST, but arithmetic and symbolic
meaning belong in F*. JSON, colored terminal output, and MCP must remain views
of the same evaluated result rather than separate evaluation paths.

## Non-negotiable correctness rules

- Never parse a decimal literal through `float`, C `double`, or any binary
  floating-point representation. Build arbitrary-precision numerator and
  denominator values directly.
- Use Zarith `Z.t` for unbounded integers in handwritten OCaml. Do not narrow an
  unbounded mathematical value to an OCaml `int` except after an explicit,
  justified bounds check.
- Normalize exact rationals and require a positive denominator. Reject invalid
  values at boundaries; do not silently repair them in the host.
- Do not silently turn a rigorous enclosure into a point value. Approximate
  results retain exact outward bounds, requested digits, and working precision.
- Decimal display must be derived by outward rounding of the complete validated
  enclosure. Never infer accuracy from a backend decimal string or from the
  number of digits it contains.
- Approximation must be visible in source intent, value classification,
  provenance, human text, and structured output.
- Preserve three-valued reasoning for enclosure predicates: true, false, or
  unknown. Never map unknown to false.
- Preserve mathematical domain conditions in symbolic results. Do not apply a
  simplification outside its valid domain or discard an `assuming` condition.
- Substitution is simultaneous and capture-avoiding. Respect the binder scopes
  documented in `docs/VERIFICATION.md`, including iteration, recurrence,
  integration, differentiation, substitution, and solve forms.
- Resource exhaustion, insufficient precision, cancellation, backend contract
  violations, and unsupported operations are structured outcomes. Do not
  fabricate a partial or approximate success.
- Do not introduce unbounded recursion or traversal over user-controlled input.
  Use explicit stacks, bounded work, or tail-recursive/iterative designs where
  input depth or size can be adversarial.

## Limits, state, and cancellation

Every new potentially expensive operation must participate in the applicable
request-wide budgets in `Centl_engine.evaluation_limits`: source bytes,
expression nodes/transformation work, exact-result bits, integer iterations,
result bytes, bindings, requested digits, and working bits. Check limits before
large allocation or work when possible and validate actual results before
returning them.

Session definitions are immutable and aggregate-retention limits apply across
the session. Preflight a definition, check cancellation immediately before the
commit, and do not mutate session state on error or cancellation.

Persistent JSONL and MCP evaluation is FIFO. The input reader may mark
cancellation but must not evaluate expressions or mutate bindings. Add
cooperative cancellation checkpoints around parsing, expansion, bounded loops,
symbolic work, approximation retries, and state commits. Preserve bounded queue
admission and the separately accounted emergency cancellation slot described in
`docs/PROTOCOL.md` and `docs/MCP.md`.

## Public behavior and compatibility

- Calculator, stdin, and file modes share syntax and multiline assembly.
- Human diagnostics use source name, one-based line/column presentation, and a
  caret excerpt; stable machine error positions are zero-based byte offsets.
  Keep source-location metadata beside the verified AST so it cannot affect
  semantics.
- Protocol version 1 and its error codes, value shapes, provenance, limits, and
  request-ID behavior are compatibility contracts. Make additive changes when
  possible and update all protocol views together.
- JSON unbounded integers remain decimal strings. Machine output never contains
  ANSI escape sequences and must not be produced by parsing pretty text.
- MCP uses the same stateful request engine as `--serve`. Keep text content and
  `structuredContent` mathematically consistent and follow notification rules,
  especially the absence of responses to cancellation notifications.
- Keep terminal color semantic-only; it must not alter canonical plain text.
- If syntax or behavior changes, update the applicable docs, `README.md`
  examples when user-visible, CLI/MCP/protocol tests, and `CHANGELOG.md` when the
  change is release-relevant. `docs/SYNTAX.md` is tested and must describe every
  implemented public form.

## Implementation conventions

- Follow `.ocamlformat` (`ocamlformat` 0.29.0, conventional profile). Use
  `Result` for expected failures and stable `{ code; message; position }`
  errors; do not raise exceptions for ordinary syntax, math, limit, or protocol
  failures.
- Match existing OCaml names and variants: `snake_case` values/functions,
  descriptive record fields, and explicit pattern matching. Avoid broad
  catch-all patterns when a new variant should force a compiler review.
- Keep pure mathematical helpers separate from I/O and mutation. Pass limits
  and cancellation hooks explicitly through user-controlled work.
- In C stubs, use the OCaml GC macros correctly (`CAMLparam`, `CAMLlocal`,
  `CAMLreturn`), validate all values before passing them to FLINT, release every
  initialized native object on every path, and keep precision/exponent checks at
  the native boundary. Never retain an unrooted OCaml value across allocation.
- Do not add an external dependency casually. Respect the exact versions in
  `centl.opam` and `toolchain.lock`; update pins, bootstrap checks, CI, and docs
  together when a dependency change is intentional.
- Do not edit version strings in isolation. Search for the current version and
  keep producer metadata, docs, packaging, fixtures, and changelog consistent.
- Prefer focused changes over opportunistic refactors. Comments should explain
  mathematical invariants, trust boundaries, non-obvious resource accounting,
  or protocol constraints—not restate the code.

## Tests and validation

Add regression coverage with each behavior change, including both success and
failure boundaries. Prefer the narrowest appropriate location:

- Extend `tests/test_centl.ml` for core engine, exact, symbolic, enclosure,
  session, limit, and rendering behavior.
- Use focused test modules such as `test_iteration.ml`, `test_sequence.ml`,
  `test_history.ml`, and `test_request_queue.ml` for their subsystems.
- Extend `tests/cli.t` for observable command-line behavior and JSON/MCP wire
  cases where already covered there.
- Add deterministic corpus, adversarial, metamorphic, sanitizer, performance,
  or Julia/Nemo cases when changing a security, numerical, native, or scaling
  boundary.
- For mathematical changes, test exact identities independently rather than
  only snapshotting formatted output. Include zero, signs, empty/boundary
  ranges, large values, malformed inputs, resource limits, and cancellation as
  applicable.
- Verify agreement among plain, colored, JSON, and MCP views when result
  rendering or structured values change.

Run validation proportional to the change:

```sh
# Fast handwritten/native loop; uses the checked-in generated core
make native-build
make native-test

# Formatting and static/package/toolchain checks (does not rewrite files)
make quality

# Apply formatting only when intentionally requested
make format-fix

# Required complete path for F* or verified-semantics changes
make test

# Additional boundary suites as relevant
make fuzz-test
make metamorphic-test
make sanitizer-test
make performance-test
make differential-test
```

`make test` runs F* verification and extraction before native tests and requires
the pinned F*/Z3 toolchain. After an F* change, ensure `make extract` succeeds
and `git diff -- src/generated` contains only the expected regenerated output.
Use `make native-test` for an iteration when F* is unchanged. Run
`make differential-test` before completing mathematical algorithm changes; it
requires the checked-in Julia environment and a built CENTL executable.

Report the exact commands run and any checks not run because a pinned tool or
system library is unavailable. Do not claim verification based solely on a
successful build.
