# Residual Signature {3,11,13} — Operator-02 Structural Notes

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** structural examination of a dominant residual fiber-kernel signature  
**Claim boundary:** inherits all parent claim boundaries. Diagnostic observations remain diagnostic. No universal solvability claim is made.

This note examines only the residual signature `{3,11,13}` that appears as one of the two overwhelmingly dominant nonempty fiber kernels in the published diagnostic sample (see parent `FIBER-SHADOW-KERNEL.md`). All statements are relative to the arithmetic already present in the parent theory documents.

---

## 1. Why this signature matters

In the published diagnostic sample of 5 000 candidates drawn from the k ≤ 1000 corpus, residual kernels of size 3 were frequent, and `{3,11,13}` is reported as one of the two dominant nonempty forms. After exact fiber peeling has removed every larger prime, the remaining obstruction (when nonempty) often collapses precisely onto these three primes.

A classification or local solvability theorem for this signature would therefore cover a large fraction of the remaining hard cases once the complete fiber-kernel census is frozen by the primary automation.

---

## 2. Arithmetic features of the three primes

All three primes are congruent to 3 mod 4:

\[
3 \equiv 11 \equiv 13 \equiv 3 \pmod{4}.
\]

Consequently each can appear as a factor of moduli of the form 4j−1. In particular:

- 3 divides 4j−1 precisely when j ≡ 1 mod 3,
- 11 divides 4j−1 precisely when j ≡ 3 mod 11,
- 13 divides 4j−1 precisely when j ≡ 10 mod 13.

These arithmetic progressions determine which earlier layers can contribute constraints that survive onto the residual coordinates 3, 11 and 13.

Because the fiber-peeling theorem has already eliminated every larger prime, every residual constraint that remains must be supported entirely on the product of powers of these three primes (after the gcd reductions that produce the q_j).

---

## 3. Local constraint shape (Operator-02 reading)

After fiber peeling, the residual system on {3,11,13} consists of a finite collection of forbidden residue conditions of the form

\[
s \bmod q \in R,
\]

where each q is of the form 3^a · 11^b · 13^c with a,b,c small (determined by the valuations present in the original pullbacks). Most such constraints are expected to be unary or binary once the higher primes have been removed; the parent odd-covering bridge already notes a concentration of unary and binary support even before peeling.

The reducedness conditions for the three primes (when they do not divide L) each forbid a single residue class modulo the prime. These are linear conditions over the local rings and are already incorporated into the augmented fiber load Λ_p^* used by the parent theorem.

---

## 4. Basepoint and selector questions specific to this signature

The parent small-selector hypothesis tests a fixed menu of ordinary integers against residual kernels. For the concrete signature {3,11,13} the natural first questions are:

1. Does the local assignment that sets every residual prime-power coordinate to the residue 1 (when admissible) already avoid all residual forbidden sets?
2. If not, which of the small selectors {0, ±1, ±2, …} first succeeds, and is that selector stable across many instances of the same signature?
3. Is there a single residue class modulo 3·11·13 = 429 that simultaneously satisfies every residual constraint arising from any candidate whose fiber kernel is exactly {3,11,13}?

A positive answer to (3) would be especially strong: it would mean that the residual system of this signature is not merely solvable case-by-case but is governed by a uniform local survivor.

These questions are posed for future verification against frozen primary output; they are not answered here.

---

## 5. Interaction with the character shield

Because 3, 11 and 13 are all ≡ 3 mod 4, each contributes a nontrivial Jacobi factor (−1/p) = −1. When an earlier modulus m_j is divisible by an odd power of one of these primes, the character-shield linear equation over F₂ must account for that sign. Inconsistency of the global character-shield system can therefore force the residual constraints onto the Jacobi −1 side of one or more of these primes, which is precisely the side on which the traps themselves live.

Thus the hardest instances of the {3,11,13} kernel are expected to be those for which the character shield is already inconsistent; the residual exact-residue constraints then become unavoidable.

---

## 6. What is not claimed

- No claim is made that every residual kernel of signature {3,11,13} is solvable by a fixed selector.
- No claim is made that the signature is closed under any particular operation or that it is the only size-3 residual that can appear.
- No absolute bound independent of k is asserted.

All such statements remain open and belong to the primary theorem program or to later Operator-02 notes written after complete census data are available.

---

## 7. Next micro-step inside this signature

When primary fiber-kernel output becomes available, extract every candidate whose residual prime set is exactly {3,11,13} (or a power-extension of it) and record:

- the precise residual moduli and forbidden sets,
- whether the all-ones local assignment succeeds,
- the smallest absolute selector that succeeds,
- whether the character-shield system was consistent or inconsistent for that candidate.

That census will be recorded in a subsequent Operator-02 file.
