# C1 Pullback Cardinality Bound

**Status:** proved lemma + conditional escape theorem  
**Date:** 2026-08-15  
**Claim boundary:** Advances C1. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

---

## Setup

Candidate progression `x ≡ r (mod L)`. Earlier layer `j` with modulus `m = 4j − 1`. Put

\[
g = \gcd(L, m),\qquad q = m/g.
\]

Assume `q > 1` (active layer). The parameter `s` enters through

\[
x \equiv r + Ls \pmod m
\]

and is well-defined modulo `q`. The forbidden parameter set is

\[
R = \{ s \bmod q : r + Ls \in T_j \},
\]

where `T_j` is the Type A/B trap set of layer `j`.

Direct novelty of the candidate means the layer does not force a total cover for the fixed residue alone; for the active pullback one still has `R ≠ Z/qZ` only after accounting for the global construction — the local cardinality bound below is unconditional.

---

## Theorem (Pullback cardinality)

\[
\boxed{|R| \le |T_j|.}
\]

### Proof

Let `t ∈ T_j`. The congruence

\[
Ls \equiv t - r \pmod m
\]

is solvable if and only if `g | (t − r)`. When it is solvable, write `L = g L'`, `m = g q`, `t − r = g c`. Then

\[
L' s \equiv c \pmod q.
\]

Since `gcd(L', q) = 1`, there is a unique solution class `s mod q`. Distinct traps may collide on the same class, so the map from solvable traps to `R` is surjective onto `R` and therefore

\[
|R| \le |T_j|.
\]

QED.

---

## Corollary (Pigeonhole escape)

Let `U = { s mod q : gcd(s, q) = 1 }` be the reduced residues (coprime to every prime dividing `q`). Then

\[
\boxed{
|T_j| < φ(q) \implies U \setminus R \ne \emptyset.
}
\]

### Proof

`|R| ≤ |T_j| < φ(q) = |U|`, so `R` cannot contain `U`. QED.

---

## Size of trap sets

For every `j ≥ 1`,

\[
|T_j| \le 2τ(j),
\]

with a slightly tighter count after identifying the overlap between the `{e}` and `{4e}` families when `4 | j`.

In particular `|T_j|` is `j^ε` for every `ε > 0` outside a density-zero set of highly composite `j`, and is at most a few dozen for all `j ≤ 1500`.

---

## When the corollary applies automatically

If the pullback modulus `q` satisfies `φ(q) > 2τ(j)`, escape is unconditional from the cardinality bound.

Typical C1 residual moduli arising from valuation excess against `L = lcm(840, 4k−1)` are either:

- a large prime factor of `m_j` (then `φ(q) = q − 1 ≫ |T_j|`), or
- a product of small residual primes.

The second regime is the only place the corollary can fail, and only when `φ(q) ≤ |T_j|`.

---

## Computational certificate (finite)

Through `j ≤ 2000` and `L ∈ {12, 60, 420, 840, 2520, 5040, 55440, 720720}`:

- every pair with `|T_j| ≥ φ(q)` was checked;
- **zero** instances had `R` containing every reduced residue class.

This is finite evidence only, not a universal theorem for the boundary regime `φ(q) ≤ |T_j|`.

---

## Remaining gap (precise)

Prove: if `R` is a Type A/B pullback of cardinality at most `|T_j|`, then even when `φ(q) ≤ |T_j|`,

\[
U \setminus R \ne \emptyset.
\]

Equivalent geometric form: the image of the two exponent boxes under the affine pullback map never covers the full unit group of `Z/qZ`.

---

## Conditional C1 theorem

Assume the gap above. Then every directly novel candidate with `|N^{act}| = 1` admits a reduced safe parameter at the unique active layer. With the parent character-shield extension and fiber reverse construction, that candidate is reduced-realizable, and Dirichlet supplies infinitely many exact-depth primes.
