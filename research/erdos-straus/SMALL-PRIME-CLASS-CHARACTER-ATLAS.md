# Small-prime class-conditioned character and factor-support atlas

**Status:** exact fixed-shift finite-group theorems  
**Date:** 2026-08-16  
**Depends on:** `MORDELL-HARD-CLASS-CONDITIONED-SEED-LAW.md`; fixed-shift Lane-I divisor-square equivalence  
**Primary classifier:** `classify_small_prime_class_character_states.py`  
**Independent realization regression:** `verify_small_prime_class_character_states.py`  
**Claim boundary:** these are range-free statements at individual fixed shifts. They do not give a universal shift ceiling and do not prove Erdős-Straus.

## 1. Purpose

The class-conditioned seed theorem shows that a Mordell-hard residue class can force substantially more arithmetic into a fixed companion

```text
C_k = (p+k)/4
```

than the universal six-class seed alone.

The k=59 atlas already showed that this can annihilate an entire quadratic-character miss branch. The present atlas asks the same exact question at the smaller prime shifts

```text
k = 11, 19, 31, 47.
```

The answer is stronger than a Legendre-symbol restriction. On the rigid branches below, every exact miss state has divisor support entirely inside the quadratic-residue subgroup modulo k. Thus a single nonresidue prime factor of C_k forces a fixed-shift hit.

## 2. Exact state model

For prime k, write

```text
G = (Z/kZ)^x
```

and choose a primitive root so that G is represented by exponent logs modulo k-1.

For a factor residue with log a, one valuation unit in C_k contributes divisor-square exponents

```text
0, a, 2a.
```

Hence the exact transition is

```text
D -> D union (D+a) union (D+2a)
center -> center+a.
```

The two Lane-I targets are the exact divisor-square targets

```text
-1/4 mod k
-C_k mod k.
```

Closing from the complete class-conditioned forced seed under all factor directions therefore gives a finite superset state space containing every actual companion factorization in that hard class.

## 3. Exact closure counts

### k = 11

```text
seed 3   - 25 states - 9 misses - Legendre split +7 / -2
seed 15  - 15 states - 5 misses - Legendre split +5 / -0
```

The hard classes with seed 15 are

```text
h = 169, 289, 529 mod 840.
```

### k = 19

```text
seed 1   - 439 states - 136 misses - Legendre split +81 / -55
seed 5   - 132 states - 44 misses  - Legendre split +28 / -16
seed 7   - 51 states  - 18 misses  - Legendre split +15 / -3
seed 35  - 27 states  - 9 misses   - Legendre split +9 / -0
```

The hard class with seed 35 is

```text
h = 121 mod 840.
```

### k = 31

```text
seed 2   - 760 states - 118 misses - Legendre split +88 / -30
seed 10  - 75 states  - 18 misses  - Legendre split +18 / -0
seed 14  - 153 states - 23 misses  - Legendre split +22 / -1
seed 70  - 45 states  - 15 misses  - Legendre split +15 / -0
```

The seed-10 classes are

```text
h = 169, 289 mod 840,
```

and the seed-70 class is

```text
h = 529 mod 840.
```

### k = 47

```text
seed 6   - 1,079 states - 196 misses - Legendre split +116 / -80
seed 42  - 97 states    - 24 misses  - Legendre split +24 / -0
```

The seed-42 classes are

```text
h = 121, 289 mod 840.
```

The k=47 result corrects the earlier temptation to extrapolate from the universal forced-6 closure. The universal seed leaves 80 negative-character abstract misses. The exact hard classes h=121 and h=289 force the additional factor 7, replacing seed 6 by seed 42 and eliminating that branch exactly.

## 4. Range-free character corollaries

The exact closures give the following fixed-shift theorems.

For every Mordell-hard prime p:

```text
p = 169, 289, or 529 mod 840
and (11/p) = -1
=> k=11 hits.
```

```text
p = 121 mod 840
and (19/p) = -1
=> k=19 hits.
```

```text
p = 169, 289, or 529 mod 840
and (31/p) = -1
=> k=31 hits.
```

```text
p = 121 or 289 mod 840
and (47/p) = -1
=> k=47 hits.
```

Together with the already-landed k=59 class theorem,

```text
p = 361 mod 840
and (59/p) = -1
=> k=59 hits.
```

These are not finite-census extrapolations. Each follows from an exact finite-group closure after consuming a divisor forced for every integer in the specified congruence class.

## 5. Stronger QR-only factor-support theorem

The character statement is only the projection of the exact result.

