# Diamond Candidate: Selector Closure Through k ≤ 1200

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** organizational diamond on the parent fiber+selector finite closure  
**Novelty claim level:** Operator-02 diamond candidate — naming the finite selector-closure phenomenon and its theorem-target implications  
**Claim boundary:** the underlying counts are parent exact replay results (`../FIBER-SELECTOR-K1200.md`). This note does not prove a universal selector theorem.

---

## 1. Parent finite closure

\[
\boxed{
41,470/41,470
\text{ directly novel candidates through } k\le 1200
\text{ resolved by fiber peeling + selector menu } \mathcal S_{64}.
}
\]

Maximal selector radius used: 54.  
Residual primes: all ≤ 23.  
Unresolved residual kernels: 0.

---

## 2. Why this is a diamond-level finite phenomenon

The original candidatewise attack proved witnesses exist.  
The fiber+selector replay proves witnesses can be **constructed** after theorem-driven elimination from a uniformly tiny residual menu.

That is a different and stronger finite statement:

\[
\text{direct novelty}
\xrightarrow{\text{exact}}
\text{fiber peel}
\xrightarrow{\text{exact}}
\text{residual kernel on } p\le 23
\xrightarrow{\text{finite menu}}
\text{reduced avoiding class}.
\]

Through the tested range the last arrow never fails.

---

## 3. Signature structure of the selector-solved residuals

Parent complete census of nonempty residual signatures (15,426 candidates):

| Signature | Count | Notes |
|-----------|------:|-------|
| {3,11,13} | 3,868 | all ≡ 3 mod 4; no 7 |
| {3,5,11,13,17,19,23} | 10,890 | dominant; no 7 |
| {11,13} | 28 | size 2 |
| {3,11,13,19,23} | 142 | |
| other size-6 variants | 498 | all subsets of {3,5,11,13,17,19,23} omitting one or more |

**Persistent regularities:**

1. **7 is absent from every nonempty residual signature.**
2. No residual kernel of cardinality 1 or 4.
3. All signatures are subsets of {3,5,11,13,17,19,23}.
4. The two dominant signatures account for 14,758 / 15,426 ≈ 95.7% of nonempty residuals.

Operator-02 records the absence of 7 as the strongest empirical regularity still lacking an arithmetic explanation from the trap-fiber collision profile κ_{j,7^a}.

---

## 4. Theorem targets promoted by the closure

### Target A — absolute residual-prime bound

Prove that residual fiber kernels are supported on primes ≤ 23 for all k, or on some other controlled family independent of k (or growing slowly).

### Target B — bounded selector theorem

Prove that every residual fiber kernel arising from a directly novel candidate admits a selector from a fixed finite menu (e.g. |s| ≤ 54, or |s| ≤ B for some absolute B).

### Target C — signature classification

Prove that the only possible nonempty residual signatures are the finitely many observed forms (or a controlled enlargement), and that each admits a local reduced solution.

A proof of B, even restricted to the observed signatures, would give DSC-P along the fiber+selector route.

---

## 5. Hardest finite fixture

Parent records the unique radius-54 candidate:

```text
k=1062, h=361, t=4129, selector=-54
residual kernel {3,5,11,13,17,19,23}, 64 residual constraints
```

This is the natural regression fixture for any future selector theorem attempt. Operator-02 does not re-analyze it here; it is flagged for when primary releases full residual constraint data.

---

## 6. Boundaries

Finite only. No universal selector theorem claimed. Primary priority for all counts and constructions absolute.
