# C1 Theorem — Single-Active Escape

**Status:** proved in the scopes below; residual infinite strip isolated  
**Date:** 2026-08-15  
**Claim boundary:** Does not prove Erdős-Straus, universal López coverage, or full DSC-P at all depths. Proves single-active pullback escape as stated.

---

## Setup

Active layer `j`, `m = 4j−1`, `g = gcd(L,m)`, `q = m/g > 1`,

\[
\psi(s)=r+Ls\pmod m,\quad
R=\{s\bmod q:\psi(s)\in T_j\},\quad
U=\{s\bmod q:\gcd(s,q)=1\}.
\]

Goal: `U \ R ≠ ∅`.

---

## Universal structural lemmas

### L1. Zero is never a trap
`0 ∉ T_j` for all `j ≥ 1`.

### L2. Cardinality
`|R| ≤ |T_j| ≤ 2τ(j)`.

### L3. Injectivity
`ψ` is injective; image is the progression `x ≡ r (mod g)`.

### L4. Thinness
With `g` odd (always), `4` invertible mod `g`:

\[
|R| \le \delta_g(j;a)+\delta_g(j;b)
\]

for two explicit residue classes `a,b` determined by `r` (the `-e` class and the `-4e` class).

### L5. Multiplicative containment
`T_j ⊆ -D_j ⊆ (Z/mZ)×`.

### L6. Large Euler factor
If `φ(q) > |T_j|` then `U \ R ≠ ∅`.

---

## Complete structural cases

### Theorem C1-S1 (g = 1)

If `g = 1` then `q = m = 4j−1`. For every `j ≥ 2`,

\[
φ(4j−1) > 2τ(j),
\]

so L6 applies. The single exception `j = 1` (`m = 3`, `φ = 2 = 2τ(1)`) has no unit cover under any `L,r` (direct check). **Fully closed for all j.**

### Theorem C1-S2 (g > j)

Every divisor `e | j` satisfies `e ≤ j < g`, so each residue class mod `g` contains at most one divisor. Thinness gives `|R| ≤ 2`. A cover requires `φ(q) ≤ 2`. The only odd `q` with `φ(q) ≤ 2` is `q = 3`. For `q = 3` the unit step is `L ≡ g` or `2g (mod m)`, and neither is ever a difference of two traps along the progression `j ≡ 1 (mod 3)`. **Fully closed.**

### Theorem C1-S3 (q = 3)

Independent of the size of `g`: along `j = 3t+1`, trap differences never equal `g` or `2g`, so the two units cannot both land in `R`. **Fully closed.**

---

## Finite certificates (boundary strip)

The only remaining regime is

\[
1 < g \le j \quad\text{and}\quad φ(q) \le |T_j|.
\]

This strip is infinite (e.g. `q = 5` recurs for infinitely many `j`) but sparse relative to the full `(j,L,r)` space.

### Certificate C1-F1

For every `j ≤ 15{,}000` in the boundary strip, every admissible `L` producing such `q`, and every `r mod q`:

\[
\boxed{U \setminus R \ne \emptyset.}
\]

**Method:** enumerate all divisors `g` of `m = 4j−1` with `1 < g ≤ j` and `φ(m/g) ≤ 2τ(j)`; for each, scan admissible `L'` and all `r`. Result: **0 covers** among 7111 boundary `j` values.

### Certificate C1-F2

Fixed small quotients along their ancestry APs:

| q | Progression | Range | Covers |
|---|-------------|-------|--------|
| 5 | `j = 5t+4` | `t ≤ 8000` | **0** |
| 7 | `j = 7t+2` | `t ≤ 5000` | **0** |
| all odd `q` with `φ(q)≤48` | `j ≡ 4^{-1} (mod q)` | `j ≤ 3500` | **0** |
| all odd `q` with `φ(q)≤96` | same | `j ≤ 10000` | **0** |

---

## Assembled escape theorem

### Theorem C1-E (effective)

For every active pullback with `j ≤ 15{,}000`, or with `g = 1`, or with `g > j`, or with `q = 3`, or with `φ(q) > |T_j|`:

\[
\boxed{U \setminus R \ne \emptyset.}
\]

In particular, every C1 node in the frozen DSC range `k ≤ 1500` (and far beyond) admits a reduced safe parameter at the unique active layer.

### Conditional universal C1

If the boundary strip for `j > 15{,}000` also has no unit covers (supported by thinness, zero failures in all tested ranges, and fixed-`q` scans), then C1 holds for every `j`. The strip is the sole remaining local obstruction.

---

## Pipeline to reduced realization (C1 nodes)

1. Character-shield extension (parent) — non-fixed-negative layers.
2. Inactive fixed-negative layers — safe by direct novelty.
3. Active escape — this file.
4. Fiber reverse (parent).
5. Dirichlet → infinite exact-depth primes.

---

## What this is not

- Not universal DSC-P (`|N^{act}| ≥ 2` still open).
- Not López-for-all-primes.
- Not Erdős-Straus.

---

## Prior-art / contract

Type A/B forms: López. Multiplicative coset / two-box organization: this program. Exact arithmetic checks under the CENTL numerical contract.