Let Q_k be the quadratic-residue subgroup of `(Z/kZ)^x`. For every annihilated branch listed above, the classifier verifies both of the following:

1. every miss-state center lies in Q_k, and the center projection covers the complete QR set;
2. every residue represented in every miss-state divisor mask lies in Q_k.

The second fact has an immediate arithmetic meaning.

Every prime factor q of C_k appears as the exponent-one divisor residue q mod k inside the exact divisor-square box. Therefore, if an actual companion contained a prime factor satisfying

```text
(q/k) = -1,
```

the realized divisor mask would contain a nonresidue and could not equal any exact miss state in the rigid closure.

Hence, on each rigid branch,

```text
fixed k misses
=> every prime factor q of C_k satisfies (q/k)=+1.
```

Conversely, if every prime factor of C_k is a quadratic residue modulo a prime k congruent to 3 mod 4, then every divisor of C_k^2 is a quadratic residue, while both fixed-shift targets are nonresidues:

```text
-1/4 is a nonresidue because -1 is a nonresidue,
-C_k is a nonresidue because C_k is a residue.
```

Thus the rigid branches admit the exact support formulation

```text
fixed k misses
<=> C_k has only quadratic-residue prime support modulo k.
```

This support form is the useful one for cross-shift work.

## 6. Survivor decision tree

A prime surviving all currently relevant rigid shifts must satisfy the following necessary support conditions.

```text
h = 1
  no condition from this small-prime atlas yet

h = 121
  (19/p) = +1
  (47/p) = +1
  C_19 has QR-only prime support mod 19 if k=19 misses
  C_47 has QR-only prime support mod 47 if k=47 misses

h = 169
  (11/p) = +1
  (31/p) = +1
  C_11 has QR-only prime support mod 11 if k=11 misses
  C_31 has QR-only prime support mod 31 if k=31 misses

h = 289
  (11/p) = +1
  (31/p) = +1
  (47/p) = +1
  C_11, C_31, C_47 carry the corresponding QR-only support conditions

h = 361
  existing k=59 theorem forces (59/p) = +1 after a k=59 miss

h = 529
  (11/p) = +1
  (31/p) = +1
  C_11 and C_31 carry the corresponding QR-only support conditions
```

The h=289 branch is currently the most character-constrained small-prime branch.

## 7. Why this matters for the six-companion wheel

The six-companion theorem proves that, after stripping the universal seeds, prime supports in one six-shift wheel are almost completely disjoint: every rational prime other than 2 and 5 can occur in at most one residual layer.

The present atlas now supplies a different kind of information: on selected miss branches, the complete prime support of a companion is restricted to an index-two residue subgroup.

The theorem-mining target is therefore no longer merely

```text
force incompatible Legendre signs for p.
```

It is the stronger support-allocation problem

```text
can six nearly coprime residuals simultaneously allocate all of their prime factors
inside the subgroup required by every fixed-shift miss state?
```

This is the natural point at which the class-conditioned character atlas and the six-companion support theorem meet.

## 8. Independent finite realization check

The independent verifier does not use the abstract state masks to decide a finite target. It factors C_k directly, constructs the divisor-square residue box, and checks the two exact targets.

At p <= 100,000 the rigid branches give:

```text
k=11, h=169 - 43 primes - 21 negative-character primes - 0 negative misses
k=11, h=289 - 45 primes - 25 negative-character primes - 0 negative misses
k=11, h=529 - 50 primes - 26 negative-character primes - 0 negative misses
k=19, h=121 - 50 primes - 29 negative-character primes - 0 negative misses
k=31, h=169 - 43 primes - 25 negative-character primes - 0 negative misses
k=31, h=289 - 45 primes - 27 negative-character primes - 0 negative misses
k=31, h=529 - 50 primes - 29 negative-character primes - 0 negative misses
k=47, h=121 - 50 primes - 28 negative-character primes - 0 negative misses
k=47, h=289 - 45 primes - 24 negative-character primes - 0 negative misses
```

Every directly realized miss in the same regression has QR-only prime factor support for its modulus.

The finite counts are regression anchors only. The range-free theorem comes from the complete finite-group closure.

## 9. Reproduction

Run the exact atlas with

```sh
python3 research/erdos-straus/classify_small_prime_class_character_states.py --json
```

and the independent finite realization regression with

```sh
python3 research/erdos-straus/verify_small_prime_class_character_states.py --limit 100000 --json
```

Erdős-Straus remains open. The next theorem target is to combine these QR-only support constraints with the six-companion residual-support disjointness rather than treating the fixed shifts independently.
