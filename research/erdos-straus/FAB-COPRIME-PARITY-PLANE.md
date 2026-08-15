# Coprime Opposite-Parity `fab` Plane

**Status:** proved exact specialization of the 2026 divisor parametrization  
**Date:** 2026-08-15  
**Prior-art basis:** Bello-Hernández, Benito, Fernández (2026), `fab` identity.  
**Claim boundary:** the published parametrization is prior art. This note identifies a broad exact subfamily in which both admissibility divisibilities collapse to one divisor congruence. It does not prove universal prime coverage.

---

## 1. Setup

Let

\[
n\equiv1\pmod4
\]

be odd, and take positive integers `a,b` satisfying

\[
\boxed{\gcd(a,b)=1}
\]

and

\[
\boxed{\gcd(a,n)=1.}
\]

Assume `a,b` have opposite parity.

Let

\[
k\mid a+bn
\]

and put

\[
q=\frac{a+bn}{k}.
\]

Because `a,b` have opposite parity and `n` is odd,

\[
\boxed{a+bn\text{ is odd}.}
\]

Hence

\[
\boxed{k,q\text{ are odd}.}
\]

---

## 2. Coprimality with the parameter product

Since

\[
\gcd(b,a+bn)=\gcd(a,b)=1,
\]

we have

\[
\gcd(b,q)=1.
\]

Also

\[
\gcd(a,a+bn)
=
\gcd(a,bn)
=1
\]

by the two coprimality assumptions. Hence

\[
\gcd(a,q)=1.
\]

Together with `gcd(a,n)=1`,

\[
\boxed{\gcd(a,nq)=1.}
\]

---

## 3. Exact collapse of the two `fab` divisibility conditions

The published admissibility conditions are

\[
4b\mid q(n+k)
\]

and

\[
4a\mid nq(n+k).
\]

Because `q` is odd and coprime to `b`, the first is equivalent to

\[
\boxed{4b\mid n+k.}
\]

Because `nq` is odd and coprime to `a`, the second is equivalent to

\[
\boxed{4a\mid n+k.}
\]

Now `gcd(a,b)=1` gives

\[
\operatorname{lcm}(4a,4b)=4ab
\]

when `a,b` have opposite parity.

Therefore the two conditions are simultaneously equivalent to

\[
\boxed{4ab\mid n+k.}
\]

or, equivalently,

\[
\boxed{k\equiv-n\pmod{4ab}.}
\]

This congruence automatically implies

\[
k\equiv3\pmod4.
\]

---

## 4. Theorem — exact coprime-parity criterion

Let

\[
n\equiv1\pmod4,
\]

and let positive `a,b` satisfy

\[
\gcd(a,b)=1,
\qquad
\gcd(a,n)=1,
\]

with opposite parity.

Then `(a,b)` gives a valid `fab` certificate **if and only if** there is a divisor

\[
\boxed{k\mid a+bn}
\]

with

\[
\boxed{k\equiv-n\pmod{4ab}.}
\]

With

\[
q=\frac{a+bn}{k},
\]

the Erdős-Straus denominators are

\[
\boxed{x=\frac{n+k}{4}}
\]

\[
\boxed{y=\frac{q(n+k)}{4b}}
\]

\[
\boxed{z=\frac{nq(n+k)}{4a}.}
\]

---

## 5. Prime specialization

For prime

\[
p\equiv1\pmod4,
\]

the condition `gcd(a,p)=1` is automatic for every

\[
1\le a<p.
\]

Thus for small coprime opposite-parity parameter pairs `(a,b)` the test is purely:

\[
\boxed{
\exists k\mid a+bp:
\quad
k\equiv-p\pmod{4ab}.
}
\]

No secondary divisibility test remains.

The exact one-parameter axes in `FAB-ONE-PARAMETER-AXES.md` are boundary cases of this plane when the parity hypotheses give the corresponding simplification.

---

## 6. First interior laboratory: p = 351289

In an exact finite scan of Mordell-hard primes below `500000`, using both one-parameter axes with parameters at most 11, the first and only survivor of those two axis windows is

\[
\boxed{p=351289.}
\]

It is immediately caught by the interior coprime-parity pair

\[
\boxed{(a,b)=(3,2).}
\]

Indeed

\[
a+bp
=3+2(351289)
=702581
=11\cdot23\cdot2777,
\]

so

\[
\boxed{k=23\mid a+bp.}
\]

Moreover

\[
4ab=24
\]

and

\[
\boxed{23\equiv-351289\pmod{24}.}
\]

Hence `(3,2,23)` is admissible.

The quotient is

\[
q=\frac{702581}{23}=30547.
\]

Therefore

\[
\frac4{351289}
=
\frac1x+rac1y+rac1z
\]

with

\[
x=\frac{351289+23}{4}=87828,
\]

\[
y=\frac{30547(351289+23)}8,
\]

\[
z=\frac{351289\cdot30547(351289+23)}{12}.
\]

---

## 7. Geometry of the simplified plane

For fixed coprime opposite-parity `(a,b,k)`, the certificate requires

\[
p\equiv-k\pmod{4ab}
\]

and

\[
a+bp\equiv0\pmod k.
\]

When the congruences are compatible, CRT therefore gives an arithmetic progression of solved primes.

Thus a finite parameter window yields a finite congruence cover problem, while allowing `(a,b,k)` to grow produces a divisor-adaptive covering system.

This is structurally parallel to the Type A/B trap program but lives on the complete divisor parametrization rather than on one Type A/B subclass.

---

## 8. New all-prime target

The computational fact reported in the 2026 paper is that every tested prime

\[
p\equiv1\pmod4,
\qquad p<10^{14},
\]

is detected somewhere in the small full window `1<=a,b<=11`.

The FCF/CENTL proof target should be sharper than assuming a universal finite window:

\[
\boxed{
\text{Can a prime survive every coprime opposite-parity divisor plane?}
}
\]

If not, the complete all-prime theorem follows without requiring the harder same-parity portion of `fab` at all.

The next experiments should therefore classify survivors of this exact simplified plane before spending effort on the rest of the two-dimensional parametrization.
