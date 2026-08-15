# C1 Pullback Cardinality Bound

**Status:** proved lemma; see also `C1-ESCAPE-CORE.md` for the expanded core  
**Date:** 2026-08-15  
**Claim boundary:** Advances C1. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

---

## Theorem (Pullback cardinality)

\[
\boxed{|R| \le |T_j|.}
\]

### Proof

Let `t ∈ T_j`. The congruence `L s ≡ t − r (mod m)` is solvable iff `g | (t − r)`. When solvable, `gcd(L/g, q)=1` gives a unique solution class `s mod q`. Distinct traps may collide, so `|R| ≤ |T_j|`.

---

## Corollary (Pigeonhole escape)

\[
|T_j| < φ(q) \implies U \setminus R \ne \emptyset.
\]

---

## Expanded core

Full injectivity, zero-trap, prime-modulus, and finite certificate results: **[C1-ESCAPE-CORE.md](C1-ESCAPE-CORE.md)**.

## Remaining gap

When `φ(q) ≤ |T_j|` and `0 ∉ R`, prove two-box geometry still blocks `U ⊆ R`.
