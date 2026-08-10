# CENTL-SCi Interaction Intelligence and Self-Extension Vision

**Status:** Architectural vision and implementation-planning record  
**Recorded:** August 9, 2026 — 10:18 PM Central Time (America/Chicago, CDT / UTC-05:00; requested as CST)  
**Upstream repository:** `chasebryan/centl`  
**Author:** Chase Bryan  
**Organization:** Free Computation Foundation

> Free for science.

## Purpose

This document records the intended long-term direction for CENTL and CENTL-SCi after the CENTL 0.12.0 stable release. It exists as durable project memory and as an implementation-planning reference.

The discussion that produced this document began with a practical problem: ordinary users were frequently reaching responses equivalent to **“CENTL-SCi cannot solve this problem yet”** even when the underlying CENTL system could perform the relevant mathematics or physics. The failure was often not a computational limitation. It was an interpretation and interaction limitation.

The resulting direction is broader than improving a natural-language parser. CENTL should become a **user-owned, self-extensible computational environment** that helps people formulate scientific work, understand what the system did, correct mistakes, program new behavior, and extend or modify their own CENTL installation from within CENTL itself.

Mathematics and physics remain first-class, deeply trusted domains. They are not diminished. They become the strongest reference domains on top of a computational system that users are free to extend beyond the original upstream vision.

This document supplements, rather than replaces:

- [`SCI.md`](SCI.md)
- [`SYNTAX.md`](SYNTAX.md)
- [`PHYSICS.md`](PHYSICS.md)
- [`ROADMAP.md`](ROADMAP.md)
- [`DESIGN.md`](DESIGN.md)

---

# 1. Core product identity

CENTL should not ultimately be understood only as a calculator, a physics engine, a scripting language, or an AI-assisted scientific interface.

The intended identity is:

> **CENTL is a free, user-owned computational environment that can understand what a user is trying to accomplish, rigorously perform supported work, explain the evidence behind its results, and grow itself to support work it does not yet know how to perform.**

CENTL-SCi is the primary intelligent interaction layer for that environment.

The system should help the user rather than requiring the user to first become an expert in CENTL syntax, compiler internals, OCaml, F*, numerical analysis, or physics-engine implementation.

An average-intelligence user with a valid scientific or computational goal should be able to sit down at CENTL, describe what they are trying to do in ordinary language, recover from mistakes, discover the available operations, and confidently reach a useful result without reading advanced documentation first.

The governing principles remain:

1. The interpreter may infer intent; it may not manufacture mathematical or physical truth.
2. Exact values stay exact when the admitted domain permits it.
3. Approximation must remain qualified by justified bounds and provenance.
4. Unsupported work remains explicit.
5. The system should help a user reformulate or extend the system before giving up.
6. User extensions must never silently acquire the assurance level of the verified core.
7. The user owns the local system and its modifications.
8. Upstream CENTL is a reference foundation, not a limit on downstream possibility.

---

# 2. Upstream, downstream, and user sovereignty

The repository owned and maintained by Chase Bryan is the **upstream reference implementation** of CENTL.

A user's installed system is downstream.

A downstream user should be free to:

- use upstream CENTL unchanged;
- create local extensions;
- replace or augment domain behavior;
- create new mathematical, scientific, engineering, or application-specific domains;
- integrate external libraries or runtimes;
- build private functionality that is never published;
- diverge substantially from upstream;
- maintain a personal or organizational CENTL “bubble”;
- publish or contribute selected work upstream if desired.

No downstream user should be required to submit their extensions back to the upstream project.

A useful conceptual model is:

```text
upstream CENTL
      +
user workspace
      +
installed extensions
      =
that user's CENTL
```

The local system belongs to the person running it.

This is a technical expression of:

> **Free for science.**

---

# 3. The immediate usability problem

CENTL-SCi 0.0.1 deliberately has a narrow validated Problem IR. It currently admits only a small set of interpreted problem classes, while the underlying CENTL and CENTL Physics systems already support substantially more functionality.

This creates a mismatch:

```text
what CENTL can do
        >
what CENTL-SCi can recognize and route
```

The problem is amplified when the default deterministic fast path depends on particular sentence forms or prefixes. A user can describe a supported problem in perfectly reasonable English and still fall outside the recognizer.

When no semantic model is configured, that miss can collapse directly into a generic unsupported response.

This is unacceptable as the long-term user experience.

A supported problem should not fail merely because the user did not know the preferred phrasing.

---

# 4. CENTL-SCi must be intentionally “dummy-proof”

The interface should be forgiving of ordinary human imperfection without weakening mathematical rigor.

It should tolerate and recover from:

- spelling mistakes;
- common typos;
- capitalization differences;
- punctuation variation;
- extra or missing whitespace;
- Unicode mathematical notation;
- casual wording;
- terse wording;
- polite conversational wording;
- alternative mathematical vocabulary;
- common unit names and aliases;
- harmless notation differences;
- incomplete formulations;
- ambiguous but recoverable intent.

