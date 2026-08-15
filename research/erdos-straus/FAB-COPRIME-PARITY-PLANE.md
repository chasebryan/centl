# Exact Coprime `fab` Plane

> Historical filename: `FAB-COPRIME-PARITY-PLANE.md`. The original draft unnecessarily assumed opposite parity. The theorem is stronger: **all coprime parameter pairs** are covered.

**Status:** proved exact specialization of the 2026 divisor parametrization  
**Date:** 2026-08-15  
**Prior-art basis:** Bello-Hernández, Benito, Fernández (2026), `fab` identity.  
**Claim boundary:** the published parametrization is prior art. This note proves that on the coprime `(a,b)` plane the two published admissibility tests collapse to one divisor congruence. It does not prove universal prime coverage.

---

## 1. Setup

Let

\[
n\equiv1\pmod4
\]

be odd. Take positive integers `a,b` with

\[
\boxed{\gcd(a,b)=1}
\]

and

\[
\boxed{\gcd(a,n)=1.}
\]

Let

\[
k\mid a+bn,
\qquad
q=\frac{a+bn}{k},
\qquad
k\equiv3\pmod4.
\]

Because

\[
\gcd(b,a+bn)=\gcd(a,b)=1,
\]

and

\[
\gcd(a,a+bn)=\gcd(a,bn)=1,
\]

we have

\[
\boxed{\gcd(b,q)=1}
\]

and

\[
\boxed{\gcd(a,nq)=1.}
\]

---

## 2. The unavoidable factor 4 already lies in n+k

Since

\[
n\equiv1\pmod4
\]

and

\[
k\equiv3\pmod4,
\]

we always have

\[
\boxed{4\mid n+k.}
\]

This observation removes the parity restriction from the first draft.

---

## 3. First published divisibility condition

The first `fab` condition is

\[
4b\mid q(n+k).
\]

Because `gcd(b,q)=1`, its `b`-part forces

\[
b\mid n+k.
\]

Now split only to account for the 2-adic part.

- If `b` is odd, `gcd(4,b)=1`; combining `b|n+k` with `4|n+k` gives `4b|n+k`.
- If `b` is even, coprimality forces `a` odd, hence `a+bn` is odd. Therefore `q` is odd. Since `q` is also coprime to `b`, in fact `gcd(q,4b)=1`, so the original condition directly forces `4b|n+k`.

Thus in **all** coprime cases,

\[
\boxed{
4b\mid q(n+k)
\iff
4b\mid n+k.
}
\]

---

## 4. Second published divisibility condition

The second condition is

\[
4a\mid nq(n+k).
\]

Because `gcd(a,nq)=1`, its `a`-part forces

\[
a\mid n+k.
\]

Again:

- if `a` is odd, combine `a|n+k` with `4|n+k`;
- if `a` is even, coprimality forces `b` odd, so `a+bn` and hence `q` are odd; then `nq` is odd and coprime to `4a`, forcing the full `4a` into `n+k`.

Therefore

\[
\boxed{
4a\mid nq(n+k)
\iff
4a\mid n+k.
}
\]

---

## 5. Exact theorem

Since

\[
\gcd(a,b)=1,
\]

we have

\[
\operatorname{lcm}(4a,4b)=4ab.
\]

Hence the two published `fab` admissibility conditions are simultaneously equivalent to

\[
\boxed{4ab\mid n+k.}
\]

or

\[
\boxed{k\equiv-n\pmod{4ab}.}
\]

### Theorem

Let

\[
n\equiv1\pmod4,
\qquad
\gcd(a,b)=1,
\qquad
\gcd(a,n)=1.
\]

Then the pair `(a,b)` gives a valid `fab` certificate **if and only if** there is a divisor

\[
\boxed{k\mid a+bn}
\]

such that

\[
\boxed{k\equiv-n\pmod{4ab}.}
\]

The congruence automatically implies `k≡3 mod4`.

With

\[
q=\frac{a+bn}{k},
\]

the decomposition is

\[
\boxed{x=\frac{n+k}{4}},
\qquad
\boxed{y=\frac{q(n+k)}{4b}},
\qquad
\boxed{z=\frac{nq(n+k)}{4a}}.
\]

---

## 6. Prime specialization

For prime

\[
p\equiv1\pmod4,
\]

`gcd(a,p)=1` is automatic for every `1<=a<p`.

Thus the **entire coprime parameter plane** has the exact test

\[
\boxed{
\gcd(a,b)=1,
\qquad
\exists k\mid a+bp:
\quad
k\equiv-p\pmod{4ab}.
}
\]

No secondary divisibility test remains.

The exact one-parameter axes are contained in this theorem because `gcd(1,b)=gcd(a,1)=1`.

---

## 7. Interior examples

### p = 351289

The certificate

\[
(a,b,k)=(3,2,23)
\]

satisfies

\[
23\mid3+2p
\]

and

\[
23\equiv-p\pmod{24}.
\]

### Same-parity example p = 5101441

The pair

\[
(a,b)=(7,3)
\]

is **also** inside the exact coprime plane, despite both parameters being odd.

A certificate is

\[
k=15335,
\]

with

\[
15335\mid7+3p
\]

and

\[
15335\equiv-p\pmod{84}.
\]

This example is what exposed the unnecessary parity assumption.

---

## 8. Correct simplified subsystem

The natural simplified subsystem is no longer

\[
\text{axes} + \text{opposite-parity interior}.
\]

It is simply

\[
\boxed{\text{the coprime }(a,b)\text{ plane}.}
\]

Non-coprime parameter pairs are the only part of the full `fab` window not covered by the one-congruence theorem.

This is a much sharper comparison with the published computation `1<=a,b<=11`.

---

## 9. Active all-prime target

The finite evidence now motivates the stronger question

\[
\boxed{
\text{Can a prime }p\equiv1\pmod4\text{ survive every coprime pair }(a,b)?
}
\]

If the answer is no, the non-coprime part of the complete divisor parametrization is unnecessary for the full theorem.
