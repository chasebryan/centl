# CENTL Composition Predictive Simulation (CPS)

Status: planned predictive chemistry layer. Deterministic chemistry core is implemented first.

CENTL CPS is the planned **Composition Predictive Simulation** surface for evaluating a proposed chemical composition before physical preparation. CPS is not a reaction-recipe generator and it is not permitted to manufacture certainty from incomplete chemistry. Its purpose is to combine exact deductions, qualified numerical models, measured/reference data, uncertainty, and hazard evidence into one auditable pre-experiment assessment.

Planned direct CLI:

```sh
centl-cps
```

The core interaction grammar is intentionally small:

```text
comp exam(...)
exact(...)
measured(...)
interval(...)
assume(...)
model(...)
```

Examples of the intended shape:

```sh
centl-cps 'comp exam(A=2mol,B=1mol) measured(T=300K,P=1atm) model(ideal)'
centl-cps 'comp exam(A,B,C) interval(T=298.10K..298.20K) assume(closed_system)'
```

`exact(...)` is reserved for values the caller intentionally declares mathematically exact inside the admitted model. Ordinary laboratory observations should use `measured(...)` or `interval(...)` instead. A decimal spelling does not make a measurement exact.

## Scientific rule

CPS must preserve this distinction everywhere:

> An exact deduction inside a declared mathematical model is not automatically an exact claim about the physical world.

Every output datum must therefore carry an evidence class sufficient to distinguish:

```text
exact
defined
derived-exact
certified-approximation
measured
interval
model-derived
estimated
unknown
not-applicable
unsupported
```

## Execution architecture

The intended execution chain is:

```text
composition specification
  -> deterministic formula/species validation
  -> exact elemental and charge accounting
  -> candidate admitted reaction model(s)
  -> thermodynamic / equilibrium reasoning
  -> kinetic reasoning when a supported rate model exists
  -> phase, gas, pressure, and energy consequences
  -> measured/reference-property evidence
  -> uncertainty and sensitivity propagation
  -> structured hazard assessment
  -> CPS predictive chemistry certificate
```

The deterministic CENTL Chemistry engine remains authoritative for formula parsing, stoichiometry, balancing, and conservation checks. CENTL Physics supplies dimensions, units, and exact SI constants. Numerical approximations must use CENTL's justified approximation machinery or another explicitly bounded numerical backend with visible trust boundaries.

## Potentiality is a vector, not a magic percentage

CPS must not emit an invented `reaction_probability=83.7%` unless a statistically justified probability model actually exists. The internal potentiality representation should instead expose independent dimensions such as:

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
uncertainty
```

Human output may summarize those dimensions with qualified labels such as `plausible`, `low`, `elevated`, or `unknown`, but the evidence vector remains available underneath.

## Sample spreads and analytical evidence

Chemists must be able to inspect the sample spread, not only a collapsed mean. CPS therefore treats the following as separate concepts:

- raw replicate observations;
- sample distribution and descriptive statistics;
- repeatability / intermediate precision / reproducibility evidence;
- measurement uncertainty and its budget;
- model/prediction uncertainty;
- analytical range, detection, and quantification limits when relevant.

A result such as `10.01 ± 0.03` is insufficient unless the meaning of `±`, the coverage rule, units, and calculation are explicit.

The result contract is defined in [`CPS-RESULT-CONTRACT.md`](CPS-RESULT-CONTRACT.md).

## Hazard model

CPS hazard reporting is multidimensional. A single generic poison or danger score is not scientifically adequate. The minimum planned hazard dimensions are:

```text
acute_toxicity
chronic_toxicity
volatility
flammability
explosivity
oxidizing_potential
corrosivity
reactivity
thermal_runaway
gas_generation
pressure_generation
environmental_hazard
```

Each dimension must carry its value/classification, provenance, conditions, confidence/evidence class, uncertainty where available, and whether the result is measured, model-derived, or unknown.

Toxicity must preserve route, endpoint, dose/concentration, duration, population/species context, and source evidence. CPS must not convert heterogeneous toxicology evidence into a fake universal `poison score`.

## Safety boundary

CPS is intended for pre-experiment scientific and safety assessment. It may identify hazardous, toxic, corrosive, unstable, explosive, or otherwise dangerous potential outcomes and explain the evidence supporting those warnings.

CPS must not be designed as an optimizer for maximizing toxicity, explosive performance, weaponization, or other harmful chemical properties. Hazard analysis is allowed; deliberate harmful-design optimization is outside the product contract.

## Data provenance

Reference data should be versioned and source-addressable. Candidate public sources and standards include authoritative metrology, chemistry, analytical-validation, safety, and property data such as JCGM/GUM guidance, IUPAC terminology, ICH analytical validation guidance, SDS/GHS-style hazard structure, NIST chemistry data, and PubChem reference records.

CENTL should record the exact source record/version used rather than copying an unexplained decimal into the codebase.

## Implementation order

CPS begins only after deterministic chemistry foundations exist.

1. Formula/species/reaction model and exact balancing.
2. Amount-of-substance and stoichiometric quantities.
3. Chemical-data provenance and interval/uncertainty semantics.
4. CPS input grammar and result certificate schema.
5. Thermodynamic/equilibrium vertical slices with explicit models.
6. Sample-spread and uncertainty propagation.
7. Hazard-evidence aggregation with unknown/refusal semantics.
8. Kinetics, phase/pressure, and broader predictive chemistry only when independently validated.

No later phase may weaken the exact-first or provenance rules of the earlier layers.

