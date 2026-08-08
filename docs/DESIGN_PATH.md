# CENTL product design path

Status: `0.11.0` agent-safe foundation shipped; `0.12.0` contracts are next.

This document turns CENTL's existing exactness, verification, numerical, and
machine-interface work into an ordered product path. It does not replace the
architectural invariants in [DESIGN.md](DESIGN.md), the proof inventory in
[VERIFICATION.md](VERIFICATION.md), or the protocol contract in
[PROTOCOL.md](PROTOCOL.md). It determines which capabilities should be built
next and the conditions under which each capability is ready to ship.

The broader capability list in [ROADMAP.md](ROADMAP.md) remains useful, but
mathematical breadth does not drive the next releases. Honest result semantics,
claim verification, replayable evidence, and repository integration do.

## Product decision

CENTL will become the mathematical contract checker for code and automated
workflows:

> Given a formula, constant, threshold, example result, identity, or bound,
> CENTL verifies it, refutes it with evidence, or returns an honest `unknown`.

The short positioning is:

> CENTL is a type checker for mathematical claims.

The operational promise is:

> change the world.

This direction is more valuable than competing on the number of supported
calculator functions. It turns a calculation into a durable repository
contract that can be checked interactively, called by an agent, committed with
source, replayed in CI, and audited later.

## Two related workstreams

There are two related products, but this document owns only one of them.

### Deterministic CENTL

This repository and design path own:

- exact and symbolic semantics;
- rigorous enclosure semantics;
- transformation-completion metadata;
- structured claim verification;
- evidence receipts and their trust classification;
- CLI, script, JSON, MCP, and CI behavior;
- deterministic limits, cancellation, and session behavior; and
- the stable integration contract consumed by other applications.

### CENTL Math AI

CENTL Math AI is being designed in a separate workstream. This document does
not choose its model provider, model architecture, prompts, user interface,
conversation storage, deployment topology, or release plan.

The Math AI workstream depends on the interface defined here. Its AI may
interpret a question, propose a formal claim, choose tools, organize multiple
claims, and explain returned evidence. It is not a second mathematical
evaluator and must not create a second definition of CENTL semantics.

The boundary is:

```text
natural-language question
          |
          v
  CENTL Math AI                    separate workstream
  interpretation, planning,
  clarification, explanation
          |
          | typed claim or expression
          v
  deterministic CENTL             this design path
  parse, resolve, compute,
  verify, classify, receipt
          |
          v
  verdict and evidence
```

The AI workstream may evolve independently as long as it consumes the stable
contract and preserves the distinction between:

1. what the user said;
2. how the AI formalized it;
3. what assumptions and domains were selected;
4. what CENTL actually verified; and
5. how the AI explained the result.

CENTL verifies the formal claim. It does not certify that an AI interpretation
faithfully captures an ambiguous natural-language request.

## Licensing decision

This path assumes the existing `AGPL-3.0-or-later` license remains in place.
No relicensing, dual-licensing, or product work aimed at satisfying a specific
company's open-source policy is included in this path.

## Primary users and jobs

The initial users are maintainers and automation authors working in repositories
where incorrect mathematics can enter source, tests, configuration, or
documentation. Useful initial domains include:

- pricing, billing, rates, discounts, and exact decimal rules;
- scientific and numerical libraries;
- engineering calculations and documented bounds;
- constants, unit conversions, and formula implementations;
- generated examples and expected outputs in documentation; and
- agent-authored changes containing arithmetic or algebraic claims.

The first job is deliberately narrow:

> Decide whether an explicit mathematical claim is valid before accepting a
> change.

Natural-language discovery of claims inside arbitrary code is not required for
the deterministic product's first release. Humans, agents, or the separate Math
AI workstream can construct the initial typed claim.

## Non-negotiable product properties

The existing numerical rules remain in force, with the following product-level
additions:

- Exactness describes a value; it does not imply that a requested operation
  completed.
- Every transformation reports whether it completed, remained residual, was
  outside its domain, or became indeterminate.
- `unknown` is an ordinary and useful verification outcome.
- An unsupported claim never becomes `verified` merely because an expression
  remained unchanged or two renderings look alike.
- Every `refuted` verdict carries an exact, replayable witness.
- Every `verified` verdict names its method, scope, domain, and assurance class.
- Conditions and domain obligations are never silently discarded.
- Stateful verification identifies every session definition on which it
  depended.
