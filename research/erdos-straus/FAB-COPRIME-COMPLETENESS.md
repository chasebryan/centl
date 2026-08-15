# Coprime Completeness of the `fab` Parametrization for Primes

**Status:** proved theorem / strengthening of the parameter normalization in the 2026 divisor parametrization  
**Date:** 2026-08-15  
**Prior-art basis:** Bello-Hernández, Benito, Fernández (2026), Theorem 5 gives completeness of `fab` with unrestricted positive parameters.  
**New point recorded here:** for prime targets, the inverse construction can always be ordered so that the resulting `fab` parameters are **coprime**.  
**Claim boundary:** this is an equivalent reformulation of the prime Erdős-Straus problem, not a proof that a certificate always exists.

---

## 1. Start from an arbitrary prime ES decomposition

Let

\[
p\equiv1\pmod4
\]

be prime and suppose

\[
\frac4p
=
\frac1X+
\frac1Y+
\frac1Z
\]

for positive integers `X,Y,Z`.

Scale by four:

\[
\boxed{
\frac1p
=
\frac1x+
\frac1y+
\frac1z,
\qquad
x=4X,\ y=4Y,\ z=4Z.
}
\]

Thus

\[
4\mid x,\qquad4\mid y,\qquad4\mid z.
\]

Every denominator is larger than `p`.

---

## 2. Choose the inverse ordering by p-adic valuation

Choose any two of the three denominators and order them so that

\[
\boxed{v_p(x)\le v_p(y).}
\]

Use the remaining denominator as `z`.

Put

\[
\boxed{g=\gcd(x,y)}
\]

and define

\[
\boxed{b=\frac{x}{g},\qquad q=\frac{y}{g}.}
\]

Then by construction

\[
\boxed{\gcd(b,q)=1.}
\]

The p-adic ordering gives

\[
v_p(g)=\min(v_p(x),v_p(y))=v_p(x),
\]

hence

\[
\boxed{v_p(b)=0.}
\]

Therefore

\[
\boxed{p\nmid b.}
\]

---

## 3. Apply the published inverse construction

Set

\[
\boxed{k=x-p.}
\]

Since `x` is divisible by 4 and `p≡1 mod4`,

\[
\boxed{k\equiv3\pmod4.}
\]

The identity

\[
\frac1p=\frac1x+\frac1y+\frac1z
\]

implies

\[
\boxed{z(ky-px)=pxy.}
\]

Thus

\[
ky-px>0.
\]

Define, exactly as in the completeness proof of the 2026 paper,

\[
\boxed{a=\frac{ky-px}{g}.}
\]

Since `y=gq` and `x=gb`,

\[
\boxed{a=kq-pb.}
\]

The published argument then gives

\[
k\mid a+bp,
\qquad
q=\frac{a+bp}{k},
\]

and the two `fab` admissibility divisibilities; the associated divisor identity reproduces the chosen decomposition exactly.

---

## 4. New theorem — the inverse parameters are coprime

We compute

\[
\begin{aligned}
\gcd(a,b)
&=\gcd(kq-pb,b)\\
&=\gcd(kq,b).
\end{aligned}
\]

Since

\[
\gcd(q,b)=1,
\]

this becomes

\[
\gcd(a,b)=\gcd(k,b).
\]

But

\[
k=x-p
\]

and

\[
b\mid x,
\]

so

\[
\gcd(k,b)
=
\gcd(x-p,b)
=
\gcd(p,b).
\]

The p-adic ordering proved

\[
p\nmid b.
\]

Because `p` is prime,

\[
\boxed{\gcd(p,b)=1.}
\]

Therefore

\[
\boxed{\gcd(a,b)=1.}
\]

QED.

---

## 5. Coprime completeness theorem

### Theorem

For prime

\[
p\equiv1\pmod4,
\]

the following are equivalent:

1. the Erdős-Straus equation
   \[
   \frac4p=\frac1X+\frac1Y+\frac1Z
   \]
   has a positive-integer solution;
2. there exist **coprime** positive integers
   \[
   \boxed{\gcd(a,b)=1}
   \]
   and an admissible `fab` divisor `k` for `p`.

### Proof

`2 -> 1` is Proposition 2 of the published divisor parametrization.

For `1 -> 2`, scale the solution by 4, choose two denominators ordered by p-adic valuation, and apply Sections 2–4 above. QED.

---

## 6. Universal consequence — non-coprime fab parameters are redundant for primes

The unrestricted 2026 completeness theorem permits arbitrary positive `(a,b)`.

For prime targets, the theorem above proves that the non-coprime region is never logically necessary:

\[
\boxed{
\text{prime ES solvability}
\iff
\text{solvability somewhere in the coprime fab plane}.
}
\]

Thus the complete prime problem may be studied entirely inside

\[
\boxed{\gcd(a,b)=1.}
\]

This is a universal structural reduction, not a finite-search observation.

---

## 7. Important sector split inside the coprime plane

The exact one-congruence theorem in `FAB-COPRIME-PARITY-PLANE.md` additionally assumes

\[
\gcd(a,p)=1.
\]

For prime `p`, the coprime plane therefore splits into two sectors.

### Sector I — p-primitive numerator

\[
\boxed{p\nmid a.}
\]

Then `gcd(a,p)=1`, and admissibility is exactly

\[
\boxed{
\exists k\mid a+bp:
\quad
k\equiv-p\pmod{4ab}.
}
\]

This is the one-congruence coprime plane studied in the finite `a,b<=11` certificates.

### Sector II — p-divisible numerator

\[
\boxed{p\mid a.}
\]

The parameters can still satisfy

\[
\gcd(a,b)=1,
\]

because the inverse p-adic ordering ensures `p∤b`.

But the factor `p` in the second published admissibility condition can be supplied by the target `p` itself, so the reduction to

\[
4ab\mid p+k
\]

is no longer automatically valid.

This is a genuine residual sector and must be treated separately unless Sector I is proved universally sufficient.

---

## 8. Relation to Type I / Type II geometry

The sector split matches the classical p-adic shape of prime ES solutions.

- When the inverse ordering can use two denominators not divisible by `p`, the constructed `a` is also p-primitive; this is naturally associated with the one-p-divisible-denominator / Type I side.
- When the useful ordered pair lies among p-divisible denominators, the inverse construction can place a factor `p` into `a`; this is naturally associated with the two-p-divisible-denominator / Type II side.

This paragraph is structural interpretation, not a replacement for the exact formulas above.

---

## 9. Finite evidence for Sector I

`FAB-COPRIME-K1E9.md` proves by two independent exact computations that every Mordell-hard prime below

\[
10^9
\]

already lies in Sector I with

\[
1\le a,b\le11.
\]

Thus Sector II is not needed anywhere in that certified hard-prime range.

That finite fact does **not** prove Sector II is universally unnecessary.

---

## 10. New prime reformulation

The prime Erdős-Straus conjecture is now equivalent to:

> For every prime `p≡1 mod4`, there exist coprime positive integers `a,b` and a divisor `k|a+bp`, `k≡3 mod4`, satisfying the original two `fab` divisibility conditions.

The strongest currently supported sub-conjecture is:

\[
\boxed{
\text{Sector I sufficiency: every prime }p\equiv1\pmod4
\text{ has coprime }a,b\text{ with }p\nmid a
\text{ and }k\equiv-p\pmod{4ab}.
}
\]

If Sector I sufficiency is proved, Erdős-Straus follows immediately for all primes, and `PRIME-REDUCTION.md` then gives all integers.
