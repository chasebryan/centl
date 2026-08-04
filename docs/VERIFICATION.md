# Verification boundary

The current F* core proves:

- the Euclidean algorithm returns a greatest common divisor of its inputs;
- normalized rationals have a positive denominator;
- normalization preserves the represented mathematical value;
- addition, subtraction, multiplication, negation, and successful division
  implement their exact rational semantics;
- exact rational powers preserve rational invariants;
- division by zero is a structured result; and
- every successful evaluator result satisfies the rational invariant;
- symbolic differentiation agrees with independently defined tangent
  semantics for the supported univariate integer-polynomial domain;
- exact rational-coefficient polynomial integration constructs zero-constant
  coefficient lists, and independently defined coefficient differentiation
  recovers the source coefficients up to exact rational equivalence; and
- dyadic intervals are rounded outward to exact decimal scales.

The core also validates native real enclosures before use: the lower endpoint
must not exceed the upper endpoint, and the shared binary exponent must remain
within the configured boundary. The bounded `round_enclosure_outward` entry
point then computes the floor of the lower endpoint and ceiling of the upper
endpoint at a requested power-of-ten scale. Its postcondition proves both
endpoint inequalities using exact integer arithmetic, including for negative
values. Exact rational square-root candidates are computed by the host but
accepted only after the F* core checks, by direct integer equality, that the
candidate squares to the radicand.

The F* symbolic evaluator, substitution pass, differentiation pass, and exact
polynomial-integration helpers are total and extract with no admits.
Differentiation correctness is stated over a separate polynomial model
containing integer constants, one distinguished variable, negation, addition,
subtraction, multiplication, and natural powers.
Ordinary evaluation and dual-number tangent evaluation are defined
independently. `polynomial_differentiation_is_semantic` proves that evaluating
the production differentiator's output returns that tangent at every integer
point. A checked cubic witness demonstrates that this domain is inhabited.

Substitution is simultaneous: one replacement is never rewritten by another
replacement from the same operation. It is also capture-avoiding across every
expression-level binder. The iterator variable in four-argument `sum`,
`product`, and `sequence` forms scopes only the body, so a matching substitution
does not enter the body or replace the binder, while both bounds still receive
substitutions. In six-argument `recurrence`, the previous-value and index names
both scope only the step; the initial expression and both bounds remain outside
their scope. The integration variable similarly scopes only its integrand;
definite integration bounds remain outside that scope. The variable in
`substitute(inner, variable = replacement)` scopes only `inner`; the
replacement remains outside that scope. Differentiation and residual-derivative
variables scope their inner expressions, and a `solve` variable scopes both
equation sides.

When a replacement contains a free occurrence of a binder name, the core
alpha-renames that binder before entering its scope. Fresh names use ordinary
parser identifier syntax and are checked against the scoped term, substitution
names, and replacement expressions. A structurally bounded suffix search skips
preoccupied candidates, allowing an alpha-renamed symbolic definition to
survive rendering and parsing without capture. A recurrence may alpha-rename
either or both step binders. Checked F* witnesses cover direct iteration,
sequence, and two-binder recurrence capture as well as an already occupied
initial candidate; native substitution and session regressions exercise the
same scope behavior after extraction.

Finite range enumeration, recurrence stepping, and the exact-sequence container
remain in the OCaml host. Each produced element is nevertheless evaluated by
the extracted exact core. The host enforces request-wide element and traversal
budgets plus aggregate exact-bit, symbolic-node, and rendered-byte ceilings as
the result grows, and checks cancellation between terms. This boundary returns
a structured failure rather than a partial sequence and is covered by exact,
scope, empty-range, limit, cancellation, protocol, and MCP tests.

Exact polynomial addition, negation, subtraction, scaling, multiplication,
bounded powers, coefficient collection, rendering, and the conservative
assumption simplifier are also total F* definitions. Generated expansion,
collection, and cubic-derivative identities are checked after exact
substitution against independently computed integer results.

CENTL 0.9.0 extends that exact polynomial model with coefficient-wise
antiderivatives. Each coefficient division is exact rational arithmetic, and
the chosen constant term is zero.
`polynomial_derivative_of_antiderivative_correct` proves the coefficient-list
round trip up to exact rational equivalence; the public expression path is
covered by concrete F* witnesses and native regression tests, not by a stronger
production-differentiator equivalence theorem. Definite integration at exact
rational bounds evaluates the same coefficient list twice with Horner's method
and subtracts, without introducing a numerical backend. Inputs outside the
accepted univariate polynomial domain remain explicit `integrate(...)`
expressions.

Exact equation classification is also in F*. The core reduces both sides to a
univariate rational polynomial, distinguishes constant, linear, quadratic, and
unsupported cases, and computes linear and repeated quadratic roots exactly.
For a positive quadratic discriminant, the host proposes an integer square-root
candidate; the core checks the exact square identity before computing both
rational roots.

Exact rational powers use verified exponentiation by squaring rather than a
linear recursive multiplication chain.

Verification runs with no admitted SMT queries:

```sh
make verify
```

F* extracts the verified definitions to OCaml. A small local extraction runtime
maps F* integers directly to Zarith arbitrary-precision integers. The generated
OCaml snapshot is versioned so ordinary opam/Dune package builds do not need F*;
verification CI regenerates it with the pinned verifier and rejects any diff.

The current trusted application boundary still includes the handwritten OCaml
lexer/parser, exact finite-iteration driver and sequence container, terminal
and JSON code, Zarith, the F*/OCaml extraction process, the OCaml compiler, Z3,
the narrow C shim, FLINT/Arb, MPFR, and GMP. Tests attack that boundary with
golden CLI cases, direct enclosure-containment checks, and thousands of
generated exact identities checked against independent Zarith computations.
The result renderer uses an explicit traversal stack, iterative size preflight,
and a bounded buffer; adversarial tests cover deep symbolic trees, allocation
scaling, cancellation, and agreement among plain, colored, JSON, and MCP views.

The host validates that every core result is reduced and has a positive
denominator before rendering it. It never repairs or silently approximates a
core result.