- Human, JSON, MCP, script, and CI surfaces are views of the same typed result.
- The deterministic runtime does not execute arbitrary generated Python,
  shell, or general-purpose language code to check mathematics.
- AI confidence and mathematical assurance are separate fields and separate
  concepts.

## The immediate semantic gap

The current value kind `ExactSymbolic` answers only whether the returned
expression is exact. It does not answer whether the requested transformation
was performed.

Several materially different situations can currently converge on an
unchanged symbolic expression:

- a simplification reached a proven fixed point;
- a polynomial was proved irreducible in the supported factorization domain;
- a transformer did not support the expression;
- an integral or derivative remained formal; or
- a work or precision limit prevented a decision.

Post-hoc inspection of the final AST can recognize some residual forms, such
as explicit derivative and integration nodes, but it cannot recover all lost
operation information. Transformation functions must preserve a classified
outcome as they run.

`ExactSymbolic` therefore remains a value classification, while a new
orthogonal resolution classification describes the operation.

## Public result model

### Transformation resolution

Every requested computation or symbolic transformation returns one of:

| Resolution | Meaning |
|---|---|
| `computed` | A value was calculated without a remaining requested operation. |
| `transformed` | The requested symbolic transformation was applied. |
| `unchanged_proved` | The unchanged form is a justified result within a named supported domain. |
| `residual` | The exact unevaluated operation remains visible in the result. |
| `unsupported` | The operation is outside the implemented domain. |
| `indeterminate` | Limits, precision, or mathematical uncertainty prevented completion. |

Every non-complete resolution includes a stable reason code and a concise
description of the supported domain. `residual` and `unsupported` are distinct:
a residual is a representable mathematical value, while unsupported describes
why the requested operation did not complete.

The classification belongs to the operation result, not to a renderer or a
provenance function inferred only from the final value constructor.

### Verification verdict

A typed claim returns exactly one verdict:

| Verdict | Meaning |
|---|---|
| `verified` | The claim was established within the declared scope by the named method. |
| `refuted` | An exactly checked witness makes the declared claim false. |
| `unknown` | The claim is meaningful, but the selected method cannot decide it. |
| `invalid` | The input does not denote a well-formed claim under the declared domain. |

These are successful verification responses, including `refuted`, `unknown`,
and `invalid`. Transport failures, cancellation, and resource-admission errors
remain tool or protocol errors.

An unresolved condition, an enclosure containing the decision boundary, an
unsupported quantifier, or a method outside its declared domain yields
`unknown`; it never falls through to `false` or `verified`.

### Assurance class

The verdict is accompanied by an assurance class so callers can distinguish
different trust arguments:

| Assurance | Meaning |
|---|---|
| `verified_core` | The decisive path is covered by a stated F* semantic theorem. |
| `exact_algorithm` | The decisive path used exact arithmetic but lacks the corresponding general semantic theorem. |
| `certified_enclosure` | A validated Arb enclosure establishes the required ordering or bound. |
| `witness_checked` | Exact evaluation confirms the supplied counterexample. |
| `none` | No decisive assurance is available; normally paired with `unknown` or `invalid`. |

The public documentation must not call every receipt a formal proof
certificate. A receipt is replayable evidence. Its assurance field describes
which parts are proof-backed and which trusted implementation boundaries remain.

## Typed claim interface

The first verification interface avoids immediate changes to the calculator
grammar. It accepts structured fields:

```json
{
  "left": "(x + 1)^3",
  "relation": "equal",
  "right": "x^3 + 3*x^2 + 3*x + 1",
  "variables": [
    {"name": "x", "domain": "rational"}
  ],
  "assumptions": []
}
```

Supported relation names remain:

```text
equal
not_equal
less_than
less_or_equal
greater_than
greater_or_equal
```

An explicit variables list determines whether the claim is closed or
universally quantified in a supported domain. An omitted variable is never
silently inferred as universally quantified. The first release accepts zero or
one rational variable and no free-form assumptions.

The response is a discriminated object rather than an unstructured value:

```json
{
  "schema": 1,
  "verdict": "verified",
  "scope": "univariate_rational_polynomial",
  "method": "polynomial_zero_difference",
  "claim": {
    "left": "(x + 1)^3",
    "relation": "equal",
    "right": "x^3 + 3*x^2 + 3*x + 1",
    "variables": [{"name": "x", "domain": "rational"}]
  },
  "evidence": {
    "normalized_difference": "0"
  },
  "assurance": {
    "class": "verified_core",
    "theorem": "rational_polynomial_zero_difference_sound"
  },
  "producer": {
    "name": "centl",
    "version": "0.12.0",
    "build": "..."
  }
}
```

