# Prime-shift Kneser dichotomy for the classical strong/Type-II corridor

**Status:** proved application of Kneser's theorem  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-FINITE-SHIFT-CORRIDOR.md`, `FAB-KNESER-FULL-STABILIZER-DEFECT.md`  
**Claim boundary:** organizes fixed prime-shift Type-II misses into a pure quadratic-splitting branch and higher even-index defects. It does not prove universal Type-II coverage.

---

## 1. Setup

Let

\[
p\equiv1\pmod4
\]

be prime and let

\[
\boxed{q\equiv3\pmod4}
\]

be a prime shift with

\[
q\ne p.
\]

Put

\[
\boxed{C=\frac{p+q}{4}.}
\]

Then

\[
\gcd(C,q)=1.
\]

Let

\[
G=(\mathbb Z/q\mathbb Z)^\times,
\]

and define the symmetric signed divisor box

\[
\boxed{
R=\mathcal R_q(C).}
\]

The standard Type-II target is

\[
\boxed{-1\in G.}
\]

Let

\[
\boxed{H=\operatorname{Stab}_G(R)}
\]

and

\[
\boxed{n=[G:H].}
\]

Because

\[
1\in R,
\]

one has

\[
\boxed{H\subseteq R.}
\]

---

## 2. A Type-II miss forces odd stabilizer order

Assume

\[
\boxed{-1\notin R.}
\]

Since

\[
q\equiv3\pmod4,
\]

the group `G` has order

\[
q-1=2m
\]

with `m` odd.

The cyclic group `G` has a unique element of order two, namely `-1`.

Every even-order subgroup of a cyclic group contains that unique order-two element.

Therefore if `H` had even order, then

\[
-1\in H\subseteq R,
\]

contradicting the miss.

Hence:

### Theorem — even defect index

Every prime-shift Type-II miss satisfies

\[
\boxed{|H|\text{ odd}}
\]

and therefore

\[
\boxed{n=[G:H]\text{ even}.}
\]

---

## 3. Index two is exactly the pure quadratic branch

Suppose

\[
\boxed{n=2.}
\]

Then `H` is the unique index-two subgroup of `G`, namely the quadratic residues

\[
\boxed{Q=G^2.}
\]

Because `R` is `H`-periodic and contains `1`,

\[
H\subseteq R.
\]

If `R` contained any quadratic nonresidue, then `H`-periodicity would force the complete nonresidue coset into `R`.

That coset contains `-1`, contradiction.

Therefore

\[
R=H=Q.
\]

In particular every prime divisor of `C`, which appears individually in the signed box, is a quadratic residue modulo `q`.

Conversely, if every prime divisor of `C` is a quadratic residue, then the entire signed box lies in `Q`, so `-1` is missed.

The full stabilizer may in that direction be smaller than `Q` unless the box fills `Q`; but the Type-II miss itself is automatic.

Thus the exact `n=2` normal form is pure quadratic splitting.

---

## 4. Any nonresidue factor forces index at least six

Assume the Type-II target is missed and some prime divisor

\[
r\mid C
\]

is a quadratic nonresidue modulo `q`.

Then the signed box contains `r`, so it is not contained in the quadratic-residue subgroup.

Therefore the full stabilizer cannot have index two.

The defect index is even by Section 2.

Also index four is impossible because

\[
v_2(q-1)=1,
\]

so `4` does not divide `q-1` and `G` has no subgroup of index four.

Hence:

### Corollary — splitting-or-high-defect dichotomy

A prime-shift Type-II miss satisfies either:

1. every prime divisor of `C` is a quadratic residue modulo `q`; or
2. the full stabilizer index satisfies
   \[
   \boxed{n\ge6\text{ and }n\text{ is even}.}
   \]

This is the universal form behind the explicit `q=7,11,23` filters.

---

## 5. One-target Kneser budget

Factor

\[
C=\prod_i r_i^{e_i}.
\]

For each local factor define

\[
s_i
=
\min\left(
2e_i+1,
\operatorname{ord}_{G/H}(r_iH)
\right).
\]

Kneser's theorem gives

\[
|R|
\ge
|H|\left(1+\sum_i(s_i-1)\right).
\]

A Type-II miss removes at least one `H`-coset, so

\[
|R|\le(n-1)|H|.
\]

Hence

\[
\boxed{
\sum_i(s_i-1)
\le n-2.}
\]

Thus every higher defect is a low-expansion factorization in the stabilizer quotient.

---

## 6. Safe-prime specialization

Suppose

\[
\boxed{q=2\ell+1}
\]

with `ell` an odd prime.

Then

\[
|G|=2\ell.
\]

The subgroup indices are only

\[
1,2,\ell,2\ell.
\]

Index `1` means the box is all of `G` and therefore hits.

Index `ell` is odd, impossible for a miss by Section 2.

Therefore a Type-II miss has only two possibilities:

\[
\boxed{n=2}
\]

or

\[
\boxed{n=2\ell=q-1.}
\]

That is:

### Theorem — safe-prime miss dichotomy

For a safe prime shift

\[
q=2\ell+1\equiv3\pmod4,
\]

every Type-II miss is either:

1. the pure quadratic-splitting branch; or
2. a full-stabilizer-trivial aperiodic defect.

No intermediate quotient geometry exists.

---

## 7. The small filters as specializations

The shifts

\[
q=7,11,23
\]

are all safe primes:

\[
7=2\cdot3+1,
\qquad
11=2\cdot5+1,
\qquad
23=2\cdot11+1.
\]

Therefore each exact filter has the same architecture:

- main branch: all prime factors of `C` are quadratic residues;
- exceptional branch: the full signed box has trivial stabilizer.

The hard-prime congruences force small QR factors into `C`, which makes the aperiodic branch extremely small:

- at `q=7`, the forced factor `2` eliminates it completely;
- at `q=11`, forced `3` leaves only a two-unit primitive packet;
- at `q=23`, forced `2,3` leave only a two-unit primitive packet in two residue classes.

This explains the parallel exact classifications without treating them as unrelated coincidences.

---

## 8. Research consequence

To find additional useful fixed shifts, prioritize primes

\[
q\equiv3\pmod4
\]

for which:

1. the possible stabilizer indices are sparse, ideally safe primes;
2. hard congruences force one or more generators of the QR subgroup into `(p+q)/4`;
3. those forced local intervals consume most of the aperiodic Kneser budget.

Such shifts contribute a clean half-density main splitting branch and only low-entropy exceptional branches to the consecutive-corridor sieve.
