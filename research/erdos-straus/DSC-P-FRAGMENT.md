# DSC-P Fragment — Coprime Active Cores

**Status:** proved theorem  
**Date:** 2026-08-15  
**Claim boundary:** Infinite fragment of Direct-Shadow Completeness. Not universal DSC-P. Not Erdős-Straus.

---

## Theorem

Let a directly novel Type A/B candidate have active fixed-negative core `N^{act}` with pullback moduli `q_j` (j ∈ N^{act}). If

\[
\gcd(q_j, q_{j'}) = 1 \quad\text{for all distinct } j,j' \in N^{\mathrm{act}},
\]

then the candidate admits a reduced avoiding progression. Dirichlet supplies infinitely many primes of exact Type A/B depth equal to the candidate depth.

## Proof chain

1. Character-shield completeness ⇒ non-fixed-negative layers can be made Jacobi-positive (parent).
2. Inactive fixed-negative layers (`q_j = 1`) exact-safe by direct novelty.
3. Each active layer has nonempty reduced safe set `S_j` by **C1**.
4. Pairwise-coprime CRT of the `S_j` by **CN-coprime**.
5. Fiber reverse construction (parent).
6. Dirichlet.

## Content

This is an exact infinite theorem inside the Type A/B shadow program, not a finite census.

## Limitations

- Shared prime factors among active moduli excluded.
- Does not force López coverage for primes outside Type A/B.
- Does not handle composite denominators of Erdős-Straus.