The system should help users converge on a valid scientific statement instead of making them reverse-engineer the parser.

The target principle is:

> **The user should understand the mathematics, physics, or task they care about. They should not need to understand CENTL-SCi's parser.**

---

# 5. Input normalization and conservative correction

CENTL-SCi should have an explicit normalization layer before intent routing.

Equivalent forms should normalize toward the same semantic interpretation where doing so is safe.

Examples include:

```text
x²
x^2
x squared
```

```text
×
*
times
multiplied by
```

```text
÷
/
divided by
```

```text
½
1/2
```

```text
π
pi
```

Common spelling mistakes should be detected.

Example:

```text
MATH> intergrate x squred from 0 to 5

I think you mean:
  integrate x squared from 0 to 5

[Tab] accept suggestion
```

Correction policy must distinguish between **safe lexical correction** and **semantically dangerous correction**.

Safe candidates include obvious spelling or presentation errors such as:

```text
intergrate -> integrate
squred     -> squared
equls      -> equals
```

CENTL-SCi must not silently change information such as:

- numbers;
- signs;
- mathematical operators;
- comparison direction;
- variable identifiers;
- physical quantities;
- ambiguous unit symbols;
- assumptions;
- boundary values.

Where a correction could change meaning, CENTL-SCi must ask for clarification or present ranked alternatives.

---

# 6. Clarification is a first-class outcome

The interaction system should not treat every non-executable interpretation as “unsupported.”

At minimum, it should distinguish:

```text
UNDERSTOOD + SUPPORTED
UNDERSTOOD + MISSING INFORMATION
UNDERSTOOD + DOMAIN NOT YET IMPLEMENTED
AMBIGUOUS INTERPRETATION
INPUT NOT UNDERSTOOD
EXECUTION FAILURE
```

A generic response such as:

```text
CENTL-SCi cannot solve this problem yet.
```

should be a last resort, not the normal recovery path.

Example:

```text
MATH> find x squared plus 4

I understand the expression x² + 4, but I am not sure what
operation you want.

You may mean:

  1. Solve x² + 4 = 0 for x
  2. Simplify x² + 4
  3. Differentiate x² + 4 with respect to x
  4. Evaluate x² + 4 for a value of x

Type a number, continue the statement, or rewrite it.
```

Another example:

```text
MATH> solve x squared plus 4

I can solve an equation, but the right-hand side is missing.

Examples:
  solve x squared plus 4 equals 0
  solve x squared plus 4 equals 12
```

Clarification state may persist only as much context as is needed to complete the pending scientific action.

This is not intended to turn the REPL into an unbounded social chatbot. It is bounded workflow state.

Useful bounded state includes:

- pending interpretation;
- candidate meanings;
- missing fields or slots;
- current mode;
- current workspace;
- session definitions;
- previous input/result references;
- pending proposed modification.

---

# 7. Intent routing should replace brittle sentence-prefix routing

The deterministic path should classify scientific intent rather than primarily asking whether a line starts with one exact phrase.

Candidate intent families include:

```text
arithmetic
simplification
equation solving
differentiation
integration
substitution
approximation
verification
unit conversion
constant lookup
geometry
sequence
recurrence
physics calculation
physics simulation
system inspection
program creation
system extension
system modification
unknown
```

Equivalent verbs and formulations should map to the same intent.

For equation solving, examples include:

```text
solve
find x
find the roots
roots of
zeros of
solutions of
where does ... equal
find where
determine x
```

For differentiation:

```text
differentiate
derivative of
take the derivative
find dy/dx
rate of change of
```

For unit conversion:

```text
convert
in
into
express in
how many ... in ...
change ... to ...
```

The intent router does not calculate the answer. It selects or constructs a validated request for the authoritative CENTL machinery.

---

# 8. Candidate recovery before rejection

When the first deterministic interpretation fails, CENTL-SCi should attempt bounded, conservative candidate recovery before declaring failure.

Example:

```text
find where x squared minus five x plus six equals zero
```

A valid candidate could be:

```text
intent: solve polynomial equation
variable: x
left: x^2 - 5*x + 6
relation: equal
right: 0
```

The candidate is then validated before execution.

The recovery layer should be permitted to infer structure, but not fabricate mathematical data.

For example, when a user types:

```text
solve x^2 - 5x
```

CENTL-SCi may indicate that an equation relation/right-hand side is missing. It must not invent `+ 6 = 0` merely because such a polynomial is common.

---

# 9. Smart shadow suggestions

CENTL-SCi should provide live “ghost” or shadow suggestions in interactive terminals.

The shadow suggestion should appear as noncommitted text after the current cursor/input and should be accepted explicitly, normally with Tab.

Examples:

```text
MATH> dif
      differentiate
```

```text
PHYS> convert 25 kilom
      convert 25 kilometers to
```

