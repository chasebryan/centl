# Candidate exact Type-II decomposition framework

**Status:** active research framework, not yet a decomposition theorem  
**Date:** 2026-08-16  
**Research policy:** full exact Type-II geometry is governing; López A/B is a boundary certificate family  
**Claim boundary:** this document defines the developing mechanism and the conditions required before it may be called a decomposition method. It does not prove a new universal decomposition theorem and does not prove Erdős–Straus.

## 1. Current framing

The active program is not merely an expansion of the López A/B search space.

The hierarchy is now:

```text
López A/B
    = divisibility-comparable boundary family inside Type II

full exact Type-II geometry
    = governing certificate space

candidate decomposition framework
    = developing systematic mechanism for producing exact decompositions
```

López remains useful as an exact subfamily and diagnostic coordinate system. It is not assumed complete and it does not define the ontology of Type II.

The present work is attempting to derive another systematic decomposition mechanism inside the larger exact signed-box geometry.

Until the construction closes mathematically, the correct terms are:

- **candidate decomposition method**;
- **developing decomposition framework**;
- **candidate exact Type-II mechanism**.

The terms **new decomposition theorem** or **established decomposition method** are reserved for a later stage in which global soundness, coverage, and termination have all been proved.

## 2. Governing exact target

For a fixed admissible shift k and

`C_k=(p+k)/4`,

Type II is governed by the exact divisor-square condition

`d | C_k^2`

and

`d = -C_k mod k`.

Equivalently, the divisor-square residue mask of C_k must hit the moving target `-C_k mod k`.

The active framework therefore treats the exact `(mask,center)` geometry as primary state.

Character signs, López A/B coordinates, residual supports, valuation phases, and square-completion data are projections or auxiliary coordinates of this exact object.

## 3. Components already proved

The developing framework currently contains several exact modules.

### 3.1 Character and route promotion

The recursive character graph tracks ancestry-compatible positive character sources and exact route residues.

Single-source and multi-source promotion theorems can force new positive characters from exact state geometry even without full QR saturation.

### 3.2 Exact survivor signatures

On the two h169 pair routes actually realized by the recursive closure, the k19 miss state compresses losslessly to two modes:

- `FULL_QR`;
- `BARE`.

The BARE mode has a rigid seven-element mask and forces the remaining cofactor to be supported entirely on primes `1 mod19`.

### 3.3 Cross-shift residual coupling

For the realized k19/k23 routes, consecutive companions give

`6B-SR=1`,

with S equal to391 or1081.

Hence

`gcd(B,R)=1`.

Simultaneous k19/k23 survival therefore carries two disjoint residual prime populations with independent local support restrictions.

### 3.4 Periodic valuation phase

A routed source q creates a deterministic q-adic lift phase along

`k_n=k_0+4qn`.

For q23 starting from k19, exactly one n modulo23 produces a q23^2 lift.

### 3.5 Canonical square-divisor phase sieve

At the q23 square lift, the canonical divisor `d=23^2` is Type-II-compatible on h169 only on13 of the23 valuation phases.

The remaining ten phases are arithmetically blocked for that canonical divisor before factorization.

The same deterministic valuation mechanism can terminate in different full signed-box geometries, including Type-II-only and simultaneous Type-I/Type-II hits.

These are established modules. Their composition into a universal decomposition procedure is not yet established.

## 4. Candidate state object

The natural working state is now larger than a character assignment but much smaller than an uncompressed Cartesian product of fixed-shift closures.

A candidate survivor state may be written schematically as

`Sigma = (h, ancestry, survivor signatures, residual support, affine coupling, valuation phase, signed-box data, root geometry, BEC history)`.

For the current h169 q23 route prototype this can be compressed to coordinates of the form

```text
k19_mode            FULL_QR | BARE
R_support           QR19 | ONE19
k23_support         QR23
gcd(B,R)            1
affine_relation     6B-SR=1
q23_phase           n mod23
canonical_q23^2     allowed | blocked
signed_box_status   Type-I | Type-II | I+II | miss
root_geometry       boundary-only | interior-only | mixed | n/a
BEC_history         ordered L/R/U/D transition annotations
```

This object is the current prototype for a general decomposition-state machine.

`BEC_history` refers to the Bryan Entanglement Cross defined in `BRYAN-ENTANGLEMENT-CROSS.md`. It is observational state only. The exact arithmetic coordinates remain authoritative.

## 5. What would make this an actual decomposition method

A genuine new decomposition method requires more than isolated certificates or finite closure experiments.

The framework must eventually supply a deterministic or finitely branching procedure with the following proved properties.

### A. Domain coverage

Every input in the method's stated domain must enter one of the controlled initial states.

No survivor family may be silently discarded because it does not fit López A/B or a currently preferred route.

### B. Transition soundness

Every transition must follow from an exact theorem.

A state refinement may add residue, support, valuation, or mask information only when that information is logically forced by the parent state.

### C. Certificate soundness

Whenever the procedure declares success, it must construct an exact Erdős–Straus decomposition or an equivalent exact Type-I/II certificate.

### D. Progress

There must be a proved measure showing that a nonterminal transition makes mathematical progress rather than merely expanding descriptive state.

Examples could include a strictly reduced survivor signature, a forced valuation lift, a smaller residual-support class, or movement in a well-founded state order.

A BEC direction is **not** such a progress measure by itself. In particular, `R`, `U`, or `D` must never be substituted for a proved well-founded order.

