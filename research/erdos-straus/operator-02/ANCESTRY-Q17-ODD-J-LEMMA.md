# q = 17 Odd-j Blocking Lemma

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** PROVED  
**Type:** proved lemma (component of q=17 classification)  
**Related:** `ANCESTRY-Q17-RESULTS.md`, `ANCESTRY-Q13-ODD-J-LEMMA.md`

---

## Lemma

Let j ≥ 1 be odd and set

\[
K = 17j - 4,\qquad m = 4j - 1.
\]

If K is composite, then

\[
T_K \bmod m \not\subseteq T_j.
\]

---

## Proof

Since j is odd, gcd(j, 4) = 1, hence

\[
\gcd(j,K) = \gcd(j, 17j-4) = \gcd(j,4) = 1.
\]

No prime factor of K divides j.

Also K is odd (17j odd, 4 even). Let ℓ be the least prime factor of K. Then ℓ is odd and ℓ ≤ √K.

For j ≥ 2,

\[
m^2 - K = (4j-1)^2 - (17j-4) = 16j^2 - 25j + 5 > 0,
\]

because the quadratic 16j² − 25j + 5 has discriminant 305 and positive leading coefficient, and is positive at j = 2. (For j = 1, K = 13 is prime, so the composite hypothesis does not apply.)

Thus √K < m, so 1 < ℓ < m.

Let S_j = −T_j. The prime ℓ cannot lie in S_j:
- ℓ ∤ j, so ℓ is not a plain divisor residue;
- 4e for e | j, e < j is divisible by 4, while ℓ is odd;
- the wrapped residue 4j ≡ 1 mod m equals 1 ≠ ℓ.

Therefore ℓ ∉ S_j, so the divisor ℓ of K witnesses failure of full unrestricted shadowing. QED.

---

## Role

Together with the parent prime-child theorem: when j is odd, unrestricted q = 17 full shadow holds if and only if K is prime.

The remaining classification work is entirely in the even-j regime (shapes 2p, 4p, and the exception (4,64)).
