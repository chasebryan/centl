# CENTL Scientific Domains: Scheme and Implementation Plan

Status: strategic implementation plan.

This document defines the full scientific expansion of CENTL across:

1. Mathematics
2. Physics
3. Chemistry
4. Materials science
5. Biology
6. Computer science
7. Earth and planetary science

The order matters. CENTL should grow as one exact-first scientific system, not
as seven unrelated calculators. Each domain must reuse the mathematical kernel,
typed quantities, provenance model, result schemas, and verification boundary.

## 1. Product scheme

```text
                         CENTL-SCi
                  interpretation and composition
                              |
       +----------------------+----------------------+
       |                      |                      |
  domain engines         shared scientific       evidence /
                         foundations              provenance
       |                      |                      |
 Math -> Physics -> Chemistry -> Materials       Units
       |          |             |                 Constants
       +----------+-------------+----------------- Models
                  |                               Uncertainty
             Biology                         Verification
                  |
       Computer Science <-> Earth Science
```

The domain engines are authoritative. CENTL-SCi may translate natural language
into typed requests, compose domain operations, and explain results, but it may
not supply missing values, silently choose a model, or replace a verified
domain result.

## 2. Governing rules

Every public capability must satisfy these rules:

- Exact inputs produce exact outputs whenever the admitted model permits it.
- Approximate, measured, empirical, and uncertain values retain their status.
- Units, dimensions, domains, assumptions, and model choices are explicit.
- Every result has a stable machine representation and provenance record.
- Conservation laws, identities, invariants, or certificates are checked
  independently wherever applicable.
- Unsupported, ambiguous, underdetermined, or out-of-domain work is refused or
  returned as an explicit unresolved result.
- Human CLI, JSON Lines, MCP, graphical Lab, and CENTL-SCi all call the same
  authoritative implementation.
- New syntax follows a capability; syntax is not considered an implementation.

## 3. Shared platform work

Before adding more domain breadth, establish the following shared layers.

### 3.1 Value and quantity model

Extend the existing exact scalar and physics quantity model into a common
scientific value algebra:

```text
exact_integer | exact_rational | exact_algebraic | exact_symbolic
interval      | measured       | uncertain      | empirical
vector        | matrix         | tensor         | finite_set
structured_record | unresolved
```

Each value carries its unit or dimension where relevant, plus provenance,
precision/interval information, assumptions, and model identity.

### 3.2 Model registry

Introduce versioned model descriptors for calculations such as ideal gas,
Newtonian mechanics, Arrhenius kinetics, linear elasticity, Mendelian
inheritance, and plate motion. A model descriptor records:

- name and version;
- accepted inputs and units;
- assumptions and validity range;
- exact versus approximate operations;
- required data sources;
- verification checks;
- known non-goals.

### 3.3 Scientific data and provenance

Create one provenance system for constants, tables, observations, simulations,
and user-supplied measurements. At minimum distinguish:

```text
defined | exact-derived | measured | interval | uncertain | empirical | inferred
```

Data packages must be content-addressed, versioned, license-aware, and
reproducible. A decimal literal must never become exact merely because it was
printed in a table.

### 3.4 Protocol and evidence schemas

Add common result fields:

```json
{
  "value": {},
  "resolution": {},
  "units": {},
  "model": {},
  "assumptions": [],
  "provenance": [],
  "evidence": [],
  "warnings": []
}
```

Domain-specific evidence may include atom conservation, dimensional balance,
energy residual, type-check certificate, mass balance, or geospatial closure.

### 3.5 Capability and refusal infrastructure

Every domain publishes capabilities, limits, supported models, and refusal
codes through the existing discovery and machine interfaces. Resource limits,
cancellation, deterministic ordering, malformed-input handling, and fuzz tests
are shared platform obligations.

## 4. Domain implementation tracks

Each track follows the same six-step pattern:

```text
contract -> kernel -> protocol -> CLI -> interpreter -> qualification
```

