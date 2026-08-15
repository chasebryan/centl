# q = 13 Classification — Converse Sketch

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** THEOREM CANDIDATE — partial proof  
**Type:** THEOREM CANDIDATE  
**Depends on:** `ANCESTRY-Q13-ODD-J-LEMMA.md`, parent prime-child theorem, 3p divisor argument

---

## Target

Prove: unrestricted full shadow along K = 13j−3 holds if and only if K is prime or K = 3p with p prime.

**Already proved:**
- (⇒) prime or 3p ⇒ shadow
- (⇐ partial) odd j + composite ⇒ no shadow

**Remains:** even j + composite K not of form 3p ⇒ no shadow.

---

## Setup for even j

Let j be even, K = 13j − 3 composite, m = 4j − 1. Criterion: need some e|K with e mod m ∉ S_j.

Note

\[
\gcd(j,K)=\gcd(j,13j-3)=\gcd(j,3)\in\{1,3\}.
\]

---

## Case A — 3 ∤ j

Then gcd(j,K) = 1, so no prime factor of K divides j.

Let ℓ be the smallest prime factor of K. Then ℓ ≤ √K.

**Claim A1.** For all even j ≥ 2 with composite K = 13j−3 and 3 ∤ j,

\[
\ell \le \sqrt K < m = 4j-1,
\]

except possibly a finite list of tiny pairs that can be checked by hand.

**Numerical support:** through K ≤ 30,000 every such pair has a failing prime factor < m not in S_j; zero unexpected shadows.

**Claim A2.** An integer ℓ with 1 < ℓ < m, ℓ ∤ j, and ℓ prime cannot lie in S_j:
- not a divisor residue e|j;
- if ℓ = 4e unwrapped with e < j then ℓ ≡ 0 mod 4 or ℓ ≥ 4, but more carefully: 4e is divisible by 4 when e ≥ 1, so odd ℓ cannot equal 4e; if ℓ = 2 this requires separate check — but K = 13j−3 with j even is odd, so ℓ is odd;
- wrapped endpoint 4j ≡ 1 mod m gives 1 only.

Thus ℓ ∉ S_j, so full shadowing fails.

**Status of Case A:** the S_j exclusion (A2) is elementary for odd ℓ. The inequality √K < m (A1) needs a uniform proof or a complete finite exception list. Operator-02 has not closed A1 for all j; finite range is clean.

---

## Case B — 3 | j but N = (13j−3)/3 is composite

Write j = 3d (automatically d even when j even). Then

\[
K = 3N,\qquad N = 13d - 1,\qquad m = 12d - 1,
\]

and N ≡ d mod m as before.

Since N is composite and N > 1, let ℓ be a prime factor of N with ℓ < N (e.g. smallest).

Then ℓ | K, so −ℓ ∈ T_K after reduction issues.

**Subcase B1 — ℓ ∤ j.** Same argument as A2 once ℓ < m: ℓ ∉ S_j.

**Subcase B2 — ℓ | j.** Possible in principle because gcd(j,K) = 3, so the only shared prime can be 3. If ℓ ≠ 3, then ℓ cannot divide both N and j?  
gcd(N,d) = gcd(13d−1, d) = 1, and j = 3d, so primes dividing d do not divide N. The only possible common prime between j and K is 3. Thus if ℓ | N and ℓ | j then ℓ = 3.

If 3 | N = 13d−1, then 13d ≡ 1 mod 3 ⇒ d ≡ 1 mod 3 since 13 ≡ 1 mod 3. Possible.

When 3 | N, K is divisible by 9. The divisor 9 may or may not land in S_j. Finite examples (e.g. j=12, K=153 = 3·51 = 3·3·17) fail via residue 9 or other factors.

**Status of Case B:** structure is parallel to q = 9 even case; a complete write-up needs careful handling when 3 | N and when N is a prime power. Finite range: all 484 tested even j=3d with N composite fail shadowing as expected.

---

## What would close the theorem

1. Uniform proof that √K < 4j−1 for composite K = 13j−3 outside a finite checked set.
2. Complete analysis when 9 | K (i.e. 3 | N).
3. Hand verification of all pairs with K below the √K < m threshold.

Operator-02 leaves these to the Coordinator proof track or a follow-up note. The finite evidence strongly supports the classification; the odd-j half is already theorem-grade.

---

## Claim boundary

This is a sketch, not a complete proof of the converse. Do not cite as PROVED classification. Odd-j lemma remains the only new fully proved Operator-02 lemma in this family.
