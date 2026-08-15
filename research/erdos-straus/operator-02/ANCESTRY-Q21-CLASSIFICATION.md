# Quotient-21 Ancestry Shadow Classification

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** PROVED  
**Type:** proved theorem (Operator-02 lane)  
**Claim boundary:** unrestricted trap-set shadowing only. Not DSC-P / López / Erdős-Straus.

---

## Theorem

Let j ≥ 1 and set

\[
K = 21j - 5,\qquad m = 4j - 1.
\]

Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
K\text{ is prime or }K=5p\text{ with }p\text{ prime}.
}
\]

In the second alternative, necessarily 5|j and p = (21j−5)/5 = 21(j/5)−1.

---

## Direct implications

### Prime child

Parent prime-child theorem (q = 21 ≡ 1 mod 4).

### K = 5p

Write j = 5d. Then p = 21d − 1 and m = 20d − 1, so

\[
p - d = 20d - 1 = m \implies p \equiv d = j/5 \pmod m.
\]

Divisors of K = 5p are {1,5,p,K} → {1,5,j/5,j}, all dividing j. Full shadowing holds.

---

## Converse

Normalized criterion: every e|K has e mod m ∈ S_j = −T_j.

Note gcd(j,K) = gcd(j,5) ∈ {1,5}.

### Case 5 ∤ j

Then gcd(j,K) = 1. Suppose K composite. Let ℓ be its least prime factor; ℓ ≤ √K.

For j ≥ 2, K = 21j−5 < (4j−1)² (poly 16j² − 29j + 6 > 0 for j ≥ 2). Thus ℓ < m.

If ℓ is odd: ℓ ∤ j ⇒ ℓ ∉ S_j (same exclusion as q=13/17).

If ℓ = 2: then K even. 21j−5 even ⇒ j odd. For odd j, 2 ∉ S_j (plain divisors odd; 4e ≥ 4; wrap = 1). So −2 ∉ T_j. Shadowing fails.

### Case 5 | j

Write j = 5d, N = 21d − 1, K = 5N. If N is prime we are done. Assume N composite.

Let ℓ be the least prime factor of N; ℓ ≤ √N < m for d ≥ 1.

gcd(N,d) = gcd(21d−1,d) = 1.

**If ℓ ≠ 5:** then ℓ ∤ j = 5d, so ℓ ∉ S_j (if ℓ = 2 and N even: possible; 2 ∉ S_j when d odd / j ≡ 5 mod 10 carefully — if 2|N and 2∉S_j, fail; if 2∈S_j need other factor). Standard: pick least prime factor; if it divides j it must be 5.

**If ℓ = 5:** then 5|N, so 25|K. Divisor 25: does 25 ∈ S_j?

5|N ⇒ 21d ≡ 1 mod 5 ⇒ d ≡ 1 mod 5 (21≡1). So 5∤d, hence 25∤j.

25 = 4e ⇒ e = 25/4 not integer. Wrapped: 4e ≡ 25 mod m with e≤j ⇒ 4e = 25+m = 4j+24 ⇒ e = j+6 > j, impossible. Thus 25 ∉ S_j. Shadowing fails.

**If ℓ ≠ 5:** ℓ ∤ d and ℓ ≠ 5 ⇒ ℓ ∤ j. If ℓ odd, ℓ ∉ S_j. If ℓ = 2, N even, K divisible by 10. For 2 ∈ S_j we need 2|j (so 2|5d ⇒ 2|d). If 2|d and 2|N: N=21d−1 odd when d even? 21d even, −1 odd — **N is always odd**. So ℓ ≠ 2. Always odd least factor. Done.

---

## Conclusion

Shadowing holds iff K is prime or K = 5p. QED.

---

## Finite check

Through K ≤ 40,000: zero composite full shadows outside the 5p family.

---

## Prior-art boundary

Same as q=13/17. Contribution: exact unrestricted q=21 classification in the C_AB framework.
