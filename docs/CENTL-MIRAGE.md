# CENTL-MIRAGE

**Codename:** Mathematical Introspective Recursive Autonomous Growth Engine
**Status:** active development architecture
**Current development epoch:** **Al-Tih** -- see [`MIRAGE-AL-TIH.md`](MIRAGE-AL-TIH.md)
**Scope:** CENTL-SCi self-development, local specification ingestion, synthesis, validation, recursive improvement
**Network requirement:** none

> A self-extensible system must be able to change itself without being allowed to lie to itself.

> **Al-Tih declaration:** Oasis is not scheduled. Oasis is earned.

## 1. Purpose

CENTL-MIRAGE is the development effort for turning CENTL-SCi from an interaction and extension frontend into a locally owned self-development system.

The target is not a chatbot that edits source files. The target is a computational development loop in which CENTL can:

1. ingest a user's design, specification, notes, examples, or requirements written in ordinary language;
2. preserve those statements as attributable source material rather than silently paraphrasing them into authority;
3. map the requested behavior against the capabilities already present in CENTL and the active downstream workspace;
4. derive the smallest candidate change that can satisfy the unmet requirements;
5. synthesize native CENTL definitions, adapters, generated native modules, or isolated core patches as required;
6. construct proof, type, dimension, test, regression, and behavioral obligations for the candidate;
7. execute those obligations locally;
8. compare the candidate state against the previous state using explicit improvement rules;
9. accept only admissible improvements into a reversible workspace revision;
10. repeat when unmet requirements remain.

The system must remain useful with no paid AI service and no network connection. A local semantic model may help interpret prose, rank candidate meanings, or propose programs, but it is never the mathematical or engineering authority.

The active **Al-Tih** epoch deliberately pushes this architecture through sustained experimentation before another Oasis is sought. Its major expeditions are **The Caravan Trial**, **The Mirror**, **The Crucible**, **The Scribe**, **The Djinn Boundary**, **The Long Night**, **The Book of the Desert**, and eventually **The Return**. The complete charter, promotion protocol, and end conditions are defined in [`MIRAGE-AL-TIH.md`](MIRAGE-AL-TIH.md).

## 2. The MIRAGE state

A MIRAGE development state is modeled as

```text
S = (C, K, G, E, R)
```

where:

- `C` is the current computational system: upstream CENTL plus active downstream code and packages;
- `K` is the structure library: user documents, normalized specification cells, capability descriptions, examples, and provenance;
- `G` is the active goal graph: requested capabilities, invariants, acceptance criteria, non-goals, and unresolved questions;
- `E` is the evidence set: parser/type checks, exactness obligations, dimensional checks, proofs, tests, counterexamples, benchmarks, and assurance metadata;
- `R` is the reversible workspace revision history.

A candidate development step is a delta `d` producing

```text
S' = apply(S, d)
```

MIRAGE does not accept a delta because a generator considers it plausible. It accepts the delta only when the delta is admissible under the current goal graph and assurance policy.

## 3. Admissibility before scoring

Self-development must not reduce correctness to a single opaque reward number.

For a candidate `d`, MIRAGE first evaluates hard admissibility:

```text
A(S, d) =
    parses(d)
  ∧ type_safe(d)
  ∧ dimensions_safe(d)
  ∧ hard_invariants_hold(S, d)
  ∧ mandatory_regressions_pass(S, d)
  ∧ trust_boundaries_are_explicit(d)
  ∧ provenance_is_complete(d)
  ∧ rollback_state_exists(d)
```

Only admissible candidates can be compared.

Among admissible candidates, MIRAGE uses a partial order rather than pretending every engineering property has one natural numeric weight.

A candidate may dominate another when it is no worse on all required dimensions and strictly better on at least one of:

- requirement coverage;
- proof/evidence strength;
- semantic precision;
- deterministic behavior;
- runtime or memory cost, when performance is part of the requirement;
- implementation complexity;
- dependency surface;
- trust-boundary exposure;
- semantic drift from established behavior.

This produces a Pareto frontier of defensible candidates. Deterministic tie-breaking then prefers, in order:

1. the smallest semantic delta;
2. native CENTL over a new external dependency;
3. stronger assurance;
4. fewer new concepts exposed to the user;
5. lower implementation complexity.

The rule for autonomous acceptance is intentionally monotone:

```text
accept S' only if
  A(S, d)
  and (
       requirement_coverage(S') > requirement_coverage(S)
    or evidence_strength(S') > evidence_strength(S)
    or complexity(S') < complexity(S) with behavior preserved
  )
```

Adding an experimental capability may extend the system without promoting that capability to verified-core assurance. Assurance is component-local; MIRAGE must never hide this distinction.

## 4. The Structure Library

The local workspace gains a `library/` surface.

Conceptual layout:

```text
~/.centl/workspaces/default/
  library/
    <content-id>-design.md
  generated/
    mirage/
      <content-id>.spec.json
      <content-id>.plan.md
      active.json
```

