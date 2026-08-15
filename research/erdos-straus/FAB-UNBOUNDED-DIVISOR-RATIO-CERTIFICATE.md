# Unbounded strong sufficient certificates and the fixed-k divisor-ratio box

**Status:** proved exact algebraic reduction for a strong sufficient subclass  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-SHIFTED-FACTOR-DESCENT.md`  
**Claim boundary:** Bello-Hernández–Benito–Fernández define `fab(n,a,b)` for arbitrary positive `a,b`; they do **not** impose `a,b<n`. The bounds `a,b<p` entered the FCF coprime simplification in `FAB-COPRIME-DIVISOR-CRITERION.md`. This note removes that auxiliary size restriction only for the stronger sufficient congruence/divisibility subclass below. It does not claim to characterize every `fab` certificate and does not prove Erdős–Straus.

---

## 1. Strong sufficient identity

Let `n,a,b,k` be positive integers and assume

\[
\boxed{k\mid a+bn}
\]

and

\[
\boxed{4ab\mid n+k.}
\]

Put

\[
q=\frac{a+bn}{k},
\qquad
 t=\frac{n+k}{4ab}.
\]

Then

\[
kq=a+bn,
\qquad
k=4abt-n.
\]

Substitution gives

\[
(4abt-n)q=a+bn,
\]

so

\[
\boxed{4abqt=a+n(b+q).}
\]

Therefore

\[
\boxed{
\frac4n
=
\frac1{abt}
+
\frac1{aqt}
+
\frac1{bnqt}.
}
\]

This identity is exact and requires no size bound on `a,b`.

### Provenance correction

The original 2026 `fab` definition already allows arbitrary positive `a,b`. The restriction `a,b<p` was used only in the FCF **coprime divisor criterion** to collapse the full `fab` admissibility conditions to the single congruence

\[
k\equiv-p\pmod{4ab}.
\]

The two conditions in this section are stronger than general `fab` admissibility, but they are sufficient for an Erdős–Straus decomposition and remain valid for arbitrarily large auxiliaries.

We call such data a **strong sufficient certificate** in this note.

---

## 2. Fixed-k setup

Let `p` be an odd prime and `k` a positive integer with

\[
\gcd(p,k)=1,
\qquad
p+k\equiv0\pmod4.
\]

Put

\[
\boxed{C=\frac{p+k}{4}.}
\]

Then

\[
\gcd(C,k)=1.
\]

A strong sufficient certificate using this `k` is equivalent to positive `a,b,c` satisfying

\[
abc=C
\]

and

\[
k\mid a+bp,
\]

because `p+k=4abc` then automatically gives `4ab|p+k`.

---

## 3. Divisor-square equivalence for the strong subclass

For

\[
C=abc
\]

we have

\[
p=4abc-k.
\]

Hence

\[
a+bp
=a+4ab^2c-bk
=a(1+4b^2c)-bk.
\]

Since `a|C` and `gcd(C,k)=1`,

\[
\gcd(a,k)=1.
\]

Therefore

\[
\boxed{
k\mid a+bp
\iff
k\mid1+4b^2c.}
\]

Put

\[
u=b^2c.
\]

Then `u|C^2`.

Conversely, every divisor `u|C^2` can be realized as `b^2c` inside a factorization `abc=C` with `gcd(a,b)=1`. Prime by prime, if

\[
v_r(C)=E,
\qquad
v_r(u)=U,
\qquad
0\le U\le2E,
\]

choose exponent triples `(alpha,beta,gamma)` for `(a,b,c)` by

\[
(\alpha,\beta,\gamma)=(E-U,0,U)
\]

when `U<=E`, and

\[
(\alpha,\beta,\gamma)=(0,U-E,2E-U)
\]

when `U>=E`.

Thus:

### Theorem — fixed-k strong divisor-square certificate

For odd prime `p` and positive `k` with

\[
\gcd(p,k)=1,
\qquad p+k\equiv0\pmod4,
\]

there exists a **strong sufficient certificate** using this `k` if and only if

\[
\boxed{
\exists u\mid C^2:
\quad
4u\equiv-1\pmod k,
\qquad
C=\frac{p+k}{4}.
}
\]

This is not asserted to characterize every possible `fab` certificate with that `k`; it characterizes the stronger `4ab|p+k` subclass.

---

## 4. Divisor-ratio box

Because

\[
\frac{u}{C}
=
\frac{b^2c}{abc}
=
\frac ba,
\]

and

\[
4C\equiv p\pmod k,
\]

the target congruence becomes

\[
\boxed{
\frac ba\equiv-p^{-1}\pmod k.
}
\]

If

\[
C=\prod_r r^{E_r},
\]

the possible ratios `b/a` are exactly the signed exponent box

\[
\boxed{
\mathcal R_k(C)
=
\left\{
\prod_r r^{z_r}\bmod k:
-E_r\le z_r\le E_r
\right\}.
}
\]

Hence:

### Theorem — fixed-k strong divisor-ratio box

\[
\boxed{
\text{strong sufficient certificate with divisor }k
\iff
-p^{-1}\in\mathcal R_k(C),
\qquad
C=\frac{p+k}{4}.
}
\]

This gives a precise multiplicative-box subproblem inside the larger all-prime `fab` wall.

---

## 5. Three canonical points of the strong box

### Center: b/a = 1

Here `u=C`. The target condition gives

\[
4C\equiv-1\pmod k.
\]

Since `4C=p+k`,

\[
\boxed{k\mid p+1.}
\]

This is the familiar simplest Type-B / `p+1` spine.

### Upper endpoint: b/a = C

Here `u=C^2`. The target becomes

\[
k\mid4C^2+1,
\]

which modulo `k` is equivalent to

\[
\boxed{k\mid p^2+4.}
\]

after multiplication by `4`.

For a hard prime `p≡1 mod4`, any `k` with `p+k≡0 mod4` satisfies `k≡3 mod4`. Such a `k>1` has a prime divisor `q≡3 mod4`. But a `3 mod4` prime cannot divide the coprime sum of two squares

\[
p^2+2^2.
\]

Therefore the upper endpoint cannot solve a hard prime.

### Lower endpoint: b/a = C^{-1}

Here `u=1`, so `k|5`. Positive divisors of `5` are `1 mod4`, while the hard-prime shift `k` is `3 mod4`. Thus the lower endpoint also cannot solve a hard prime.

---

## 6. Structural consequence

Within this strong sufficient subclass, a hard prime escaping the `p+1` spine can be rescued only by a genuinely asymmetric interior signed divisor of

\[
C=\frac{p+k}{4}.
\]

The three canonical box points are

\[
\boxed{
C^{-1}:\text{ impossible},
\qquad
1:\text{ the }p+1\text{ spine},
\qquad
C:\text{ impossible by sums of two squares}.
}
\]

This is a useful local theorem target for the repository's multiplicative quotient / defect / zero-sum machinery, but the all-prime proof must remember that general `fab` admissibility is broader than this strong box.
