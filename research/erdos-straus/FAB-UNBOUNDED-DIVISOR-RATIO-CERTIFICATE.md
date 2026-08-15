# Unbounded sufficient certificates and the fixed-k divisor-ratio box

**Status:** proved exact algebraic reduction  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-SHIFTED-FACTOR-DESCENT.md`  
**Claim boundary:** this is a sufficient-certificate extension/repackaging of the divisor parametrization. It does not prove the required divisor-ratio hit exists for every prime and therefore does not prove Erdős–Straus.

---

## 1. The sufficient identity has no a,b<p requirement

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
kq=a+bn
\]

and

\[
k=4abt-n.
\]

Substituting gives

\[
(4abt-n)q=a+bn,
\]

hence

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

Indeed, after multiplying the right side by the common denominator `abnqt`, the numerator is

\[
nq+bn+a=4abqt.
\]

### Consequence

For the purpose of proving Erdős–Straus, the auxiliary bounds `a,b<n` are **not needed for sufficiency**. They belong to the bounded/completeness packaging of the external parametrization, not to this exact identity.

Thus a proof is free to use large positive auxiliary parameters if they produce the two displayed divisibilities.

---

## 2. Fixed-k setup

Let `p` be an odd prime and let `k` be a positive integer satisfying

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

We ask whether there are positive `a,b,c` with

\[
abc=C
\]

and

\[
k\mid a+bp.
\]

Such a triple gives a sufficient certificate by the theorem above because

\[
p+k=4abc
\]

is automatically divisible by `4ab`.

---

## 3. Divisor-square equivalence

For a factorization

\[
C=abc,
\]

we have

\[
p=4abc-k.
\]

Therefore

\[
a+bp
=a+4ab^2c-bk
=a(1+4b^2c)-bk.
\]

Since `a|C` and `gcd(C,k)=1`,

\[
\gcd(a,k)=1.
\]

Hence

\[
\boxed{
k\mid a+bp
\iff
k\mid1+4b^2c.
}
\]

Put

\[
u=b^2c.
\]

Then `u|C^2`.

Conversely, every divisor `u|C^2` is representable as `b^2c` inside a factorization `abc=C` with `gcd(a,b)=1`. Prime-by-prime, if

\[
v_r(C)=E,
\qquad
v_r(u)=U,
\qquad
0\le U\le2E,
\]

choose

\[
(\alpha,\beta,\gamma)=(E-U,0,U)
\]

when `U<=E`, and

\[
(\alpha,\beta,\gamma)=(0,U-E,2E-U)
\]

when `U>=E`, where these are the exponents of `(a,b,c)`.

Thus:

### Theorem — fixed-k divisor-square certificate

For odd prime `p` and positive `k` with

\[
\gcd(p,k)=1,
\qquad p+k\equiv0\pmod4,
\]

there exists a sufficient certificate using this `k` **if and only if**

\[
\boxed{
\exists u\mid C^2:
\quad
4u\equiv-1\pmod k,
\qquad
C=\frac{p+k}{4}.
}
\]

No upper bound on the reconstructed `a,b` is required for the resulting Egyptian-fraction identity.

---

## 4. Divisor-ratio formulation

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

the congruence

\[
4u\equiv-1\pmod k
\]

is equivalent to

\[
\boxed{
\frac ba\equiv-p^{-1}\pmod k.
}
\]

If

\[
C=\prod_r r^{E_r},
\]

the possible ratios `b/a` are exactly the signed divisor box

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

Therefore:

### Theorem — fixed-k divisor-ratio box

\[
\boxed{
\text{certificate with divisor }k
\iff
-p^{-1}\in\mathcal R_k(C),
\qquad
C=\frac{p+k}{4}.
}
\]

This is the post-DSC pointwise existence problem at fixed `k`: hit one specified unit with the signed divisor box of `(p+k)/4`.

---

## 5. Three canonical ratio points

The signed box has three obvious points.

### Center: b/a = 1

This gives `u=C`. The target condition becomes

\[
4C\equiv-1\pmod k.
\]

Since `4C=p+k`, this is

\[
\boxed{k\mid p+1.}
\]

Thus the center is exactly the familiar simplest Type-B / `p+1` spine.

### Upper endpoint: b/a = C

This gives `u=C^2`. The target condition is

\[
k\mid4C^2+1.
\]

Modulo `k`, this is equivalent to

\[
\boxed{k\mid p^2+4.}
\]

after multiplying by `4`.

For the hard-prime situation `p≡1 mod4`, every admissible `k` satisfies `k≡3 mod4`. Such a `k>1` has a prime divisor `q≡3 mod4`. But a prime `q≡3 mod4` cannot divide the coprime sum of two squares

\[
p^2+2^2,
\]

because a `3 mod4` prime dividing a sum of two squares divides both summands. Since `p` is odd, this is impossible.

Hence:

\[
\boxed{
\text{the upper endpoint never solves a hard prime.}
}
\]

### Lower endpoint: b/a = C^{-1}

This gives `u=1`, so

\[
4u+1=5.
\]

Thus `k|5`. But a hard-prime admissible `k` is `3 mod4`, while the positive divisors of `5` are `1 mod4`.

Hence:

\[
\boxed{
\text{the lower endpoint never solves a hard prime.}
}
\]

---

## 6. Structural consequence

For a Mordell-hard prime escaping the `p+1` spine, the fixed-k theorem says any rescue must come from a **genuinely asymmetric interior signed divisor** of

\[
C=\frac{p+k}{4}.
\]

The three canonical points behave as follows:

\[
\boxed{
C^{-1}:\text{ impossible},
\qquad
1:\text{ exactly the }p+1\text{ spine},
\qquad
C:\text{ impossible by sums of two squares}.
}
\]

So the remaining theorem is not about endpoint size. It is about internal multiplicative structure of the shifted factor `(p+k)/4`.

This is the exact place to reuse the repository's multiplicative quotient / defect / zero-sum machinery, now on the actual all-prime ES wall rather than on the false DSC exact-depth bridge.
