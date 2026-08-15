# Erdős-Straus research operator coordination

**Coordinator:** primary research lead / Operator-01  
**Parallel research lane:** Operator-02  
**Date:** 2026-08-15  
**Canonical store:** this repository  

## Operating rule

The coordinator owns synthesis, theorem promotion, claim boundaries, reproducibility, literature calibration, and the canonical research map.

Operator-02 remains a parallel analysis / verification-support lane under `research/erdos-straus/operator-02/`. Its files are preserved as independent research notes and are not silently rewritten or collapsed into parent material.

A result moves from an Operator-02 diamond candidate into the primary theorem chain only after the coordinator classifies it as one of:

1. **exact theorem / corollary** — proof follows from checked parent definitions or admits an independent proof;
2. **finite certified result** — exact only in the stated computational range;
3. **formulation / compression** — useful reorganization of already proved material;
4. **conjecture / diagnostic** — requires falsification and proof work;
5. **revise** — useful candidate containing an overstatement or ambiguity that must be corrected before promotion;
6. **superseded** — a stronger primary theorem now subsumes the candidate.

Every promotion must retain provenance by linking the Operator-02 source note.

## Operator-02 diamond intake

### 1. Fixed-negative pullback split

Source: [`operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md`](operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md)

Coordinator classification: **exact compression / useful theorem-level split**.

For a fixed-negative earlier layer,

\[
q_j=\frac{m_j}{\gcd(L,m_j)}.
\]

If `q_j=1`, the candidate progression is fixed modulo `m_j`; direct novelty already certifies that fixed residue is not in `T_j`, so the layer contributes no free-parameter covering constraint.

Only

\[
\boxed{\mathcal N^{\rm act}_{k,r}
=\{j\in\mathcal N_{k,r}:q_j>1\}}
\]

can feed the residual `s`-system from the fixed-negative core.

This is adopted as coordinator terminology: **active fixed-negative core**.

Important boundary: non-fixed-negative earlier layers can still survive finer exact reductions. `N^act` identifies the active portion of the fixed-negative character core; it is not automatically the complete exact residual row set.

### 2. Valuation criterion

Source: [`operator-02/DIAMOND-VALUATION-CRITERION.md`](operator-02/DIAMOND-VALUATION-CRITERION.md)

Coordinator classification: **exact arithmetic criterion / bookkeeping lemma**, now linked directly to the primary square-lift theorem.

\[
\boxed{q_j>1
\iff
\exists p:\ v_p(m_j)>v_p(L).}
\]

Under the fixed-squareclass condition, valuation excess splits into:

- fixed-prime excess at primes already dividing `L`;
- even-powered primes absent from `L`.

The second case is exactly the higher-power phenomenon isolated independently in [`SQUARE-LIFT-CORE.md`](SQUARE-LIFT-CORE.md): a genuinely new prime in a character-fixed row can occur only to even exponent.

Thus Operator-02's Class A/B language and the primary square-lift reduction are consistent views of the same residual mechanism.

Novelty boundary: this criterion is mostly a useful normal form extracted from the parent definitions, not a stand-alone major novelty claim.

### 3. Residual support envelope

Source: [`operator-02/DIAMOND-RESIDUAL-SIGNATURE-SUPPORT.md`](operator-02/DIAMOND-RESIDUAL-SIGNATURE-SUPPORT.md)

Coordinator classification: **finite certified envelope / proof-mining guide**.

The finite universal fiber bounds constrain the residual prime universe. The tighter small-prime patterns remain finite diagnostics unless independently promoted to a universal theorem.

This candidate is useful for choosing the finite state space of residual analyzers but is not a universal-in-`k` claim.

The completed `k<=1500` run now gives a stronger current finite census:

```text
directly novel candidates:                 53,240
fiber kernel empty:                        26,532
fiber-empty or canonical residual solved: 45,063
largest nonempty residual kernel:               9 prime coordinates
largest residual prime:                        31
bounded selector 0,±1,...,±64:             53,240 / 53,240 solved
largest selector radius used:                  54
```

These values supersede older sample-only descriptions where the scopes overlap.

### 4. Signature-coset residual target

Source: [`operator-02/DIAMOND-SIGNATURE-COSET-TARGET.md`](operator-02/DIAMOND-SIGNATURE-COSET-TARGET.md)

Coordinator classification: **valuable formulation requiring one important logical correction; partially superseded by stronger primary quotient theory**.

The parent theorem is an image statement:

\[
\boxed{\lambda_j(T_j)=\eta_j+V_j.}
\]

Therefore

\[
x\in T_j
\Longrightarrow
\lambda_j(x)\in\eta_j+V_j,
\]

and hence

\[
\boxed{
\lambda_j(x)\notin\eta_j+V_j
\Longrightarrow
x\notin T_j.
}
\]

But the converse is generally false. A unit residue can have the same local Legendre-signature class as some trap without itself being a divisor-generated Type A/B trap.

The exact hierarchy is

\[
\boxed{
T_j
\subseteq
\lambda_j^{-1}(\eta_j+V_j)
\subseteq
\{x\in(\mathbb Z/m_j\mathbb Z)^\times:(x/m_j)=-1\}.
}
\]

So the trap-signature coset is a **quadratic-resolution unsafe envelope**, not the exact unsafe set.

Accordingly, phrases in the Operator-02 source note such as

> "the unsafe set is the trap coset"

or any use of "equivalently" between signature-coset membership and exact trap membership must be read as too strong and must not be promoted unchanged.

Correct use:

