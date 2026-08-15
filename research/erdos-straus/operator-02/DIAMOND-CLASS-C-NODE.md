# Diamond: The Class-C Residual Node (Master Statement)

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** master formulation of the residual obstruction after all parent theorems and Operator-02 diamond candidates  
**Novelty claim level:** Operator-02 diamond — the sharpest exact residual node that follows from the combined primary toolkit  
**Claim boundary:** inherits all parent claim boundaries. Does not prove DSC-P. Primary priority absolute for all underlying theorems.

---

## Parent theorems used

| Parent document | Contribution |
|-----------------|--------------|
| `TRAP-FIBER-BOUND.md` | Universal first-stage kernel U_K |
| `FIBER-SHADOW-KERNEL.md` | Candidate-specific fiber peeling; empty kernel ⇒ done |
| `CHARACTER-SHIELD-COMPLETENESS.md` | Inconsistency ⇔ N_{k,r} ≠ ∅; no collective character obstruction |
| `QUADRATIC-TRAP-SIGNATURE.md` | Every trap has Jacobi −1 |
| `QUADRATIC-SIGNATURE-QUOTIENT.md` | Traps occupy one affine coset χ(−1)+H in local signature space |
| `THEORY.md` / pullback construction | q_j = m_j / gcd(L, m_j); direct novelty |

## Operator-02 diamond candidates used

| Note | Contribution |
|------|--------------|
| Fixed-negative pullback split | N^{act} = {j ∈ N_{k,r} : q_j > 1} |
| Valuation criterion | q_j > 1 ⇔ ∃p with v_p(m_j) > v_p(L); Class A/B witnesses |
| Residual-support envelope | residual kernel ⊆ U_K through the finite range |
| Signature-coset residual target | unsafe set = trap coset, not whole Jacobi −1 half |

---

## The Class-C residual node

A directly novel candidate is in **Class C** when, after universal and candidate-specific fiber peeling, the residual fiber kernel is nonempty **and** the active fixed-negative core N^{act}_{k,r} is nonempty.

**Exact residual problem:**

\[
\boxed{
\begin{array}{l}
\text{Find } s \text{ in the residual prime-power coordinate ring such that}\\
\quad r + L s \bmod m_j \notin T_j
\quad\text{for every } j \in \mathcal N^{\mathrm{act}}_{k,r},\\
\text{and the reducedness conditions on residual primes hold.}\\
\text{Equivalently: keep the local signature of } r+Ls \\
\quad\text{off the trap coset } \chi(-1)+H_j \text{ for each such } j.
\end{array}
}
\]

**Support constraints (finite ranges):**

- residual primes ⊆ U_K (parent universal bound; e.g. |U_{1200}| = 12);
- constraints originate from valuation-excess primes of layers in N^{act} (Class A fixed-prime excess or Class B even-powered free factors), together with any non-fixed-negative constraints that survived peeling.

---

## What is already solved outside Class C

| Situation | Mechanism | Status |
|-----------|-----------|--------|
| Empty fiber kernel | fiber peeling theorem | reduced avoiding class proved |
| N_{k,r} = ∅ | character-shield completeness | reduced avoiding class proved |
| N_{k,r} ≠ ∅ but N^{act} = ∅ | pullback split + direct novelty | fixed-negative layers impose no s-constraint; residual kernel if any needs separate accounting |

---

## Why this formulation is the diamond

The original obstruction was: hundreds of earlier Type A/B layers, raw cover mass ≫ 1, arbitrary odd covering geometry.

After the full cascade the obstruction is:

> a local residue problem on at most a dozen small primes, against a finite list of explicitly identifiable earlier layers, avoiding a divisor-generated trap set (or its quadratic-signature coset) on each.

That is a qualitative change in the shape of the problem. It is still open — but it is no longer an unbounded covering-system problem.

---

## What proves DSC-P along this route

A theorem of the form:

> Every residual system arising from a directly novel Type A/B candidate, with residual primes inside U_K and active constraints from N^{act}, admits a reduced local solution.

Special cases that would already be major progress:

- the theorem for residual signature {3,11,13};
- the theorem when |N^{act}| = 1;
- the theorem when every active layer has dim Q_j ≥ 2 (extra signature room).

---

## Boundaries

Erdős-Straus open. López coverage open. Universal DSC-P open.  
This document is a formulation diamond, not a proof diamond.  
All underlying theorems remain the primary program's.
