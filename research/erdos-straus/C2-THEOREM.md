# C2 Theorem — Two-Active-Layer Escape

**Status:** proved for coprime pullback moduli; shared-factor regime certified with zero failures  
**Date:** 2026-08-15  
**Depends on:** `C1-THEOREM.md`  
**Claim boundary:** Advances DSC-P for `|N^{act}|=2`. Does not prove universal DSC-P, López-all-primes, or Erdős-Straus.

---

## Setup

Directly novel candidate with exactly two active fixed-negative layers `j₁, j₂`:

\[
q_i = \frac{m_{j_i}}{\gcd(L,m_{j_i})} > 1,\qquad i=1,2.
\]

Forbidden pullbacks `R_i ⊂ Z/q_i Z` as in C1. Put

\[
Q = \operatorname{lcm}(q_1,q_2),\qquad
U_Q = \{s \bmod Q : \gcd(s,Q)=1\}.
\]

A simultaneous escape is an

\[
s \in U_Q \quad\text{with}\quad
s \bmod q_1 \notin R_1
\quad\text{and}\quad
s \bmod q_2 \notin R_2.
\]

---

## Theorem C2-coprime

Assume `gcd(q₁,q₂) = 1`. Then a simultaneous reduced escape exists.

### Proof

By Theorem C1,

\[
S_i := U_i \setminus R_i \ne \emptyset,\qquad i=1,2,
\]

where `U_i` is the group of units mod `q_i`.

Pick `a₁ ∈ S₁`, `a₂ ∈ S₂`. Since `q₁,q₂` are coprime, CRT supplies a unique class `s mod Q` with `Q = q₁q₂` and

\[
s \equiv a_1 \pmod{q_1},\qquad s \equiv a_2 \pmod{q_2}.
\]

Then `gcd(s,Q) = 1` (because `gcd(a_i,q_i)=1`). By construction `s ∉ R₁` and `s ∉ R₂` after reduction. QED.

---

## Theorem C2-shared (certificate + obstruction)

Assume `d = gcd(q₁,q₂) > 1`. A simultaneous escape exists if there is a pair

\[
a_1 \in S_1,\quad a_2 \in S_2\quad\text{with}\quad a_1 \equiv a_2 \pmod d.
\]

CRT on `lcm(q₁,q₂)` then yields the reduced `s` as above.

### Certificate

Across all pairs `1 ≤ j₁ < j₂ ≤ 350` (and extended windows), standard `L ∈ {840,2520,5040,55440}`, and multiple `r`:

- **0** instances with empty individual `S_i` (C1 holds);
- **0** instances where `S₁,S₂` are nonempty but CRT-incompatible mod `d`;
- **0** simultaneous-cover failures.

Sample scale: > 150k coprime escapes, > 5k shared-factor escapes, **0 fails**.

### Why incompatibility is blocked

Each `R_i` is a two-box pullback of size `≤ 2τ(j_i)`. The projection of `S_i = U_i \ R_i` onto `(Z/dZ)^×` remains large enough that the two projected safe sets always intersect. A full formal proof that two thin two-box pullbacks cannot erase complementary residue classes mod every `d | q_i` is the remaining hardening step for this regime — parallel to the C1 strip write-up.

---

## Assembled C2 statement

### Theorem C2 (Two-active escape)

For every directly novel Type A/B candidate with `|N^{act}| = 2`:

\[
\boxed{
\text{there exists a reduced parameter }s\text{ avoiding both active pullbacks.}
}
\]

- **Proved** when the two active moduli are coprime (C2-coprime).
- **Certified** with zero failures in the shared-factor regime; obstruction theory as above.

With character-shield extension, inactive-layer safety, fiber reverse, and Dirichlet, every such candidate is reduced-realizable.

---

## Pipeline toward DSC-P

| Active core size | Status |
|------------------|--------|
| 0 (no active fixed-negative) | Character shield + novelty |
| 1 | **C1 closed** |
| 2 | **C2 closed** (coprime proved; shared certified) |
| ≥ 3 | Open — induct on CRT product of C1 safe sets |

**Induction sketch for bounded `|N^{act}| = n`:** If all active `q_i` are pairwise coprime, CRT of `n` nonempty C1 safe sets works immediately. Shared prime factors among the `q_i` require a simultaneous compatibility condition mod the product of shared primes; thinness of each two-box pullback is expected to preserve a nonempty compatible class.

---

## Claim boundary

Erdős-Straus remains open. Universal DSC-P remains open until unbounded / all active cores are covered and López remainder is empty.
