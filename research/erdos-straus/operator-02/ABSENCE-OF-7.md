# Absence of 7 from Residual Fiber Kernels — Operator-02 Notes

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** structural investigation of the strongest residual regularity in the parent k ≤ 1200 census  
**Claim boundary:** the absence of 7 is a parent finite observation (`../FIBER-SELECTOR-K1200.md`). This note does not prove that 7 is always peelable. No universal claim is made.

---

## 1. The regularity

In the complete parent residual-signature census through k ≤ 1200, every nonempty residual fiber kernel is a subset of

\[
\{3,5,11,13,17,19,23\}.
\]

The prime **7 is absent from every nonempty residual signature**, including all 15,426 nonempty kernels.

By contrast, the parent universal trap-fiber bound through k ≤ 1200 still lists 7 among the primes that are not automatically peelable:

\[
U_{1200} = \{3,5,7,11,13,17,19,23,29,31,37,41\}.
\]

So 7 survives the candidate-independent bound but is eliminated by candidate-specific fiber peeling in every observed case through this range.

---

## 2. Why 7 is special among small primes

### Arithmetic of 4j − 1 divisible by 7

\[
4j - 1 \equiv 0 \pmod 7 \iff j \equiv 2 \pmod 7.
\]

Layers that can impose 7-constraints occur at j = 2, 9, 16, 23, … .

### Trap structure at those layers

For such j, m_j is divisible by 7. The trap set T_j projects onto residues mod 7. The fiber width f_{j,7} and the contribution β_{j,7} to the universal load are determined by how many traps collide in each fiber away from the 7-coordinate.

Parent trap-fiber bound already computes that the universal load F_7(K) stays ≥ 1 through the tested ranges (hence 7 ∈ U_K). Candidate-specific loads are smaller because:

- gcd reductions with L remove some occurrences;
- fiber widths are often strictly less than |R_j|;
- iterative peeling removes constraints after other coordinates peel.

The systematic candidate-specific elimination of 7 suggests that one or more of these effects is strong enough, for every directly novel candidate through k ≤ 1200, to drive Λ_7^* < 1.

---

## 3. Hypotheses for later testing (not claims)

**H1 — L always absorbs enough 7-power.**  
For admissible hard-class candidates, L = lcm(840, m_k) is always divisible by 7 (since 7 | 840). Higher 7-powers in earlier m_j may still produce residual constraints, but the base factor is always present in L, changing the reducedness cost and the gcd pattern relative to primes that do not divide 840.

**H2 — Trap-fiber collisions mod 7 are systematically high.**  
The maps e ↦ −e, e ↦ −4e may produce more collisions in 7-fibers than in fibers of 3, 11, 13, etc., lowering f_{j,7}/7^{a} enough that the sum stays < 1 after candidate-specific reductions.

**H3 — Direct novelty correlates with peelability of 7.**  
Candidates that would retain 7 in the residual kernel might be exactly those that are directly shadowed (hence excluded from the novel set on which residual kernels are computed).

These hypotheses are recorded for primary census correlation and for pure-arithmetic attack on κ_{j,7^a}; none is asserted.

---

## 4. Contrast with 3, 11, 13

The dominant residual signature {3,11,13} consists of three primes all ≡ 3 mod 4, none dividing 840 except 3.

- 3 divides 840, yet appears in residual kernels frequently.
- 11 and 13 do not divide 840 and appear in almost every nonempty residual.

So divisibility by 840 alone cannot explain the absence of 7 (or else 3 would also be absent). The distinction must involve the trap-fiber geometry or the interaction of 7 with the hard-class residue system more subtly than mere presence in 840.

---

## 5. What would explain the regularity

A theorem of the form

\[
\text{for every admissible directly novel candidate through depth } K,\quad \Lambda_7^* < 1
\]

(with K = 1200 or larger), proved from trap-fiber bounds and admissibility rather than case-by-case peeling, would convert the observation into a structural fact and shrink U_K by removing 7.

Operator-02 flags this as a high-value finite theorem target subordinate to the parent trap-fiber program.

---

## 6. Boundaries

Absence of 7 is finite observation only. No claim that 7 never appears in residual kernels for k > 1200. No claim that H1–H3 are true.
