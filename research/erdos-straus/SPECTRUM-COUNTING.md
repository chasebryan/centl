# Quantitative counting in the Type A/B exact-depth spectrum

**Status:** proved corollaries from the prime-modulus backbone and reciprocity-gap theorem  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not classify the full exact-depth spectrum and does not prove universal Type A/B coverage or Erdős-Straus. It gives rigorous lower bounds for both infinitely realized depths and structurally forbidden depths.

Read with:

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

The full functions are unknown. The theorem families already give nontrivial lower bounds for both.

## 2. A square-root lower bound for structural gaps

The first reciprocity-gap family is

\[
A_n=3n^2+3n+1,
\qquad n\ge1.
\]

Every `A_n` is a structural gap.

The sequence is strictly increasing. The inequality

\[
3n^2+3n+1\le X
\]

is equivalent to

\[
n\le
\frac{\sqrt{12X-3}-3}{6}.
\]

Therefore, for `X>=7`,

\[
\boxed{
G(X)
\ge
\left\lfloor
\frac{\sqrt{12X-3}-3}{6}
\right\rfloor.
}
\]

In particular,

\[
\boxed{
G(X)=\Omega(\sqrt X).
}
\]

More explicitly, this one shadow family alone contributes

\[
\frac1{\sqrt3}\sqrt X+O(1)
\]

permanent exact-depth gaps up to `X`.

The other two reciprocity families and the dyadic shadow gaps can only increase `G(X)`, subject to overlaps.

## 3. Prime-modulus backbone count

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

Thus exactly

\[
\boxed{
\#(\mathcal B\cap[1,X])
=
\pi_{3\bmod4}(4X-1)-2
}
\]

for `X>=2`, where the subtraction removes `q=3,7` from this particular backbone statement.

Consequently

\[
\boxed{
R(X)
\ge
\pi_{3\bmod4}(4X-1)-2.
}
\]

## 4. Asymptotic realized-depth lower bound

The prime number theorem in arithmetic progressions gives

\[
\pi_{3\bmod4}(x)
\sim
\frac12\operatorname{Li}(x)
\sim
\frac{x}{2\log x}.
\]

Therefore the prime-modulus backbone itself satisfies

\[
\boxed{
\#(\mathcal B\cap[1,X])
\sim
\frac{2X}{\log(4X)}.
}
\]

Hence

\[
\boxed{
R(X)
\ge
\left(2+o(1)\right)
\frac{X}{\log(4X)}.
}
\]

This is only a lower bound on the full infinitely-realized spectrum. Composite target moduli contribute many additional exact-depth nodes.

## 5. Quantitative two-sided structure

The current theorem families therefore imply simultaneously

\[
\boxed{
R(X)
\gg
\frac{X}{\log X}
}
\]

and

\[
\boxed{
G(X)
\gg
\sqrt X.
}
\]

These bounds concern different sides of the spectrum:

- `R(X)` counts depths known to support infinitely many prime first hits;
- `G(X)` counts depths known to support no prime first hit at all.

Thus neither side is a finite exceptional phenomenon.

## 6. Interpretation

The exact-depth line is not converging toward a simple eventual regime in which every sufficiently large depth is realized.

Instead, already-proved algebraic mechanisms force an interleaving of:

\[
\boxed{
\text{many infinite-arrival depths}
+
\text{many permanent structural gaps}.
}
\]

The backbone contributes on the order of `X/log X` proved infinite-realization depths up to `X`, while just one reciprocity tower forces on the order of `sqrt(X)` permanent gaps.

The unclassified portion is where composite shadow/tower geometry remains to be understood.

## 7. Paper-level use

These counting statements are useful because they distinguish the `C_AB` spectrum from a mere finite record table.

A prospective structural theorem can now discuss:

1. explicit exact-depth arrivals;
2. explicit exact-depth exclusions;
3. quantitative growth of both;
4. shadow mechanisms explaining the exclusions;
5. the remaining composite/tower core.

## 8. Novelty boundary

The prime number theorem in arithmetic progressions and the underlying classical analytic number theory are prior mathematics. The candidate contribution is the application to the new Type-A/B minimal-depth spectrum together with the explicit reciprocity shadow-gap families.

No claim is made that the analytic counting theorems themselves are new.
