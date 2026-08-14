# Prime-modulus backbone of the Type A/B depth spectrum

**Status:** theorem note
**Date:** 2026-08-14
**Claim boundary:** this note applies classical CRT, Dirichlet's theorem on primes in arithmetic progressions, and the Type A/B congruence characterization. It does not claim the Erdős-Straus conjecture is solved, and it does not make a literature-priority claim without a separate prior-art review.

## 1. Setup

Let

\[
m_k=4k-1,
\qquad
T_k=\{-e,-4e\pmod{m_k}:e\mid k\},
\]

and for a prime `p` define

\[
C_{AB}(p)=\min\{k\ge1:p\bmod m_k\in T_k\},
\]

with `C_AB(p)=infinity` if no such `k` exists.

The elementary control lemma used below is

\[
1\notin T_j\qquad\text{for every }j\ge1.
\]

## 2. Prime-modulus exact-depth theorem

### Theorem

Let `k` be such that

\[
q=4k-1
\]

is a prime greater than `7`. Then there exist infinitely many primes `p` satisfying

\[
\boxed{C_{AB}(p)=k}.
\]

Moreover all of these primes may be chosen in the Mordell hard class

\[
\boxed{p\equiv1\pmod{840}}.
\]

### Proof

Define

\[
L_{k-1}=\operatorname{lcm}\bigl(840,\{4j-1:1\le j<k\}\bigr).
\]

Because `q=4k-1` is prime and

\[
q>4j-1
\]

for every `j<k`, the prime `q` divides none of the earlier moduli `4j-1`. Since `q>7`, it also divides neither `840`. Therefore

\[
\gcd(q,L_{k-1})=1.
\]

By CRT there is a unique residue class `a mod qL_{k-1}` satisfying

\[
a\equiv1\pmod{L_{k-1}},
\qquad
 a\equiv-1\pmod q.
\]

This residue is reduced:

\[
\gcd(a,qL_{k-1})=1,
\]

because it is `1` modulo every prime divisor of `L_{k-1}` and `-1` modulo `q`.

Dirichlet's theorem now gives infinitely many primes

\[
p\equiv a\pmod{qL_{k-1}}.
\]

For every earlier layer `j<k`,

\[
p\equiv1\pmod{4j-1}.
\]

Since `1` is never a Type A/B trap residue,

\[
p\bmod(4j-1)\notin T_j.
\]

At the target layer,

\[
p\equiv-1\pmod{4k-1}.
\]

Because `1|k`, the residue `-1` belongs to `T_k`. Therefore the first Type A/B hit is exactly `k`:

\[
\boxed{C_{AB}(p)=k}.
\]

Finally, `840|L_{k-1}`, so all these primes satisfy `p=1 mod 840`. QED.

## 3. Consequence: finite C_AB values are unbounded

There are infinitely many primes

\[
q\equiv3\pmod4.
\]

Every such prime `q>7` can be written uniquely as

\[
q=4k-1
\]

with

\[
k=\frac{q+1}{4}.
\]

Applying the theorem to each such `k` produces infinitely many distinct exact finite values of `C_AB`.

Hence

\[
\boxed{C_{AB}(p)\text{ is unbounded even when restricted to finite values.}}
\]

This is stronger than the earlier observation that, for every `K`, infinitely many primes can be forced to have `C_AB(p)>K` or `C_AB(p)=infinity`. The prime-modulus construction exhibits arbitrarily large layers that are definitely reached, and reached by infinitely many primes.

## 4. Prime-modulus backbone

Let `D_H` denote the hard-class minimal-depth spectrum:

\[
\mathcal D_H
=
\{k:\text{infinitely many primes }p\equiv h\pmod{840},\ h\in H,\ C_{AB}(p)=k\}.
\]

Define

\[
\mathcal B
=
\left\{\frac{q+1}{4}:q>7\text{ prime},\ q\equiv3\pmod4\right\}.
\]

Then

\[
\boxed{\mathcal B\subseteq\mathcal D_H.}
\]

In fact every depth in `B` is realized infinitely often already inside the single hard class `1 mod 840`.

We call `B` the **prime-modulus backbone** of the Type A/B minimal-depth spectrum.

## 5. Quantitative lower bound for the spectrum

The prime number theorem for arithmetic progressions gives

\[
\pi(x;4,3)\sim\frac12\operatorname{Li}(x).
\]

Therefore the number of prime-modulus backbone depths up to `K` satisfies

\[
|\mathcal B\cap[1,K]|
=
\pi(4K-1;4,3)+O(1)
\sim
\frac{2K}{\log(4K)}.
\]

Consequently

\[
\boxed{
|\mathcal D_H\cap[1,K]|
\ge
(1+o(1))\frac{2K}{\log(4K)}.
}
\]

This is only a lower bound. Composite target moduli `4k-1` contribute many additional realized depths in the computational spectrum.

## 6. Explicit Type B family on every backbone depth

The target residue in the proof is

\[
p\equiv-1\pmod{4k-1}.
\]

This is a Type B congruence with

\[
d=k,
\qquad n=1.
\]

Write

\[
p=(4k-1)t-1.
\]

Then the standard Type B construction gives

\[
x=kt,
\qquad
y=ktp,
\qquad
z=kp.
\]

Indeed,

\[
\frac1{kt}+\frac1{ktp}+\frac1{kp}
=
\frac{p+1+t}{ktp}
=
\frac{(4k-1)t+t}{ktp}
=
\frac4p.
\]

Thus every prime produced by the theorem comes with an explicit exact Erdős-Straus decomposition.

## 7. Why this matters for the shadow program

The prime-modulus backbone gives an infinite family of layers that cannot be structural gaps.

For these `k`, the earlier shadow closure is guaranteed to have an uncovered reduced class. Therefore any proposed global theory of the shadow graph must contain an infinite irreducible backbone indexed by primes `4k-1`.

This creates a sharper theorem target:

- understand the guaranteed prime-modulus backbone;
- characterize which composite `4k-1` layers join it;
- characterize which composite layers are structural gaps because of admissibility or shadow closure;
- study the arrival function on both the backbone and the additional composite-modulus spectrum.

The hard-class minimal-depth spectrum is therefore provably infinite before any conjectural Type A/B coverage assumption is used.
