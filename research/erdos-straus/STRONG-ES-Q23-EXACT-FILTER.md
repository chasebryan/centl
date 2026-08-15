# Exact q=23 filter for Mordell-hard primes in the strong/Type-II corridor

**Status:** proved exact factorization criterion  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-FINITE-SHIFT-CORRIDOR.md`, `STRONG-ES-Q11-EXACT-FILTER.md`  
**Claim boundary:** classifies the fixed Type-II shift `q=23` for Mordell-hard primes. It does not prove the strong conjecture or Erdős--Straus.

---

## 1. Two forced factors

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+23}{4}.}
\]

Hard primes satisfy

\[
p\equiv1\pmod{24}.
\]

Therefore

\[
p+23\equiv24\equiv0\pmod{24},
\]

and hence

\[
\boxed{6\mid C.}
\]

So both `2` and `3` are forced prime factors of `C`.

The fixed-shift Type-II target is

\[
\boxed{-1\in\mathcal R_{23}(C).}
\]

---

## 2. The quadratic-residue subgroup modulo 23

The unit group

\[
G=(\mathbb Z/23\mathbb Z)^\times
\]

is cyclic of order `22`.

Its quadratic-residue subgroup

\[
Q=G^2
\]

has prime order

\[
\boxed{11.}
\]

Both forced factors have exact order `11` modulo `23`:

\[
\boxed{\operatorname{ord}_{23}(2)=11,}
\]

\[
\boxed{\operatorname{ord}_{23}(3)=11.}
\]

Thus each is a generator of `Q`.

Use `2` as a generator of `Q`. Then

\[
\boxed{3\equiv2^8\pmod{23}.}
\]

So in additive `C_11` coordinates the forced simple factors contribute directions

\[
1
\qquad\text{and}\qquad
8=-3.
\]

---

## 3. The forced simple box occupies nine of eleven QR classes

Assume first

\[
v_2(C)=v_3(C)=1.
\]

The signed local contribution from the two forced factors is

\[
\boxed{
F
=
\{a+8b\pmod{11}:a,b\in\{-1,0,1\}\}.}
\]

Direct calculation gives

\[
\boxed{
F
=
\{0,1,2,3,4,7,8,9,10\}.}
\]

Thus

\[
\boxed{|F|=9}
\]

and only the two QR coordinates

\[
\boxed{5,6}
\]

are missing.

---

## 4. Any extra nontrivial QR factor fills the whole subgroup

Let `c` be any nonzero element of `C_11`.

A simple additional nontrivial QR factor contributes

\[
\{0,c,-c\}.
\]

For every nonzero `c`, one checks

\[
\boxed{
F+\{0,c,-c\}=C_{11}.}
\]

Likewise if either forced factor occurs to exponent at least two, its longer local interval fills the two missing QR coordinates when combined with the other forced factor.

Therefore the complete QR subgroup is filled whenever any one of the following holds:

\[
\boxed{
v_2(C)\ge2,}
\]

\[
\boxed{
v_3(C)\ge2,}
\]

or `C` has any further prime factor that is a nontrivial quadratic residue modulo `23`.

Once the QR subgroup is full, the presence of any quadratic-nonresidue factor translates it onto the full NR coset, which contains `-1`.

Thus in all those cases a miss is possible only under pure quadratic splitting.

---

## 5. Which simple nonresidue factors can evade the forced box

Continue in the thin case

\[
\boxed{v_2(C)=v_3(C)=1}
\]

with no other nontrivial QR factor.

Use primitive root `5 mod23` for the full group `C_22`. The forced QR set `F` corresponds to the even logarithm classes

\[
2F\subset C_{22}.
\]

Let a simple quadratic-nonresidue factor have odd log class `c`.

Its local signed set is

\[
\{0,c,-c\}.
\]

The target is class `11`.

A direct check shows

\[
11\notin2F+\{0,c,-c\}
\]

only for

\[
\boxed{c=\pm1\pmod{22}.}
\]

These two primitive classes are the residues

\[
\boxed{5,14\pmod{23}.}
\]

Every other quadratic-nonresidue residue class forces a Type-II hit immediately.

The class `-1=22 mod23` of course hits the target directly.

---

## 6. The surviving primitive pair has valuation at most two

The residues `5` and `14` are inverses modulo `23` and correspond to log classes `±1`.

If their total valuation is `E`, their combined signed contribution is the interval

\[
\boxed{
P_E=\{-E,-E+1,\ldots,E\}\pmod{22}.}
\]

For `E<=2`, the only odd classes present are `±1`, and the target remains outside `2F+P_E`.

For `E>=3`, the classes `±3` appear. Since the forced QR set contains the required complementary even classes, one obtains target class `11`.

Therefore a thin miss requires

\[
\boxed{E\le2.}
\]

---

## 7. Exact q=23 miss theorem

For a Mordell-hard prime `p`, let

\[
C=\frac{p+23}{4}.
\]

Then `q=23` misses exactly in one of the following two cases.

### Branch A: pure quadratic splitting

Every prime factor of `C` is a quadratic residue modulo `23`.

### Branch B: forced-6 thin defect

All of the following hold:

1. \[
   \boxed{v_2(C)=v_3(C)=1};
   \]
2. every other quadratic-residue prime factor is actually `1 mod23`;
3. the only allowed quadratic-nonresidue prime factors are
   \[
   \boxed{5,14\pmod{23}};
   \]
4. their total valuation satisfies
   \[
   \boxed{
   \sum_{r^e\parallel C,\ r\equiv5,14\ (23)}e\le2.}
   \]

No other miss geometry is possible.

---

## 8. Sieve density of the thin branch

Ignoring the finite exceptional primes `2` and `3`, Branch B allows ordinary prime factors only in the three reduced residue classes

\[
\boxed{1,5,14\pmod{23}.}
\]

Thus ordinary primes in

\[
\boxed{19\text{ of the }22}
\]

reduced residue classes modulo `23` are forbidden as factors of `C`.

The exact valuation cap on the two nonresidue classes makes the true Branch-B set even thinner.

This will be useful when the `q=23` filter is inserted into the consecutive-corridor sieve.

---

## 9. Consecutive corridor position

With

\[
A=\frac{p+3}{4},
\]

one has

\[
\boxed{C=A+5.}
\]

Thus the corridor now contains exact splitting/defect laws at

\[
A,\quad A+1,\quad A+2,\quad A+5
\]

for shifts

\[
3,7,11,23.
\]

The `q=23` position is especially rigid because two independent generators of the QR subgroup are forced into `A+5` by the Mordell-hard congruence `p=1 mod24`.

---

## 10. Next target

Combine `q=23` with the existing `q=3,7,11` sieve.

Since Branch A excludes half the prime residue classes modulo `23`, while Branch B excludes `19/22` of them, **every** `q=23` miss branch adds at least one-half unit of sieve dimension.

This should raise the three-shift exponent `5/2` to a four-shift exponent `3`.
