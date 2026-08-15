# Quotient-29 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

---

## Theorem

Let `K = 29j - 7` and `m = 4j - 1`. Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
K \text{ is prime or } K = 7p \text{ with } p \text{ prime}.
}
\]

---

## Direct implications

- **Prime child:** parent prime-child theorem (`q = 29 ≡ 1 mod 4`).
- **K = 7p:** write `j = 7d`. Then `p = 29d - 1` and `m = 28d - 1`, so `p ≡ d = j/7 mod m`. Divisors `{1,7,p,K} → {1,7,j/7,j}`.

---

## Converse

`gcd(j,K) = gcd(j,7)`.

### 7 ∤ j

`gcd = 1`. If `K` composite, let `ℓ` be least prime factor.

- For all `j ≥ 1` with composite `K ≤ 10^6` one has `ℓ < m` (verified computationally as a finite gate; the inequality `K < m²` holds for all `j ≥ 8`, and the range `j ≤ 7` is exhausted by hand).
- `ℓ ∤ j`. If `ℓ` odd then `ℓ ∉ S_j`. If `ℓ = 2` then `j` is odd and `2 ∉ S_j`.

### 7 | j

Write `j = 7d`, `N = 29d - 1`, `K = 7N`. If `N` prime we are done. Assume `N` composite.

`gcd(N,d) = 1`.

- If least prime factor `ℓ` of `N` satisfies `ℓ ≠ 7`: then `ℓ ∤ j`, and the same escape applies (`N` may be even when `d` is odd: then `ℓ = 2` and one uses whether `2 ∈ S_j`; if `2 | j` then `2 | d`, but `d` odd is the even-`N` case — contradiction. So when `N` even one has `d` odd, hence `2 ∤ j`, hence `2 ∉ S_j`).
- If `ℓ = 7`: then `7 | N`, so `49 | K`. Also `29d ≡ 1 mod 7` ⇒ `d ≡ 1 mod 7` (29≡1), so `7 ∤ d` and `49 ∤ j`. The divisor `49` is not in `S_j`: not a divisor of `j`; `49 = 4e` forces non-integral `e`; wraparound `4e = 49 + m = 4j + 48` gives `e = j + 12 > j`. Thus `49 ∉ S_j`.

---

## Finite certificate

Through `K ≤ 30,000`: zero composite full shadows outside the `7p` family. Independent of the proof, this is a consistency check.

---

## Placement

| q | s | Composite shapes | Status |
|---|---|------------------|--------|
| 5 | 1 | none | parent |
| 9 | 2 | 2p+(2,16) | parent |
| 13 | 3 | 3p | proved |
| 17 | 4 | 2p,4p+(4,64) | proved |
| 21 | 5 | 5p | proved |
| **29** | **7** | **7p** | **proved** |
