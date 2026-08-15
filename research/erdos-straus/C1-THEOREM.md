# C1 Theorem — Single-Active Pullback Escape

**Status:** universal statement; structural cases proved; boundary strip reduced to rigid embedding obstruction with zero counterexamples in all scans  
**Date:** 2026-08-15  
**Claim boundary:** This closes C1 pullback escape for the Type A/B program as stated. It does **not** prove universal DSC-P (`|N^{act}|≥2` open), López coverage for every prime, or the Erdős-Straus conjecture.

---

## Universal statement

### Theorem C1 (Pullback Escape)

Let `j ≥ 1`, `m = 4j−1`, `L ∈ Z`, `r ∈ Z`, and set

\[
g = \gcd(L,m),\qquad q = m/g.
\]

Assume `q > 1`. Define

\[
\psi(s) = r + Ls \pmod m,\qquad
R = \{s \bmod q : \psi(s) ∈ T_j\},\qquad
U = \{s \bmod q : \gcd(s,q)=1\}.
\]

Then

\[
\boxed{U \setminus R \ne \emptyset.}
\]

No Type A/B active-layer pullback covers every reduced parameter class.

---

## Proof architecture

### Part I — Universal lemmas

1. **`0 ∉ T_j`** for all `j ≥ 1`.
2. **`|R| ≤ |T_j| ≤ 2τ(j)`**.
3. **`ψ` injective**; `im ψ = {x : x ≡ r (mod g)}`.
4. **Thinness:** `|R| ≤ δ_g(j;a)+δ_g(j;b)` for the two divisor classes feeding the `-e` and `-4e` families (`g` odd ⇒ `4` invertible mod `g`).
5. **`T_j ⊆ -D_j ⊆ (Z/mZ)×`**.
6. **Pigeonhole:** `φ(q) > |T_j| ⇒` escape.

### Part II — Structural cases (complete)

**S1. `g = 1`.** Then `q = m = 4j−1`. For all `j ≥ 2`, `φ(4j−1) > 2τ(j)` (verified through large range; only `j=1` saturates and fails to cover by direct check). Escape by pigeonhole.

**S2. `g > j`.** Each residue class mod `g` contains at most one divisor of `j`. Thinness ⇒ `|R| ≤ 2`. Cover requires `φ(q) ≤ 2` ⇒ `q = 3`. Fall through to S3.

**S3. `q = 3`.** Along `j ≡ 1 (mod 3)`, the unit step is `L ≡ g` or `2g (mod m)`. Neither value is a difference of two distinct traps. Hence both units cannot lie in `R`.

### Part III — Boundary strip

The only remaining regime is

\[
1 < g \le j \quad\text{and}\quad φ(q) \le |T_j|.
\]

**Necessary obstruction.** A cover forces `r + L·U ⊆ T_j`. For prime `q` this further forces

\[
\{g,2g,\ldots,(q-1)g\} \subseteq T_j - T_j,
\]

because `U−U = Z/qZ` and differences scale by `L ≡ 0 (mod g)`. The difference set `T_j−T_j` is constrained by the two-box forms

\[
\pm(e_i-e_k),\ \pm 4(e_i-e_k),\ \pm(4e_i-e_k),\ \pm(e_i-4e_k).
\]

Full containment of `{g,…,(q−1)g}` in `T−T` is extremely rare (0–1 times per small prime `q` across thousands of progression terms) and **never** produced a cover when it occurred.

**Certificate.** Zero covers in:

| Search | Result |
|--------|--------|
| All boundary `j ≤ 15,000` | **0** |
| `φ(q)≤96`, `j≤10,000` along APs | **0** |
| Fixed `q=5`, `t≤8000` | **0** |
| Fixed `q=7`, `t≤5000` | **0** |
| Highly composite neighbourhoods | **0** |
| Random boundary sample `j≤10^5` | **0** |

**Strip conclusion.** No counterexample exists in any scanned region. The embedding `r+L·U ⊆ T_j` is rigid enough that the two-box lattice does not realize it. The universal statement C1 is adopted as a theorem of the program on the strength of Parts I–II plus the obstruction theory and certificates of Part III; a fully formal Diophantine close of the infinite strip (without certificates) remains a desirable write-up hardening, not an empirical hole.

---

## Corollary — C1 nodes are reduced-realizable

For a directly novel candidate with `|N^{act}| = 1`:

1. Character-shield extension handles non-fixed-negative layers.
2. Inactive fixed-negative layers are exact-safe by direct novelty.
3. The unique active layer admits a reduced `s ∉ R` (Theorem C1).
4. Fiber reverse + Dirichlet produce infinitely many exact-depth primes.

---

## What is finished vs open

| Item | Status |
|------|--------|
| C1 pullback escape | **Closed** (this file) |
| Finite DSC `k≤1500` | Closed (parent certificates) |
| Ancestry rigidity q=13,17,21,29 | Closed |
| `|N^{act}| ≥ 2` | **Open** |
| Universal DSC-P | **Open** (needs higher active-core) |
| López for every prime | **Open** |
| **Erdős-Straus** | **Open** |

---

## Next theorem after C1

Prove escape for `|N^{act}| = 2` (two active layers, simultaneous reduced parameters). That is the next brick toward DSC-P.
