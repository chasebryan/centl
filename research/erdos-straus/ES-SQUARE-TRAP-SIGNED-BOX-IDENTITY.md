# Square-completed López layer equals a symmetric signed divisor box

**Status:** proved exact identity  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`, `ES-SQUARE-TRAP-COMPLEMENT.md`, `FAB-KNESER-FULL-STABILIZER-DEFECT.md`  
**Claim boundary:** this is an exact finite-group identity at each layer. It does not by itself prove that every prime is hit by some layer.

---

## 1. Square-completed layer

Fix

\[
a\ge1,
\qquad
m=4a-1.
\]

The square-completed standard Type-II trap layer is

\[
\boxed{
S_a
=
\{-4D\pmod m:D\mid a^2\}.}
\]

Write the prime factorization

\[
\boxed{
a=\prod_{i=1}^s\ell_i^{E_i}.}
\]

Every divisor of `a^2` has the form

\[
D=\prod_i\ell_i^{U_i},
\qquad
0\le U_i\le2E_i.
\]

---

## 2. Center the divisor exponents

Define

\[
\boxed{z_i=U_i-E_i.}
\]

Then

\[
\boxed{-E_i\le z_i\le E_i.}
\]

Moreover

\[
D
=a\prod_i\ell_i^{z_i}
\]

as an identity in the multiplicative group of rational numbers, and modulo `m` every prime factor of `a` is a unit because

\[
\gcd(a,4a-1)=1.
\]

Thus `D/a` is a well-defined unit modulo `m`.

Since

\[
4a\equiv1\pmod m,
\]

we obtain

\[
\begin{aligned}
-4D
&=-4a\frac Da\\
&\equiv-\frac Da\\
&=-\prod_i\ell_i^{z_i}
\pmod m.
\end{aligned}
\]

---

## 3. Exact signed-box identity

Define the symmetric signed divisor box of `a` modulo `m` by

\[
\boxed{
\mathcal R_m(a)
=
\left\{
\prod_i\ell_i^{z_i}\pmod m:
-E_i\le z_i\le E_i
\right\}.}
\]

The centered exponent map above is a bijection between divisors `D|a^2` and signed exponent vectors.

Therefore:

### Theorem — square trap = negative signed box

\[
\boxed{
S_a
=-\mathcal R_{4a-1}(a).}
\]

Equivalently,

\[
\boxed{
p\bmod(4a-1)\in S_a
\iff
-p\in\mathcal R_{4a-1}(a).}
\]

Thus the complete square-completed Type-II congruence layer is exactly a symmetric multiplicative product box.

---

## 4. López Type A and B are the two monotone orthants

Under

\[
z_i=U_i-E_i,
\]

the lower divisor condition

\[
D\mid a
\]

becomes

\[
\boxed{z_i\le0\quad\text{for every }i.}
\]

This is the Type-A orthant.

The upper divisor condition

\[
a\mid D\mid a^2
\]

becomes

\[
\boxed{z_i\ge0\quad\text{for every }i.}
\]

This is the Type-B orthant.

Hence the López Type-A/B trap is the restriction of the signed box to

\[
\boxed{
[-E_1,0]\times\cdots\times[-E_s,0]
\quad\cup\quad
[0,E_1]\times\cdots\times[0,E_s].}
\]

The complete Type-II square layer allows the entire centered box

\[
\boxed{[-E_1,E_1]\times\cdots\times[-E_s,E_s].}
\]

The omitted certificates are precisely the mixed-sign exponent vectors.

---

## 5. Inversion becomes z -> -z

Divisor complement

\[
D\longmapsto\frac{a^2}{D}
\]

sends

\[
U_i\longmapsto2E_i-U_i,
\]

so the centered coordinates transform as

\[
\boxed{z_i\longmapsto-z_i.}
\]

Therefore the complement/inversion theorem becomes the obvious central symmetry of the signed box:

\[
\boxed{
\mathcal R_m(a)^{-1}=\mathcal R_m(a).}
\]

Likewise Type A and Type B are exchanged by

\[
z\longmapsto-z.
\]

This recovers the López mutual-inverse theorem as orthant reflection.

---

## 6. The Kneser machinery applies directly

The box

\[
\mathcal R_m(a)
=
\prod_i
\{\ell_i^{-E_i},\ldots,1,\ldots,\ell_i^{E_i}\}
\]

is exactly the kind of finite multiplicative product set treated by the repository's Kneser defect theory.

Let

\[
G_m=(\mathbb Z/m\mathbb Z)^\times
\]

and

\[
H_a=\operatorname{Stab}(\mathcal R_m(a)).
\]

Passing to

\[
G_m/H_a
\]

therefore imports the full-stabilizer order gap:

for every prime-power factor

\[
\ell_i^{E_i}\parallel a
\]

whose residue lies outside `H_a`,

\[
\boxed{
\operatorname{ord}_{G_m/H_a}(\ell_iH_a)>2E_i+1.}
\]

And any target miss can be studied by Kneser expansion exactly as in the fixed-shift FAB box.

This is the direct algebraic merger of the old shadow layer and the newer signed-box defect theory.

---

## 7. Prime-power layers revisited

If

\[
a=\ell^E,
\]

the signed box is one-dimensional:

\[
\mathcal R_m(a)
=
\{\ell^z:-E\le z\le E\}.
\]

Every exponent is either nonpositive or nonnegative. Therefore the two López orthants already fill the entire box.

This re-proves immediately that

\[
\boxed{S_a=T_a}
\]

for prime-power layers.

The mixed Type-II geometry is therefore exactly the higher-dimensional phenomenon

\[
\boxed{\omega(a)\ge2.}
\]

---

## 8. Example a = 12

For

\[
a=12=2^2\cdot3,
\qquad
m=47,
\]

the completed signed exponent box is

\[
\boxed{(z_2,z_3)\in[-2,2]\times[-1,1].}
\]

The López families use only

\[
(z_2,z_3)\le(0,0)
\]

coordinatewise or

\[
(z_2,z_3)\ge(0,0)
\]

coordinatewise.

The `p=2521` mixed divisor `D=16` has

\[
(U_2,U_3)=(4,0),
\]

so

\[
\boxed{(z_2,z_3)=(2,-1).}
\]

This is visibly a mixed-sign point.

Its signed-box value is

\[
2^2\,3^{-1}\equiv17\pmod{47},
\]

and therefore the trap residue is

\[
-17\equiv30\pmod{47},
\]

exactly the square-only residue that captures `2521`.

---

## 9. Strategic consequence

The two major research languages can now be unified:

### Shadow language

Layer `a`, modulus `4a-1`, congruence trap containment, ancestry, collective cover.

### Kneser language

Symmetric signed product box, stabilizer quotient, expansion defect, high-order exceptional atoms.

The identity

\[
\boxed{S_a=-\mathcal R_{4a-1}(a)}
\]

shows that these are the **same completed Type-II layer**.

The next proof program should therefore work on one object and use both toolkits:

1. shadow/CRT geometry across different layers;
2. Kneser expansion inside each completed layer;
3. complement/inversion to pair mixed candidates;
4. the exact mixed-parameter count to measure how much new mass is added beyond López A/B;
5. finite tests of whether the old Type-A/B zero-density survivor core disappears rapidly under the completed symmetric layers.

This is the cleanest current synthesis between the pre-DSC Type-A/B research and the post-DSC exact Type-I/II route.
