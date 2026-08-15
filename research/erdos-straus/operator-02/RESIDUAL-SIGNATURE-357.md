# Residual Signature {3,5,11,13,17,19,23} — Operator-02 Structural Notes

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** structural examination of the second dominant residual fiber-kernel signature  
**Claim boundary:** inherits all parent claim boundaries. Diagnostic observations remain diagnostic. No universal solvability claim is made.

This note examines the residual signature

\[
\{3,5,11,13,17,19,23\}
\]

reported in the parent diagnostic sample as the other overwhelmingly dominant nonempty form after fiber peeling (see parent `FIBER-SHADOW-KERNEL.md`). All statements stay inside the arithmetic already present in the parent documents.

---

## 1. Size and arithmetic profile

Seven distinct primes, all ≤ 23, all odd. The set is exactly the odd primes up to 23 except 7:

\[
\{3,5,11,13,17,19,23\} = \{p \text{ prime}: 3 \le p \le 23\} \setminus \{7\}.
\]

The systematic absence of 7 inside this dominant signature is itself a structural observation worth recording. It suggests that, in the cases that produce this large residual, the prime 7 is still being peeled by the fiber-load criterion while the other small primes are not.

All seven primes are ≡ 1 or 3 mod 4; the subset congruent to 3 mod 4 is

\[
\{3,11,13,19,23\}.
\]

These five primes are the ones that can contribute nontrivial Jacobi factors (−1/p) = −1 and therefore participate most directly in character-shield linear equations.

---

## 2. Relation to the smaller signature {3,11,13}

The smaller dominant signature is a proper subset of the larger one:

\[
\{3,11,13\} \subset \{3,5,11,13,17,19,23\}.
\]

This raises a natural structural question (not answered here):

> Are instances of the large signature simply cases in which additional small primes (5,17,19,23) failed to peel, while the core obstruction still lives on the {3,11,13} subsystem?

If so, solvability results obtained for {3,11,13} might lift, under additional local conditions, to the larger signature. If not, the large signature may represent a genuinely different residual geometry.

---

## 3. Local modulus product

The product of the seven primes is

\[
3 \cdot 5 \cdot 11 \cdot 13 \cdot 17 \cdot 19 \cdot 23 = 23\,391\,465.
\]

Any uniform local survivor for this signature would be a single residue class modulo this product (or a divisor of it after accounting for the exact residual powers). The modulus is large enough that exhaustive search is feasible for a fixed residual system but not for a uniform statement across all candidates; any uniform survivor would have to be derived arithmetically rather than by brute force over the full product.

---

## 4. Selector and basepoint questions

The same questions posed for {3,11,13} apply, with higher expected difficulty:

1. Does a canonical local assignment (all-ones, or all residues 1 where admissible) already solve every residual constraint for instances of this signature?
2. What is the distribution of the smallest absolute selector that works when the canonical assignment fails?
3. Does the failure set of the character shield correlate with the appearance of the larger signature?

Because the parent small-selector menu is bounded by B = 64, any instance of this signature that requires a selector outside that range would be a clean falsification of the bounded-selector hypothesis for this residual form, without affecting the status of DSC-P itself.

---

## 5. What is not claimed

- No claim that the large signature is the maximal residual that can appear.
- No claim that 7 is universally peelable while the other primes in the set are not.
- No claim of a uniform local survivor modulo the product of the seven primes.

All stronger statements remain open.

---

## 6. Coupling and next micro-step

When primary fiber-kernel output is frozen, extract the multiplicity of this exact signature (and of its power-extensions) and compare the character-shield consistency rate against the rate observed for the smaller signature {3,11,13}. That comparison will be recorded in a later Operator-02 census note.