Suggestions should be divided into two classes.

## 9.1 Lexical completion

These are safe completions of known words, identifiers, commands, units, functions, variables, or session bindings.

Examples:

```text
integ -> integrate
kilom -> kilometers
diffe -> differentiate
```

## 9.2 Structural suggestion

These indicate likely missing grammar without fabricating values.

Example:

```text
MATH> solve x² + 2x
                     = [right side] for [variable]
```

Structural suggestions help the user discover what CENTL expects while preserving user control over mathematical content.

---

# 10. Context-sensitive Tab completion

Tab should become a primary interaction mechanism.

Suggested semantics:

- **Tab** accepts the current best safe suggestion.
- Repeated **Tab** cycles compatible alternatives where appropriate.
- **Double Tab** or an equivalent gesture may display all candidate completions.
- Completion should be grammar-aware and mode-aware.

Examples:

```text
MATH> int<Tab>
MATH> integrate
```

Then:

```text
MATH> integrate x^2<Tab>

Possible forms:
  integrate x^2 with respect to x
  integrate x^2 from [lower] to [upper]
```

The completion engine should consider:

- current mode;
- current token;
- cursor position;
- accepted grammar;
- available CENTL operations;
- known units;
- known constants;
- session variables/functions;
- workspace extensions;
- pending clarification slots;
- likely intent;
- recent user activity where appropriate.

Suggestions should be structured internally rather than rendered directly from ad hoc strings.

A possible internal suggestion object should eventually carry fields such as:

```text
category
replacement span
replacement text
confidence
safe_to_accept
explanation
alternatives
missing slots
source/provenance
```

This structured design allows the same suggestion engine to support CLI, TUI, GUI, editor, or web interfaces later.

---

# 11. Shared terminal editing infrastructure

The main `centl` calculator already contains important terminal functionality that should be reused rather than independently recreated in CENTL-SCi.

Existing functionality includes:

- raw interactive line editing;
- cursor movement;
- Up/Down history navigation;
- durable bounded history;
- in-memory history;
- Tab completion;
- multiline handling;
- `:history`;
- `:clear-history`.

The relevant editor/history/completion machinery should be extracted into shared modules used by both `centl` and `centl-sci`.

Possible module direction:

```text
Centl_terminal
Centl_editor
Centl_history
Centl_completion
```

CENTL-SCi should then add semantic completion and suggestions on top of that common editor instead of maintaining a second terminal implementation.

---

# 12. History and recall

Interactive history is a first-class usability feature.

## 12.1 Input recall

The Up arrow should retrieve previous user inputs in reverse chronological order.

The Down arrow should move toward newer entries and eventually restore the unfinished draft.

This matches normal shell/editor expectations and should reuse the existing CENTL history implementation.

## 12.2 Result recall

Previous **results** should be accessible separately rather than being inserted unexpectedly into the input editor by the Up arrow.

Potential commands include:

```text
:last
:result
:results
:history
:recall N
```

A future history record may be structured as:

```text
input
normalized input
mode
interpretation
result
explanation/provenance
workspace revision
timestamp
```

The user should be able to inspect and reuse prior work without creating implicit conversational ambiguity.

---

# 13. Explanation mode

CENTL-SCi should include an explicit explanation mode for users who want to know why an answer was produced and what operations were performed.

Proposed CLI forms:

```text
centl-sci --explain '...'
```

Interactive controls:

```text
:explain on
:explain off
```

This should coexist with the existing concise default presentation and machine-readable JSON.

Example:

```text
MATH> Solve x squared minus 5x plus 6 equals zero.

x = 2 or x = 3

Explanation
  Understood as:
    x^2 - 5*x + 6 = 0

  Requested operation:
    Solve for x

  Mathematical domain:
    Exact rational polynomial equation

  Method:
    CENTL polynomial solver

  Result:
    x = 2 or x = 3

  Assurance:
    Exact result
    No floating-point approximation used
```

Explanation must be generated from **structured interpretation and execution evidence**.

A language model must not be allowed to fabricate a plausible derivation after the fact.

The longer-term engine should expose structured derivation/provenance events such as:

```text
normalized
parsed
substituted
simplified
expanded
factored
differentiated
integrated
bounded
verified
refuted
deferred
```

The human explanation renderer can then translate those events into approachable language.

---

# 14. Explicit MATH, PHYS, HYBRID, and BUILD modes

The product should expose clear user-facing modes.

```text
MATH>
PHYS>
HYBRID>
BUILD>
```

Possible commands:

```text
:mode math
:mode physics
:mode hybrid
:mode build
```

Possible startup flags:

```text
centl-sci --mode math
centl-sci --mode physics
centl-sci --mode hybrid
centl-sci --mode build
```

## 14.1 MATH mode

Bias interpretation toward mathematical operations, variables, equations, functions, symbolic transformations, exact arithmetic, approximation, verification, sequences, and related mathematical work.

