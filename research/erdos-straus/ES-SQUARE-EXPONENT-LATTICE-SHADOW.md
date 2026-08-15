# Exponent-lattice formulation of square-completed ancestry shadows

**Status:** proved exact criterion and coordinate-budget corollary  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`, `ES-SQUARE-MULTIPLICATIVE-SHADOW-IFF.md`, `ES-SQUARE-SQUAREFREE-FACTOR-LIFT.md`  
**Claim boundary:** gives an exact finite-lattice reformulation of direct shadow along any modulus-ancestry edge, together with a strong sufficient box-budget test. It does not solve the resulting lattice-containment problem in full generality.

---

## 1. Ancestor exponent lattice

Fix an earlier layer

\[
\boxed{j=\prod_{i=1}^d p_i^{E_i}}
\]

and put

\[
\boxed{m=4j-1.}
\]

Define the exponent homomorphism

\[
\boxed{
\phi_j:\mathbb Z^d
\longrightarrow
(\mathbb Z/m\mathbb Z)^\times,
\qquad
(z_1,\ldots,z_d)
\longmapsto
\prod_{i=1}^d p_i^{z_i}.}
\]

Let

\[
\boxed{L_j=\ker\phi_j.}
\]

Thus two exponent vectors give the same residue modulo `m` exactly when they differ by an element of `L_j`.

The centered exponent box of the completed layer is

\[
\boxed{
B_j
=
\prod_{i=1}^d[-E_i,E_i]_{\mathbb Z}.}
\]

By the signed-box identity,

\[
\boxed{
\mathcal R_m(j)=\phi_j(B_j).}
\]

---

## 2. A later ancestry layer

Let

\[
\boxed{k=\prod_{\nu=1}^t r_\nu^{F_\nu}}
\]

and assume the modulus-ancestry relation

\[
\boxed{m_j\mid m_k.}
\]

The later completed signed box reduced modulo the ancestor modulus is

\[
\boxed{
R_{k\to j}
=
\left\{
\prod_{\nu=1}^t r_\nu^{z_\nu}\pmod m:
-F_\nu\le z_\nu\le F_\nu
\right\}.}
\]

For direct shadow by `j`, one needs

\[
\boxed{R_{k\to j}\subseteq\phi_j(B_j).}
\]

---

## 3. Immediate subgroup obstruction

If some prime factor `r_\nu` of `k` does not lie in the subgroup

\[
\operatorname{im}\phi_j
=
\langle p_1,\ldots,p_d\rangle,
\]

then direct shadow is impossible.

Indeed the later box contains the residue `r_\nu` itself, while the ancestor box is contained in `im phi_j`.

Therefore a necessary condition is

\[
\boxed{
r_\nu\in\operatorname{im}\phi_j
\quad\text{for every }\nu.}
\]

Assume this from now on.

Choose arbitrary exponent lifts

\[
\boxed{v_\nu\in\mathbb Z^d}
\]

satisfying

\[
\boxed{\phi_j(v_\nu)=r_\nu.}
\]

Different choices differ by vectors in `L_j` and therefore do not change the criterion below.

---

## 4. The later signed box is a discrete zonotope

Define the discrete zonotope

\[
\boxed{
Z(k\to j)
=
\left\{
\sum_{\nu=1}^t z_\nu v_\nu:
-F_\nu\le z_\nu\le F_\nu
\right\}
\subseteq\mathbb Z^d.}
\]

Then

\[
\boxed{
R_{k\to j}
=
\phi_j(Z(k\to j)).}
\]

The ancestor completed box is

\[
\phi_j(B_j).
\]

Therefore an element of the later box lies in the ancestor box exactly when its exponent vector can be shifted by a relation vector into `B_j`.

---

## 5. Exact lattice-cover criterion

### Theorem — ancestry shadow as zonotope containment modulo the relation lattice

Along the ancestry edge `j<k`, the completed layer `k` is directly shadowed by `j` if and only if

\[
\boxed{
Z(k\to j)
\subseteq
B_j+L_j.}
\]

Equivalently, for every coefficient vector

\[
(z_\nu),
\qquad
-F_\nu\le z_\nu\le F_\nu,
\]

there exists a relation vector

\[
\lambda\in L_j
\]

such that

\[
\boxed{
\sum_\nu z_\nu v_\nu-\lambda
\in B_j.}
\]

This criterion is independent of the chosen lifts `v_\nu`.

---

## 6. Coordinate-budget sufficient theorem

A simple strong sufficient condition avoids relation-lattice wrapping entirely.

Suppose lifts can be chosen so that for every ancestor coordinate `i`,

\[
\boxed{
\sum_{\nu=1}^t
F_\nu\,|(v_\nu)_i|
\le E_i.}
\]

Then for every allowed signed coefficient vector,

\[
\left|
\sum_\nu z_\nu(v_\nu)_i
\right|
\le
\sum_\nu F_\nu|(v_\nu)_i|
\le E_i.
\]

Hence the whole zonotope already lies in `B_j`:

\[
Z(k\to j)\subseteq B_j.
\]

Therefore:

### Corollary — coordinate-budget shadow

If there exist exponent lifts satisfying

\[
\boxed{
\sum_\nu F_\nu|(v_\nu)_i|\le E_i
\quad\text{for every }i,}
\]

then

\[
\boxed{S_k\bmod m_j\subseteq S_j.}
\]

This is a finite weighted `L^1` packing test.

---

## 7. Squarefree factor lift is a disjoint-support budget

In the squarefree factor-lift theorem, the earlier index factors as

\[
j=A_1\cdots A_t
\]

and each later prime `r_\nu` is congruent to `A_\nu` modulo `m`.

Choose `v_\nu` to be the exponent vector of `A_\nu`.

When the factorization distributes the ancestor prime-power exponents among the `A_\nu`, the coordinate budgets add exactly to the midpoint exponents `E_i`.

Thus

\[
\sum_\nu |(v_\nu)_i|=E_i
\]

and the coordinate-budget theorem recovers the factor-lift shadow.

The all-quotient Dirichlet families are therefore explicit exact packings of the ancestor exponent box.

---

## 8. Multiplicative stabilizer extensions use relation-lattice wrapping

The multiplicative-shadow iff theorem can behave differently.

A stabilizer direction need not admit a small representative inside the raw coordinate budget. Its products may leave `B_j` and return through the relation lattice `L_j`.

Thus the exact criterion

\[
Z\subseteq B_j+L_j
\]

strictly generalizes the no-wrap coordinate budget.

This separates two mechanisms cleanly:

1. **geometric packing:** `Z subset B_j`;
2. **periodic packing:** `Z subset B_j+L_j` only after relation-lattice reduction.

---

## 9. Canonical relation for even ancestors

If

\[
j=2^e\prod_{i=1}^s p_i^{E_i}
\]

is even, then

\[
4j
=2^{e+2}\prod_i p_i^{E_i}
\equiv1\pmod{4j-1}.
\]

Therefore the exponent vector

\[
\boxed{
(e+2,E_1,\ldots,E_s)
\in L_j.}
\]

This canonical relation is responsible for many effective-dimension collapses.

For `j=2^e p` with `p` prime, it yields the one-dimensional interval theorem

\[
\mathcal R(j)=\{2^z:-2e-2\le z\le2e+2\}.
\]

For larger even support it supplies a distinguished lattice direction along which the ancestor box can be folded.

---

## 10. Effective dimension

The raw support dimension of the completed layer is

\[
\omega(j)=d.
\]

But the actual multiplicative geometry is governed by the quotient lattice

\[
\boxed{\mathbb Z^d/L_j.}
\]

and by the image of the bounded box `B_j` inside that quotient.

Thus a more useful invariant is the **effective signed-box dimension**, meaning the minimal rank of a lattice model needed to represent `phi_j(B_j)` after quotienting by explicit relations.

Examples:

- prime powers: effective dimension one;
- `2^e p`: raw dimension two but effective cyclic interval dimension one;
- general multi-prime indices may retain higher effective dimension.

---

## 11. Research consequence

The remaining nonmultiplicative ancestry problem is now an exact finite geometry problem:

\[
\boxed{
\text{Does a later discrete zonotope fit inside the ancestor exponent box modulo }L_j?}
\]

This suggests both theorem and computation paths:

1. derive canonical generators for `L_j` from the modulus identity and factor relations;
2. reduce `B_j` to a low-dimensional fundamental-domain model;
3. classify few-prime later zonotopes by coordinate budgets;
4. use Smith-normal-form or finite quotient methods for exact automated shadow certification;
5. search for infinite ancestry families corresponding to fixed lattice-packing templates.
