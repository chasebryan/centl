# Multiplicative semigroup shadow families from saturated Type A/B sources

**Status:** proved general shadow theorem with infinite composite-depth families  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem gives exact structural gaps inside the López Type A/B minimal-depth spectrum. It does not prove universal Type A/B coverage or the Erdős-Straus conjecture. Literature priority remains under review.

Read with:

- [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md)
- [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md)
- [PRIME-DEPTH-DICHOTOMY.md](PRIME-DEPTH-DICHOTOMY.md)
- [SPECTRUM-COUNTING-BOUNDS.md](SPECTRUM-COUNTING-BOUNDS.md)

## 1. Saturated source

For a source depth `j`, put

\[
m_j=4j-1
\]

and

\[
H_j=\langle\ell\bmod m_j:\ell\mid j,\ \ell\text{ prime}\rangle.
\]

The general multiplicative theorem gives

\[
T_j\subseteq-H_j.
\]

Call `j` **coset-saturated** when

\[
\boxed{T_j=-H_j.}
\]

Every power-of-two depth is coset-saturated by the Mersenne theorem. The initial depth `j=1` is also saturated, with

\[
H_1=\{1\}\pmod3,
\qquad
T_1=\{2\}=-H_1.
\]

## 2. Semigroup shadow theorem

### Theorem

Let `j` be coset-saturated. Let `k>j` satisfy

\[
\boxed{m_j\mid m_k}
\]

and suppose every prime divisor `p|k` satisfies

\[
\boxed{p\bmod m_j\in H_j.}
\]

Then the complete Type A/B layer at depth `k` is directly shadowed by depth `j`:

\[
\boxed{
T_k\bmod m_j\subseteq T_j.
}
\]

### Proof

Every divisor `e|k` is a product of prime divisors of `k`. Since each such prime lies in the subgroup `H_j`,

\[
e\bmod m_j\in H_j.
\]

Also

\[
4j\equiv1\pmod{m_j},
\]

and `j in H_j`, so

\[
4\equiv j^{-1}\pmod{m_j}
\]

lies in `H_j` as well.

Therefore

\[
e,4e\in H_j
\]

for every `e|k`, and hence

\[
-e,-4e\in-H_j=T_j.
\]

Thus every target trap reduces into the source trap set. QED.

## 3. The depth-1 structural semigroup

Take

\[
j=1.
\]

Then

\[
m_1=3,
\qquad
H_1=\{1\},
\qquad
T_1=\{2\}.
\]

Suppose every prime divisor of `k>1` satisfies

\[
\boxed{p\equiv1\pmod3.}
\]

Then every divisor `e|k` is also `1 mod 3`, and `k=1 mod 3`. Consequently

\[
3\mid4k-1,
\]

so the modulus-ancestry condition is automatic.

The semigroup shadow theorem gives:

### Corollary

If `k>1` has no prime divisor outside the residue class `1 mod 3`, then

\[
\boxed{T_k\bmod3=T_1=\{2\},}
\]

and therefore

\[
\boxed{C_{AB}(n)\ne k}
\]

for every integer `n` for which `C_AB(n)` is defined.

So the multiplicative semigroup

\[
\boxed{
\mathcal S_3
=
\{k>1:p\mid k\Rightarrow p\equiv1\pmod3\}
}
\]

is an infinite family of global structural gaps.

Examples include

```text
7, 13, 19, 31, 37, ...
7^2 = 49
7*13 = 91
13^2 = 169
7*19 = 133
7*13*19 = 1729
```

The composite examples are not consequences of the prime-depth dichotomy; they are new instances supplied by multiplicative source saturation.

## 4. Binary saturated sources

For every `a>=1`, take

\[
j=2^a,
\qquad
m_j=2^{a+2}-1,
\qquad
H_j=\langle2\rangle.
\]

The Mersenne theorem gives

\[
T_j=-H_j.
\]

Therefore any `k>j` satisfying

\[
k\equiv j\pmod{m_j}
\]

and

\[
p\bmod m_j\in\langle2\rangle
\qquad\text{for every }p\mid k
\]

is directly shadowed by `j`.

This produces a hierarchy of multiplicatively defined structural-gap families attached to the saturated binary sources.

The original Mersenne shadow lattice is the special case where the later target itself is another power of two.

## 5. Why the semigroup condition is natural

The trap-coset theorem says the target divisor set matters multiplicatively.

If the source trap fills an entire coset `-H_j`, then exact shadowing no longer requires checking target divisors one by one. It is enough that the prime generators of the target divisor monoid map into `H_j`.

Thus coset saturation converts an exact residue problem into a prime-factor membership test.

This gives a new general mechanism:

\[
\boxed{
\text{source coset saturation}
+
\text{target prime-factor containment}
+
\text{modulus ancestry}
\Longrightarrow
\text{complete direct shadow}.
}
\]

## 6. Counting consequence from the depth-1 semigroup

Even without using the full asymptotic theory of multiplicative sets, the family already strengthens the supply of explicit composite structural gaps.

For example, every product

\[
k=pq
\]

of primes

\[
p\equiv q\equiv1\pmod3
\]

lies in `S_3` and is globally impossible as a minimal depth.

Classical multiplicative-set methods such as Wirsing or Selberg-Delange predict and prove much denser counting asymptotics for the full semigroup. A publication version should state the sharp asymptotic only after the constant and analytic hypotheses are written carefully.

The exact shadow theorem itself is elementary and independent of those counting refinements.

## 7. Next theorem targets

1. classify all coset-saturated depths `j` satisfying `T_j=-H_j`;
2. the finite search currently suggests `j=1` and the powers of two may be the complete list, but this is **not proved**;
3. derive sharp counting asymptotics for the structural semigroup `S_3`;
4. classify intersections and unions of the saturated-source semigroup families;
5. determine whether their union has positive density among all depth values;
6. use saturated-source shadows as exact deletions before attacking the remaining composite-depth DSC-P problem.