## 14.2 PHYS mode

Bias interpretation toward physical quantities, dimensions, units, constants, mechanics, physical assumptions, models, and CENTL Physics operations.

## 14.3 HYBRID mode

This should be the default general scientific mode.

It allows the router to combine mathematical and physical interpretation as needed.

## 14.4 BUILD mode

BUILD is the first-class system-construction and extension mode.

It tells CENTL-SCi to interpret the user's input primarily as an intention to create, modify, extend, compose, or inspect the computational system.

Examples:

```text
BUILD> Add nautical miles.
```

```text
BUILD> Create a projectile-motion module that accounts for linear drag.
```

```text
BUILD> I want a function that computes the first 500 primes and exports them as JSON.
```

```text
BUILD> Make the equation solver understand this new class of equations.
```

```text
BUILD> Add an interface for my laboratory sensor data.
```

```text
BUILD> Show me why this integration function cannot handle sin(x) and extend it if we can do so safely.
```

Modes are interpretive biases, not prisons. A user in HYBRID mode may still ask CENTL to build something, and the system should recognize the construction intent.

Mode information should also aid ambiguity resolution. For example, `m` in MATH mode is likely a variable, while PHYS mode should be more cautious because `m` may denote meters depending on context.

---

# 15. CENTL-SCi should help the user determine what they mean

The system should not merely complete text. It should help the user formulate the task.

Example:

```text
BUILD> Add gravity calculations.
```

Possible response:

```text
Gravity could mean several things.

You may want:
  1. Newtonian force between masses
  2. Uniform local gravitational acceleration
  3. Gravitational potential energy
  4. Orbital/two-body mechanics
  5. All of these as one gravity package

Current CENTL Physics already supports uniform gravity.
```

The system should prefer reuse and composition of existing capabilities over unnecessary reinvention.

This behavior should extend across mathematics, physics, programming, and system modification.

---

# 16. Self-extension is a first-class feature

A central long-term requirement is that a user can extend CENTL beyond the upstream project's original vision **from within CENTL itself**.

The user should be able to communicate with the system in ordinary English in roughly the same way a user communicates with an advanced coding assistant:

```text
HYBRID> I need to calculate orbital transfer windows using exact values where possible. Add whatever CENTL needs to support that.
```

CENTL should recognize that the request is not merely a calculation. It is a request to extend the system.

A future response may identify required components, existing reusable capabilities, unresolved design questions, trust implications, and a proposed implementation plan.

Example conceptually:

```text
I can extend this workspace with an orbital-mechanics domain.

I would add:
  • typed orbital quantities
  • gravitational-parameter support with uncertainty/provenance
  • two-body orbital calculations
  • transfer-orbit functions
  • dimensional validation
  • examples and tests

One requirement is unresolved:
  gravitational constants are measured quantities, so they cannot be represented as unjustified exact values.

I can implement them using bounded/provenanced quantities instead.
```

The user can then refine the design naturally:

```text
yes, but also let me specify my own measured values
```

This is the intended direction of interaction-driven programming and extension.

---

# 17. English programming becomes a first-class frontend

English input should become a programming frontend for CENTL rather than merely a way to request calculations.

The long-term pipeline is:

```text
human intent
    ↓
CENTL-SCi interpretation
    ↓
structured programming/change IR
    ↓
generated or modified CENTL source / extension source
    ↓
parser + type/dimension checks + verifier + tests
    ↓
local program or system extension
```

The semantic interpreter proposes meaning.

It does not declare its own generated program correct.

The compiler, validators, proof machinery, test suite, and runtime remain responsible for establishing what is justified.

Example:

```text
BUILD> Create a function that takes mass and velocity and computes kinetic energy.
```

CENTL-SCi might propose a native CENTL definition and then validate it before making it part of the workspace.

---

# 18. The CENTL language should grow, but should not become a prison

The existing CENTL language is already a legitimate scientific-language foundation. It currently includes exact values, definitions, functions, symbolic transformations, iteration, sequences, recurrences, assertions, and scripts.

That language should grow into the **primary user-facing extension language**.

Potential future native constructs include:

- richer functions;
- modules/packages;
- typed physical quantities;
- user-defined units;
- user-defined constants;
- domain declarations;
- reusable transformations;
- validation rules;
- tests;
- interfaces/adapters;
- richer data structures;
- explicit uncertainty/provenance values;
- extension metadata.

A conceptual example, not frozen syntax:

```text
unit furlong = 201168/1000 m

function kinetic_energy(mass, velocity) =
    1/2 * mass * velocity^2

assert kinetic_energy(2 kg, 3 m/s) = 9 J
```

However, CENTL must not restrict all possible downstream extension to whatever the native language happens to support.

Doing so would place the upstream project's imagination back at the center of what users are allowed to build.

The native CENTL language should be the easiest and safest extension path, not the only path.

---