Method and schema names are versioned contracts. Human text may improve
without changing their meaning.

## Initial verification domains

### Closed exact rational claims

If both sides reduce to exact rationals, CENTL can decide equality and order
using the verified rational representation and operations. The receipt records
both normalized values and the comparison method.

Examples include:

```text
0.1 + 0.2 = 3/10
7/8 < 0.9
(3/4)^2 = 9/16
```

An undefined closed expression is `invalid` with a mathematical diagnostic. A
resource limit remains an operational failure rather than a false verdict.

### Univariate rational-polynomial equality

CENTL already collects and canonicalizes bounded univariate rational
polynomials. Verification computes the exact polynomial difference and tests
whether every coefficient is zero.

Before this path returns `verified` with `verified_core`, the F* core must add a
semantic preservation theorem:

> If polynomial collection of `left - right` returns the zero coefficient
> list for variable `x`, then both expressions evaluate to equal rational
> values for every rational `x` in the accepted expression domain.

The proof should define rational-point denotational evaluation and establish
soundness through constants, the selected variable, negation, addition,
subtraction, multiplication, exact constant division, and bounded natural
powers.

Until that theorem is present, normalization may be exposed as diagnostic
evidence but must not be marketed as a formal universal proof.

### Exact refutation

A false universal claim may be returned as `refuted` only after CENTL evaluates
an explicit rational counterexample exactly. A deterministic bounded witness
search may try small rational points, but failure to find a witness yields
`unknown`, never `verified`.

Example evidence:

```json
{
  "counterexample": {
    "bindings": {"x": "1"},
    "left": "4",
    "right": "2"
  }
}
```

### Closed real inequalities

For a closed real inequality, CENTL evaluates the difference using the existing
Arb path. An enclosure strictly above or below zero can establish an ordering.
If the enclosure contains zero, precision may increase within the request
limits; if it still contains zero, the verdict is `unknown`.

Enclosure overlap cannot establish real equality. Equality must reduce exactly
or use a future domain-specific method.

The receipt retains the exact dyadic endpoints, requested precision, achieved
precision, retry count, and trusted backend classification.

### Conditions and assumptions

The first claim release does not attempt a general positivity or assumption
solver. If simplification leaves a condition that is not discharged by the
declared domain, the verdict is `unknown` and the outstanding obligation is
returned explicitly.

Future assumption support must use typed relations and named domains. It must
not accept unstructured prose as a trusted mathematical assumption.

## Evidence receipt

A verification receipt contains enough information to reproduce the exact
formal claim and understand the assurance boundary:

- receipt schema version;
- canonical claim and original input fields;
- explicit variables, quantifiers, domains, and assumptions;
- verdict, scope, method, and stable reason codes;
- normalized expression or exact evaluated sides;
- exact counterexample or enclosure endpoints where applicable;
- unresolved conditions and domain obligations;
- transformation resolution metadata used while checking the claim;
- session revision and the exact definitions read by the request;
- active resource ceilings and relevant work consumed;
- CENTL semantic version and protocol version;
- source commit and generated-core hash;
- F*, OCaml, FLINT, Arb, GMP, and MPFR build versions as applicable; and
- assurance class, named theorem when applicable, and trusted components.

Receipts are generated by the verifier while it still has the operation and
dependency context. They are not reconstructed later from the final rendered
value.

Receipt serialization counts against a dedicated bounded metadata budget. A
receipt cannot grow without limit merely because a session contains many
definitions; only actual transitive dependencies are included.

The initial receipt is replayable and inspectable but not cryptographically
signed. Signing and independently checkable certificates are separate future
decisions.

## Session and dependency semantics

Verification is read-only and idempotent with respect to a session. It may read
immutable definitions, but the response must include:

- the session revision;
- every directly and transitively referenced definition;
- the resolved claim after expansion; and
- the limits under which expansion occurred.

The standalone `centl verify` form is stateless unless definitions are supplied
explicitly. `centl check` processes definitions and assertions in file order,
making the contract file itself the reproducible source of state.

Invisible persistence of calculator definitions across processes is not part
of this path. Durable mathematical state belongs in explicit scripts or
contract files.

