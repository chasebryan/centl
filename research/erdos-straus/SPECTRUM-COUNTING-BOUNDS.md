# Counting bounds for the Type A/B minimal-depth spectrum

**Status:** proved quantitative synthesis theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** these bounds concern the López Type A/B minimal-depth spectrum. They do not prove universal Type A/B coverage or the Erdős-Straus conjecture. The analytic inputs are classical prime-number theorems; the new project-specific input is the prime-modulus backbone and Mersenne shadow lattice.

Read with:

- [SPECTRUM-INFINITE-COINFINITE.md](SPECTRUM-INFINITE-COINFINITE.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md)

## 1. Counting functions

Let

\[
D_H(X)=|\mathcal D_H\cap[1,X]|,
\]

where `D_H` is the hard-class spectrum of depths realized by infinitely many primes.

Let

\[
G(X)=|[1,X]\setminus\mathcal D_{\mathbb P}|,
\]

where `D_P` is the set of minimal Type A/B depths attained by at least one prime.

Since every depth impossible for all integers is absent from every prime spectrum, any global structural-gap family gives a lower bound for `G(X)` and for the complement of `D_H`.

## 2. Lower bound for realized depths

The prime-modulus backbone theorem states that if

\[
q=4k-1
\]

is prime with `q>7`, then depth `k` is realized by infinitely many primes, even in the hard class `1 mod 840`.

Therefore every prime

\[
q\equiv3\pmod4,
\qquad q\le4X-1,
\]

apart from finitely many initial exceptions, contributes a distinct depth

\[
k=(q+1)/4\le X
\]

to `D_H`.

Hence

\[
\boxed{
D_H(X)
\ge
\pi(4X-1;4,3)-O(1),
}
\]

where `pi(Y;4,3)` counts primes `q<=Y` with `q=3 mod 4`.

By the prime number theorem for arithmetic progressions,

\[
\pi(Y;4,3)
\sim
\frac{1}{2}\frac{Y}{\log Y}.
\]

Putting `Y=4X` gives

\[
\boxed{
D_H(X)
\ge
(2+o(1))\frac{X}{\log(4X)}.
}
\]

In particular,

\[
\boxed{D_H(X)\gg X/\log X.}
\]

The same lower bound applies to `D_P(X)` because `D_H` is a subset of the prime spectrum.

## 3. Lower bound for structural gaps

The Mersenne shadow lattice proves that, for every exponent `b>=3` with `b+2` composite,

\[
\boxed{2^b\notin\mathcal D_{\mathbb P}.}
\]

Let

\[
B=\lfloor\log_2 X\rfloor.
\]

Then every exponent

\[
3\le b\le B
\]

with composite `b+2` supplies a distinct structural gap `2^b<=X`.

Therefore

\[
G(X)
\ge
\#\{3\le b\le B:b+2\text{ composite}\}.
\]

The only exponents not killed by this particular family are those with `b+2` prime, up to finitely many initial cases. Hence

\[
\boxed{
G(X)
\ge
B-\pi(B+2)-O(1).
}
\]

By the prime number theorem,

\[
\pi(B+2)=o(B),
\]

so

\[
\boxed{
G(X)
\ge
(1-o(1))\log_2 X.
}
\]

In particular,

\[
\boxed{G(X)\gg\log X.}
\]

These are **global structural gaps**, so the complement of the hard-class spectrum satisfies the same logarithmic lower bound.

## 4. Quantitative spectrum theorem

Combining the two constructions gives the unconditional pair

\[
\boxed{
D_H(X)\gg\frac{X}{\log X},
\qquad
|[1,X]\setminus\mathcal D_H|\gg\log X.
}
\]

Likewise for the prime spectrum,

\[
\boxed{
D_{\mathbb P}(X)\gg\frac{X}{\log X},
\qquad
G(X)\gg\log X.
}
\]

Thus the known realized spectrum is already quantitatively large, while the known structural complement also grows without bound.

## 5. What these bounds do not say

They do **not** determine the natural density of the full spectrum.

The lower bound `X/log X` for realized depths is compatible with density zero or positive density.

The logarithmic structural-gap bound is far too small to show that the complement has positive density among all depths. The Mersenne family is intentionally sparse in `k`, even though it kills a density-one set of exponents within the power-of-two subsequence.

So the central counting problem remains open:

\[
\boxed{
D(X)=|\mathcal D\cap[1,X]|\quad\text{and}\quad X-D(X).
}
\]

## 6. Research significance

The spectrum now has three proven scales:

1. **individual realization:** exact Dirichlet progressions at specific depths;
2. **macroscopic support:** at least `X/log X` realized depths up to `X` from the prime-modulus backbone;
3. **permanent holes:** at least logarithmically many global structural gaps from the Mersenne lattice.

The next major objective is to find additional infinite shadow families dense enough to improve the structural-gap lower bound, while Direct-Shadow Completeness would simultaneously enlarge the provably realized side.
