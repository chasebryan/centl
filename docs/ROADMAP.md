# Roadmap

Each phase ends in a usable vertical slice. Later phases may refine syntax but
must preserve the numerical contract.

## Current release

`0.9.1` retains the `0.9.0` exact bounded sums, products, and polynomial
integration surface while making the x86_64 native packages portable across
baseline processors. Unsupported integrals remain visible.

## Current development

The source tree is preparing `0.10.0`; the published runtime and protocol
producer version remain `0.9.1` until a release is intentionally cut. The
development slice adds exact finite sequences and first-order bounded
recurrences, multiline human input, source-context diagnostics, interactive
completion and process-local history, a stack-safe renderer, and focused
pull-request validation. Protocol version 1 remains stable while gaining the
exact `sequence` value kind.

## 0. Foundation

- Record the architecture, numerical contract, and trust boundary.
- Install and pin F*, OCaml, Z3, FLINT, Julia, and Nemo.
- Establish build, verification, formatting, and test commands.
- Create the planned source layout without premature abstraction.

Exit condition: every toolchain component passes a minimal independent smoke
test on the development machine.

## 1. Verified exact calculator

- Define source spans, tokens, AST nodes, and result types in F*.
- Parse integers, finite decimals, fractions, parentheses, and basic operators.
- Implement normalized unbounded rational arithmetic.
- Prove decimal parsing and rational normalization properties.
- Extract the core to OCaml and provide a minimal REPL.
- Emit both human output and versioned JSON results.

Exit condition: expressions such as `0.1 + 0.2` and `1/3 + 1/6` evaluate and
render exactly from both the REPL and machine interface.

## 2. Symbolic calculus and algebra foundation

- Add names, integer powers, and unary mathematical functions.
- Preserve exact symbolic expressions beside exact rational values.
- Add exact substitution and differentiation rules.
- Simplify neutral arithmetic while retaining unresolved formal derivatives.
- Derive plain, colored, and machine output from the same result tree.
- Add canonical exact univariate polynomials, bounded expansion, initial
  factoring, and explicit local assumptions.
- Solve exact linear equations and rational-root quadratics with explicit
  finite, empty, universal, and unresolved results.
- Extend verification from totality and rational invariants to semantic
  differentiation theorems.

Exit condition: expressions such as `diff(x^3 + 2*x + 1, x)` and
`substitute(x^2 + 1, x = 3)` return exact results through both interfaces.

## 3. Rigorous approximation

Initial vertical slice implemented in `0.4.0-dev`.

- Introduce the native binding with a deliberately small C interface.
- Add Arb constants, square roots, and one transcendental operation.
- Extend the same boundary to trigonometric, inverse-trigonometric, hyperbolic,
  exponential, and logarithmic functions.
- Transfer balls as exact dyadic components.
- Validate backend representations in F*.
- Implement precision escalation and explicit resource limits.
- Prove the first justified-decimal rendering theorem.

Exit condition: CENTL either returns the requested justified digits for values
such as `sqrt(2)` and `sin(2016.1)`, or explains precisely why it cannot.

## 4. Calculator language

Initial immutable value and function definitions implemented in `0.5.0-dev`.

- Add reusable definitions, user functions, and saved scripts gradually.
- Interactive completion, bounded process-local history, syntax-aware
  multiline input, and source-context mathematical diagnostics are implemented
  in the current development tree. Durable history across calculator processes
  remains follow-up work.
- Preserve calculator behavior for every expression accepted in a script.
- Add exact symbolic evaluation through Calcium where it improves the result.

Exit condition: useful numerical scripts require no imports, entry point, or
type declarations, while errors remain mathematical and local.

## 5. Machine tool

Initial persistent JSON Lines and stdio MCP slice implemented in `0.8.0`.

- Preserve the versioned exact, enclosure, solution, definition, and error
  schemas.
- Keep request identifiers, session state, reset, capability discovery, and
  deterministic limits stable.
- Structured provenance and request-scoped cooperative cancellation are
  implemented without changing mathematical semantics; retain them as new
  result kinds and backends are added.
- Keep MCP as a thin adapter over the same evaluator and result objects.

Exit condition: an AI system can call CENTL repeatedly without parsing terminal
text or mistaking an approximation for an exact result.

## 6. Mathematical breadth

- Exact bounded `sum(expression, variable = lower, upper)` and
  `product(expression, variable = lower, upper)` are implemented with lexical
  iterator scope, nested request-wide limits, and cooperative cancellation.
- Exact `integrate(p, x)` and `integrate(p, x = a, b)` for
  rational-coefficient univariate polynomials are implemented in `0.9.0`; the
  indefinite form chooses integration constant zero and unsupported cases stay
  explicit.
- Exact bounded `sequence(expression, variable = lower, upper)` and first-order
  `recurrence(initial, previous = step, index = lower, upper)` are implemented
  in the current development tree with lexical scope, structured exact sequence
  values, aggregate result limits, and cooperative cancellation.
- Add complex enclosures, algebraic numbers, polynomials, and matrices.
- Add generating functions, limits, series, rigorous integration outside the
  exact polynomial domain, and broader partial symbolic integration with
  explicit unevaluated results.
- Add vector calculus, differential equations, transforms, probability, and
  statistics as bounded mathematical domains.
- Grow exact geometry and concrete mathematics from the initial formula,
  combinatorics, GCD/LCM, and Fibonacci primitives.
- Evaluate number-theoretic operations through narrow backend modules.
- Use Julia/Nemo to prototype and independently test each new domain.
- Extend the exactness and approximation rules before extending syntax.

Exit condition: every new domain has a documented value model, trust boundary,
machine schema, and differential test suite.

## 7. Hardening and release

- Pull-request verification now runs the pinned F*, OCaml, native, quality, and
  seeded Julia/Nemo path without invoking all-platform packaging. Full package
  jobs remain on `main`, tags, and manual runs, and the x86_64 release smoke
  exercises large exact GMP arithmetic under an emulated Core 2 CPU.
- Exact and symbolic rendering now uses an explicit traversal stack, iterative
  size preflight, bounded buffers, and adversarial depth, allocation, and
  cancellation tests.
- Fuzz source parsing and native boundaries.
- Add algebraic-identity, monotonicity, containment, and metamorphic tests.
- Compare difficult cases against independent Julia/Nemo evaluations.
- Produce reproducible native release bundles and dependency notices.
- Publish native Linux, macOS, and Windows packages, with x86_64 and Arm targets
  where their upstream numerical dependencies support them.
- Test every package on a clean native runner against the same language and
  numerical conformance suite.
- Audit resource exhaustion, cancellation, and hostile machine requests.

Exit condition: the release process reproduces verified binaries and publishes
the exact toolchain, numerical backend, and remaining trust assumptions.
