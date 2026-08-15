# q = 17 Partial Classification

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** partial theorem + finite residual  
**Type:** THEOREM CANDIDATE (partially proved)  
**Files:** `ANCESTRY-Q17-RESULTS.md`, `ANCESTRY-Q17-ODD-J-LEMMA.md`

---

## Proved statements

1. **Prime child ⇒ shadow** (parent, all q ≡ 1 mod 4).
2. **K = 2p ⇒ shadow** when 2|j and p = (17j−4)/2 is an odd prime (divisor residues → {1,2,j/2,j}).
3. **K = 4p ⇒ shadow** when 4|j and p = (17j−4)/4 is an odd prime (residues → {1,2,4,j/4,j/2,j}).
4. **(j,K) = (4,64) ⇒ shadow** (finite explicit check).
5. **Odd j + composite K ⇒ no shadow** (`ANCESTRY-Q17-ODD-J-LEMMA.md`).

---

## Finite residual (even j)

Through K ≤ 80,000 every even-j composite full shadow is one of:

- K = 2p,
- K = 4p,
- (j,K) = (4,64).

No example with:
- odd composite factor of K;
- v₂(K) ∈ {3,4,5} or v₂(K) ≥ 7;
- v₂(K) = 6 except K = 64.

---

## Open for full classification

Prove that if j is even, K = 17j−4 is composite, and K is not of the form 2p or 4p and not equal to 64, then full unrestricted shadowing fails.

Suggested split:

- v₂(K) = 0: impossible for even j (K even).
- v₂(K) = 1: reduce to N = K/2; if N composite, find escaping prime factor (parallel to q=9/q=13).
- v₂(K) = 2: reduce to N = K/4; if N composite, same.
- v₂(K) ≥ 3: show only (4,64) works (dyadic residual analysis, parallel to q=9 power-of-two residual).

---

## Claim boundary

Odd-j half is theorem-grade. Full unrestricted classification awaits the even-j residual analysis. No DSC-P claim.