## Machine and MCP surface

The current combined calculation-and-definition tool prevents ordinary
computation from being truthfully advertised as read-only. The MCP surface will
be split into a small number of semantic tools:

| Tool | Purpose | Read-only | Idempotent |
|---|---|---:|---:|
| `centl_compute` | Evaluate one expression; reject definitions structurally. | yes | yes |
| `centl_verify` | Check one structured mathematical claim. | yes | yes |
| `centl_define` | Add one immutable value or function definition. | no | no |
| `centl_session` | Inspect revision, definitions, limits, and capabilities. | yes | yes |
| `centl_reset` | Clear the current session explicitly. | no | no |

The server also exposes one machine-readable capability catalog, either through
`centl_session`, a dedicated read-only operation, or an MCP resource. It lists:

- accepted syntax and examples;
- operation signatures;
- supported transformation domains;
- verification scopes and assurance classes;
- value and receipt schema versions;
- active deterministic ceilings; and
- known residual and `unknown` behavior.

Tool input and output schemas use discriminated unions with enums for all
stable classifications. Generic `object` placeholders are insufficient for
agent tool use.

`centl_calculate` remains temporarily as a compatibility alias. It is marked
deprecated once all first-party documentation uses the split tools and is not
removed before a protocol-major compatibility decision.

The persistent JSON protocol mirrors the same operations. MCP remains a thin
adapter and does not gain a separate evaluator, result model, or session model.

## CLI and contract files

The eventual human interface is:

```sh
centl verify \
  --left '(x + 1)^3' \
  --relation equal \
  --right 'x^3 + 3*x^2 + 3*x + 1' \
  --variable x:rational

centl check math-contracts.centl
centl check math-contracts.centl --receipt results.json
```

Once the structured verifier is stable, the calculator grammar gains an
assertion statement. One acceptable surface is:

```text
assert(0.1 + 0.2 = 3/10)
assert((x + 1)^3 = x^3 + 3*x^2 + 3*x + 1,
       for_all = x,
       domain = rational)
```

The final grammar may vary, but it must preserve explicit quantification and
domain selection. A free identifier cannot silently imply `for all`.

`centl check` uses these exit semantics:

- exit `0` when every assertion is `verified`;
- exit `1` when any assertion is `refuted`, `unknown`, or `invalid`; and
- exit `2` for invocation, transport, cancellation, or internal operational
  failure.

The structured report distinguishes the exact verdicts. A later
`--allow-unknown` option may support exploratory workflows, but strict CI is the
default.

Scripts already stop at the first evaluation error. Contract checking may
either stop immediately or collect a bounded set of assertion outcomes; this
must be chosen once and kept identical across human and machine surfaces.
Collection is preferred for CI if its aggregate receipt size is bounded.

## Math AI integration contract

The separate Math AI workstream can rely on the following guarantees once the
corresponding core release ships:

1. `centl_compute` cannot mutate the mathematical session.
2. `centl_verify` accepts a typed claim rather than requiring prompt-generated
   calculator syntax for the full assertion.
3. Every tool result has a stable discriminant and JSON schema.
4. Residual and unsupported transformations are distinguishable from completed
   work.
5. `unknown` is returned as data, not disguised as a tool failure.
6. Every decisive verdict includes a scope, method, evidence, and assurance
   classification.
7. Stateful results expose the exact definitions used.
8. Capability discovery describes supported domains and examples without the
   AI guessing from prose documentation.
9. Error objects include stable codes, source ranges, relevant limits,
   retryability, and a suggested recovery when one is known.
10. Protocol and receipt versions allow the AI product to reject an incompatible
    core rather than silently misinterpret it.

The Math AI workstream is responsible for displaying or otherwise preserving:

- the original user request;
- its proposed formalization;
- every inserted assumption;
- the CENTL verdict and assurance class; and
- whether the final explanation is fully, partially, or not mathematically
  verified.

If a material claim is `unknown`, the AI may explain the limitation or request
clarification. It must not relabel the answer as verified based on model
confidence. If the AI alters a formal claim after seeing a result, the altered
claim requires a new receipt.

No provider-specific behavior is required from deterministic CENTL. Local and
hosted models should consume the same contract.

## Internal implementation path

The work should preserve one evaluation path and reuse existing boundaries.

### Result semantics

Introduce operation-result metadata at the point transformations occur.
Conceptually:

```text
operation_result = {
  value;
  resolution;
  reason;
  supported_domain;
  conditions;
  dependencies;
}
```

Core transformations should return classified outcomes such as applied,
proven unchanged, and unsupported instead of returning only an expression.
The OCaml host carries that information through session expansion, rendering,
protocol serialization, and receipts.

A recursive scan for explicit residual nodes is useful as a compatibility
check, but it is not the source of truth because some transformation wrappers
disappear during evaluation.

### Dedicated verifier

The verifier is a dedicated classifier over the existing parser, resolver,
exact evaluator, polynomial machinery, and native enclosure path. It does not
infer success from ordinary pretty-printed output.

The initial implementation can live at the OCaml host boundary while decisive
exact algorithms and semantic theorems remain in F*. The verifier owns:

- claim validation;
- variable and domain validation;
- aggregate two-sided resource accounting;
- selection of one supported verification method;
- exact witness checking;
- verdict construction; and
- receipt construction.

Both claim sides share one request budget. Evaluating left and right separately
must not accidentally double every configured ceiling.

### Proof obligation

Add the rational-polynomial zero-difference semantic theorem before enabling a
universal polynomial `verified` verdict with `verified_core` assurance. The
generated core snapshot, verification documentation, and theorem identifier in
receipts must update together.

### Build identity

Release artifacts gain a bounded machine-readable build manifest containing:

- source commit;
- generated-core hash;
- toolchain and backend versions;
- verification command and result;
- target platform; and
- receipt-schema versions supported by the binary.

The manifest is shipped beside the executable and addressable through
capability discovery. Receipts reference its build identifier rather than
copying unbounded build metadata into every result.

### Likely implementation sites

The expected areas of change are:

- `src/fstar/Centl.Core.fst` for classified core transforms, polynomial
  semantics, and the soundness theorem;
- `src/ocaml/centl_engine.ml` for operation metadata, dependency tracking, and
  host-side method selection;
- a focused verifier module for typed claims and evidence;
- a focused receipt module for bounded, versioned serialization;
- `src/ocaml/centl_parser.ml` for assertion statements after the structured API
  is stable;
- `src/ocaml/centl_protocol.ml` for compute, verify, define, session, and reset
  operations;
- `src/ocaml/centl_mcp.ml` for the split tools and exact schemas;
- `src/ocaml/main.ml` for `verify`, `check`, exit behavior, and human rendering;
  and
- the existing syntax catalog as the source for capability and help output.

Exact module names are implementation choices. The architectural requirements
are typed outcomes, one evaluator, bounded evidence, and identical semantics
across surfaces.

## Release path

### `0.11.0` — Honest outcomes

Objective: make CENTL safe for an automated caller to interpret.

Status: shipped on 2026-08-08.

Required work:

1. Add transformation-resolution metadata and stable reason codes.
2. Ensure residual integration, differentiation, expansion, simplification,
   factoring, and solving cases are classified truthfully.
3. Carry resolution through human, JSON, persistent JSON, and MCP output.
4. Split pure computation from session mutation in MCP and JSON operations.
5. Publish precise discriminated input and output schemas.
6. Expose supported mathematical domains through capability discovery.
7. Add structured source ranges, limit details, retryability, and suggestions to
   machine errors.
8. Add definition inspection and dependency-bearing state responses.
9. Generate focused help from the existing syntax catalog.
10. Build an agent-tool evaluation corpus covering correct calls, residual
    recognition, supported-domain selection, cancellation, and `unknown`.

Exit gates:

- No supported regression case can make an unchanged residual look completed.
- `centl_compute` rejects definitions and cannot mutate state.
- Tool annotations accurately describe read-only and idempotent behavior.
- Every value and error variant is represented in the published JSON schema.
- Human and machine resolution classifications agree for the same request.
- Existing protocol clients retain a documented compatibility route.

Math AI dependency delivered: a safe, discoverable, read-only compute surface
whose status cannot be confused with mathematical completion.

### `0.12.0` — Math contracts

Objective: make mathematical claims enforceable in repositories.

Required work:

1. Add the structured claim and verdict types.
2. Implement closed exact rational comparisons.
3. Prove polynomial collection sound for the accepted univariate rational
   domain.
4. Implement universal polynomial equality through exact zero-difference
   normalization.
5. Implement bounded deterministic counterexample search and exact witness
   checking.