A user may write a complete document and then ask CENTL-SCi:

```text
BUILD> ingest design ~/Research/orbital-system.md
```

The first MIRAGE slice copies the source into the structure library, derives a provenance-preserving Specification IR, produces an initial capability-aware development plan, and marks a local MIRAGE cycle active.

The original document remains the authority for what the user wrote. Generated interpretations retain source spans.

## 5. Specification IR

A document is not flattened into one prompt. It is decomposed into attributable cells.

Initial cell kinds are:

```text
DIRECTIVE
INVARIANT
ACCEPTANCE
EXAMPLE
NON_GOAL
QUESTION
CONTEXT
```

Every cell records:

```text
id
kind
source document
start line
end line
verbatim text
```

Later revisions will add semantic links among cells and typed entities, but the provenance rule is permanent: MIRAGE must be able to show exactly which source statement caused a goal, constraint, test, or change.

A local semantic model may suggest richer classification, but deterministic extraction remains available and any inferred meaning remains distinguishable from verbatim source material.

## 6. Goal graph

Specification cells are lowered into a graph rather than an unstructured prompt history.

Node families include:

```text
Requirement
Invariant
AcceptanceCriterion
Example
Capability
Artifact
Assumption
OpenQuestion
NonGoal
EvidenceObligation
```

Important edge families include:

```text
requires
refines
conflicts_with
satisfied_by
implemented_by
validated_by
introduced_by
blocks
supersedes
```

Contradictory hard requirements must become an explicit conflict in the graph. MIRAGE may not silently choose whichever sentence appeared later.

## 7. Capability graph and gap analysis

Before generating code, MIRAGE asks what CENTL already knows.

The active capability graph includes:

- verified core operations;
- CENTL mathematical and physics engines;
- native language constructs;
- active workspace modules;
- packages and adapters;
- their dependencies;
- their assurance levels;
- tests and evidence attached to them.

For each requirement `g`, MIRAGE computes one of:

```text
SATISFIED
COMPOSABLE
ALIAS_OR_WRAPPER
EXTENSION_REQUIRED
CORE_CHANGE_REQUIRED
AMBIGUOUS
CONFLICTING
UNSUPPORTED_BY_POLICY
```

The preferred outcome is composition. Self-development should not generate a second implementation of something CENTL already possesses.

## 8. Candidate synthesis

MIRAGE uses a hierarchy of synthesis mechanisms.

### 8.1 Native AST composition

First search the existing CENTL AST and capability graph for a composition of known operations.

### 8.2 Equality saturation

For algebraic and symbolic programs, equivalent expressions can be represented in an e-graph. Rewrite saturation allows MIRAGE to search many equivalent forms without repeatedly expanding the same algebraic state.

Extraction is constrained by exactness, supported operations, dimensions, and a cost model that prefers simpler and more strongly justified forms.

### 8.3 Counterexample-guided inductive synthesis

For behavioral extensions, MIRAGE uses a CEGIS-style loop:

```text
candidate := synthesize(spec, examples, capabilities)
repeat
  result := verify(candidate, obligations)
  if result = valid then return candidate
  if result = counterexample c then
      examples := examples ∪ {c}
      candidate := refine(candidate, c)
until budget exhausted
```

The verifier, not the generator, closes the loop.

### 8.4 Property and metamorphic synthesis

When the user's document provides only examples, MIRAGE attempts to derive candidate properties from known mathematical structure, but derived properties remain hypotheses until established by an authoritative checker or explicitly accepted as assumptions.

Useful metamorphic relations include symmetry, homogeneity, dimensional invariance, exact inverse relationships, monotonicity where mathematically justified, conservation rules, and round-trip properties.

### 8.5 Local semantic proposer

A local GGUF model may propose interpretations, names, candidate programs, test descriptions, documentation, or refactorings. Its outputs always enter the same Change IR and validation path as deterministic synthesis. No model output bypasses the parser or engineering gates.

## 9. Semantic fingerprints

Passing existing tests is necessary but insufficient for self-modifying code.

MIRAGE therefore maintains a behavioral fingerprint over a curated corpus of deterministic observations:

```text
F(C) = hash(normalize(observe(C, corpus)))
```

A candidate that is intended to preserve behavior must match the relevant baseline fingerprint. A candidate intentionally changing behavior must identify which observations are expected to change and why.

The fingerprint is evidence of observed behavior, not a proof of total equivalence.

## 10. Evidence lattice

Evidence is recorded by strength and scope rather than collapsed into `passed`.

A conceptual ordering includes:

```text
parsed
< type/dimension checked
< example tested
< property tested
< regression tested
< differential/metamorphic tested
< verifier discharged
< formally verified for stated theorem/domain
```

The ordering is not universal across unrelated properties. Evidence is attached to the claim it supports.

A result may therefore say:

```text
capability: orbital_transfer
source: local MIRAGE extension
assurance:
  parser checked
  dimensions checked
  43 deterministic tests passed
  8 metamorphic properties passed
  no formal proof for numerical convergence
```

