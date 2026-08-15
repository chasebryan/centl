# C1: Single-Active Layer — Operator-02 Independent Attack Notes

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** THEOREM CANDIDATE design / independent formulation attack  
**Type:** THEOREM CANDIDATE (unproved)  
**Parent references:** `../CLASS-C-C1-SINGLE-ACTIVE.md`, `../CLASS-C-RESIDUAL-CORE.md`, Operator-02 diamonds (with signature-coset correction)

---

## 1. Target statement (candidate)

Let a directly novel candidate satisfy

\[
|\mathcal N^{\mathrm{act}}_{k,r}| = 1,
\]

with unique active fixed-negative layer j₀.

**Candidate claim:** there exists a residual parameter s such that

\[
r + L s \bmod m_{j_0} \notin T_{j_0},
\]

the global character-shield extension for all non-fixed-negative layers is realized, and reducedness holds on residual primes — hence a reduced avoiding class exists.

This would be an infinite special case of DSC-P, not a finite statistic.

---

## 2. What is already proved (parent)

1. Character-shield completeness: free signs can make every non-fixed-negative layer Jacobi-positive iff no fixed-only Jacobi-negative obstruction remains outside N.
2. Inactive fixed-negative layers (q_j = 1) are exact-safe by direct novelty.
3. Direct novelty at j₀ ⇒ the pullback forbidden set R_{j₀} is a **proper** subset of Z/q_{j₀}Z (no full direct shadow).
4. Fiber peeling and reverse extension construct a global reduced class once a local residual solution exists.
5. Exact traps satisfy T ⊆ −D ⊆ signature-coset preimage ⊆ Jacobi −1 (nested sufficient shields; exact condition is T).

---

## 3. The open local lemma (Step 5 of parent C1 route)

Need:

> The complementary set of residues mod q_{j₀} that avoid R_{j₀}, after restriction by residual reducedness and by any character/sign constraints on the prime-power coordinates of q_{j₀}, is still nonempty.

Equivalently: the two-box / multiplicative structure of T_{j₀} together with direct novelty prevents the constrained choices from exhausting the complement of R_{j₀}.

---

## 4. Operator-02 attack angles

### Angle A — proper forbidden set has positive density

Since R_{j₀} ≠ Z/q_{j₀}Z, there is at least one safe residue class mod q_{j₀}. Reducedness forbids at most one class mod each residual prime. If q_{j₀} is a product of residual primes already accounted for by Class A/B witnesses, a Chinese-remainder argument may produce a simultaneous safe+reduced residue unless the forbidden set is adversarially aligned with the reducedness hyperplanes.

**Falsifier:** a C1 candidate where every residue outside R_{j₀} fails reducedness on some residual prime.

### Angle B — two-box cannot fill the parameter line under direct novelty

Inside −D_{j₀} the traps are two exponent boxes. Pullback to q_{j₀} inherits structure. Direct novelty says the boxes do not cover the full progression. After fixing character signs on free coordinates, the remaining freedom is p-adic lifts on valuation-excess primes — Class A (higher powers of fixed primes) and Class B (even-powered free primes from square lifts).

**Falsifier:** a C1 candidate where after all character-compatible lifts, every remaining residue hits T_{j₀}.

### Angle C — single-tower case

If the unique active layer belongs to a single negative square-lift tower with base a, parent tower coherence applies. Escape is a p-adic problem on the lift parameter. Parent median negative-tower count is 1, so C1 may often coincide with single-tower residuals.

---

## 5. Census requirements specific to C1

When CLASS-C-CENSUS-K1500 is populated, extract the subpopulation `|N_act|=1` and record:

- distribution of q_{j₀} factorizations;
- Class A vs B;
- whether fiber kernel is empty (already solved by peeling alone);
- residual signatures when nonempty;
- whether all residual primes are sourced by the unique active layer;
- selector radius.

Zero exceptions in that subpopulation is FINITE OBSERVATION only.

---

## 6. Claim boundary

No proof is claimed. No finite census is claimed beyond parent published aggregates.  
This note is an independent formulation attack aligned with the Coordinator C1 design.
