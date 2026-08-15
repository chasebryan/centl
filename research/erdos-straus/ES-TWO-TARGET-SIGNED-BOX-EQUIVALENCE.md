# Exact two-target signed-box equivalence for prime Erdős--Straus

**Status:** proved exact reformulation  
**Date:** 2026-08-15  
**External background:** the standard prime Type-I/Type-II parametrization, as recorded for example in Bello-Hernández, Benito, Fernández, *A Divisor Parametrization for the Erdős--Straus Conjecture*, arXiv:2606.10922v1, equations (13)--(16)  
**Depends on:** `FAB-TYPE-II-SIGNED-DIVISOR.md`, `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`  
**Claim boundary:** this is an exact reformulation of the prime Erdős--Straus problem in one family of finite multiplicative boxes. It does not prove that one of the two targets is always hit. No literature-priority claim is made without a separate prior-art review.

---

## 1. The signed box

Let `p` be a prime with

\[
p\equiv1\pmod4.
\]

Let `k` be a positive integer satisfying

\[
\boxed{k\equiv3\pmod4,\qquad \gcd(k,p)=1.}
\]

Put

\[
\boxed{C_k=\frac{p+k}{4}}
\]

and factor

\[
C_k=\prod_i r_i^{e_i}.
\]

Since `gcd(C_k,k)=1`, define the signed divisor box

\[
\boxed{
\mathcal R_k(C_k)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i
\right\}
\subseteq(\mathbb Z/k\mathbb Z)^\times.}
\]

It is symmetric under inversion:

\[
\boxed{\mathcal R_k(C_k)^{-1}=\mathcal R_k(C_k).}
\]

The two distinguished targets are

\[
\boxed{
\tau_I=-p^{-1}\pmod k,
\qquad
\tau_{II}=-1\pmod k.}
\]

---

## 2. Every signed ratio has a coprime factor realization

Let

\[
\rho=\prod_i r_i^{z_i}\in\mathcal R_k(C_k).
\]

Construct positive integers `B,D,T` prime by prime:

- if `z_i>0`, place `r_i^{z_i}` in `B`;
- if `z_i<0`, place `r_i^{-z_i}` in `D`;
- place the remaining `r_i^{e_i-|z_i|}` in `T`.

Then

\[
\boxed{BDT=C_k,\qquad \gcd(B,D)=1}
\]

and

\[
\boxed{BD^{-1}\equiv\rho\pmod k.}
\]

Thus the whole box is exactly the set of ratios `B/D` obtained by assigning each prime-power unit of `C_k` to the numerator, denominator, or neutral leftover factor.

---

## 3. Type-I target gives a standard Type-I solution

Assume

\[
\boxed{-p^{-1}\in\mathcal R_k(C_k).}
\]

Choose `B,D,T` as above so that

\[
BD^{-1}\equiv-p^{-1}\pmod k.
\]

Equivalently,

\[
\boxed{k\mid D+pB.}
\]

Put

\[
\boxed{A=\frac{D+pB}{k}.}
\]

Because

\[
p+k=4BDT,
\]

we have

\[
k=4BDT-p.
\]

Substituting into `Ak=D+pB` gives

\[
A(4BDT-p)=D+pB.
\]

Rearranging,

\[
\boxed{(4ABT-1)D=(A+B)p.}
\]

This is exactly the standard prime Type-I equation.

Therefore

\[
\boxed{-p^{-1}\in\mathcal R_k(C_k)\Longrightarrow\text{a Type-I Erdős--Straus solution}.}
\]

The corresponding unit-fraction decomposition is

\[
\boxed{
\frac4p
=
\frac1{ABTp}
+
\frac1{BTD}
+
\frac1{ATD}.}
\]

---

## 4. Every Type-I solution gives the first target

Conversely, suppose positive integers `A,B,T,D` satisfy the standard Type-I equation

\[
\boxed{(4ABT-1)D=(A+B)p.}
\]

Rearrange it as

\[
\boxed{A(4BDT-p)=D+pB.}
\]

Set

\[
\boxed{k=4BDT-p.}
\]

The right side is positive, so `k>0`. Also

\[
k\equiv-p\equiv3\pmod4.
\]

The non-`p` denominator `BDT` in the Type-I decomposition is not divisible by `p`, so

\[
\gcd(k,p)=1.
\]

Further,

