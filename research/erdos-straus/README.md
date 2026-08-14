# Erdős-Straus Type A/B automated research harness

This directory operationalizes the research program recorded in `docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`.

## Research map

**Current synthesis:** [`DIAMOND.md`](DIAMOND.md) records how the minimal Type A/B depth invariant, shadow graph, exact-depth spectrum, exact survivor hazard, prime-modulus backbone, composite rescue core, and Direct-Shadow Completeness program fit into one theorem architecture.

Core linked records:

- [`THEORY.md`](THEORY.md) — foundational shadow and modulus-ancestry results;
- [`RESULTS-2026-08-14.md`](RESULTS-2026-08-14.md) — automated frontier, shadow map, independent verification, and CENTL certification;
- [`DEPTH-SPECTRUM.md`](DEPTH-SPECTRUM.md) — exact-depth realization and structural-gap versus latency-gap distinction;
- [`DIRECT-SHADOW-COMPLETENESS.md`](DIRECT-SHADOW-COMPLETENESS.md) — first candidatewise completeness attack through `k=600`;
- [`DIRECT-SHADOW-K1000.md`](DIRECT-SHADOW-K1000.md) — independently verified extension through `k=1000`, with `33,644/33,644` directly novel candidates carrying reduced avoiding progressions;
- [`DIRECT-SHADOW-K1200.md`](DIRECT-SHADOW-K1200.md) — subsequent extension through `k=1200`;
- [`SHADOW-COVER-GEOMETRY.md`](SHADOW-COVER-GEOMETRY.md) — dense-cover diagnostics showing the phenomenon is not explained by a trivial global union bound;
- [`ODD-COVERING-BRIDGE.md`](ODD-COVERING-BRIDGE.md) — bridge to odd covering-system structure;
- [`SHADOW-KERNEL.md`](SHADOW-KERNEL.md) — exact prime-power local-load peeling theorem and small-prime kernel reduction;
- [`FIBER-SHADOW-KERNEL.md`](FIBER-SHADOW-KERNEL.md) — sharper exact fiber-load elimination theorem;
- [`QUADRATIC-TRAP-SIGNATURE.md`](QUADRATIC-TRAP-SIGNATURE.md) — exact Jacobi `-1` signature of every Type A/B trap and the resulting quadratic character-shield theorem;
- [`PRIME-MODULUS-BACKBONE.md`](PRIME-MODULUS-BACKBONE.md) — infinite exact-depth prime-modulus backbone;
- [`SURVIVOR-DENSITY.md`](SURVIVOR-DENSITY.md) — exact finite-depth density, mass, and conditional hazard;
- [`COMPOSITE-CORE.md`](COMPOSITE-CORE.md) — zero-density prime-modulus survivor core and composite-rescue reduction;
- [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md) — current theorem and computation frontier;
- [`PRIOR-ART.md`](PRIOR-ART.md) — literature and priority boundary;
- [`CRYPTOLOGY.md`](CRYPTOLOGY.md), [`CRYPTOLOGY-THEORY.md`](CRYPTOLOGY-THEORY.md), and [`CRYPTOLOGY-RESULTS-2026-08-14.md`](CRYPTOLOGY-RESULTS-2026-08-14.md) — controlled cryptology side investigation;
- [`../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md) — formal Wellspring Candidate record.

## Automation

The main workflow `.github/workflows/erdos-straus-research.yml` regenerates the finite Type A/B research corpus, independently verifies certificates, feeds exact identities into CENTL, hashes outputs, and uploads the evidence bundle.

The candidatewise falsification workflow `.github/workflows/erdos-straus-direct-shadow-completeness.yml` now performs a stronger theorem attack:

1. enumerate every directly novel hard-compatible candidate through the configured depth;
2. search for an integer avoiding every earlier Type A/B layer;
3. search for a **reduced** avoiding progression, which yields infinitely many exact-depth primes by Dirichlet;
4. independently recompute and verify every witness;
5. analyze the prime-power coordinate core;
6. apply exact coarse local-load peeling;
7. apply exact fiber-load peeling;
8. apply the quadratic-character shield;
9. certify selected CRT progression identities with CENTL;
10. freeze hashes and upload the complete certificate bundle.

The current workflow defaults are `k<=1500` and `s<=3,000,000`, while earlier frozen results remain separately documented.

## Default main research contract

The main finite research run uses:

- prime limit `10,000,000`;
- Mordell-hard classes modulo 840: `1, 121, 169, 289, 361, 529`;
- Type A/B depth search through `k=3000`;
- the checked-in thirteen-record frontier as a regression fixture;
- exact direct-shadow analysis through `k=3000`;
- explicit non-union-shadow witnesses wherever a first-hit prime is present.

## What is proved or certified by the harness

Depending on the workflow and configured range, the project can certify statements such as:

- a listed prime has no Type A/B hit below its claimed `C_AB` and does have a hit at that depth;
- a direct-shadow certificate really gives a complete residue fibre contained in an earlier trap set;
- a candidate-specific avoiding integer disproves union coverage by all earlier layers;
- a reduced avoiding parameter class gives infinitely many exact-depth primes by Dirichlet;
- the trap-cardinality formula agrees with explicit trap enumeration;
- observed modulus-divisibility edges satisfy the proved ancestry identity;
- large prime-power coordinates can be eliminated by exact local-load or fiber-load inequalities;
- every Type A/B trap residue has Jacobi symbol `-1` modulo `4k-1`;
- a solvable quadratic character-shield system gives an independent reduced exact-depth progression;
- CENTL verifies the supplied exact Egyptian-fraction, polynomial, and CRT progression identities without floating-point approximation.

## What the harness does not prove

It does not prove the Erdős-Straus conjecture. It does not prove López's universal Type A/B coverage conjecture. It does not yet prove universal Direct-Shadow Completeness. It does not establish literature priority.

Finite candidatewise results are theorem-certificate statements for their stated ranges. Kernel and character criteria are exact sufficient theorems, but a residual kernel or inconsistent character-shield system is **not** evidence of a counterexample; it means finer exact trap geometry remains to be analyzed.

## Research direction

The active theorem program is now:

`Type A/B witnesses -> C_AB -> shadow graph -> exact-depth spectrum -> exact survivor process -> direct-shadow completeness -> prime-power/fiber kernel -> quadratic character shield -> bounded residual core -> composite rescue`.

The immediate goal is to identify an invariant or finite kernel classification proving that a directly novel candidate always has a reduced avoiding progression. If achieved, the direct-shadow graph would become a complete obstruction theory for exact Type A/B first-hit realizability.
