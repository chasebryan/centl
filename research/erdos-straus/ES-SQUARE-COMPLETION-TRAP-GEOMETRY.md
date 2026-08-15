# Square-completed Type-II trap geometry: López A/B are the two boundary orthants

**Status:** proved exact structural theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-TYPEII-SQUARE-COMPLETION-LOPEZ-A.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `COMPOSITE-CORE.md`  
**External background:** Miguel Angel López, *A Complete Congruence System for the Erdos-Straus Conjecture*, arXiv:2404.01508  
**Claim boundary:** this identifies the López Type-A/B layer inside the complete square-divisor Type-II layer. It does not prove that every prime is hit by a square-completed layer.

---

## 1. Three trap systems at one layer

Fix

\[
a\ge1,
\qquad
m_a=4a-1.
\]

The existing López Type-A/B trap set is

\[
\boxed{
T_a
=
\{-e,-4e\pmod{m_a}:e\mid a\}.}
\]

The exact square-completed standard Type-II theorem suggests the enlarged set

\[
\boxed{
S_a
=
\{-4D\pmod{m_a}:D\mid a^2\}.}
\]

For a prime `p`, a residue hit in `S_a` is a standard Type-II certificate whenever the representing divisor `D` is not divisible by `p`.

We now identify the old two-family trap exactly inside this square-divisor box.

---

## 2. Type A is the lower divisor box

Every divisor

\[
e\mid a
\]

is also a divisor of `a^2`.

Taking

\[
D=e
\]

in the square-completed trap gives

\[
-4D=-4e.
\]

Therefore the López Type-A residues are exactly the square-divisor parameters

\[
\boxed{D\mid a.}
\]

This is the lower half of the divisor exponent box.

---

## 3. Type B is the upper divisor box

Again let

\[
e\mid a.
\]

Take

\[
\boxed{D=ae.}
\]

Then

\[
D\mid a^2.
\]

Since

\[
4a\equiv1\pmod{4a-1},
\]

we have

\[
-4D
=-4ae
\equiv-e\pmod{4a-1}.
\]

Thus every López Type-B residue is also a square-completed Type-II residue at the **same layer**.

The Type-B parameters are exactly

\[
\boxed{D=ae,\qquad e\mid a,}
\]

or equivalently

\[
\boxed{a\mid D\mid a^2.}
\]

This is the upper half of the divisor exponent box.

Therefore:

### Theorem — exact layerwise containment

For every `a`,

\[
\boxed{T_a\subseteq S_a.}
\]

More precisely,

\[
\boxed{
T_a
=
\{-4D:D\mid a\}
\cup
\{-4D:a\mid D\mid a^2\}
\pmod{4a-1}.}
\]

So López A and B are not separate from square-completed Type II. They are the two boundary divisor regions of the complete Type-II layer.

---

## 4. Prime-exponent geometry

Write

\[
a=\prod_{i=1}^s \ell_i^{E_i}.
\]

Every divisor of `a^2` has the unique form

\[
D=\prod_{i=1}^s\ell_i^{U_i},
\qquad
0\le U_i\le2E_i.
\]

Thus the square-completed parameter space is the full integer box

\[
\boxed{
\mathcal B(a)
=
\prod_{i=1}^s[0,2E_i]_{\mathbb Z}.}
\]

### Type-A orthant

The condition `D|a` is

\[
\boxed{U_i\le E_i\quad\text{for every }i.}
\]

### Type-B orthant

The condition `a|D|a^2` is

\[
\boxed{U_i\ge E_i\quad\text{for every }i.}
\]

Hence the López parameter region is

\[
\boxed{
\mathcal B_-(a)\cup\mathcal B_+(a),}
\]

where

\[
\mathcal B_-(a)=\prod_i[0,E_i],
\qquad
\mathcal B_+(a)=\prod_i[E_i,2E_i].
\]

The complete Type-II square box is all of `B(a)`.

---

## 5. The genuinely new region is mixed

A square divisor `D|a^2` lies outside both López families exactly when its exponent vector is **mixed** relative to the midpoint vector `(E_i)`:

\[
\boxed{
\exists i,j:
U_i<E_i,
\qquad
U_j>E_j.}
\]

These are the cross-orthant regions omitted by both Type A and Type B.

Therefore a standard Type-II certificate that is not represented by López A or B at the same layer must use a mixed square divisor.

This gives a precise geometric meaning to the extra Type-II room.

---

## 6. Prime-power layers are already complete

Suppose

\[
a=\ell^E
\]

