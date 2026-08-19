# CENTL Mathematics Implementation Standard

Status: mandatory admission standard for new mathematical capabilities.

This document defines when a new mathematical feature is allowed to move from
`[ ]` to `[x]` in
[MATHEMATICS-CAPABILITY-TODO.md](MATHEMATICS-CAPABILITY-TODO.md).

The standard exists to prevent breadth from eroding CENTL's central promise:
**never manufacture mathematical certainty.** A capability that cannot yet meet
this standard remains unsupported or explicitly experimental.

## 1. Independent implementation

CENTL may use public mathematical literature, public standards, public benchmark
documentation, and independently written test cases to understand the expected
mathematical problem class.

CENTL must not depend on proprietary source code, copied proprietary
implementation details, or undocumented behavior from another computer-algebra
system. Compatibility is not the goal. Mathematical correctness and a coherent
CENTL-native contract are the goal.

## 2. Mathematical contract before code

Every feature starts with a short written contract that states:

1. the mathematical object being represented or operation being performed;
2. the admitted input domain;
3. the exact output/value model;
4. assumptions and branch conventions;
5. mathematically invalid inputs;
6. supported-but-unresolved cases;
7. explicit non-goals;
8. the conditions under which CENTL may claim the result is exact, certified,
   approximate, heuristic, or unknown.

If the contract cannot be written precisely, implementation does not begin.

## 3. Result classification is mandatory

Every successful result must fit a declared semantic class. The core classes are:

- **exact:** the returned representation denotes the mathematical value exactly;
- **symbolic exact:** an unreduced symbolic object denotes the exact value or
  relation without claiming canonical closed form;
- **algebraic exact:** the value is represented by an exact polynomial/root
  object plus sufficient isolation or identity data;
- **rigorous enclosure:** the returned set is proven to contain the mathematical
  value;
- **certified:** a predicate, witness, or certificate has been mechanically
  checked under a stated contract;
- **statistical:** the result has declared probabilistic/model assumptions and
  must not be described as mathematical certainty;
- **heuristic:** a deliberately non-certifying result whose limitations are
  machine-visible;
- **unknown / unsupported:** CENTL refuses to infer a result it cannot justify.

A new feature may introduce a new class only by extending the machine schemas and
this standard deliberately.

## 4. Exact-first evaluation

Exact input must remain exact whenever the admitted mathematical result can be
represented exactly by CENTL.

An implementation must not fall back to floating point merely because exact
work is expensive. It may instead:

- return a residual symbolic expression;
- return an explicit resource-limit result;
- require an explicit approximation request;
- use a rigorous enclosure when approximation is part of the feature contract.

Binary floating-point approximations are never allowed to masquerade as exact
constants, exact roots, exact angles, exact probabilities, exact invariants, or
exact equality decisions.

## 5. Irrational and transcendental values

CENTL preserves structure before printing decimals.

Examples of acceptable exact representations include:

- `sqrt(2)`;
- a canonical algebraic root object with an isolating interval;
- `acos(5/6)`;
- a symbolic special-function value;
- a conditional/piecewise expression with explicit assumptions.

If a decimal rendering is requested, it must come from a rigorous enclosure or
another proof-bearing numerical method that justifies the printed digits.

## 6. Domains, assumptions, and branches

Every operation that depends on a mathematical domain must state and enforce it.
Examples include:

- real versus complex roots;
- positive versus principal square root;
- logarithm branch choice;
- inverse-trigonometric branch conventions;
- orientation and coordinate conventions in geometry;
- probability model assumptions;
- unit and frame conventions in physics.

Assumptions used to justify simplification, solving, integration, or other
transformations must survive in the result or its evidence unless the result is
unconditionally valid.

## 7. Degenerate and boundary cases are first-class

Implementations must enumerate meaningful boundary cases rather than hiding them
inside a generic failure.

Examples include:

- division by zero;
- repeated roots;
- singular matrices;
- empty and universal solution sets;
- touching versus overlapping geometry;
- equality at a strict physical threshold;
- zero-duration evolution;
- non-convergent integrals or transforms;
- rank-deficient statistical models.

