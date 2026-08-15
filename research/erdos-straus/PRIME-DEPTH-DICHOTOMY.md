# Complete dichotomy for prime Type A/B minimal depths

**Status:** proved universal structural theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem classifies **prime values of the depth parameter** `k` inside the López Type A/B minimal-depth system. It does not prove that every prime input has finite `C_AB`, and it does not prove the Erdős-Straus conjecture. Literature priority for this minimal-depth formulation remains under review.

Read with:

- [THEORY.md](THEORY.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [SPECTRUM-INFINITE-COINFINITE.md](SPECTRUM-INFINITE-COINFINITE.md)
- [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md)

## 1. Setup

For a depth `k`, put

\[
m_k=4k-1
\]

and

\[
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

When `k` itself is prime, its only divisors are `1` and `k`, so

\[
\boxed{
T_k=\{-1,-4,-k,-4k\}\pmod{m_k}.
}
\]

Since

\[
4k\equiv1\pmod{m_k},
\]

the last residue duplicates `-1`, but keeping all four forms makes the ancestry argument transparent.

## 2. Composite target modulus always has a 1 mod 4 factor

### Lemma

Let `m>1` satisfy

\[
m\equiv3\pmod4.
\]

If `m` is composite, then there is a proper factorization

\[
\boxed{m=AB}
\]

with

\[
\boxed{1<A<m,\qquad A\equiv1\pmod4,\qquad B\equiv3\pmod4.}
\]

### Proof

Factor `m` into primes with multiplicity.

If some prime divisor is `1 mod 4`, choose that prime as `A`; the complementary factor is then `3 mod 4`.

Otherwise every prime divisor is `3 mod 4`. Since the total product is `3 mod 4`, the number of prime factors counted with multiplicity is odd. Composite then means there are at least three. Choose any two of them for `A`; their product is `1 mod 4`, and the nontrivial complementary factor remains `3 mod 4`.

QED.

Write

\[
A=4s+1,
\qquad
B=4j-1.
\]

Then

\[
m_k=(4s+1)(4j-1).
\]

Expanding gives

\[
\boxed{k=(4s+1)j-s.}
\]

Thus `j<k` and this is exactly a modulus-ancestry relation

\[
\boxed{m_k=(4s+1)m_j.}
\]

## 3. Prime-target ancestry shadow theorem

### Theorem

Let `k` be prime. If

\[
4k-1
\]

is composite, then the complete Type A/B layer at depth `k` is directly shadowed by an earlier depth `j<k`.

### Proof

Use the factorization above:

\[
4k-1=(4s+1)(4j-1).
\]

Hence

\[
k=(4s+1)j-s=s(4j-1)+j,
\]

so

\[
\boxed{k\equiv j\pmod{4j-1}.}
\]

Also

\[
4k=(4s+1)(4j-1)+1,
\]

so

\[
\boxed{4k\equiv1\pmod{4j-1}.}
\]

Because `k` is prime,

\[
T_k=\{-1,-4,-k,-4k\}.
\]

Reducing these residues modulo `m_j=4j-1` gives

\[
\{-1,-4,-j,-1\}.
\]

But `1|j` and `j|j`, so

\[
-1,-4,-j\in T_j.
\]

Therefore

\[
\boxed{
T_k\bmod m_j\subseteq T_j.
}
\]

Every integer hitting layer `k` already hits layer `j<k`. Hence `k` can never be a minimal Type A/B depth. QED.

## 4. Prime-modulus realization

If instead

\[
4k-1
\]

is prime, the prime-modulus backbone theorem applies. The target modulus contributes a new CRT coordinate relative to all earlier Type A/B moduli, and one obtains reduced arithmetic progressions containing infinitely many primes with exact depth `k`.

In particular, even within the Mordell-hard class

\[
p\equiv1\pmod{840},
\]

there are infinitely many primes `p` satisfying

\[
\boxed{C_{AB}(p)=k.}
\]

See [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md).

## 5. Prime-depth classification theorem

Combining the two directions gives:

### Theorem

For every prime depth `k`, exactly one of the following occurs.

### Realized side

If

\[
\boxed{4k-1\text{ is prime},}
\]

then infinitely many primes, including infinitely many in the hard class `1 mod 840`, satisfy

\[
\boxed{C_{AB}(p)=k.}
\]

### Structural-gap side

If

\[
\boxed{4k-1\text{ is composite},}
\]

then layer `k` is completely directly shadowed by an earlier layer, and

\[
\boxed{C_{AB}(n)\ne k}
\]

for every integer `n` for which `C_AB(n)` is defined.

Equivalently, for prime `k`,

\[
\boxed{
k\in\mathcal D_H
\iff
k\in\mathcal D_{\mathbb P}
\iff
4k-1\text{ is prime}.}
\]

This is a complete exact classification of the spectrum on the prime-depth subsequence.

## 6. Infinite ancestry families

The proof can be read constructively.

Fix any

\[
s\ge1,
\qquad
A=4s+1.
\]

If a prime depth `k` satisfies

\[
\boxed{k\equiv-s\pmod A,}
\]

then

\[
A\mid4k-1.
\]

Writing

\[
4k-1=A(4j-1)
\]

gives an earlier source depth

\[
\boxed{j=(k+s)/A}
\]

that directly shadows `k`.

Because

\[
\gcd(s,4s+1)=1,
\]

Dirichlet's theorem gives infinitely many prime depths in each such residue class.

The first family is

\[
s=1,
\qquad
A=5,
\]

so every prime depth

\[
\boxed{k\equiv4\pmod5}
\]

is completely shadowed by

\[
\boxed{j=(k+1)/5.}
\]

Examples:

```text
k=19  -> j=4,  m_k=75 = 5*15
k=29  -> j=6,  m_k=115 = 5*23
k=59  -> j=12, m_k=235 = 5*47
k=79  -> j=16, m_k=315 = 5*63
```

Every listed prime depth is structurally impossible, irrespective of how far one searches over input primes.

## 7. Stronger structural-gap counting bound

Let

\[
G(X)=|[1,X]\setminus\mathcal D_{\mathbb P}|.
\]

Every prime

\[
k\le X,
\qquad
k\equiv4\pmod5
\]

is a global structural gap by the `s=1` ancestry family.

Therefore

\[
\boxed{
G(X)\ge\pi(X;5,4)-O(1).
}
\]

By the prime number theorem in arithmetic progressions,

\[
\pi(X;5,4)
\sim
\frac{1}{4}\frac{X}{\log X}.
\]

Hence

\[
\boxed{
G(X)\ge
\left(\frac14+o(1)\right)\frac{X}{\log X}.
}
\]

In particular,

\[
\boxed{G(X)\gg X/\log X.}
\]

This improves the previously recorded logarithmic lower bound coming only from the sparse power-of-two Mersenne family.

The same lower bound applies to the complement of the hard-class infinite-realization spectrum because these are global gaps for every integer.

## 8. Relation to the Mersenne lattice

The Mersenne lattice and the prime-depth dichotomy are two different exact deletion mechanisms:

- the Mersenne theorem uses **coset saturation** in the binary power-of-two family;
- the prime-depth theorem uses **extreme divisor sparsity** of a prime target depth together with any nontrivial modulus ancestry factorization.

Together they show that structural gaps are produced both by highly structured target divisor sets and by maximally sparse target divisor sets.

## 9. Research significance

This theorem gives a complete infinite-subsequence classification with no unresolved union-shadow issue:

\[
\boxed{
\text{prime depth }k
\longleftrightarrow
\begin{cases}
4k-1\text{ prime}: & \text{infinitely realized},\\
4k-1\text{ composite}: & \text{globally impossible}.
\end{cases}
}
\]

The remaining spectrum problem therefore begins in earnest on **composite target depths**.

That sharply localizes the hard part of Direct-Shadow Completeness and the exact-depth spectrum.
