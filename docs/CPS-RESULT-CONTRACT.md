# CENTL CPS result contract

Status: design contract for planned Composition Predictive Simulation (CPS).

CENTL CPS is intended to evaluate proposed chemical compositions before physical
execution by combining exact chemistry, dimensioned physics, measured evidence,
certified approximation, and explicitly bounded predictive models. A CPS result
is a scientific dossier, not a single score.

## Governing rule

**Exact mathematics inside a declared model does not make the physical world
exact.**

Every reported field must carry a semantic class that tells the caller what kind
of claim CENTL is making. CPS must never collapse exact deductions, measured
quantities, model predictions, uncertainty intervals, and unavailable evidence
into one undifferentiated number.

The initial semantic classes are:

```text
exact              mathematically exact deduction from exact admitted inputs
defined            exact value fixed by definition
derived-exact      exact value derived only from exact/defined inputs
certified-approx   numerical enclosure with a stated mathematical guarantee
measured           observation or reference datum with experimental provenance
interval           bounded quantity whose interval is part of the evidence
uncertain          value accompanied by an uncertainty model or budget
model-derived      result of an explicitly named physical/chemical model
estimated          non-certified estimate with stated method and limitations
unknown            no admissible evidence supports a value
not-applicable     field does not apply to the admitted problem
unsupported-model  CPS has no justified model for the requested claim
```

`exact` is reserved. Decimal spelling alone never confers exactness.

## Proposed command surface

The planned executable is:

```sh
centl-cps
```

The first composition dialect should remain compact and typed:

```text
comp exam(...)
exact(...)
measured(...)
interval(...)
assume(...)
model(...)
```

Illustrative shape only:

```sh
centl-cps 'comp exam(A=2mol,B=1mol) measured(T=300K,P=1atm) model(ideal)'
```

The parser and execution semantics for this language are not implemented by this
document. No syntax is public merely because it appears as an example here.

## Required result sections

A complete CPS certificate should be able to represent the following sections.
A section that has no admissible value must remain visible with an explicit
status rather than disappearing silently.

### 1. Identity and provenance

- certificate schema and engine version;
- composition/species identifiers;
- chemical formulae and charge state when supported;
- phase labels when supplied or established;
- source dataset/database identifiers and versions;
- retrieval/publication dates where applicable;
- model names and versions;
- unit system and reference conditions;
- computation receipt/fingerprint where available.

### 2. Sample definition

For experimental or measured inputs:

- sample, lot, and batch identifiers when supplied;
- replicate identifiers;
- preparation metadata;
- mass, volume, amount of substance, concentration, and dilution metadata;
- temperature, pressure, humidity, solvent/matrix, and timing when relevant;
- instrument/calibration context when supplied;
- operator/environment context when intentionally recorded.

CPS must not invent missing laboratory metadata.

### 3. Raw observations and sample spread

When replicate data exist, preserve the observations as evidence and report the
appropriate descriptive spread, including where applicable:

- `n`;
- raw values or a stable reference to them;
- mean;
- median;
- standard deviation;
- variance;
- relative standard deviation / coefficient of variation;
- median absolute deviation;
- minimum and maximum;
- range;
- quantiles/interquartile range;
- confidence interval with method and confidence level;
- excluded observations plus the predeclared exclusion rule and evidence.

CPS must distinguish sample variability from measurement uncertainty and from
model uncertainty. A bare `value +/- number` is insufficient.

### 4. Metrology and analytical performance

Where evidence supports it, represent:

- measurand definition;
- repeatability conditions and result;
- intermediate precision/reproducibility conditions and result;
- accuracy/trueness and known bias/correction;
- standard uncertainty;
- combined uncertainty;
- expanded uncertainty;
- coverage factor and coverage probability;
- uncertainty budget and component provenance;
- calibration and traceability information;
- reference materials;
- selectivity/specificity;
- calibration/response model;
- validated working interval;
- robustness/ruggedness;
- detection and quantification limits.

Absence of validation evidence must be represented as absence, not inferred from
apparent numerical precision.

### 5. Exact chemistry certificate

Before predictive chemistry is admitted, CPS should reuse CENTL Chemistry to
establish the deterministic foundation:

- parsed species/formula evidence;
- elemental composition;
- stoichiometric matrix;
- canonical reaction coefficients where balancing is supported;
- per-element conservation;
- charge conservation when charge semantics exist;
- dimension checks;
- exact derived relationships and constants.

A candidate process that violates a required conservation invariant cannot be
rescued by a later predictive model.

### 6. Candidate chemistry and alternative outcomes

Predictive results should be able to represent:

- candidate products/states;
- competing pathways or alternative states;
- required assumptions;
- model domain and validity conditions;
- unsupported pathways explicitly left unresolved.

CPS must not convert a list of plausible candidates into an unjustified reaction
probability.

