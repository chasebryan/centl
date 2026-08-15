# Exact Type II Equivalence of the Coprime p-Divisible `fab` Sector

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-COMPLETENESS.md`  
**Classical basis:** prime Erdős-Straus Type I/II dichotomy; the underlying complete `fab` parametrization is due to Bello-Hernández, Benito, Fernández (2026).  
**Claim boundary:** this gives an exact Type II divisor-congruence criterion. It does not prove every Type I survivor has such a Type II certificate.

---

## 1. Type II setup

Let

\[
p\equiv1\pmod4
\]

be prime.

A Type II solution has exactly two denominators divisible by `p`:

\[
\frac4p=\frac1X+\frac1Y+\frac1Z.
\]

Scale by four:

\[
\frac1p=\frac1x+\frac1y+\frac1z,
\qquad
x=4X,\ y=4Y,\ z=4Z.
\]

Choose the ordering so that

\[
\boxed{p\nmid x}
\]

and

\[
\boxed{p\mid y,\qquad p\mid z.}
\]

Among the two p-divisible denominators, choose `y` so that

\[
\boxed{v_p(y)\le v_p(z).}
\]

---

## 2. Apply the complete inverse fab map

Put

\[
g=\gcd(x,y),
\qquad
b=x/g,
\qquad
q=y/g,
\qquad
k=x-p,
\]

and

\[
a=\frac{ky-px}{g}=kq-pb.
\]

Since `p∤x` while `p|y`,

\[
\boxed{p\nmid g,b,k}
\]

and

\[
\boxed{p\mid q}.
\]

The general coprime-completeness theorem gives

\[
\boxed{\gcd(a,b)=1.}
\]

---

## 3. The p-divisible denominators have equal p-adic valuation

The inverse-map identity is

\[
\boxed{z(ky-px)=pxy.}
\]

Since

\[
ky-px=ga
\]

and `p∤g,x`, taking p-adic valuations gives

\[
v_p(z)+v_p(a)=1+v_p(y).
\]

By the chosen ordering,

\[
v_p(y)\le v_p(z).
\]

Also `a=kq-pb` is divisible by `p`, because both terms are divisible by `p`; hence

\[
v_p(a)\ge1.
\]

Therefore

\[
1
\le
v_p(a)
=
1+v_p(y)-v_p(z)
\le1.
\]

So equality holds throughout:

\[
\boxed{v_p(a)=1}
\]

and

\[
\boxed{v_p(y)=v_p(z).}
\]

Thus we may write

\[
\boxed{a=pA}
\]

with

\[
\boxed{p\nmid A.}
\]

Because `gcd(a,b)=1`, also

\[
\boxed{\gcd(A,b)=1,\qquad p\nmid b.}
\]

---

## 4. Remove the mandatory factor p from q

Write

\[
\boxed{q=pQ.}
\]

The defining relation

\[
kq=a+bp
\]

becomes

\[
kpQ=pA+bp.
\]

Divide by `p`:

\[
\boxed{kQ=A+b.}
\]

Hence

\[
\boxed{k\mid A+b}
\]

and

\[
\boxed{Q=\frac{A+b}{k}.}
\]

Because `gcd(A,b)=1`, any divisor of `A+b`, including `Q`, is coprime to both `A` and `b`:

\[
\boxed{\gcd(Q,Ab)=1.}
\]

---

## 5. Collapse the remaining fab admissibility to one congruence

The two published conditions are

\[
4b\mid q(p+k)
\]

and

\[
4a\mid pq(p+k).
\]

Substitute

\[
a=pA,
\qquad
q=pQ.
\]

The first becomes

\[
4b\mid pQ(p+k),
\]

and the second becomes

\[
4pA\mid p^2Q(p+k),
\]

or

\[
4A\mid pQ(p+k).
\]

Since

\[
p\nmid Ab
\]

and

\[
\gcd(Q,Ab)=1,
\]

the `A`- and `b`-parts must come from `p+k`.

Also

\[
p\equiv1\pmod4,
\qquad
k\equiv3\pmod4,
\]

so

\[
4\mid p+k.
\]

If one of `A,b` is even, then `A+b=kQ` is odd times `Q`; coprimality forces the other parameter odd and consequently `Q` is odd, so the full 2-adic requirement also lies in `p+k`.

If both `A,b` are odd, then `Ab` is odd and `4|p+k` is already enough for the 2-part.

Thus the two published conditions are simultaneously equivalent to

\[
\boxed{4Ab\mid p+k.}
\]

Equivalently,

\[
\boxed{k\equiv-p\pmod{4Ab}.}
\]

---

## 6. Type II divisor-congruence theorem

### Theorem

A prime

\[
p\equiv1\pmod4
\]

has a Type II Erdős-Straus solution if and only if there exist positive integers

\[
A,b,k
\]

such that

\[
\boxed{\gcd(A,b)=1}
\]

\[
\boxed{p\nmid Ab}
\]

\[
\boxed{k\mid A+b}
\]

and

\[
\boxed{k\equiv-p\pmod{4Ab}.}
\]

The congruence automatically gives

\[
k\equiv3\pmod4.
\]

---

## 7. Forward construction from the criterion

Assume the criterion.

Put

\[
Q=\frac{A+b}{k},
\qquad
a=pA,
\qquad q=pQ.
\]

Then

\[
kq=kpQ=p(A+b)=a+bp.
\]

Thus `k|a+bp` and `q=(a+bp)/k`.

The congruence

\[
4Ab\mid p+k
\]

immediately implies both published `fab` divisibility conditions.

The resulting Erdős-Straus denominators are

\[
\boxed{X=\frac{p+k}{4}}
\]

\[
\boxed{Y=\frac{pQ(p+k)}{4b}}
\]

\[
\boxed{Z=\frac{pQ(p+k)}{4A}}.
\]

Because `p∤kAbQ` is not required for Q but `p∤kAb` follows from the congruence and `p∤Ab`, one has

\[
p\nmid X,
\]

while

\[
p\mid Y,\qquad p\mid Z.
\]

If `Q` itself contains additional powers of `p`, both `Y` and `Z` gain them equally.

Hence exactly two denominators are p-divisible: the constructed solution is Type II.

---

## 8. Reverse construction from any Type II solution

Sections 1–5 prove the converse:

- choose the unique p-free scaled denominator as `x`;
- choose the lesser-p-adic p-divisible denominator as `y`;
- the inverse map yields coprime `a,b`;
- p-adic valuation forces `a=pA` with `p∤A`;
- write `q=pQ`;
- obtain `kQ=A+b`;
- the published admissibility collapses to `4Ab|p+k`.

Thus every Type II solution yields the displayed divisor-congruence data.

QED.

---

## 9. Complete two-system reformulation of prime Erdős-Straus

Combining `FAB-TYPE-I-EQUIVALENCE.md` and this theorem, a prime

\[
p\equiv1\pmod4
\]

satisfies Erdős-Straus if and only if **at least one** of the following holds.

### Type I system

There exist positive `a,b,k` with

\[
\gcd(a,b)=1,
\qquad p\nmid a,
\]

\[
\boxed{k\mid a+bp}
\]

and

\[
\boxed{k\equiv-p\pmod{4ab}.}
\]

### Type II system

There exist positive `A,b,k` with

\[
\gcd(A,b)=1,
\qquad p\nmid Ab,
\]

\[
\boxed{k\mid A+b}
\]

and

\[
\boxed{k\equiv-p\pmod{4Ab}.}
\]

This is a complete prime reformulation entirely in coprime divisor-congruence coordinates.

---

## 10. Structural asymmetry

The two systems have the same target congruence shape

\[
k\equiv-p\pmod{4uv},
\]

but very different divisor sources:

- Type I: `k` divides the **target-dependent** linear form `a+bp`;
- Type II: `k` divides the **parameter-only** sum `A+b`.

That asymmetry explains why Type II naturally produces fixed congruence families, while Type I is divisor-adaptive to the target prime.

It also gives a precise framework for combining the Type I coprime-plane search with López Type A/B, which are structured Type II subclasses.