### Track A: Mathematics

Mathematics remains the foundational engine.

#### A1. Core exact mathematics

- rational, complex-rational, algebraic, polynomial, matrix, and tensor values;
- equations, inequalities, substitutions, differentiation, integration, sums,
  products, sequences, recurrences, and exact transforms;
- exact geometry, combinatorics, number theory, probability, and statistics;
- explicit symbolic residuals when a result is not admitted.

#### A2. Rigorous numerical mathematics

- interval/ball arithmetic and justified decimal rendering;
- adaptive precision and certified root isolation;
- rigorous linear algebra, optimization, ODE/PDE slices, and numerical error
  propagation;
- comparison tests against independent backends without treating them as
  authorities.

#### A3. Qualification gate

Every mathematical capability requires a value model, theorem or invariant
where practical, adversarial limits, deterministic JSON, CLI examples, and
explicit unsupported cases.

### Track B: Physics

Physics is the typed model layer over mathematics.

#### B1. Classical and foundational mechanics

- quantities, unit conversion, dimensional analysis, vectors, matrices;
- kinematics, Newtonian dynamics, momentum, energy, angular momentum;
- collisions, contact, constraints, and event stepping;
- explicit frame, sign convention, and initial-condition contracts.

#### B2. Fields, waves, and thermodynamics

- electromagnetism primitives;
- oscillators, waves, optics, and Cherenkov calculations;
- heat, work, entropy, idealized thermodynamic systems;
- exact defining constants with derived-constant provenance.

#### B3. Qualification gate

Every solver must expose dimensions, assumptions, conserved quantities, residuals,
stability limits, and failure behavior. Numerical simulation is never presented
as a proof of physical truth.

### Track C: Chemistry

Chemistry is the first applied domain built on physics quantities and exact
linear algebra.

#### C1. Exact symbolic chemistry

- element and isotope identities;
- nested formula parsing and atom counting;
- exact reaction parsing and integer/rational balancing;
- per-element conservation evidence.

#### C2. Stoichiometry and data-aware quantities

- moles, particles, mass, volume, concentration, dilution;
- limiting reagent, theoretical yield, percent yield;
- molar mass with measured/interval atomic-weight provenance;
- exact dimensional validation.

#### C3. Model-based chemistry

- ideal gases;
- thermochemistry and electrochemistry;
- equilibrium, acid/base, logarithmic chemistry, and simple kinetics;
- explicit standard-state, activity, temperature, and uncertainty contracts.

Ab initio chemistry, molecular dynamics, reaction prediction, and property
prediction remain separate future programs rather than hidden features.

### Track D: Materials science

Materials science should be the first new domain after chemistry because it
reuses the largest amount of existing physics and chemistry.

#### D1. Material identity and structure

- composition, phases, mixtures, stoichiometric compounds;
- crystal lattice and unit-cell representations;
- density, molar volume, porosity, and composition conversions;
- versioned material records with source provenance.

#### D2. Deterministic property models

- stress/strain and linear elasticity;
- thermal expansion and heat capacity;
- electrical and thermal conductivity;
- phase diagrams and lever-rule calculations;
- diffusion and simple transport laws.

#### D3. Qualification gate

Every property calculation must identify whether it is a definition, derived
quantity, measured value, fitted model, or extrapolation. Initial releases must
avoid claiming universal material-property prediction.

### Track E: Biology

Biology should follow the deterministic substrate work, with a clear separation
between exact structure and uncertain biological inference.

#### E1. Formal biological structures

- DNA/RNA/protein sequence alphabets and validation;
- complements, transcription, translation, codon tables, and reading frames;
- pedigree and genotype representations;
- population-count and compartment models.

#### E2. Quantitative biology

- dilution, concentration, growth, decay, and mass-balance models;
- enzyme kinetics and binding models under declared assumptions;
- Hardy-Weinberg and basic population genetics;
- deterministic compartment ODE slices with interval-aware outputs.

