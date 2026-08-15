# Atom-to-Shadow Census Design

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** census / falsification design  
**Type:** FORMULATION  
**Parent directive:** O2-D / O2-E  
**Parent sources:** `../DEFECT-ZERO-SUM-ATOMS.md`, `../MULTIPLICATIVE-DEFECT-QUOTIENT.md`, `../CLASS-C-RESIDUAL-CORE.md`

---

## 1. Question

> Is every multiplicatively neutral atom whose neutral divisor residue misses the ancestor exact two-box trap already removed by another earlier layer?

If yes universally, multiplicative defect atoms that fail exact ancestor membership are still compatible with DSC-P via other direct shadows.  
If no, an explicit atom is a concrete residual exact-obstruction packet.

---

## 2. Objects

For squarefree ancestor a, d = 4a−1, M_a = K_a/D_a:

1. Take a square lift j = (1 + d s²)/4.
2. Form defect sequence S(j/a); decompose into minimal zero-product atoms A_i.
3. Each atom → divisor e_i | j with e_i mod d ∈ D_a.
4. Test whether −e_i or −4e_i lies in T_a (exact two-box membership), not merely in −D_a.
5. If miss T_a: search all layers ℓ < j (or ℓ < depth of interest) for direct shadow / trap hit explaining the residue; record first explaining layer if any.

---

## 3. Census fields

| Field | Meaning |
|-------|---------|
| a, d, ι(a), structure of M_a | ancestor |
| s, j | lift |
| atom type (length, multiset of classes) | |
| e_i | neutral divisor |
| e_i mod d ∈ D_a? | must be true |
| e_i mod d in image of two-box? | exact trap test |
| if miss: first earlier layer explaining | or NONE |

---

## 4. Outcomes

| Outcome | Interpretation |
|---------|----------------|
| Always exact trap | atoms never leave the two-box; stronger than coset neutrality |
| Miss trap but always earlier-shadowed | DSC-compatible residual; supports atom-to-shadow route |
| Miss trap and no earlier shadow | **hard residual packet** — freeze immediately as certificate |

---

## 5. Priority ancestors

Start with small ι(a) and small D(M_a):

- cyclic M_a of small order;
- M_a trivial (ι(a)=2) — should have no nontrivial atoms;
- ancestors appearing most often in k≤1500 character residuals.

---

## 6. Claim boundary

Design only. No census counts claimed. No theorem claimed.  
A single certified NONE on step 5 is a FINITE OBSERVATION of high value, not a DSC-P counterexample by itself.
