# C1 Partial Theorems Toward DSC-P

**Status:** partial theorems + explicit remaining obstruction  
**Date:** 2026-08-15  
**Claim boundary:** Does **not** prove Erdős-Straus, López Type A/B coverage, or universal DSC-P. Proves restricted escape lemmas under C1 hypotheses.

---

## 0. What solving Erdős-Straus would require

Erdős-Straus asks for Egyptian fraction representations `4/n = 1/x+1/y+1/z` for all `n ≥ 2`. The López Type A/B program reduces a large arithmetic portion of the prime case to exact-depth / shadow structure. Universal DSC-P would give:

\[
\text{directly novel Type A/B candidate} \implies \text{infinite exact-depth primes},
\]

and with the density-one Type A/B coverage theorem already proved in this program, the exceptional set for López coverage of primes would be under extreme pressure — but **still not automatically empty**. Closing Erdős-Straus requires either:

1. López Type A/B for **every** prime, plus classical handling of composite `n`, or
2. a different global covering argument.

Neither is achieved here. Anyone claiming ES is solved by the present notes is wrong.

The correct attack is to prove DSC-P, starting at C1.

---

## 1. C1 hypotheses

Directly novel candidate, `|N^{act}| = 1`, unique active layer `j0`, pullback modulus

\[
q = q_{j_0} > 1,\qquad R \subsetneq \mathbb Z/q\mathbb Z
\]

the proper forbidden parameter set (proper because not a direct shadow).

---

## 2. Lemma (prime-power pullback)

**Theorem C1-PP.** Suppose `q = p^a` is a prime power and `R ≠ Z/qZ`. Then there exists `s mod q` with `s ∉ R` and `p ∤ s` (reduced at `p`).

**Proof.** The non-reduced residues are the multiples of `p`: there are `p^{a-1}` of them. The full ring has `p^a` residues. Since `R` is a proper subset, `|R| ≤ p^a - 1`. The number of reduced residues is `φ(p^a) = p^a - p^{a-1} = p^{a-1}(p-1)`.

If every reduced residue lay in `R`, then `|R| ≥ φ(p^a)`. This is possible in principle. **However**, under the additional structure that `R` is a pullback of a Type A/B trap set through an affine map from a two-box of size `|T_{j0}| = O(τ(j0))`, one has

\[
|R| \le C\,τ(j_0)\,p^{O(1)}
\]

in the standard pullback geometry (each trap residue lifts to at most a bounded number of classes mod `p^a` after fixing other CRT coordinates). For `a = 1` (`q = p` prime):

**Corollary C1-P.** If `q = p` is prime and `R ≠ Z/pZ`, then some `s ≢ 0 mod p` lies outside `R` unless `R` contains all of `1,...,p-1`. That would mean `|R| ≥ p-1`, so `R` omits at most one class. Direct novelty omits at least one class. If the omitted class is `0`, all reduced residues are forbidden — **this is the only prime-modulus obstruction**.

So for prime `q`, C1 reduces to: the omitted class cannot be solely `{0}` under two-box pullback geometry.

**Two-box exclusion of R = (Z/pZ)\\{0}:** Type A/B traps are specific residues `-e, -4e mod m`. Their pullback to a prime coordinate `p | q` is a sparse affine set, not the full multiplicative group. A complete residue system of all nonzero classes mod `p` would require `|T|` large enough to cover `p-1` classes after projection — impossible when `|T_{j0}| < p-1` after accounting for projection multiplicity 1. Since `|T_k| = O(τ(k))` and `τ(k) = o(k^ε)`, while residual primes in finite ranges are `≤ 31`, one has `|T| < p-1` for all residual primes `p ≥ 3` once `τ(j0)` is moderate.

More sharply for `a = 1`:

**Theorem C1-P-strong.** If `q = p` is an odd prime, `R` is the pullback of `T_{j0}` under a surjective affine map `Z/pZ →` (projection of trap condition), and `|T_{j0}| < p`, then `R ≠ (Z/pZ)\\{0}`. Combined with direct novelty, a reduced safe residue exists.

*Proof sketch.* Projection of `T_{j0}` has size at most `|T_{j0}| < p`, so cannot fill all `p` classes; if it filled all nonzero classes it would have size ≥ `p-1`. When `|T_{j0}| < p-1`, cannot fill all nonzero classes. Direct novelty excludes size `p`. ∎

This closes C1 when the residual kernel is a **single prime** and trap cardinality is less than `p-1`.

---

## 3. Lemma (small trap cardinality)

**Theorem C1-sparse.** Let `q` be arbitrary with residual primes `P = {p | q}`. Let `U` be the set of reduced residues mod `q` (coprime to all `p ∈ P`). If

\[
|R| < |U| = φ(q),
\]

then a reduced safe residue exists.

**Proof.** Immediate pigeonhole. ∎

**When does |R| < φ(q) hold?** If `R` injects from a subset of `T_{j0}` of size `≤ |T_{j0}|` and `|T_{j0}| < φ(q)`, yes. Pullbacks can multiply classes (one trap may forbid many `s`), so the inequality is not automatic. It holds whenever the fiber size of the pullback map is controlled:

\[
|R| \le |T_{j0}| \cdot \frac{q}{\mathrm{period}},
\]

with period related to `m_{j0}/gcd(L,m_{j0})` geometry.

In the fiber-peeling regime, residual `q` is a product of tiny primes and `|T|` is moderate, so the inequality is the expected generic case — still not uniform without a fiber-size bound.

---

## 4. The remaining obstruction (honest)

C1 is not fully proved. The gap is:

> Prove that a two-box / Type A/B pullback forbidden set `R ⊂neq Z/qZ` cannot contain every reduced residue class mod `q`.

Equivalent form:

> The complement of a Type A/B pullback is never contained in the non-reduced hyperplanes `⋃_{p|q}{s : s ≡ 0 mod p}`.

This is a statement purely about the arithmetic of divisor boxes and CRT projections — no conjecture, no appeal to ES. It is the correct lemma.

---

## 5. Conditional DSC-P fragment

**Theorem C1-conditional.** Assume the two-box pullback gap lemma (§4). Then every directly novel candidate with `|N^{act}| = 1` admits a reduced avoiding class, hence (by Dirichlet) infinitely many primes of exact Type A/B depth equal to that candidate's depth.

*Proof.* Character-shield extension (parent) handles non-fixed-negative layers. Inactive fixed-negative layers are safe by direct novelty. The unique active layer contributes proper `R`. Gap lemma supplies reduced `s ∉ R`. Fiber reverse extension (parent) builds the global reduced class. ∎

---

## 6. Relation to Erdős-Straus

Even with full DSC-P, one still needs López coverage for all primes (or an independent argument for the density-zero exceptional set) and the classical composite-`n` theory. **Erdős-Straus remains open.**

The density-one Type A/B theorem in this program already shows almost all primes are covered. The diamond edge is the sparse exceptional set and the exact-depth realization of every directly novel class.

---

## 7. Next proof actions

1. Bound pullback fiber size uniformly in terms of `q` and `|T|`.
2. Prove `|R| < φ(q)` for all C1 residual moduli arising from valuation excess.
3. Handle the boundary case `|R| ≥ φ(q)` by two-box geometry (no full cover of units).
4. Extend from `|N^{act}| = 1` to bounded `|N^{act}|`.

Until §4 is closed, do not claim C1, DSC-P, or Erdős-Straus.
