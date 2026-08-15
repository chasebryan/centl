# A structural-gap family of order X / sqrt(log X)

**Status:** proved analytic consequence of the depth-1 semigroup shadow theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this is a counting theorem for one explicit family of Type A/B structural gaps. It does not determine the density of the full depth-spectrum complement and does not prove the Erdős-Straus conjecture. The analytic input is the classical Selberg-Delange theorem for multiplicative Dirichlet series.

Read with:

- [COSET-SOURCE-SEMIGROUP-SHADOW.md](COSET-SOURCE-SEMIGROUP-SHADOW.md)
- [SPECTRUM-COUNTING-BOUNDS.md](SPECTRUM-COUNTING-BOUNDS.md)
- [PRIME-DEPTH-DENSITY.md](PRIME-DEPTH-DENSITY.md)

## 1. Structural semigroup

Define

\[
\mathcal S_3
=
\{n\ge1:\ p\mid n\Rightarrow p\equiv1\pmod3\}.
\]

The element `1` is included for multiplicative convenience.

The depth-1 semigroup shadow theorem proves that every

\[
n\in\mathcal S_3,
\qquad n>1,
\]

is globally impossible as a minimal Type A/B depth:

\[
\boxed{C_{AB}(x)\ne n}
\]

for every integer `x` for which `C_AB(x)` is defined.

Thus

\[
\boxed{
\mathcal S_3\setminus\{1\}
\subseteq
\mathbb N\setminus\mathcal D_{\mathbb P}.
}
\]

## 2. Dirichlet series

Let

\[
F(s)
=
\sum_{n\in\mathcal S_3}\frac1{n^s}
=
\prod_{p\equiv1\ (3)}(1-p^{-s})^{-1},
\qquad \Re s>1.
\]

Let `chi_{-3}` be the nontrivial real Dirichlet character modulo `3`.

The Euler products for `zeta(s)` and `L(s,chi_{-3})` give the exact identity

\[
\boxed{
F(s)^2
=
\zeta(s)L(s,\chi_{-3})
(1-3^{-s})
\prod_{p\equiv2\ (3)}(1-p^{-2s}).
}
\]

Indeed:

- at `p=1 mod 3`, the product `zeta L` contributes `(1-p^{-s})^{-2}`;
- at `p=2 mod 3`, it contributes `(1-p^{-2s})^{-1}`, cancelled by the displayed correction factor;
- at `p=3`, the zeta factor is cancelled by `1-3^{-s}`.

Therefore

\[
F(s)=\zeta(s)^{1/2}G(s),
\]

where, in a neighborhood of `s=1`,

\[
G(s)
=
\left[
L(s,\chi_{-3})
(1-3^{-s})
\prod_{p\equiv2\ (3)}(1-p^{-2s})
\right]^{1/2}
\]

is analytic and nonzero after choosing the positive real branch at `s=1`.

## 3. Selberg-Delange asymptotic

The classical Selberg-Delange theorem for a Dirichlet series of the form

\[
\zeta(s)^zG(s)
\]

with `z=1/2` gives

\[
\boxed{
S_3(X)
:=
|\mathcal S_3\cap[1,X]|
\sim
\frac{G(1)}{\Gamma(1/2)}
\frac{X}{\sqrt{\log X}}.
}
\]

Since

\[
\Gamma(1/2)=\sqrt\pi
\]

and

\[
L(1,\chi_{-3})=\frac{\pi}{3\sqrt3},
\]

we obtain the explicit constant

\[
\boxed{
C_3
=
\sqrt{
\frac{2}{9\sqrt3}
\prod_{p\equiv2\ (3)}
\left(1-\frac1{p^2}\right)
}.
}
\]

Thus

\[
\boxed{
S_3(X)
\sim
C_3\frac{X}{\sqrt{\log X}}.
}
\]

The Euler product converges absolutely to a positive number, so

\[
C_3>0.
\]

## 4. Structural-gap lower bound

Let

\[
G_{AB}(X)
=
|[1,X]\setminus\mathcal D_{\mathbb P}|.
\]

Because every member of `S_3` except `1` is a global structural gap,

\[
G_{AB}(X)
\ge
S_3(X)-1.
\]

Therefore

\[
\boxed{
G_{AB}(X)
\ge
(C_3+o(1))
\frac{X}{\sqrt{\log X}}.
}
\]

In particular,

\[
\boxed{
G_{AB}(X)
\gg
\frac{X}{\sqrt{\log X}}.
}
\]

The same bound applies to the complement of the hard-class infinite-realization spectrum because these depths are impossible for **every integer**, not only for hard-class primes.

## 5. Comparison with previous gap families

The known structural-gap lower bounds have now progressed through three scales:

### Mersenne power-of-two lattice

\[
G_{AB}(X)\gg\log X.
\]

### Prime-depth ancestry

\[
G_{AB}(X)\gg X/\log X.
\]

### Depth-1 multiplicative semigroup

\[
\boxed{
G_{AB}(X)\gg X/\sqrt{\log X}.
}
\]

Because

\[
\frac{X}{\sqrt{\log X}}
\gg
\frac{X}{\log X},
\]

the multiplicative structural semigroup is asymptotically the strongest explicit deletion family currently proved in the project.

## 6. What this does not establish

Since

\[
\frac{1}{\sqrt{\log X}}\to0,
\]

this family still has natural density zero among all positive depths.

Therefore the theorem does **not** imply that the full depth spectrum has density less than one, nor does it determine whether the total complement has positive density.

It proves something different and concrete: the complement contains an explicit multiplicatively defined family much larger than any previously isolated project family.

## 7. Research interpretation

The result shows that structural gaps are not rare isolated curiosities created only by Mersenne divisibility or prime target depths.

They form a substantial multiplicative population:

\[
\boxed{
\text{prime-factor restriction}
\Longrightarrow
\text{exact source-coset containment}
\Longrightarrow
\text{global impossible depth}.
}
\]

The next natural question is whether the union of semigroup-shadow families from the other coset-saturated sources has a larger asymptotic order than `X/sqrt(log X)`, or even positive density.
