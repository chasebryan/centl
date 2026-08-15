# Diamond Candidate: Residual Kernel Support Inside the Universal Bound

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** structural synthesis of parent universal bounds with parent diagnostic sample  
**Novelty claim level:** Operator-02 diamond candidate — a precise finite support statement that organizes existing parent theorems and diagnostics into a single residual-support envelope  
**Claim boundary:** inherits all parent claim boundaries. The universal kernels are parent theorems (`../TRAP-FIBER-BOUND.md`). The diagnostic support ≤ 23 is parent diagnostic data (`../FIBER-SHADOW-KERNEL.md`). No new universal-in-k bound is claimed.

---

## 1. Parent facts

**Universal trap-fiber bound (parent theorem).**  
Through k ≤ 1200 every prime p ≥ 43 is reduced-fiber-peelable for every admissible candidate. The candidate-independent first-stage kernel is contained in

\[
U_{1200} = \{3,5,7,11,13,17,19,23,29,31,37,41\}.
\]

Through k ≤ 1500 the corresponding set is

\[
U_{1500} = \{3,5,7,11,13,17,19,23,29,31,37,41,43,47\}.
\]

**Diagnostic sample (parent, k ≤ 1000).**  
Every residual fiber kernel in a 5 000-candidate sample was supported on primes ≤ 23. Dominant nonempty signatures:

\[
\{3,11,13\},\qquad \{3,5,11,13,17,19,23\}.
\]

**Character-shield completeness (parent theorem).**  
Inconsistency ⇔ nonempty fixed-negative core \(\mathcal N_{k,r}\).

**Fixed-negative pullback split (Operator-02 diamond candidate, preceding note).**  
Only the active part \(\mathcal N^{\mathrm{act}}_{k,r}\) contributes parameter constraints.

---

## 2. Finite residual-support envelope through k ≤ 1200

Combining the parent universal bound with the parent finite certificate range:

\[
\boxed{
\text{every residual fiber kernel through } k\le 1200
\text{ is a subset of } U_{1200}.
}
\]

This is an immediate corollary of the parent trap-fiber theorem; it is recorded here only to fix the envelope against which Class-C residual signatures must be compared.

The diagnostic sample suggests the much tighter empirical envelope

\[
U_{1200}^{\mathrm{emp}} = \{p \text{ prime}: 3 \le p \le 23\},
\]

but that tighter envelope remains diagnostic until a complete census or a stronger theorem is available.

---

## 3. Signature lattice inside the envelope

The two dominant diagnostic signatures form a chain under inclusion:

\[
\{3,11,13\}
\subset
\{3,5,11,13,17,19,23\}
\subseteq
U_{1200}^{\mathrm{emp}}
\subseteq
U_{1200}.
\]

Notable structural features already noted in earlier Operator-02 signature notes:

- both signatures omit 7;
- the smaller signature consists entirely of primes ≡ 3 mod 4;
- the larger adds both 1 mod 4 primes (5, 17) and further 3 mod 4 primes (19, 23).

Operator-02 records the omission of 7 as a persistent empirical regularity worth explaining arithmetically from the trap-fiber collision profile κ_{j,7^a}, but does not assert a theorem.

---

## 4. Diamond statement (finite, exact from parent theorems)

\[
\boxed{
\begin{array}{c}
\text{Through } k\le 1200,\text{ every Class-C residual fiber kernel}\\
\text{is a subset of a fixed 12-element prime set } U_{1200},\\
\text{and must serve exact trap avoidance only against}\\
\text{the active fixed-negative core } \mathcal N^{\mathrm{act}}_{k,r}.
\end{array}
}
\]

This is the sharpest finite residual-support statement Operator-02 can currently write using only parent theorems plus the pullback-split observation. It converts the residual node of DSC-P into a problem about subsets of a known 12-prime set and about a explicitly identifiable finite list of earlier layers.

---

## 5. What would promote this from envelope to theorem

- A complete census confirming that every residual kernel through k ≤ 1200 is not only inside U_{1200} (already forced) but inside the diagnostic envelope ≤ 23.
- A structural reason for the systematic absence of 7 from dominant signatures.
- A proof that every nonempty residual kernel inside U_{1200} that arises from an active fixed-negative core admits a reduced local solution.

The last item is exactly the remaining open node for DSC-P along the parent cascade.

---

## 6. Boundaries

- No absolute bound independent of k is claimed.
- No claim that Class C is empty.
- No claim that the diagnostic signatures are exhaustive.
- Priority for the universal bound remains with the primary program (`TRAP-FIBER-BOUND.md`).
