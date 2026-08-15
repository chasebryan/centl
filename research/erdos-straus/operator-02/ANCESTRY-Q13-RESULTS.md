# Ancestry q = 13 — Finite Scout Results

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** FINITE OBSERVATION  
**Type:** FINITE OBSERVATION / THEOREM CANDIDATE (conjectural classification)  
**Parent directive:** O2-3  
**Parent theorems used:** prime-child theorem (`../PRIME-CHILD-SHADOWS.md`); normalized-divisor criterion as in `../QUOTIENT-9-RIGIDITY.md`

---

## 1. Scope

Unrestricted full-shadow test for

\[
K = 13j - 3,\qquad m = 4j - 1,
\]

via the criterion: every divisor e|K has e mod m ∈ S_j = −T_j.

Ranges:

- K ≤ 5,000 (initial)
- K ≤ 30,000 (extension)

---

## 2. Counts through K ≤ 30,000

| Class | Count |
|-------|------:|
| Prime children (shadowed; parent theorem) | many (55 through K≤5000) |
| Composite, no full shadow | majority |
| **Composite full shadows** | **100** through K≤30,000 |
| Odd j among composite full shadows | **0** |
| Composite full shadows not of shape 3·p | **0** |

---

## 3. Composite full-shadow shape

Every composite full shadow found has factorization

\[
\boxed{K = 3p\quad\text{with }p\text{ prime}.}
\]

Necessarily 3|j. Write j = 3d. Then

\[
K = 13(3d) - 3 = 3(13d - 1),
\]

so p = 13d − 1 when that quantity is prime.

**Residue identity:**

\[
m = 4j - 1 = 12d - 1,
\qquad
p - d = 12d - 1 = m,
\]

hence

\[
\boxed{p \equiv d = j/3 \pmod m.}
\]

Divisors of K = 3p are {1, 3, p, K}. Modulo m they become

\[
\{1,\ 3,\ j/3,\ j\},
\]

all of which divide j when 3|j. Therefore all lie in S_j, and full unrestricted shadowing holds — **same mechanism as the q = 9 twice-prime family**, with 3 in place of 2.

---

## 4. Theorem candidate (unproved converse)

**Candidate classification for unrestricted q = 13:**

\[
\boxed{
T_{13j-3}\bmod(4j-1)\subseteq T_j
\iff
\begin{cases}
13j-3\text{ is prime},\quad\text{or}\\
(13j-3)/3\text{ is prime (hence }3\mid j\text{).}
\end{cases}
}
\]

**Direction ⇒ (shadow from shape):** proved for prime children by parent theorem; proved for K = 3p by the divisor residue argument above.

**Direction ⇐ (only these shapes):** **FINITE OBSERVATION** through K ≤ 30,000 with zero exceptions; **not a theorem**. Converse requires a q = 9–style case analysis excluding other factorizations.

---

## 5. Odd j

When j is odd, K = 13j − 3 is even, so 2|K. Through K ≤ 30,000 no odd-j composite full shadow appears. Provisional explanation: 2 ∉ S_j for odd j (same as q = 5 Case 1), so the divisor 2 blocks full shadowing. Not promoted until written as a lemma with full proof.

---

## 6. Comparison table

| q | Composite unrestricted full-shadow shapes (known/observed) |
|---|-------------------------------------------------------------|
| 5 | none |
| 9 | 2p, and exception (2,16) |
| 13 | **3p only** (observed through K≤30k; converse open) |

---

## 7. Mixed-box side result (same session)

All 15 parent mixed-only failures through j ≤ 20,000 have **minimal failing support = 2**. No support-3 counterexample inside the parent published list. Axis_ok confirmed for each. Still not a theorem that support ≤ 2 always.

---

## 8. Claim boundary

- Finite observation only for the converse.
- Prime-child direction is parent theorem.
- 3p direction is elementary once shape is assumed.
- No claim of universal DSC-P or unrestricted classification theorem until the converse is proved.
- Coordinator promotion required before any parent-document integration.