#### E3. Data and uncertainty boundary

Biological observations remain measured or uncertain. CENTL must show model
assumptions, confidence/interval information, parameter provenance, and model
residuals. It must not turn a sequence calculator into a diagnostic system or
present statistical association as causation.

### Track F: Computer science

Computer science is a particularly strong fit for CENTL because it extends the
verified mathematics and makes the trust model directly useful.

#### F1. Discrete and formal computation

- Boolean algebra, propositional logic, predicates, sets, relations;
- graphs, trees, automata, grammars, and finite-state machines;
- exact algorithms for sorting, paths, flows, matching, and counting;
- recurrence and complexity summaries with explicit bounds.

#### F2. Verification and security mathematics

- type checking and small-step semantics for a bounded language;
- SAT/CNF transformations and proof-producing decision procedures;
- modular arithmetic, hashing, signatures, and cryptographic primitives;
- invariant checking, model checking, and counterexample traces.

#### F3. Qualification gate

Results must distinguish “verified for the supplied finite instance” from
“proved generally.” External solver output may be evidence or a candidate, but
the CENTL certificate checker remains authoritative.

### Track G: Earth and planetary science

Earth science should come after the common geospatial, temporal, and uncertainty
foundations exist.

#### G1. Earth-system quantities

- coordinate reference systems and unit-safe geospatial quantities;
- time scales, calendars, rates, and coordinate transformations;
- elevation, distance, area, volume, and mass-balance calculations;
- atmosphere, hydrology, and basic energy-budget models.

#### G2. Geophysics and planetary models

- gravity and orbital calculations;
- seismic travel-time and layered-medium models;
- radiative balance and climate-box models;
- plate-motion vectors and tectonic geometry;
- planetary composition and simple interior models.

#### G3. Qualification gate

Every output must state coordinate system, epoch, datum, model resolution, data
source, and uncertainty. Maps and observational products must never imply that
interpolation is direct measurement.

## 5. Dependency and delivery order

```text
Math foundation
   |
Physics quantities and models
   |
Chemistry formulas + stoichiometry
   |
Materials science
   +------------------+
   |                  |
Biology          Computer science
   |                  |
   +--------+---------+
            |
   Earth / planetary science
```

The practical delivery order is:

1. Harden the shared value, provenance, model, evidence, and protocol layers.
2. Complete the current mathematics and physics capability backlog.
3. Finish Chemistry Phases 1–3: formulas, balancing, stoichiometry, and data
   provenance.
4. Add Chemistry Phases 4–5 only as explicit model-qualified slices.
5. Deliver Materials D1–D2 as the first new vertical domain.
6. Deliver Computer Science F1, then F2; it provides useful certificate and
   parser infrastructure for every later domain.
7. Deliver Biology E1, then E2–E3 with uncertainty-first semantics.
8. Deliver Earth G1, then G2 after geospatial and temporal contracts mature.
9. Add cross-domain composition recipes and CENTL-SCi workflows.
10. Qualify each domain independently before promoting a multi-domain release.

## 6. Repository scheme

The implementation should evolve toward this layout without a disruptive
rewrite:

```text
src/
  verified/                 F* foundations and extracted certificates
  math/                     exact and rigorous mathematics
  scientific/               shared quantities, units, provenance, models
  physics/                  typed physics kernels and solvers
  chemistry/                formulas, reactions, stoichiometry, data
  materials/                phases, structures, properties, transport
  biology/                  sequences, genetics, kinetics, populations
  computer_science/         logic, graphs, automata, certificates
  earth/                    geospatial, temporal, geophysical models
  protocols/                JSON Lines, MCP, capability and result schemas
  cli/                      thin domain command surfaces
tests/
  golden/                   canonical successful results
  refusal/                  explicit unsupported and invalid requests
  conservation/             domain invariants and balance checks
  provenance/               source and uncertainty behavior
  metamorphic/              cross-surface and algebraic properties
docs/
  domains/                  domain contracts and field guides
data/
  manifests/                versioned, hashed source datasets
```

