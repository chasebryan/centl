# Power-of-Two `fab` Divisor Layers

**Status:** proved exact sufficient-and-necessary criterion inside the subfamily `a=1`, `b=2^t`  
**Date:** 2026-08-15  
**Prior-art basis:** Bello-Hernández, Benito, Fernández (2026), `fab` divisor identity.  
**Claim boundary:** this is a specialization/reorganization of the published divisor identity, not a claim that FCF invented the underlying parametrization. It supplies an independent sieve for the ES prime remainder; it does not prove universal coverage.

---

## 1. Published `fab` identity

For `n≡1 (mod 4)`, the 2026 divisor parametrization takes positive integers `a,b` and a divisor

\[
k\mid a+bn,
\qquad
k\equiv3\pmod4.
\]

Writing

\[
q=\frac{a+bn}{k},
\]

the admissibility conditions are

\[
4b\mid q(n+k),
\qquad
4a\mid nq(n+k).
\]

When these hold,

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

## 2. Specialize to `a=1`, `b=2^t`

Let

\[
t\ge0,
\qquad
b=2^t,
\qquad
a=1,
\]

and let `n≡1 (mod4)` be odd.

Suppose

\[
k\mid1+2^t n.
\]

Since `1+2^t n` is odd for `t>=1`, every divisor `k` and quotient

\[
q=\frac{1+2^tn}{k}
\]

are odd. For `t=0`, `1+n` is even, so the parity discussion differs; the criterion below is still valid directly from the divisibility conditions.

For `t>=1`, the first `fab` divisibility condition becomes

\[
2^{t+2}\mid q(n+k).
\]

Because `q` is odd, this is equivalent to

\[
\boxed{2^{t+2}\mid n+k.}
\]

Equivalently,

\[
\boxed{k\equiv-n\pmod{2^{t+2}}.}
\]

Since `n≡1 (mod4)`, this automatically implies

\[
k\equiv3\pmod4.
\]

The second admissibility condition

\[
4\mid nq(n+k)
\]

is automatic once `2^{t+2}|n+k`.

Therefore we obtain the exact criterion below for every `t>=1`.

---

## 3. Theorem — exact power-of-two layer criterion

Let

\[
n\equiv1\pmod4,
\qquad t\ge1.
\]

Then the `fab` subfamily

\[
(a,b)=(1,2^t)
\]

produces an Erdős-Straus decomposition **if and only if** there is a positive divisor

\[
\boxed{k\mid1+2^t n}
\]

with

\[
\boxed{k\equiv-n\pmod{2^{t+2}}.}
\]

For such a divisor put

\[
q=\frac{1+2^t n}{k}.
\]

Then

\[
\boxed{
\frac4n
=
\frac1x+
\frac1y+
\frac1z
}
\]

with

\[
\boxed{
x=\frac{n+k}{4}}
\]

\[
\boxed{
y=\frac{q(n+k)}{2^{t+2}}}
\]

and

\[
\boxed{
z=\frac{nq(n+k)}4.}
\]

All three are positive integers.

---

## 4. The `t=0` layer

For

\[
(a,b)=(1,1),
\]

the criterion is especially simple.

If

\[
\boxed{k\mid n+1,\qquad k\equiv3\pmod4,}
\]

then with

\[
q=\frac{n+1}{k}
\]

we obtain

\[
\boxed{
x=\frac{n+k}{4},
\qquad
y=\frac{q(n+k)}4,
\qquad
z=\frac{nq(n+k)}4.}
\]

Conversely this is exactly the admissibility condition in the `(1,1)` subfamily.

Hence any `n≡1 mod4` for which `n+1` has a divisor `3 mod4` is solved immediately.

In particular, if the odd part of `n+1` has a prime factor

\[
\ell\equiv3\pmod4,
\]

then choosing `k=ell` solves `n`.

---

## 5. Hard-prime specialization

Every Mordell-hard residue class modulo 840 used by the Type A/B program satisfies

\[
p\equiv1\pmod8.
\]

### Layer `t=0`

A hard prime is solved whenever

\[
p+1
\]

has an odd divisor `3 mod4`.

Therefore a survivor of this first `fab` layer must have the odd part

\[
\frac{p+1}{2}
\]

supported entirely on primes

\[
\boxed{1\pmod4.}
\]

### Layer `t=1`

Here

\[
1+2p
\]

is odd and the exact divisor condition is

\[
k\equiv-p\pmod8.
\]

For a hard prime `p≡1 mod8`, this becomes

\[
\boxed{k\equiv7\pmod8.}
\]

Thus every hard prime for which

\[
2p+1
\]

has a divisor `7 mod8` is solved by the `(a,b)=(1,2)` layer.

A particularly simple sufficient condition is that `2p+1` have a prime factor

\[
\ell\equiv7\pmod8.
\]

---

## 6. Higher binary layers

For each

\[
t\ge2,
\]

the target divisor is in one exact odd residue class modulo

\[
2^{t+2}:
\]

\[
\boxed{k\equiv-p\pmod{2^{t+2}}.}
\]

So the binary `fab` hierarchy examines the shifted odd integers

\[
1+2^t p
\]

for divisors in a target 2-adic class determined by `p`.

This gives an independent all-prime sieve:

\[
\boxed{
\text{Type A/B survivors}
\quad\cap\quad
\text{binary-fab survivors}
}
\]

rather than forcing the complete proof through one parametrization alone.

---

## 7. Translation-invariant congruence families

For fixed `t` and a fixed admissible divisor `k`, the published translation-invariance proposition gives another view of the same layer.

With

\[
a=1,
\qquad b=2^t,
\]

one admissible value of `n` propagates by

\[
\boxed{n\mapsto n+2^{t+2}k.}
\]

Thus every fixed `(t,k)` certificate solves a complete arithmetic progression.

The all-prime problem can therefore be reframed as a covering/survivor problem in the `(t,k)` divisor layers, in parallel with the Type A/B trap system.

---

## 8. Next attack

1. Enumerate the exact survivor classes of the first few binary layers on the six Mordell-hard classes.
2. Intersect those survivors with the Type A/B survivor machinery and collective-core reductions.
3. Search for a structural descent showing that a prime cannot survive all binary layers and all Type A/B layers simultaneously.
4. Extend beyond `a=1` only when the binary hierarchy leaves a clearly structured residue/factorization core.
