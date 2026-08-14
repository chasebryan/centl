# Fiber-Kernel Residuals — Operator-02 Analysis

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** independent reading and structural notes  
**Claim boundary:** inherits all boundaries of the parent program. This note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. Finite diagnostic numbers quoted from parent documents remain diagnostic until the primary automation freezes complete enumerations.

This document lives exclusively under `operator-02/`. It does not modify any parent file.

---

## 1. Sources (read-only)

Primary parent documents used:

- [`../FIBER-SHADOW-KERNEL.md`](../FIBER-SHADOW-KERNEL.md) — exact fiber peeling theorem and diagnostic sample
- [`../SHADOW-KERNEL.md`](../SHADOW-KERNEL.md) — coarse prime-power peeling and universal bound
- [`../SMALL-SELECTOR-HYPOTHESIS.md`](../SMALL-SELECTOR-HYPOTHESIS.md) — bounded selector experiment on residual kernels
- [`../QUADRATIC-TRAP-SIGNATURE.md`](../QUADRATIC-TRAP-SIGNATURE.md) — Jacobi −1 theorem and character-shield construction
- [`../CURRENT-FRONTIER.md`](../CURRENT-FRONTIER.md) — moving edge summary
- [`../DIRECT-SHADOW-K1200.md`](../DIRECT-SHADOW-K1200.md) — finite certificate through k ≤ 1200

No material from those files is rewritten or altered.

---

## 2. Exact statements accepted as given

### 2.1 Fiber peeling theorem (parent)

For a fixed candidate, after writing the pullback system

\[
s \bmod q_j \in R_j,
\]

define for each prime power dividing a modulus the maximum fiber width

\[
f_{j,p} = \max_b |F_{j,p}(b)|.
\]

The fiber load is

\[
\Lambda_p = \sum_{p \mid q_j} \frac{f_{j,p}}{p^{a_{j,p}}}.
\]

If \(\Lambda_p < 1\) (or the reduced form \(\Lambda_p^* < 1\)), the coordinate is peelable. Iteration yields the **fiber shadow kernel** — the residual set of primes that cannot be eliminated by this rule.

If the kernel is empty, a reduced avoiding assignment exists by constructive reverse extension, independently of sequential witness search.

### 2.2 Universal coarse bound (parent)

Through k ≤ 1000 the candidate-independent bound already forces every p ≥ 113 to be peelable. The possible universal kernel is therefore confined to the 28 primes ≤ 109. Candidate-specific fiber peeling is reported to be substantially stronger.

### 2.3 Diagnostic sample (parent, k ≤ 1000)

From an evenly distributed sample of 5 000 of the 33 644 certified novel candidates:

- empty fiber kernel: 3 686 / 5 000 ≈ 73.7 %
- every residual kernel supported on primes ≤ 23
- dominant nonempty signatures: {3,11,13} and {3,5,11,13,17,19,23}

These figures are treated here strictly as published diagnostics, not as complete enumerations.

---

## 3. Structural reading (Operator-02)

### 3.1 Compression cascade

The parent architecture already supplies a clear reduction cascade:

```
hundreds of raw earlier constraints
        ↓
prime-power decomposition
        ↓
coarse local-load peeling (λ_p)
        ↓
fiber-load peeling (Λ_p)
        ↓
tiny recurring small-prime kernel
```

The decisive object for a universal DSC-P proof is therefore the classification of the residual kernels that survive the last step.

### 3.2 Observed residual signatures

The two dominant nonempty signatures reported in the parent diagnostic are highly structured:

- `{3,11,13}` — three primes, all ≡ 3 mod 4, all small
- `{3,5,11,13,17,19,23}` — seven primes, again all ≤ 23

The repeated appearance of 3 together with consecutive or near-consecutive odd primes suggests that residual kernels may be governed by the interaction of the smallest primes that divide many of the earlier moduli 4j−1.

Operator-02 hypothesis for later testing (not a claim):

> After fiber peeling, residual kernels are supported on primes that simultaneously divide many of the active q_j and participate in odd-exponent Jacobi constraints that the character shield cannot fully neutralize.

This is only a direction for analysis; it is not asserted as true.

### 3.3 Relation to the character shield

The quadratic nonresidue theorem confines every trap to the Jacobi −1 side of its modulus. The character-shield construction attempts to force every earlier modulus onto the Jacobi +1 side. When the linear system over F₂ is solvable, the candidate is already proved to possess a reduced avoiding progression without any further kernel analysis.

Consequently the residual fiber kernels that matter most for further theorem work are precisely those for which the character-shield system is inconsistent. In that case one must still escape some earlier layers inside their Jacobi −1 region by exact residue avoidance. The fiber kernel is the natural place where those remaining exact constraints live.

### 3.4 Selector interaction

The small-selector experiment tests whether a fixed bounded menu {0, ±1, …, ±B} already solves every residual kernel. A positive outcome on a complete enumeration would suggest that the residual systems are not only small but also “shallow” in the sense that ordinary small integers already avoid the residual forbidden sets.

Operator-02 notes that a successful bounded selector, once proved rather than observed, would convert the residual-kernel classification problem into a finite check of a small list of local residue patterns.

---

## 4. Concrete questions for subsequent Operator-02 work

These questions stay inside the published material and do not require modification of any parent document or script.

1. **Signature census (once primary data are frozen)**  
   For the complete k ≤ 1200 (and later k ≤ 1500) fiber-kernel output, list every distinct residual prime set up to ordering. Record multiplicity and any correlation with the original depth k or the hard class h.

2. **Character-core intersection**  
   Among candidates whose fiber kernel is nonempty, what fraction also have an inconsistent character-shield system? Those form the hardest residual class.

3. **Basepoint solvability**  
   For each dominant residual signature, does the all-ones (or all-zero) local assignment already solve the residual constraints? If not, what is the minimal number of coordinate changes required?

4. **Trap-fiber width bounds**  
   Can one derive uniform upper bounds on f_{j,p} that depend only on the trap structure of T_j rather than on the particular candidate? Such bounds would turn the fiber load into a more analytic object.

5. **Ancestry interaction**  
   Do residual kernels behave differently on candidates that lie in strong modulus-ancestry families (especially q = 5)?

---

## 5. What this note does not claim

- It does not claim that every fiber kernel is empty or that every residual kernel is solvable by a fixed selector.
- It does not claim that the diagnostic 73.7 % empty-kernel rate survives on the full corpus.
- It does not claim an absolute small-prime bound independent of k.
- It does not assert that the combination of fiber peeling and the character shield already yields universal DSC-P.

All such statements remain open and belong to the primary theorem program.

---

## 6. Immediate next Operator-02 step

Await or, when available, read the complete fiber-kernel certificate output from the primary automation for k ≤ 1200 / k ≤ 1500. Until that output is frozen and hashed by the primary workflow, further numerical claims will be limited to the diagnostic sample already published in the parent documents.

In parallel, begin a purely structural examination of the two dominant residual signatures {3,11,13} and {3,5,11,13,17,19,23} using only the arithmetic definitions already present in the parent theory notes. Any resulting lemmas will be recorded in a subsequent Operator-02 file.
