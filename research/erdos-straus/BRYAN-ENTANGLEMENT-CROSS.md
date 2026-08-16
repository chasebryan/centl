# Bryan Entanglement Cross

**Status:** operational research grammar over exact Erdős–Straus state transitions  
**Date:** 2026-08-16  
**Authorial name:** Bryan Entanglement Cross (BEC)  
**Primary use:** directional annotation, transition telemetry, and scheduler research  
**Claim boundary:** BEC is not an independent number-theoretic theorem, proof rule, pruning theorem, or substitute for exact arithmetic. Every BEC label is attached only after the underlying transition has been established by the exact machinery. A BEC label by itself never permits a branch to be discarded and never certifies Erdős–Straus.

---

## 1. Definition

Let `E` denote an entanglement state: an exact research state together with the arithmetic constraints currently acting on it.

The Bryan Entanglement Cross is

```text
                    ↑  ⊕/⊖

             ← ⊖     E     ⊕ →

                    ↓  ⊖/⊕
```

and its directional alphabet is

\[
\boxed{
\mathcal B(E)
=
\{\leftarrow\!\ominus,\;\rightarrow\!\oplus,\;\uparrow(\oplus/\ominus),\;\downarrow(\ominus/\oplus)\}.
}
\]

The directions are semantic, not geometric claims about the integers themselves.

- `E -> ⊕` : **positive propagation**;
- `E <- ⊖` : **negative propagation**;
- `E ↑ ⊕/⊖` : **upward expansion**, constructive enlargement that may create a later obstruction or additional branching burden;
- `E ↓ ⊖/⊕` : **downward excavation**, a restrictive or negative step that may expose a later constructive mechanism.

So entanglement is not merely signed. It is directed.

---

## 2. Exact machine interpretation

BEC sits **above** the exact state, never in place of it.

Write the exact research state schematically as

\[
\Sigma
=
(h,\text{ancestry},\text{survivor signature},\text{residual support},
\text{affine coupling},\text{valuation phase},\text{signed-box data},\text{root geometry}).
\]

The BEC-augmented state is

\[
\boxed{\Sigma^*=(\Sigma,\mathcal H_B)},
\]

where `H_B` is the ordered BEC transition history.

The invariant is:

```text
exact arithmetic decides what is true;
BEC records how the proved transition acts on the research state.
```

The annotation layer therefore carries interpretation and scheduling information without weakening exactness.

---

## 3. Direction semantics

### 3.1 Right: constructive propagation

\[
\boxed{\rightarrow\oplus}
\]

Use rightward propagation when a proved transition produces direct constructive closure or an exact terminal object.

Typical examples:

- an exact Type-I certificate;
- an exact Type-II certificate;
- a verified decomposition;
- an exact replacement mechanism that terminates the current survivor state;
- a state refinement that directly constructs a usable next exact object rather than merely enlarging the descriptive space.

Right is therefore the natural terminal direction for a successful branch.

A rightward label does **not** mean that the global Erdős–Straus problem is solved. It means only that the particular exact state or branch has propagated constructively.

### 3.2 Left: obstructive propagation

\[
\boxed{\leftarrow\ominus}
\]

Use leftward propagation when a proved transition records obstruction without itself creating a smaller controlled constructive state.

Typical examples:

- an exact miss at the currently tested destination;
- a dead local route;
- a shadowed candidate family that contributes no new controlled state;
- an obstruction that leaves the machine with no forced refinement other than returning to an earlier decision point.

Left is not failure of the research program. It is the exact recording of pressure against the current direction of travel.

### 3.3 Up: constructive expansion with possible negative consequence

\[
\boxed{\uparrow(\oplus/\ominus)}
\]

Use upward expansion when the machine gains expressive or constructive reach while also enlarging the future burden of control.

Typical examples:

