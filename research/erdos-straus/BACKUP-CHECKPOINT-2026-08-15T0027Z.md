# Crash-safe Erdős-Straus research checkpoint

**Checkpoint time:** 2026-08-15 00:27 UTC  
**Project:** Free Computation Foundation / CENTL  
**Purpose:** durable recovery point for the active Type A/B theorem program  
**Claim boundary:** Erdős-Straus remains open; universal López Type A/B coverage and universal Direct-Shadow Completeness remain unproved.

This checkpoint exists because live chat/session state is not considered durable. **The repository is canonical.**

## 1. Repository state frozen immediately before this checkpoint

Main branch head immediately before writing this file:

```text
5fe657887b0fca5b447bda867ffa1e294c132aa2
```

Commit message:

```text
research: add multiplicative defect quotient and zero-product atom analyzer
```

All theorem notes, analyzers, and research records listed below were already committed to `main` at or before that SHA.

## 2. Newly completed k <= 1500 evidence run

GitHub Actions run:

```text
31849103304
```

Head SHA tested by the workflow:

```text
c508994fb48e6f701f15577352f275df5646cd78
```

Configured contract:

```text
k_limit:      1500
search_limit: 3000000
```

Final workflow status:

```text
Candidatewise union-shadow attack and CENTL certification: SUCCESS
```

Every workflow stage completed successfully:

```text
candidate attack                         SUCCESS
independent verifier                     SUCCESS
prime-power coordinate-core mining       SUCCESS
coarse shadow-kernel peeling             SUCCESS
fiber shadow-kernel peeling              SUCCESS
bounded residual selector test           SUCCESS
quadratic character shield               SUCCESS
CENTL exact certification                SUCCESS
hash freezing                            SUCCESS
summary publication                      SUCCESS
artifact upload                          SUCCESS
```

Artifact:

```text
artifact id:   9238241616
artifact name: direct-shadow-completeness-c508994fb48e6f701f15577352f275df5646cd78
size:          3226135 bytes
expires:       2026-11-12T23:05:32Z
sha256:        e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
```

The artifact freezes the complete `k<=1500` workflow evidence produced from commit `c508994...`. Later theorem commits are repository-backed separately and were intentionally **not** retroactively mixed into that workflow artifact.

## 3. Earlier fully frozen k <= 1200 evidence

Completed run:

```text
run id:       31846146909
head commit:  ef88f759a68907e517430e82432c5054f463edc5
artifact id:  9236427053
artifact sha256:
a2479a4113d693af2e647ffc2e007d3d7b1cf628ce7190f72c4ad6282a98ba14
```

Certified finite frontier:

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

Independent theorem-driven replay on the same frozen candidate bundle:

```text
fiber-empty candidates:             26,044
nonempty residual kernels:          15,426
bounded-selector solved:            15,426 / 15,426
maximum selector radius required:       54
unresolved residual kernels:             0
```

## 4. Current theorem chain backed up in the repository

### Minimal depth and shadow geometry

- `WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`
- `DIAMOND.md`
- `CURRENT-FRONTIER.md`
- `DEPTH-SPECTRUM.md`
- `DIRECT-SHADOW-COMPLETENESS.md`
- `DIRECT-SHADOW-K1000.md`
- `DIRECT-SHADOW-K1200.md`
- `SPECTRUM-INFINITE-COINFINITE.md`
- `SPECTRUM-COUNTING-BOUNDS.md`

### Fiber and local-kernel reductions

- `SHADOW-KERNEL.md`
- `FIBER-SHADOW-KERNEL.md`
- `SMALL-SELECTOR-HYPOTHESIS.md`
- `FIBER-SELECTOR-K1200.md`

### Quadratic-character and local-signature structure

- `QUADRATIC-TRAP-SIGNATURE.md`
- `CHARACTER-SHIELD-COMPLETENESS.md`
- `QUADRATIC-SIGNATURE-QUOTIENT.md`
- `QUADRATIC-SIGNATURE-COSET.md`
- `PROPER-JACOBI-ANCESTOR.md`
- `QUADRATIC-SIGNATURE-SHIELD-K1200.md`

### Multiplicative quotient structure

- `MULTIPLICATIVE-TRAP-COSET.md`
- `MULTIPLICATIVE-TRAP-QUOTIENT.md`
- `TRAP-QUOTIENT-FACTORIZATION.md`
- `MULTIPLICATIVE-DEFECT-QUOTIENT.md`
- `DEFECT-ZERO-SUM-ATOMS.md`
- `multiplicative_defect_atom_analyzer.py`