The current flat OCaml module layout may remain during migration. The important
boundary is dependency direction: domain modules depend on shared foundations;
shared foundations never depend on domain-specific interpreters.

## 7. Milestones and exit criteria

### Milestone 0: shared scientific foundation

Deliver the common value/provenance/model/evidence schemas, capability
discovery, refusal taxonomy, and cross-surface test harness.

Exit: a synthetic calculation can preserve exact, measured, interval, and
uncertain values through CLI, JSON Lines, MCP, and CENTL-SCi without semantic
loss.

### Milestone 1: mathematics and physics platform

Close the highest-value exact math, rigorous approximation, units, vectors,
matrices, mechanics, and field-model gaps.

Exit: every supported result has exactness status, dimensions where applicable,
assumptions, limits, and machine-readable evidence.

### Milestone 2: chemistry vertical slice

Formula parsing, balancing, conservation evidence, stoichiometry, and provenance-
aware molar mass.

Exit: representative reactions pass native, CLI, JSON, MCP, golden, refusal,
fuzz, and conservation tests.

### Milestone 3: materials vertical slice

Composition, unit cells, density, phase fractions, linear stress/strain, and
thermal expansion.

Exit: a material record and a calculation can be reproduced from a pinned data
manifest and model version.

### Milestone 4: computer science vertical slice

Graphs, automata, logic transformations, bounded algorithms, and at least one
proof-producing checker.

Exit: certificate verification is independent of certificate generation and
counterexamples are rendered as structured traces.

### Milestone 5: biology vertical slice

Sequence operations, codon translation, conservation/counting, and simple
mass-balance or growth models with intervals.

Exit: exact sequence semantics and uncertain biological quantities are visibly
separated in every interface.

### Milestone 6: earth and planetary vertical slice

Coordinate/time foundations, geospatial measurements, gravity/orbit, and one
layered geophysical model.

Exit: coordinate system, epoch, datum, source, resolution, and uncertainty are
mandatory in machine and human results.

### Milestone 7: cross-domain composition

Add typed recipes such as:

- chemistry -> materials: composition to phase/property calculation;
- physics -> materials: stress and thermal response;
- chemistry -> biology: concentration and reaction inputs;
- physics -> earth: gravity, orbit, and energy-balance models;
- computer science -> all domains: verified data transforms and certificates.

Exit: composition is typed, provenance-preserving, deterministic, and refuses
incompatible or missing assumptions.

## 8. Testing and qualification matrix

Every domain must have:

- parser and canonicalization tests;
- exact arithmetic and dimensional tests;
- positive golden cases;
- malformed, unsupported, ambiguous, and underdetermined refusal cases;
- invariant/conservation/certificate tests;
- provenance and uncertainty propagation tests;
- deterministic JSON and MCP conformance tests;
- property-based and metamorphic tests;
- resource-limit, cancellation, and adversarial-depth tests;
- independent comparison tests where an external numerical backend is useful;
- documentation examples executed in CI.

Cross-domain releases additionally require:

- no duplicated evaluator logic across interfaces;
- stable capability discovery;
- reproducible data manifests;
- schema compatibility checks;
- security review of parsers, data loading, native bindings, and external
  solver boundaries;
- clear release notes listing supported models and deliberate non-goals.

## 9. What “complete” means

CENTL is not complete when it has a command for every school subject. It is
complete when each supported capability has:

1. a documented mathematical or scientific contract;
2. an authoritative implementation;
3. explicit exactness, uncertainty, and provenance semantics;
4. independent evidence or verification appropriate to the domain;
5. stable CLI and machine interfaces;
6. refusal behavior for requests outside the contract;
7. reproducible tests and data;
8. a field guide that makes the trust boundary understandable.

That definition preserves CENTL's central promise while allowing the system to
grow from an exact calculator into a coherent open scientific workbench.
