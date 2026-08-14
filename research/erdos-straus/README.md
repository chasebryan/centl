# Erdős-Straus Type A/B automated research harness

This directory operationalizes the research program recorded in `docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`.

## Research map

**Current synthesis:** [`DIAMOND.md`](DIAMOND.md) records how the minimal Type A/B depth invariant, shadow graph, exact-depth spectrum, exact survivor hazard, prime-modulus backbone, composite rescue core, and Direct-Shadow Completeness program fit into one theorem architecture.

**Moving frontier:** [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md) is the shortest current-state record.

**Durable checkpoint:** [`RESEARCH-BACKUP-2026-08-14.md`](RESEARCH-BACKUP-2026-08-14.md) freezes the latest independently verified frontier, workflow run, artifact ID and SHA-256 digest so the research state is recoverable from the repository independently of chat or local scratch data.

Core linked records:

- [`THEORY.md`](THEORY.md) — foundational shadow and modulus-ancestry results;
- [`RESULTS-2026-08-14.md`](RESULTS-2026-08-14.md) — automated frontier, shadow map, independent verification, and CENTL certification;
- [`DEPTH-SPECTRUM.md`](DEPTH-SPECTRUM.md) — exact-depth realization and structural-gap versus latency-gap distinction;
- [`DIRECT-SHADOW-COMPLETENESS.md`](DIRECT-SHADOW-COMPLETENESS.md) — first candidatewise completeness attack through `k=600`;
- [`DIRECT-SHADOW-K1000.md`](DIRECT-SHADOW-K1000.md) — independently verified extension through `k=1000`;
- [`DIRECT-SHADOW-K1200.md`](DIRECT-SHADOW-K1200.md) — exact extension through `k=1200`, with `41,470/41,470` directly novel candidates carrying reduced avoiding progressions;
- [`SHADOW-COVER-GEOMETRY.md`](SHADOW-COVER-GEOMETRY.md) — dense-cover diagnostics showing the phenomenon is not explained by a trivial global union bound;
- [`ODD-COVERING-BRIDGE.md`](ODD-COVERING-BRIDGE.md) — bridge to odd covering-system structure;
- [`SHADOW-KERNEL.md`](SHADOW-KERNEL.md) — exact prime-power local-load peeling theorem and small-prime kernel reduction;
- [`FIBER-SHADOW-KERNEL.md`](FIBER-SHADOW-KERNEL.md) — sharper exact fiber-load elimination theorem;
- [`SMALL-SELECTOR-HYPOTHESIS.md`](SMALL-SELECTOR-HYPOTHESIS.md) — bounded integer-selector attack on residual fiber kernels;
- [`QUADRATIC-TRAP-SIGNATURE.md`](QUADRATIC-TRAP-SIGNATURE.md) — exact Jacobi `-1` signature of every Type A/B trap and the resulting quadratic character-shield theorem;
- [`PRIME-MODULUS-BACKBONE.md`](PRIME-MODULUS-BACKBONE.md) — infinite exact-depth prime-modulus backbone;
- [`SURVIVOR-DENSITY.md`](SURVIVOR-DENSITY.md) — exact finite-depth density, mass, and conditional hazard;
- [`COMPOSITE-CORE.md`](COMPOSITE-CORE.md) — zero-density prime-modulus survivor core and composite-rescue reduction;
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
8. test a bounded fixed selector menu on the residual fiber kernel without consulting the stored witness;
9. apply the quadratic-character shield;
10. certify selected CRT progression identities with CENTL;
11. freeze hashes and upload the complete certificate bundle.

The current workflow defaults are `k<=1500`, `s<=3,000,000`, and residual selector menu `0, ±1, ..., ±64`.

## Latest frozen finite result

The completed candidatewise run through `k<=1200` produced:

```text
admissible candidates:             57,367
directly shadowed candidates:      15,897
directly novel candidates:         41,470
integer avoiding witnesses:        41,470
reduced avoiding witnesses:        41,470
unresolved integer candidates:          0
unresolved reduced candidates:          0
independent verifier:              VERIFIED
```

Every directly novel hard-compatible candidate in this finite range therefore has an explicit reduced avoiding progression. This is an exact finite theorem-certificate statement, not a universal proof of DSC-P.

The same run showed that every certified local solution is within at most nine guided prime-power coordinate changes of a simple unary-safe basepoint. That count is an upper bound, not a proven minimum.

## Exact structural tools

The project now contains several exact sufficient mechanisms for proving candidate realizability without relying on the sequential numerical witness search:

- **prime-power peeling:** if a local coordinate load is below one, that coordinate can be eliminated while preserving satisfiability;
- **fiber peeling:** replace full forbidden-set size by the maximum relevant fiber width after other coordinates are fixed, giving a strictly sharper elimination theorem;
- **quadratic character shield:** every Type A/B trap modulo `m_k=4k-1` has Jacobi symbol `-1`, so any construction forcing all earlier moduli to Jacobi sign `+1` automatically avoids every earlier trap;
- **small-selector experiment:** after exact fiber peeling, test whether a tiny fixed menu of integer parameter values already solves the remaining small-prime kernel.

The small-selector test is a falsifiable proof-mining diagnostic. Failure of the bounded menu is not a DSC-P counterexample.

## Default main research contract

The main finite research run uses:

- prime limit `10,000,000`;
- Mordell-hard classes modulo 840: `1, 121, 169, 289, 361, 529`;
- Type A/B depth search through `k=3000`;
- the checked-in thirteen-record frontier as a regression fixture;
- exact direct-shadow analysis through `k=3000`;
- explicit non-union-shadow witnesses wherever a first-hit prime is present.

## What the harness does not prove

It does not prove the Erdős-Straus conjecture. It does not prove López's universal Type A/B coverage conjecture. It does not yet prove universal Direct-Shadow Completeness. It does not establish literature priority.

Finite candidatewise results are theorem-certificate statements for their stated ranges. Kernel, selector and character criteria are sufficient tools; a residual kernel, failed bounded selector, or inconsistent character-shield system is **not** evidence of a counterexample. It means finer exact trap geometry remains to be analyzed.

## Research direction

The active theorem program is now:

`Type A/B witnesses -> C_AB -> shadow graph -> exact-depth spectrum -> exact survivor process -> direct-shadow completeness -> prime-power/fiber kernel -> quadratic character shield -> bounded selector/core classification -> composite rescue`.

The immediate goal is to identify an invariant or finite kernel classification proving that a directly novel candidate always has a reduced avoiding progression. If achieved, the direct-shadow graph would become a complete obstruction theory for exact Type A/B first-hit realizability.

Chat discussion is exploratory. **The repository is canonical.**
