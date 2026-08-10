# CENTL-SCi

Status: active development toward **CENTL-SCi `v0.0.2-Caramels`**. This document describes the Caramels development branch; it is not a claim that the release has been tagged or published.

**CENTL-SCi means Specific CENTL Interpreter.** It is developed as part of CENTL under the Free Computation Foundation.

> Free for science.

CENTL-SCi is a local interaction and interpretation layer for mathematics, physics, and user-owned CENTL extension. It is not a general-purpose chatbot and it is not a second mathematical or physics evaluator.

Its scientific job is to interpret a problem, produce a validated representation, dispatch that representation to CENTL's deterministic machinery, and present only what the resulting evidence justifies.

Its BUILD job is different: help the user inspect, extend, modify, and own their downstream CENTL environment while keeping local/generated/external assurance visibly separate from verified core assurance.

## Caramels interaction model

Caramels exposes four explicit modes:

```text
MATH>    mathematics-first interaction
PHYS>    physics-first interaction
HYBRID>  mixed scientific interaction; default
BUILD>   downstream programming and system extension
```

Switch mode inside the REPL with:

```text
:mode math
:mode physics
:mode hybrid
:mode build
```

The terminal interaction layer provides:

- cursor-aware editing;
- Up/Down and Ctrl-P/Ctrl-N history navigation;
- Home/End and Ctrl-A/Ctrl-E movement;
- backspace/delete editing;
- durable input history unless disabled;
- mode-aware Tab completion;
- noncommitted ghost/shadow suggestions;
- Ctrl-C interruption and Ctrl-D/EOF exit;
- canonical input fallback outside a compatible terminal.

A shadow suggestion is not part of submitted input until the user explicitly accepts it. Structural suggestions that would invent missing scientific content are display-only.

## Input recovery and interpretation

Before model inference, Caramels applies conservative deterministic normalization:

- whitespace normalization;
- `×` -> `*`;
- `÷` -> `/`;
- Unicode minus -> `-`;
- `²` / `³` -> `^2` / `^3`;
- `½` -> `1/2`;
- `π` -> `pi`;
- selected safe typo repair;
- ordinary polite wrappers such as `please`, `could you`, and `can you`;
- a small set of unambiguous intent canonicalizations such as roots/zeros and unit-conversion phrasing.

Identifiers and user expressions are not globally lowercased.

Interpretation order is:

```text
input
  -> normalization
  -> deterministic intent classification
  -> deterministic canonicalization/recovery
  -> Tier-0 deterministic interpreter
  -> useful clarification if required fields are missing
  -> local semantic model only when semantic interpretation is genuinely required
  -> validated Problem IR
  -> authoritative CENTL / CENTL Physics execution
```

The semantic model remains untrusted. Model output is validated before lowering and cannot confer mathematical truth or verified-core status.

## Scientific Problem IR

Caramels currently has typed deterministic paths for:

| Problem class | Domain | Execution |
| --- | --- | --- |
| `exact_expression` | mathematics | CENTL `compute` |
| `polynomial_equation` | mathematics | CENTL `solve` |
| `unit_conversion` | physics | typed CENTL Physics conversion |
| `physical_constant` | physics | typed CENTL Physics exact defining/conventional constant lookup |
| `uniform_gravity_particle` | physics | typed CENTL Physics `simulate_particle` |
| `unsupported` | either/outside scope | no fabricated computation |

The deterministic natural-language surface also lowers supported differentiation, integration, substitution, simplification, expansion, factoring, and approximation requests into existing native CENTL expressions instead of creating separate implementations.

The optional local-model schema now admits the same Caramels constant and uniform-gravity classes. Model output still passes through the independent typed IR validator before execution.

## Deterministic approximation

Caramels lowers explicit approximation requests into CENTL's existing bounded-enclosure operation rather than inventing a second numerical evaluator.

Examples:

```text
MATH> approximate pi
MATH> approximate sqrt(2) to 30 significant digits
```

These lower to native forms such as:

```text
approx(pi)
approx(sqrt(2), 30)
```

CENTL remains responsible for the numerical contract: requested digits must be justified by the returned enclosure, and unresolved precision remains visible rather than being replaced by guessed decimal output.

## Exact physical constants

Caramels exposes the deliberately narrow exact CENTL Physics constant catalog:

- speed of light in vacuum, `c`;
- Planck constant, `h`;
- elementary charge, `e`;
- Boltzmann constant, `k_B`;
- Avogadro constant, `N_A`;
- standard acceleration of gravity, `g0`.

These are defining or conventional exact values already represented by CENTL Physics with provenance. Natural-language requests for those constants use the deterministic fast path and do not require a model.

Measured constants are not silently promoted to exactness. For example, a request for the Newtonian gravitational constant `G` is explicitly refused by this route because CENTL does not yet have first-class measured-uncertainty/provenance semantics for that catalog entry.

## Narrow mechanics class

Caramels exposes a first narrow natural-language mechanics class: a particle under explicit uniform gravity.

Example:

```text
PHYS> simulate a particle with mass 2 kg, position (0,0,10) m, velocity (1,0,0) m/s, gravity (0,0,-10) m/s^2, dt 1/10 s, steps 10
```