- replacing a boundary-only ontology by the full exact Type-II geometry;
- opening the complete signed box after a narrower certificate family has been shown insufficient;
- promoting a scalar or character projection to a richer exact state object;
- exposing mixed Type-I/Type-II or boundary/interior witness geometry.

The positive component comes first: the machine now sees more true structure.

The possible negative consequence follows: a larger state space can introduce more branches, more witness classes, or more proof obligations.

### 3.4 Down: restrictive excavation with possible positive resolution

\[
\boxed{\downarrow(\ominus/\oplus)}
\]

Use downward excavation when a theorem first removes, restricts, or blocks a mechanism, but the resulting smaller state becomes a sharper laboratory for construction.

Typical examples:

- proving that a canonical mechanism is confined to a boundary family;
- phase-blocking a specific certificate while retaining the complete exact state;
- imposing exact survivor support, gcd, valuation, or ancestry restrictions;
- replacing a broad unresolved family by a smaller exact residual problem.

This direction is central to the present ES program. A negative restriction can be productive when it exposes the structure that the broader formulation was hiding.

---

## 4. Transition operator

Let

\[
T:\Sigma_t\longrightarrow\Sigma_{t+1}
\]

be any exact state transition admitted by the research machine.

Define the BEC annotation map

\[
\boxed{
\beta(T,\Sigma_t,\Sigma_{t+1})
\in
\{L,R,U,D\}
}
\]

with

```text
L = ←⊖
R = →⊕
U = ↑(⊕/⊖)
D = ↓(⊖/⊕)
```

The annotation must be assigned from the proved effect of the transition, not from whether the researcher likes the outcome.

A transition record should therefore store both layers:

```text
{
  exact_transition: ...,
  theorem_or_check: ...,
  before_state: ...,
  after_state: ...,
  bec_direction: L | R | U | D,
  bec_symbol: ←⊖ | →⊕ | ↑(⊕/⊖) | ↓(⊖/⊕),
  reason: ...
}
```

The exact transition remains authoritative.

---

## 5. BEC paths

A sequence of exact transitions gives a directional word

\[
\boxed{
\mathcal P_B(E_0\to E_n)
=
\beta_1\beta_2\cdots\beta_n.
}
\]

Examples:

```text
D U R
```

means

1. a restrictive theorem excavated a smaller state;
2. the machine reopened the larger exact geometry inside that reduced state;
3. the branch terminated constructively.

Likewise

```text
U L
```

means an expansion exposed a larger possibility space but the tested branch ended in obstruction.

BEC paths are intended to become empirical research objects. Their frequency and conditional structure may inform scheduling hypotheses, but no observed path frequency is itself a theorem.

---

## 6. Immediate mapping onto the active Type-II program

The current research stack already contains natural BEC transitions.

### Full Type-II geometry over López A/B

Promoting the governing search space from López A/B to full exact Type-II root geometry is

\[
\boxed{U=\uparrow(\oplus/\ominus)}.
\]

The constructive gain is a complete certificate space. The cost is a richer geometry containing boundary-only, interior-only, and mixed witness sets.

### Canonical q² boundary theorem

Proving that a successful canonical `d=q^2` square-lift Type-II certificate necessarily lies on the López-A boundary is

\[
\boxed{D=\downarrow(\ominus/\oplus)}.
\]

The theorem removes the canonical q² mechanism from the incomparable interior, but thereby creates a sharper controlled experiment on phases where that boundary mechanism is blocked.

### q23 blocked phases

The theorem that ten q23 phases block the canonical `d=529` certificate is also a downward excavation:

\[
\boxed{D}.
\]

The complete signed box is deliberately preserved.

### Reopening the complete signed box

Evaluating Type I, comparable-root Type II, incomparable-root Type II, and mixed geometry after the canonical mechanism has been removed is

\[
\boxed{U}.
\]

### First exact replacement hit

When that full geometry yields an exact Type-I or Type-II certificate, the terminal step is

\[
\boxed{R}.
\]

