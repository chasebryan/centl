# CENTL design

## Objective

CENTL is an exact-first calculator and numerical language for interactive work,
scripts, and machine tools. Its implementation must preserve a sharp boundary
between exact results, rigorous enclosures, and indeterminate results.

The implementation is intentionally polyglot. Each language has one bounded
role chosen for its strengths.

## Architecture

```text
terminal / script / JSON
          |
          v
      OCaml host
  I/O, REPL, limits, protocol
          |
          v
  extracted F* core
 parser, AST, exact semantics,
 precision policy, validation,
 rendering and proofs
          |
          v
   narrow OCaml/C boundary
          |
          v
 FLINT / Arb / Calcium
 balls, symbolic numbers,
 advanced numerical algorithms
```

Julia and Nemo form an independent laboratory for exploring algorithms,
generating adversarial cases, and checking production results. They are not a
runtime dependency of the shipped `centl` executable.

## Responsibilities

### F*

The F* core defines what CENTL means. It owns:

- lexical and syntactic structures;
- the typed AST and value classifications;
- exact integer, decimal, and rational semantics;
- transitions from exact computation to approximation;
- exact univariate polynomial normalization and bounded expansion;
- local mathematical conditions used to justify symbolic simplification;
- precision requests and retry decisions;
- validation of values returned across the numerical boundary;
- human and machine result construction;
- decimal rendering and its correctness properties.

Proofs are shipped beside the executable definitions and erased during OCaml
extraction. The extracted interface must accept and return simple, unrefined
boundary types whose invariants are checked at entry.

The initial slice begins its verified boundary at the AST. Its small
OCaml parser converts source literals directly to arbitrary-precision integer
pairs without passing through floating point. F* then evaluates and reduces the
result. Until parsing and result construction move into F*, the parser and
renderer remain explicit parts of the trusted boundary.

The `0.4.0-dev` slice adds a native Arb boundary. The host walks the resolved
AST, supplies exact rational inputs and a binary working precision, and receives
exact dyadic lower and upper endpoints. The F* core checks endpoint ordering and
the exponent budget before the host creates an outward-rounded decimal view.

### OCaml

OCaml is the application and extraction host. It owns:

- the executable entry point;
- terminal input, history, completion, and cancellation;
- file and script loading;
- time, memory, and precision budgets;
- JSON request and response transport;
- terminal-aware semantic coloration and plain-text fallback;
- coordination between the extracted core and numerical backend;
- native application packaging.

OCaml must not independently redefine CENTL arithmetic or rendering semantics.

### FLINT, Arb, and Calcium

The numerical backend owns algorithms that should not be reimplemented without
a compelling correctness or performance reason:

- arbitrary-precision real and complex ball arithmetic;
- elementary and special functions;
- algebraic and symbolic exact numbers;
- polynomials, matrices, number fields, and number-theoretic operations.

The binding surface is deliberately small. It exchanges tagged requests and
exact representations of results, never host-language floating-point values or
preformatted decimal answers.

### Julia and Nemo

The laboratory owns no production semantics. It is used to:

- prototype numerical operations;
- generate reference values and difficult inputs;
- compare independent evaluation paths;
- investigate precision growth and performance;
- reproduce suspected backend defects.

## Value model

CENTL has no general-purpose semantic `float` value.

```text
ExactInteger
ExactRational
ExactSymbolic
RealEnclosure
ComplexEnclosure
Indeterminate
```

Every result also carries provenance sufficient to explain whether it was
computed exactly, enclosed numerically, or left unresolved.

Conditions attached with `assuming` remain part of the symbolic result. A
simplifier may use a condition only for a rule it establishes directly, and the
condition remains visible in both human and machine output.

Approximate real values cross the backend boundary as exact dyadic data: signed
integer mantissas, binary exponents, and a nonnegative radius. Decimal strings
are created only after the F* core validates this representation.

## Evaluation

1. Parse source text into a checked AST.
2. Evaluate with exact values for as long as the operation permits.
3. Preserve a symbolic exact value when the backend can establish one.
4. Request a rigorous enclosure when approximation is explicit or necessary.
5. Increase working precision until the requested output contract is met, a
   resource limit is reached, or further refinement cannot decide the result.
6. Render only information justified by the exact value or full enclosure.

Predicates over enclosures are three-valued: certainly true, certainly false,
or unknown. Unknown is never silently treated as false.

## Human and machine interfaces

The human interface is calculator-first. A script is a saved sequence of the
same expressions accepted by the REPL.

The machine interface uses versioned JSON over standard input and output. It
returns structured exact values, enclosure endpoints, precision metadata,
stable error codes, and explanatory messages. Pretty terminal output is never
parsed by machine clients.

Terminal coloration is derived from typed result fragments: numbers, symbols,
functions, operators, and punctuation. ANSI codes are never stored in values or
emitted by the JSON interface, and color does not alter evaluation or canonical
plain text.

The same protocol may later be transported over JSON-RPC, MCP, or a local
service without changing the evaluator.

## Trust boundary

F* can prove properties of CENTL's own executable core, but it cannot prove an
external numerical library merely by calling it. The initial trusted base is:

- F*, its extraction process, and its selected Z3 version;
- the OCaml compiler and runtime;
- the narrow C binding;
- FLINT, Arb, Calcium, GMP, and MPFR;
- the platform compiler and linker.

CENTL reduces this risk with narrow interfaces, range and representation checks,
property testing, fuzzing, differential evaluation, and precision-independent
identities. Basic verified interval operations may later move into F* to shrink
the numerical trust boundary.

## Planned source layout

```text
src/fstar/       verified language core
src/ocaml/       executable host
src/native/      numerical binding shim
lab/julia/       independent Nemo experiments
tests/           golden, property, differential, and adversarial tests
docs/            design and user documentation
```

## Non-negotiable rules

- Decimal source literals never pass through binary machine floats.
- Approximation is visible in both source intent and result representation.
- Precision is a request and a verified outcome, not an unsupported promise.
- No layer may convert an enclosure to a point value silently.
- Resource exhaustion produces a structured indeterminate result.
- The human renderer and machine protocol are views of the same result object.
