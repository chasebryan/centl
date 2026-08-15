# Diamond Candidate: Trap-Signature Coset as the Precise Residual Target

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** integration of parent quotient theorem into the residual cascade  
**Novelty claim level:** Operator-02 diamond candidate — naming the precise unsafe set that residual local solutions must avoid  
**Claim boundary:** inherits all parent claim boundaries. The trap-signature coset theorem is a parent theorem (`../QUADRATIC-SIGNATURE-QUOTIENT.md`). This note only places it at the correct node of the residual cascade.

---

## 1. Parent trap-signature coset theorem

For m = 4k−1 with local signature space V_m = F_2^r (one bit per distinct prime factor),

\[
\chi_m(T_k) = \chi_m(-1) + H_k,
\]

where H_k is the span of the local signatures of the prime factors of k. All traps occupy a single affine coset. Any unit whose quotient class in V_m / H_k differs from [χ_m(−1)] is automatically outside T_k.

Jacobi −1 is the projection of this condition onto a single functional. When dim(V_m / H_k) > 1, the trap coset is a proper subset of the Jacobi −1 half-space.

Parent finite data through k ≤ 3000: roughly one third of layers have dim Q_k ≥ 2.

---

## 2. Placement in the residual cascade

After the Operator-02 refinements, the residual problem for a Class-C candidate is exact trap avoidance against layers in \(\mathcal N^{\mathrm{act}}_{k,r}\), using the residual fiber-kernel coordinates.

For each such active layer j, the unsafe set is not the whole Jacobi −1 half of (Z/m_j Z)^×. It is the much smaller set T_j, equivalently the residues whose local signature lies in the coset χ(−1)+H_j.

Therefore the residual local solution must achieve, for every j ∈ \(\mathcal N^{\mathrm{act}}\):

\[
\boxed{
[\chi_{m_j}(r + L s)] \ne [\chi_{m_j}(-1)]
\quad\text{in } V_{m_j}/H_j,
}
\]

or, more strongly and finally,

\[
r + L s \bmod m_j \notin T_j.
\]

The first condition is the quadratic-signature shield restricted to the active fixed-negative core; the second is exact trap avoidance.

---

## 3. Why this is a further compression

On layers with dim Q_j ≥ 2, the signature condition is strictly weaker than "escape the whole Jacobi −1 half," and therefore easier to satisfy. Parent data show that a substantial fraction of layers have this extra room.

Combined with the pullback split (only active layers matter) and the universal fiber bound (only primes in U_K remain), the residual target becomes:

> Inside a fixed small-prime coordinate ring, keep the local signatures of r+Ls off the trap cosets of a finite list of active fixed-negative layers.

That is a concrete, finite, algebraic problem for each candidate, and a uniform structural problem for the family of all directly novel candidates.

---

## 4. Relation to the parent quadratic-signature shield program

Parent `QUADRATIC-SIGNATURE-QUOTIENT.md` already poses the simultaneous full-signature shield as a Boolean problem on free Legendre bits and asks whether it has its own direct-obstruction completeness property.

Operator-02 observes that, once character-shield completeness and the pullback split are applied, the simultaneous signature problem that still matters is **only** the one over layers in \(\mathcal N^{\mathrm{act}}\), with free bits restricted to residual kernel primes. That is a drastically smaller Boolean system than the original simultaneous shield over all earlier layers.

---

## 5. Diamond statement

\[
\boxed{
\begin{array}{c}
\text{Residual DSC-P node (Class C)}\\
=\\
\text{find residual-kernel } s \text{ such that for every } j\in\mathcal N^{\mathrm{act}}_{k,r},\\
[\chi_{m_j}(r+Ls)] \ne [\chi_{m_j}(-1)] \text{ in } Q_j
\text{ (equivalently } r+Ls \notin T_j\text{).}
\end{array}
}
\]

This is the sharpest formulation of the open node that Operator-02 can write from the full set of parent theorems plus the pullback-split observation.

---

## 6. Boundaries

Not claimed: that the signature condition is always achievable on residual kernels.  
Not claimed: completeness of the full-signature shield.  
Not claimed: DSC-P.  
Parent priority for the coset theorem remains absolute.
