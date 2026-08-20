# CENTL Chemistry

Status: **development implementation on `feature/centl-chem-phase1`**. This document does not claim that `centl-chem` has been merged, released, or Oasis-qualified.

CENTL Chemistry is the exact-first chemical-computation layer of CENTL. The first vertical slice is deliberately narrow: chemical formula parsing, exact atom counting, reaction parsing, exact stoichiometric balancing, canonical coefficient normalization, and independent conservation verification.

The implementation reuses CENTL's existing arbitrary-precision rational matrix machinery. It does not introduce a floating-point balancing solver or a second arithmetic system.

## Command surface

The development executable is:

```sh
centl-chem
```

Current commands:

```sh
centl-chem atoms FORMULA
centl-chem balance 'REACTION'
centl-chem --json atoms FORMULA
centl-chem --json balance 'REACTION'
```

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

## Examples

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

## Machine evidence

The version-1 development JSON result includes:

- canonical balanced equation;
- arbitrary-precision coefficient strings;
- exact element-row ordering;
- exact stoichiometric matrix entries as rational strings;
- reactant/product column metadata;
- originally supplied coefficients;
- matrix sign convention;
- independent per-element conservation evidence;
- final `verified` flag.

Representative shape:

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

Machine errors use stable codes such as:

```text
unknown_element
invalid_subscript
missing_arrow
impossible_balance
underdetermined_balance
zero_coefficient
mixed_sign_coefficients
```

Human error messages may improve without changing those machine identifiers.

## What `verified=true` means

In this first slice, `verified=true` has a narrow meaning:

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

## CPS relationship

Composition Predictive Simulation is a later layer, documented in [`CPS.md`](CPS.md) and [`CPS-RESULT-CONTRACT.md`](CPS-RESULT-CONTRACT.md).

CPS must consume deterministic chemistry evidence from this engine rather than reimplement balancing. Predictive chemistry remains blocked behind provenance-aware measured data, uncertainty semantics, explicit thermodynamic/kinetic models, and multidimensional hazard evidence.

The governing boundary remains:

> exact mathematics inside a declared model does not make a physical-world prediction exact.

## Validation status

The development branch includes unit, protocol, refusal, and Cram CLI tests for the first slice. Until the branch has passed the repository's actual build/format/test gates, this implementation must be described as **implemented but not yet validated green**.
