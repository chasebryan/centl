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

The F* symbolic evaluator, substitution pass, and differentiation pass are
total and extract with no admits. Semantic correctness theorems for the
differentiation rules are the next proof milestone. Until then, generated
polynomial identities are checked independently after exact substitution.

Verification runs with no admitted SMT queries:

```sh
make verify
```

F* extracts the verified definitions to OCaml. A small local extraction runtime
maps F* integers directly to Zarith arbitrary-precision integers.

The current trusted application boundary still includes the handwritten OCaml
lexer/parser, terminal and JSON code, Zarith, the F*/OCaml extraction process,
the OCaml compiler, and Z3. Tests attack that boundary with golden CLI cases and
thousands of generated fraction operations checked against Zarith's independent
rational implementation.

The host validates that every core result is reduced and has a positive
denominator before rendering it. It never repairs or silently approximates a
core result.
