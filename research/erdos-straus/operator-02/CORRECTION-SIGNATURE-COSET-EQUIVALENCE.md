# CORRECTION: Signature-Coset Is Not Equivalent to Exact Trap Membership

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** INDEPENDENT VERIFICATION / correction of prior Operator-02 overstatement  
**Type:** FORMULATION correction  
**Parent directive:** `COORDINATOR-DIRECTIVES.md`, `OPERATOR-COORDINATION.md`

Historical diamond notes are preserved unchanged for provenance. This follow-up records the required correction.

---

## 1. Parent theorem (image statement only)

\[
\lambda_j(T_j) = \eta_j + V_j.
\]

Therefore

\[
x \in T_j \implies \lambda_j(x) \in \eta_j + V_j,
\]

and the contrapositive is a **sufficient** safety certificate:

\[
\lambda_j(x) \notin \eta_j + V_j \implies x \notin T_j.
\]

The converse is generally **false**. A unit may lie in the signature-coset preimage without being a divisor-generated Type A/B trap.

---

## 2. Correct hierarchy

\[
\boxed{
T_j
\subseteq
\lambda_j^{-1}(\eta_j + V_j)
\subseteq
\{x : (x/m_j) = -1\}.
}
\]

And with the multiplicative refinement:

\[
\boxed{
T_j
\subseteq
-D_j
\subseteq
\lambda_j^{-1}(\eta_j + V_j)
\subseteq
\{x : (x/m_j) = -1\}.
}
\]

---

## 3. Corrected terminology for all future Operator-02 notes

| Phrase | Status |
|--------|--------|
| "outside the signature coset ⇒ exact-safe" | **Correct** (sufficient certificate) |
| "inside the signature coset ⇒ exact trap" | **Incorrect** |
| "unsafe set is the trap coset" | **Too strong** — coset preimage is an unsafe *envelope* |
| "equivalently" between coset membership and \(x \in T_j\) | **Forbidden** |

Use:

- **signature-certified safe** for residues outside the coset preimage;
- **signature-undecided** for residues inside the coset preimage (requires multiplicative / exact-residue analysis);
- **exact final condition** remains \(r + L s \bmod m_j \notin T_j\).

---

## 4. Affected historical Operator-02 notes

The following notes contain formulations that must be read under this correction:

- `DIAMOND-SIGNATURE-COSET-TARGET.md`
- `DIAMOND-CLASS-C-NODE.md` (any "equivalently" between coset and exact trap)
- `RESIDUAL-OBSTRUCTION-SYNTHESIS.md` (where signature and exact trap were conflated)

Those files are **not rewritten**. This correction is the authoritative Operator-02 stance going forward.

---

## 5. Alignment with parent CLASS-C-RESIDUAL-CORE

Parent `../CLASS-C-RESIDUAL-CORE.md` already adopts the nested-shield hierarchy and keeps exact trap avoidance as the final row condition. Operator-02 adopts that formulation as canonical.
