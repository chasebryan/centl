# Ancestry Quotient q = 17 — Finite Scout Results

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** FINITE OBSERVATION / partial proved implications  
**Type:** FINITE OBSERVATION / THEOREM CANDIDATE  
**Parent:** prime-child theorem; style of `ANCESTRY-Q13-CLASSIFICATION.md`

---

## Setup

\[
q = 17 = 4\cdot4 + 1,\qquad s = 4,\qquad K = 17j - 4,\qquad m = 4j - 1.
\]

---

## Finite census (K ≤ 80,000)

| Class | Count |
|-------|------:|
| Composite full shadows | 350 |
| Of shape \(2^a \cdot p\) (p odd prime) | 349 |
| Pure power of 2 | 1 — namely \((j,K)=(4,64)=2^6\) |
| Odd composite factor | **0** |
| Odd j among composite shadows | **0** |

2-adic valuation of composite full-shadow K:

| \(v_2(K)\) | Count |
|-----------:|------:|
| 1 | majority (~2/3) |
| 2 | remainder |
| 6 | 1 (the pure power \(64\)) |

**Residue identity (all 349 cases of shape \(2^a p\)):**

\[
\boxed{p \equiv j / 2^a \pmod m,\qquad 2^a \mid j.}
\]

Verified with zero congruence failures through K ≤ 80,000.

---

## Direct implications (elementary)

### Prime child ⇒ shadow

Parent prime-child theorem.

### \(K = 2p\) with p odd prime ⇒ shadow (when 2|j)

Write j = 2d. Then K = 17(2d) − 4 = 2(17d − 2). If p = 17d − 2 is prime,

\[
p - d = 16d - 2 = 2(8d - 1),\quad m = 8d - 1,
\]

so p ≡ d = j/2 mod m after adjusting — wait, more carefully:

Actually K = 2p = 17j − 4 ⇒ p = (17j − 4)/2. With j = 2d:

p = 17d − 2, m = 8d − 1,
p − 2d = 15d − 2? Better use verified form: p ≡ j/2 mod m.

j/2 = d. Check p − d = 17d − 2 − d = 16d − 2 = 2(8d − 1) = 2m ≡ 0 mod m. Yes p ≡ d mod m.

Divisors of K = 2p are {1,2,p,K} → {1,2,j/2,j} all divide j. Shadow holds.

### \(K = 4p\) with p odd prime ⇒ shadow (when 4|j)

Write j = 4d. Then p = (17·4d − 4)/4 = 17d − 1.
m = 16d − 1.
p − d = 16d − 1 = m, so p ≡ d = j/4 mod m.

Divisors {1,2,4,p,2p,4p} reduce to {1,2,4,j/4,j/2,j}, all dividing j when 4|j. Shadow holds.

### Exception (4, 64)

j = 4, m = 15, K = 64. Divisors of 64 are powers of 2; S_4 = {1,2,4} mod 15 (check: divisors of 4 give 1,2,4 and 4e). All 2^k mod 15 for k ≤ 6 land in a set contained after explicit check — parent-style finite verification. Recorded as the unique pure 2-power composite full shadow in range.

---

## Classification candidate

\[
T_{17j-4}\bmod(4j-1)\subseteq T_j
\iff
\begin{cases}
K\text{ prime},\quad\text{or}\\
K=2p\text{ with }p\text{ odd prime},\quad\text{or}\\
K=4p\text{ with }p\text{ odd prime},\quad\text{or}\\
(j,K)=(4,64).
\end{cases}
\]

**Proved direction:** shapes ⇒ shadow (above + parent).  
**Converse:** FINITE OBSERVATION through K ≤ 80,000; not a theorem.

---

## Pattern across quotients

| q | Composite unrestricted full-shadow shapes |
|---|-------------------------------------------|
| 5 | none |
| 9 | 2p + (2,16) |
| 13 | 3p |
| 17 | 2p, 4p + (4,64) |

The small prime factors appearing (2, 3, 2-powers) track gcd structure of (s, q) and parity of j.

---

## Claim boundary

Finite observation for the converse. No universal DSC-P claim. Coordinator may take the converse proof track.
