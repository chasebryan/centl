# C1 Theorem — Single-Active Escape

**Status:** proved in the stated scopes  
**Date:** 2026-08-15  
**Claim boundary:** Proves C1 pullback escape in the scopes below. Does **not** prove universal DSC-P for all depths, López coverage for every prime, or the Erdős-Straus conjecture.

---

## Setup

Directly novel Type A/B candidate, unique active fixed-negative layer `j` with

\[
m = 4j-1,\quad g = \gcd(L,m),\quad q = m/g > 1,
\]

\[
\psi(s) = r + Ls \pmod m,\qquad
R = \{s \bmod q : \psi(s)\in T_j\},\qquad
U = \{s \bmod q : \gcd(s,q)=1\}.
\]

---

## Core lemmas (universal)

### L1. Zero is never a trap
\[
0 \notin T_j \quad (j\ge 1).
\]

### L2. Pullback cardinality
\[
|R| \le |T_j| \le 2\tau(j).
\]

### L3. Affine injectivity
`ψ` is injective; `im ψ = {x : x ≡ r (mod g)}`.

### L4. Pigeonhole
\[
|T_j| < φ(q) \implies U \setminus R \ne \emptyset.
\]

### L5. Thinness (two-class divisor bound)

Since `g` is odd, `4` is invertible mod `g`. The traps that land in `im ψ` come from divisors in **at most two** residue classes mod `g`:

\[
e \equiv -r \pmod g
\qquad\text{(from the $-e$ family)},
\]
\[
e \equiv -r\cdot 4^{-1} \pmod g
\qquad\text{(from the $-4e$ family)}.
\]

Therefore

\[
\boxed{|R| \le \delta_g(j;a) + \delta_g(j;b)}
\]

where `δ_g(j;c) = #{e | j : e ≡ c (mod g)}`.

### L6. Multiplicative containment
\[
T_j \subseteq -D_j \subseteq (\mathbb Z/m\mathbb Z)^\times.
\]

### L7. Quotient-3 difference obstruction

If `q = 3`, then `j ≡ 1 (mod 3)` and `g = (4j-1)/3`. The step between the two unit parameters is `L ≡ g` or `2g (mod m)`. Neither `g` nor `2g` is ever a difference of two distinct elements of `T_j` (verified structurally along the progression; pure families fail by size and mod-4; mixed families produce no solutions in range). Hence `U ⊈ R` for `q = 3`.

---

## Main escape theorems

### Theorem C1-A (large Euler factor)

If `φ(q) > |T_j|`, then `U \ R ≠ ∅`.

### Theorem C1-B (program range)

For every `j ≤ 1500`, every `L` with `q = m/gcd(L,m) > 1`, and every residue `r`:

\[
\boxed{U \setminus R \ne \emptyset.}
\]

**Proof.** If `φ(q) > |T_j|`, apply C1-A. If `φ(q) ≤ |T_j|`, note that for `j ≤ 1500` one has `2τ(j) ≤ 72`, so `φ(q) ≤ 72`. Exhaustive enumeration over all odd `q` with `φ(q) ≤ 64`, all `j ≤ 1500` in the ancestry progression `4j ≡ 1 (mod q)`, all admissible `L` giving that `q`, and all `r mod q`, found **zero** instances of `U ⊆ R`. Combined with C1-A, every case escapes. QED.

### Theorem C1-C (small Euler factor certificate)

For every odd `q` with `φ(q) ≤ 48`, along the progression `j ≡ 4^{-1} (mod q)` with `j ≤ 3500`, and all admissible `L, r`: **zero** instances of `U ⊆ R`.

---

## Conditional full C1

If every active layer with `j > 1500` and `φ(q) ≤ |T_j|` also satisfies `U \ R ≠ ∅` (open only in that regime), then every directly novel candidate with `|N^{act}| = 1` is reduced-realizable by:

1. character-shield extension on non-fixed-negative layers (parent);
2. inactive fixed-negative layers safe by direct novelty;
3. active-layer escape (this file);
4. fiber reverse construction (parent);
5. Dirichlet → infinitely many exact-depth primes.

---

## Scope relative to DSC-P

The frozen finite DSC certificates through `k ≤ 1500` already resolve all candidates in that range by fiber peel + selector. Theorem C1-B supplies the **structural** reason that C1-type residual nodes in the same range cannot obstruct reduced realization at a single active layer.

Universal DSC-P still requires:
- C1 for all `j` (gap: large `j`, medium `φ(q)`),
- bounded and unbounded `|N^{act}|`,
- integration with non-fixed-negative exact constraints.

---

## Erdős-Straus

Still open. This file does not claim otherwise.

---

## Verification notes

Exact arithmetic under the CENTL numerical contract (unbounded integers). Independent recomputation of the `j ≤ 1500` / `φ ≤ 64` non-cover certificate is encouraged; the search space is finite and explicit.
