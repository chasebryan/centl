# Universal Trap-Fiber Bounds — Operator-02 Reading

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** independent reading of the parent candidate-independent bounds  
**Claim boundary:** inherits all parent claim boundaries. The finite universal kernels quoted below are those already proved in `../TRAP-FIBER-BOUND.md`. No extension of the range or of the bounds is claimed here.

---

## 1. Parent theorem accepted as given

From `../TRAP-FIBER-BOUND.md`:

The trap-fiber collision profile

\[
\kappa_{j,p^a}
=
\max_{b \bmod (m_j/p^a)}
\#\{u\in T_j : u\equiv b \pmod{m_j/p^a}\}
\]

depends only on the trap set T_j and the prime power, not on the target candidate. Defining

\[
\beta_{j,p} = \max_{1\le a\le v_p(m_j)} \frac{\kappa_{j,p^a}}{p^a}
\]

and the universal reduced fiber load

\[
\mathcal F_p(K) = \frac1p + \sum_{1\le j<K} \beta_{j,p},
\]

one obtains:

**Theorem.** If \(\mathcal F_p(K)<1\), then the prime coordinate p is reduced-fiber-peelable for every admissible Type A/B candidate at every depth k ≤ K.

---

## 2. Exact finite universal kernels (parent evaluations)

| Depth bound K | Last non-automatic prime | Universal peelability for |
|---------------|--------------------------|---------------------------|
| 1000 | 37 | all p ≥ 41 |
| 1200 | 41 | all p ≥ 43 |
| 1500 | 47 | all p ≥ 53 |
| 3000 | 61 | all p ≥ 67 |

Through k ≤ 1200 the candidate-independent first-stage kernel is contained in

\[
\{3,5,7,11,13,17,19,23,29,31,37,41\}.
\]

Through k ≤ 1500 it is contained in

\[
\{3,5,7,11,13,17,19,23,29,31,37,41,43,47\}.
\]

These bounds already improve dramatically on the earlier coarse universal threshold p ≥ 113 (parent `SHADOW-KERNEL.md`). Candidate-specific fiber peeling, iterative constraint removal, and exact fibers make actual residual kernels still smaller — as seen in the diagnostic sample where every residual was supported on primes ≤ 23.

---

## 3. Consequence for Operator-02 residual analysis

The residual signatures studied earlier now sit inside a rigorously bounded universe:

- Any residual kernel that appears through k ≤ 1200 must be a subset of the twelve-prime set above (before candidate-specific sharpening).
- The two dominant diagnostic signatures `{3,11,13}` and `{3,5,11,13,17,19,23}` are consistent with that universe and, moreover, lie well inside the still smaller empirically observed support ≤ 23.

The universal bound therefore supplies the outer envelope; the diagnostic sample supplies evidence that the actual envelope is tighter. A complete census (template already prepared) will measure how much tighter.

---

## 4. New parent object: trap-fiber collision profile

The parent note introduces \(\kappa_{j,p^a}\) as a natural arithmetic object measuring how strongly the divisor-generated trap set collides when projected away from a prime-power coordinate. Operator-02 records this as a high-value target for later pure-arithmetic work:

> closed bounds or classification of \(\kappa_{j,p^a}\) from the divisor structure of j and the two trap maps e ↦ −e, e ↦ −4e.

A sufficiently sharp uniform bound on these collision profiles could turn the finite small-kernel phenomenon into an asymptotic statement. That direction remains open and belongs to the primary theorem program; Operator-02 only notes its presence.

---

## 5. What this note does not claim

- It does not claim an absolute residual-prime bound independent of K.
- It does not claim that the diagnostic support ≤ 23 is universal.
- It does not claim that every residual kernel inside the universal set is solvable.

All such statements remain outside the present scope.