A boundary case that changes the mathematics must have a distinct test and,
where useful, a distinct structured status.

## 8. Determinism

For identical admitted input, configuration, and dependency versions, CENTL must
produce mathematically equivalent results and deterministic machine-visible
ordering.

Randomized algorithms must either:

- use a caller-visible seed/provenance record; or
- be wrapped in a deterministic verification stage that makes the final verdict
  independent of the random path.

Hash-table order, thread scheduling, backend incidental ordering, or platform
iteration order must not leak into canonical mathematical results.

## 9. Resource bounds and cancellation

Every potentially expensive capability must define limits before it crosses a
public machine boundary.

Depending on the algorithm, limits may include:

- input bytes;
- expression nodes;
- degree;
- variable count;
- coefficient bit size;
- matrix/tensor dimensions;
- iteration count;
- recursion depth;
- solution count;
- precision bits;
- output bytes;
- wall-independent algorithmic work units.

Long-running work must expose deterministic cancellation checkpoints where this
can be done without corrupting the mathematical state.

Resource exhaustion is not a mathematical contradiction and must not be reported
as one.

## 10. One mathematical evaluator, many surfaces

A feature's mathematical semantics belong in one canonical implementation.

CLI, JSON Lines, MCP, CENTL-SCi, web, and future interfaces must delegate to that
implementation rather than reimplementing the mathematics independently.

Adapters may:

- parse validated surface syntax;
- translate into typed requests;
- render structured results;
- attach transport-level metadata.

Adapters may not silently change the domain, algorithm, assumptions, precision,
or exactness classification.

## 11. Machine schema before promotion

A public feature is incomplete until its result can be represented without
scraping human text.

The machine schema must expose, where applicable:

- result kind;
- exactness/certification class;
- mathematical value;
- assumptions/conditions;
- algorithm or method identity at an appropriate abstraction level;
- backend identity when relevant;
- precision/enclosure data;
- refusal/deferred reason;
- provenance;
- resource-limit metadata.

Schema additions must be versioned or additive according to the existing
protocol contract.

## 12. Evidence and provenance

Every nontrivial new domain must identify the evidence supporting its result.
This does not require a gigantic proof object for every calculation, but the
result must reveal enough to audit the claim.

Examples:

- exact polynomial coefficient identity;
- substitution check for a solved equation;
- residual norm or exact zero check for a linear solve;
- isolating interval for an algebraic root;
- interval containment for numerical approximation;
- conservation invariant for a collision;
- witness/counterexample for a finite claim;
- solver certificate for an optimization problem when available.

Backend names and dependency versions belong in build or result provenance when
they materially affect reproducibility.

## 13. Testing ladder

Every feature must pass the following ladder before promotion.

### 13.1 Unit examples

Cover ordinary valid inputs, invalid inputs, boundaries, and explicit refusal
cases.

### 13.2 Exact identities

Where applicable, verify returned results by substitution or an independent exact
identity. Examples:

- differentiate an antiderivative;
- substitute solved roots into the defining polynomial;
- multiply matrix factors back together;
- apply forward and inverse transforms on admitted classes;
- reconstruct CRT solutions and check every congruence.

### 13.3 Property and metamorphic tests

Test mathematical invariants across generated inputs, such as:

- commutativity/associativity where valid;
- distributivity;
- determinant identities;
- conservation laws;
- transform linearity;
- probability normalization;
- permutation invariance where mathematically appropriate.

### 13.4 Independent differential testing

Compare against at least one independent implementation or independently coded
oracle for representative cases.

Preferred tools include Julia/Nemo, FLINT, Arb/Acb, MPFR, or another suitable
open mathematical library. Differential agreement is evidence, not the formal
definition of correctness: CENTL must still enforce its own contract.

### 13.5 Adversarial tests

Exercise:

- extreme exact bit sizes;
- degree/dimension boundaries;
- singular/degenerate inputs;
- cancellation races;
- malformed machine requests;
- branch cuts;
- near-threshold enclosure cases;
- output explosions;
- backend error translation.