Thus the current twenty-cell blocked-phase experiment has the canonical high-level path

\[
\boxed{D\;U\;R}.
\]

The payload carried by the final `R` distinguishes

- Type I;
- comparable-root Type II;
- incomparable-root Type II;
- mixed I/II geometry.

Earlier exact destination misses encountered before the first replacement are `L` observations inside the finite progression search.

---

## 7. Machine state extension

The candidate decomposition-state machine should carry BEC data as observational state:

```text
Sigma = (
    h,
    ancestry,
    survivor_signature,
    residual_support,
    affine_coupling,
    valuation_phase,
    signed_box_status,
    root_geometry,
    bec_history
)
```

For compact storage, `bec_history` may be represented as

```text
DUUR
```

or as a structured event list when theorem provenance matters.

The state may also retain a non-scalar directional pressure vector

```text
BEC_pressure = {
    left_obstructions,
    right_constructions,
    upward_expansions,
    downward_excavations
}
```

This vector is telemetry only. It must not be collapsed into a universal numerical merit score unless a separate scheduling experiment explicitly defines and validates such a score.

---

## 8. Scheduler research

BEC is particularly suited to empirical scheduler design.

A scheduler may test hypotheses such as:

- states whose `D` transitions historically resolve into `R` are high-value excavation targets;
- repeated `L` with no new `D` or `U` may indicate a low-yield local region;
- `U` states may deserve deeper analysis when they expose new exact geometry, but they should be charged for the branching burden they create;
- `D U R` motifs may identify useful theorem-search corridors;
- `D U L` motifs may expose missing transition mechanisms.

These are scheduling hypotheses only.

The exact cover and theorem layers remain unchanged regardless of scheduler preference.

---

## 9. Non-negotiable safeguards

```text
BEC label != theorem
BEC label != proof
BEC label != pruning permission
BEC path frequency != density theorem
BEC scheduler priority != mathematical necessity
```

A branch may be removed only by an independent exact theorem or by the ordinary semantics of an exact terminal certificate.

BEC must never be used to smuggle heuristic confidence into the proof layer.

---

## 10. Immediate research target

The first serious BEC-conditioned theorem search is the existing twenty-cell q23 blocked-phase atlas.

For each cell, retain

```text
route
k19_mode                    FULL_QR | BARE
R_support                   QR19 | ONE19
k23_support                 QR23
affine_relation             6B-SR=1
q23_phase                   n mod23
canonical_q23^2             blocked
replacement_mechanism       Type I | Type II | I+II
replacement_root_geometry   boundary-only | interior-only | mixed | n/a
BEC_path                    D U R
left_obstructions_before_R  exact finite count
```

The next theorem question is then:

> Which exact survivor-state coordinates force or forbid particular BEC continuations and terminal replacement geometries?

For example, can one prove a state implication of the form

\[
(\text{BARE},\text{support},\text{phase},\text{coupling})
\Longrightarrow
DUR_{\mathrm{interior\ Type\ II}}
\]

on a nontrivial infinite family?

That would convert the Bryan Entanglement Cross from a descriptive grammar into a useful indexing language for a genuine transition theorem, while the theorem itself would still be stated and proved entirely in exact arithmetic.

---

## 11. Research interpretation

The central idea is simple:

> a prime, certificate, or survivor state does not merely survive or collapse; the exact constraints acting on it can be tracked as directed pressure.

Right records construction.  
Left records obstruction.  
Up records expansion with possible later cost.  
Down records excavation with possible later resolution.

The Bryan Entanglement Cross gives that motion a mathematical grammar without confusing the grammar for the mathematics underneath it.

The intended use is therefore disciplined:

\[
\boxed{
\text{exact arithmetic state}
\;\longrightarrow\;
\text{proved transition}
\;\longrightarrow\;
\text{BEC direction}
\;\longrightarrow\;
\text{telemetry and theorem search}
}
\]

Erdős–Straus remains open.
