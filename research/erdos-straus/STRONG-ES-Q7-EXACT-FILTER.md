# Exact q=7 filter for Mordell-hard primes in the strong/Type-II corridor

**Status:** proved exact factorization criterion  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-FINITE-SHIFT-CORRIDOR.md`, `FAB-HARD-FIRST-FILTERS.md`, `STRONG-ES-MIZONY-THEPAULT-PROVENANCE.md`  
**Claim boundary:** classifies the fixed Type-II shift `q=7` for Mordell-hard primes. It does not prove the strong conjecture or Erdős--Straus.

---

## 1. Fixed shift q = 7

Let `p` be Mordell-hard. Then

\[
p\equiv1\pmod8.
\]

Put

\[
\boxed{C=\frac{p+7}{4}.}
\]

The exact fixed-shift Type-II criterion is

\[
\boxed{-1\in\mathcal R_7(C).}
\]

Because `p!=7`, one has

\[
\gcd(C,7)=1.
\]

The unit group

\[
(\mathbb Z/7\mathbb Z)^\times
\]

is cyclic of order six.

---

## 2. Residue classes by order

The nonzero classes modulo `7` split as follows:

\[
\boxed{
\begin{array}{c|c|c}
\text{residues} & \text{order} & \text{quadratic character}\\
\hline
1 & 1 & +\\
6 & 2 & -\\
2,4 & 3 & +\\
3,5 & 6 & -
\end{array}}
\]

The Type-II target is

\[
\boxed{-1\equiv6\pmod7,}
\]

the unique order-two element.

---

## 3. Primitive-order-six valuation

Let

\[
E_6(C)
=
\sum_{
 r^e\parallel C,
 r\equiv3,5\ (7)
} e
\]

be the total valuation carried by primitive order-six prime factors.

The product of their local signed exponent intervals is, in additive `C_6` notation,

\[
\boxed{
P_E=\{-E,-E+1,\ldots,E\}\pmod6,}
\]

where `E=E_6(C)`.

Hence:

- if `E>=3`, the primitive factors alone hit class `3`, i.e. `-1`;
- if `E<=2`, they alone miss `-1`.

---

## 4. An order-three factor plus a primitive factor forces a hit

Any prime factor in residue class

\[
2\text{ or }4\pmod7
\]

has order three.

Its signed local set already fills the order-three subgroup

\[
\boxed{\{0,2,4\}\subset C_6.}
\]

If even one primitive order-six factor is also present, its local set contains

\[
\{0,1,5\}.
\]

The sum is the whole group:

\[
\boxed{
\{0,2,4\}+\{0,1,5\}=C_6.}
\]

Therefore the target class `3` is hit.

Likewise any prime factor congruent to `6 mod7` hits `-1` directly.

---

## 5. General q=7 miss classification

For an arbitrary integer `C` coprime to `7`, the target `-1` is missed exactly in one of the following two situations.

### Quadratic-residue branch

Every prime factor of `C` belongs to

\[
\boxed{1,2,4\pmod7.}
\]

Then the entire signed box lies inside the quadratic-residue subgroup of order three and cannot contain `-1`.

### Primitive sparse branch

Every prime factor outside class `1` belongs to

\[
\boxed{3,5\pmod7,}
\]

there are no factors in classes `2,4,6`, and

\[
\boxed{E_6(C)\le2.}
\]

These are the only misses.

---

## 6. Mordell-hard parity kills the primitive sparse branch

Now use the hard-prime condition

\[
p\equiv1\pmod8.
\]

Then

\[
p+7\equiv0\pmod8,
\]

so

\[
\boxed{2\mid C.}
\]

But

\[
2\pmod7
\]

has order three.

Therefore `C` always contains a nontrivial order-three factor.

If any primitive order-six factor were also present, Section 4 would force a Type-II hit.

A factor `6 mod7` also forces a hit directly.

Hence the primitive sparse branch is impossible for a Mordell-hard miss.

We obtain the exact theorem.

---

## 7. Exact hard-prime q=7 theorem

### Theorem

For a Mordell-hard prime `p`, put

\[
C=\frac{p+7}{4}.
\]

Then

\[
\boxed{
-1\notin\mathcal R_7(C)
\iff
\text{every prime factor of }C
\text{ is a quadratic residue modulo }7.}
\]

Equivalently,

\[
\boxed{
q=7\text{ fails}
\iff
\operatorname{supp}(C)
\subseteq
\{\ell:\ell\equiv1,2,4\pmod7\}.}
\]

Thus any prime factor

\[
\ell\equiv3,5,6\pmod7
\]

immediately yields a Type-II solution at shift `7`.

---

## 8. Hard residue classes modulo 840

The six Mordell-hard classes have

\[
p\pmod7\in\{1,2,4\}.
\]

Since

\[
C\equiv2p\pmod7,
\]

the three pairs of hard classes give:

\[
\boxed{
\begin{array}{c|c|c}
p\bmod840 & p\bmod7 & C\bmod7\\
\hline
1,169 & 1 & 2\\
121,289 & 2 & 4\\
361,529 & 4 & 1
\end{array}}
\]

These product residues are automatically compatible with the quadratic-residue-only miss branch.

---

## 9. Consecutive-neighbor form

Let

\[
A=\frac{p+3}{4}.
\]

Then

\[
\boxed{C=A+1.}
\]

The previous exact `q=3` filter says a hard-prime miss at `q=3` is equivalent to

\[
\boxed{
\text{every prime factor of }A
\text{ being }1\pmod3.}
\]

The present theorem says a miss at the next corridor position `q=7` is equivalent to

\[
\boxed{
\text{every prime factor of }A+1
\text{ being a quadratic residue modulo }7.}
\]

Thus a hypothetical strong/Type-II counterexample must satisfy both factorization restrictions on consecutive integers.

---

## 10. Strategic consequence

The first two corridor defects are now exact splitting conditions rather than approximate sieves:

\[
\boxed{
\begin{array}{c|c|c}
h & C_h & \text{required miss condition}\\
\hline
0 & A & \operatorname{supp}(A)\subseteq\{1\pmod3\}\\
1 & A+1 & \operatorname{supp}(A+1)\subseteq\mathrm{QR}(7)
\end{array}}
\]

The next useful targets are `q=11` and `q=19`, where hard congruences force small prime factors into the shifted integers and may similarly collapse the general Kneser defect to a pure higher-residue splitting condition.
