# CENTL CPS composition preflight

Status: development implementation on `feature/centl-chem-phase1`. This document does not claim merge, release, or Oasis qualification.

The first executable slice of Composition Predictive Simulation is deliberately non-predictive. It creates a deterministic inventory certificate for a proposed composition and explicitly records which later scientific layers have not been evaluated.

## Command

```sh
centl-cps preflight [measured|exact] FORMULA=MOLES [FORMULA=MOLES ...]
```

Machine output:

```sh
centl-cps --json preflight [measured|exact] FORMULA=MOLES [FORMULA=MOLES ...]
```

When neither `measured` nor `exact` is supplied, the source class is `unspecified`.

## Example

```sh
centl-cps preflight measured O2=1 H2=3
```

The preflight validates both formulas using CENTL Chemistry, parses the reported amounts as exact rationals for arithmetic, retrieves the exact SI Avogadro constant from CENTL Physics, and constructs a canonical composition inventory.

Representative human output:

```text
input_source_class=measured
result_source_class=derived_from_measured
arithmetic_class=exact_over_supplied_values
composition_validated=true
species_count=2
species=H2[H:2]:3,O2[O:2]:1 mol
total_species_moles=4 mol
elemental_inventory=H:6,O:2 mol-of-atoms
reaction_model=not_provided
thermodynamics=not_evaluated
kinetics=not_evaluated
phase_pressure=not_evaluated
safety_evidence=not_evaluated
measurement_uncertainty=not_provided
prediction=not_performed
```

The final lines are part of the contract. Successful preflight must not be presented as a reaction prediction.

## Canonical composition model

The current formula model represents elemental composition only. Each parsed formula therefore receives a canonical composition key formed from its alphabetically ordered elemental counts.

Examples:

```text
H2   -> H:2
O2   -> O:2
H2O  -> H:2;O:1
OH2  -> H:2;O:1
```

Because this first model has no structural or isomeric identity, two inputs with the same elemental key are refused as duplicates rather than pretending they are distinguishable species.

This restriction must be revisited only when a richer molecular-identity model is explicitly implemented.

## Deterministic ordering

Species output is ordered by canonical composition key, not shell argument order. Elemental inventory is also ordered deterministically.

Therefore:

```text
H2=3 O2=1
```

and:

```text
O2=1 H2=3
```

produce the same canonical inventory ordering.

## Exact elemental inventory

For each species amount, CENTL multiplies the supplied amount of substance by the exact atom count encoded in the parsed formula.

For:

```text
3 mol H2
1 mol O2
```

the exact elemental inventory is:

```text
H = 6 mol of atoms
O = 2 mol of atoms
```

This is an exact deduction over the supplied values and admitted formula model. If the source amounts were measured, the resulting physical quantities remain derived from measured inputs.

## Specified-entity equivalents

Each species entry also carries the exact mathematical entity equivalent derived through the existing CENTL Physics `N_A` value.

The machine certificate records whether that equivalent is an integer. A non-integral result remains a mathematical equivalent and is not presented as a realizable fractional entity count.

## Provenance axes

Preflight preserves:

```text
input_source_class
result_source_class
arithmetic_class
```

Possible input source classes are currently:

```text
unspecified
measured
declared_exact
```

Derived result classes are correspondingly:

```text
derived_from_unspecified
derived_from_measured
derived_exact
```

The arithmetic class is currently:

```text
exact_over_supplied_values
```

An exact arithmetic path does not upgrade a measured input into an exact physical quantity.

## Explicit non-prediction boundary

The preflight certificate does not infer a reaction, products, or physical outcome.

Its version-1 machine result therefore includes explicit states for later layers:

```text
reaction_model.status=not_provided
thermodynamics.status=not_evaluated
kinetics.status=not_evaluated
phase_pressure.status=not_evaluated
safety_evidence.status=not_evaluated
measurement_uncertainty.status=not_provided
prediction.status=not_performed
```

A caller must not interpret `composition_validated=true` as evidence that the supplied materials react, remain stable, form a particular product, or have been assessed for laboratory suitability.

## Refusals

The current preflight refuses:

- empty compositions;
- more than 128 species in one request;
- malformed `FORMULA=MOLES` assignments;
- invalid or unsupported chemical formulas;
- negative amounts;
- duplicate species under the current elemental-composition model;
- failure to obtain the exact Avogadro constant from the authoritative CENTL Physics catalog.

## Machine certificate

The JSON certificate includes:

- schema version and result kind;
- provenance axes;
- canonical species list;
- original formula spelling and canonical composition key;
- exact mole amount;
- exact per-entity atom counts;
- exact specified-entity equivalent and integrality status;
- total species amount;
- exact elemental mole inventory;
- exact `N_A` value and provenance inherited from CENTL Physics;
- explicit non-evaluated states for later CPS layers.

The preflight implementation is intended as the base object that later CPS models enrich. Later work must add evidence to this certificate rather than replacing its exact inventory with a separate evaluator.

