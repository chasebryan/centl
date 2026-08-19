# BARE q23 square-lift refinement

**Status:** exact module inside the candidate Type-II decomposition framework  
**Date:** 2026-08-16  
**Primary classifier:** `classify_bare_q23_square_lift_refinement.py`  
**Independent verifier:** `verify_bare_q23_square_lift_refinement.py`  
**Depends on:** `K19-REALIZED-PAIR-SURVIVOR-NORMAL-FORM.md`, `Q23-SQUARE-LIFT-PHASE-SIEVE.md`, `TYPEII-CANDIDATE-DECOMPOSITION-FRAMEWORK.md`  
**Claim boundary:** this is a proved refinement module, not a decomposition method. BARE-center compatibility is necessary but not sufficient for BARE; actual BARE additionally requires every prime factor of the remaining k19 cofactor to be `1 mod19`.

## 1. Why BARE is a distinct framework state

On the two realized h169 pair routes, k19 has a lossless two-mode miss normal form:

- `FULL_QR`;
- `BARE`.

BARE fixes both the seven-element divisor mask and the k19 center.

The centers are

- Route A `q17+q23 -> k19`: `p mod19=6`;
- Route B `q23+q47 -> k19`: `p mod19=11`.

BARE also forces the residual cofactor R in

`C19 = S R`

to have every prime factor congruent to1 modulo19.

This is stronger than merely knowing `(19/p)=+1`.

## 2. Parent q23 square-lift sieve

The canonical q23^2 Type-II event on h169 is possible only on the13 valuation phases

```text
0,3,5,6,8,11,12,14,15,17,18,20,21.
```

At phase n,

`k_n=19+92n`

and the canonical event has

`p = k_n(2116s-1)-2116`.

The BARE state adds the exact p residue modulo19.

## 3. BARE removes n=0

Intersecting the canonical event with either BARE center removes phase0.

The surviving BARE-center-compatible phases are exactly

```text
3,5,6,8,11,12,14,15,17,18,20,21.
```

There are12.

The structural reason is stronger than the congruence calculation.

At n=0 the q23^2 lift would occur at k19 itself.

But BARE has

- Route A: `C19=17*23*R`;
- Route B: `C19=23*47*R`;

with every prime factor of R equal to1 modulo19.

Since

`23 mod19=4`,

R cannot contain another factor23.

Therefore

`23^2` cannot divide `C19`

in BARE mode.

So the square-lift phase n=0 is impossible before any search.

## 4. Route-A BARE-center progressions

Route A additionally requires

`p mod17=15`

and

`p mod19=6`.

For each of the12 surviving phases there is exactly one s progression:

```text
n   k      s0      T
3   295    11811   13566
5   479    65801   67830
6   571    17976   67830
8   755    10478   13566
11  1031   61421   67830
12  1123   7806    67830
14  1307   18296   67830
15  1399   43791   67830
17  1583   31901   67830
18  1675   654     13566
20  1859   55076   67830
21  1951   38421   67830
```

These progressions impose the hard class, route ancestry, BARE center, and canonical q23^2 quotient congruence.

They do not by themselves prove the factor-support condition on R.

## 5. Route-B BARE-center progressions

Route B requires

`p mod47=28`

and

`p mod19=11`.

The exact progressions are

```text
n   k      s0       T
3   295    30123    37506
5   479    39761    187530
6   571    49476    187530
8   755    4178     37506
11  1031   19841    187530
12  1123   19566    187530
14  1307   16406    187530
15  1399   180081   187530
17  1583   37151    187530
18  1675   30306    37506
20  1859   80486    187530
21  1951   164841   187530
```

Again these are candidate progressions for the exact BARE center, not a sufficient BARE theorem.

## 6. Necessary center versus actual BARE support

This distinction is essential to the candidate decomposition framework.

A canonical candidate can satisfy

- h169;
- the route residue;
- the BARE p center modulo19;
- the q23^2 canonical Type-II congruence;

