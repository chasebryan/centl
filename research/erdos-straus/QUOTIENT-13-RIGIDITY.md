# Quotient-13 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Provenance:** proved in Operator-02 lane (`operator-02/ANCESTRY-Q13-CLASSIFICATION.md`); promoted to parent theorem document  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [QUOTIENT-9-RIGIDITY.md](QUOTIENT-9-RIGIDITY.md)
- [QUOTIENT-17-RIGIDITY.md](QUOTIENT-17-RIGIDITY.md)
- [QUOTIENT-21-RIGIDITY.md](QUOTIENT-21-RIGIDITY.md)

---

## 1. Quotient-13 ancestry

Fix source depth `j >= 1` and set

\[
K = 13j - 3.
\]

Then

\[
4K - 1 = 13(4j - 1),
\]

so this is ancestry of quotient `q = 13 = 4·3 + 1`.

---

## 2. Classification theorem

### Theorem

Let

\[
m = 4j - 1.
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

In the second alternative necessarily `3 | j` and `p = (13j-3)/3`.

---

## 3. Normalized criterion

Define

\[
S_j = -T_j = \{e,\, 4e \bmod m : e \mid j\}.
\]

The set `S_j` is inverse-closed. Full unrestricted shadowing holds if and only if every divisor of `K` has residue in `S_j`.

---

## 4. Direct implications

### Prime child

Immediate from the prime-child ancestry theorem.

### Thrice-prime child

Suppose `K = 3p` with `p` prime. Then `3 | K`, so `3 | j`. Write `j = 3d`. Then

\[
p = 13d - 1,\qquad m = 12d - 1,
\]

and `p ≡ d = j/3 mod m`. Divisors of `K` are `{1, 3, p, K}`, reducing to `{1, 3, j/3, j}`, all of which divide `j`. Full shadowing holds.

---

## 5. Converse

Assume full shadowing.

### Odd j

If `j` is odd then `K` is even. If `K` is composite then `2 | K`, so it suffices that `2 ∉ S_j`. For odd `j`: `2 ∤ j`; unwrapped `4e ≥ 4`; wrapped endpoint `4j ≡ 1 mod m`. Hence `2 ∉ S_j` and shadowing fails. Thus odd `j` forces `K` prime.

### Even j with 3 ∤ j

Then `gcd(j,K) = 1`. If `K` is composite, its least prime factor `ℓ` satisfies `ℓ ≤ √K < m` for `j ≥ 2` (because `K < m²`). Also `K` is odd, so `ℓ` is odd, `ℓ ∤ j`, and therefore `ℓ ∉ S_j`.

### Even j with 3 | j

Write `j = 3d` and `N = 13d - 1`, so `K = 3N`. If `N` is prime we are done. Assume `N` composite and let `ℓ` be its least prime factor.

- If `ℓ ≠ 3`: then `ℓ ∤ j` (using `gcd(N,d) = 1`), so `ℓ ∉ S_j`.
- If `ℓ = 3`: then `5 ∤` wait — `3 | N` forces `d ≡ 1 mod 3`, hence `3 ∤ d` and `9 ∤ j`. The divisor `9` of `K` satisfies `9 ∉ S_j` (not a divisor of `j`; not of the form `4e` with `e | j`). Shadowing fails.

(Note: `3 | d` and `3 | N` cannot occur simultaneously, since `N = 13d - 1 ≡ -1 mod 3` when `3 | d`.)

---

## 6. Infinite families

Dirichlet gives infinitely many primes `K ≡ 10 mod 13` and infinitely many primes `p ≡ 12 mod 13` yielding `K = 3p` shadows.

---

## 7. Novelty boundary

Elementary arithmetic and the prime-child theorem are prior within this program. The contribution is the exact unrestricted quotient-13 composite-child classification.
