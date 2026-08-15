# Quantitative counting in the Type A/B exact-depth spectrum

**Status:** proved corollaries from the prime-modulus backbone, prime-depth dichotomy, and shadow-gap theorems  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not classify the full exact-depth spectrum and does not prove universal Type A/B coverage or Erdős-Straus. It gives rigorous lower bounds for both infinitely realized depths and structurally forbidden depths.

Read with:

- [PRIME-DEPTH-DICHOTOMY.md](PRIME-DEPTH-DICHOTOMY.md)
- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [EXACT-DEPTH-GAP-THEOREMS.md](EXACT-DEPTH-GAP-THEOREMS.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md)

## 1. Counting functions

Let

\[
R(X)
=
\#\{k\le X:k\in\mathcal D_\infty\},
\]

where `D_infty` is the set of depths realized by infinitely many primes.

Let

\[
G(X)
=
\#\{k\le X:k\notin\mathcal D_\exists\},
\]

where `D_exists` is the set of depths realized by at least one prime.

The full functions are unknown. The theorem families now give order-`X/log X` lower bounds for **both** sides.

## 2. Prime-modulus backbone count

Define the prime-modulus backbone

\[
\mathcal B
=
\{k:4k-1\text{ is prime and }>7\}.
\]

The prime-modulus backbone theorem gives

\[
\boxed{
\mathcal B\subseteq\mathcal D_\infty.
}
\]

The map

\[
k\mapsto q=4k-1
\]

is a bijection between backbone depths `k<=X` and primes

\[
q\le4X-1,
\qquad
q\equiv3\pmod4,
\qquad
q>7.
\]

Thus

\[
\boxed{
\#(\mathcal B\cap[1,X])
=
\pi_{3\bmod4}(4X-1)-2.
}
\]

Consequently

\[
\boxed{
R(X)
\ge
\pi_{3\bmod4}(4X-1)-2.
}
\]

The prime number theorem in arithmetic progressions gives

\[
\pi_{3\bmod4}(x)
\sim
\frac{x}{2\log x}.
\]

Therefore

\[
\boxed{
R(X)
\ge
\left(2+o(1)\right)
\frac{X}{\log(4X)}
}
\]

and in particular

\[
\boxed{R(X)\gg X/\log X.}
\]

This is only a lower bound. Composite target moduli contribute many additional realized depths.

## 3. Prime-child gaps give an X/log X structural-gap lower bound

The quotient-5 prime-child theorem says:

\[
\boxed{
k\text{ prime},\quad k\equiv4\pmod5
\Longrightarrow
k\notin\mathcal D_\exists.}
\]

Indeed every such prime depth can be written

\[
k=5j-1
\]

and is fully shadowed by the earlier layer `j`.

Therefore

\[
\boxed{
G(X)
\ge
\pi(X;5,4)-O(1).
}
\]

By the prime number theorem in arithmetic progressions,

\[
\pi(X;5,4)
\sim
\frac14\frac{X}{\log X}.
\]

Hence

\[
\boxed{
G(X)
\ge
\left(\frac14+o(1)\right)
\frac{X}{\log X}.
}
\]

In particular,

\[
\boxed{G(X)\gg X/\log X.}
\]

This supersedes the earlier square-root lower bound as the strongest currently recorded unconditional gap count from one explicit shadow family.

## 4. Prime-depth dichotomy gives the exact prime slice

For every prime-valued depth `k`, [PRIME-DEPTH-DICHOTOMY.md](PRIME-DEPTH-DICHOTOMY.md) proves

\[
\boxed{
k\in\mathcal D_\infty
\iff
4k-1\text{ is prime},}
\]

and if `4k-1` is composite then

\[
\boxed{k\notin\mathcal D_\exists.}
\]

Thus the prime-depth subsequence contains no intermediate finitely-realized case.

The quotient-5 count above uses only one easy subfamily of the composite-modulus side. The complete dichotomy says every prime `k` with composite `4k-1` is actually a structural gap.

Any sharper analytic estimate for prime pairs

\[
k,\quad4k-1
\]

would immediately sharpen the structural-gap count among prime depth indices, but no such extra estimate is required for the present `X/log X` theorem.

## 5. A separate square-root gap family remains explicit

The first reciprocity-gap sequence is

\[
A_n=3n^2+3n+1,
\qquad n\ge1.
\]

Every `A_n` is a structural gap, and

\[
A_n\le X
\iff
n\le
\frac{\sqrt{12X-3}-3}{6}.
\]

Hence, independently of prime-depth arguments,

\[
\boxed{
G(X)
\ge
\left\lfloor
\frac{\sqrt{12X-3}-3}{6}
\right\rfloor
}
\]

for `X>=7`.

This family is no longer the strongest counting bound, but remains valuable because it consists of explicit polynomial depth gaps rather than a prime residue class.

## 6. Quantitative two-sided spectrum theorem

The current exact theorem package gives simultaneously

\[
\boxed{
R(X)\gg\frac{X}{\log X}
}
\]

and

\[
\boxed{
G(X)\gg\frac{X}{\log X}.
}
\]

More explicitly, the proved mechanisms give

\[
R(X)
\ge
\pi_{3\bmod4}(4X-1)-2
\sim
\frac{2X}{\log(4X)},
\]

while

\[
G(X)
\ge
\pi(X;5,4)-O(1)
\sim
\frac{X}{4\log X}.
\]

These are lower bounds on opposite sides of the same minimal-depth spectrum.

Thus both infinite-arrival nodes and permanent structural gaps occur at least at prime-scale frequency among depth indices.

## 7. Interpretation

The `C_AB` depth line is not a nearly full set with a few exotic holes, nor a thin list of isolated arrivals.

Already-proved arithmetic mechanisms force substantial populations on both sides:

\[
\boxed{
\text{many infinitely realized depths}
+
\text{many impossible depths}.
}
\]

The remaining problem is to classify the composite-depth region not already decided by ancestry, quotient, or shadow theorems.

## 8. Paper-level use

The quantitative spectrum can now be summarized as:

1. the realized spectrum is infinite and grows at least like `X/log X`;
2. the structural-gap set is infinite and also grows at least like `X/log X`;
3. prime depths are completely classified by primality of `4k-1`;
4. explicit polynomial and Mersenne shadow families give additional deterministic gaps;
5. universal DSC-P would classify every remaining directly novel composite depth as infinitely prime-realizable.

## 9. Novelty boundary

The prime number theorem in arithmetic progressions and related analytic counting are classical. The candidate contribution is their application to the Type-A/B minimal-depth spectrum after the prime-child and prime-depth shadow theorems identify explicit realized and forbidden depth families.

No claim is made that the analytic counting theorems themselves are new.