\[
C_k=\frac{p+k}{4}=BDT.
\]

Modulo `k`,

\[
D+pB\equiv0,
\]

hence

\[
BD^{-1}\equiv-p^{-1}\pmod k.
\]

Because `B` and `D` both divide `C_k`, their ratio is represented by a signed exponent vector in the box (common prime powers cancel into the neutral exponent). Therefore

\[
\boxed{-p^{-1}\in\mathcal R_k(C_k).}
\]

Thus the first target is exact for Type I.

---

## 5. Type-II target gives a standard Type-II solution

Assume

\[
\boxed{-1\in\mathcal R_k(C_k).}
\]

Choose `B,D,T` with

\[
BD^{-1}\equiv-1\pmod k.
\]

Then

\[
\boxed{k\mid B+D.}
\]

Put

\[
\boxed{A=\frac{B+D}{k}.}
\]

Again `k=4BDT-p`. Substituting into `Ak=B+D` gives

\[
A(4BDT-p)=B+D,
\]

hence

\[
\boxed{(4ABT-1)D=Ap+B.}
\]

This is exactly the standard prime Type-II equation.

Therefore

\[
\boxed{-1\in\mathcal R_k(C_k)\Longrightarrow\text{a Type-II Erdős--Straus solution}.}
\]

The associated decomposition is

\[
\boxed{
\frac4p
=
\frac1{ABTp}
+
\frac1{BTD}
+
\frac1{ATDp}.}
\]

---

## 6. Every Type-II solution gives the second target

Conversely, suppose

\[
\boxed{(4ABT-1)D=Ap+B.}
\]

Rearrange:

\[
\boxed{A(4BDT-p)=B+D.}
\]

Set

\[
\boxed{k=4BDT-p.}
\]

Then `k>0`, `k≡3 mod4`, and because `BDT` is the unique non-`p` denominator in the standard Type-II form,

\[
\gcd(k,p)=1.
\]

Moreover

\[
C_k=BDT.
\]

Modulo `k`,

\[
B+D\equiv0,
\]

so

\[
BD^{-1}\equiv-1\pmod k.
\]

As before, this ratio belongs to the signed divisor box. Therefore

\[
\boxed{-1\in\mathcal R_k(C_k).}
\]

Thus the second target is exact for Type II.

---

## 7. Exact prime equivalence

The standard Type-I/Type-II parametrization is complete for prime Erdős--Straus solutions. Combining the two directions above gives:

### Theorem — exact two-target signed-box equivalence

For every prime

\[
p\equiv1\pmod4,
\]

the following are equivalent:

1. `p` satisfies the Erdős--Straus equation;
2. there exists a positive integer
   \[
   k\equiv3\pmod4,
   \qquad\gcd(k,p)=1,
   \]
   such that, with
   \[
   C_k=(p+k)/4,
   \]
   one has
   \[
   \boxed{
   \{-p^{-1},-1\}
   \cap
   \mathcal R_k(C_k)
   \ne\varnothing.}
   \]

Equivalently,

\[
\boxed{
\text{prime ES}
\iff
\exists k\equiv3\pmod4:
\bigl(-p^{-1}\in\mathcal R_k(C_k)
\ \lor\ 
-1\in\mathcal R_k(C_k)\bigr).}
\]

This converts the prime conjecture into an exact **two-target divisor-placement problem**.

---

## 8. The inverse Type-I orientation

Since the signed box is inversion-symmetric,

\[
-p^{-1}\in\mathcal R_k(C_k)
\iff
-p\in\mathcal R_k(C_k).
\]

The two residues are the two orientations of the same Type-I ratio.

Therefore an unsolved fixed shift must avoid the three natural residues

\[
\boxed{-p^{-1},\quad -p,\quad -1.}
\]

although the first two encode one solution type.

This three-residue exclusion is the source of the strengthened Kneser budget in `FAB-TWO-TARGET-KNESER.md`.

---

## 9. Strategic consequence

The direct prime Erdős--Straus problem is now exactly:

> For every prime `p≡1 mod4`, prove that at least one admissible shift `k≡3 mod4` has a signed divisor box of `(p+k)/4` containing either `-p^{-1}` or `-1` modulo `k`.

The external-nonresidue program is one structured way to choose such shifts. It is no longer merely a search inside a sufficient FAB subclass: the two-target box language is an exact reformulation of the complete standard Type-I/Type-II solution space.
