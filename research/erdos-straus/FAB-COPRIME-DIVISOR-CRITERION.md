# Coprime fab certificates reduce to one divisor congruence

**Status:** proved exact reformulation  
**Date:** 2026-08-15  
**External framework:** Bello-Hernández, Benito, Fernández, arXiv:2606.10922v1  
**Claim boundary:** this is a reformulation of the admissibility conditions in the recent divisor-parametrization framework. It does not prove that such a divisor always exists and therefore does not prove Erdős-Straus.

## 1. Setup

Let `p` be a prime with

\[
p\equiv1\pmod4.
\]

Let `a,b` be positive integers satisfying

\[
\gcd(a,b)=1,
\qquad
a<p,
\qquad b<p.
\]

For a positive divisor `k` of `a+bp`, put

\[
q=\frac{a+bp}{k}.
\]

The `fab` admissibility conditions are

\[
k\equiv3\pmod4,
\]

\[
4b\mid q(p+k),
\]

and

\[
4a\mid p q(p+k).
\]

## 2. Coprimality collapse

Because

\[
kq=a+bp,
\]

any common divisor of `b` and `kq` divides `a`; since `gcd(a,b)=1`,

\[
\boxed{\gcd(b,kq)=1.}
\]

Likewise any common divisor of `a` and `kq` divides `bp`. Since `a<p`, `p` is coprime to `a`, and `gcd(a,b)=1`, so

\[
\boxed{\gcd(a,kq)=1.}
\]

In particular

\[
\gcd(a,pq)=1,
\qquad
\gcd(b,q)=1.
\]

If `k≡3 mod4`, then with `p≡1 mod4`,

\[
p+k\equiv0\pmod4.
\]

Write

\[
c=\frac{p+k}{4}.
\]

The two remaining `fab` conditions become

\[
b\mid qc,
\qquad
a\mid pqc.
\]

By the coprimalities above these are equivalent to

\[
\boxed{b\mid c,\qquad a\mid c.}
\]

Since `gcd(a,b)=1`, this is equivalent to

\[
\boxed{ab\mid c.}
\]

Thus

\[
4ab\mid p+k,
\]

or equivalently

\[
\boxed{k\equiv-p\pmod{4ab}.}
\]

Because `p≡1 mod4`, this congruence already forces `k≡3 mod4`.

## 3. The theorem

### Coprime divisor criterion

For prime `p≡1 mod4` and coprime `a,b<p`, a positive divisor `k` of `a+bp` is `fab`-admissible **if and only if**

\[
\boxed{
k\equiv-p\pmod{4ab}.}
\]

Equivalently,

\[
\boxed{
\operatorname{fab}(p,a,b)>0
\iff
\exists k\mid(a+bp):
 k\equiv-p\pmod{4ab}.
}
\]

The right side is now a pure divisor-in-residue-class condition.

## 4. Explicit decomposition

Write

\[
p+k=4abt
\]

and

\[
q=\frac{a+bp}{k}.
\]

The divisor identity becomes

\[
\boxed{
\frac4p
=
\frac1{abt}
+
\frac1{aqt}
+
\frac1{bpqt}.
}
\]

Indeed,

\[
4abqt=a+p(b+q)
\]

follows from `kq=a+bp` and `k=4abt-p`, and clearing denominators verifies the identity.

## 5. Edge cases a=1 or b=1

### b=1

A certificate is equivalent to finding a divisor

\[
k\mid p+a
\]

with

\[
\boxed{k\equiv-p\pmod{4a}.}
\]

### a=1

A certificate is equivalent to finding a divisor

\[
k\mid1+bp
\]

with

\[
\boxed{k\equiv-p\pmod{4b}.}
\]

For `a=b=1`, this says exactly that `p+1` has a divisor `3 mod4`, recovering the familiar simplest Type-B spine.

## 6. New all-prime target

The 2026 divisor-parametrization paper reports that every tested prime

\[
5\le p\equiv1\pmod4,
\qquad p<10^{14},
\]

has a certificate with `1<=a,b<=11`.

For coprime pairs, the theorem above translates that phenomenon into the concrete statement:

> For each tested prime, at least one small linear form `a+bp` has a divisor in the single target class `-p mod 4ab`.

This suggests a cleaner proof target than universal exact-depth realizability:

\[
\boxed{
\forall p\equiv1\pmod4\text{ prime},
\quad
\exists\ (a,b)=1
\text{ with a controlled size and }
\exists k\mid(a+bp),
\ k\equiv-p\pmod{4ab}.
}
\]

No bounded universal theorem is claimed here. The point is that the ES wall has been reduced to a precise divisor-distribution statement that can be attacked with reciprocity, shifted-factor structure, or a descent argument.