### 7. Thermodynamics, equilibrium, and kinetics

When an explicit model and admissible data exist, CPS may report bounded results
for quantities such as:

- reaction enthalpy/free-energy bookkeeping;
- equilibrium expressions and equilibrium constants;
- reaction quotient;
- rate-law evaluation;
- Arrhenius-type temperature dependence;
- time-evolution predictions.

Every such field must record the model, assumptions, input provenance, numerical
method, and uncertainty/approximation class.

### 8. Phase, heat, gas, and pressure consequences

Where justified, report separately:

- predicted phase behavior;
- heat release/absorption potential;
- gas-generation potential;
- pressure-generation potential;
- temperature/pressure sensitivity;
- thermal-runaway indicators;
- scale dependence or transport assumptions where relevant.

An ideal-gas or ideal-mixture result must say that it is an ideal-model result.

### 9. Hazard evidence

Hazard output is multidimensional. CPS must not replace it with a single
"poison" or "danger" score.

The schema should be able to represent independently:

- volatility;
- flammability;
- explosivity / energetic decomposition evidence;
- oxidizing/reducing character;
- corrosivity;
- incompatibility/reactivity evidence;
- thermal instability/runaway potential;
- gas and pressure hazards;
- acute toxicity by route and endpoint;
- chronic toxicity evidence;
- carcinogenicity;
- reproductive/developmental toxicity;
- organ-specific toxicity;
- ecological/environmental hazards;
- applicable regulatory classifications.

Each hazard datum or classification must include its evidence source, conditions,
units where meaningful, semantic class, and uncertainty/confidence information.

CPS may identify hazardous properties and refuse unsupported safety claims. It
must not treat a missing hazard record as evidence of safety.

## Potentiality

`potentiality` is a structured vector, not an invented percentage. Candidate
fields include:

```text
stoichiometric_admissibility
thermodynamic_drive
kinetic_accessibility
phase_compatibility
pathway_competition
temperature_sensitivity
pressure_sensitivity
evidence_coverage
model_validity
prediction_uncertainty
```

A compact human label such as `plausible`, `weakly_supported`, or `unresolved`
may be rendered only as a summary over explicit underlying evidence. CPS must not
print a probability such as `83.7%` unless a statistically justified probability
model actually defines that quantity.

## Unknown, missing, and refusal states

Every planned result section must support explicit absence states such as:

```text
status=not_applicable
status=not_measured
status=no_reference_data
status=unknown
status=unsupported_model
status=refused_claim
```

Missing evidence is part of the result.

## Predictive uncertainty

A CPS prediction may have several independent uncertainty sources:

- sample spread;
- measurement uncertainty;
- reference-data uncertainty;
- parameter uncertainty;
- numerical approximation/enclosure width;
- structural/model uncertainty;
- extrapolation outside validated conditions;
- pathway ambiguity.

The result must preserve these categories instead of folding them into one
opaque confidence number. Sensitivity analysis should identify which admitted
inputs dominate the predicted range when the selected model supports that
analysis.

## Safety boundary

CPS is intended for pre-experiment scientific assessment and hazard visibility.
It may identify dangerous, toxic, corrosive, flammable, unstable, or energetic
properties and should surface those warnings prominently.

Predictive safety output is not permission to execute a procedure. CPS must not
claim `safe=true` as a general laboratory conclusion. Any future narrow safety
verdict must define exactly which property was checked, under which conditions,
against which evidence and threshold.

The system must not become an optimization surface for deliberately maximizing
harmful toxicity, explosive performance, or other weaponizable properties.
Hazard identification and defensive assessment remain distinct from harmful
optimization.

## Machine contract

The future machine representation should:

1. version its schema;
2. use strings for arbitrary-precision exact numbers where JSON numeric transport
   could lose information;
3. keep raw evidence separate from rendered summaries;
4. attach semantic class and provenance to every nontrivial datum;
5. identify models and assumptions explicitly;
6. expose uncertainty components and intervals structurally;
7. include unknown/refusal states rather than dropping fields;
8. preserve deterministic ordering where order is part of the schema;
9. make certificates replayable where deterministic checks permit it.

## Implementation order

CPS predictive simulation remains blocked behind the deterministic CENTL
Chemistry foundation. The implementation sequence is:

```text
formula parser
-> exact atom counting
-> reaction parser
-> exact stoichiometric matrix
-> canonical reaction balancing
-> independent conservation verification
-> provenance-aware chemical quantities/data
-> sample-spread + uncertainty representation
-> bounded thermodynamic/equilibrium/kinetic models
-> multidimensional hazard evidence
-> integrated CPS certificates
```

The first chemistry release therefore does **not** claim predictive composition
simulation. This contract exists now so later predictive work cannot silently
weaken CENTL's exactness, provenance, or uncertainty semantics.
