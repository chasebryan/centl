# Complete Inverse-Pair Congruence System for Prime Erdős–Straus

**Status:** proved reformulation from the classical Type I/II criteria and the coprime `fab` normalization  
**Date:** 2026-08-15  
**Depends on:** `FAB-TYPE-I-EQUIVALENCE.md`, `FAB-TYPE-II-EQUIVALENCE.md`, `FAB-COPRIME-COMPLETENESS.md`  
**Classical basis:** Elsholtz–Tao equivalent criteria for Type I and Type II prime solutions.  
**Claim boundary:** this is a complete equivalent formulation of the prime conjecture, not a proof that every prime hits the system.

---

## 1. Common parameter data

Let

\[
\boxed{\gcd(u,v)=1}
\]

and let

\[
\boxed{e\mid u+v}
\]

with

\[
\boxed{e\equiv3\pmod4.}
\]

Put

\[
\boxed{M=4uv.}
\]

Because `e|u+v` and `gcd(u,v)=1`,

\[
\gcd(e,u)=\gcd(e,v)=1.
\]

Since `e` is odd,

\[
\boxed{\gcd(e,M)=1.}
\]

Thus `e` is invertible modulo `M`.

---

## 2. Type II class

The exact Type II criterion may be written

\[
e\mid u+v,
\qquad
\boxed{4uv\mid p+e.}
\]

Equivalently,

\[
\boxed{p\equiv-e\pmod M.}
\]

Thus Type II occupies the residue

\[
\boxed{r=-e\pmod M.}
\]

---

## 3. Type I class

The classical equivalent Type I criterion may be written

\[
e\mid u+v,
\qquad
\boxed{4uv\mid pe+1.}
\]

Since `e` is a unit modulo `M`, this is equivalent to

\[
\boxed{p\equiv-e^{-1}\pmod M.}
\]

But

\[
(-e)^{-1}\equiv-e^{-1}\pmod M,
\]

so the Type I class is exactly

\[
\boxed{r^{-1}\pmod M.}
\]

---

## 4. Master theorem

### Theorem

For every odd prime `p`, the Erdős-Straus equation is solvable if and only if there exist coprime positive integers `u,v` and a divisor

\[
e\mid u+v,
\qquad e\equiv3\pmod4,
\]

such that, with

\[
M=4uv,
\qquad r=-e\pmod M,
\]

one has

\[
\boxed{
p\equiv r\pmod M
\quad\text{or}\quad
p\equiv r^{-1}\pmod M.
}
\]

The two alternatives are respectively Type II and Type I.

Thus the complete prime problem is one **inverse-pair covering system**:

\[
\boxed{
\mathcal S_{u,v,e}
=\{-e,-e^{-1}\}\pmod{4uv}.
}
\]

No solution type lies outside this system.

---

## 5. Exact multiplicative symmetry

The two solution residues satisfy

\[
\boxed{
(-e)(-e^{-1})\equiv1\pmod M.
}
\]

So Type I and Type II are not merely analogous congruence classes. They are exact multiplicative inverses in

\[
(\mathbb Z/M\mathbb Z)^\times.
\]

The fixed points of the involution are the classes satisfying

\[
r^2\equiv1\pmod M.
\]

When the pair is not fixed, the Type I and Type II classes form a two-element orbit under inversion.

---

## 6. Quadratic-signature blindness theorem

Let `ell` be any odd prime divisor of `uv`.

Because both solution residues are units modulo `ell`, their Legendre symbols are defined.

For the Type II residue,

\[
\left(\frac{-e}{\ell}\right)
=
\left(\frac{-1}{\ell}\right)
\left(\frac e\ell\right).
\]

For the Type I inverse residue,

\[
\left(\frac{-e^{-1}}{\ell}\right)
=
\left(\frac{-1}{\ell}\right)
\left(\frac{e^{-1}}\ell\right).
\]

But a quadratic character is unchanged by inversion:

\[
\left(\frac{e^{-1}}\ell\right)
=
\left(\frac e\ell\right).
\]

Therefore

\[
\boxed{
\left(\frac{-e}{\ell}\right)
=
\left(\frac{-e^{-1}}{\ell}\right).
}
\]

### Consequence

The Type I / Type II inverse pair has the **same complete vector of quadratic signs** at every prime dividing `uv`.

Hence no scalar Jacobi symbol, and no vector consisting only of quadratic characters on the modulus support, can distinguish the two members of an inverse pair.

This is a structural limitation, not a computational observation.

---

## 7. Higher characters do distinguish orientation

For a general multiplicative character `chi`,

\[
\chi(e^{-1})=\chi(e)^{-1}.
\]

Thus higher-order characters need not identify the two inverse classes; they exchange a character value with its inverse.

This is exactly the kind of information retained by the higher-order multiplicative quotient machinery developed earlier in the Type A/B program.

The master system therefore explains why quadratic shielding alone can be powerful but incomplete.

---

## 8. Sum-product parameter geometry

The congruence system depends on

\[
M=4uv
\]

and on a divisor

\[
e\mid u+v.
\]

So every inverse pair is governed simultaneously by:

- the **product** `uv`, which sets the modulus;
- the **sum** `u+v`, whose divisors supply the inverse-pair orientation.

This sum/product coupling is the essential arithmetic geometry of the complete prime system.

A universal proof must show that for every prime target `p`, some coprime factor pair `(u,v)` has a divisor of its sum whose negative residue or inverse negative residue matches `p` modulo `4uv`.

---

## 9. Relation to López Type A/B

López Type A and Type B are Type II subclasses with their own divisor-congruence parametrizations and a documented inverse relationship between the two residue families.

The theorem here shows that inverse-residue geometry is not peculiar to those subclasses. It is built into the full prime Type I/Type II dichotomy.

Therefore the López inverse behavior should be studied as a structured subquotient of this complete inverse-pair system rather than as an isolated coincidence.

A precise variable-by-variable embedding remains a separate bookkeeping task and should preserve López's original notation and attribution.

---

## 10. New all-prime formulation

The prime Erdős-Straus conjecture is now exactly the statement:

\[
\boxed{
\forall p\text{ prime},\ \exists\ (u,v,e):
\gcd(u,v)=1,
\ e\mid u+v,
\ e\equiv3\pmod4,
\ p\in\{-e,-e^{-1}\}\pmod{4uv}.
}
\]

This is the cleanest current congruence-system target.

The active proof problem is to understand why the moving family of inverse pairs covers every prime despite the quadratic-character obstruction that prevents any naive fixed finite congruence cover.
