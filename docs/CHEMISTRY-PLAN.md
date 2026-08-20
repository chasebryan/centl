# CENTL Chemistry plan

Status: planned scientific domain expansion.

CENTL Chemistry is a proposed exact-first chemistry layer built on CENTL's existing mathematical kernel and CENTL Physics quantity system. It must preserve the same central rule used elsewhere in CENTL: exact values stay exact, measured values remain visibly measured, incompatible dimensions fail, and unsupported chemistry is refused rather than guessed.

## Product surface

Planned direct CLI:

```sh
centl-chem
```

Planned scientific family:

```text
CENTL Math      -> exact mathematics
CENTL Physics   -> dimension-safe deterministic physics
CENTL Chemistry -> exact-first chemical computation
CENTL-SCi       -> optional interpretation layer across supported domains
```

Chemistry must reuse CENTL mathematics and CENTL Physics instead of implementing parallel arithmetic, unit, constant, or approximation machinery.

## Phase 1: formulas and exact reaction balancing

First milestone:

- parse elemental symbols and chemical formulas;
- support integer subscripts and nested parenthesized groups;
- count atoms exactly;
- parse reaction sides and stoichiometric coefficients;
- balance reactions using exact integer/rational linear algebra;
- normalize coefficients to the least positive integer solution when a unique one-dimensional stoichiometric null space exists;
- verify conservation of every represented element independently after balancing;
- reject malformed formulas, unknown elements, impossible balances, and underdetermined reactions that do not admit a canonical result under the supported contract;
- provide deterministic output ordering and multiply-back/conservation evidence.

Target examples:

```sh
centl-chem atoms 'Ca(OH)2'
centl-chem balance 'Fe + O2 -> Fe2O3'
centl-chem balance 'C2H6 + O2 -> CO2 + H2O'
centl-chem balance 'KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2'
```

A balanced reaction is not merely formatted text. CENTL Chemistry must return explicit conservation evidence for every element.

## Phase 2: amount of substance and stoichiometry

Build on the existing SI amount-of-substance dimension and exact Avogadro constant already present in CENTL Physics.

Planned capabilities:

- mole <-> specified-particle conversion;
- stoichiometric ratio calculations;
- reactant/product amount conversion;
- limiting-reagent determination;
- theoretical yield;
- percent yield when supplied an experimental yield;
- concentration and dilution calculations;
- exact dimensional validation for mol, mass, volume, and related quantities.

Target examples:

```sh
centl-chem particles '1 mol'
centl-chem stoich '2 H2 + O2 -> 2 H2O' --from '3 mol H2' --to H2O
centl-chem limiting '2 H2 + O2 -> 2 H2O' '3 mol H2' '1 mol O2'
```

## Phase 3: chemical data provenance and uncertainty

CENTL Chemistry must not treat measured chemical data as exact merely because they are printed with decimals.

Introduce or reuse provenance classes sufficient to distinguish at least:

```text
exact
defined
derived-exact
measured
interval
uncertain
```

Planned requirements:

- periodic-table identity data must be versioned and provenance-carrying;
- standard atomic weights must retain their source status;
- interval-valued standard atomic weights must remain intervals;
- isotope-specific masses must remain measured quantities unless a definition says otherwise;
- molar-mass calculations must propagate the provenance/interval semantics of their inputs;
- CLI output must never label a measured-derived molar mass as exact.

Target example:

```sh
centl-chem molar-mass H2O
```

The result must report the data source and assurance class used to derive the value.

## Phase 4: exact derived constants, gases, thermochemistry, electrochemistry

Reuse the exact SI defining constants already present in CENTL Physics.

Initial exact derived constants should include:

```text
R = N_A * k_B
F = N_A * e
```

with provenance showing the derivation rather than storing unexplained decimal literals.

Planned domain work:

- ideal-gas-law calculations under an explicitly declared ideal-gas model;
- thermochemical quantity bookkeeping with dimensions and provenance;
- reaction enthalpy calculations when supplied trusted data;
- Faraday-law electrochemistry;
- charge/mole/electron conversion through exact `F` where appropriate.

Target examples:

```sh
centl-chem constant R
centl-chem constant F
```

## Phase 5: equilibrium, logarithmic chemistry, and kinetics

Later work may include:

- equilibrium expressions;
- reaction quotient and equilibrium-constant calculations;
- pH/pOH with explicit logarithmic numerical contracts;
- acid/base stoichiometry;
- simple supported kinetic rate laws;
- Arrhenius calculations when all required parameters and provenance are supplied.

These capabilities must not silently assume activities equal concentrations, select a thermodynamic standard state, invent temperature, or fabricate missing chemical data.

## Explicit non-goals for the first chemistry releases

Do not present the following as implemented merely because general mathematics could approximate parts of them:

- ab initio quantum chemistry;
- electronic-structure or orbital solvers;
- density-functional theory;
- molecular dynamics;
- reaction-path or transition-state prediction;
- automatic reaction prediction;
- molecular geometry optimization;
- general chemical database inference;
- measured-property prediction without a justified model and provenance.

Those require separate mathematical, physical, numerical, and data contracts.

## Exact-first chemistry contract

Every CENTL Chemistry capability must satisfy the following before becoming public:

1. The admitted chemical model is explicit.
2. Exact arithmetic is preserved wherever the model permits it.
3. Units and dimensions are checked rather than inferred from convenient numbers.
4. Measured data carry provenance and are never silently promoted to exact values.
5. Interval or uncertainty information is preserved when present.
6. Canonicalization is deterministic.
7. Results are independently verified where a conservation or identity check exists.
8. Unsupported, ambiguous, or underdetermined requests produce explicit refusal or unresolved verdicts.
9. CLI and machine interfaces share one authoritative implementation rather than duplicating chemistry evaluators.
10. Tests include positive cases, refusal cases, malformed input, provenance behavior, and exact multiply-back/conservation verification.

## Integration with CENTL-SCi

After deterministic chemistry capabilities exist, CENTL-SCi may add a chemistry mode or chemistry-aware HYBRID interpretation path.

Natural-language interpretation remains untrusted. It may parse a chemistry request into a typed problem representation, but the authoritative result must come from CENTL Chemistry.

Example future interaction:

```text
HYBRID> balance methane combustion and calculate the amount of CO2 produced from 3 mol CH4
```

The intended execution chain is:

```text
natural language
  -> validated chemistry problem representation
  -> CENTL Chemistry reaction balancing
  -> exact stoichiometric arithmetic
  -> CENTL Physics quantities/constants where required
  -> independent conservation/dimension checks
  -> evidence-backed result
```

## First implementation target

The first chemistry PR should stay narrow:

```text
formula parser
+ atom counter
+ reaction parser
+ exact integer reaction balancer
+ canonical coefficient normalization
+ per-element conservation verification
+ human CLI
+ deterministic JSON/machine representation
+ golden/refusal tests
```

Acceptance examples:

```text
Fe + O2 -> Fe2O3
=> 4 Fe + 3 O2 -> 2 Fe2O3

C2H6 + O2 -> CO2 + H2O
=> 2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O
```

This is the chemistry equivalent of an Oasis-quality mathematical capability: no public alias over approximate or unverifiable machinery. The implementation becomes CENTL-public only when its semantics are exact or properly qualified, canonical, independently checked, and green through the relevant native and CLI gates.
