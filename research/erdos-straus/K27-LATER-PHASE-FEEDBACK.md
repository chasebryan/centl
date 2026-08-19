# Later phase coordinates feed back into k27

**Status:** exact cross-shift dependency module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k27_later_phase_feedback.py`  
**Depends on:** `K27-SURVIVOR-GRAMMAR.md`, `K27-QR-FACTOR-MODE-SELECTORS.md`, and the landed phase restrictions at k31/k39/k43/k47/k51/k55.  
**Claim boundary:** exact necessary restrictions on the k27 nonresidue-skeleton mode and one exact phase exclusion. This is not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. The phase envelope is not downstream-only

For h169,

`C27 = 7E`,

with

`E = 7 + 30t`.

The later local machine already retains several residues of t because they control survival at other shifts:

```text
t mod13   k39 phase coordinate
t mod17   k51 phase coordinate
t mod31   k31 phase coordinate
t mod43   k43 phase coordinate
t mod47   k47 phase coordinate
t mod11   k55 phase coordinate.
```

Those same residues also determine whether the corresponding rational prime divides E.

For any prime q not dividing30,

`q | E <=> t = -7*30^(-1) mod q`.

Therefore a phase coordinate introduced for one shift can force a prime factor into the earlier k27 cofactor and restrict the exact k27 survivor mode.

This is genuine cross-shift feedback. It is arithmetic, not scheduling metadata.

## 2. Exact feedback table

The relevant phase/factor coincidences are:

```text
phase condition   forced factor of E   residue mod27   k27 NR-skeleton consequence
---------------------------------------------------------------------------------
t mod11 = 6       11                   11              {B,F}
t mod13 = 8       13                   13              {Q,E}
t mod17 = 6       17                   17              {B,D}
t mod19 = 8       19                   19              {Q}
t mod31 = 7       31                    4              {Q,A,D}
t mod43 = 27      43                   16              {Q}
t mod47 = 17      47                   20              HIT
```

Here the named k27 mode is the landed **nonresidue-skeleton behavioral mode before QR completion**.

The t mod19 row is the previously landed Q-selector theorem. The other rows are new cross-coordinate consequences of the same exact k27 state model.

## 3. Why the QR rows work

Rational primes 13,19,31,43 are QR27 residues:

```text
13 -> QR residue13
19 -> QR residue19
31 -> QR residue4
43 -> QR residue16.
```

From the exact k27 QR transition table, one occurrence leaves these possible initial skeleton modes:

```text
r=13 -> {Q,E}
r=19 -> {Q}
r=4  -> {Q,A,D}
r=16 -> {Q}.
```

Thus:

```text
t mod13=8  AND k27 miss -> k27_NR_mode in {Q,E}
t mod19=8  AND k27 miss -> k27_NR_mode = Q
t mod31=7  AND k27 miss -> k27_NR_mode in {Q,A,D}
t mod43=27 AND k27 miss -> k27_NR_mode = Q.
```

The last and the t mod19 rule also imply full QR27 support of E because Q is the empty NR skeleton and is stable under arbitrary QR completion.

## 4. Why the nonresidue rows work

Rational primes 11,17,47 are NR27 residues.

The landed complete NR-skeleton atlas shows:

- every surviving skeleton containing residue11 belongs to mode B or F;
- every surviving skeleton containing residue17 belongs to mode B or D;
- residue20 is an immediate one-occurrence killer and appears in no surviving skeleton.

Therefore

```text
t mod11=6 AND k27 miss -> k27_NR_mode in {B,F}
t mod17=6 AND k27 miss -> k27_NR_mode in {B,D}
t mod47=17             -> k27 hits.
```

The t mod47 statement is unconditional with respect to the rest of E: rational prime47 itself supplies the immediate k27 Type-I target residue20.

## 5. New phase exclusion inside the landed envelope

The standalone k47 phase theorem permits 34 possible survivor phases modulo47, including

`t=17 mod47`.

But simultaneous survival at k27 rules that phase out exactly.

Hence a branch surviving both k27 and k47 must satisfy

`S47* = S47 - {17}`

with

`|S47*| = 33`.

This is a strict refinement of the phase envelope obtained only after cross-shift dependency propagation.

The same phenomenon is not new at t mod11=6 because the landed k55 theorem already excludes phase6. The k27 `{B,F}` restriction there is therefore redundant once k55 survival is assumed, but remains an exact local k27 statement.

## 6. Updated phase-only contraction

Before this feedback theorem, the general h169 phase-only survivor counts through k31/k39/k43/k47/k51/k55 used

```text
15 * 9 * 40 * 34 * 13 * 7
```

classes over the pairwise-coprime phase modulus

`31*13*43*47*17*11 = 152,304,581`.

Simultaneous k27 survival replaces the k47 factor34 by33.

Thus the refined raw phase count is

`15*9*40*33*13*7 = 16,216,200`

classes out of

`152,304,581`.

The fraction reduces to

`113,400 / 1,065,067`

or approximately

`0.10647217498993021`.

This is an exact necessary phase fraction, not a density estimate and not a termination measure.

### Route A

Route A leaves the k47 phase coordinate free. Its conditional phase count therefore sharpens from

`11,566,800`

to

`11,226,600`

classes out of

`170,222,767`,

namely

`1,020,600 / 15,474,797 ≈ 0.06595239989254786`.

### Route B

Route B ancestry fixes

`t=0 mod47`.

Therefore the new exclusion `t!=17 mod47` does not change the Route-B scalar phase volume. Its value is in the mode feedback rows, especially t mod13,17,31,43.

## 7. Mode feedback on already-retained phases

Four of the new mode restrictions occur on phases that the standalone later-shift theorems still allow:

```text
t mod13=8   is allowed by k39, but restricts k27 to {Q,E}
t mod17=6   is allowed by k51, but restricts k27 to {B,D}
t mod31=7   is allowed by k31, but restricts k27 to {Q,A,D}
t mod43=27  is allowed by k43, but forces k27 to Q.
```

So retaining only a scalar phase-volume coordinate throws away useful information. The actual CRT phase is proof-bearing state because it can select the k27 mode.

## 8. Constraint-propagation rules

The exact propagator can add the rules

```text
if tau13 == 8 and k27 misses:
    k27_NR_mode in {Q,E}

if tau17 == 6 and k27 misses:
    k27_NR_mode in {B,D}

if tau31 == 7 and k27 misses:
    k27_NR_mode in {Q,A,D}

if tau43 == 27 and k27 misses:
    k27_NR_mode = Q
    E_support = QR27

if tau47 == 17:
    contradiction with k27 miss.
```

The already-landed rule

```text
if tau19 == 8 and k27 misses:
    k27_NR_mode = Q
```

remains in force.

These implications should be applied before any expensive factor enumeration of E.

## 9. Bryan Entanglement Cross / BREC boundary

This theorem is a good example of why direction should remain separate from truth.

A phase coordinate discovered while moving forward through later shifts reaches backward and constrains k27. Depending on the eventual BEC/BREC vocabulary, that may be useful as backward obstructive pressure, downward excavation, or a compound history annotation.

The directional choice does not affect the arithmetic statement. The forced prime divisor and exact k27 state transition are the only proof-bearing objects.

## 10. Next target

The immediate engineering step is to extend the exact dependency propagator with

`tau13, tau17, tau43, tau47`

and these new mode filters.

The mathematical continuation is to search for **intersections** of the mode selectors. For example, simultaneous phase conditions that demand disjoint k27 mode subsets yield exact contradictions without factoring E at all.

That turns CRT phase collision into a new source of state elimination.