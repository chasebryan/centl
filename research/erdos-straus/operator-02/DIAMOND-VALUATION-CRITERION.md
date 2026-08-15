# Diamond Candidate: Valuation Criterion for Active Fixed-Negative Layers

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** exact criterion derived from parent definitions  
**Novelty claim level:** Operator-02 diamond candidate — explicit arithmetic criterion separating active from inactive fixed-negative layers  
**Claim boundary:** inherits all parent claim boundaries. Pure rearrangement of parent definitions; priority remains with the primary program if already used internally.

---

## 1. Parent definitions

\[
m_j = 4j-1,\qquad L = \operatorname{lcm}(840, m_k),\qquad q_j = m_j / \gcd(L, m_j).
\]

\[
F_k = \text{span of odd primes dividing } L,\qquad
\sigma(m_j) = (v_p(m_j) \bmod 2)_p.
\]

Fixed-only: \(\sigma(m_j) \in F_k\) means every odd prime that divides m_j to an **odd** valuation already divides L.

---

## 2. Exact criterion for q_j > 1

\[
\boxed{
 q_j > 1
 \iff
 \exists\, p:\ v_p(m_j) > v_p(L).
}
\]

The primes p that witness this excess fall into two disjoint classes under the fixed-only hypothesis:

### Class A — fixed-prime excess

\[
p \mid L\quad\text{and}\quad v_p(m_j) > v_p(L).
\]

The odd-exponent condition for fixed-only is already satisfied for such p (or p appears only to even excess beyond an odd base). These are higher powers of primes already locked into the target progression modulus.

### Class B — even-powered free primes

\[
p \nmid L\quad\text{and}\quad v_p(m_j) \ge 2\text{ is even}.
\]

Such a p does **not** appear in \(\sigma(m_j)\) (even valuation), so the layer can still be fixed-only, yet p survives into q_j because it is absent from L. These free primes with even valuation in m_j are invisible to the Jacobi character of m_j but still constrain the parameter s.

---

## 3. Consequence for the residual fiber kernel

After fiber peeling, residual kernel primes must be among the primes that still carry load. For constraints originating from layers in \(\mathcal N^{\mathrm{act}}_{k,r}\), those primes are exactly the Class A and Class B witnesses above (together with any residual structure created by the affine pullback).

In particular:

- Class A residual primes are a subset of the odd primes dividing L (hence of the fixed prime set of the candidate).
- Class B residual primes are free primes that appear to even valuation in some fixed-only Jacobi-negative m_j.

This gives a **source classification** for residual kernel primes inside Class C:

\[
\boxed{
\text{residual prime from }\mathcal N^{\mathrm{act}}
\implies
\text{fixed-prime excess or even-powered free factor in some } j\in\mathcal N^{\mathrm{act}}.
}
\]

---

## 4. Why Class B matters

Class B is the subtle case. A free prime p with even valuation in m_j is invisible to the character shield (it does not affect the Jacobi symbol of m_j) yet it still generates a parameter constraint. After peeling, such a p may sit in the residual fiber kernel even though the character system never "saw" it as a free sign variable for that layer.

Operator-02 records this as a potential explanation for residual kernels that appear to be disconnected from the fixed-negative character data: the connection runs through even-powered free factors rather than through odd squareclass coordinates.

---

## 5. Census predictions

When primary output is available, measure for each Class-C candidate:

1. |\(\mathcal N\)| vs |\(\mathcal N^{\mathrm{act}}\)|;
2. for each j in \(\mathcal N^{\mathrm{act}}\), the set of primes with v_p(m_j) > v_p(L), split into Class A vs Class B;
3. whether every residual kernel prime appears as a Class A or Class B witness for at least one active fixed-negative layer.

Prediction (diagnostic, not theorem): residual kernel primes are covered by the Class A ∪ Class B witness sets of \(\mathcal N^{\mathrm{act}}\).

---

## 6. Boundaries

No claim that Class B is nonempty in the data. No claim that the residual kernel is always explained solely by \(\mathcal N^{\mathrm{act}}\) (non-fixed-negative layers may also survive peeling). No DSC-P claim.