while still failing to be BARE because its residual cofactor R contains a prime not equal to1 modulo19.

Therefore the framework state must preserve the exact support theorem, not replace it with a center congruence.

## 7. Earliest persistent Route-A BARE canonical anchor

The independent verifier exhausts all40 BARE-center-compatible canonical candidates through

`p=159,799,693,369`.

Among them:

- 8 are prime;
- 2 have actual BARE residual support;
- only 1 also preserves the earlier k23 miss.

That earliest persistent BARE anchor is

`p=159,799,693,369`.

It occurs at

`n=3`, `k=295`, `s=255999`.

Its k19 companion is

`C19=39,949,923,347=17*23*102,173,717`,

where

`102,173,717 mod19=1`.

Thus the k19 state is genuinely BARE.

Its adjacent companion is

`C23=39,949,923,348=2^2*3^2*1,109,720,093`,

and k23 still misses in the rigid QR23 state.

At the q23 square lift,

`C295=39,949,923,416=2^3*13*23^2*41*89*199`.

The canonical quotient is

`Q=C295/23^2=75,519,704`,

with

`Q=-1 mod295`.

The canonical Type-II divisor hits, and the Type-I target also hits.

So this persistent BARE lift terminates as an **I+II** signed-box event.

## 8. Earlier Route-A BARE candidate excluded by framework ancestry

There is an earlier actual BARE canonical prime

`p=81,757,751,209`

at

`n=8`, `k=755`, `s=51176`.

Its k19 state is genuinely BARE:

`C19=17*23*52,274,777`

with

`52,274,777 mod19=1`.

The canonical q23^2 Type-II event also exists at k755.

However k23 has already hit for this prime.

Therefore it is not a member of the persistent simultaneous k19/k23 survivor state.

This is an important control: the developing framework must preserve ancestry and earlier termination conditions. A later algebraic pattern is not automatically a transition of the survivor machine.

## 9. Earliest persistent Route-B BARE canonical anchor

The verifier exhausts all18 BARE-center-compatible canonical candidates through

`p=182,687,343,889`.

Among them:

- 3 are prime;
- 1 has actual BARE residual support;
- that same candidate preserves the k23 miss.

The earliest persistent BARE anchor is therefore

`p=182,687,343,889`.

It occurs at

`n=3`, `k=295`, `s=292665`.

Its k19 companion is

`C19=45,671,835,977=23*47*42,249,617`,

with

`42,249,617 mod19=1`.

Its adjacent companion is

`C23=45,671,835,978=2*3^2*2,537,324,221`,

and k23 still misses.

At the square lift,

`C295=45,671,836,046=2*23^2*43*1,003,909`.

The canonical quotient is

`Q=86,336,174`,

with

`Q=-1 mod295`.

Here the Type-I target is absent.

The lift is therefore **Type-II-only**.

## 10. Interpretation inside the candidate framework

BARE survives into the valuation layer and can terminate in more than one full signed-box geometry.

The observed earliest persistent anchors give

- Route A BARE -> canonical lift -> I+II;
- Route B BARE -> canonical lift -> Type-II-only.

This reinforces the current architecture:

- survivor signature matters;
- ancestry matters;
- residual support matters;
- valuation phase matters;
- full signed-box geometry remains the terminal test.

No one coordinate is the decomposition method by itself.

## 11. What this module contributes toward closure

This theorem makes one genuine framework transition smaller:

```text
BARE k19 survivor
    + persistent k23 miss
    + q23 valuation ladder
        -> 12 canonical phases instead of 13
```

It also proves that BARE cannot be discarded as a transient state before valuation analysis.

What remains open is the framework-level question:

> can every persistent BARE state either be forced into a terminal signed-box hit or mapped to a strictly smaller survivor signature under a proved well-founded progress measure?

That is not yet established.

This document is therefore a proved module of the candidate decomposition framework, not a decomposition theorem.