This extends CENTL's rule against unjustified numerical digits into a rule against unjustified implementation confidence.

## 11. Recursive development cycle

The MIRAGE loop is:

```text
INGEST
  -> NORMALIZE
  -> BUILD GOAL GRAPH
  -> INTROSPECT CAPABILITIES
  -> COMPUTE GAPS
  -> SYNTHESIZE CANDIDATES
  -> CONSTRUCT OBLIGATIONS
  -> VERIFY / SEARCH FOR COUNTEREXAMPLES
  -> COMPARE WITH BASELINE
  -> ACCEPT OR REJECT
  -> RECORD REVISION + EVIDENCE
  -> RECOMPUTE GAPS
  -> repeat
```

The loop terminates when one of the following is true:

- all active requirements are satisfied;
- the remaining goals require user information that cannot be inferred safely;
- no admissible improvement is found within the configured local resource budget;
- a policy boundary blocks the required operation;
- the user stops the cycle.

A loop that merely keeps rewriting itself is not intelligence. MIRAGE must have an explicit progress measure and termination condition.

## 12. Autonomy policy

MIRAGE separates local autonomy from publication authority.

A local user may configure how aggressively MIRAGE applies admissible changes:

```text
observe   - analyze only
stage     - synthesize and validate candidates, do not activate
local     - automatically activate admissible downstream changes
core      - allow isolated downstream core patches after full relevant gates
```

No autonomy level implies automatic network publication. Pushing upstream remains a separate explicit operation.

Uploaded documents are data, not shell scripts. Document text never gains command-execution authority merely because it contains imperative language.

## 13. Implementation slice

The first MIRAGE implementation began below autonomous code mutation. The
current local cycle now also includes the documented next slice:

1. a first-class `library/` directory in the local CENTL workspace;
2. deterministic ingestion of local text/Markdown design documents;
3. provenance-preserving Specification IR;
4. classification of directives, invariants, examples, acceptance criteria, non-goals, questions, and context;
5. capability-aware planning using the existing BUILD capability and implementation-layer machinery;
6. a typed goal/capability graph with conflict detection, gap analysis, and `validated_by` links;
7. evidence obligations, candidate transactions, deterministic materialization, readiness, and execution plans;
8. a bounded CEGIS loop: extract examples, verify them against staged source, and refuse to invent a second implementation after a counterexample;
9. semantic fingerprints over a curated deterministic CENTL corpus, plus baseline comparison;
10. evidence executors for parser acceptance, capability discovery, example/fingerprint regression, and reversible snapshots;
11. admission, review, and explicit accept/reject under an `observe|stage|local|core` autonomy policy;
12. an `active.json` cycle record identifying the next MIRAGE phase and termination condition;
13. tests proving the cycle is local, attributable, reversible, and independent of a remote AI service;
14. bounded algebraic rewrite saturation with cheaper equivalent extraction;
15. metamorphic property checks (determinism, exactness, equality substitution);
16. a claim-local evidence lattice and Pareto ranking among admissible candidates;
17. an explicit progress measure recorded on the active cycle;
18. native AST composition of existing CENTL operations before new synthesis;
19. session-aware semantic fingerprints that detect core-corpus shadowing;
20. deterministic proposals that never inherit model authority;
21. `iterate` to recompute gaps from the stored source and `library` to list ingested documents.

A cycle never activates source by itself. `local` policy permits a later
explicit `centl-mirage accept` of an admissible downstream candidate. Isolated
core patches and network publication remain outside automatic authority.

Generated material still does not inherit verified-core assurance.

During Al-Tih, these slices are no longer treated as isolated endpoints. They are to be driven toward the integrated expeditions and promotion architecture defined in [`MIRAGE-AL-TIH.md`](MIRAGE-AL-TIH.md).

## 14. Non-negotiable invariants

CENTL-MIRAGE development is governed by these invariants:

1. No paid or remote AI service is required for operation.
2. A model may propose meaning or code; it may not confer truth or assurance.
3. Original user source text and provenance are retained.
4. Numbers, signs, operators, units, assumptions, and hard constraints are never silently invented during interpretation.
5. Every applied change is attributable to a goal and a workspace revision.
6. Every self-change is reversible before activation.
7. Existing verified guarantees cannot be silently weakened to admit a candidate.
8. New external dependencies and trust boundaries are explicit.
9. Generated code never inherits verified-core assurance merely because CENTL generated it.
10. Publication outside the local machine remains a distinct user-authorized action.
11. Progress is measured against explicit requirements and evidence, not model self-confidence.
12. MIRAGE must be able to explain why a change was made, what evidence admitted it, and which source requirement caused it.

This is the architecture required for CENTL to become capable of developing itself while remaining recognizably CENTL.

During **Al-Tih**, the project intentionally remains in MIRAGE until the evidence justifies **The Return**. There is no version deadline and no scheduled Oasis declaration.