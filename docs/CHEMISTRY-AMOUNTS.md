# CENTL Chemistry amount-of-substance contract

Status: development implementation on `feature/centl-chem-phase1`. This document does not claim merge, release, or Oasis qualification.

This layer builds exact amount-of-substance arithmetic on top of the verified reaction-balancing foundation and the exact SI constants already exposed by CENTL Physics.

## Governing distinction

CENTL separates three ideas:

```text
input_source_class
result_source_class
arithmetic_class
```

For example, a measured amount can be represented exactly as the decimal/rational value reported by the caller while remaining physically measured:

```text
input_source_class=measured
result_source_class=derived_from_measured
arithmetic_class=exact_over_supplied_values
```

A caller may explicitly declare a mathematical input exact:

```text
input_source_class=declared_exact
result_source_class=derived_exact
```

If no source class is supplied, CENTL uses:

```text
input_source_class=unspecified
result_source_class=derived_from_unspecified
```

The direct calculator never invents provenance.

## Exact Avogadro conversion

CENTL Chemistry does not store its own copy of Avogadro's constant. It obtains `N_A` from the existing CENTL Physics constant catalog and requires that entry to remain marked exact.

The current defining value is used through the physics quantity system:

```text
N_A = 602214076000000000000000 1/mol
```

with provenance inherited from CENTL Physics.

### Moles to specified entities

```sh
centl-chem particles exact 1
```

The mathematical result is:

```text
602214076000000000000000
```

specified entities.

The machine result also exposes whether the mathematical entity equivalent is an integer. This matters because an arbitrary exact rational amount of substance need not map to an integer number of entities.

For example, exactly `1/3 mol` gives a non-integral rational entity equivalent under the exact defining relation. CENTL reports:

```text
entities_integral=false
entity_count_status=nonintegral_mathematical_equivalent
```

rather than pretending a fractional entity is a physically realizable exact count.

### Specified entities to moles

```sh
centl-chem moles 602214076000000000000000
```

returns exactly:

```text
1 mol
```

The entity-count input is required to be a non-negative integer.

## Stoichiometric amount conversion

The `stoich` command uses the canonical verified coefficient vector from CENTL Chemistry. It does not trust coefficients typed by the caller and does not implement a second reaction balancer.

Example:

```sh
centl-chem stoich measured 'C2H6 + O2 -> CO2 + H2O' C2H6 3 CO2
```

The chemistry engine first establishes:

```text
2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O
```

then applies the exact coefficient ratio:

```text
3 mol C2H6 * (4 mol CO2 / 2 mol C2H6) = 6 mol CO2
```

The result preserves the source class of the input amount separately from the exact ratio arithmetic.

The machine result nests the complete reaction-balancing evidence, including the exact stoichiometric matrix and per-element conservation verification.

## Limiting reagent and theoretical product amounts

The first limiting-reagent solver works only in amount-of-substance units. It requires one supplied amount for every reactant.

Example:

```sh
centl-chem limiting measured 'H2 + O2 -> H2O' H2=3 O2=1
```

CENTL establishes the canonical reaction:

```text
2 H2 + O2 -> 2 H2O
```

For each reactant it computes the exact candidate reaction extent:

```text
H2: 3 / 2 = 3/2 mol reaction
O2: 1 / 1 = 1 mol reaction
```

The minimum is the admitted extent:

```text
extent = 1 mol reaction
```

so:

```text
limiting_species=O2
remaining H2=1 mol
remaining O2=0 mol
theoretical H2O=2 mol
```

### Co-limiting ties

CENTL does not break an exact tie arbitrarily.

For:

```text
H2=2 mol
O2=1 mol
```

both normalized extents equal `1`, so the result carries:

```text
limiting_species=[H2,O2]
co_limiting=true
```

### Strict input completeness

The limiting solver refuses:

- a missing reactant amount;
- an amount for a species that is not a reactant;
- duplicate assignments for one reactant;
- ambiguous duplicate reactant formulae;
- negative amounts;
- reactions that fail the exact balancing contract.

Assignment order does not determine output order. Inputs, leftovers, and product amounts follow the canonical reaction order.

## Why theoretical product output is moles only

The current layer deliberately stops before mass yield.

Converting a theoretical product amount to grams requires a molar mass. Standard atomic weights and isotope masses are measured/reference data with provenance and, for some elements, interval semantics. CENTL Chemistry does not yet have the versioned chemical-data model needed to carry those values honestly.

Therefore the current result explicitly scopes itself as:

```text
amount_of_substance_only
```

No fixed decimal table of atomic weights is smuggled into the exact engine.

## What this layer does not establish

Exact stoichiometric amount arithmetic does not establish:

- that the reaction occurs;
- thermodynamic favorability;
- kinetic accessibility;
- product selectivity;
- equilibrium conversion;
- actual experimental yield;
- purity;
- phase behavior;
- safety or hazard level.

Those belong to later evidence/model layers.

## Machine evidence

The version-1 amount schemas use strings for arbitrary-precision numbers and include:

- input source class;
- derived result source class;
- exact-arithmetic class;
- exact `N_A` value and inherited provenance for entity conversion;
- canonical balanced equation for stoichiometric work;
- source and target coefficients;
- source and target mole amounts;
- exact reaction evidence;
- exact limiting extent;
- all limiting species, including ties;
- reactant leftovers;
- theoretical product amounts in moles;
- explicit scope statement.

This layer is intended to become a deterministic foundation consumed by CPS rather than reimplemented inside predictive simulation.

