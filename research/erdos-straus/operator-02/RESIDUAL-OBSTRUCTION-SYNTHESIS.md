# Residual Obstruction Synthesis — Operator-02 Working View (diamond update)

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** working synthesis after diamond candidates  
**Claim boundary:** inherits all parent claim boundaries. Organizing document only.

---

## 1. Full cascade now held by Operator-02

```
direct novelty
  → universal trap-fiber bound          (parent theorem: small finite U_K)
  → candidate-specific fiber peel       (parent theorem)
  → character-shield completeness       (parent theorem: N_{k,r} only)
  → fixed-negative pullback split       (Operator-02 diamond candidate)
        N_{k,r} = inactive ∪ active
        inactive: q_j = 1 → already resolved by direct novelty
        active:   q_j > 1 → only these feed the s-system
  → residual fiber kernel ⊆ U_K         (parent corollary)
  → exact trap avoidance against N^{act}
        inside Jacobi −1, and more finely outside the trap-signature coset
        (parent quotient theorem)
  → DSC-P (open)
```

---

## 2. Class C refined

Class C = nonempty residual fiber kernel **and** nonempty active fixed-negative core \(\mathcal N^{\mathrm{act}}_{k,r}\).

(If \(\mathcal N^{\mathrm{act}}\) is empty while the residual kernel is nonempty, the residual constraints come from non-fixed-negative layers; that configuration is to be isolated in census work.)

---

## 3. Finite residual-support envelope (k ≤ 1200)

Every residual fiber kernel is a subset of

\[
U_{1200} = \{3,5,7,11,13,17,19,23,29,31,37,41\}.
\]

Diagnostic sample suggests support ≤ 23 with dominant signatures `{3,11,13}` and `{3,5,11,13,17,19,23}`.

---

## 4. Diamond candidates produced by Operator-02 this session

1. **Fixed-negative pullback split** — isolation of \(\mathcal N^{\mathrm{act}}\) as the only character-negative layers that constrain s.  
   File: `DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md`

2. **Residual-support envelope** — every Class-C residual kernel through k ≤ 1200 lives inside a fixed 12-prime set and faces only the active fixed-negative core.  
   File: `DIAMOND-RESIDUAL-SIGNATURE-SUPPORT.md`

Both are offered as compressions of the residual node, derived from parent definitions and theorems, clearly labeled, and subject to primary priority.

---

## 5. What closes DSC-P along this route

A proof that every residual system of the form

- residual primes ⊆ U_K,
- constraints coming from layers in \(\mathcal N^{\mathrm{act}}_{k,r}\) (and any surviving non-fixed-negative constraints),
- candidate directly novel,

admits a reduced local solution.

That is the diamond-level theorem target.

---

## 6. Boundaries restated

Erdős-Straus open. López coverage open. Universal DSC-P open.  
Finite certificates remain range-limited.  
Residual kernels and failed selectors are not counterexamples.
