# The Type A/B minimal-depth spectrum is infinite and co-infinite

**Status:** proved synthesis theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem concerns the minimal depth spectrum inside López Type A/B congruence solutions. It does not prove that every prime has finite `C_AB`, and it does not prove the Erdős-Straus conjecture. Literature priority for this spectrum formulation remains under review.

Read with:

- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md)
- [SURVIVOR-DENSITY.md](SURVIVOR-DENSITY.md)

## 1. Spectrum

Define the prime minimal-depth spectrum

\[
\mathcal D_{\mathbb P}
=
\{k\ge1:\exists\text{ prime }p\text{ with }C_{AB}(p)=k\}.
\]

Define also the hard-class infinite-realization spectrum

\[
\mathcal D_H
=
\{k:\text{infinitely many primes }p\equiv h\pmod{840}
\text{ for some }h\in H\text{ satisfy }C_{AB}(p)=k\}.
\]

The prime-modulus backbone and the Mersenne shadow lattice give opposite infinite families.

## 2. Infinite realized side

Let

\[
q=4k-1
\]

be prime with `q>7`.

The prime-modulus backbone theorem gives a target Type A/B candidate at depth `k` whose target modulus is a new CRT coordinate relative to all previous layers. Finite congruence avoidance plus Dirichlet then gives infinitely many primes, even in the hard class

\[
p\equiv1\pmod{840},
\]

with

\[
\boxed{C_{AB}(p)=k.}
\]

There are infinitely many primes

\[
q\equiv3\pmod4,
\]

so there are infinitely many such depths

\[
k=(q+1)/4.
\]

Therefore

\[
\boxed{\mathcal D_H\text{ is infinite}.}
\]

In particular

\[
\boxed{\mathcal D_{\mathbb P}\text{ is infinite}.}
\]

## 3. Infinite impossible side

The Mersenne shadow theorem gives, for `a,b>=1`,

\[
a+2\mid b+2,
\quad a<b
\Longrightarrow
T_{2^b}\text{ is completely shadowed by }T_{2^a}.
\]

Hence

\[
\boxed{C_{AB}(n)\ne2^b}
\]

for every integer `n` whenever such a proper divisor relation exists.

In particular, for every `r>=2`, take

\[
b=3r-2.
\]

Then

\[
3\mid b+2,
\]

so depth

\[
\boxed{2^{3r-2}}
\]

is completely shadowed by depth `2`.

Thus there are infinitely many positive integers `k` that are not a minimal Type A/B depth for **any** integer, and therefore certainly not for any prime.

Hence

\[
\boxed{\mathbb N\setminus\mathcal D_{\mathbb P}\text{ is infinite}.}
\]

The same global gaps are absent from the hard-class spectrum, so

\[
\boxed{\mathbb N\setminus\mathcal D_H\text{ is infinite}.}
\]

## 4. Spectrum theorem

Combining the two sides:

### Theorem

The Type A/B minimal-depth spectrum is infinite and co-infinite:

\[
\boxed{
|\mathcal D_{\mathbb P}|=\infty,
\qquad
|\mathbb N\setminus\mathcal D_{\mathbb P}|=\infty.
}
\]

Moreover the hard-class infinite-realization spectrum is also infinite and co-infinite:

\[
\boxed{
|\mathcal D_H|=\infty,
\qquad
|\mathbb N\setminus\mathcal D_H|=\infty.
}
\]

## 5. Stronger binary subsequence statement

Inside the subsequence of depths

\[
k=2^b,
\]

the Mersenne theorem proves that every `b>=3` with composite `b+2` is structurally impossible.

Only `b+2` prime can escape that particular obstruction.

Therefore, if

\[
E(B)=\#\{b\le B:2^b\text{ survives the Mersenne obstruction}\},
\]

then

\[
E(B)\le\pi(B+2)+O(1),
\]

and hence

\[
\boxed{E(B)/B\to0.}
\]

So the complement of the spectrum occupies a density-one set of exponents inside this explicit sparse subsequence.

## 6. Conceptual meaning

The minimal Type A/B depth parameter is therefore not simply an unbounded complexity statistic whose every sufficiently large value eventually appears.

Its spectrum has two permanent arithmetic forces:

1. **arrival:** independent prime-modulus coordinates create infinitely many realizable exact depths;
2. **deletion:** modulus ancestry and exact trap containment create infinitely many structurally forbidden depths.

Thus the object is naturally a genuine arithmetic spectrum with both infinite support and infinite holes.

## 7. Paper-level consequence

The depth program can now state a clean unconditional theorem package:

\[
\boxed{
\begin{array}{c}
C_{AB}\text{ has unbounded finite values};\\
\text{infinitely many depths are infinitely prime-realizable};\\
\text{infinitely many depths are structurally impossible};\\
\text{therefore the minimal-depth spectrum is infinite and co-infinite.}
\end{array}
}
\]

This is independent of whether López's universal Type A/B coverage conjecture is ultimately true.

Even if every prime has finite `C_AB`, the **set of values taken by `C_AB` still has an infinite deterministic gap structure**.

## 8. Next questions

- What is the density of the spectrum among all positive depths?
- Can additional infinite shadow lattices enlarge the known complement?
- Can every non-shadowed depth be shown to lie in the spectrum under universal DSC-P?
- What is the asymptotic counting function
  \[
  D(X)=|\mathcal D_{\mathbb P}\cap[1,X]|?
  \]
- How does the spectrum decompose into prime-modulus backbone values, composite-rescue values, and structural gaps?