> staying outside the trap-signature coset is a sufficient certificate of exact Type A/B safety; landing inside the coset means only that finer multiplicative/exact-residue analysis is required.

The primary program refines the hierarchy further:

\[
\text{Jacobi-negative units}
\supseteq
\lambda^{-1}(\eta+V)
\supseteq
-D_j
\supseteq
T_j.
\]

See [`MULTIPLICATIVE-TRAP-QUOTIENT.md`](MULTIPLICATIVE-TRAP-QUOTIENT.md), [`MULTIPLICATIVE-DEFECT-QUOTIENT.md`](MULTIPLICATIVE-DEFECT-QUOTIENT.md), and [`MIXED-BOX-OBSTRUCTION.md`](MIXED-BOX-OBSTRUCTION.md).

### 5. Class-C residual node

Source: [`operator-02/DIAMOND-CLASS-C-NODE.md`](operator-02/DIAMOND-CLASS-C-NODE.md)

Coordinator classification: **high-value master formulation, with the same signature/exact distinction corrected in the primary upgrade**.

Operator-02 identified the right place to concentrate proof effort: nonempty residual fiber kernel plus nonempty active fixed-negative core after direct novelty, peeling, and character compression.

The source note again uses "equivalently" too strongly between signature-coset avoidance and exact trap avoidance. The coordinated primary formulation [`CLASS-C-RESIDUAL-CORE.md`](CLASS-C-RESIDUAL-CORE.md) fixes this by treating the resolution hierarchy as nested sufficient shields and keeping

\[
\boxed{r+Ls\pmod{m_j}\notin T_j}
\]

as the exact final row condition.

The coordinator upgrade incorporates the later primary results:

- local quadratic signatures;
- squarefree-lift ancestry;
- quadratic-field/genus interpretation;
- multiplicative quotient `Gamma_j`;
- multiplicative defect quotient `M_a`;
- zero-product atom decomposition;
- exact signed two-box residue geometry;
- mixed-box interaction failures.

## Current division of labor

### Coordinator / primary lane

- prove and falsify universal statements;
- integrate Operator-02 diamonds into the canonical theorem architecture;
- maintain `CURRENT-FRONTIER.md`, `DIAMOND.md`, backup checkpoints, workflows and certificate provenance;
- run independent computational attacks;
- maintain prior-art and claim-boundary discipline;
- prioritize the route to universal DSC-P;
- issue corrections when a coarse envelope is accidentally stated as an exact equivalence.

### Operator-02 lane

Highest-value parallel tasks from this checkpoint:

#### O2-A. Correct the signature-coset formulations

In future notes, preserve the strict distinction

\[
T_j\subseteq\lambda_j^{-1}(\eta_j+V_j).
\]

Use "signature-certified safe" for residues outside the coset. Do not identify the preimage of the signature coset with the exact trap set.

Operator-02 source notes remain preserved as provenance; corrections should be made by new follow-up notes rather than silently rewriting historical analysis.

#### O2-B. Active-core census on the full k<=1500 bundle

For all `53,240` directly novel candidates, measure:

- `|N|`;
- `|N^act|`;
- Class-A versus Class-B valuation witnesses;
- overlap with the final fiber-kernel support;
- whether each residual prime is sourced by an active fixed-negative row or only by other surviving exact constraints.

Do not infer a universal theorem from the finite census.

#### O2-C. Cross active-core sources with the multiplicative defect quotient

For active fixed-negative rows with squarefree ancestor `a`, compute

\[
\mathcal M_a=K_a/D_a
\]

and classify the defect classes contributed by residual primes.

Primary question:

> Are Class-A/Class-B valuation witnesses concentrated into a small list of minimal zero-product atom types in `M_a`?

#### O2-D. Falsify bounded mixed-box support

Primary found exact square-lift projection failures where all one-prime axes are safe but a mixed divisor escapes, first at `j=696`.

Attack:

> Whenever exact signed-box containment fails after all single-axis tests pass, is there always a failing divisor supported on at most two distinct prime directions?

If false, find the smallest support-3 counterexample and freeze it immediately.

If no support-3 failure appears over a large exact range, report the exact range and verifier logic, not a universal theorem.

#### O2-E. Atom-to-shadow census

Using minimal zero-product atoms in `M_a`, test whether an atom whose neutral divisor residue misses the ancestor exact trap is already trapped or shadowed by **another earlier layer**.

This is the highest-value Operator-02 bridge from finite-abelian conservation back toward universal Direct-Shadow Completeness.

#### O2-F. Small Class-C exact systems

Isolate and independently solve the smallest coordinated Class-C systems, starting with:

- `|N^act|=1`;
- residual kernel size `2` or `3`;
- cyclic `M_a`;
- the smallest mixed-box support patterns.

Every proof attempt should include a falsifier and an explicit exact-trap check rather than stopping at quadratic-signature safety.

## Promotion rules

A diamond candidate is promoted only if it satisfies all of:

1. exact statement with quantified scope;
2. proof or independently checkable certificate;
3. no hidden equivalence between a coarse envelope and the exact trap set;
4. explicit classical prior-art boundary;
5. integration point in the canonical theorem chain;
6. falsifier or counterexample condition stated.

Formulation diamonds may remain useful without promotion as theorems.

## Coordination invariant

No operator's result is allowed to exist only in chat.

The flow is

\[
\boxed{
\text{operator note}
\to
\text{coordinator review}
\to
\text{proof / falsifier / certificate}
\to
\text{primary synthesis}
\to
\text{backup checkpoint}.
}
\]

The repository, not session memory, is the research ledger.
