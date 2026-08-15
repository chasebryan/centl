# C1 Partial Theorems Toward DSC-P — corrected

**Status:** proved local C1 theorems + explicit remaining global obstruction  
**Date:** 2026-08-15  
**Claim boundary:** does **not** prove Erdős-Straus, López Type A/B coverage, universal DSC-P, or full C1. It does prove that the unique active fixed-negative row is never by itself a reduced covering obstruction.

Read with:

- [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md)
- [SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md](SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md)
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)
- [CLASS-C-RESIDUAL-CORE.md](CLASS-C-RESIDUAL-CORE.md)

## 1. Correction to the previous draft

An earlier version of this file labeled the following as a theorem:

> if `q=p^a` and `R` is a proper subset of `Z/qZ`, then a reduced class exists outside `R`.

That statement is false in general. A proper forbidden set can contain every reduced class while omitting only non-reduced classes.

The previous text itself noticed this possibility, so the theorem label was inconsistent with its own proof.

The false general statement is withdrawn.

A second correction: at one exact Type A/B layer, the compatible-trap pullback does **not** multiply one trap into several parameter classes. The affine pullback map is injective on the compatible trap fiber.

Both points are now handled exactly in [SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md](SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md).

## 2. C1 setup

Let a directly novel target candidate have

\[
x=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1),
\qquad
\gcd(r,L)=1.
\]

Assume

\[
\boxed{|\mathcal N^{\rm act}_{k,r}|=1.}
\]

Let `j0` be the unique active fixed-negative layer and put

\[
m=4j_0-1,
\qquad
g=\gcd(L,m),
\qquad
q=m/g.
\]

Let

\[
R\subseteq\mathbb Z/q\mathbb Z
\]

be its exact Type A/B forbidden pullback.

Direct novelty gives

\[
R\ne\mathbb Z/q\mathbb Z.
\]

## 3. Prime-power shape theorem

The previously proved unique-active valuation theorem gives

\[
\boxed{q=p\text{ or }p^2}
\]

for one odd prime `p`.

If `p∤L` (Operator-02 Class B), then fixed-squareclass parity forces

\[
\boxed{q=p^2.}
\]

Since `840|L`, a Class-B prime satisfies

\[
\boxed{p\ge11.}
\]

## 4. Exact pullback injection

Let

\[
U=\{u\in T_{j_0}:u\equiv r\pmod g\}.
\]

The map

\[
u\mapsto
\frac{u-r}{g}
\left(\frac Lg\right)^{-1}
\pmod q
\]

is injective on `U`.

Therefore

\[
\boxed{|R|=|U|.}
\]

This is an exact fact, not a heuristic fiber-size assumption.

## 5. Class-A local theorem

If

\[
p\mid L,
\]

then reducedness at `p` does not depend on the parameter:

\[
r+Ls\equiv r\pmod p.
\]

Because `gcd(r,L)=1`, every parameter class is reduced at `p`.

Since `R` is proper, choose any

\[
s_0\notin R.
\]

Then the unique active row is avoided exactly and reducedness holds automatically.

Thus every Class-A unique active row has a reduced local escape.

## 6. Class-B local theorem

Assume

\[
p\nmid L.
\]

Then

\[
q=p^2,
\qquad
m=g p^2=4j_0-1.
\]

Because `p` is odd,

\[
g\equiv3\pmod4
\]

and

\[
j_0=\frac{g p^2+1}{4}.
\]

For either trap family

\[
-e
\quad\text{or}\quad
-4e,
\qquad e\mid j_0,
\]

compatibility modulo `g` forces `e` into one fixed residue class modulo `g`.

Any residue class modulo `g` contains at most

\[
\frac{p^2+3}{4}
\]

integers in the interval `1<=e<=j_0`.

Therefore the two trap families together give

\[
\boxed{|R|\le\frac{p^2+3}{2}.}
\]

Since `p∤L`, non-reduced parameters form exactly one class modulo `p`, so the number of reduced parameter classes modulo `p^2` is

\[
\boxed{p^2-p.}
\]

For `p>=5`,

\[
\frac{p^2+3}{2}<p^2-p.
\]

Class B has `p>=11`, so the forbidden set is strictly too small to contain every reduced class.

Hence every Class-B unique active row also has a reduced local escape.

## 7. Universal local C1 theorem

Combining the two cases:

\[
\boxed{
|\mathcal N^{\rm act}_{k,r}|=1
\Longrightarrow
\text{the unique active fixed-negative row admits a reduced exact local escape.}
}
\]

This is now proved universally.

The former local “two-box pullback gap” is therefore **closed** in the single-active regime.

## 8. Why full C1 is still open

The `k<=1500` independently verified census showed:

```text
single-active candidates:                       2,770
fiber kernel nonempty:                          1,480
unique active row survives final kernel:            18
nonfixed residual edge incidences:             69,672
```

So after the local active row is understood, the actual residual system is dominated by **nonfixed exact rows**.

The remaining theorem is not

> can the active row leave one reduced class?

That is solved.

The remaining theorem is:

\[
\boxed{
\text{Can one choose a parameter that simultaneously}
\text{ realizes the guaranteed active-row escape and avoids}
\text{ every surviving nonfixed exact row?}
}
\]

This is an interaction/coordination problem among the residual rows.

## 9. Correct C1 target

A sufficient theorem would be:

### C1 coordination theorem candidate

For every directly novel candidate with `|N^act|=1`, after exact fiber peeling of the nonfixed rows, at least one reduced assignment survives that is compatible with the guaranteed local active-row escape.

If proved, this would establish C1 and give infinitely many exact-depth primes for every single-active directly novel candidate by Dirichlet.

It still would not prove universal DSC-P, since `|N^act|>1` cases would remain.

## 10. Finite evidence

Through `k<=1500`, every one of the `2,770` single-active candidates is globally resolved.

Among the `1,480` nonempty residual kernels, the fixed selector menu

\[
\{0,\pm1,\ldots,\pm64\}
\]

found a reduced global escape in

\[
\boxed{1,480/1,480}
\]

cases, with maximum radius `48`.

That is strong finite evidence for the coordination theorem, not a proof.

## 11. Next proof actions

1. classify the nonfixed residual rows that survive in C1;
2. prove why the unique active row is peeled in `1,462/1,480` nonempty finite kernels;
3. solve the two smallest residual signature cases `{11,13}` exactly;
4. solve the recurring `{3,11,13}` signature structurally;
5. search for a local product/character invariant forcing overlap among the nonfixed rows;
6. only then promote from C1 to bounded `|N^act|>1`.

## 12. Wall statement

Erdős-Straus remains open. López universal Type A/B coverage remains open. Universal DSC-P remains open. Full C1 remains open.

The local active-row obstruction is no longer open.
