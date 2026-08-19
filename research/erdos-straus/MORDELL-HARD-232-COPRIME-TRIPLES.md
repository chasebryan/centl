# Mordell-hard `2-3-2` coprime companion triples

**Status:** proved elementary cross-shift theorem  
**Date:** 2026-08-16  
**Depends on:** `MORDELL-HARD-FORCED-SEED-LAW.md`  
**Regression:** `verify_mordell_hard_232_triples.py`  
**Claim boundary:** this is an exact structural relation between three neighboring fixed-shift companions. It does not by itself prove that one of the three shifts must hit the Erdős–Straus targets.

## 1. The recurring `2-3-2` shift block

Let `p` be Mordell-hard, so

\[
p=24m+1.
\]

Take any nonnegative integer `t` and the three admissible shifts

\[
\boxed{
k_0=24t+7,
\qquad
k_1=24t+11,
\qquad
k_2=24t+15.
}
\]

Their `u=(k+1)/4` values are

\[
6t+2,\qquad6t+3,\qquad6t+4.
\]

By the universal hard forced-seed law, the mandatory seeds are therefore

\[
\boxed{2,\ 3,\ 2.}
\]

This produces the repeating blocks

```text
(7, 11, 15)
(31, 35, 39)
(55, 59, 63)
(79, 83, 87)
(103, 107, 111)
...
```

## 2. Exact residual normal form

Put

\[
n=m+t.
\]

Then

\[
C_{k_0}=\frac{p+k_0}{4}
=6n+2
=2(3n+1),
\]

\[
C_{k_1}=\frac{p+k_1}{4}
=6n+3
=3(2n+1),
\]

and

\[
C_{k_2}=\frac{p+k_2}{4}
=6n+4
=2(3n+2).
\]

Define the seed-stripped residuals

\[
\boxed{
A=3n+1,
\qquad
B=2n+1,
\qquad
D=3n+2.
}
\]

Then the companion triple is exactly

\[
\boxed{
(C_{k_0},C_{k_1},C_{k_2})=(2A,3B,2D).
}
\]

Since `D=A+1`, the three actual companions are consecutive integers:

\[
\boxed{
C_{k_1}=C_{k_0}+1,
\qquad
C_{k_2}=C_{k_0}+2.
}
\]

## 3. Unimodular residual relations

The residuals satisfy three determinant-one relations:

\[
2A-3B=-1,
\]

\[
3B-2D=-1,
\]

and

\[
D-A=1.
\]

Equivalently,

\[
\boxed{
3B=2A+1=2D-1,
\qquad
D=A+1.
}
\]

These are exact identities, not congruences.

## 4. Pairwise coprimality theorem

Any common divisor of `A` and `B` divides

\[
2A-3B=-1,
\]

so

\[
\gcd(A,B)=1.
\]

Any common divisor of `B` and `D` divides

\[
3B-2D=-1,
\]

so

\[
\gcd(B,D)=1.
\]

Finally `D-A=1`, hence

\[
\gcd(A,D)=1.
\]

Therefore:

### Theorem — `2-3-2` coprime residual triple

For every Mordell-hard prime and every block

\[
(24t+7,24t+11,24t+15),
\]

the three seed-stripped fixed-shift companions are pairwise coprime:

\[
\boxed{
\gcd(A,B)=\gcd(B,D)=\gcd(A,D)=1.
}
\]

Thus no rational prime can occur in the residual factorization of two different members of the same `2-3-2` block.

## 5. Exact gcds of the unstripped companions

Since

\[
(C_{k_0},C_{k_1},C_{k_2})=(2A,3B,2D)
\]

and `A,B,D` are pairwise coprime, while adjacent companions are consecutive, one obtains

\[
\boxed{
\gcd(C_{k_0},C_{k_1})=1,
}
\]

\[
\boxed{
\gcd(C_{k_1},C_{k_2})=1,
}
\]

and

\[
\boxed{
\gcd(C_{k_0},C_{k_2})=2.
}
\]

So the common factor 2 of the two outer companions is exactly their universal seed and nothing more.

## 6. Factor-support disjointness

Let

\[
\operatorname{Supp}(N)=\{q:q\text{ prime},\ q\mid N\}.
\]

The theorem gives

\[
\boxed{
\operatorname{Supp}(A),
\operatorname{Supp}(B),
\operatorname{Supp}(D)
\text{ are pairwise disjoint}.
}
\]

This is the key cross-shift consequence for exact state analysis.

A prime used as a nontrivial packet direction in the seed-stripped state at one member of a `2-3-2` block cannot simultaneously supply a packet at either of the other two members.

The forced primes `2` and `3` are the only shared structural resources, and those have already been consumed into the seeds.

## 7. The two currently classified blocks

### Block `(31,35,39)`

Here `t=1`. The universal seeds are

\[
2,\ 3,\ 2.
\]

The existing k=31 valuation theorem already incorporates the forced factor 2. The new hard reductions give only 64 miss states at k=35 and 36 at k=39.

The residual factor supports for all three shifts are pairwise disjoint by this theorem.

### Block `(55,59,63)`

Here `t=2`. Write

\[
A=3m+7,
\qquad
B=2m+5,
\qquad
D=3m+8.
\]

Then

\[
\boxed{
C_{55}=2A,
\quad
C_{59}=3B,
\quad
C_{63}=2D,
}
\]

with

\[
\boxed{3B=2A+1,\qquad D=A+1.}
\]

The exact hard miss tables currently have sizes

```text
k=55    314
k=59  5,869
k=63     87
```

but their residual prime supports cannot overlap. Any simultaneous cross-shift obstruction must therefore be assembled from three disjoint rational-prime sets satisfying the two linear determinant-one identities above.

## 8. The corrected 100M tail sits in the next block

The unique corrected 100M corridor survivor after k=63 is

\[
p=8,803,369.
\]

Its first later hit is at k=107.

The shift 107 is the middle member of the next `2-3-2` block

\[
\boxed{(103,107,111).}
\]

Accordingly,

\[
3\mid C_{107}
\]

is not an isolated accident. It is the middle seed of the same universal block structure.

For this prime, k=103 misses and k=107 hits. Since the hit occurs at the middle member, k=111 is not needed for its finite certificate.

## 9. Research consequence

The fixed-shift proof problem should no longer treat neighboring seeded layers as independent factorization states.

For every `2-3-2` block, after consuming the mandatory seeds, the residual data live on the rigid Diophantine skeleton

\[
\boxed{
A,\quad B=\frac{2A+1}{3},\quad A+1,
}
\]

with pairwise disjoint prime supports.

A universal cross-shift theorem may therefore be attacked by combining:

1. the reduced miss-state constraints at the three moduli;
2. pairwise disjoint residual prime supports;
3. the exact linear relations `2A-3B=-1` and `3B-2D=-1`;
4. quadratic/Jacobi character restrictions on the allowed packet directions.

That is a strictly smaller and more structured problem than intersecting three generic fixed-shift state tables.

## 10. Reproduction

```sh
python3 research/erdos-straus/verify_mordell_hard_232_triples.py --max-t 10000 --json
```

The verifier checks the normal form, determinant-one identities, pairwise residual gcds, and exact companion gcds throughout the requested symbolic test range.

Erdős–Straus remains open. This theorem supplies an exact cross-shift bridge between the seed-reduced fixed-shift state spaces.