### E. Termination

Every controlled input must reach a terminal certificate after finitely many transitions.

A finite census or bounded observed depth does not substitute for this proof.

### F. Completeness within the stated domain

The transition grammar must include every branch that can remain unresolved under the preceding rules.

If a branch is excluded, an independent theorem must prove that exclusion safe.

Only after A-F are established should the developing framework be promoted to a **decomposition method**.

## 6. What is still missing

The present framework does not yet satisfy the closure criteria.

In particular:

- the current exact survivor machinery is proved only on selected realized routes rather than all hard states;
- the 380-state character projection still does not carry every branch-local exact-state distinction;
- blocked canonical q23^2 phases are not controlled by a universal alternate signed-box rule;
- allowed canonical phases do not guarantee a prime, route realization, earlier simultaneous survival, or a terminal hit;
- BARE survivor states are genuinely realized and persist into later valuation geometry;
- no global well-founded progress measure has been proved;
- no universal selector `(state -> k,d)` has been proved;
- no termination theorem has been proved.

These are research targets, not cosmetic gaps.

## 7. The active derivation strategy

The developing method should be pursued in the following order.

1. **Preserve exact survivor information.** Do not collapse a useful `(mask,center)` signature back to a Legendre bit too early.
2. **Exploit cross-shift arithmetic.** Carry affine companion identities and exact residual coprimality into later shifts.
3. **Add deterministic valuation phase.** Treat q-adic lifts as state transitions, not as automatic certificates.
4. **Evaluate the full signed box.** At each controlled lift, allow Type I, comparable-root Type II, and incomparable-root Type II to terminate the branch.
5. **Classify residual misses.** Every miss after a controlled transition should produce a smaller exact survivor signature or expose a missing mechanism.
6. **Annotate transition direction.** After the exact transition is established, assign its Bryan Entanglement Cross direction and retain the ordered BEC history for telemetry.
7. **Search for a well-founded measure.** Test whether recurring exact/BEC motifs identify theorem corridors, but prove progress in arithmetic state rather than in the annotation grammar.

The goal is not to accumulate more non-López examples.

The goal is a machine whose state transitions themselves explain why a decomposition must eventually appear.

## 8. Research language rule

Until closure is proved, repository language should distinguish clearly between:

- **proved exact module**: a theorem already verified in its stated scope;
- **candidate transition**: a proposed composition of exact modules not yet proved complete;
- **candidate decomposition framework**: the current multi-stage architecture;
- **decomposition method**: reserved for a closed, proved construction;
- **Erdős–Straus proof**: reserved for a construction whose stated domain covers every required n.

This distinction is mandatory in PR titles, abstracts, status notes, and public summaries.

## 9. Why closure would matter

If this framework closes, the result would be qualitatively different from finding additional isolated non-López certificates.

A closed construction would provide another systematic mechanism for generating decompositions inside exact Type-II geometry.

That would be a new machine, not merely a larger solution set.

At present, that machine is being derived.

It is not yet claimed as established.

## 10. Bryan Entanglement Cross integration

The framework now carries the Bryan Entanglement Cross as a directional grammar over **proved exact transitions**.

Write

```text
L = ←⊖
R = →⊕
U = ↑(⊕/⊖)
D = ↓(⊖/⊕)
```

with the semantics fixed in `BRYAN-ENTANGLEMENT-CROSS.md`:

- `L`: exact obstruction without a forced smaller constructive state;
- `R`: direct constructive propagation or a terminal exact certificate;
- `U`: constructive expansion of the exact state space with possible later branching/obstruction cost;
- `D`: restrictive excavation that may expose a sharper constructive residual problem.

The BEC layer is intentionally downstream of proof:

```text
exact theorem/check
    -> exact before/after state
        -> BEC direction
            -> telemetry / scheduler hypothesis
```

The reverse implication is forbidden. A BEC direction can never create a theorem, pruning rule, or certificate.

### 10.1 Current q23 prototype

The blocked q23 phase experiment gives a canonical high-level BEC path:

```text
D   canonical d=23^2 López-A boundary mechanism is phase-blocked
U   the complete Type-I/Type-II signed box is reopened
R   the first exact replacement certificate is found
```

so each successful controlled cell carries

```text
BEC_path = D U R
```

with the final `R` payload recording the actual terminal geometry:

```text
Type I
boundary-only Type II
interior-only Type II
mixed I/II and/or mixed Type-II root geometry
```

Exact candidate destinations that miss before the first replacement are recorded separately as `L` obstruction observations. They do not alter the theorem-level `D U R` path for the controlled experiment because they belong to different prime candidates inside the finite progression search.

### 10.2 What to measure next

For each controlled state, retain at least

```text
exact_state
BEC_path
left_obstructions_before_terminal_R
terminal_mechanism
terminal_root_geometry
```

and condition those outputs on

```text
k19_mode
residual_support
affine coupling
valuation phase
factor pattern
ancestry route
```

The immediate theorem-search question is:

> Can an exact survivor-state predicate force or forbid a BEC continuation and, more importantly, force the arithmetic terminal geometry represented by that continuation?

A useful result would not be “this state points right.” It would be an exact implication such as

```text
specified survivor signature + support + phase + coupling
    => exact incomparable-root Type-II certificate at a controlled destination
```

with the BEC label `D U R` attached only as the machine-readable directional summary.

That is the intended role of the Bryan Entanglement Cross in the decomposition machine.