6. Implement closed real inequality decisions from certified sign enclosures.
7. Return `unknown` for every claim outside these declared domains.
8. Generate bounded, versioned evidence receipts.
9. Add the assertion grammar after the structured interface stabilizes.
10. Add `centl verify` and `centl check` with stable exit behavior.
11. Add build identity and verification metadata to release artifacts.
12. Publish a reusable CI action and contract-file examples.

Exit gates:

- No unsupported claim receives a decisive verdict.
- Every `refuted` result includes an exactly rechecked counterexample.
- Every `verified` result identifies its domain, method, and assurance class.
- Every receipt can be replayed against a compatible build with the same
  canonical claim and verdict.
- Contract files produce identical verdicts locally and in CI.
- A strict CI run fails on `refuted`, `unknown`, and `invalid`.
- Verification documentation states the new theorem and remaining trusted
  boundary precisely.

Math AI dependency delivered: a typed, read-only verification API with honest
four-state verdicts and inspectable evidence.

### `0.13.0` — One certified domain

Objective: become unusually useful in one high-value domain instead of adding
shallow breadth.

Select exactly one primary expansion after `0.12.0` pilots:

| Pilot demand | Primary expansion | Why it fits |
|---|---|---|
| Engineering and scientific bounds | Bounded variables, interval subdivision, certified extrema or inequalities | Extends the existing Arb strength and makes rigorous bounds accessible without theorem-prover ceremony. |
| Pricing and billing | Decimal quantization, named rounding modes, scale contracts, exact rate composition | Produces immediately useful regression contracts for financially sensitive code. |
| Conversion-heavy software | First-class dimensions and exact unit conversions | Prevents a common class of formula and conversion errors. |

Selection gate:

- at least three pilot repositories request the same domain;
- the domain has at least twenty real claims suitable for committed contracts;
- its semantics can be documented without weakening exactness or `unknown`;
- its value and receipt model can remain bounded; and
- it has an independent differential or reference-testing strategy.

Do not implement all three in one release. Units and bounded variables both
change core semantics materially; they require dedicated design amendments.

Math AI dependency delivered: a deeper verified domain that the separate AI
workstream can expose conversationally without inventing its own calculations.

## Distribution path

The deterministic product should reach users through the workflow in which the
contract matters:

1. Native CLI releases remain the canonical local executable.
2. A reusable CI action runs `centl check` and retains the receipt artifact.
3. MCP bundles package the same native executable and advertise the split tool
   schemas.
4. Registry metadata and copyable client configurations make local tool setup
   routine.
5. Release archives include a real offline quickstart, build manifest, and
   verification-boundary document.
6. `centl doctor` checks native backend loading, build identity, protocol
   compatibility, and one exact plus one enclosure smoke case.
7. `centl --print-mcp-config` emits a valid local configuration for supported
   clients without embedding client-specific behavior in the evaluator.

A hosted deterministic service is not required for the first contract release.
If one is added later, it uses the same typed operations and receipt schema.

Packaging or UI decisions for CENTL Math AI belong to its separate workstream.

## Verification and evaluation strategy

### Deterministic test layers

- F* proofs for the exact semantic obligations.
- Golden claim/verdict/receipt fixtures.
- Property tests for exact rational comparisons.
- Generated polynomial identities and mutations that introduce one error.
- Exact replay of every generated counterexample.
- Enclosure tests in which zero is clearly excluded, clearly included, and only
  excluded after precision escalation.
- Domain-boundary tests that must produce `unknown`.
- Session dependency and revision tests.
- Aggregate two-sided limit and receipt-size tests.
- Agreement tests across CLI, scripts, JSON, persistent JSON, and MCP.
- Compatibility tests for the deprecated combined tool.
- Cancellation tests before method selection, between claim sides, during
  witness search, during precision retry, and before receipt emission.

### Agent-facing contract tests

The deterministic repository should maintain a provider-neutral tool-use corpus
that the Math AI workstream can also consume. It covers:

- selecting compute versus verify versus define;
- constructing a syntactically valid typed claim;
- recognizing a residual transformation;
- preserving `unknown` rather than guessing;
- reading exact counterexample evidence;
- respecting declared domains and conditions;
- avoiding hidden mutation; and
- rejecting incompatible schema versions.

The corpus evaluates the interface, not a particular model. Provider-specific
prompts and model-quality benchmarks remain with the Math AI workstream.

### Release quality targets

These are release gates, not marketing claims:

