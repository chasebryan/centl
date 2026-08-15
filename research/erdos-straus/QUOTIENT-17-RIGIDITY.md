# Quotient-17 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Provenance:** proved in Operator-02 lane (`operator-02/ANCESTRY-Q17-CLASSIFICATION.md`); promoted to parent theorem document  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

Read with:

- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [QUOTIENT-9-RIGIDITY.md](QUOTIENT-9-RIGIDITY.md)
- [QUOTIENT-13-RIGIDITY.md](QUOTIENT-13-RIGIDITY.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)

---

## Theorem

Let `K = 17j - 4` and `m = 4j - 1`. Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
\begin{cases}
K \text{ is prime},\quad\text{or}\\
K = 2p \text{ with } p \text{ an odd prime},\quad\text{or}\\
K = 4p \text{ with } p \text{ an odd prime},\quad\text{or}\\
(j,K) = (4, 64).
\end{cases}
}
\]

---

## Direct implications

- **Prime child:** parent prime-child theorem.
- **K = 2p:** `j = 2d`, `p = 17d - 2 ≡ j/2 mod m`; divisors map to `{1,2,j/2,j}`.
- **K = 4p:** `j = 4d`, `p = 17d - 1 ≡ j/4 mod m`; divisors map into `{1,2,4,j/4,j/2,j}`.
- **(4,64):** explicit check; `S_4 = {1,2,4,8} mod 15` absorbs all powers of two.

---

## Converse outline

1. **Odd j:** `gcd(j,K) = 1`, `K` odd; least prime factor of composite `K` escapes `S_j` (`√K < m` for `j ≥ 2`).
2. **v₂(K) = 1:** write `K = 2N`; if `N` composite its least odd prime factor escapes `S_j`.
3. **v₂(K) = 2:** write `K = 4N`; same if `N` composite.
4. **v₂(K) ≥ 3:** forces `j ≡ 4 mod 8` and `v₂(j) = 2` exactly.
   - **v₂ ≥ 5, j > 4:** divisor `32 ∉ S_j`.
   - **v₂ = 3 or 4:** odd part `N` satisfies `j < N < m` and is odd, hence `N ∉ S_j`.
   - Only remaining shadow: `(4,64)`.

Full case-by-case write-up: `operator-02/ANCESTRY-Q17-CLASSIFICATION.md`.

---

## Structural remark

Unlike quotients with odd prime `s = (q-1)/4`, the case `s = 4 = 2²` produces a short 2-adic family rather than a single odd factor `s·p`. This is the first fully classified quotient whose composite-child list is governed by 2-adic valuation rather than a single odd prime factor.
