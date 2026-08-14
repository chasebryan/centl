# Erdős-Straus research backup — 2026-08-14

**Project:** Free Computation Foundation / CENTL  
**Purpose:** durable checkpoint of the active Type A/B theorem program  
**Claim boundary:** this checkpoint does not claim a proof of the Erdős-Straus conjecture, universal López Type A/B coverage, or universal Direct-Shadow Completeness.

This file exists specifically so the live research state is recoverable from the repository even if chat context, local scratch files, or workflow artifacts are later unavailable.

## Canonical research chain

- [WS-CAND-003](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md)
- [DIAMOND.md](DIAMOND.md)
- [CURRENT-FRONTIER.md](CURRENT-FRONTIER.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md)
- [DIRECT-SHADOW-K1200.md](DIRECT-SHADOW-K1200.md)
- [SHADOW-COVER-GEOMETRY.md](SHADOW-COVER-GEOMETRY.md)
- [ODD-COVERING-BRIDGE.md](ODD-COVERING-BRIDGE.md)
- [SHADOW-KERNEL.md](SHADOW-KERNEL.md)
- [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md)
- [SMALL-SELECTOR-HYPOTHESIS.md](SMALL-SELECTOR-HYPOTHESIS.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [SURVIVOR-DENSITY.md](SURVIVOR-DENSITY.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [COMPOSITE-CORE.md](COMPOSITE-CORE.md)
- [PRIOR-ART.md](PRIOR-ART.md)

## Exact finite frontier frozen here

The completed candidatewise Direct-Shadow attack through `k<=1200` produced:

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

Thus every directly novel hard-compatible candidate tested through depth 1200 has an explicit reduced avoiding progression and hence an infinite exact-depth prime progression by Dirichlet.

This is an exact finite certificate statement only. Universal DSC-P remains open.

## Coordinate-locality result

Across all `41,470` directly novel candidates through `k<=1200`:

```text
canonical unary-safe basepoint solved: 15,715 / 41,470 = 37.895%
maximum guided repair count:            9 prime-power coordinates
```

Cumulative guided repair upper bounds:

```text
0 changes: 37.895%
<=1:       71.264%
<=2:       88.847%
<=3:       96.122%
<=4:       98.727%
<=5:       99.612%
<=6:       99.908%
<=7:       99.990%
<=8:       99.998%
<=9:      100.000%
```

The guided-repair count is not asserted minimal. The stored reduced witness guides the replacement values, after which the resulting local assignment is checked exactly.

## Completed automated run provenance

GitHub Actions run:

```text
run id:       31846146909
head commit:  ef88f759a68907e517430e82432c5054f463edc5
artifact id:  9236427053
```

Artifact ZIP digest:

```text
sha256:a2479a4113d693af2e647ffc2e007d3d7b1cf628ce7190f72c4ad6282a98ba14
```

The run completed successfully through discovery, independent verification, coordinate-core proof mining, CENTL exact symbolic certification, per-file SHA-256 verification, and artifact upload.

## Exact theorem machinery now in the repository

### Prime-power peeling

For a candidate pullback system with parameter moduli `q_j`, the local load

\[
\lambda_p=\sum_{p\mid q_j}\frac{|R_j|}{p^{v_p(q_j)}}
\]

is an exact sufficient elimination criterion: `lambda_p<1` makes the `p` coordinate peelable. The augmented form includes the one local residue excluded by reducedness.

### Fiber peeling

Writing `q_j=p^a c`, the sharper fiber width `f_{j,p}` records the maximum number of forbidden `p^a` residues above one fixed value modulo `c`. The exact fiber load

\[
\Lambda_p=\sum_{p\mid q_j}\frac{f_{j,p}}{p^{v_p(q_j)}}
\]

is therefore strictly sharper. If the augmented `Lambda_p*<1`, the coordinate is peelable while preserving reduced prime realization.

### Quadratic trap signature

For `m=4k-1` and every divisor `e|k`, the exact theorem now recorded in the repository is

\[
\boxed{
\left(\frac{-e}{m}\right)
=\left(\frac{-4e}{m}\right)
=-1.
}
\]

Thus every Type A/B trap lies in the Jacobi-negative part of the unit group. This yields the **quadratic character shield**: if the candidate progression can be assigned local Legendre signs making every earlier modulus have Jacobi sign `+1`, then all earlier Type A/B traps are avoided automatically. The sign-selection problem is a finite linear system over `F_2`.

A solvable character system therefore gives a reduced exact-depth progression independently of the stored sequential witness.

### Small-selector residual-kernel experiment

After exact fiber peeling, [`shadow_small_selector_analyzer.py`](shadow_small_selector_analyzer.py) tests whether the residual small-prime kernel is already solved by a fixed menu

\[
0,\pm1,\ldots,\pm64.
\]

Selector success is an independent constructive existence proof when combined with reverse fiber extension. Failure of the bounded menu is only a proof-mining failure, not a DSC-P counterexample.

## Active proof architecture

\[
\boxed{
\text{direct novelty}
\to
\text{coarse peel}
\to
\text{fiber peel}
\to
\text{quadratic shield / small selector}
\to
\text{bounded small-prime core}
\to
\text{reduced avoiding class}
\to
\text{DSC-P}.
}
\]

## Current k<=1500 assault

The combined workflow commit is:

```text
c508994fb48e6f701f15577352f275df5646cd78
```

The resulting GitHub Actions run is:

```text
run id: 31849103304
status at checkpoint: in progress
k_limit: 1500
search_limit: 3,000,000
selector menu after fiber peeling: 0, ±1, ..., ±64
```

The workflow now executes:

1. exhaustive candidate discovery;
2. independent verifier;
3. coordinate-core locality analysis;
4. coarse shadow-kernel peeling;
5. fiber shadow-kernel peeling;
6. bounded small-selector residual-kernel attack;
7. quadratic character-shield analysis;
8. CENTL symbolic certification;
9. SHA-256 freezing;
10. artifact publication.

No numerical conclusion from this `k<=1500` run is established until every stage completes successfully and the final artifact digest is frozen into the repository.

## Research rule

Every material theorem, conjecture, computational frontier, counterexample search, workflow result, artifact digest, and change in claim boundary should be committed to this repository. Chat discussion is exploratory; **the repository is canonical**.
