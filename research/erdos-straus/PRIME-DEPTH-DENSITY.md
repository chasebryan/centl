# Almost all prime depth values are structural gaps

**Status:** proved analytic corollary of the prime-depth dichotomy  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this is a density statement about **prime values of the depth parameter** `k`. It does not claim that almost all input primes fail Type A/B, and it does not prove the Erdős-Straus conjecture. The analytic ingredient is the classical Brun/Selberg upper-bound sieve for two linear forms.

Read with:

- [PRIME-DEPTH-DICHOTOMY.md](PRIME-DEPTH-DICHOTOMY.md)
- [PRIME-DEPTH-BACKBONE-PROJECTION.md](PRIME-DEPTH-BACKBONE-PROJECTION.md)
- [SPECTRUM-COUNTING-BOUNDS.md](SPECTRUM-COUNTING-BOUNDS.md)

## 1. Prime-depth realization is a prime-pair condition

The prime-depth dichotomy proves that for prime `k`,

\[
\boxed{
k\text{ is a realizable minimal Type A/B depth}
\iff
4k-1\text{ is prime}.}
\]

Thus the number of realizable prime depth values up to `X` is

\[
R_{\rm prime}(X)
=
\#\{k\le X:k\text{ prime and }4k-1\text{ prime}\}.
\]

This is a two-linear-form prime problem.

## 2. Upper-bound sieve

Consider

\[
F(n)=n(4n-1).
\]

For every odd prime `ell`, the congruence

\[
F(n)\equiv0\pmod\ell
\]

has exactly two residue classes:

\[
n\equiv0\pmod\ell
\]

or

\[
n\equiv4^{-1}\pmod\ell.
\]

They are distinct. The prime `2` contributes one harmless local condition.

This is therefore an admissible dimension-two sieve problem. The classical Brun/Selberg upper-bound sieve gives

\[
\boxed{
R_{\rm prime}(X)
\ll
\frac{X}{(\log X)^2}.
}
\]

No conjecture about the infinitude of the prime pairs `k,4k-1` is used.

## 3. Relative density among prime depths

The total number of prime depth values up to `X` is

\[
\pi(X)
\sim
\frac{X}{\log X}.
\]

Therefore

\[
\frac{R_{\rm prime}(X)}{\pi(X)}
\ll
\frac1{\log X}
\to0.
\]

Hence:

### Theorem

\[
\boxed{
\text{Among prime depth values }k,
\text{ a relative density-one set are structural gaps.}
}
\]

Equivalently,

\[
\boxed{
\#\{k\le X:k\text{ prime and }k\notin\mathcal D_{\mathbb P}\}
=
(1-o(1))\pi(X).
}
\]

Using the prime number theorem,

\[
\boxed{
\#\{k\le X:k\text{ prime and structurally impossible}\}
=
(1-o(1))\frac{X}{\log X}.
}
\]

## 4. Stronger global gap lower bound

Every structurally impossible prime depth is also a gap in the full depth spectrum. Therefore, if

\[
G(X)=|[1,X]\setminus\mathcal D_{\mathbb P}|,
\]

then

\[
G(X)
\ge
\pi(X)-R_{\rm prime}(X).
\]

The sieve estimate gives

\[
\boxed{
G(X)
\ge
(1-o(1))\frac{X}{\log X}.
}
\]

This strengthens the explicit single-residue-family bound

\[
G(X)\ge\left(\frac14+o(1)\right)\frac{X}{\log X}
\]

coming from prime depths `k=4 mod 5`.

Because these prime-depth gaps are impossible for every integer, the same lower bound applies to the complement of the hard-class spectrum.

## 5. Graph interpretation

The prime-depth backbone projection shows that every impossible prime depth is directly shadowed by at least one prime-modulus backbone parent.

Thus the relative-density theorem may be read graphically:

> almost every prime-valued node in the depth graph is not a new spectrum vertex at all; it is a one-edge satellite of an earlier backbone vertex.

Only the sparse prime-pair nodes

\[
k,\quad4k-1\text{ both prime}
\]

remain as genuine prime-depth spectrum vertices.

## 6. What remains unknown

The sieve theorem is an **upper bound**. It does not prove that infinitely many prime depths are realizable.

Infinitude of prime `k` for which `4k-1` is also prime is a separate prime-pair problem not resolved here.

This does not affect the global spectrum's infinitude because the prime-modulus backbone produces infinitely many realized depths `k=(q+1)/4` as `q` ranges over primes `3 mod 4`, and those depth values need not themselves be prime.

## 7. Structural message

The depth spectrum is now known to have a remarkable asymmetry on the prime subsequence:

\[
\boxed{
\begin{array}{c}
\text{all prime depths}\\
\downarrow\\
\text{almost all: composite target modulus}\\
\downarrow\\
\text{directly shadowed by backbone}\\
\downarrow\\
\text{structural gaps}
\end{array}}
\]

The genuinely difficult spectrum classification is therefore overwhelmingly a problem about **composite depth values**.
