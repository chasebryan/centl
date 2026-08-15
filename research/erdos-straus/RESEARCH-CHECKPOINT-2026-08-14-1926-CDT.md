# Crash-safe research checkpoint — 2026-08-14 19:26 CDT

**Project:** Free Computation Foundation / CENTL  
**Coordinator:** primary research coordinator  
**Partner:** Operator-02  
**Claim boundary:** Erdős-Straus remains open. Universal López Type A/B coverage and universal Direct-Shadow Completeness remain unproved.

This is a redundant recovery record. It exists so the active theorem program can be reconstructed from GitHub if chat state or temporary local data are lost.

## Canonical recovery chain

1. [`COORDINATION.md`](COORDINATION.md)
2. [`DIAMOND.md`](DIAMOND.md)
3. [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md)
4. [`DIRECT-SHADOW-K1500.md`](DIRECT-SHADOW-K1500.md)
5. [`RESEARCH-BACKUP-2026-08-14.md`](RESEARCH-BACKUP-2026-08-14.md)
6. [`operator-02/README.md`](operator-02/README.md)
7. [`operator-02/DIAMOND-CLASS-C-NODE.md`](operator-02/DIAMOND-CLASS-C-NODE.md)
8. [`PRIOR-ART.md`](PRIOR-ART.md)

## Latest completed all-stage finite frontier

GitHub Actions run `31849103304` completed successfully at `k<=1500`, `s<=3,000,000`.

```text
head commit:  c508994fb48e6f701f15577352f275df5646cd78
artifact id:  9238241616
artifact sha256:
e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
```

Exact counts:

```text
admissible candidates:             73,814
directly shadowed candidates:      20,574
directly novel candidates:         53,240
integer avoiding witnesses:        53,240
reduced avoiding witnesses:        53,240
unresolved integer candidates:          0
unresolved reduced candidates:          0
independent verifier:              VERIFIED
```

All `53,240` directly novel candidates are also independently resolved in this finite range by exact fiber peeling followed, where necessary, by the fixed selector menu `0,±1,...,±64`. Maximum selector radius observed: `54`.

Fiber result:

```text
fiber-empty candidates: 26,532
nonempty kernels:        26,708
selector-solved:         26,708 / 26,708
largest kernel size:     9 prime coordinates
largest residual prime:  31
```

Quadratic scalar shield:

```text
character-shield solved: 38,658 / 53,240
character residual:       14,582
```

See [`DIRECT-SHADOW-K1500.md`](DIRECT-SHADOW-K1500.md) for the frozen record.

## Primary exact theorem inventory

The active parent program includes:

- minimal Type A/B witness depth `C_AB`;
- exact trap cardinality;
- direct CRT shadow criterion;
- modulus ancestry;
- exact-depth spectrum and structural-gap/latency-gap distinction;
- exact survivor density, mass, and hazard;
- prime-modulus exact-depth backbone;
- composite rescue core;
- fiber peeling theorem;
- character obstruction completeness `W_k ∩ F_k = U_k`;
- full local quadratic-signature quotient;
- multiplicative trap coset and quotient;
- exact two-box representation of normalized traps inside the divisor-generated subgroup;
- square-lift / reciprocity refinements;
- dyadic trap saturation and infinite Mersenne shadow lattice.

Universal DSC-P remains the main theorem target.

## Operator-02 integrated diamond candidates

Operator-02 remains analysis-only and non-destructive under `operator-02/`. The Coordinator has accepted the following into the coordinated proof map without overstating their status:

### 1. Active fixed-negative split

\[
\mathcal N^{\mathrm{act}}_{k,r}
=\{j\in\mathcal N_{k,r}:q_j>1\}.
\]

Fixed-negative layers with `q_j=1` do not constrain the free parameter and are already exact-safe by direct novelty.

### 2. Valuation criterion

\[
q_j>1
\iff
\exists p:\ v_p(m_j)>v_p(L).
\]

Excess sources split into:

- Class A: excess powers of primes already dividing `L`;
- Class B: free primes entering `m_j` to even exponent and therefore invisible to squareclass/Jacobi data.

### 3. Residual-support envelope

Residual Class-C kernels live inside the parent small-prime fiber support bound. The completed `k<=1500` computation observes no residual prime above `31`.

### 4. Signature-coset target

On each active fixed-negative layer, the residual choice must avoid the Type A/B trap coset in the local signature quotient, and ultimately the exact trap set itself.

### 5. Class-C residual node

The coordinated open node is now:

\[
\boxed{
\begin{array}{l}
\text{Given a directly novel candidate with nonempty residual fiber kernel and}\\
\mathcal N^{\mathrm{act}}_{k,r}\ne\varnothing,\\
\text{find a reduced residual parameter }s\text{ such that}\\
r+Ls\bmod m_j\notin T_j\quad\forall j\in\mathcal N^{\mathrm{act}}_{k,r}.
\end{array}}
\]

This is a formulation diamond, not yet a proof of DSC-P.

## Coordinated immediate targets

The Coordinator will now prioritize:

1. **C1:** prove the Class-C node when `|N^{act}|=1`;
2. **C2:** prove it for the recurring residual kernel `{3,11,13}`;
3. **C3:** prove it when every active layer has higher quadratic-signature codimension and therefore extra quotient room;
4. **C4:** run a complete `k<=1500` census testing whether every residual kernel prime is explained by Operator-02 Class A/B valuation witnesses;
5. **C5:** use those results to formulate the universal local escape lemma needed for DSC-P.

Operator-02 continues independent analysis/candidate generation and adversarial review under `operator-02/`.

## Crash-safety rule

Every material theorem, experiment design, workflow result, artifact digest, failed conjecture, and claim-boundary change must be committed before the research frontier advances. The repository is canonical; chat is not.