### Square-lift / reciprocity / quadratic-field structure

- `SQUARE-LIFT-CORE.md`
- `SQUAREFREE-LIFT-CORE.md`
- `SQUARE-LIFT-RECIPROCITY.md`
- `SQUARE-LIFT-SIGNATURE.md`
- `SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md`
- `RECIPROCITY-DEFECT-QUOTIENT.md`
- `RECIPROCITY-MATRIX.md`
- `QUADRATIC-FIELD-BRIDGE.md`
- `square_lift_core_analyzer.py`

### Infinite structural-gap families and classifications

- `MERSENNE-SHADOW-LATTICE.md`
- `DYADIC-TRAP-LATTICE.md`
- `PRIME-POWER-TRAP-DICHOTOMY.md`
- `PRIME-DEPTH-DICHOTOMY.md`
- `PRIME-DEPTH-BACKBONE-PROJECTION.md`
- `PRIME-DEPTH-DENSITY.md`
- `COSET-SOURCE-SEMIGROUP-SHADOW.md`
- `DEPTH1-SHADOW-CLASSIFICATION.md`
- `COSET-SATURATION-CLASSIFICATION.md`
- `STRUCTURAL-GAP-ASYMPTOTIC.md`

### Supporting analyses and automation

- `trap_coset_analyzer.py`
- `quadratic_signature_shield_analyzer.py`
- `mersenne_shadow_analyzer.py`
- `.github/workflows/erdos-straus-research.yml`
- `.github/workflows/erdos-straus-direct-shadow-completeness.yml`

## 5. Important proved results currently frozen

The repository now contains proofs or exact finite certificates for all of the following, with their stated claim boundaries:

1. minimal Type A/B witness depth `C_AB` and its exact direct-shadow framework;
2. exact trap cardinality;
3. unboundedness of `C_AB` over primes, including primes `1 mod 840`;
4. exact candidatewise no-counterexample evidence through the completed finite workflow frontier;
5. fiber-peeling and bounded-selector constructions on the frozen `k<=1200` bundle;
6. scalar character obstruction completeness;
7. full local quadratic-signature affine-coset structure;
8. proper Jacobi ancestors for higher signature codimension;
9. multiplicative trap coset and exact quotient factorization;
10. squarefree-lift localization and square-lift reciprocity;
11. reciprocity defect quotient and defect conservation;
12. full multiplicative defect quotient and finite-abelian conservation law;
13. zero-product atom decomposition bounded by the Davenport constant;
14. exact dyadic/Mersenne shadow lattice;
15. prime-power binary/odd dichotomy;
16. complete coset-saturation classification:
    `T_k=-H_k` iff `k=1` or `k` is a power of two;
17. prime-depth dichotomy:
    for prime depth `k`, `4k-1` prime gives infinite exact-depth realization, while `4k-1` composite makes the depth globally impossible;
18. prime-depth backbone projection;
19. relative-density-one structural impossibility among prime depth values;
20. depth-1 shadow classification:
    depth `k>1` is globally shadowed by depth `1` iff every prime divisor of `k` is `1 mod 3`;
21. structural-gap family of order `X/sqrt(log X)` from that multiplicative semigroup;
22. the minimal-depth spectrum is infinite and co-infinite.

## 6. Current strongest active theorem targets

The unresolved edge is no longer a raw search problem. The current proof program is:

```text
exact Type A/B pullbacks
  -> direct shadow graph
  -> fiber peeling
  -> bounded small-prime kernel
  -> scalar character saturation
  -> local quadratic-signature quotient
  -> multiplicative defect quotient
  -> bounded zero-product atoms
  -> exact two-box residue geometry
  -> local p-adic / ray-class escape
  -> universal DSC-P target
```

Immediate targets:

1. classify the zero-product atoms of `M_a` that can arise from square-lift norm-form factorizations;
2. determine when a neutral atom lands in the exact ancestor two-box trap rather than merely its multiplicative coset;
3. prove or falsify universal Direct-Shadow Completeness from those local atom classes;
4. preserve every new theorem and falsifier in the repo before proceeding.

## 7. Recovery rule

If a session crashes, recovery should start from:

1. this checkpoint file;
2. `CURRENT-FRONTIER.md`;
3. `DIAMOND.md`;
4. the two frozen workflow artifacts above;
5. the latest `main` commit.

No theorem should be reconstructed from chat memory when a canonical repository copy exists.
