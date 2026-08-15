# Exact One-Parameter `fab` Divisor Axes

**Status:** proved exact specializations of the 2026 `fab` divisor identity  
**Date:** 2026-08-15  
**Prior-art basis:** Bello-Hernández, Benito, Fernández (2026), *A Divisor Parametrization for the Erdős--Straus Conjecture*.  
**Claim boundary:** the underlying divisor parametrization is prior art. This note isolates two exact one-parameter axes and their survivor formulation for the FCF/CENTL all-prime program.

---

## 1. Published admissibility conditions

For

\[
n\equiv1\pmod4,
\]

take positive integers `a,b` and a divisor

\[
k\mid a+bn,
\qquad
k\equiv3\pmod4.
\]

Put

\[
q=\frac{a+bn}{k}.
\]

The published `fab` conditions are

\[
4b\mid q(n+k),
\qquad
4a\mid nq(n+k).
\]

When they hold,

\[
\frac4n
=
\frac1{(n+k)/4}
+
\frac1{q(n+k)/(4b)}
+
\frac1{nq(n+k)/(4a)}.
\]

---

## 2. Axis A: `a=1`, arbitrary `b`

Set

\[
a=1.
\]

Then

\[
kq=1+bn.
\]

The elementary identity

\[
\gcd(b,1+bn)=1
\]

implies

\[
\gcd(b,k)=\gcd(b,q)=1.
\]

The second `fab` divisibility condition follows from the first, because

\[
4b\mid q(n+k)
\Longrightarrow
4\mid nq(n+k).
\]

Since `q` is coprime to `b`, the odd-prime part of the first condition must come from `n+k`. The 2-adic contribution also collapses exactly after using `n≡1 mod4` and `k≡3 mod4`; equivalently, the condition is

\[
\boxed{4b\mid n+k.}
\]

Thus:

### Theorem A

For `n≡1 mod4` and `b>=1`, the `(a,b)=(1,b)` `fab` layer is admissible if and only if there is a divisor

\[
\boxed{k\mid1+bn}
\]

such that

\[
\boxed{k\equiv-n\pmod{4b}.}
\]

For such `k`, with

\[
q=\frac{1+bn}{k},
\]

one obtains

\[
\boxed{
x=\frac{n+k}{4}}
\]

\[
\boxed{
y=\frac{q(n+k)}{4b}}
\]

\[
\boxed{
z=\frac{nq(n+k)}4.}
\]

---

## 3. Axis B: `b=1`, arbitrary `a` coprime to `n`

Set

\[
b=1.
\]

Then

\[
kq=a+n.
\]

Assume

\[
\gcd(a,n)=1.
\]

This is automatic for prime `n=p` whenever

\[
1\le a<p.
\]

Now

\[
\gcd(a,a+n)=1,
\]

so

\[
\gcd(a,k)=\gcd(a,q)=1.
\]

The first `fab` condition is

\[
4\mid q(n+k),
\]

while the second is

\[
4a\mid nq(n+k).
\]

Since `n` and `q` are both coprime to `a`, the `a`-part must come from `n+k`; and the common `4` condition is exactly the same one. Therefore

\[
\boxed{4a\mid n+k.}
\]

Hence:

### Theorem B

Let

\[
n\equiv1\pmod4,
\qquad
\gcd(a,n)=1.
\]

The `(a,b)=(a,1)` `fab` layer is admissible if and only if there is a divisor

\[
\boxed{k\mid n+a}
\]

such that

\[
\boxed{k\equiv-n\pmod{4a}.}
\]

With

\[
q=\frac{n+a}{k},
\]

the resulting decomposition is

\[
\boxed{
x=\frac{n+k}{4}}
\]

\[
\boxed{
y=\frac{q(n+k)}4}
\]

\[
\boxed{
z=\frac{nq(n+k)}{4a}.}
\]

---

## 4. Prime specialization

For a prime

\[
p\equiv1\pmod4,
\]

define two survivor predicates.

### A-axis survivor through B

`p` survives the first `B` A-axis layers if for every

\[
1\le b\le B
\]

the integer

\[
1+bp
\]

has no divisor in the exact class

\[
\boxed{-p\pmod{4b}.}
\]

### B-axis survivor through A

`p` survives the first `A` B-axis layers if for every

\[
1\le a\le A
\]

the integer

\[
p+a
\]

has no divisor in the class

\[
\boxed{-p\pmod{4a}.}
\]

A prime surviving both axes for every positive parameter would be a genuine residual target for the full two-dimensional `fab` search.

---

## 5. Example: 1129

The hard prime

\[
p=1129
\]

survives the initial binary A-axis layers but is killed by

\[
b=3.
\]

Indeed

\[
1+3p=3388=11\cdot308
\]

and

\[
11\equiv-1129\pmod{12}.
\]

Thus `(a,b,k)=(1,3,11)` is admissible.

---

## 6. Example: 2521

The prime

\[
p=2521
\]

is a stubborn A-axis survivor in small searches, but the dual B-axis catches it immediately with

\[
a=2.
\]

Indeed

\[
p+a=2523=87\cdot29
\]

and

\[
87\equiv-2521\pmod8.
\]

Hence

\[
\boxed{(a,b,k)=(2,1,87)}
\]

is admissible.

---

## 7. Symmetric sufficient two-parameter criterion

Even away from the axes, there is an immediate strong sufficient condition.

If

\[
k\mid a+bn,
\qquad
k\equiv-n\pmod{4ab},
\]

then

\[
4ab\mid n+k.
\]

Therefore both published divisibility conditions hold:

\[
4b\mid q(n+k),
\qquad
4a\mid nq(n+k).
\]

So any such divisor gives a valid `fab` certificate.

This criterion is not asserted to be necessary for general `(a,b)`.

---

## 8. All-prime program

The new cross-parametrization survivor hierarchy is:

\[
\boxed{
\text{Mordell-hard primes}
\to
\text{Type A/B reductions + collective cores}
\to
\text{A-axis survivors}
\to
\text{B-axis survivors}
\to
\text{full fab residual}.
}
\]

The key proof question is now sharper than “search small a,b”:

\[
\boxed{
\text{Can a prime survive both exact divisor axes for every }a,b>0?
}
\]

A structural impossibility here would solve the all-prime wall without needing a uniform finite bound on the two-dimensional `fab` window.
