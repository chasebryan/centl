# Quotient-21 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Provenance:** proved in Operator-02 lane (`operator-02/ANCESTRY-Q21-CLASSIFICATION.md`); promoted to parent theorem document  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

Read with:

- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [QUOTIENT-13-RIGIDITY.md](QUOTIENT-13-RIGIDITY.md)
- [QUOTIENT-9-RIGIDITY.md](QUOTIENT-9-RIGIDITY.md)

---

## Theorem

Let `K = 21j - 5` and `m = 4j - 1`. Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
K \text{ is prime or } K = 5p \text{ with } p \text{ prime}.
}
\]

In the second alternative, `5 | j` and `p = 21(j/5) - 1`.

---

## Direct implications

- **Prime child:** parent prime-child theorem.
- **K = 5p:** `j = 5d`, `p = 21d - 1 ≡ j/5 mod m`; divisors `{1,5,p,K} → {1,5,j/5,j}`.

---

## Converse

`gcd(j,K) = gcd(j,5)`.

- **5 ∤ j:** least prime factor of composite `K` escapes `S_j` (including the even subcase via `2 ∉ S_j` for odd `j`).
- **5 | j:** write `K = 5N`. If `N` composite, either a prime factor `ℓ ≠ 5` escapes `S_j`, or `5 | N` forces the divisor `25 ∉ S_j`.

Note `N = 21d - 1` is always odd, so the least prime factor of `N` is never `2`.

Full write-up: `operator-02/ANCESTRY-Q21-CLASSIFICATION.md`.

---

## Pattern

With `q = 13` (`s = 3`) and `q = 21` (`s = 5`), the odd-prime-`s` pattern is:

\[
\boxed{
\text{composite unrestricted full shadow} \iff K = s\cdot p.
}
\]

This is now proved for `s ∈ {3,5}`. The case `s = 7` (`q = 29`) is the immediate next target.