All required physical data must be supplied by the user:

- mass;
- initial position;
- initial velocity;
- gravity vector;
- timestep;
- number of steps.

CENTL-SCi does not invent missing initial conditions or a default gravity constant for this request class. Missing fields produce clarification.

The request lowers into the existing deterministic CENTL Physics `simulate_particle` protocol using its uniform-gravity force model. Human/details output identifies the discrete symplectic-Euler integrator. A discrete integration result is not presented as the analytic continuous-time trajectory.

## Answer-first output

The default scientific output stays compact:

```sh
centl-sci 'What is 0.1 plus 0.2?'
```

```text
3/10
```

```sh
centl-sci 'Solve x squared minus 5x plus 6 equals zero.'
```

```text
x = 2 or x = 3
```

Exact values remain exact. Approximation qualifications remain visible. If CENTL cannot establish a result, the presenter does not manufacture one.

## Evidence explanation

`--details` adds concise scientific metadata.

`--explain` adds a structured evidence view grounded in the actual interpretation/execution path. It records information such as:

- normalized input;
- mode;
- deterministic intent classification;
- typed IR domain, problem class, and operation;
- interpreter-introduced assumptions;
- interpreter path;
- authoritative executor;
- the executor request actually sent to CENTL/CENTL Physics;
- runtime status;
- workspace revision where available;
- execution/evidence events;
- resulting value/text.

The explanation renderer does not ask a language model to invent a derivation after the fact.

`--json` preserves the structured machine result.

`--json` is mutually exclusive with the human details/explanation views.

## Result recall

Input history and result recall are separate concepts.

The REPL includes session-scoped structured result records:

```text
:last
:result
:results
:recall N
```

A result record keeps the original input, normalized input, mode, intent, rendered result/details, and workspace revision where available.

## BUILD mode

BUILD is the first-class downstream extension surface.

Examples of direct native CENTL definitions:

```text
BUILD> create function kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2
BUILD> create value tau = 2*pi
BUILD> modify function kinetic_energy(mass, velocity) = mass * velocity^2 / 2
```

Caramels also implements a first English-to-CENTL generation grammar:

```text
BUILD> create a function named kinetic_energy that takes mass and velocity and computes 1/2 * mass * velocity^2
BUILD> create a value named tau equal to 2*pi
BUILD> modify a function named square that takes x and returns x^2
```

The flow is deliberately layered:

```text
English BUILD request
  -> structured change-request IR
  -> native CENTL source generation
  -> existing CENTL parser validation
  -> reversible workspace snapshot
  -> source + manifest write
  -> local workspace revision
  -> reload enabled native definitions into the downstream CENTL session
```

Generated text does not bypass the existing parser boundary.

## Reuse before invention

Generic BUILD planning searches a capability inventory before proposing new machinery. That inventory includes existing mathematical/physics surfaces, Caramels runtime mechanisms, downstream extensions, and local packages.

Useful inspection forms include:

```text
BUILD> capabilities
BUILD> show capability integration
BUILD> validate NAME
BUILD> validate package NAME
BUILD> audit workspace
```

The inventory includes reusable Caramels capabilities such as workspace audit, structural extension validation, package validation, reversible workspace portability, and English-to-CENTL extension generation.

The goal is to answer questions such as:

- Does CENTL already solve this class?
- Is there an existing deterministic physics operation?
- Is there already a local extension with a related name?
- Can the request be expressed as a native CENTL definition rather than a new backend?
- Does the request genuinely need an external or native extension boundary?

BUILD planning currently distinguishes:

1. declarative/local extension;
2. native CENTL module/package;
3. controlled external adapter;
4. generated native extension;
5. downstream core patch;
6. upstream contribution preparation.

Core-patch-classified requests create persistent downstream JSON and Markdown plan artifacts. Planning does not silently edit or publish trusted core source.

## User-owned workspace

The default downstream workspace is:

```text
~/.centl/workspaces/default/
```

Override it with `CENTL_WORKSPACE`.

Layout:

```text
workspace.json
extensions/
modules/
tests/
data/
config/
history/
packages/
generated/
```

`workspace.json` identifies the environment as user-owned downstream state and records the rule that local extensions never silently inherit verified-core assurance.

Each workspace mutation increments a local revision and records a JSONL revision event.

## Extension manifests and assurance

Extension manifests record, where applicable:

- name and kind;
- enabled/disabled state;
- source;
- summary;
- provenance;
- dependencies;
- generated/declared tests;
- workspace revision;
- assurance category;
- timestamp.

Current assurance labels include distinctions for verified extensions, validated native extensions, locally tested extensions, external backends, experimental local extensions, and unverified generated extensions.

A locally generated capability is never silently presented as verified CENTL core.

`validate NAME` performs structural checks appropriate to the extension kind. Structural validation does not upgrade assurance to verified core.

Native extensions are revalidated before activation. A missing, unparsable, non-definition, or non-native source cannot be enabled through the native CENTL definition loader.

## Packages

Local packages group downstream extensions without creating a separate package-level assurance claim.

Package validation reports every member's:

- presence/missing state;
- enabled/disabled state;
- extension kind;
- individual assurance label.

Package composition never promotes member assurance.

## Inspect, disable, remove, undo

BUILD exposes lifecycle foundations for downstream ownership:

```text
show workspace
show extensions
inspect NAME
disable NAME
enable NAME
remove NAME
undo
```

The REPL also exposes colon forms for the common inspection/lifecycle operations implemented by the current app.

Mutating operations create a reversible snapshot first. Snapshot payloads cover manifests, native modules, packages, tests, data, and generated extension scaffolds while deliberately excluding the revision/history ledger, workspace identity/configuration, and snapshot store itself.

Removal archives local files instead of silently pretending the extension never existed.

## Workspace portability

Caramels implements a revision-stamped downstream workspace bundle format.

A safe read-only export is exposed through BUILD:

```text
BUILD> export workspace
BUILD> export workspace /path/to/bundle
```

A validated reversible import is also live through BUILD:

```text
BUILD> import workspace /path/to/bundle
```

The bundle includes downstream extension manifests, native modules, packages, tests, data, and generated scaffolds. It excludes verified core, history, undo snapshots, prior exports, and local workspace identity/configuration.

Import validates bundle metadata, rejects symlinks/unsupported filesystem objects, validates extension manifests and structural extension checks, checks package membership and activation policy, and snapshots the existing downstream workspace **before mutation**. Only then are downstream surfaces replaced.

A successful BUILD import returns `changed=true`; the existing CENTL-SCi app path then rebuilds the active downstream core session and reloads enabled native definitions immediately. The prior downstream state remains available through `undo`.

Verified CENTL core, workspace identity, configuration, and history are not replaced by import.

## External and native extension scaffolds

Caramels can generate **inactive** first-pass scaffolds:

```text
BUILD> scaffold python adapter telescope_reader astropy
BUILD> scaffold native extension sparse_backend sparse-matrix-solver
```

A scaffold includes:

- machine-readable `scaffold.json` contract;
- JSONL-over-stdio boundary declaration;
- inactive implementation source/stub;
- test/validation placeholder;
- manifest provenance;
- explicit assurance category;
- no automatically granted network/filesystem privilege;
- disabled activation state.

Scaffold generation is not successful validation and does not make external/native code verified core.

## Upstream contribution preparation

A downstream user can prepare a local review artifact with:

```text
BUILD> prepare upstream contribution
```

The artifact records the workspace revision, current local extension inventory, assurance/source information, and review work required before publication.

This command does **not** create a Git branch, commit, push, pull request, or publication. Upstream publication remains an explicit user choice.

## Contribution and privacy model

Scientific contribution capture remains opt-in and **off by default**.

- `diagnostics` captures metadata/errors without raw problem text;
- `examples` may capture raw problem text only after explicit opt-in;
- no contribution mode performs hidden network upload;
- exported data is intended for user review before sharing.

BUILD workspace state is local user-owned data and is conceptually separate from model-training contribution capture.

## Platform priority

**Linux is the reference platform for Caramels development.**

The first implementation pass prioritizes complete end-to-end Linux functionality. macOS/Windows portability, exhaustive hardening, and non-blocking platform-specific problems are subsequent passes unless a defect reveals a shared correctness or trust-boundary problem.

## Human-variation gate

Caramels includes a generated human-variation corpus in the requested 250–500 range. The current corpus contains **435 prompt variants** spanning mathematics, approximation, physics, exact constants, measured-constant refusal, mechanics, incomplete requests, and BUILD-oriented input.

The corpus varies:

- capitalization;
- whitespace;
- punctuation;
- polite wrappers;
- selected typos;
- Unicode mathematical symbols;
- complete vs incomplete requests.

The test surface includes a target of at least **95% useful interpretation or useful clarification** on this supported-operation corpus.

## Local model boundary

A local model remains optional for requests that genuinely need semantic inference. Deterministic Tier-0 requests do not require a model.

The reference local model boundaries remain `llama-cli` and loopback `llama-server`, configured explicitly. The Caramels model schema/grammars admit exact expression, polynomial equation, unit conversion, exact physical constant, explicit uniform-gravity particle, and unsupported classes. The model cannot select arbitrary shell commands, declare its own output mathematically authoritative, or silently promote external/generated code into verified core.

## Development sequence for `v0.0.2-Caramels`

Caramels is intentionally being developed in passes:

1. **Breadth pass:** implement the full interaction/self-extension vision across the repository on Linux, accepting rough edges while the architecture is still being connected end to end.
2. **Improvement pass:** improve natural-language coverage, terminal ergonomics, structural completion, package/adapter behavior, generated tests, capability reuse, documentation, and implementation quality.
3. **Repair/hardening passes:** systematically address build/CI failures, edge cases, invariant violations, performance, security hardening, and cross-platform portability.

A failing non-blocking check does not define the sequencing of the breadth pass. A failure that prevents further implementation or invalidates the trust boundary does.

The governing rule remains:

> The interpreter may infer intent. CENTL computes and verifies scientific results. The user owns the downstream system and can extend it without silently changing what “verified core” means.
