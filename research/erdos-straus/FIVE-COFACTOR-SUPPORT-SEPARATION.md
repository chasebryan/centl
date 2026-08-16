# Five-cofactor support separation on the realized h169 routes

**Status:** exact algebraic module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_five_cofactor_support_separation.py`  
**Depends on:** the realized k19 route coupling and the landed post-k23 companion ladder  
**Claim boundary:** exact route-local coprimality theorem. It is not a termination theorem, a universal decomposition method, or an Erdős–Straus proof.

## 1. Route coordinates

Write

`p = 169 + 840t`

and

`C19 = (p+19)/4 = 47 + 210t`.

On the two realized k19 routes,

```text
Route A: C19 = 391 R  = 17*23*R
Route B: C19 = 1081 R = 23*47*R.
```

Let

`S in {391,1081}`

so that

`C19 = S R`.

The post-k23 companion coordinates are

```text
C23 =  6B = S R + 1
C27 =  7E = S R + 2
C31 = 10D = S R + 3
C35 =  3F = S R + 4,
```

where

```text
B = 8  + 35t
E = 7  + 30t
D = 5  + 21t
F = 17 + 70t.
```

## 2. Previously visible four-way separation

The consecutive-companion identities give

```text
7E  - 6B  = 1
10D - 7E  = 1
5D  - 3B  = 1
F   - 2B  = 1
3F  - 10D = 1
3F  - 7E  = 2.
```

Hence

```text
gcd(B,E)=gcd(B,D)=gcd(B,F)=1
gcd(E,D)=gcd(D,F)=1.
```

For E and F, the last relation says the gcd divides 2. But

`E=7+30t`

and

`F=17+70t`

are both odd, so

`gcd(E,F)=1`.

Thus B,E,D,F are pairwise coprime.

## 3. R is also disjoint from every later dynamic cofactor

The route equations themselves give the missing four relations.

### R versus B

`6B - SR = 1`.

Therefore

`gcd(R,B)=1`.

### R versus E

`7E - SR = 2`.

Any common divisor of R and E divides 2.

Now C19 is odd and S is odd, so R is odd. E is also odd. Hence

`gcd(R,E)=1`.

### R versus D

`10D - SR = 3`.

Any common divisor of R and D divides 3.

But

`C19 = 47 + 210t = 2 mod3`,

while both route seeds satisfy

`391 = 1 mod3`

and

`1081 = 1 mod3`.

Therefore

`R = 2 mod3`

on either route, so 3 does not divide R. Hence

`gcd(R,D)=1`.

### R versus F

`3F - SR = 4`.

Any common divisor of R and F divides 4. Both R and F are odd, so

`gcd(R,F)=1`.

## 4. Five-way theorem

### Theorem

On either realized h169 route,

`R, B, E, D, F`

are pairwise coprime.

Equivalently,

`gcd(X,Y)=1`

for every distinct pair

`X,Y in {R,B,E,D,F}`.

This is range-free. It follows only from the exact affine companion identities, parity, and the fixed mod-3 route residue.

## 5. Support-separation consequence

A branch surviving the already proved local modules carries separate rational-prime reservoirs:

```text
R : k19 survivor support
B : k23 survivor support
E : k27 survivor grammar
D : k31 survivor support
F : k35 survivor branch.
```

No rational prime can occur in two of these five dynamic cofactors.

For a simultaneous survivor the existing modules further require, schematically,

```text
R : QR19 support, strengthened to 1 mod19 in k19 BARE mode
B : QR23 support
E : one of the exact k27 survivor grammars
D : QR31 support
F : J35 or S7.
```

The important new fact is that these constraints cannot be satisfied by reusing the same prime factor across coordinates. Every surviving compartment is arithmetically disjoint from the others.

## 6. Why this matters for the candidate machine

The local state is no longer merely a list of five congruence conditions. It is a product of five **disjoint support systems** tied together by four consecutive companion equations:

```text
SR
SR+1 = 6B
SR+2 = 7E
SR+3 = 10D
SR+4 = 3F.
```

That is structurally useful for any future contradiction or progress measure. A proof that one support system must import a prime already forced into another would now terminate the branch immediately, because support overlap is impossible.

Likewise, character constraints on one compartment cannot be discharged by silently recycling a favorable prime from another compartment.

## 7. Next target

The next high-value object is the exact residual intersection

`R19 x B23 x G27(E) x R31 x G35(F)`

subject to

1. the five-way coprimality theorem;
2. the affine companion chain;
3. the landed k39 phase restriction;
4. the k43 selector shell;
5. the k47 phase restriction.

The goal is a branch-local selector or contradiction, not another unconditioned census.

Erdős–Straus remains open.
