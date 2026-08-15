# Universal square-lift shadow classification

**Status:** proved classification theorem inside the Type A/B minimal-depth program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. It completely classifies one natural infinite shadow mechanism: full shadowing of every odd square lift of a fixed Type A/B modulus.

Read with:

- [RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md)
- [SQUARE-LIFT-TOWERS.md](SQUARE-LIFT-TOWERS.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)

## 1. Universal square-lift shadow property

Fix a Type A/B depth `j` and put

\[
m=4j-1.
\]

For every positive odd integer `c`, define

\[
K_c=\frac{mc^2+1}{4},
\qquad
4K_c-1=mc^2.
\]

Say that `j` has the **universal square-lift shadow property** if

\[
\boxed{
T_{K_c}\bmod m\subseteq T_j
\quad\text{for every positive odd }c.
}
\]

For `c>1`, this says every later layer in the entire square-lift tower is directly shadowed by the base.

## 2. Classification theorem

### Theorem

For a Type A/B depth `j`, the following are equivalent:

1. `j` has the universal square-lift shadow property;
2. the base trap set is the complete Jacobi-negative half of the unit group,
   \[
   T_j=\left\{u:\left(\frac u{4j-1}\right)=-1\right\};
   \]
3. `j` is one of
   \[
   \boxed{1,2,4.}
   \]

Therefore

\[
\boxed{
\text{universal odd square-lift shadow bases}
=\{1,2,4\}.
}
\]

## 3. Proof that Jacobi saturation implies universal shadowing

This direction is the reciprocity tower theorem already proved in [RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md).

If the base is Jacobi-saturated, then for every divisor `e|K_c`, quadratic reciprocity gives

\[
\left(\frac e m\right)=+1.
\]

Hence both lifted trap residues

\[
-e,
\qquad
-4e
\]

have Jacobi sign `-1 mod m` and therefore belong to the saturated base trap set.

Thus

\[
T_{K_c}\bmod m\subseteq T_j
\]

for every odd `c`.

## 4. Converse: a non-saturated base always has an escaping square lift

Now assume the base is **not** Jacobi-saturated.

The quadratic trap theorem still gives

\[
T_j\subseteq N_m^-,
\]

where

\[
N_m^-=
\left\{u:\left(\frac u m\right)=-1\right\}.
\]

Since the inclusion is strict, choose

\[
\boxed{v\in N_m^-\setminus T_j.}
\]

Set

\[
\boxed{u=-v\pmod m.}
\]

Because

\[
\left(\frac{-1}{m}\right)=-1,
\]

we have

\[
\left(\frac u m\right)
=
\left(\frac{-1}{m}\right)
\left(\frac v m\right)
=( -1)( -1)=+1.
\]

Thus `u` is a Jacobi-positive unit modulo `m`.

### Choose a prime in the positive class

By Dirichlet's theorem, there exist infinitely many primes `ell` satisfying

\[
\boxed{\ell\equiv u\pmod m.}
\]

Choose such an odd prime.

Then

\[
\left(\frac\ell m\right)=+1.
\]

Since `m=3 mod 4`, quadratic reciprocity gives

\[
\boxed{
\left(\frac{-m}{\ell}\right)
=
\left(\frac\ell m\right)
=+1.
}
\]

Therefore `-m` is a quadratic residue modulo `ell`. Equivalently, there exists `c_0` such that

\[
\boxed{
c_0^2\equiv-m^{-1}\pmod\ell.}
\]

Choose an **odd** positive integer `c` in this residue class. This is always possible because `ell` is odd: adding `ell` flips parity without changing the residue class.

Now

\[
mc^2+1\equiv0\pmod\ell,
\]

so

\[
\ell\mid K_c=\frac{mc^2+1}{4}.
\]

Therefore `ell` is a divisor of the lifted depth and

\[
-\ell\in T_{K_c}.
\]

Reducing to the base modulus gives

