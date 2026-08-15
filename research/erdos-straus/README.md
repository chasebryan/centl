# Erdős-Straus Type A/B automated research harness

This directory operationalizes the research program recorded in `docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`.

## Research map

**Current synthesis:** [`DIAMOND.md`](DIAMOND.md) records how the minimal Type A/B depth invariant, shadow graph, exact-depth spectrum, exact survivor hazard, prime-modulus backbone, composite rescue core, and Direct-Shadow Completeness program fit into one theorem architecture.

**Moving frontier:** [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md) is the shortest current-state record.

**Shared-factor CN (2026-08-15):** [`CN-SHARED-THEOREM.md`](CN-SHARED-THEOREM.md) proves lift-room, the odd totient-ratio lemma, the C2-thin reduction to complementary `q=3`, and the `205 → 10` absorption theorem. Unrestricted C2-shared is false. Directly novel admissible complementary covers are zero through `k ≤ 1500`; the replayable certificate is [`CN-SHARED-CERTIFICATE-2026-08-15.md`](CN-SHARED-CERTIFICATE-2026-08-15.md).

**Durable checkpoint:** [`RESEARCH-BACKUP-2026-08-14.md`](RESEARCH-BACKUP-2026-08-14.md) freezes independently verified workflow/artifact provenance so the research state is recoverable from the repository independently of chat or local scratch data.

Core linked records:

- [`THEORY.md`](THEORY.md) — foundational shadow and modulus-ancestry results;
- [`RESULTS-2026-08-14.md`](RESULTS-2026-08-14.md) — automated frontier, shadow map, independent verification, and CENTL certification;
- [`DEPTH-SPECTRUM.md`](DEPTH-SPECTRUM.md) — exact-depth realization and structural-gap versus latency-gap distinction;
- [`DIRECT-SHADOW-COMPLETENESS.md`](DIRECT-SHADOW-COMPLETENESS.md) — first candidatewise completeness attack through `k=600`;
- [`DIRECT-SHADOW-K1000.md`](DIRECT-SHADOW-K1000.md) — independently verified extension through `k=1000`;
- [`DIRECT-SHADOW-K1200.md`](DIRECT-SHADOW-K1200.md) — exact extension through `k=1200`, with `41,470/41,470` directly novel candidates carrying reduced avoiding progressions;
- [`FIBER-SELECTOR-K1200.md`](FIBER-SELECTOR-K1200.md) — full theorem-driven replay of the frozen `k<=1200` bundle: `26,044` fiber-empty candidates plus `15,426/15,426` nonempty kernels solved by `0,±1,...,±64`, with maximum radius `54`;
- [`SHADOW-COVER-GEOMETRY.md`](SHADOW-COVER-GEOMETRY.md) — dense-cover diagnostics showing the phenomenon is not explained by a trivial global union bound;
- [`ODD-COVERING-BRIDGE.md`](ODD-COVERING-BRIDGE.md) — bridge to odd covering-system structure;
- [`SHADOW-KERNEL.md`](SHADOW-KERNEL.md) — exact prime-power local-load peeling theorem and small-prime kernel reduction;
- [`FIBER-SHADOW-KERNEL.md`](FIBER-SHADOW-KERNEL.md) — sharper exact fiber-load elimination theorem;
- [`SMALL-SELECTOR-HYPOTHESIS.md`](SMALL-SELECTOR-HYPOTHESIS.md) — bounded integer-selector attack on residual fiber kernels;
- [`QUADRATIC-TRAP-SIGNATURE.md`](QUADRATIC-TRAP-SIGNATURE.md) — exact Jacobi `-1` signature of every Type A/B trap and quadratic character shield;
- [`CHARACTER-SHIELD-COMPLETENESS.md`](CHARACTER-SHIELD-COMPLETENESS.md) — proved collapse of collective scalar-character obstruction to fixed negative earlier layers;
- [`QUADRATIC-SIGNATURE-QUOTIENT.md`](QUADRATIC-SIGNATURE-QUOTIENT.md) and [`QUADRATIC-SIGNATURE-COSET.md`](QUADRATIC-SIGNATURE-COSET.md) — complete vector-valued Legendre-signature quotient/coset of every Type A/B trap set;
- [`MULTIPLICATIVE-TRAP-COSET.md`](MULTIPLICATIVE-TRAP-COSET.md) and [`MULTIPLICATIVE-TRAP-QUOTIENT.md`](MULTIPLICATIVE-TRAP-QUOTIENT.md) — multiplicative envelope, quotient shield, and exact two-box trap geometry;
- [`DYADIC-TRAP-LATTICE.md`](DYADIC-TRAP-LATTICE.md) — exact power-of-two trap saturation and infinite Mersenne-type shadow lattice;
- [`SQUARE-LIFT-CORE.md`](SQUARE-LIFT-CORE.md) — fixed-character residual primes outside the target modulus can enter only through even powers;
- [`SQUAREFREE-LIFT-CORE.md`](SQUAREFREE-LIFT-CORE.md) — squarefree-ancestor localization and exact projection-excess reduction;
- [`SQUARE-LIFT-RECIPROCITY.md`](SQUARE-LIFT-RECIPROCITY.md) — quadratic reciprocity forces every square-lift divisor onto the Jacobi-positive side of its squarefree ancestor, yielding infinite shadow families;
- [`JACOBI-SATURATION.md`](JACOBI-SATURATION.md) — classification of exact Jacobi-saturated Type A/B layers: only `k=1,2,4`;
- [`SQUARE-LIFT-SIGNATURE.md`](SQUARE-LIFT-SIGNATURE.md) — exact projected local-signature space and automatic ancestor shadowing whenever `kappa(a)=1`;
- [`RECIPROCITY-DEFECT-QUOTIENT.md`](RECIPROCITY-DEFECT-QUOTIENT.md) — defect quotient `R_a`, its dimension `kappa(a)-1`, and the prime-factor defect conservation law;
- [`SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md`](SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md) — if-and-only-if theorem: `kappa(a)=1` exactly when every square lift is ancestor-shadowed at quadratic-signature resolution; `kappa(a)>1` produces infinitely many signature exceptions;
- [`RECIPROCITY-MATRIX.md`](RECIPROCITY-MATRIX.md) — binary Type A/B reciprocity matrix with canonical left Jacobi null vector and right exponent-parity null vector;
- [`QUADRATIC-FIELD-BRIDGE.md`](QUADRATIC-FIELD-BRIDGE.md) — norm-form, split-prime, ideal-class conservation, and explicit genus/Rédei prior-art boundary for the square-lift theory;
- [`PRIME-MODULUS-BACKBONE.md`](PRIME-MODULUS-BACKBONE.md) — infinite exact-depth prime-modulus backbone;
- [`SURVIVOR-DENSITY.md`](SURVIVOR-DENSITY.md) — exact finite-depth density, mass, and conditional hazard;
- [`COMPOSITE-CORE.md`](COMPOSITE-CORE.md) — zero-density prime-modulus survivor core and composite-rescue reduction;
- [`PRIOR-ART.md`](PRIOR-ART.md) — literature and priority boundary;
- [`CRYPTOLOGY.md`](CRYPTOLOGY.md), [`CRYPTOLOGY-THEORY.md`](CRYPTOLOGY-THEORY.md), and [`CRYPTOLOGY-RESULTS-2026-08-14.md`](CRYPTOLOGY-RESULTS-2026-08-14.md) — controlled cryptology side investigation;
- [`../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md) — formal Wellspring Candidate record.

## Automation

The main workflow `.github/workflows/erdos-straus-research.yml` regenerates the finite Type A/B research corpus, independently verifies certificates, feeds exact identities into CENTL, hashes outputs, and uploads the evidence bundle.

The candidatewise falsification workflow `.github/workflows/erdos-straus-direct-shadow-completeness.yml` performs the stronger theorem attack:

1. enumerate every directly novel hard-compatible candidate through the configured depth;
2. search for an integer avoiding every earlier Type A/B layer;
3. search for a **reduced** avoiding progression, yielding infinitely many exact-depth primes by Dirichlet;
4. independently recompute and verify every witness;
5. analyze the prime-power coordinate core;
6. apply exact coarse local-load peeling;
7. apply exact fiber-load peeling;
8. test a bounded fixed selector menu on the residual fiber kernel without consulting the stored witness;
9. apply quadratic-character analysis;
10. certify selected CRT progression identities with CENTL;
11. freeze hashes and upload the complete certificate bundle.

The current workflow defaults are `k<=1500`, `s<=3,000,000`, and residual selector menu `0, ±1, ..., ±64`.

Additional theorem falsifiers and proof-mining analyzers now include:

- [`trap_coset_analyzer.py`](trap_coset_analyzer.py) — exact finite regression of the multiplicative trap-coset theorem;
- [`quadratic_signature_shield_analyzer.py`](quadratic_signature_shield_analyzer.py) — exact affine local Legendre-signature shield;
- [`square_lift_core_analyzer.py`](square_lift_core_analyzer.py) — parity check and finite classification of the post-character square-lift core;
- [`squarefree_lift_core_analyzer.py`](squarefree_lift_core_analyzer.py) — exact squarefree-ancestor projection-excess localization on a candidate bundle.

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

A separate full replay on the same frozen candidate bundle independently resolves all `41,470` candidates by exact fiber peeling followed, when necessary, by a bounded residual selector. No stored witness is used to decide those two stages.

## Exact structural tools

The project now contains a hierarchy of exact sufficient mechanisms and envelopes:

- **prime-power peeling:** a coordinate whose local load is below one can be eliminated while preserving satisfiability;
- **fiber peeling:** replacing full forbidden-set size by the maximum relevant fiber width gives a strictly sharper local elimination theorem;
- **bounded residual selectors:** after fiber peeling, the `k<=1200` replay solved every nonempty kernel with the fixed menu `0,±1,...,±64`;
- **Jacobi character shield:** every Type A/B trap modulo `m_k=4k-1` has Jacobi symbol `-1`;
- **character obstruction completeness:** collective scalar-character inconsistency adds no obstruction beyond one fixed-negative earlier layer;
- **full quadratic-signature coset:** the complete vector of local Legendre signs of `T_k` is the affine space `eta_k+V_k`;
- **multiplicative trap coset:** the exact trap set sits inside one proper coset `-H_k` in the unit group;
- **squarefree-lift localization:** every character-fixed layer has a squarefree ancestor modulus and only its projection excess can remain exactly active;
- **square-lift reciprocity:** every divisor prime of a lift splits in the ancestor quadratic field;
- **signature-shadow classification:** `kappa(a)=1` is exactly the universal square-lift signature-shadow regime;
- **reciprocity defect conservation:** higher-quotient lift defects must cancel according to prime-exponent parity;
- **reciprocity matrix:** the Legendre-symbol matrix has canonical conservation laws on both its left and right null spaces;
- **quadratic-field norm bridge:** square-lift depths are norms of `(1+s sqrt(-d))/2`, giving a principal-ideal conservation law stronger than its quadratic-character projection.

Each stage deliberately preserves the claim boundary: failure of a coarse shield or a bounded selector does **not** imply exact Type A/B coverage. It only says finer geometry remains.

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

Finite candidatewise results are theorem-certificate statements for their stated ranges. Kernel, selector, quadratic-signature, multiplicative-coset and square-lift tools are exact sufficient structures or envelopes, but a residual from any one of them is **not** evidence of a counterexample.

## Research direction

The active theorem program is now:

`Type A/B witnesses -> C_AB -> shadow graph -> exact-depth spectrum -> exact survivor process -> direct-shadow completeness -> fiber kernel -> bounded selector -> scalar character saturation -> local quadratic signatures -> reciprocity matrix/defect quotient -> multiplicative quotient -> exact square-lift/ray-class residue core -> composite rescue`.

The immediate goal is to convert the increasingly tiny residual core into a universal local escape theorem. If achieved, the direct-shadow graph would become a complete obstruction theory for exact Type A/B first-hit realizability.

Chat discussion is exploratory. **The repository is canonical.**
