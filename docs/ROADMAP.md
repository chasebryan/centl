# Roadmap

Each phase ends in a usable vertical slice. Later phases may refine syntax but
must preserve the numerical contract.

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
- Add completion, history, multiline input, and mathematical diagnostics.
- Preserve calculator behavior for every expression accepted in a script.
- Add exact symbolic evaluation through Calcium where it improves the result.

Exit condition: useful numerical scripts require no imports, entry point, or
type declarations, while errors remain mathematical and local.

## 5. Machine tool

- Stabilize a versioned JSON schema.
- Add batch and persistent-process modes.
- Make determinism, precision budgets, and resource limits explicit.
- Provide exact, enclosure, provenance, and error result schemas.
- Add an MCP or equivalent adapter without coupling it to the evaluator.

Exit condition: an AI system can call CENTL repeatedly without parsing terminal
text or mistaking an approximation for an exact result.

## 6. Mathematical breadth

- Add complex enclosures, algebraic numbers, polynomials, and matrices.
- Add limits, sequences, series, rigorous definite integration, and partial
  symbolic integration with explicit unevaluated results.
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

- Fuzz source parsing and native boundaries.
- Add algebraic-identity, monotonicity, containment, and metamorphic tests.
- Compare difficult cases against independent Julia/Nemo evaluations.
- Produce reproducible native release bundles and dependency notices.
- Audit resource exhaustion, cancellation, and hostile machine requests.

Exit condition: the release process reproduces verified binaries and publishes
the exact toolchain, numerical backend, and remaining trust assumptions.
