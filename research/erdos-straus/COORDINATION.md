# Erdős-Straus research coordination

**Date:** 2026-08-14  
**Coordinator:** primary research coordinator  
**Partner:** Operator-02  
**Repository:** `chasebryan/centl`  
**Canonical rule:** the repository is the source of truth. Chat state and local scratch data are disposable.

## 1. Roles

### Coordinator

The Coordinator owns the integrated theorem program and is responsible for:

1. maintaining the canonical parent research documents;
2. deciding when a finite observation is promoted to a theorem candidate or theorem;
3. checking proofs against the existing Type A/B definitions and claim boundaries;
4. integrating Operator-02 diamond candidates into the main architecture;
5. maintaining GitHub Actions falsification/certification workflows;
6. freezing successful finite runs with independent verification, CENTL receipts, SHA-256 provenance, and durable Markdown records;
7. preventing duplicated research branches from drifting into contradictory notation or claims;
8. maintaining prior-art and novelty discipline;
9. writing a crash-safe checkpoint whenever a material theorem, finite frontier, or proof architecture changes.

### Operator-02

Operator-02 remains an analysis/verification partner with a deliberately non-destructive container:

`research/erdos-straus/operator-02/`

Its mandate is to derive, stress-test, compress, and formulate new candidate structure without modifying parent documents or primary scripts. Finished Operator-02 work is committed to `main` and coupled to the primary program by reference.

The Operator-02 container currently records five linked diamond candidates:

1. **Fixed-negative pullback split**
   \[
   \mathcal N^{\mathrm{act}}_{k,r}
   =\{j\in\mathcal N_{k,r}:q_j>1\}.
   \]
   Fixed-negative layers with `q_j=1` are inactive on the parameter line and are already exactly safe by direct novelty.

2. **Valuation criterion**
   \[
   q_j>1
   \iff
   \exists p:\ v_p(m_j)>v_p(L).
   \]
   Residual valuation excess splits into Class A fixed-prime excess and Class B even-powered free primes.

3. **Residual-support envelope**
   Residual fiber kernels lie inside the parent universal small-prime support bound for the finite range. The completed `k<=1500` run sharpens the actual observed residual support further: the largest residual prime is `31`.

4. **Signature-coset residual target**
   For active fixed-negative layers, the residual variable must avoid the actual Type A/B trap set, with the local quadratic-signature coset providing a stronger coarse shield than the single Jacobi bit.

5. **Class-C residual node**
   The master remaining node after parent peeling/character theorems and the Operator-02 reductions is a local exact residue problem on a small prime-power coordinate ring against the active fixed-negative layers.

The source documents are under [`operator-02/`](operator-02/), especially [`operator-02/DIAMOND-CLASS-C-NODE.md`](operator-02/DIAMOND-CLASS-C-NODE.md) and [`operator-02/RESIDUAL-OBSTRUCTION-SYNTHESIS.md`](operator-02/RESIDUAL-OBSTRUCTION-SYNTHESIS.md).

## 2. Current shared theorem architecture

The coordinated program is now

\[
\boxed{
\begin{array}{c}
C_{AB}\text{ minimal witness depth}\\
\downarrow\\
\text{direct shadow graph and exact-depth spectrum}\\
\downarrow\\
\text{fiber peeling}\\
\downarrow\\
\text{bounded residual selector evidence}\\
\downarrow\\
\text{scalar character obstruction completeness}\\
\downarrow\\
\text{full local quadratic signature quotient}\\
\downarrow\\
\text{multiplicative trap quotient / two-box core}\\
\downarrow\\
\mathcal N^{\mathrm{act}}_{k,r}\text{ and valuation-source split}\\
\downarrow\\
\textbf{Class-C local residual node}\\
\downarrow\\
\text{universal DSC-P target}
\end{array}
}
\]

Universal DSC-P remains unproved.

## 3. Latest frozen finite frontier

The Coordinator has frozen the completed all-stage `k<=1500` run in [`DIRECT-SHADOW-K1500.md`](DIRECT-SHADOW-K1500.md).

Proven finite certificate counts:

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

All `53,240` directly novel candidates are also independently resolved by exact fiber peeling plus the fixed residual selector menu `0,±1,...,±64` in the tested range. The maximum selector radius remains `54`.

Workflow provenance:

```text
run id:       31849103304
head commit:  c508994fb48e6f701f15577352f275df5646cd78
artifact id:  9238241616
artifact sha256:
e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
```

## 4. Division of immediate work

### Coordinator primary track

The Coordinator will focus on turning the residual compression into proof:

1. integrate the Operator-02 `N^{act}` split into a candidate census on the verified `k<=1500` bundle;
2. measure which residual fiber-kernel primes are explained by Operator-02 Class A/Class B valuation witnesses;
3. intersect the active fixed-negative core with the full quadratic-signature and multiplicative trap quotients;
4. classify residual exact constraints inside the two-box representation of `T_j`;
5. prove special cases of the Class-C node before attempting the universal statement;
6. maintain the next falsification workflow only after current results are frozen.

### Operator-02 partner track

Operator-02 should continue analysis-only work under `operator-02/`, prioritizing:

1. census predictions for `|N|` versus `|N^{act}|`;
2. Class A/Class B valuation-source coverage of residual kernel primes;
3. arithmetic explanation for recurring residual signatures and the persistent absence/suppression of selected small primes such as `7`;
4. `q=5` ancestry arithmetic against the primary data;
5. candidate proof lemmas for the Class-C special cases;
6. adversarial review of Coordinator theorem attempts.

Operator-02 should not edit parent files or primary scripts unless the Coordinator explicitly changes this protocol.

## 5. Promotion protocol

Every Operator-02 diamond candidate is assigned one of four states by the Coordinator:

- `FORMULATION` — useful reframing, no new theorem claimed;
- `FINITE-CERTIFIED` — exact finite statement supported by independent certificate/replay;
- `THEOREM-CANDIDATE` — precise universal statement with evidence but incomplete proof;
- `PROVED` — proof checked and promoted into a parent theorem document.

Promotion requires preserving prior-art attribution. A useful reorganization of parent facts is not automatically a novelty claim.

Current Operator-02 status:

```text
Fixed-negative pullback split:   FORMULATION / exact consequence
Valuation criterion:             PROVED elementary criterion
Residual-support envelope:       FINITE-CERTIFIED consequence of parent bounds
Signature-coset residual target: FORMULATION using parent quotient theorem
Class-C residual node:           FORMULATION / master open node
```

## 6. First coordinated theorem targets

Rather than attacking universal Class C all at once, the Coordinator will attempt the following in order:

### Target C1: single active layer

Prove the Class-C residual problem whenever

\[
|\mathcal N^{\mathrm{act}}_{k,r}|=1.
\]

This should expose whether direct novelty plus the two-box trap geometry already forces a local escape.

### Target C2: `{3,11,13}` residual kernel

Prove reduced local solvability for the recurring residual signature

\[
\{3,11,13\}.
\]

This is the smallest dominant nontrivial kernel family and is therefore the cleanest finite-dimensional laboratory.

### Target C3: higher signature room

Prove Class-C solvability when every active fixed-negative layer has quadratic quotient codimension at least two, exploiting the additional signature cosets outside the trap class.

### Target C4: valuation-source completeness

Determine whether every residual kernel coordinate in the complete `k<=1500` bundle is accounted for by Class A/Class B valuation witnesses from active fixed-negative layers. If true in the full range, derive the structural reason.

### Target C5: universal local escape

Only after the preceding structure is understood, attack

\[
\boxed{
\text{direct novelty}
\Longrightarrow
\text{Class-C local escape}
\Longrightarrow
\text{reduced avoiding progression}.
}
\]

This is universal DSC-P.

## 7. Crash-safety protocol

Because chat sessions have been unstable, every material step follows this order:

1. **commit the theorem/experiment design first;**
2. run the experiment or proof falsifier;
3. independently verify the output;
4. use CENTL where exact algebraic certification applies;
5. hash and archive the result artifact;
6. write a durable result/checkpoint document containing run ID, commit SHA, artifact ID, digest, and claim boundary;
7. only then advance the frontier.

No important result should exist only in chat.

## 8. Coordination rule

The Coordinator and Operator-02 are one research program, not competing branches.

Operator-02 scouts and sharpens the terrain. The Coordinator decides what becomes canonical, proves or falsifies the strongest candidates, maintains reproducibility, and keeps the theorem architecture coherent.

The diamond is shared; provenance is explicit.
