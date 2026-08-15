# Ancestry Quotient Pattern — Operator-02 Observation

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** FORMULATION / pattern from proved cases + finite scouts  
**Type:** FORMULATION (not a universal theorem)

---

## Setup

Ancestry quotient q = 4s + 1 > 1, child K = qj − s.

---

## Proved classifications

| q | s | Composite unrestricted full-shadow shapes |
|---|---|-------------------------------------------|
| 5 | 1 | none (only primes) |
| 9 | 2 | 2p + (2,16) |
| 13 | 3 | 3p |
| 17 | 4 | 2p, 4p + (4,64) |
| 21 | 5 | 5p |

---

## Finite scouts

| q | s | Observed composite shapes (bounded K) |
|---|---|----------------------------------------|
| 25 | 6 | mixed 2p, 3p, 2·3·p, … (q composite) |
| 29 | 7 | 7p only (through K≤20k) |

---

## Working pattern (conjectural)

When **q is prime** (hence s = (q−1)/4):

- If s = 1: only prime children.
- If s is an odd prime: composite shadows are exactly **s·p**.
- If s is a power of 2: composite shadows are **2^a · p** for a bounded by the 2-adic structure of s, plus possible pure power-of-2 exceptions at small j.

When **q is composite** (e.g. 9, 25): richer factorization shapes appear.

---

## Mechanism

For K = s·p with s|j, write j = s·d. Then

\[
p = qd - \frac{s(q-1)/4 + something}{...}
\]

More cleanly for the odd-prime s cases (13,21,29,…):

\[
p = q\cdot\frac{j}{s} - 1,\qquad m = 4j-1 = s\cdot\bigl(4\tfrac{j}{s}\bigr)-1,
\]

and p ≡ j/s mod m, so divisors {1,s,p,K} → {1,s,j/s,j} ⊆ S_j.

---

## Claim boundary

Pattern is a guide for proof search, not a theorem. Each q needs its own converse. q=25 (composite) is intentionally excluded from the simple rule.