### 13.6 Regression vectors

Every discovered bug that could produce a mathematically wrong answer receives a
permanent regression case.

## 14. Formal verification policy

Not every algorithm must be fully proved in F*, but the most dangerous semantic
boundaries should be verified when feasible.

Priority verification targets include:

- parsing exact numeric literals;
- normalization/canonicalization invariants;
- checked backend-to-core representation transfer;
- exact equality or zero certificates used to promote a result;
- enclosure inclusion/rounding rules;
- transformations that could otherwise silently widen a mathematical domain.

A backend algorithm may be trusted as a component while CENTL formally verifies
the narrower property that turns backend output into a CENTL claim.

## 15. Backend policy

External mathematical libraries are allowed when they improve correctness,
performance, or breadth, provided that:

1. the dependency is compatible with the project's licensing and preservation
   policy;
2. the dependency is pinned/reproducible where required;
3. CENTL validates data crossing the boundary;
4. backend errors cannot become successful mathematical results;
5. the backend does not define CENTL's public semantics by accident;
6. an independent test oracle is preferred over using the same backend as both
   implementation and verifier.

## 16. Performance comes after the semantic floor

A slow correct implementation can be optimized. A fast ambiguous implementation
is technical debt with a calculator attached.

Optimization work must preserve:

- exactness classification;
- deterministic output;
- refusal behavior;
- boundary-case semantics;
- machine schema;
- evidence.

Any optimized path must be cross-checked against a simpler reference path where
practical.

## 17. Documentation requirements

Every promoted capability needs documentation that states:

- what it computes;
- accepted syntax or API;
- mathematical domain;
- exactness/approximation semantics;
- assumptions and conventions;
- examples;
- refusal cases;
- resource limits;
- current non-goals.

Marketing language must not claim an entire field is supported when only a narrow
slice is implemented.

## 18. Security requirements

Mathematical breadth creates denial-of-service surfaces. New algorithms must be
reviewed for:

- input-size amplification;
- pathological expression growth;
- unbounded recursion;
- superlinear allocation;
- parser/schema ambiguity;
- unsafe native boundary handling;
- temporary-file or subprocess hazards;
- attacker-controlled backend options.

Machine-facing mathematical requests remain data, not shell commands or source
code to execute.

## 19. Completion gate

A capability may be checked in the strategic backlog only when all applicable
items below are satisfied:

- [ ] Mathematical contract written.
- [ ] Input domain and branch conventions explicit.
- [ ] Exactness/result classification defined.
- [ ] Canonical implementation landed.
- [ ] Refusal and boundary cases implemented.
- [ ] Resource limits implemented.
- [ ] Machine schema implemented.
- [ ] CLI/SCi/web adapters delegate rather than reimplement mathematics.
- [ ] Unit and boundary tests pass.
- [ ] Property/metamorphic tests pass where applicable.
- [ ] Independent differential tests pass where applicable.
- [ ] Adversarial tests pass.
- [ ] Documentation landed.
- [ ] Security/native-boundary review complete where applicable.
- [ ] CI green on the feature branch.

## 20. Feature specification template

Use the following template at the start of an implementation branch or design
record.

```text
Capability:
Domain:
Backlog item:

Mathematical definition:
Accepted inputs:
Returned value model:
Result classification:
Assumptions/conventions:
Boundary cases:
Refusal cases:
Non-goals:

Algorithm/backend:
Independent oracle:
Resource limits:
Cancellation points:
Machine schema:
Evidence/provenance:

Tests:
- exact examples
- boundary/degenerate examples
- property/metamorphic checks
- differential checks
- adversarial/resource checks

Promotion condition:
```

## 21. The governing rule

Breadth is valuable only when every new capability strengthens rather than
weakens the meaning of a CENTL result.

If CENTL knows, it should say what it knows and why.
If CENTL can only enclose, it should show the enclosure.
If CENTL depends on assumptions, it should carry the assumptions.
If CENTL cannot justify the answer, it should refuse the certainty.
