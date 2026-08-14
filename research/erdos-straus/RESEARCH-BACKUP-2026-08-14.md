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

The run completed successfully through:

1. discovery of every directly novel candidate;
2. independent verification;
3. coordinate-core proof mining;
4. CENTL exact symbolic certification;
5. per-file SHA-256 verification;
6. artifact upload.

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

The active proof strategy is now:

\[
\text{directly novel candidate}
\to
\text{fiber peeling}
\to
\text{small-prime residual kernel}
\to
\text{prove a reduced local survivor}
\to
\text{DSC-P}.
\]

## Next configured computational assault

The workflow is configured to attack:

```text
k_limit      = 1500
search_limit = 3,000,000
```

This crosses the earlier record-depth region around `k=1403` and `k=1435` while applying both coarse and fiber kernel reduction.

No future run is to be promoted to an established result until discovery, independent verification, CENTL certification, hashes, and artifact publication all complete successfully.

## Research rule

Every material theorem, conjecture, computational frontier, counterexample search, artifact digest, and change in claim boundary should be committed to this repository. Chat discussion is exploratory; the repository is canonical.