is a prime power.

Then every exponent

\[
0\le U\le2E
\]

satisfies either

\[
U\le E
\]

or

\[
U\ge E.
\]

Hence there is no mixed region.

Therefore:

### Theorem — prime-power layer equality

If `a` is a prime power, then

\[
\boxed{S_a=T_a.}
\]

So square completion adds **no new Type-II trap residue at all** on a prime-power layer.

Every genuinely new square-completed parameter requires a layer `a` with at least two distinct prime divisors.

---

## 7. Composite layers create the cross-regions

If `a` has at least two distinct prime factors, then mixed divisor parameters exist.

For example, if

\[
a=u^Ev^F\cdots
\]

with distinct primes `u,v`, then the exponent choice

\[
U_u=0,
\qquad
U_v=2F
\]

is below the midpoint in one coordinate and above it in another.

This proves that the **parameter-space** completion is nontrivial on every non-prime-power layer.

Residue collisions modulo `4a-1` can in principle identify some mixed parameters with boundary residues, so parameter-space nontriviality alone does not assert strict residue-set enlargement for every such `a`. But strict enlargement occurs already in small examples and is exactly what happens in the canonical `2521` rescue below.

---

## 8. The p = 2521 mixed-divisor rescue

Take

\[
p=2521,
\qquad
 a=12=2^2\cdot3.
\]

Then

\[
m_a=4a-1=47.
\]

The square-only certificate from `ES-TYPEII-SQUARE-COMPLETION-LOPEZ-A.md` uses

\[
\boxed{D=16=2^4.}
\]

Relative to

\[
a^2=2^4\cdot3^2,
\]

the exponent vector of `D` is

\[
(U_2,U_3)=(4,0),
\]

while the midpoint vector for `a` is

\[
(E_2,E_3)=(2,1).
\]

Thus

\[
4>2,
\qquad
0<1,
\]

so `D` is genuinely mixed.

Its residue is

\[
-4D=-64\equiv30\pmod{47}.
\]

The ordinary López layer has divisors

\[
1,2,3,4,6,12
\]

and trap residues

\[
\{-e,-4e:e\mid12\}.
\]

None is `30 mod 47`.

Therefore

\[
\boxed{30\in S_{12}\setminus T_{12}.}
\]

And indeed

\[
2521\equiv30\pmod{47}.
\]

So the square-completed layer solves `2521` at the prime modulus `47` through a mixed divisor that neither López boundary orthant can see.

---

## 9. Exact relation to the López Type-B parametrization

The upper-box embedding can also be written directly in López parameters.

A Type-B witness has positive `d,n` and modulus

\[
4dn-1.
\]

Put

\[
a=dn
\]

and choose the square divisor

\[
\boxed{D=dn^2=an.}
\]

Then

\[
D\mid a^2
\]

because

\[
\frac{a^2}{D}=d.
\]

Moreover

\[
4D=4dn^2
=n(4dn)
\equiv n\pmod{4dn-1}.
\]

Hence

\[
\boxed{-4D\equiv-n\pmod{4dn-1},}
\]

which is exactly the López Type-B residue.

Thus both López parametrizations embed explicitly into one square-divisor formula:

\[
\boxed{
\begin{array}{c|c}
\text{López family} & \text{square divisor }D\\
\hline
\text{Type A} & d\\
\text{Type B} & dn^2
\end{array}}
\]

at the common layer `a=dn`.

---

## 10. Strategic consequence: reuse the shadow machinery

The mature Type-A/B research should not be discarded when moving to the exact Type-I/II formulation.

Instead, define the square-completed layer

\[
S_a=\{-4D:D\mid a^2\}\pmod{4a-1}
\]

and regard the existing López layer `T_a` as its two boundary orthants.

This creates a concrete next program:

1. extend exact trap cardinality from `Div(a)` to the square divisor lattice `Div(a^2)`;
2. classify collisions among mixed square-divisor residues;
3. extend direct-shadow and ancestry theorems from `T_a` to `S_a`;
4. determine whether the old zero-density Type-A/B survivor core is killed by mixed square-divisor traps;
5. exploit the theorem that prime-power layers need no extension, so all new geometry is localized to multi-prime layers;
6. compare mixed-divisor shadow quotients with the exact Kneser stabilizer defects of the signed-box formulation.

The conceptual picture is now precise:

\[
\boxed{
\text{López A/B}
=
\text{two boundary orthants of the complete Type-II square-divisor box}.}
\]

The missing certificates live in the cross-regions.
