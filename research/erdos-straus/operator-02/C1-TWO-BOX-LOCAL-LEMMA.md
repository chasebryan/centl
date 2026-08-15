# C1 Local Lemma Draft — Two-Box and Proper Pullback

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** THEOREM CANDIDATE draft (unproved)  
**Type:** THEOREM CANDIDATE  
**Parent references:** `../CLASS-C-C1-SINGLE-ACTIVE.md`, `../MIXED-BOX-OBSTRUCTION.md`, `../MULTIPLICATIVE-TRAP-QUOTIENT.md`  
**Correction:** signature-coset used only as sufficient shield; exact condition is ∉ T_j

---

## 1. Setup

Directly novel candidate with |N^{act}| = 1, unique active layer j₀, pullback modulus q = q_{j₀} > 1, forbidden set R ⊂ Z/qZ with R ≠ Z/qZ (direct novelty).

Need a residue s mod q with s ∉ R, reducedness on residual primes, and compatibility with the character extension on non-fixed-negative layers.

---

## 2. Candidate local lemma (unproved)

**Lemma candidate C1-LB.**  
Under the above hypotheses, the set of residues mod q that are:

1. outside R,
2. reduced at every residual prime dividing q (or required by residual kernel reducedness),

is nonempty.

If true, combined with parent character-shield extension and fiber reverse extension, C1 follows.

---

## 3. Why it might be true

- |R| < q, so the unconstrained complement is nonempty.
- Reducedness removes at most one class mod each residual prime p|q.
- If the number of residual primes is small and q is not covered by the union of R with the reducedness hyperplanes, a CRT survivor exists.
- Two-box structure of T_{j₀} constrains R: R is an affine pullback of a two-box set, not an arbitrary subset. Arbitrary covering configurations that would kill all reduced residues may be incompatible with two-box geometry.

---

## 4. Why it might fail

- Reducedness conditions could be aligned with the complement of R so that every safe trap-avoiding class is non-reduced.
- Character constraints on free signs (for other layers) might further restrict lifts of the residual coordinates of q beyond plain reducedness.
- Class B even-powered free primes in q may interact with residual kernel constraints from non-N^{act} rows (if any survive peeling) — C1 as stated assumes the unique active fixed-negative layer is the only exact residual constraint source; parent C1 falsifiers already list the case where additional sources appear.

---

## 5. Minimal falsifier design

A C1 counterexample to this lemma (not to DSC-P) would be a directly novel candidate with |N^{act}| = 1 such that every residue mod q outside R fails either reducedness or a necessary residual compatibility condition forced by the global construction.

Census field: for each C1 candidate, compute |complement of R|, number of reduced residues in the complement, and whether the independently found selector (if any) lands in that set.

---

## 6. Boundary

Lemma is **unproved**. Finite success of selectors through k ≤ 1500 is consistent with the lemma but does not prove it. No promotion requested until a proof or a sharp counterexample to the lemma is available.
