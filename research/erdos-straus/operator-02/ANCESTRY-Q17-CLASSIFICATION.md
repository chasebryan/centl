# Quotient-17 Ancestry Shadow Classification

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** PROVED  
**Type:** proved theorem (Operator-02 lane; Coordinator integration pending)  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Not DSC-P, López, or Erdős-Straus. Hard-class shadows may be larger.

Parent: prime-child theorem. Parallel to `ANCESTRY-Q13-CLASSIFICATION.md` and parent `../QUOTIENT-9-RIGIDITY.md`.

---

## Theorem

Let j ≥ 1 and set

\[
K = 17j - 4,\qquad m = 4j - 1.
\]

Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
\begin{cases}
K \text{ is prime},\quad\text{or}\\
K = 2p \text{ with } p \text{ an odd prime},\quad\text{or}\\
K = 4p \text{ with } p \text{ an odd prime},\quad\text{or}\\
(j,K) = (4,64).
\end{cases}
}
\]

---

## Normalized criterion

\[
S_j = -T_j = \{e,\,4e \bmod m : e \mid j\}.
\]

Full shadowing ⇔ every divisor of K has residue in S_j.

---

## Direct implications

### Prime child

Parent prime-child theorem.

### K = 2p

Requires 2|j. Write j = 2d, p = 17d − 2. Then p ≡ d = j/2 mod m, and divisors {1,2,p,K} → {1,2,j/2,j} ⊆ S_j.

### K = 4p

Requires 4|j. Write j = 4d, p = 17d − 1. Then p ≡ d = j/4 mod m, and divisors map into {1,2,4,j/4,j/2,j} ⊆ S_j.

### (4, 64)

j = 4, m = 15, K = 64. Divisors of 64 are powers of 2. Explicitly S_4 = {1,2,4,8} mod 15, and every 2^k mod 15 lands in S_4.

---

## Converse

Assume full shadowing. Show one of the four alternatives holds.

### Odd j

**Lemma.** If j is odd and K is composite, shadowing fails.

*Proof.* gcd(j,K) = gcd(j,4) = 1. K is odd. Least prime factor ℓ satisfies 1 < ℓ ≤ √K < m for j ≥ 2 (since m² − K = 16j² − 25j + 5 > 0 for j ≥ 2; j = 1 gives K = 13 prime). ℓ odd, ℓ ∤ j ⇒ ℓ ∉ S_j. QED.

Thus for odd j, shadowing ⇒ K prime.

### Even j, v₂(K) = 1

Write j = 2d, K = 2N, N = 17d − 2 odd. If N is prime we have K = 2p. Assume N composite. Least prime factor ℓ of N is odd, ℓ ≤ √N < m (64d² − 33d + 3 > 0 for d ≥ 1). Since N is odd, gcd(N,d) = 1, so ℓ ∤ j. Hence ℓ ∉ S_j. Shadowing fails.

### Even j, v₂(K) = 2

Write K = 4N with N odd. Then j = 4d for some d, and N = 17d − 1. (Exact v₂ = 2 forces N odd.) If N is prime we have K = 4p. Assume N composite. Least prime factor ℓ of N is odd, ℓ ≤ √N < m, and gcd(N,d) = 1, so ℓ ∤ j. Hence ℓ ∉ S_j.

### Even j, v₂(K) ≥ 3

**Structural fact.** K = 17j − 4 divisible by 8 forces j ≡ 4 mod 8, so j = 8t + 4 = 4(2t+1) and **v₂(j) = 2 exactly**.

#### Subcase v₂(K) ≥ 5

Then 32 | K. For j = 4 one has K = 64, already listed. For j > 4 one has m = 4j − 1 > 32, so the divisor 32 reduces to the integer 32.

Claim: 32 ∉ S_j when v₂(j) = 2.
- 32 ∤ j;
- 32 = 4e ⇒ e = 8, but 8 ∤ j;
- if 4e ≡ 32 mod m with e ≤ j and 4e ≥ m, then 4e = 32 + m = 4j + 31, not divisible by 4 on the right-hand side (31 ≡ 3 mod 4) — impossible.

Thus 32 ∉ S_j and shadowing fails for all j > 4 with v₂(K) ≥ 5.

#### Subcase v₂(K) = 3

Write K = 8N with N odd > 1 (K ≥ 8·3). Here t is odd in j = 8t+4, and N = 17t + 8.

Then N > j (17t+8 > 8t+4 for t ≥ 0) and N < m (17t+8 < 32t+15). The divisor N of K reduces to N.

N is odd, so N ≠ 4e for any integer e. All plain divisors e of j satisfy e ≤ j < N, so N ≠ e. Hence N ∉ S_j. Shadowing fails.

#### Subcase v₂(K) = 4

Write K = 16N with N odd > 1. One has j = 16u + 4 for some u ≥ 1 and N = 17u + 4.

Then N − j = u ≥ 1, so N > j, and N < m. Same argument: N odd ⇒ N ≠ 4e; N > j ⇒ N ≠ e for e|j. Hence N ∉ S_j. Shadowing fails.

---

## Conclusion

Every case in which shadowing holds is one of: K prime; K = 2p; K = 4p; or (j,K) = (4,64). QED.

---

## Infinite families

- Primes K ≡ −4 ≡ 13 mod 17 (Dirichlet).
- K = 2p with p = 17d − 2 prime (j = 2d).
- K = 4p with p = 17d − 1 prime (j = 4d).

---

## Comparison

| q | Unrestricted composite full-shadow shapes |
|---|-------------------------------------------|
| 5 | none |
| 9 | 2p + (2,16) |
| 13 | 3p |
| **17** | **2p, 4p + (4,64)** |

---

## Prior-art boundary

Elementary congruences, Dirichlet, and inverse-closed divisor sets are classical. López Type A/B is prior art. Contribution: exact unrestricted q=17 classification in the C_AB shadow framework.

**Coordinator intake requested.** No parent files modified.
