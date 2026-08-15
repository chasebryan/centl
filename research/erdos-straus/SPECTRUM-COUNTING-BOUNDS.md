# Counting bounds for the Type A/B minimal-depth spectrum

**Status:** proved quantitative synthesis theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** these bounds concern the López Type A/B minimal-depth spectrum. They do not prove universal Type A/B coverage or the Erdős-Straus conjecture. The analytic inputs are classical prime-number theorems in arithmetic progressions; the project-specific inputs are the prime-modulus backbone, prime-depth dichotomy, and Mersenne shadow lattice.

Read with:

- [SPECTRUM-INFINITE-COINFINITE.md](SPECTRUM-INFINITE-COINFINITE.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [PRIME-DEPTH-DICHOTOMY.md](PRIME-DEPTH-DICHOTOMY.md)
- [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md)

## 1. Counting functions

Let

\[
D_H(X)=|\mathcal D_H\cap[1,X]|,
\]

where `D_H` is the hard-class spectrum of depths realized by infinitely many primes.

Let

\[
D_{\mathbb P}(X)=|\mathcal D_{\mathbb P}\cap[1,X]|,
\]

and

\[
G(X)=|[1,X]\setminus\mathcal D_{\mathbb P}|.
\]

Every depth impossible for all integers is absent from every prime spectrum, so a global structural-gap family also lower-bounds the complement of `D_H`.

## 2. Lower bound for realized depths

If

\[
q=4k-1
\]

is prime with `q>7`, the prime-modulus backbone gives infinitely many hard-class primes of exact depth `k`.

Therefore every prime

\[
q\equiv3\pmod4,
\qquad q\le4X-1,
\]

apart from finitely many initial cases, contributes a distinct depth

\[
k=(q+1)/4\le X.
\]

Hence

\[
\boxed{
D_H(X)
\ge
\pi(4X-1;4,3)-O(1).
}
\]

By the prime number theorem for arithmetic progressions,

\[
\pi(Y;4,3)
\sim
\frac12\frac{Y}{\log Y},
\]

so

\[
\boxed{
D_H(X)
\ge
(2+o(1))\frac{X}{\log(4X)}
\gg
\frac{X}{\log X}.
}
\]

The same lower bound applies to `D_P(X)`.

## 3. Macroscopic lower bound for structural gaps

The prime-depth dichotomy gives a much denser deletion family than the original Mersenne construction.

Every prime depth

\[
k\equiv4\pmod5
\]

satisfies

\[
5\mid4k-1.
\]

Writing

\[
k=5j-1
\]

gives

\[
4k-1=5(4j-1),
\]

and because `k` is prime the complete target trap layer reduces into the earlier layer `j`. Thus every such prime `k` is a global structural gap:

\[
\boxed{k\notin\mathcal D_{\mathbb P}.}
\]

Therefore

\[
\boxed{
G(X)
\ge
\pi(X;5,4)-O(1).
}
\]

The prime number theorem in arithmetic progressions gives

\[
\pi(X;5,4)
\sim
\frac14\frac{X}{\log X},
\]

hence

\[
\boxed{
G(X)
\ge
\left(\frac14+o(1)\right)\frac{X}{\log X}.
}
\]

In particular,

\[
\boxed{G(X)\gg X/\log X.}
\]

Because these depths are impossible for **every integer**, the same bound applies to the complement of the hard-class spectrum:

\[
\boxed{
|[1,X]\setminus\mathcal D_H|
\gg X/\log X.
}
\]

## 4. General ancestry residue families

The `mod 5` family is only the first member of an infinite collection.

Fix `s>=1` and put

\[
A=4s+1.
\]

Every prime depth satisfying

\[
\boxed{k\equiv-s\pmod A}
\]

has

\[
A\mid4k-1
\]

and is directly shadowed by

\[
j=(k+s)/A<k.
\]

Since

\[
\gcd(s,A)=1,
\]

Dirichlet gives infinitely many prime depths in each such shadow family.

The families overlap, so their densities cannot simply be added. The single `s=1` family is enough for the unconditional `X/log X` lower bound above.

## 5. Mersenne gaps remain structurally distinct

The power-of-two Mersenne lattice still supplies a different kind of deletion:

\[
2^b\notin\mathcal D_{\mathbb P}
\]

whenever `b>=3` and `b+2` is composite.

This gives

\[
G(X)
\ge
(1-o(1))\log_2 X
\]

from the binary subsequence alone.

That bound is now numerically weaker than the prime-depth `X/log X` bound, but it remains conceptually important because it comes from exact multiplicative-coset saturation rather than prime-target divisor sparsity.

## 6. Quantitative spectrum theorem

We now have unconditional lower bounds of the same broad order on both known sides:

\[
\boxed{
D_H(X)\gg\frac{X}{\log X},
\qquad
|[1,X]\setminus\mathcal D_H|
\gg\frac{X}{\log X}.
}
\]

Likewise

\[
\boxed{
D_{\mathbb P}(X)\gg\frac{X}{\log X},
\qquad
G(X)\gg\frac{X}{\log X}.
}
\]

More explicitly, the two current constructions give

\[
D_H(X)
\ge
\pi(4X-1;4,3)-O(1)
\]

and

\[
G(X)
\ge
\pi(X;5,4)-O(1).
\]

## 7. What these bounds do not say

They do **not** determine the natural density of the full spectrum or its complement.

Both `X/log X` lower bounds are compatible with density zero.

The exact prime-depth dichotomy also shows that understanding the spectrum on prime values of `k` is equivalent to understanding prime pairs

\[
k,\ 4k-1,
\]

on the realizable side. No infinitude of such prime pairs is assumed or needed for the global spectrum lower bound, because the prime-modulus backbone allows composite depths `k` as well.

The central counting problem remains

\[
\boxed{
D(X)=|\mathcal D\cap[1,X]|,
\qquad
X-D(X).
}
\]

## 8. Research significance

The spectrum now has four proven quantitative structures:

1. exact individual Dirichlet realization certificates;
2. at least `X/log X` realized depths from the prime-modulus backbone;
3. at least `X/log X` global structural gaps from one prime-depth ancestry family alone;
4. an independent infinite Mersenne deletion lattice dominating the power-of-two exponent subsequence.

The next counting objective is to understand the union of the prime-depth ancestry families and to find comparable infinite deletion mechanisms on composite depths.
