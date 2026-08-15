# C1 Escape Core Theorems

**Status:** proved structural core + residual gap  
**Date:** 2026-08-15  
**Claim boundary:** Advances C1 / DSC-P. Does **not** prove Erdős-Straus, universal López coverage, or full DSC-P.

Exact arithmetic checks below are CENTL-contract equivalent (unbounded integers / rational identity). A native `centl` binary was not available in the operator environment; identities were verified with exact rational arithmetic under the same numerical contract as `docs/NUMERICS.md`.

---

## Setup

Active earlier layer `j`, modulus `m = 4j−1`, global modulus factor `L`, residue `r`:

\[
g = \gcd(L,m),\qquad q = m/g > 1.
\]

Parameter `s mod q` via

\[
\psi(s) = r + Ls \pmod m.
\]

Forbidden set

\[
R = \{ s \bmod q : \psi(s) \in T_j \}.
\]

Reduced classes: `U = { s mod q : gcd(s,q)=1 }`.

Goal: `U \ R ≠ ∅`.

---

## Theorem A — Trap set misses zero

\[
\boxed{0 \notin T_j \quad (j \ge 1).}
\]

**Proof.** Every generator of `T_j` is `-e` or `-4e` with `1 ≤ e ≤ j`. Then `m = 4j−1 > j ≥ e`, so `e ≢ 0 (mod m)`. Hence neither `-e` nor `-4e` is `0`. Independent verification: `j = 1..9999`.

---

## Theorem B — Pullback cardinality (restated)

\[
\boxed{|R| \le |T_j| \le 2\tau(j).}
\]

**Proof.** Each solvable trap determines a unique `s mod q` because `gcd(L/g, q)=1`. Surjection from a subset of `T_j` onto `R`.

---

## Theorem C — Affine injectivity and image

The map `ψ : Z/qZ → Z/mZ` is injective. Its image is exactly the arithmetic progression

\[
\operatorname{im} ψ = \{ x \bmod m : x \equiv r \pmod g \},
\]
of length `q`.

**Proof.** If `L(s₁−s₂) ≡ 0 (mod m)` then `q | (s₁−s₂)` using `gcd(L/g,q)=1`. Every residue `≡ r (mod g)` occurs once as `s` runs over a complete set mod `q`.

---

## Theorem D — Pigeonhole escape

\[
\boxed{|T_j| < φ(q) \implies U \setminus R \ne \emptyset.}
\]

**Proof.** `|R| ≤ |T_j| < φ(q) = |U|`.

---

## Theorem E — Zero-slot penalty (prime modulus)

Let `q = p` be an odd prime, so `U = {1,...,p−1}` and `|U| = p−1`.

If `0 ∈ R` and `|T_j| ≤ p−1`, then

\[
|R \cap U| \le |R| - 1 \le |T_j| - 1 \le p-2,
\]

hence `U \ R ≠ ∅`.

**Proof.** `0 ∉ U` for `p > 1`, so membership of `0` in `R` consumes a slot outside `U`.

Combined with Theorem D: the only remaining prime-`q` danger is

\[
|T_j| \ge p-1,\qquad 0 \notin R,\qquad U \subseteq R.
\]

---

## Theorem F — Finite non-cover certificate

For all `j ≤ 2500` and

\[
L \in \{12,24,60,120,420,840,2520,5040,55440,720720,1441440\},
\]

every pair with `|T_j| ≥ φ(q)` was checked over residues `r`. **Zero** instances satisfied `U ⊆ R`.

Prime-`q` subsearch through `j ≤ 3000`: **zero** full unit covers.

This is a finite certificate, not a universal theorem for the boundary regime.

---

## Theorem G — Multiplicative containment (parent)

\[
T_j \subseteq -D_j,\qquad D_j = \langle \ell : \ell \mid j \rangle \le (\mathbb Z/m\mathbb Z)^\times.
\]

(Parent: `MULTIPLICATIVE-TRAP-QUOTIENT.md`.) Consequently `R` is the pullback of a subset of a single multiplicative coset, not an arbitrary subset of size `|T_j|`.

---

## Exact frontier identity (CENTL-contract check)

\[
\frac{4}{9658489}
=
\frac{1}{2414862}
+
\frac{1}{613787317461}
+
\frac{1}{25324558158}
\]

verified as an equality of rational numbers (exact, no floating point).

---

## Residual gap (only remaining C1 obstruction)

Prove in full generality:

> If `φ(q) ≤ |T_j|` and `0 ∉ R`, the two-box set `T_j ⊆ -D_j` still cannot satisfy `U ⊆ R` under the affine pullback `ψ`.

Equivalent form: the intersection of a Type A/B two-box with any full residue progression `{x : x ≡ r (mod g)}` never hits every ψ-preimage of a unit class mod `q`.

---

## Conditional C1 theorem

Assume the residual gap. Then every directly novel candidate with `|N^{act}|=1` is reduced-realizable (character shield + inactive layers safe + active escape + fiber reverse + Dirichlet).

---

## What this does not claim

Erdős-Straus, López-for-all-primes, and universal DSC-P remain open.
