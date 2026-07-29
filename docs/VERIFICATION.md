# Verification boundary

The current F* core proves:

- the Euclidean algorithm returns a greatest common divisor of its inputs;
- normalized rationals have a positive denominator;
- normalization preserves the represented mathematical value;
- addition, subtraction, multiplication, negation, and successful division
  implement their exact rational semantics;
- exact rational powers preserve rational invariants;
- division by zero is a structured result; and
- every successful evaluator result satisfies the rational invariant.

The core also validates native real enclosures before use: the lower endpoint
must not exceed the upper endpoint, and the shared binary exponent must remain
within the configured boundary. Exact rational square-root candidates are
computed by the host but accepted only after the F* core checks, by direct
integer equality, that the candidate squares to the radicand.

The F* symbolic evaluator, substitution pass, and differentiation pass are
total and extract with no admits. Semantic correctness theorems for the
differentiation rules are the next proof milestone. Until then, generated
polynomial identities are checked independently after exact substitution.

Exact polynomial addition, negation, subtraction, scaling, multiplication,
bounded powers, coefficient collection, rendering, and the conservative
assumption simplifier are also total F* definitions. Generated expansion,
collection, and cubic-derivative identities are checked after exact
substitution against independently computed integer results.

Exact rational powers use verified exponentiation by squaring rather than a
linear recursive multiplication chain.

Verification runs with no admitted SMT queries:

```sh
make verify
```

F* extracts the verified definitions to OCaml. A small local extraction runtime
maps F* integers directly to Zarith arbitrary-precision integers.

The current trusted application boundary still includes the handwritten OCaml
lexer/parser, terminal and JSON code, Zarith, the F*/OCaml extraction process,
the OCaml compiler, Z3, the narrow C shim, FLINT/Arb, MPFR, and GMP. Tests attack
that boundary with golden CLI cases, direct enclosure-containment checks, and
thousands of generated exact identities checked against independent Zarith
computations.

The host validates that every core result is reduced and has a positive
denominator before rendering it. It never repairs or silently approximates a
core result.