# 19. Implementation-language and interoperability policy

The recommended hierarchy is:

## 19.1 Native CENTL language

Primary language for user programs, formulas, packages, scientific concepts, domain rules, transformations, workflows, tests, and ordinary extensions.

## 19.2 F* and OCaml

Continue to provide the trusted implementation, extraction, verification, parser, runtime, protocol, and native engine foundation where appropriate.

Ordinary users should not need to learn these languages to use or extend CENTL at the common level.

## 19.3 Python

Python should be supported as an interoperability, prototyping, data, and scientific ecosystem bridge.

CENTL should not become “Python with a natural-language wrapper,” but ignoring the Python scientific ecosystem would unnecessarily restrict users.

Example future interactions:

```text
BUILD> I have a Python package for reading this telescope's data. Make it available inside CENTL.
```

```text
BUILD> Prototype this algorithm using Python first.
```

Later:

```text
BUILD> The prototype works. Move the critical numerical part into a native CENTL backend.
```

## 19.4 Other native languages/backends

If a user's requirement cannot reasonably be implemented in native CENTL, the system should eventually be able to scaffold or integrate an appropriate native extension implementation.

OCaml, Rust, C, or another suitable implementation language may be appropriate depending on the task and trust boundary.

Example:

```text
BUILD> I need a very fast sparse matrix backend.
```

A future CENTL system could determine that a native backend is appropriate, generate the adapter and tests, build it, and record that the result crosses into a native-extension trust boundary.

The user need not necessarily know the implementation language in advance.

---

# 20. Local workspaces

Self-extension should use an explicit local workspace model instead of casually modifying the installed upstream package in place.

A conceptual workspace layout may look like:

```text
~/.centl/workspaces/default/
  extensions/
  modules/
  tests/
  data/
  config/
  history/
  packages/
  generated/
```

Exact paths and formats remain an implementation decision.

The important semantic model is:

- upstream installation remains identifiable;
- local changes are layered on top;
- extensions can be enabled/disabled;
- workspace state has explicit revisions;
- system behavior can be traced back to upstream plus local changes.

Users should eventually be able to ask:

```text
BUILD> Show me everything I've changed from upstream.
```

CENTL should be able to answer precisely.

---

# 21. Self-modification must be inspectable and reversible

Every applied system extension or modification should carry provenance and be reversible where technically possible.

Potential interaction commands include:

```text
:changes
:extensions
:inspect NAME
:disable NAME
:enable NAME
:remove NAME
:undo
```

Natural-language equivalents should also work:

```text
BUILD> Undo the unit changes we made earlier.
```

```text
BUILD> Show me everything I've changed from upstream.
```

```text
BUILD> Disable my experimental turbulence package.
```

Changes should have identifiable revisions so that a user can understand which state produced a result.

---

# 22. Assurance levels for user extensions

A self-extensible system must never imply that every local extension has the same assurance as the verified CENTL core.

CENTL should develop an explicit assurance model.

Possible categories include:

```text
verified CENTL core
verified CENTL extension
validated native extension
locally tested CENTL extension
external backend
experimental local extension
unverified/generated extension
```

The exact names and hierarchy remain to be designed.

Results should retain relevant assurance metadata.

For example:

```text
Result: ...

Source:
  local extension: turbulence-v1

Assurance:
  dimension checked
  deterministic
  37 local tests passed
  not formally verified
  uses an approximate external numerical backend
```

Freedom and honesty must coexist.

CENTL's existing principle—never manufacture numerical certainty—should extend naturally into **never manufacture implementation certainty**.

---

# 23. Extension planning should understand existing capabilities

Before adding new code, BUILD mode should inspect what upstream and the active workspace already provide.

The system should answer questions such as:

- Is this capability already implemented?
- Can existing operations be composed to satisfy the request?
- Is only an alias or wrapper needed?
- Does the requested behavior require a new mathematical domain?
- Does it require a new physics operation?
- Does it require a native backend?
- Does it cross an uncertainty/provenance boundary?
- Does it require new verification obligations?
- Is the requested operation incompatible with current trust guarantees?

This helps prevent duplicate systems and unnecessary complexity.

---

# 24. Modifying CENTL internals from within CENTL

Long term, users should be able to ask CENTL to extend or modify CENTL itself, including deeper engine behavior.

Examples:

```text
BUILD> Add milligrams to the unit system.
```

This may be handled declaratively.

A deeper example:

```text
BUILD> Make the equation solver support this new class of equations.
```

This may require changes to parser/runtime/solver code, tests, documentation, and possibly verification obligations.

CENTL should distinguish between levels of modification.

An initial progression should be:

1. declarative local extensions;
2. native CENTL language modules/packages;
3. controlled external adapters;
4. generated native extension modules;
5. generated upstream/core patches with full engineering validation.

For core implementation changes, the intelligent layer may generate a patch and implementation plan, but the same quality gates used by upstream development must remain applicable:

- parsing/build validation;
- F* verification where relevant;
- OCaml/native tests;
- differential tests;
- hardening/adversarial tests;
- documentation updates;
- compatibility checks;
- explicit trust-boundary review.

Self-modification must not become a mechanism for bypassing CENTL's engineering standards.

---

# 25. Preparing downstream work for upstream contribution

Downstream freedom should coexist naturally with upstream collaboration.

A future user should be able to request:

```text
BUILD> Prepare this extension for upstream contribution.
```

CENTL could then:

- isolate the relevant workspace changes;
- identify upstream compatibility concerns;
- run appropriate quality gates;
- generate or update tests;
- generate documentation;
- identify unverified assumptions;
- prepare a branch/patch/commit set;
- summarize the change for human review.

Publishing upstream remains the user's choice.

---

# 26. Mathematics and physics remain privileged reference domains

The move toward a general self-extensible computational system does not demote mathematics or physics.

They remain the strongest built-in demonstration of the CENTL philosophy:

- exact-first computation;
- explicit approximation bounds;
- mathematical contracts;
- physical dimensions;
- deterministic execution;
- explicit unsupported domains;
- structured evidence;
- verification where admitted;
- reproducibility.

The recommended conceptual hierarchy is:

## Layer 1 — Verified computational kernel

Exact arithmetic, rigorous approximation, proof-backed invariants, core mathematical semantics, limits, and foundational trust boundaries.

## Layer 2 — Scientific engines

Mathematics, CENTL Physics, and future built-in authoritative domains.

## Layer 3 — Extensible CENTL environment

User programs, packages, domain modules, workspace extensions, external adapters, custom interfaces, and downstream capabilities.

## Layer 4 — CENTL-SCi interaction intelligence

Natural-language interpretation, normalization, typo recovery, clarification, live suggestion, explanation, construction, modification, system navigation, and extension planning.

Math and physics are therefore both first-class applications and trusted foundations for the broader system.

---

# 27. CLI first; GUI later without architectural rewrite

CENTL remains CLI-first.

The terminal is the reference interface because it is:

- scriptable;
- local;
- lightweight;
- transparent;
- reproducible;
- accessible over SSH;
- compatible with scientific workflows;
- straightforward to automate.

A graphical environment is not excluded.

The architecture should ensure that future interfaces do not require a second interpretation engine.

Structured internal outputs should allow future clients such as:

```text
CLI
TUI
desktop GUI
web interface
editor extension
notebook integration
```

to consume the same:

- interpretation results;
- suggestions;
- clarification candidates;
- history records;
- explanation/provenance;
- extension plans;
- workspace state;
- execution evidence.

---

# 28. Proposed interaction architecture

A target architecture is:

```text
                         CENTL-SCi
                            │
                 ┌──────────┴──────────┐
                 │ Interaction Engine │
                 └──────────┬──────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
 spelling/error       live completion       history/
   recovery           + shadow hints         recall
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                     Intent Router
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
       MATH               PHYS              HYBRID
         │                  │                  │
         └──────────────────┼──────────────────┘
                            │
                 clarification engine
                            │
                      validated IR
                            │
             ┌──────────────┴──────────────┐
             │                             │
           CENTL                     CENTL Physics
             │                             │
             └──────────────┬──────────────┘
                            │
                   structured evidence
                            │
              ┌─────────────┼─────────────┐
              │             │             │
            answer      explanation      JSON
```

BUILD mode extends the interaction path:

```text
English construction intent
          │
          ▼
  extension/change planning
          │
          ▼
   structured change IR
          │
          ▼
 CENTL language / adapter / native patch
          │
          ▼
validate / test / verify / build
          │
          ▼
     local workspace
```

---

# 29. Model policy

The solution to weak interaction must not be “put a larger LLM in front of everything.”

The preferred routing order remains:

1. deterministic normalization;
2. deterministic intent recognition where safe;
3. grammar-aware extraction;
4. deterministic candidate recovery;
5. clarification where meaning is incomplete or ambiguous;
6. local semantic model only where genuine language understanding is required;
7. strict validation of model output;
8. deterministic CENTL/CENTL Physics execution or system-change tooling.

Mechanically recoverable scientific syntax belongs in deterministic Tier 0.

The semantic model should become responsible for less boilerplate over time, not more.

For self-extension, the model may help infer architecture, generate source, or propose changes, but it does not bypass validation, tests, proof obligations, or trust metadata.

---

# 30. Human-variation and abuse corpus

Interaction robustness should become a release-gated property.

A large test corpus should be built from prompts written the way real people write, including people who did not build CENTL.

Each supported operation should have variations covering:

- formal wording;
- casual wording;
- terse wording;
- polite wording;
- Unicode notation;
- missing spaces;
- extra spaces;
- capitalization variation;
- punctuation variation;
- harmless misspellings;
- alternative verbs;
- mobile/phone-style text;
- explicit units;
- spelled-out units;
- abbreviated units;
- equivalent equation forms;
- incomplete but recoverable requests;
- genuinely ambiguous requests;
- adversarial near-misses that must not be autocorrected.

A useful initial target is **250–500 prompts**, growing over time.

A proposed release criterion for already-supported deterministic domains is:

> **At least 95% successful interpretation or useful clarification for human-variation prompts whose intended operation is already supported by CENTL.**

This metric measures interaction success, not mathematical correctness. Mathematical correctness remains separately tested by CENTL's existing verification, conformance, differential, and native test systems.

---

# 31. Explanation and suggestion tests

The interaction corpus should explicitly test that:

- a misspelling does not silently alter mathematical data;
- ambiguous corrections trigger clarification;
- safe lexical corrections are offered consistently;
- shadow suggestions never invent numerical values;
- Tab completion does not commit unsafe structural guesses;
- explanation output matches structured execution evidence;
- unsupported domains are described precisely;
- existing capabilities are reused before new extension work is proposed;
- BUILD mode identifies trust-boundary changes;
- history recall preserves expected input ordering;
- mode changes alter interpretation bias but not mathematical semantics.

---

# 32. Immediate implementation milestone: CENTL-SCi v0.0.2

The next major CENTL-SCi milestone should focus primarily on **Interaction Intelligence and Robust Scientific Input**, rather than racing immediately into broad new mathematical domains.

Recommended implementation order:

## Phase A — Shared terminal foundation

1. Extract the existing CENTL terminal editor into shared reusable modules.
2. Give CENTL-SCi Up/Down input history and durable history.
3. Give CENTL-SCi cursor-aware editing and current completion functionality.
4. Preserve simple canonical-input fallback for unsupported terminals/platforms.

## Phase B — Explicit modes

5. Add MATH, PHYS, HYBRID, and BUILD mode state.
6. Make HYBRID the default scientific mode.
7. Make mode visible in the prompt.
8. Add mode commands and startup flags.

## Phase C — Input intelligence

9. Add Unicode and lexical normalization.
10. Add spelling detection and conservative correction candidates.
11. Introduce structured intent routing.
12. Add deterministic synonym/phrase families.
13. Add bounded candidate recovery.
14. Add first-class clarification results.
15. Replace generic unsupported responses with actionable diagnostics wherever possible.

## Phase D — Completion intelligence

16. Add context-sensitive Tab completion.
17. Add shadow/ghost suggestions.
18. Separate safe lexical completion from noncommitted structural suggestions.
19. Make completion mode-aware and grammar-aware.
20. Include session definitions, units, constants, extensions, and available operations in completion candidates.

## Phase E — Explanation and recall

21. Add `--explain` and `:explain on/off`.
22. Generate explanations from structured evidence only.
23. Add explicit result-recall commands such as `:last` / `:results` / `:recall` as appropriate.
24. Keep Up/Down semantics focused on user input recall.

## Phase F — Robustness gate

25. Build the large human-variation corpus.
26. Add typo and ambiguity adversarial cases.
27. Gate release on interaction-success criteria for already-supported domains.

These phases should be considered the core of the v0.0.2 interaction milestone.

---

# 33. Next capability expansion after interaction robustness

Once the interaction layer is robust, CENTL-SCi should expose more of what CENTL already knows how to do before adding unrelated breadth.

High-value candidates include:

- differentiation;
- exact polynomial integration;
- definite polynomial integration;
- substitution;
- simplification;
- expansion/factoring;
- rigorous approximation;
- verification;
- geometry primitives;
- sequences and recurrences;
- physical constant lookup;
- typed basic mechanics;
- selected particle simulation operations.

The goal is to reduce the gap between the underlying engine capability and the natural-language interface capability.

---

# 34. First natural-language mechanics expansion

CENTL Physics already supports more mechanics than the current CENTL-SCi Problem IR exposes.

After the interaction milestone, a good first typed mechanics class should be deliberately narrow and strongly specified, such as uniform-gravity particle mechanics.

A user should be able to describe mass, initial position, initial velocity, acceleration/gravity, timestep, and duration/steps naturally.

CENTL-SCi should produce a typed request.

CENTL Physics should remain responsible for dimensional checks and deterministic evolution.

The human explanation must distinguish a discrete integrator result from an analytic continuous-time solution.

---

# 35. Self-extension implementation roadmap

Self-extension should begin as a first-class architectural concern even if the deepest functionality arrives incrementally.

Recommended sequence:

## Stage 1 — Workspace and declarative extension foundation

- define workspace identity and revision model;
- define extension manifest format;
- allow local functions, aliases, units, formulas, and other safe declarations;
- make extensions inspectable, disableable, and removable;
- record extension assurance metadata;
- preserve upstream/local separation.

## Stage 2 — Native CENTL package/module language

