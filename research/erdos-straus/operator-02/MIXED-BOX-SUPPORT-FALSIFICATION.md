# Mixed-Box Bounded Support — Falsification Design

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** falsification design  
**Type:** FORMULATION / finite search design  
**Parent directive:** O2-C  
**Parent source:** `../MIXED-BOX-OBSTRUCTION.md`

---

## 1. Target conjecture (parent, not Operator-02 claim)

> If exact signed-box containment fails after every individual prime-power axis passes, then some failing divisor uses at most two distinct prime directions.

Equivalently: every mixed-box defect is witnessed by a support-≤2 divisor.

---

## 2. What parent already falsified / established

- Generator-wise simplification (all axes safe ⇒ all divisors safe) is **false**.
- First mixed-only failure: **j = 696**, ancestor d = 23, a = 6; mixed divisor 3·29 ≡ 18 ∉ U_6.
- Through j ≤ 20,000: 15 mixed-only failures listed; all currently consistent with support-2 witnesses in the published examples (not yet certified as a classification).

---

## 3. Operator-02 falsification protocol

### Search object

Among non-squarefree 4j−1 with squarefree ancestor d = 4a−1:

1. Confirm every prime-power divisor q^t of j lands in U_a = D_a ∪ D_a^{−1}.
2. Confirm some divisor e|j has e mod d ∉ U_a (mixed failure).
3. Among all failing divisors e, compute ω(e) = number of distinct prime factors.
4. Record minimal ω(e) over failing e.

### Counterexample condition

A **support-3 counterexample** is a mixed-only failure where every failing divisor has at least 3 distinct prime factors (no support-1 or support-2 failing divisor exists).

If found: freeze j, factorization of j, ancestor a,d, U_a, and a minimal-support failing divisor with full residue certificate. File as `MIXED-BOX-SUPPORT3-COUNTEREXAMPLE.md` under operator-02/ only.

If not found over a stated range: report exact range, number of mixed failures tested, verifier logic. **Do not** call it a theorem.

---

## 4. Finite parent list to recheck first

Parent mixed-only failures through j ≤ 20,000:

```text
696, 1180, 2076, 2324, 6408,
7044, 8319, 9592, 10024, 10632,
10740, 12702, 16152, 19752, 19869
```

Operator-02 priority: for each, compute minimal failing support. If any already has min support ≥ 3, that is an immediate counterexample to the bounded-support conjecture within parent’s own search range.

---

## 5. Connection to residual kernels

Parent asks whether minimal failing support correlates with fiber-kernel residual size. Operator-02 notes:

- Residual kernels through k ≤ 1500 have size up to 9, but are parameter-space objects, not divisor-support objects.
- A support-2 mixed-box theorem would reduce exact square-lift projection failures to pairwise interactions — aligning with the “small residual complexity” theme, but not identical to residual fiber kernels.

---

## 6. Claim boundary

No theorem claimed. No counterexample claimed until an explicit certified instance is written. Parent finite list is not re-verified in this note (no local computation run this session).
