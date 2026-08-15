# GCD-square reformulation of coprime fab rescue

**Status:** proved exact construction and converse on the coprime fab range  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`  
**Claim boundary:** this is a new exact reformulation/construction. It does not prove that the required pair always exists, and therefore does not prove Erdős–Straus.

## 1. From a coprime fab certificate to two `3 mod 4` integers

Let `p≡1 mod4` be prime and suppose coprime positive `a,b` give a fab certificate with divisor `k`:

\[
k\mid a+bp,
\qquad
k\equiv-p\pmod{4ab}.
\]

Write

\[
\boxed{p+k=4abc}
\]

and

\[
q=\frac{a+bp}{k}.
\]

The auxiliary factorization from `FAB-HARD-NONRESIDUE-BRIDGE.md` gives

\[
k(q+b)=a(1+4b^2c).
\]

Since `gcd(a,k)=1`, put

\[
\boxed{kd=1+4b^2c.}
\]

Because `k≡3 mod4` and the right side is `1 mod4`,

\[
\boxed{d\equiv3\pmod4.}
\]

Define

\[
\boxed{M=kd-1=4b^2c.}
\]

Then

\[
p+k=4abc.
\]

Since `gcd(a,b)=1`,

\[
\gcd(p+k,M)
=
\gcd(4abc,4b^2c)
=
\boxed{4bc}.
\]

Call this gcd `G`. Then

\[
\boxed{G=4bc,}
\qquad
\boxed{M=4b^2c.}
\]

Consequently

\[
\boxed{G^2=4cM,}
\]

so in particular

\[
\boxed{4M\mid G^2.}
\]

Moreover the original parameters are recovered exactly:

\[
\boxed{
a=\frac{p+k}{G},
\qquad
b=\frac{M}{G},
\qquad
c=\frac{G^2}{4M}.}
\]

Thus every coprime fab certificate produces two `3 mod 4` integers `k,d` for which the two numbers

\[
p+k,
\qquad
kd-1
\]

have unusually large square overlap.

---

## 2. Converse construction from a gcd-square overlap

Now start with an odd positive integer `p≡1 mod4` and positive integers

\[
\boxed{k\equiv d\equiv3\pmod4.}
\]

Put

\[
M=kd-1,
\qquad
G=\gcd(p+k,M).
\]

Assume the exact divisibility

\[
\boxed{4M\mid G^2.}
\]

Define

\[
\boxed{
a=\frac{p+k}{G},
\qquad
b=\frac{M}{G},
\qquad
c=\frac{G^2}{4M}.}
\]

Then `a,b,c` are positive integers, and because `G` is the full gcd,

\[
\boxed{\gcd(a,b)=1.}
\]

The definitions give

\[
4abc
=4\frac{p+k}{G}\frac{M}{G}\frac{G^2}{4M}
=p+k,
\]

hence

\[
\boxed{p+k=4abc.}
\]

They also give

\[
4b^2c
=4\frac{M^2}{G^2}\frac{G^2}{4M}
=M=kd-1,
\]

so

\[
\boxed{kd=1+4b^2c.}
\]

Set

\[
\boxed{q=ad-b.}
\]

It is positive, because

\[
q
=\frac{d(p+k)-(kd-1)}{G}
=\boxed{\frac{dp+1}{G}}>0.
\]

Finally,

\[
a+bp
=a+b(4abc-k)
=a+4ab^2c-bk
=a+a(kd-1)-bk
=k(ad-b)
=kq.
\]

Therefore

\[
\boxed{k\mid a+bp.}
\]

And since `p+k=4abc`,

\[
\boxed{k\equiv-p\pmod{4ab}}.
\]

Thus the coprime divisor criterion is satisfied whenever its standard size hypotheses are desired. More strongly, the identities above directly produce the positive decomposition

\[
\boxed{
\frac4p
=
\frac1{abc}
+
\frac1{aqc}
+
\frac1{bpqc},
}
\]

so the construction itself does not need a separate bounded-parameter argument.

---

## 3. GCD-square rescue theorem

### Theorem

Let `p≡1 mod4` be a positive odd integer. If there exist positive

\[
k\equiv d\equiv3\pmod4
\]

such that, with

\[
M=kd-1,
\qquad
G=\gcd(p+k,M),
\]

one has

\[
\boxed{4M\mid G^2,}
\]

then `p` satisfies the Erdős–Straus equation.

Every coprime fab certificate produces such a pair `(k,d)`, with the stronger identity

\[
\boxed{G^2=4cM}
\]

for its leftover parameter `c`.

---

## 4. Structural interpretation

The all-prime divisor problem can therefore be attacked as a **square-overlap problem**:

\[
\boxed{
\text{find }k,d\equiv3\pmod4
\text{ such that }
kd-1
\text{ is supported deeply enough inside }p+k.
}
\]

The condition is not merely that the two numbers share a factor. It requires their full gcd to contain at least half of every prime-power valuation of `4(kd-1)`:

\[
2v_\ell(G)\ge v_\ell(4M)
\qquad\text{for every prime }\ell.
\]

This valuation form may be better suited to a descent than the original divisor-in-one-residue-class statement.

Two boundary cases recover familiar shifted-factor mechanisms:

- if `M | p+k`, then `G=M`, and the condition reduces to `4|M`; since `k,d≡3 mod4`, this is automatic. Thus any factorization
  \[
  kd-1\mid p+k
  \]
  is an immediate rescue;
- taking `M=p+k` gives
  \[
  k(d-1)=p+1,
  \]
  which contains the classical `p+1` / `3 mod4` divisor spine as a special case.

The new target is to determine whether the exact hard-prime factor restrictions force such a square overlap for some controlled `(k,d)`, rather than continuing to enumerate unrelated `(a,b)` pairs.
