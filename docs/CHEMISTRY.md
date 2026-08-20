# CENTL Chemistry

Status: **development implementation on `feature/centl-chem-phase1`**. This document does not claim that `centl-chem` has been merged, released, or Oasis-qualified.

CENTL Chemistry is the exact-first chemical-computation layer of CENTL. The first development slice now contains two foundations:

1. deterministic formula/reaction chemistry: formula parsing, atom counting, exact reaction balancing, canonical coefficient normalization, and independent conservation verification;
2. exact-over-reported-values sample spread: bounded replicate ingestion, descriptive spread statistics, and exact symbolic preservation of irrational standard deviations without confusing sample spread with measurement uncertainty.

The implementation reuses CENTL's existing arbitrary-precision rational matrix and physical-unit machinery. It does not introduce floating-point balancing or a second arithmetic system.

## Command surface

The development executable is:

```sh
centl-chem
```

Current commands:

```sh
centl-chem atoms FORMULA
centl-chem balance 'REACTION'
centl-chem spread UNIT VALUE [VALUE ...]
centl-chem spread measured UNIT VALUE [VALUE ...]
centl-chem spread exact UNIT VALUE [VALUE ...]

centl-chem --json atoms FORMULA
centl-chem --json balance 'REACTION'
centl-chem --json spread UNIT VALUE [VALUE ...]
centl-chem --json spread measured UNIT VALUE [VALUE ...]
centl-chem --json spread exact UNIT VALUE [VALUE ...]
```

Plain `spread` defaults to `measured` input semantics. `spread exact` is an explicit caller declaration and must not be inferred merely because an input was written as a terminating decimal.

## Formula syntax

The first parser accepts:

```text
formula := term+
term    := element count?
         | '(' formula ')' count?
element := uppercase lowercase?
count   := positive integer
```

Examples:

```text
H2O
Ca(OH)2
Al2(SO4)3
Fe2(SO4)3
```

Atom counts are arbitrary-precision integers.

The parser validates element symbols against the current 118-element symbol set. Unknown symbols are errors rather than user-defined pseudo-elements.

Current bounded-parser limits include:

- maximum formula text length: 4096 characters;
- maximum nesting depth: 64;
- maximum decimal digits in one subscript: 128;
- maximum reaction text length: 16384 characters;
- maximum species per request: 128.

These are resource boundaries, not chemistry claims.

### Explicitly unsupported formula syntax in this slice

The first parser does not yet claim support for:

- isotope notation;
- ionic charge notation;
- square-bracket coordination syntax;
- hydrate/dot notation such as `CuSO4·5H2O`;
- state labels such as `(aq)` or `(s)`;
- polymer repeat notation;
- structural formulas, SMILES, InChI, stereochemistry, or molecular graphs.

Unsupported notation must fail rather than being silently reinterpreted.

## Exact atom counting

Example:

```sh
centl-chem atoms 'Ca(OH)2'
```

Development output:

```text
Ca=1
H=2
O=2
```

Human output uses deterministic alphabetical element ordering. The JSON form carries counts as strings so arbitrary-precision integers are never routed through a lossy host JSON number.

## Reaction parsing

A reaction contains exactly one ASCII arrow:

```text
reactants -> products
```

Species on each side are separated by `+`.

Positive integer coefficients may be supplied in front of species, with or without whitespace. They are parsed as input evidence but the balancing operation recomputes the canonical primitive coefficient vector instead of trusting the supplied coefficients.

For example:

```text
8 Fe + 6 O2 -> 4 Fe2O3
```

canonicalizes to:

```text
4 Fe + 3 O2 -> 2 Fe2O3
```

## Stoichiometric matrix

For a reaction with elements as rows and species as columns, CENTL Chemistry constructs an exact matrix using the sign convention:

```text
reactants = positive
products  = negative
```

For:

```text
Fe + O2 -> Fe2O3
```

the exact matrix is:

```text
       Fe  O2  Fe2O3
Fe      1   0   -2
O       0   2   -3
```

Balancing solves the homogeneous system:

```text
A x = 0
```

over exact rationals using the existing CENTL matrix nullspace implementation.

No SVD tolerance, floating-point epsilon, or approximate rank decision is used in this path.

## Admission and canonicalization

