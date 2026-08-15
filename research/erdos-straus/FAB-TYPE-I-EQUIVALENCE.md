# Exact Type I Equivalence of the Primitive Coprime `fab` Sector

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-COMPLETENESS.md`, `FAB-COPRIME-PARITY-PLANE.md` (historical filename; exact coprime theorem)  
**Classical basis:** Elsholtz–Tao Type I/II dichotomy for prime Erdős-Straus solutions.  
**Claim boundary:** this identifies a sector exactly. It does not prove every prime has a Type I solution.

---

## 1. Type I convention

For a prime

\[
p
\]

write an Erdős-Straus solution as

\[
\frac4p=\frac1X+\frac1Y+\frac1Z.
\]

A **Type I** solution has exactly one denominator divisible by `p`.

A **Type II** solution has exactly two denominators divisible by `p`.

For odd primes, at least one but not all three denominators are divisible by `p`, so every solution is of one of these two types.

---

## 2. The primitive coprime fab sector

Call a coprime `fab` certificate **p-primitive** when

\[
\boxed{p\nmid a.}
\]

Thus

\[
\gcd(a,b)=1,
\qquad
p\nmid a.
\]

By the exact coprime-plane theorem, its admissibility is equivalent to

\[
\boxed{
 k\mid a+bp,
 \qquad
 k\equiv-p\pmod{4ab}.
}
\]

Put

\[
q=\frac{a+bp}{k}.
\]

---

## 3. Primitive coprime certificate implies Type I

Because

\[
p\nmid a,
\]

we have

\[
a+bp\not\equiv0\pmod p.
\]

Therefore neither factor of

\[
kq=a+bp
\]

is divisible by `p`:

\[
\boxed{p\nmid kq.}
\]

Also a valid coprime-plane certificate cannot have `p|b`. Indeed the exact congruence

\[
4ab\mid p+k
\]

would then imply `p|k`, contradicting `p∤k`.

Hence

\[
\boxed{p\nmid b,k,q.}
\]

The produced Erdős-Straus denominators are

\[
X=\frac{p+k}{4},
\]

\[
Y=\frac{q(p+k)}{4b},
\]

\[
Z=\frac{pq(p+k)}{4a}.
\]

Since `p∤k`,

\[
p\nmid p+k.
\]

Therefore

\[
p\nmid X,
\qquad
p\nmid Y,
\qquad
p\mid Z.
\]

Exactly one denominator is divisible by `p`.

Thus every p-primitive coprime `fab` certificate gives a **Type I** solution.

---

## 4. Every Type I solution gives a p-primitive coprime certificate

Suppose a Type I solution exists.

Scale by four:

\[
\frac1p=\frac1x+\frac1y+\frac1z,
\]

with all of `x,y,z` divisible by 4.

Since the solution is Type I, exactly two of these scaled denominators are not divisible by `p`.

Choose those two as the ordered pair `x,y` in the inverse `fab` construction.

Put

\[
g=\gcd(x,y),
\qquad
b=x/g,
\qquad
q=y/g,
\qquad
k=x-p,
\qquad
a=kq-pb.
\]

Because `p∤x,y`,

\[
p\nmid g,b,q,k.
\]

Modulo `p`,

\[
a\equiv kq\not\equiv0\pmod p.
\]

Thus

\[
\boxed{p\nmid a.}
\]

The coprime-completeness calculation gives

\[
\boxed{\gcd(a,b)=1.}
\]

So every Type I solution produces a p-primitive coprime `fab` certificate.

---

## 5. Equivalence theorem

For every prime

\[
p\equiv1\pmod4,
\]

the following are equivalent:

1. `p` has a Type I Erdős-Straus solution;
2. `p` has a coprime `fab` certificate with
   \[
   p\nmid a;
   \]
3. there exist positive integers `a,b,k` such that
   \[
   \gcd(a,b)=1,
   \qquad
   p\nmid a,
   \]
   \[
   k\mid a+bp,
   \qquad
   \boxed{k\equiv-p\pmod{4ab}}.
   \]

Thus the exact one-congruence coprime plane is **precisely the Type I prime problem**.

---

## 6. Consequence for the billion-prime certificate

`FAB-COPRIME-K1E9.md` proves that every Mordell-hard prime below

\[
10^9
\]

has a coprime certificate with

\[
1\le a,b\le11.
\]

Since every such parameter `a` is smaller than every relevant prime except trivial small cases already solved, all those certificates are p-primitive.

Therefore:

\[
\boxed{
\text{every Mordell-hard prime below }10^9
\text{ has a Type I solution.}
}
\]

This is an exact finite theorem-certificate.

---

## 7. The real residual wall

If a prime has no p-primitive coprime `fab` certificate, then it has **no Type I solution**.

By `FAB-COPRIME-COMPLETENESS.md`, if Erdős-Straus is nevertheless true for that prime, it still has some coprime `fab` certificate. Such a certificate must lie in the p-divisible numerator sector

\[
\boxed{p\mid a.}
\]

The classical Type I/II dichotomy then says a genuine survivor of the primitive sector can only be rescued by Type II geometry.

Thus the all-prime program has an exact fork:

\[
\boxed{
\text{Type I / primitive coprime certificate}
\quad\text{or}\quad
\text{Type II residual}.
}
\]

The first branch is governed by one divisor congruence. The second is the only remaining p-adic sector of the complete coprime parametrization.
