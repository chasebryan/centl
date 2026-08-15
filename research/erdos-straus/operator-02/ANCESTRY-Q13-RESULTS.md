# Ancestry q = 13 — Finite Scout Results (updated)

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** FINITE OBSERVATION + partial proved lemmas  
**Type:** FINITE OBSERVATION / THEOREM CANDIDATE  
**See also:** `ANCESTRY-Q13-ODD-J-LEMMA.md`

---

## Proved pieces

1. **Prime child ⇒ shadow** — parent prime-child theorem for every q ≡ 1 mod 4.
2. **K = 3p ⇒ shadow** — if 3|j and p = (13j−3)/3 is prime, divisors map to {1,3,j/3,j} ⊆ S_j.
3. **Odd j + composite K ⇒ no shadow** — Operator-02 lemma (`ANCESTRY-Q13-ODD-J-LEMMA.md`).

---

## Finite observation (K ≤ 30,000)

- 100 composite full shadows; **all** of shape K = 3p.
- **Zero** composite full shadows with j even and 3 ∤ j.
- **Zero** other factorization shapes.

---

## Classification candidate

\[
T_{13j-3}\bmod(4j-1)\subseteq T_j
\iff
K\text{ prime or }K=3p\text{ with }p\text{ prime}.
\]

**Open:** converse when j is even — exclude composite K not of the form 3p.

Suggested case split (parallel to q = 9):

- 3 ∤ j: show some prime factor of K lands outside S_j;
- 3|j but (13j−3)/3 is composite: show a proper factor of N = 13d−1 escapes S_j, or a power-of-three residual is unique/impossible except known shapes.

---

## Claim boundary

Finite observation is not a theorem. Odd-j lemma is proved. Full classification awaits the even-j converse.
