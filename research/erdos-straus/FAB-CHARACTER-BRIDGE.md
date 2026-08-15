# `fab` Character Bridge

**Status:** proved elementary character theorem on the exact coprime `fab` plane  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-PARITY-PLANE.md` (historical filename; theorem now covers all coprime pairs)  
**Prior-art boundary:** the `fab` parametrization is from Bello-Hernández, Benito, Fernández (2026). The character deductions below are elementary consequences used to connect that parametrization to the FCF/CENTL character framework.  
**Claim boundary:** this does not prove every prime has a `fab` certificate.

---

## 1. Certificate equations

Let

\[
p\equiv1\pmod4
\]

be prime. Suppose positive integers `a,b` satisfy

\[
\gcd(a,b)=1,
\qquad
\gcd(a,p)=1.
\]

By the exact coprime-plane theorem, a certificate is a divisor

\[
k\mid a+bp
\]

with

\[
\boxed{p+k=4abc}
\]

for some positive integer `c`. Equivalently,

\[
\boxed{k\equiv-p\pmod{4ab}.}
\]

No parity condition on `a,b` is required.

---

## 2. Hidden local congruence

From

\[
p=4abc-k
\]

we obtain

\[
a+bp=a+4ab^2c-bk=a(1+4b^2c)-bk.
\]

Because `k|a+bp` and `k|bk`,

\[
k\mid a(1+4b^2c).
\]

Moreover

\[
\gcd(a,k)=1
\]

because `k|a+bp` and `gcd(a,bp)=1`.

Therefore

\[
\boxed{k\mid1+4b^2c.}
\]

---

## 3. c has negative Jacobi character modulo k

The congruence gives

\[
4b^2c\equiv-1\pmod k.
\]

Thus `gcd(2bc,k)=1`. For every odd prime `ell|k`,

\[
(2b)^2c\equiv-1\pmod\ell,
\]

so

\[
\left(\frac c\ell\right)=\left(\frac{-1}\ell\right).
\]

Multiplying with prime-power multiplicity,

\[
\boxed{\left(\frac ck\right)=\left(\frac{-1}k\right).}
\]

Since the certificate congruence implies

\[
k\equiv3\pmod4,
\]

we get

\[
\boxed{\left(\frac ck\right)=-1.}
\]

---

## 4. Reciprocity relation with the target prime

Modulo `k`,

\[
p\equiv4abc.
\]

The factors `4` and `b^2` are squares modulo `k`, hence

\[
\left(\frac pk\right)
=
\left(\frac ak\right)
\left(\frac ck\right)
=-\left(\frac ak\right).
\]

Because

\[
p\equiv1\pmod4,
\]

quadratic reciprocity introduces no sign change, so

\[
\boxed{
\left(\frac kp\right)
=-\left(\frac ak\right).
}
\]

This identity holds across the entire exact **coprime** `fab` plane, including odd-odd parameter pairs.

---

## 5. A-axis corollary

When

\[
a=1,
\]

we have

\[
\left(\frac ak\right)=1,
\]

so every A-axis certificate satisfies

\[
\boxed{\left(\frac kp\right)=-1.}
\]

Thus the certificate divisor is necessarily a quadratic nonresidue modulo the target prime.

---

## 6. Two character modes

The coprime plane splits into:

### Mode N

\[
\left(\frac ak\right)=1
\quad\Longrightarrow\quad
\boxed{\left(\frac kp\right)=-1.}
\]

### Mode R

\[
\left(\frac ak\right)=-1
\quad\Longrightarrow\quad
\boxed{\left(\frac kp\right)=1.}
\]

The parameter `a` is therefore an explicit character-switch coordinate.

---

## 7. Interaction with Mordell-hard classes

The six hard classes modulo 840 satisfy the inherited small-prime positive-character conditions. In particular, a hard prime has

\[
\left(\frac3p\right)=\left(\frac5p\right)=\left(\frac7p\right)=1
\]

and `p≡1 mod8`.

Consequently small A-axis divisors already inside the classical positive shield, such as `3` and `7`, cannot serve as A-axis certificate divisors.

The `FAB-ELEVEN-BARRIER.md` theorem sharpens this: if `a` is supported only on `2,3,5,7`, then `(a/k)=1`, so the certificate remains in Mode N. The first possible Mode R numerator parameter is `a=11`.

---

## 8. Example p = 351289

The certificate

\[
(a,b,k)=(3,2,23)
\]

has

\[
c=\frac{351289+23}{4\cdot3\cdot2}=14638.
\]

The hidden congruence is

\[
1+4b^2c=1+16(14638)\equiv0\pmod{23},
\]

so

\[
\left(\frac{14638}{23}\right)=-1.
\]

The target relation is

\[
\left(\frac{23}{351289}\right)
=-\left(\frac3{23}\right).
\]

---

## 9. Example p = 5101441 shows odd-odd parameters fit the same theorem

A coprime odd-odd certificate is

\[
(a,b,k)=(7,3,15335).
\]

It satisfies

\[
15335\mid7+3p
\]

and

\[
15335\equiv-p\pmod{84}.
\]

Thus the same hidden congruence and character bridge apply. No separate same-parity theory is needed for coprime parameters.

---

## 10. Relation to the FCF character program

The Type A/B research already developed scalar Jacobi shields, full local quadratic signatures, character-level redundancy, and multiplicative quotient structure.

The complete divisor parametrization now has an explicit compatible layer:

\[
\boxed{
\text{coprime divisor certificate}
\Longrightarrow
\left(\frac ck\right)=-1
\Longrightarrow
\left(\frac kp\right)=-\left(\frac ak\right).
}
\]

The new all-prime problem can therefore compare Type A/B survivors and coprime-`fab` survivors in one character-signature language.
