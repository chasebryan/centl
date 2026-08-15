# Mersenne shadow lattice: an infinite exact family of impossible Type A/B minimal depths

**Status:** proved infinite exact shadow family  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem does not prove universal López Type A/B coverage or the Erdős-Straus conjecture. It proves an infinite family of exact redundancies inside the López Type A/B depth system. Literature priority for this formulation remains under review.

Read with:

- [THEORY.md](THEORY.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md)
- [TRAP-QUOTIENT-FACTORIZATION.md](TRAP-QUOTIENT-FACTORIZATION.md)
- [PRIME-POWER-TRAP-DICHOTOMY.md](PRIME-POWER-TRAP-DICHOTOMY.md)

## 1. Power-of-two layers

Let

\[
k_a=2^a,
\qquad a\ge1,
\]

and put

\[
m_a=4k_a-1=2^{a+2}-1.
\]

The Type A/B trap set is

\[
T_{k_a}
=
\{-e,-4e\pmod{m_a}:e\mid2^a\}.
\]

## 2. Exact power-of-two coset theorem

### Theorem

For every `a>=1`,

\[
\boxed{
T_{2^a}
=-\langle2\rangle
\pmod{2^{a+2}-1}.
}
\]

Moreover

\[
\boxed{|T_{2^a}|=a+2}
\]

and

\[
\boxed{
\operatorname{ord}_{2^{a+2}-1}(2)=a+2.
}
\]

### Proof

Because

\[
2^{a+2}\equiv1\pmod{2^{a+2}-1},
\]

the order of `2` divides `a+2`.

If `1<=d<a+2`, then

\[
0<2^d-1<2^{a+2}-1,
\]

so the modulus cannot divide `2^d-1`. Hence no smaller positive exponent gives `1`, and therefore

\[
\operatorname{ord}_{m_a}(2)=a+2.
\]

Thus

\[
|\langle2\rangle|=a+2.
\]

The divisors of `2^a` are `2^i`, `0<=i<=a`. The Type A/B trap families are

\[
-2^i
\]

and

\[
-4\cdot2^i=-2^{i+2}.
\]

Together these exponents cover one complete cycle modulo the order `a+2`. Hence

\[
T_{2^a}=-\langle2\rangle.
\]

Equivalently, the general trap-cardinality formula gives the same cardinality. QED.

## 3. Mersenne divisibility

The moduli satisfy

\[
2^u-1\mid2^v-1
\iff
u\mid v.
\]

Therefore

\[
\boxed{
m_a\mid m_b\iff a+2\mid b+2.}
\]

## 4. Exact shadow theorem

### Theorem

Let `1<=a<b`. If

\[
\boxed{a+2\mid b+2,}
\]

then the entire Type A/B layer at depth `2^b` is directly shadowed by the earlier layer at depth `2^a`:

\[
\boxed{
T_{2^b}\bmod m_a
\subseteq
T_{2^a}.
}
\]

### Proof

The divisibility assumption gives `m_a|m_b`. By the power-of-two coset theorem,

\[
T_{2^b}=-\langle2\rangle\pmod{m_b}.
\]

Reducing `-2^r mod m_b` modulo `m_a` gives `-2^r mod m_a`, which belongs to

\[
-\langle2\rangle=T_{2^a}.
\]

So every later hit is already an earlier hit. QED.

## 5. Infinite structural gaps

If there exists `a` with

\[
1\le a<b,
\qquad
a+2\mid b+2,
\]

then

\[
\boxed{C_{AB}(n)\ne2^b}
\]

for every integer `n` for which `C_AB(n)` is defined.

In particular, choosing

\[
b=3r-2,
\qquad r\ge2,
\]

gives

\[
3\mid b+2
\]

and therefore

\[
\boxed{2^{3r-2}\text{ is completely shadowed by depth }2.}
\]

Hence the exact-depth spectrum has infinitely many structural gaps.

## 6. Near-classification inside the power-of-two subsequence