The first balancing contract is intentionally strict.

A result is admitted only when:

1. the reaction parses under the supported grammar;
2. the exact stoichiometric matrix has a one-dimensional nullspace;
3. the null vector can be oriented so every species coefficient is strictly positive;
4. rational denominators are cleared exactly;
5. all integer coefficients are divided by their common GCD;
6. the resulting primitive coefficient vector is unique under the supported contract;
7. an independent second pass verifies every element count on both sides.

A zero-dimensional nullspace returns `impossible_balance`.

A nullspace of dimension greater than one returns `underdetermined_balance` rather than selecting an arbitrary solution.

A vector requiring a zero species coefficient is refused rather than quietly deleting the species.

## Balancing examples

```sh
centl-chem balance 'Fe + O2 -> Fe2O3'
```

```text
4 Fe + 3 O2 -> 2 Fe2O3
Fe: 4 = 4
O: 6 = 6
verified=true
```

```sh
centl-chem balance 'C2H6 + O2 -> CO2 + H2O'
```

```text
2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O
C: 4 = 4
H: 12 = 12
O: 14 = 14
verified=true
```

```sh
centl-chem balance 'KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2'
```

```text
2 KMnO4 + 16 HCl -> 2 KCl + 2 MnCl2 + 8 H2O + 5 Cl2
Cl: 16 = 16
H: 16 = 16
K: 2 = 2
Mn: 2 = 2
O: 8 = 8
verified=true
```

## Sample spread foundation

Chemists often need the observations and their spread, not a collapsed number. The development `spread` surface therefore preserves the replicate values and computes descriptive statistics exactly over the values as reported.

Example:

```sh
centl-chem spread g 10.01 10.04 9.98 10.03 9.99
```

The first two lines state the two independent semantic axes:

```text
source_class=measured
arithmetic_class=exact_over_reported_values
```

This distinction is mandatory.

`source_class=measured` means the reported numbers are observations of the physical world. Parsing `10.01` as the rational number `1001/100` does not claim that the underlying physical measurand is mathematically exact.

`arithmetic_class=exact_over_reported_values` means CENTL performs the descriptive calculation without adding binary floating-point rounding to the supplied decimal/rational reports.

A caller may intentionally declare mathematical data exact:

```sh
centl-chem spread exact mol 1/3 2/3
```

which changes the source class to:

```text
source_class=declared_exact
```

The default remains measured.

### Current spread statistics

For one common unit shared by all observations, the current exact spread layer returns:

- raw reported observations, represented as exact rationals;
- `n`;
- sum and sum of squares;
- arithmetic mean;
- median;
- minimum and maximum;
- range;
- median absolute deviation (MAD);
- population variance;
- population standard deviation;
- sample variance when `n >= 2`;
- sample standard deviation when `n >= 2`;
- standard error of the mean when `n >= 2`;
- relative standard deviation as a dimensionless fraction when defined.

The sample request is bounded to 10,000 observations.

The unit must already be known to CENTL Physics. All values in one spread request currently share that one unit. Mixed-unit replicate ingestion is not yet admitted.

### Exact radicals instead of fake decimals

A standard deviation need not be rational even when every observation is rational. CENTL preserves that exact structure.

For example, for observations `1 g` and `3 g`, the sample variance is exactly:

```text
2 g^2
```

so the sample standard deviation is represented as:

```text
sqrt(2) g
```

rather than an unjustified decimal pretending to be exact.

The JSON representation distinguishes `exact_rational` from `exact_radical` and carries the radical's rational radicand explicitly.

### Spread is not measurement uncertainty

The current spread command deliberately emits:

```text
confidence_interval=not_computed(requires_declared_confidence_model_and_level)
measurement_uncertainty=not_provided
```

CENTL does not infer a confidence interval without a declared confidence model, level, and method. It does not treat sample standard deviation or standard error as a complete measurement-uncertainty budget.

The machine result similarly keeps these concepts explicit:

```text
source_class
arithmetic_class
sample spread
confidence_interval.status=not_computed
measurement_uncertainty.status=not_provided
```

Future metrology work must introduce its own uncertainty components, traceability, coverage rules, corrections, and provenance rather than overloading the descriptive spread.

## Chemical data and molar mass

