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

`Sigma = (h, ancestry, survivor signatures, residual support, affine coupling, valuation phase, signed-box data, root geometry, BEC scope, BEC history)`.

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
BEC_scope           research-operation | live-ancestry
BEC_history         ordered L/R/U/D transition annotations
```

This object is the current prototype for a general decomposition-state machine.

`BEC_history` refers to the Bryan Entanglement Cross defined in `BRYAN-ENTANGLEMENT-CROSS.md`. It is observational state only. Exact arithmetic and exact ancestry remain authoritative.

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
4. **Respect exact ancestry.** Before promoting a distant destination geometry into the machine, verify that no earlier admissible shift already terminates the branch.
5. **Evaluate the full signed box.** At each live controlled transition, allow Type I, comparable-root Type II, and incomparable-root Type II to terminate the branch.
6. **Classify residual misses.** Every miss after a controlled transition should produce a smaller exact survivor signature or expose a missing mechanism.
7. **Annotate transition direction.** After the exact live transition is established, assign its Bryan Entanglement Cross direction and retain the scoped BEC history for telemetry.
8. **Search for a well-founded measure.** Test whether recurring exact/BEC motifs identify theorem corridors, but prove progress in arithmetic state rather than in the annotation grammar.

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

The framework carries the Bryan Entanglement Cross as a directional grammar over **proved exact transitions**.

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

The BEC layer is intentionally downstream of proof and ancestry:

```text
exact theorem/check
    -> exact before/after state
        -> exact ancestry validation
            -> scoped BEC direction
                -> telemetry / scheduler hypothesis
```

The reverse implication is forbidden. A BEC direction can never create a theorem, pruning rule, certificate, or progress proof.

### 10.1 Research-operation path versus live-ancestry path

The blocked q23 destination experiment has a valid research-operation path

```text
D   canonical d=23^2 López-A boundary mechanism is phase-blocked
U   the complete Type-I/Type-II destination geometry is reopened
R   an exact certificate is observed at that destination cross-section
```

so its **experimental** BEC path is

```text
D U R
```

However, `Q23-BLOCKED-PHASE-ANCESTRY-AUDIT.md` proves that none of the 148 simultaneous k19/k23 survivors in the audited finite prefixes actually reaches its blocked q23 destination as a live framework state. Every one terminates earlier.

Therefore `DUR` is not the live BEC history of those primes.

The ancestry-correct live paths are pinned in `BRYAN-ENTANGLEMENT-CROSS-Q23-ANCESTRY.md` and `audit_q23_blocked_phase_ancestry.py`:

```text
R           64
LR          64
LLR          7
LLLR         4
LLLLR        5
LLLLLR       3
LLLLLLLR     1
```

Here each `L` is an exact post-k23 signed-box miss at a live admissible shift and the terminal `R` is the first exact Type-I/II certificate.

The first-hit support is

```text
{27,31,35,39,43,47,55}
```

with exact totals

```text
left obstruction observations   132
right constructions              148
```

These are finite telemetry statements only. They do not prove a universal k55 ceiling or a universal drift toward construction.

### 10.2 Terminal payload remains arithmetic

A BEC terminal `R` must retain the exact certificate payload.

Across the 148 ancestry-correct first exits:

```text
Type I + Type II   122
Type I only         20
Type II only         6
```

and the complete Type-II root geometry is

```text
mixed          63
interior-only  49
boundary-only  16
n/a            20
```

Thus the direction does not replace mechanism or root geometry. It indexes the transition while the exact payload records what happened.

### 10.3 What to measure next

The immediate theorem-search split is now

```text
R       64   first hit k27
LR      64   first hit k31
L^jR    20   deeper residual, j>=2
```

Condition these exact live paths on

```text
k19_mode
residual_support
affine coupling
q23 valuation phase
factor pattern
ancestry route
```

and search for arithmetic predicates that force the first live exit and its terminal geometry.

A useful result would not be “this state points right.” It would be an exact implication such as

```text
specified survivor signature + support + phase + coupling
    => first exact hit at k31
    => exact Type-II interior certificate
```

with the BEC label `LR` attached only as the machine-readable directional summary.

That is the intended role of the Bryan Entanglement Cross in the decomposition machine.
