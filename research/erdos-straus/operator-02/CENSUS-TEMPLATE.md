# Census Template for Primary Fiber-Kernel and Character-Shield Output

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** preparatory template only  
**Claim boundary:** this file defines the questions that will be asked of future primary output. It contains no numerical results beyond those already published as diagnostics in the parent documents.

When the primary automation freezes complete fiber-kernel and character-shield certificates for a stated range (k ≤ 1200, k ≤ 1500, or later), Operator-02 will populate a census note that answers exactly the fields below. No other files outside this container will be touched.

---

## 1. Range and input identity

- Primary certificate range: k ≤ ____
- Source artifact / workflow run / SHA-256 (as published by primary):
- Number of directly novel candidates in range:
- Number of candidates for which fiber-kernel analysis is present:
- Number of candidates for which character-shield analysis is present:

---

## 2. Fiber-kernel emptiness rate

- Empty fiber kernel (Class A):
- Nonempty fiber kernel:
- Empty-kernel percentage:

Compare against the published diagnostic sample rate ≈ 73.7 % (5 000 / 33 644 at k ≤ 1000).

---

## 3. Residual prime support

- Maximum prime appearing in any residual kernel:
- Complete list of primes that appear at least once in a residual kernel:
- Histogram of residual kernel cardinality (0, 1, 2, 3, …):

---

## 4. Residual signature multiplicity

List every distinct residual prime set (ignoring powers) that occurs, ordered by multiplicity:

| Residual signature | Count | Percentage of nonempty |
|--------------------|-------|------------------------|
| {3,11,13}          |       |                        |
| {3,5,11,13,17,19,23} |     |                        |
| (others)           |       |                        |

---

## 5. Character-shield outcomes

- Character-shield solvable:
- Character-shield inconsistent:
- Solvable percentage:

---

## 6. Class-C size (residual obstruction)

Class C = nonempty fiber kernel **and** inconsistent character shield.

- |Class C| =
- Percentage of all directly novel candidates:
- Residual signatures appearing inside Class C (with counts):

---

## 7. Selector diagnostics (if present in primary output)

- Number of residual kernels solved by the bounded menu S_B:
- Number of residual kernels not solved by S_B:
- Distribution of minimal absolute selector by residual signature:
- Any residual kernel requiring |s| > 64 (falsification of the current bounded menu for that instance):

---

## 8. Basepoint diagnostics (if present)

- Number of residual kernels already solved by the canonical all-ones (or unary-safe) local assignment:
- Maximal number of residual coordinate changes needed from that basepoint:

---

## 9. Operator-02 interpretation rules (fixed in advance)

- All counts are finite-range theorem-certificate statements only.
- An empty Class C in a given range is strong evidence but not a proof of universal DSC-P.
- A nonempty Class C whose residual signatures are few and small remains consistent with the compression picture; it does not constitute a counterexample.
- Any residual kernel that survives both filters and also fails the bounded selector menu is recorded as a concrete instance requiring deeper local analysis; it is still not a DSC-P counterexample.

---

## 10. Output location

The populated census will be written as a new file

```
operator-02/CENSUS-kXXXX.md
```

inside this container only.
