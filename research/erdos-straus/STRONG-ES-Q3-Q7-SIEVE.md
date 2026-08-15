# Dimension-two sieve from the exact q=3 and q=7 strong/Type-II filters

**Status:** proved application of a classical upper-bound sieve  
**Date:** 2026-08-15  
**Depends on:** `FAB-HARD-FIRST-FILTERS.md`, `STRONG-ES-Q7-EXACT-FILTER.md`, `STRONG-ES-FINITE-SHIFT-CORRIDOR.md`  
**Imported classical tools:** Selberg/Brun upper-bound sieve, prime number theorem in arithmetic progressions, bounded prime reciprocal sums for nonprincipal Dirichlet characters  
**Claim boundary:** the sieve method and almost-all Erdős--Straus philosophy are classical; Vaughan and later Elsholtz prove much stronger exceptional-set estimates using larger parametric families. This note records the specific consequence of the exact `q=3,7` Type-II filters. It does not prove universal strong/Type-II coverage.

---

## 1. The two exact miss conditions

Let `p` be Mordell-hard and put

\[
\boxed{A=\frac{p+3}{4}.}
\]

Then

\[
\frac{p+7}{4}=A+1.
\]

The exact `q=3` theorem gives

\[
\boxed{
q=3\text{ misses}
\iff
\text{every prime divisor of }A\text{ is }1\pmod3.}
\]

The exact `q=7` theorem gives

\[
\boxed{
q=7\text{ misses}
\iff
\text{every prime divisor of }A+1\text{ is a quadratic residue mod }7.}
\]

Thus a simultaneous survivor must satisfy both splitting restrictions on two consecutive integers.

---

## 2. Convert the conditions into forbidden sieve residues

For every prime `ell>7`, define three possible forbidden residues for the variable `A`.

### Primality of p = 4A-3

If

\[
A\equiv 3\cdot4^{-1}\pmod\ell,
\]

then

\[
4A-3\equiv0\pmod\ell.
\]

Except for the single possibility `p=ell`, such an `A` cannot correspond to a prime `p`.

Thus primality contributes one forbidden residue for every sieve prime.

### q = 3 miss

If

\[
\ell\equiv2\pmod3,
\]

then a simultaneous survivor cannot satisfy

\[
A\equiv0\pmod\ell,
\]

because such an `ell` is forbidden as a prime divisor of `A`.

### q = 7 miss

Let

\[
\chi_7(\ell)=\left(\frac\ell7\right).
\]

If

\[
\chi_7(\ell)=-1,
\]

then a simultaneous survivor cannot satisfy

\[
A\equiv-1\pmod\ell,
\]

because `ell` would be a quadratic-nonresidue prime divisor of `A+1`.

For every `ell>7`, the three candidate residues

\[
3\cdot4^{-1},\qquad0,\qquad-1
\]

are pairwise distinct whenever their corresponding conditions are active.

---

## 3. Local sieve dimension

For primes `ell>7`, let

\[
\rho(\ell)
=
1
+
\mathbf1_{\ell\equiv2\ (3)}
+
\mathbf1_{(\ell/7)=-1}.
\]

This is the number of distinct forbidden residue classes modulo `ell`.

Write `chi_3` for the nonprincipal quadratic character modulo `3`. Away from the finitely many ramified primes,

\[
\mathbf1_{\ell\equiv2\ (3)}
=
\frac{1-\chi_3(\ell)}2,
\]

and

\[
\mathbf1_{(\ell/7)=-1}
=
\frac{1-\chi_7(\ell)}2.
\]

Therefore

\[
\boxed{
\rho(\ell)
=
2-rac{\chi_3(\ell)+\chi_7(\ell)}2.}
\]

Summing over primes and using the boundedness of prime reciprocal sums of nonprincipal Dirichlet characters gives

\[
\boxed{
\sum_{\ell<z}\frac{\rho(\ell)}\ell
=
2\log\log z+O(1).}
\]

Thus the simultaneous primality-plus-two-filter problem has sieve dimension

\[
\boxed{\kappa=2.}
\]

---

## 4. Selberg upper bound

Apply the standard upper-bound Selberg sieve to the interval

\[
1\le A\le Y
\]

with the residue sets above.

The local density product satisfies

\[
\prod_{\ell<z}
\left(1-\frac{\rho(\ell)}\ell\right)
\asymp
\frac1{(\log z)^2}.
\]

Taking a fixed positive power of `Y` as the sieve level gives

\[
\boxed{
\#\left\{
A\le Y:
\begin{array}{l}
4A-3\text{ prime},\\
q=3\text{ misses},\\
q=7\text{ misses}
\end{array}
\right\}
\ll
\frac{Y}{(\log Y)^2}.}
\]

The finitely many small sieve primes and the exceptional equality `4A-3=ell` contribute only lower-order terms.

---

## 5. Prime formulation

Since

\[
p=4A-3,
\]

the same estimate becomes

\[
\boxed{
\#\{p\le X:\ p\text{ prime and both }q=3,7\text{ Type-II shifts miss}\}
\ll
\frac{X}{(\log X)^2}.}
\]

Restricting further to the six Mordell-hard residue classes can only decrease the count.

Thus the exact `q=3` and `q=7` Type-II families alone leave at most a dimension-two sifted prime set.

---

## 6. Relative prime density

The prime number theorem gives

\[
\pi(X)\sim\frac{X}{\log X}.
\]

Hence

\[
\frac{
\#\{p\le X:\ q=3,7\text{ both miss}\}
}{\pi(X)}
\ll
\frac1{\log X}
\longrightarrow0.
\]

Therefore:

### Theorem — two fixed Type-II shifts solve a relative density-one set of primes

\[
\boxed{
\text{The union of the }q=3\text{ and }q=7\text{ Type-II families captures a relative density-one set of primes.}}
\]

This is a statement about those two explicit strong/Type-II families, not about a universal proof.

---

## 7. Why the sieve dimension is exactly two

The local arithmetic has a useful interpretation.

Among large primes `ell`:

- primality of `4A-3` forbids one residue universally;
- half of the primes also forbid `A=0` through the mod-3 splitting condition;
- half also forbid `A=-1` through the mod-7 quadratic condition;
- one quarter satisfy both splitting obstructions and therefore forbid two extra residues.

The average number of forbidden classes is

\[
1
+\frac12
+\frac12
=2.
\]

Equivalently, sorting primes into the four independent character combinations gives

\[
\frac14(1)+\frac14(2)+\frac14(2)+\frac14(3)=2.
\]

---

## 8. Prior-art boundary

Almost-all results for Erdős--Straus are classical and substantially stronger than this specific bound.

Vaughan's 1970 work and later Elsholtz parametric-sieve results produce much thinner exceptional sets using richer families of solutions.

Therefore the responsible interpretation is:

> The exact FCF `q=3,7` factorization filters fit naturally into classical sieve theory and, by themselves, already have enough combined local dimension to capture a relative density-one set of primes.

No novelty claim is made for the sieve method or for density-one solvability in general.

---

## 9. Next analytic target

The `q=11` exact filter adds a third consecutive shifted integer `A+2`.

Its main branch is another half-density quadratic splitting condition, while its exceptional branch contains at most two units of tightly prescribed nonresidue valuation.

A natural next target is to prove a three-position bound of the shape

\[
\boxed{
\#\{p\le X:\ q=3,7,11\text{ all miss}\}
\ll
\frac{X(\log\log X)^{O(1)}}{(\log X)^{5/2}},}
\]

or stronger, by treating the thin `q=11` defect packet separately.
