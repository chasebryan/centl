# Ancestry Quotient q = 13 — Operator-02 Scout

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** scout / finite pattern search design  
**Type:** FORMULATION / FINITE OBSERVATION design  
**Parent directive:** O2-3  
**Parent sources:** `../PRIME-CHILD-SHADOWS.md`, `../QUOTIENT-9-RIGIDITY.md`, `../THEORY.md`

---

## 1. Setup

Ancestry quotient q = 13 = 4·3 + 1, so s = 3:

\[
K = 13j - 3,
\qquad
4K - 1 = 13(4j - 1).
\]

Also K ≡ j mod (4j−1).

**Do not assume** the q = 9 factorization hierarchy continues.

---

## 2. What parent already proves for every q ≡ 1 mod 4

**Prime-child theorem:** if K is prime, then T_K mod (4j−1) ⊆ T_j.

Hence every prime K ≡ −3 ≡ 10 mod 13 gives an unrestricted full shadow edge j → K with j = (K+3)/13.

Dirichlet supplies infinitely many such primes.

---

## 3. Normalized-divisor criterion (same as q = 9)

Let m = 4j−1 and S_j = −T_j = {e, 4e mod m : e|j} (inverse-closed).

For the pair (j, K),

\[
T_K \bmod m \subseteq T_j
\iff
e \bmod m \in S_j \quad\text{for every divisor } e \mid K.
\]

Full unrestricted shadowing is completely determined by the image of the divisor lattice of K in Z/mZ.

---

## 4. Structural differences from q = 5 and q = 9

| Quotient | Form of q | Child formula | Composite shadows (unrestricted) |
|----------|-----------|---------------|----------------------------------|
| 5 | prime | K = 5j−1 | **none** (rigidity: shadow ⇔ K prime) |
| 9 | square 3² | K = 9j−2 | prime, twice-prime, and (j,K)=(2,16) only |
| 13 | prime | K = 13j−3 | **unknown** — scout target |

Because 13 is prime (not a square), the square-lift tower mechanism is not the same as q = 9. Composite children need not follow the twice-prime pattern.

---

## 5. Scout questions

1. **Exact divisor-image criterion** — already stated in §3; implement for enumeration.
2. **Prime children** — guaranteed by parent theorem; count in finite ranges for calibration.
3. **Composite full shadows** — find all composite K = 13j−3 ≤ X such that every e|K has e mod m ∈ S_j.
4. **Factorization shapes** of those composite K (semiprime, 2p, p², pqr, …).
5. **Correlation with divisors of j** — affine shifts analogous to p ≡ j/2 mod m in the q = 9 twice-prime case.
6. **Quadratic / multiplicative explanation** — does local signature or Γ_j containment explain the composite cases, or is exact two-box required?
7. **Failure of naive classifications** — does “K prime or K = 2p” already fail at small X?

---

## 6. Finite search protocol

For j = 1, 2, … with K = 13j−3 ≤ X (suggested first X = 10⁴, then 10⁵):

1. If K is prime: record as prime-child (expected shadow = true).
2. If K is composite: compute all divisors of K; reduce mod m = 4j−1; test membership in S_j.
3. If all pass: record (j, K, factorization of K, divisor residues) as composite full-shadow candidate.
4. Independently re-verify T_K mod m ⊆ T_j by explicit trap enumeration for each recorded composite hit.

Output tables:

- composite full-shadow list with factorizations;
- histogram of Ω(K), ω(K), smallest prime factor;
- whether any composite shadow has three or more distinct prime factors.

---

## 7. First algebraic probes (before compute)

### Odd j

K = 13j−3 is even when j is odd? 13j odd, 3 odd ⇒ K even. So 2|K when j odd.

Check whether −2 ∈ T_j (equivalently 2 ∈ S_j). For odd j, 2 ∤ j; unwrapped 4d ≥ 4; wrapped endpoint 1. Same argument as q = 5 odd case may force 2 ∉ S_j, hence **no unrestricted full shadow when j is odd and K is composite and divisible by 2** — unless 2 is somehow in S_j for special j.

**Operator-02 provisional observation (not a theorem):** for odd j, K even composite ≥ 4 likely fails full shadowing via the divisor 2, analogous to q = 5 Case 1. Must be verified carefully for small j.

### Even j

Write j = 2d. Then K = 26d − 3 is odd. Composite K has an odd prime factor ℓ ≤ √K. Whether ℓ < m and ℓ ∉ S_j is the same style of argument as q = 5 Case 2 / q = 9 even case, but the relation between N and d will differ because s = 3 not 1.

Explicit identity to use:

\[
K - 13\cdot\frac{j}{\gcd(j,\cdot)} \quad \text{(derive case-by-case when searching)}.
\]

---

## 8. Claim boundary

- No classification theorem claimed for q = 13.
- A finite pattern is not a theorem.
- Prime-child infinite family is parent theorem, not Operator-02 novelty.
- Provisional odd-j observation requires verification before promotion.

---

## 9. Deliverable when compute runs

`ANCESTRY-Q13-RESULTS.md` under operator-02/ only, with exact X, composite list, factorizations, and independent trap verification hashes if available.