For `b>=3`, if `b+2` is composite, it has a proper divisor `d>=3`. Taking

\[
a=d-2
\]

gives

\[
1\le a<b,
\qquad
a+2\mid b+2.
\]

Therefore

\[
\boxed{
 b\ge3,\ b+2\text{ composite}
\Longrightarrow
2^b\text{ is structurally impossible as a minimal Type A/B depth.}
}
\]

Thus only exponents with

\[
\boxed{b+2\text{ prime}}
\]

can escape this particular Mersenne-ancestry obstruction once `b>=3`.

This is necessary, not sufficient, for realization.

Examples:

```text
k=8     : b=3,  b+2=5 prime       -> not killed by this family
k=16    : b=4,  b+2=6 composite   -> shadowed by k=2
k=32    : b=5,  b+2=7 prime       -> not killed by this family
k=64    : b=6,  b+2=8 composite   -> shadowed by k=4
k=128   : b=7,  b+2=9 composite   -> shadowed by k=2
k=256   : b=8,  b+2=10 composite  -> shadowed by k=8
k=512   : b=9,  b+2=11 prime      -> not killed by this family
k=1024  : b=10, b+2=12 composite  -> shadowed by k=2 and k=4
```

## 7. Density-one structural deletion inside the binary subsequence

Let

\[
E(B)=\#\{3\le b\le B:\ 2^b\text{ is not killed by the Mersenne shadow theorem}\}.
\]

The necessary condition above gives

\[
E(B)\le\#\{3\le b\le B:b+2\text{ prime}\}.
\]

Therefore

\[
E(B)\le\pi(B+2)+O(1).
\]

By the prime number theorem,

\[
\pi(B+2)\sim\frac{B}{\log B},
\]

so

\[
\boxed{
\frac{E(B)}{B}\to0.
}
\]

Equivalently:

\[
\boxed{
\text{among the power-of-two depth sequence }2^b,
\text{ a density-one set of exponents is structurally impossible.}
}
\]

This is a density statement **within the exponent-indexed binary subsequence**, not a density claim among all positive depths `k`.

## 8. Shadow-lattice interpretation

Label the power-of-two node `2^a` by

\[
n=a+2.
\]

Then

\[
\boxed{
n_a\mid n_b
\Longrightarrow
2^b\to2^a
\text{ in the direct-shadow graph.}
}
\]

The power-of-two subgraph is therefore a reversed divisibility lattice on the shifted exponents.

This is the first explicit infinite sublattice isolated inside the Type A/B shadow graph.

## 9. Binary exceptionalism among prime powers

The companion theorem [PRIME-POWER-TRAP-DICHOTOMY.md](PRIME-POWER-TRAP-DICHOTOMY.md) proves that this exact coset saturation is special to `p=2`.

For odd prime powers

\[
k=p^a,
\]

the trap set has the exponent-window form

\[
T_{p^a}=\{-p^j:-a\le j\le a\},
\]

but

\[
\boxed{T_{p^a}\subsetneq-\langle p\rangle.}
\]

Thus the Mersenne lattice is a genuinely binary phenomenon, not generic prime-power behavior.

## 10. Why this matters

The depth-spectrum program distinguishes:

1. **latency gaps**, where a realizable depth simply appears beyond a finite prime cutoff;
2. **structural gaps**, where congruence ancestry makes minimal realization impossible.

The Mersenne shadow lattice proves not merely that structural gaps exist, but that they occur in an explicit infinite family and dominate the power-of-two subsequence in exponent density.

So the minimal Type A/B spectrum contains deterministic arithmetic holes on every scale.

## 11. Next targets

1. classify all `k` for which `T_k=-H_k`;
2. derive additional infinite shadow lattices from exact or near-exact subgroup saturation;
3. determine whether analogous lattices exist for products of a bounded number of primes;
4. intersect infinite structural-gap families with hard-compatible candidates;
5. determine the density of structural gaps among all depths, not merely within special subsequences;
6. integrate these infinite gap families into a publication-grade exact-depth spectrum theorem.
