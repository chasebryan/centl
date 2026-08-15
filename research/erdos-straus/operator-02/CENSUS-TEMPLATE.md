# Census Template for Primary Fiber-Kernel, Character-Shield, and Fixed-Negative-Core Output

**Author:** Operator-02  
**Date:** 2026-08-14 (updated)  
**Status:** preparatory template only  
**Claim boundary:** this file defines the questions that will be asked of future primary output. It contains no numerical results beyond those already published as diagnostics or finite theorems in the parent documents.

When the primary automation freezes complete certificates for a stated range, Operator-02 will populate a census note that answers exactly the fields below. No other files outside this container will be touched.

---

## 1. Range and input identity

- Primary certificate range: k ≤ ____
- Source artifact / workflow run / SHA-256 (as published by primary):
- Number of directly novel candidates in range:
- Number of candidates with fiber-kernel analysis:
- Number of candidates with character-shield / fixed-negative-core analysis:

---

## 2. Fiber-kernel emptiness rate

- Empty fiber kernel (Class A contribution):
- Nonempty fiber kernel:
- Empty-kernel percentage:

Compare against published diagnostic sample ≈ 73.7 % (5 000 / 33 644 at k ≤ 1000).

---

## 3. Residual prime support

- Maximum prime appearing in any residual kernel:
- Complete list of primes that appear at least once:
- Histogram of residual kernel cardinality (0, 1, 2, 3, …):

Compare against universal first-stage bound from parent `TRAP-FIBER-BOUND.md` (e.g. p ≤ 41 through k ≤ 1200).

---

## 4. Residual signature multiplicity

| Residual signature | Count | % of nonempty |
|--------------------|-------|---------------|
| {3,11,13}          |       |               |
| {3,5,11,13,17,19,23} |     |               |
| (others)           |       |               |

---

## 5. Character-shield / fixed-negative-core outcomes

- Character-shield solvable (\(\mathcal N_{k,r}=\emptyset\)):
- Character-shield inconsistent (\(\mathcal N_{k,r}\neq\emptyset\)):
- Solvable percentage:

Parent finite check through k ≤ 1200: 30 414 solvable, 11 056 inconsistent, with exact equality between inconsistency and presence of a fixed-only Jacobi-negative layer.

---

## 6. Class-C size (residual obstruction)

Class C = nonempty fiber kernel **and** nonempty fixed-negative core \(\mathcal N_{k,r}\).

- |Class C| =
- Percentage of all directly novel candidates:
- Residual signatures appearing inside Class C (with counts):
- Distribution of |\(\mathcal N_{k,r}\)| inside Class C:

---

## 7. Selector diagnostics (if present in primary output)

- Residual kernels solved by the bounded menu S_B:
- Residual kernels not solved by S_B:
- Distribution of minimal absolute selector by residual signature:
- Any residual kernel requiring |s| > 64:

---

## 8. Basepoint diagnostics (if present)

- Residual kernels already solved by the canonical unary-safe local assignment:
- Maximal number of residual coordinate changes needed from that basepoint:

---

## 9. Operator-02 interpretation rules (fixed in advance)

- All counts are finite-range theorem-certificate statements only.
- An empty Class C in a given range is strong evidence but not a proof of universal DSC-P.
- A nonempty Class C whose residual signatures are few and small remains consistent with the compression picture; it is not a counterexample.
- Any residual kernel that survives both filters and also fails the bounded selector menu is recorded as a concrete instance requiring deeper local analysis; it is still not a DSC-P counterexample.

---

## 10. Output location

The populated census will be written as a new file

```
operator-02/CENSUS-kXXXX.md
```

inside this container only.
