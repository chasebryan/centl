# Quotient-13 Ancestry Shadow Classification

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** PROVED  
**Type:** THEOREM CANDIDATE promoted to proved (Operator-02 lane; Coordinator integration pending)  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove DSC-P, López coverage, or Erdős-Straus. Hard-class conditioned shadows may be strictly larger.

Parent input: prime-child theorem (`../PRIME-CHILD-SHADOWS.md`); proof style parallel to `../QUOTIENT-9-RIGIDITY.md`.

---

## Theorem

Let j ≥ 1 and set

\[
K = 13j - 3,\qquad m = 4j - 1.
\]

Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
\begin{cases}
K \text{ is prime},\quad\text{or}\\
K = 3p \text{ with } p \text{ prime}.
\end{cases}
}
\]

In the second alternative necessarily 3 | j and p = (13j − 3)/3.

Equivalently: unrestricted full direct shadow along ancestry quotient q = 13 holds if and only if the child depth is prime or three times a prime.

---

## Normalized criterion

Let

\[
S_j = -T_j = \{e,\,4e \bmod m : e \mid j\}.
\]

The set S_j is inverse-closed. For the ancestry pair (j, K),

\[
T_K \bmod m \subseteq T_j
\iff
e \bmod m \in S_j \quad\text{for every divisor } e \mid K.
\]

---

## Direction: prime or 3p ⇒ shadow

### Prime child

Immediate from the parent prime-child theorem (every q ≡ 1 mod 4).

### Thrice-prime child

Suppose K = 3p with p prime. Then 3 | K = 13j − 3, so 3 | j. Write j = 3d. Then

\[
p = 13d - 1,\qquad m = 12d - 1,
\]

and

\[
p - d = 12d - 1 = m \implies p \equiv d = j/3 \pmod m.
\]

Divisors of K are {1, 3, p, K}. Modulo m they become

\[
\{1,\,3,\,j/3,\,j\},
\]

all of which divide j. Hence all lie in S_j, and full shadowing holds.

---

## Direction: shadow ⇒ prime or 3p

Assume T_K mod m ⊆ T_j. We show K is prime or K = 3p.

### Lemma (odd j)

If j is odd and K is composite, then full shadowing fails.

**Proof.** K = 13j − 3 is even and ≥ 4, so 2 | K and −2 ∈ T_K. But 2 ∉ S_j: j odd ⇒ 2 ∤ j; for e < j one has 4e ≤ m − 3 so 4e ≢ 2 mod m; for e = j one has 4j ≡ 1 mod m. Thus −2 ∉ T_j. QED.

Consequently, if j is odd and shadowing holds, K must be prime (the 3p alternative requires 3 | j, hence j even when combined with other constraints is irrelevant—odd j forces K prime).

### Even j, 3 ∤ j

Then gcd(j, K) = gcd(j, 3) = 1, so no prime factor of K divides j.

K is odd (j even). Suppose K is composite. Let ℓ be its least prime factor. Then ℓ ≤ √K.

**Inequality.** For j ≥ 2,

\[
K = 13j - 3 < (4j - 1)^2 = m^2,
\]

because 16j² − 21j + 4 > 0 for all j ≥ 2. Hence √K < m, so ℓ < m.

**Exclusion from S_j.** The prime ℓ is odd, 1 < ℓ < m, and ℓ ∤ j. It cannot equal any e | j. It cannot equal 4e for e | j and e < j, because 4e is divisible by 4 while ℓ is odd. The wrapped residue 4j ≡ 1 mod m is 1 ≠ ℓ. Therefore ℓ ∉ S_j, full shadowing fails.

So when 3 ∤ j and shadowing holds, K must be prime.

### Even j, 3 | j

Write j = 3d and N = 13d − 1, so K = 3N and m = 12d − 1. (For even j one has d ≥ 2 when j ≥ 6; j = 0 is excluded.)

If N is prime then K = 3p as required. Assume N is composite; we derive a contradiction to shadowing.

Let ℓ be the least prime factor of N. Then ℓ ≤ √N. For d ≥ 2,

\[
\sqrt{N} = \sqrt{13d-1} < 12d-1 = m.
\]

Also gcd(N, d) = gcd(13d − 1, d) = 1.

**Subcase ℓ ≠ 3.** Then ℓ ∤ d and ℓ ≠ 3, so ℓ ∤ j = 3d. The same exclusion as above gives ℓ ∉ S_j (ℓ odd, 1 < ℓ < m, ℓ ∤ j). Shadowing fails.

**Subcase ℓ = 3.** Then 3 | N, so 13d ≡ 1 mod 3, i.e. d ≡ 1 mod 3. In particular 3 ∤ d, hence 9 ∤ j = 3d.

Since N is composite and 3 | N with N ≠ 3 (13d − 1 = 3 ⇒ 13d = 4, impossible), one has 9 | K.

We claim 9 ∉ S_j. Indeed 9 ∤ j. If 4e ≡ 9 mod m for some e | j with e ≤ j, then either:

- 0 < 4e < m and 4e = 9, impossible (9 not divisible by 4); or
- 4e ≥ m and 4e − m = 9, so 4e = 9 + m = 4j + 8, hence e = j + 2 > j, impossible.

Thus 9 ∉ S_j, so the divisor 9 of K witnesses failure of full shadowing.

**Note.** The subcase 3 | d and 3 | N is empty: if 3 | d then N = 13d − 1 ≡ −1 ≢ 0 mod 3.

---

## Conclusion of the converse

Whenever unrestricted full shadowing holds, the case analysis forces K prime or K = 3p with p prime. Combined with the direct implications, the classification is complete. QED.

---

## Infinite families

### Prime children

K ≡ −3 ≡ 10 mod 13. Dirichlet supplies infinitely many primes in this class, each giving a q = 13 full shadow.

### Thrice-prime children

K = 3p with p = 13d − 1 prime and j = 3d. Then p ≡ −1 ≡ 12 mod 13. Dirichlet supplies infinitely many such primes, each giving a q = 13 full shadow.

---

## Comparison

| q | Unrestricted full-shadow child shapes |
|---|----------------------------------------|
| 5 | prime only |
| 9 | prime, 2p, and exception (j,K)=(2,16) |
| 13 | prime, 3p |

---

## Novelty / prior-art boundary

Dirichlet, elementary congruence arguments, and inverse-closed divisor sets are classical. López Type A/B congruences are prior art. The contribution is the **exact unrestricted q = 13 ancestry shadow classification** inside the C_AB minimal-depth/shadow framework, extending the prime-child theorem and the q = 5 / q = 9 rigidity results.

Coordinator review and promotion into parent documents are requested. Operator-02 does not edit parent theorem files.