\[
-\ell
\equiv
-u
\equiv
v
\pmod m.
\]

But `v` was chosen outside `T_j`. Hence

\[
T_{K_c}\bmod m\not\subseteq T_j.
\]

So the square lift `K_c` escapes the base shadow.

This proves:

\[
\boxed{
\text{universal square-lift shadow}
\Longrightarrow
\text{Jacobi saturation}.
}

## 5. Finish the classification

[RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md) proves the exact Jacobi-saturation classification

\[
\boxed{
T_j=N_{4j-1}^-
\iff
j\in\{1,2,4\}.
}
\]

Combining both directions gives

\[
\boxed{
\forall\text{ odd }c,
\ T_{((4j-1)c^2+1)/4}\bmod(4j-1)\subseteq T_j
\iff
j\in\{1,2,4\}.
}
\]

QED.

## 6. Constructive counter-lift certificate for every other base

The proof is constructive once one chooses a missing Jacobi-negative residue `v`.

For every

\[
j\notin\{1,2,4\},
\]

one can generate a finite certificate of failure of universal square-lift shadowing:

1. find
   \[
   v\in N_m^-\setminus T_j;
   \]
2. set `u=-v mod m`;
3. find a prime
   \[
   \ell\equiv u\pmod m;
   \]
4. solve
   \[
   c^2\equiv-m^{-1}\pmod\ell;
   \]
5. choose `c` odd;
6. form
   \[
   K=(mc^2+1)/4;
   \]
7. verify
   \[
   \ell\mid K;
   \]
8. verify the lifted trap residue
   \[
   -\ell\pmod m
   
   \]
   lies outside `T_j`.

This gives an explicit later layer in the base's square-lift tower that is **not** shadowed by the base.

## 7. Why the classification matters

Before the converse, the three towers based at `1`, `2`, and `4` were infinite sufficient shadow families.

The converse upgrades the statement:

> these are the **only** bases whose entire odd square-lift tower can collapse under one base layer.

Therefore any universal theorem for the many other square-lift shadows visible in the finite shadow graph must use additional information beyond the scalar Jacobi character.

That pushes the theory naturally toward:

- full local quadratic signatures;
- multiplicative quotient classes;
- exact two-box divisor geometry;
- higher `p`-adic structure.

The hierarchy is not optional. The classification proves the scalar quadratic mechanism has been exhausted completely.

## 8. Relationship to the observed finite shadow map

The finite direct-shadow graph contains many square-lift ancestry edges where the base is not `1`, `2`, or `4`.

This theorem says those cannot arise from a base that shadows **every** odd square lift merely because of Jacobi saturation.

They must be selective:

\[
\boxed{
\text{specific lift arithmetic}
+
\text{finer quotient/residue structure}
}
\]

is responsible.

This isolates the next classification problem very sharply.

## 9. New theorem target

Classify, for a general base `j`, the set

\[
\boxed{
\mathcal C_j
=
\left\{
c\text{ odd}:
T_{K_c}\bmod(4j-1)\subseteq T_j
\right\}.
}
\]

The present theorem gives the complete universal case:

\[
\boxed{
\mathcal C_j=\{1,3,5,\ldots\}
\iff
j\in\{1,2,4\}.
}
\]

For every other base, `C_j` is a proper subset of the odd integers.

The next diamond question is whether `C_j` itself has a finite congruence, multiplicative, or automata-like description controlled by the quotient `Gamma_j` and the two-box trap geometry.

## 10. Novelty boundary

Dirichlet's theorem and quadratic reciprocity are classical. López Type A/B congruences are prior art.

The candidate contribution is the **complete classification of universal Type-A/B square-lift shadow bases inside the minimal-depth/shadow framework**, together with the constructive counter-lift mechanism for every non-saturated base.

Targeted arXiv searches on 2026-08-15 did not locate this exact formulation. That negative search does not establish publication priority.