- expand the existing language toward modules/packages;
- support richer reusable scientific constructs;
- support tests and assertions as package metadata;
- expose package capabilities to completion and help systems.

## Stage 3 — English-to-CENTL construction

- add structured programming/change IR;
- generate native CENTL definitions/modules from ordinary-language requests;
- validate before applying;
- expose proposed changes to explanation/inspection tools;
- support iterative refinement through bounded construction state.

## Stage 4 — External adapters

- define controlled extension interfaces;
- support Python integration where useful;
- record external runtime and dependency provenance;
- prevent external code from masquerading as verified core functionality.

## Stage 5 — Native generated extensions

- permit generated OCaml/Rust/C/etc. extension modules where justified;
- build through controlled toolchains;
- generate tests;
- expose clear trust metadata;
- isolate extension failures from the core where practical.

## Stage 6 — Core modification assistance

- allow users to request deeper changes to their own downstream CENTL;
- generate patch plans and implementation changes;
- run full validation gates;
- retain reversible workspace/system revisions;
- support preparing validated subsets for upstream contribution.

---

# 36. Safety and trust requirements for self-extension

Self-extension must remain compatible with the project's honesty guarantees.

Required principles:

1. A generated change is not automatically trusted.
2. A local extension must not silently alter the reported assurance of core operations.
3. Exactness claims must still originate from the authoritative computation path.
4. External approximate backends must be identified as such.
5. Generated code must pass the validation appropriate to its layer before activation.
6. Local changes should be attributed to a workspace revision/extension identity.
7. The user must be able to inspect what changed.
8. The user must be able to disable or remove local extensions.
9. Upstream files should not be casually mutated as the ordinary extension mechanism.
10. A user should be able to determine how their system differs from upstream.
11. Machine-generated explanations must be grounded in structured evidence.
12. The semantic model must never become a hidden second mathematical or physics evaluator.

---

# 37. What should not happen

The project should avoid several tempting but harmful shortcuts.

## Do not make CENTL-SCi a generic chatbot

Scientific clarification and bounded construction state are useful. Unbounded conversational behavior is not the primary product.

## Do not solve parser weakness by requiring a large model

Common mathematical language, notation, aliases, completion, and typo recovery should be deterministic whenever practical.

## Do not make Python the identity of CENTL

Python interoperability is valuable, but CENTL should retain its own language and trust model.

## Do not make the native CENTL language the only legal downstream implementation mechanism

Users must be allowed to go beyond the upstream language's expressiveness.

## Do not silently “fix” mathematical data

Never autocorrect uncertain numbers, signs, operators, assumptions, variables, or physical quantities.

## Do not present generated extensions as verified core functionality

Assurance and provenance must remain visible.

## Do not build GUI-specific intelligence

The intelligence belongs in structured core interaction services so future interfaces can reuse it.

---

# 38. Product success criteria

The long-term system is succeeding when a user can:

1. Open CENTL-SCi without studying documentation.
2. State a supported math or physics problem naturally.
3. Make ordinary spelling or notation mistakes without hitting a dead end.
4. Receive useful clarification when a statement is incomplete.
5. See context-sensitive suggestions while typing.
6. Use Tab to accept safe completions.
7. Recall previous inputs through normal terminal history behavior.
8. Ask why a result was produced and receive an evidence-grounded explanation.
9. Switch explicitly between math, physics, hybrid, and build-oriented work.
10. Ask CENTL to create a new function or domain capability in ordinary English.
11. Inspect the proposed extension and its assurance level.
12. Apply the extension to a local workspace.
13. Use the new capability immediately.
14. Ask how the local system differs from upstream.
15. Disable, remove, revise, or undo local modifications.
16. Integrate external tools when native CENTL is insufficient.
17. Build a downstream CENTL that grows beyond the upstream project's original scope.
18. Keep that work private or prepare selected parts for upstream contribution.

The system should help the user accomplish the task rather than force the user to learn the internal implementation first.

---

# 39. Working statement of direction

CENTL begins from an exact-first mathematical and physical foundation, but its longer-term purpose is larger:

> **CENTL should be a computational environment that belongs to the person running it.**
>
> It should understand what the user is trying to accomplish, help correct and complete imperfect input, explain what it did, rigorously execute what it can justify, and help the user extend the system when the required capability does not yet exist.
>
> The upstream project provides the foundation. It does not define the ceiling.
>
> Mathematics and physics remain first-class trusted domains. Downstream users may build whatever additional systems, sciences, tools, workflows, interfaces, or computational domains they need.
>
> A user should be able to grow CENTL from inside CENTL itself.

That is the intended meaning of:

> **Free for science.**

---

# 40. Signature

Recorded for project memory, architecture, and implementation planning.

**Chase Bryan**  
**Founder of the Free Computation Foundation**

August 9, 2026 — 10:18 PM Central Time  
America/Chicago (CDT / UTC-05:00; requested as CST)
