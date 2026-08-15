# Exact q=11 filter for Mordell-hard primes in the strong/Type-II corridor

**Status:** proved exact factorization criterion  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-FINITE-SHIFT-CORRIDOR.md`, `STRONG-ES-Q7-EXACT-FILTER.md`, `FAB-HARD-FIRST-FILTERS.md`  
**Claim boundary:** classifies the fixed Type-II shift `q=11` for Mordell-hard primes. It does not prove the strong conjecture or Erdős--Straus.

---

## 1. Forced factor at q = 11

Let `p` be Mordell-hard. Then

\[
\boxed{p\equiv1\pmod3.}
\]

Put

\[
\boxed{C=\frac{p+11}{4}.}
\]

Since

\[
p+11\equiv1+2\equiv0\pmod3,
\]

we have

\[
\boxed{3\mid C.}
\]

Also `p≡1 mod8`, so `p+11≡4 mod8` and therefore

\[
\boxed{C\text{ is odd}.}
\]

The exact fixed-shift Type-II criterion is

\[
\boxed{-1\in\mathcal R_{11}(C).}
\]

---

## 2. Cyclic coordinate modulo 11

The group

\[
G=(\mathbb Z/11\mathbb Z)^\times
\]

is cyclic of order ten.

Using primitive root `2`, write residues by discrete-log class in

\[
\mathbb Z/10\mathbb Z.
\]

Then:

- quadratic residues are the even classes;
- quadratic nonresidues are the odd classes;
- the target `-1` is class `5`;
- the forced factor
  \[
  3\equiv2^8
  \]
  has class `8=-2`, hence order five.

The residue classes split concretely as

\[
\boxed{
\begin{array}{c|c}
\text{type} & \text{residues mod }11\\
\hline
\text{identity} & 1\\
\text{nontrivial quadratic residues} & 3,4,5,9\\
\text{primitive NR, type I} & 2,6\\
\text{primitive NR, type II} & 7,8\\
\text{order-two target} & 10
\end{array}}
\]

The labels “type I/II” in this table refer only to the two primitive-log orientations inside `C_10`, not to standard Erdős--Straus Type I/II.

---

## 3. Two units of quadratic-residue valuation fill the QR subgroup

Let `Q` be the total signed contribution from nontrivial quadratic-residue prime factors of `C`.

Every such factor has order five.

A simple factor contributes a three-point set

\[
\{0,\pm c\}
\subset C_5
\]

for some nonzero `c`.

Two such valuation units already fill all of `C_5`: by direct inspection, or Cauchy--Davenport,

\[
\boxed{
\{0,\pm c\}+\{0,\pm d\}=C_5
}
\]

for nonzero `c,d`.

Likewise a single order-five prime occurring to exponent at least two has local interval length five and fills the QR subgroup.

Therefore if the total valuation of nontrivial QR prime factors is at least two, the signed box contains the complete quadratic-residue subgroup.

Any quadratic-nonresidue factor would then translate that subgroup onto the full nonresidue coset, which contains `-1`.

Hence:

### Lemma

If the nontrivial QR valuation mass is at least two, then a `q=11` miss is possible **if and only if every prime factor of `C` is a quadratic residue modulo 11**.

---

## 4. The thin case has v3(C) = 1

Because `3|C` and `3` is a nontrivial QR, the only way the total nontrivial QR valuation can equal one is

\[
\boxed{v_3(C)=1}
\]

and every other quadratic-residue prime factor is actually

\[
\boxed{1\pmod{11}.}
\]

The QR contribution is then exactly

\[
\boxed{Q=\{0,2,8\}}
\]

in additive `C_10` notation, after replacing class `8` by its symmetric generator `±2`.

We classify which nonresidue factors may coexist with this set while still missing target class `5`.

---

## 5. Primitive classes 7 and 8 force a hit immediately

The residues

\[
7,8\pmod{11}
\]

have logarithms `7,3`, i.e. classes `±3` in `C_10`.

A simple such factor contributes

\[
\{0,3,7\}.
\]

But

\[
2+3=5
\]

and

\[
8+7=15\equiv5\pmod{10}.
\]

Therefore even one prime factor

\[
\boxed{7\text{ or }8\pmod{11}}
\]

forces the Type-II target.

A factor `10 mod11` is the target `-1` itself and also forces a hit directly.

---

## 6. Primitive classes 2 and 6 can survive only with valuation at most two

The residues

\[
2,6\pmod{11}
\]

have logarithms `1,9`, i.e. classes `±1` in `C_10`.

If their total valuation is `E`, their combined signed contribution is

\[
\boxed{P_E=\{-E,-E+1,\ldots,E\}\pmod{10}.}
\]

The target is hit exactly when

\[
5\in Q+P_E.
\]

Since

\[
Q=\{0,2,8\},
\]

this requires `P_E` to contain one of

\[
5,3,7.
\]

For

\[
E\le2,
\]

it contains none of them.

For

\[
E\ge3,
\]

it contains `3` and `7`, hence the target is hit.

Therefore the thin branch misses exactly when

\[
\boxed{E\le2.}
\]

---

## 7. Exact q=11 miss theorem

Let

\[
C=\frac{p+11}{4}
\]

for a Mordell-hard prime `p`.

Then `q=11` misses exactly in one of the following two cases.

### Branch A: pure quadratic splitting

Every prime factor of `C` is a quadratic residue modulo `11`:

\[
\boxed{
\operatorname{supp}(C)
\subseteq
\{1,3,4,5,9\}\pmod{11}.}
\]

### Branch B: thin primitive defect

All of the following hold:

1. \[
   \boxed{v_3(C)=1};
   \]
2. every other quadratic-residue prime factor is `1 mod11`;
3. there are no prime factors `7,8,10 mod11`;
4. every nonresidue prime factor belongs to
   \[
   \boxed{2,6\pmod{11}};
   \]
5. their total valuation satisfies
   \[
   \boxed{
   \sum_{r^e\parallel C,\ r\equiv2,6\ (11)}e\le2.}
   \]

No other miss geometry is possible.

---

## 8. The square-divisible subcase is especially clean

If

\[
\boxed{9\mid C,}
\]

then the forced prime `3` alone occurs with exponent at least two and fills the complete quadratic-residue subgroup.

Therefore Branch B is impossible and

\[
\boxed{
9\mid C
\Longrightarrow
\left(
q=11\text{ misses}
\iff
\text{every prime factor of }C\text{ is QR mod }11
\right).}
\]

---

## 9. Consecutive corridor position

With

\[
A=\frac{p+3}{4},
\]

one has

\[
\boxed{C=A+2.}
\]

Thus a hypothetical strong/Type-II counterexample must make the first three consecutive integers satisfy:

\[
\boxed{
\begin{array}{c|c}
A & \text{all prime factors }1\pmod3\\
A+1 & \text{all prime factors quadratic residues mod }7\\
A+2 & \text{Branch A or the thin Branch B above mod }11.
\end{array}}
\]

The first two are pure splitting laws; the third allows only one explicitly bounded defect packet beyond pure splitting.

---

## 10. Next targets

1. Measure the joint density of the exact `q=3,7,11` survivor templates.
2. Classify `q=19` and `q=23`, using the small prime factors forced by the hard congruence classes.
3. Search for a general theorem: a forced high-order quadratic-residue factor with enough valuation collapses a fixed prime-shift miss to pure quadratic splitting.
4. Combine several corridor positions with sieve estimates on consecutive shifted integers.
