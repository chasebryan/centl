# Square-completed trap complement: global inversion and exact mixed-parameter count

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`, `ES-TYPEII-SQUARE-COMPLETION-LOPEZ-A.md`  
**Claim boundary:** this is an exact structural theorem for the square-completed Type-II layer. It counts divisor parameters, not necessarily distinct residue classes after modular collisions.

---

## 1. Setup

Fix

\[
a\ge1,
\qquad
m=4a-1.
\]

The square-completed Type-II layer is

\[
\boxed{
S_a
=
\{-4D\pmod m:D\mid a^2\}.}
\]

The ordinary López Type-A/B boundary is represented by

\[
\boxed{
D\mid a
\quad\text{or}\quad
a\mid D\mid a^2.}
\]

The remaining divisors are the mixed cross-orthant parameters.

---

## 2. Divisor complement is residue inversion

For every divisor

\[
D\mid a^2
\]

define its complement

\[
\boxed{D^*=\frac{a^2}{D}.}
\]

The corresponding square-trap residues satisfy

\[
\begin{aligned}
(-4D)(-4D^*)
&=16DD^*\\
&=16a^2\\
&=(4a)^2\\
&\equiv1\pmod{4a-1}.
\end{aligned}
\]

Therefore:

### Theorem — global complement/inversion law

\[
\boxed{
-4D^*
\equiv
(-4D)^{-1}
\pmod{4a-1}.}
\]

Thus the complete square-divisor layer is invariant under multiplicative inversion:

\[
\boxed{S_a^{-1}=S_a.}
\]

This is the divisor-lattice origin of the inverse symmetry already visible in the signed-box formulation.

---

## 3. López A/B inverse pairing is the boundary restriction

Take a lower-box divisor

\[
e\mid a.
\]

Its complement is

\[
e^*
=\frac{a^2}{e}
=a\frac ae.
\]

This belongs to the upper box.

The lower residue is the Type-A residue

\[
\boxed{-4e.}
\]

The complementary upper residue is

\[
-4e^*
=-4a\frac ae
\equiv-\frac ae
\pmod{4a-1},
\]

which is a Type-B residue.

Hence:

### Corollary — López mutual inversion is inherited from divisor complement

For every `e|a`,

\[
\boxed{
(-4e)^{-1}
\equiv
-\frac ae
\pmod{4a-1}.}
\]

So the familiar Type-A/Type-B inverse relationship is not an isolated two-family phenomenon. It is exactly the restriction of the global involution

\[
D\leftrightarrow a^2/D
\]

on the complete Type-II square divisor lattice.

---

## 4. Exact number of boundary parameters

Let

\[
\operatorname{Div}(a^2)
\]

be the positive divisor set of `a^2`.

The lower region

\[
L(a)=\{D:D\mid a\}
\]

has cardinality

\[
|L(a)|=\tau(a).
\]

The upper region

\[
U(a)=\{D:a\mid D\mid a^2\}
\]

is the image of `Div(a)` under multiplication by `a`, so

\[
|U(a)|=\tau(a).
\]

Their intersection is exactly

\[
L(a)\cap U(a)=\{a\}.
\]

Therefore the López boundary parameter count is

\[
\boxed{|L(a)\cup U(a)|=2\tau(a)-1.}
\]

---

## 5. Exact mixed-parameter count

The complete square divisor lattice has size

\[
\boxed{|\operatorname{Div}(a^2)|=\tau(a^2).}
\]

Hence the number of mixed square-divisor parameters is exactly

\[
\boxed{
M(a)
=
\tau(a^2)-2\tau(a)+1.}
\]

This counts the square-completed Type-II divisor parameters that lie in neither López boundary orthant.

Again, this is a parameter count. Distinct mixed divisors may in principle collide modulo `4a-1`.

---

## 6. Vanishing criterion

If

\[
a=\ell^E
\]

is a prime power, then

\[
\tau(a)=E+1,
\qquad
\tau(a^2)=2E+1.
\]

Thus

\[
M(a)
=(2E+1)-2(E+1)+1
=0.
\]

Conversely, if `a` has at least two distinct prime factors, the exponent box has at least two coordinates. Choosing one coordinate strictly below its midpoint and another strictly above its midpoint produces a mixed divisor.

Therefore:

### Theorem — exact mixed-region criterion

\[
\boxed{
M(a)=0
\iff
 a\text{ is a prime power}.}
\]

Equivalently,

\[
\boxed{
M(a)>0
\iff
\omega(a)\ge2.}
\]

So multi-prime layers are exactly the layers where the complete Type-II divisor geometry contains parameter directions invisible to López A/B.

---

## 7. Mixed parameters occur in complement pairs

The complement involution preserves mixedness.

Indeed, write

\[
a=\prod_i\ell_i^{E_i},
\qquad
D=\prod_i\ell_i^{U_i}.
\]

Then

\[
D^*
=\prod_i\ell_i^{2E_i-U_i}.
\]

If `D` is mixed, some `U_i<E_i` and some `U_j>E_j`. Under complement those inequalities reverse, so `D^*` is again mixed.

The only fixed point of complement in the full divisor lattice is

\[
D=a.
\]

But `a` lies on both López boundaries and is not mixed.

Therefore complement acts without fixed points on the mixed region.

### Corollary

\[
\boxed{M(a)\text{ is even}.}
\]

The genuinely new Type-II parameters arrive in inverse residue pairs.

---

## 8. Example a = 12

For

\[
a=12=2^2\cdot3,
\]

we have

\[
\tau(12)=6,
\qquad
\tau(144)=15.
\]

Hence

\[
\boxed{M(12)=15-12+1=4.}
\]

The mixed divisors are

\[
\boxed{8,9,16,18.}
\]

They pair under complement as

\[
8\leftrightarrow18,
\qquad
9\leftrightarrow16.
\]

At modulus

\[
4a-1=47,
\]

the `p=2521` certificate uses `D=16`, while its inverse mixed residue is represented by `D=9`.

This makes the square-only rescue a literal cross-orthant inverse pair.

---

## 9. Strategic consequence

The complete Type-II layer now has a clean three-part decomposition:

\[
\boxed{
\text{lower López orthant}
\ \cup\ 
\text{mixed inverse pairs}
\ \cup\ 
\text{upper López orthant}.}
\]

The old Type-A/B inverse theorem is the boundary shadow of a global complement symmetry, and the exact amount of missing divisor geometry is measured by

\[
M(a)=\tau(a^2)-2\tau(a)+1.
\]

This supplies natural quantitative inputs for the next shadow program:

1. measure how many mixed parameters survive hard-class admissibility;
2. classify modular collisions among the mixed inverse pairs;
3. determine whether mixed-pair arrival is concentrated on the old Type-A/B composite-rescue core;
4. extend ancestry/shadow reductions using complement symmetry to halve the new parameter search.