The current data slice admits versioned standard atomic-weight intervals for H,
C, N, and O from the IUPAC-CIAAW 2021 table. These values remain measured
intervals and are never labeled exact.

```sh
centl-chem molar-mass H2O
centl-chem --json molar-mass H2O
```

Results report lower and upper molar-mass bounds in `g/mol`, an explicit
`exact=false` flag, and dataset provenance. Formulae containing elements
without an admitted versioned data record are refused.

Reference: [IUPAC periodic table and CIAAW standard atomic weights](https://iupac.org/what-we-do/periodic-table-of-elements/).

## Exact supported models

The current bounded model layer exposes:

- concentration from nonnegative moles and positive litres;
- dilution through exact `C1 V1 = C2 V2`;
- percent yield from nonnegative actual and positive theoretical yield;
- ideal-gas pressure `P = n R T / V` with SI inputs;
- electrochemical charge `q = n_e F`.

These operations report their model and inherited constant provenance. They do
not establish reaction occurrence, equilibrium, selectivity, safety, or
experimental validity.

## Machine evidence

The version-1 development reaction JSON result includes:

- canonical balanced equation;
- arbitrary-precision coefficient strings;
- exact element-row ordering;
- exact stoichiometric matrix entries as rational strings;
- reactant/product column metadata;
- originally supplied coefficients;
- matrix sign convention;
- independent per-element conservation evidence;
- final `verified` flag.

Representative reaction shape:

```json
{
  "version": 1,
  "kind": "balanced_reaction",
  "equation": "4 Fe + 3 O2 -> 2 Fe2O3",
  "coefficients": {
    "reactants": ["4", "3"],
    "products": ["2"]
  },
  "stoichiometric_evidence": {
    "elements": ["Fe", "O"],
    "matrix": [["1", "0", "-2"], ["0", "2", "-3"]],
    "sign_convention": "reactants_positive_products_negative"
  },
  "conservation": [
    {"element": "Fe", "reactants": "4", "products": "4", "verified": true},
    {"element": "O", "reactants": "6", "products": "6", "verified": true}
  ],
  "verified": true
}
```

The sample-spread JSON carries both provenance and exact-arithmetic semantics. A measured observation is represented conceptually as:

```json
{
  "value": "1001/100",
  "unit": "g",
  "source_class": "measured",
  "representation_class": "exact_rational_of_reported_value"
}
```

A derived statistic records both the source class of its inputs and that its arithmetic was exact over the reported values.

Machine errors use stable codes such as:

```text
unknown_element
invalid_subscript
missing_arrow
impossible_balance
underdetermined_balance
zero_coefficient
mixed_sign_coefficients
invalid_observation
unknown_unit
too_many_observations
```

Human error messages may improve without changing those machine identifiers.

## What `verified=true` means

In this first reaction slice, `verified=true` has a narrow meaning:

> the returned canonical coefficient vector independently conserves every element represented by the parsed reaction under the admitted formula grammar.

It does **not** mean:

- the reaction occurs physically;
- the reaction is thermodynamically favorable;
- the reaction is kinetically accessible;
- the written species are the actual products;
- the reaction is safe;
- charge is conserved, because ionic charge syntax is not yet admitted;
- mass values or measured chemical properties have been evaluated.

Those require later contracts.

Likewise, an exact sample-spread calculation means only that the descriptive arithmetic over the reported values is exact. It is not a claim that the physical measurements, calibration, sampling process, or measurand are exact.

## CPS relationship

Composition Predictive Simulation is a later layer, documented in [`CPS.md`](CPS.md) and [`CPS-RESULT-CONTRACT.md`](CPS-RESULT-CONTRACT.md).

CPS must consume deterministic chemistry and sample-evidence structures from this engine rather than reimplementing them. Predictive chemistry remains blocked behind provenance-aware chemical reference data, measurement-uncertainty semantics, explicit thermodynamic/kinetic models, and multidimensional hazard evidence.

The governing boundary remains:

> exact mathematics inside a declared model does not make a physical-world prediction exact.

## Validation status

The development branch contains unit, protocol, refusal, adversarial-limit, deterministic-replay, sample-spread, and Cram CLI tests for the implemented slices. Until the branch has passed the repository's actual build/format/test gates, this implementation must be described as **implemented but not yet validated green**.
