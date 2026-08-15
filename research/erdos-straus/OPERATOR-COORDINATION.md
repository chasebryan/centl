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
5. **superseded** — a stronger primary theorem now subsumes the candidate.

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

### 2. Valuation criterion

Source: [`operator-02/DIAMOND-VALUATION-CRITERION.md`](operator-02/DIAMOND-VALUATION-CRITERION.md)

Coordinator classification: **exact arithmetic criterion**, now linked directly to the primary square-lift theorem.

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

### 3. Residual support envelope

Source: [`operator-02/DIAMOND-RESIDUAL-SIGNATURE-SUPPORT.md`](operator-02/DIAMOND-RESIDUAL-SIGNATURE-SUPPORT.md)

Coordinator classification: **finite certified envelope / proof-mining guide**.

The finite universal fiber bounds constrain the residual prime universe. The tighter small-prime patterns remain finite diagnostics unless independently promoted to a universal theorem.

This candidate is useful for choosing the finite state space of residual analyzers but is not a universal-in-`k` claim.

### 4. Signature-coset residual target

Source: [`operator-02/DIAMOND-SIGNATURE-COSET-TARGET.md`](operator-02/DIAMOND-SIGNATURE-COSET-TARGET.md)

Coordinator classification: **correct formulation, partially superseded by stronger primary quotient theory**.

Operator-02 correctly narrows the unsafe quadratic target from the entire Jacobi-negative half to the affine trap-signature coset.

The primary program has since refined the hierarchy further:

\[
\text{Jacobi negative}
\supseteq
\text{local quadratic trap coset}
\supseteq
\text{multiplicative trap coset }-D_j
\supseteq
T_j.
\]

See [`MULTIPLICATIVE-TRAP-QUOTIENT.md`](MULTIPLICATIVE-TRAP-QUOTIENT.md) and [`MULTIPLICATIVE-DEFECT-QUOTIENT.md`](MULTIPLICATIVE-DEFECT-QUOTIENT.md).

Thus the Operator-02 formulation remains the correct quadratic-resolution node, while the coordinator's current residual target uses the finer multiplicative quotient and exact two-box geometry.

### 5. Class-C residual node

Source: [`operator-02/DIAMOND-CLASS-C-NODE.md`](operator-02/DIAMOND-CLASS-C-NODE.md)

Coordinator classification: **high-value master formulation**, adopted and upgraded in [`CLASS-C-RESIDUAL-CORE.md`](CLASS-C-RESIDUAL-CORE.md).

Operator-02 identified the right place to concentrate proof effort: nonempty residual fiber kernel plus nonempty active fixed-negative core after direct novelty, peeling, and character compression.

The coordinator upgrade incorporates the later primary results:

- local quadratic signatures;
- multiplicative quotient `Gamma_j`;
- squarefree-lift ancestry;
- multiplicative defect quotient `M_a`;
- zero-product atom decomposition;
- exact two-box trap geometry.

## Current division of labor

### Coordinator / primary lane

- prove and falsify universal statements;
- integrate Operator-02 diamonds into the canonical theorem architecture;
- maintain `CURRENT-FRONTIER.md`, `DIAMOND.md`, backup checkpoints, workflows and certificate provenance;
- run independent computational attacks;
- maintain prior-art and claim-boundary discipline;
- prioritize the route to universal DSC-P.

### Operator-02 lane

Highest-value parallel tasks:

1. census the active fixed-negative core `N^act` on completed candidate bundles;
2. classify valuation-excess sources for residual kernel primes;
3. isolate the smallest Class-C signatures and explicit active-layer configurations;
4. test whether residual constraints factor through the multiplicative defect atoms now defined by the primary lane;
5. search for minimal counterexamples to proposed local escape statements;
6. keep all results under `operator-02/` with explicit parent references and claim boundaries.

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