- zero known false decisive verdicts in the conformance corpus;
- zero residual operations mislabeled as completed;
- 100 percent of refutations include a replayed exact witness;
- 100 percent of decisive verdicts include scope, method, and assurance;
- 100 percent agreement across first-party surfaces;
- deterministic receipts for identical build, input, session dependencies, and
  limits; and
- no unbounded receipt, witness-search, queue, or session growth.

## Pilot plan

Before expanding beyond `0.12.0`, run the full workflow in real repositories:

1. Collect explicit claims from source, tests, configuration, and documentation.
2. Encode them as small contract files.
3. Run the same contracts through local CLI, an agent tool call, and CI.
4. Record which claims are verified, refuted, unknown, or invalid.
5. Record where users need unsupported domains, better diagnostics, or a
   different receipt.
6. Confirm whether maintainers voluntarily add new contracts after onboarding.

The direction is validated when at least three independent repositories:

- commit contract files;
- make the check required in CI;
- retain receipts for failures or releases; and
- add or update claims as the corresponding code changes.

The most frequent valuable `unknown` category determines the `0.13.0` domain.
Raw requests for more calculator functions do not automatically determine it.

## Explicit non-goals for this path

- Competing on general CAS function count.
- General symbolic integration, ODEs, transforms, probability, or statistics
  before the contract workflow is established.
- Matrices solely to match another calculator's feature list.
- A universal theorem prover or Lean replacement.
- Calling ordinary extra-precision numerics a proof.
- Calling every receipt a proof certificate.
- Executing arbitrary generated Python or shell as a verification strategy.
- Hundreds of operation-specific MCP tools.
- A second evaluator for MCP or Math AI.
- Hidden persistent definition state.
- A GUI, notebook platform, account system, or cloud synchronization in the
  deterministic contract releases.
- Choosing the CENTL Math AI model, provider, prompt, storage, UI, or deployment
  architecture in this document.
- Relicensing or dual-licensing work.

## Risks and controls

| Risk | Control |
|---|---|
| Residual work appears successful | Carry resolution from the transformation itself; test every unsupported boundary. |
| Exact normalization is overstated as formal proof | Gate the decisive polynomial verdict on the semantic soundness theorem. |
| Natural-language intent differs from the formal claim | Keep interpretation and formal claim visible; CENTL attests only to the latter. |
| AI explanation overstates an `unknown` result | Require the Math AI workstream to preserve verdict and assurance fields unchanged. |
| Stateful results cannot be reproduced | Include transitive dependencies and session revision in receipts. |
| Evidence becomes too large | Give receipt data its own deterministic aggregate ceiling. |
| Native calls exceed external deadlines | Keep cooperative limits honest and require callers to retain process timeouts. |
| Feature breadth delays the useful workflow | Gate `0.13.0` on pilot demand and select one domain. |
| Protocol evolution breaks the parallel AI product | Version claim and receipt schemas independently and reject incompatible versions explicitly. |
| A verifier silently becomes another evaluator | Keep verification as a classifier over the existing resolver, core, and native boundary. |

## Ordered implementation dependency graph

```text
classified transformation outcomes
          |
          +--> exact machine schemas --> split MCP/JSON tools
          |                                  |
          |                                  +--> Math AI safe compute dependency
          |
          +--> capability catalog and diagnostics
          |
          v
typed claim model --> exact rational verifier
          |                   |
          |                   +--> exact counterexample receipts
          |
          +--> polynomial semantic theorem --> polynomial verifier
          |
          +--> Arb sign classifier ---------> real inequality verifier
          |
          v
bounded receipt model --> CLI assertions --> centl check --> CI action
          |                                          |
          |                                          +--> repository pilots
          |
          +--> Math AI verification dependency       |
                                                     v
                                          select one 0.13 domain
```

No public Math AI dependency should be built on ambiguous transformation
status. No universal polynomial `verified` verdict should ship before its proof
obligation. No domain expansion should precede a working repository contract
loop.

## Final definition of the path

CENTL becomes extremely useful when it closes this loop:

```text
calculate or formalize
        -> verify
        -> expose evidence and uncertainty
        -> commit the claim
        -> replay it before merge
        -> let both people and AI depend on the same result contract
```

The deterministic engine is the authority. The separate Math AI product makes
that authority easier to access and understand. Neither product should blur the
line between interpretation, exact computation, certified enclosure, formal
proof, and honest uncertainty.
