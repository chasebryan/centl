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

Since the divisors of `2^a` are exactly

\[
1,2,\ldots,2^a,
\]

we obtain powers of `2` throughout the trap set.

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
\boxed{
|T_{2^a}|=a+2
}
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

Now the divisors `e|2^a` are `2^i` for `0<=i<=a`. The two Type A/B trap families are

\[
-2^i
\]

and

\[
-4\cdot2^i=-2^{i+2}.
\]

Together their exponents cover a complete residue cycle modulo the order `a+2`. Hence the resulting set is exactly

\[
-\langle2\rangle.
\]

Equivalently, the general trap-cardinality theorem gives

\[
|T_{2^a}|
=2\tau(2^a)-1-\tau(2^{a-2})
=a+2
\]

for `a>=2`, with `a=1` checked directly. Since the trap set is contained in the coset and both have cardinality `a+2`, equality follows. QED.

## 3. Mersenne divisibility

The moduli satisfy the classical identity

\[
2^u-1\mid2^v-1
\iff
u\mid v.
\]

Therefore, for `a,b>=1`,

\[
\boxed{
m_a\mid m_b
\iff
a+2\mid b+2.}
\]

## 4. Exact shadow theorem

### Theorem

Let `1<=a<b`. If

\[
\boxed{a+2\mid b+2,}
\]

then the entire Type A/B layer at depth `2^b` is directly shadowed by the earlier layer at depth `2^a`.

Equivalently,

\[
\boxed{
T_{2^b}\bmod m_a
\subseteq
T_{2^a}.
}
\]

### Proof

The divisibility assumption gives

\[
m_a\mid m_b.
\]

By the exact power-of-two coset theorem,

\[
T_{2^b}=-\langle2\rangle\pmod{m_b}.
\]

Reducing any element

\[
-2^r\pmod{m_b}
\]

modulo `m_a` gives

\[
-2^r\pmod{m_a},
\]

which belongs to

\[
-\langle2\rangle=T_{2^a}.
\]

Thus every integer hitting the later layer automatically hits the earlier layer. QED.

## 5. Infinite structural gaps in the minimal-depth spectrum

A depth `k` can occur as a minimal Type A/B witness depth only if some integer reaches `T_k` while avoiding every earlier trap layer.

The shadow theorem therefore gives:

### Corollary

If `b>=1` and there exists `a` with

\[
1<=a<b,
\qquad
a+2\mid b+2,
\]

then

\[
\boxed{
C_{AB}(n)\ne2^b
}
\]

for every integer `n` for which `C_AB(n)` is defined.

In particular, there are infinitely many structurally impossible finite depths.

For example, choose

\[
b=3r-2,
\qquad r\ge2.
\]

Then

\[
3=a+2\mid b+2=3r
\]

with `a=1`, so

\[
\boxed{
2^{3r-2}
\text{ is completely shadowed by depth }2.
}
\]

Hence the exact-depth spectrum has infinitely many gaps.

## 6. Near-classification inside the power-of-two subsequence

For `b>=3`, if `b+2` is composite, it has a proper divisor `d>=3`. Taking

\[
a=d-2
\]

gives `1<=a<b` and

\[
a+2=d\mid b+2.
\]

Therefore:

\[
\boxed{
 b\ge3,\ b+2\text{ composite}
\Longrightarrow
2^b\text{ is structurally impossible as a minimal Type A/B depth.}
}
\]

Thus, among power-of-two depths beyond the initial cases, only exponents satisfying

\[
\boxed{b+2\text{ prime}}
\]

can escape this particular Mersenne-ancestry obstruction.

This is a necessary condition within the power-of-two subsequence, not a proof that every such remaining depth is realizable.

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

## 7. Shadow-lattice interpretation

Inside the power-of-two subsequence, define the node label

\[
n=a+2.
\]

Then modulus divisibility and direct shadow ancestry are controlled by ordinary divisibility of the labels:

\[
\boxed{
n_a\mid n_b
\Longrightarrow
2^b\to2^a
\text{ in the direct-shadow graph.}
}
\]

The resulting subgraph is therefore a reversed divisibility lattice on the shifted exponents `a+2`.

This is the first explicit infinite sublattice currently isolated inside the Type A/B shadow graph.

## 8. Why this matters

The depth-spectrum work previously distinguished two reasons for an absent finite depth:

1. **latency:** a realizable depth whose first observed prime lies beyond the search bound;
2. **structure:** a depth prohibited by exact congruence ancestry.

The Mersenne shadow lattice proves that the second phenomenon occurs infinitely often.

So the minimal Type A/B depth spectrum is not merely sparse because primes arrive late. It has an infinite deterministic deletion mechanism built into the arithmetic of the moduli themselves.

## 9. Next targets

1. search for analogous exact-coset families at `k=p^a` for odd primes `p`;
2. classify all `k` for which `T_k=-H_k`;
3. derive additional infinite shadow lattices from exact subgroup equality;
4. intersect these lattices with the hard-compatible spectrum;
5. determine whether structural gaps have a positive or zero density among depths;
6. incorporate proved infinite gap families into the exact-depth spectrum theorem program.
